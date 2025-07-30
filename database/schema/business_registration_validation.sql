-- =====================================================
-- 사업자등록번호 검증 함수 개선 및 API 연동 준비
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- 확장 기능 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 1. 사업자등록번호 검증 결과 캐시 테이블
-- =====================================================

-- 검증 결과 타입 정의
CREATE TYPE business_verification_result AS ENUM ('VALID', 'INVALID', 'API_ERROR', 'PENDING');

-- 사업자등록번호 검증 캐시 테이블
CREATE TABLE IF NOT EXISTS business_registration_cache (
    cache_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    business_registration_number VARCHAR(20) NOT NULL UNIQUE,
    checksum_valid BOOLEAN NOT NULL,
    api_verification_result business_verification_result,
    api_verification_data JSONB DEFAULT '{}',
    api_last_checked TIMESTAMPTZ,
    api_error_message TEXT,
    cache_expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 인덱스 생성
CREATE INDEX idx_business_cache_brn ON business_registration_cache(business_registration_number);
CREATE INDEX idx_business_cache_expires ON business_registration_cache(cache_expires_at);
CREATE INDEX idx_business_cache_api_result ON business_registration_cache(api_verification_result);

-- =====================================================
-- 2. 개선된 사업자등록번호 체크섬 검증 함수
-- =====================================================

-- 기존 함수 대체
DROP FUNCTION IF EXISTS validate_business_registration_number(TEXT);

CREATE OR REPLACE FUNCTION validate_business_registration_checksum(brn TEXT)
RETURNS BOOLEAN AS $
DECLARE
    digits INTEGER[];
    check_sum INTEGER;
    calculated_check INTEGER;
    i INTEGER;
BEGIN
    -- NULL 또는 빈 문자열 검증
    IF brn IS NULL OR LENGTH(TRIM(brn)) = 0 THEN
        RETURN FALSE;
    END IF;
    
    -- 하이픈 제거 및 공백 제거
    brn := REGEXP_REPLACE(TRIM(brn), '[^0-9]', '', 'g');
    
    -- 10자리 숫자 검증
    IF LENGTH(brn) != 10 OR brn !~ '^[0-9]{10}$' THEN
        RETURN FALSE;
    END IF;
    
    -- 모든 자리가 같은 숫자인 경우 제외 (예: 0000000000, 1111111111)
    IF brn ~ '^(.)\1{9}$' THEN
        RETURN FALSE;
    END IF;
    
    -- 각 자리수를 배열로 변환
    FOR i IN 1..10 LOOP
        digits[i] := SUBSTRING(brn FROM i FOR 1)::INTEGER;
    END LOOP;
    
    -- 한국 사업자등록번호 체크섬 알고리즘
    -- 가중치: 1,3,7,1,3,7,1,3,5 (9번째 자리까지)
    check_sum := digits[1] * 1 + digits[2] * 3 + digits[3] * 7 + digits[4] * 1 + 
                 digits[5] * 3 + digits[6] * 7 + digits[7] * 1 + digits[8] * 3;
    
    -- 9번째 자리는 특별 처리 (5를 곱한 후 10으로 나눈 몫을 더함)
    check_sum := check_sum + ((digits[9] * 5) / 10)::INTEGER;
    
    -- 체크 디지트 계산
    calculated_check := (10 - (check_sum % 10)) % 10;
    
    -- 마지막 자리수와 계산된 체크 디지트 비교
    RETURN calculated_check = digits[10];
    
EXCEPTION
    WHEN OTHERS THEN
        -- 예외 발생 시 FALSE 반환
        RETURN FALSE;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 사업자등록번호 종합 검증 함수 (캐시 포함)
-- =====================================================

CREATE OR REPLACE FUNCTION validate_business_registration_number(brn TEXT)
RETURNS JSONB AS $
DECLARE
    clean_brn TEXT;
    checksum_result BOOLEAN;
    cache_record RECORD;
    result JSONB;
BEGIN
    -- 입력값 정리
    clean_brn := REGEXP_REPLACE(TRIM(COALESCE(brn, '')), '[^0-9]', '', 'g');
    
    -- 기본 형식 검증
    IF LENGTH(clean_brn) != 10 THEN
        RETURN jsonb_build_object(
            'valid', false,
            'checksum_valid', false,
            'api_verified', false,
            'error', '사업자등록번호는 10자리 숫자여야 합니다.',
            'business_registration_number', clean_brn
        );
    END IF;
    
    -- 체크섬 검증
    checksum_result := validate_business_registration_checksum(clean_brn);
    
    -- 체크섬이 유효하지 않으면 즉시 반환
    IF NOT checksum_result THEN
        RETURN jsonb_build_object(
            'valid', false,
            'checksum_valid', false,
            'api_verified', false,
            'error', '사업자등록번호 체크섬이 유효하지 않습니다.',
            'business_registration_number', clean_brn
        );
    END IF;
    
    -- 캐시에서 기존 검증 결과 조회
    SELECT * INTO cache_record 
    FROM business_registration_cache 
    WHERE business_registration_number = clean_brn 
      AND cache_expires_at > now();
    
    -- 캐시된 결과가 있는 경우
    IF FOUND THEN
        result := jsonb_build_object(
            'valid', (cache_record.checksum_valid AND cache_record.api_verification_result = 'VALID'),
            'checksum_valid', cache_record.checksum_valid,
            'api_verified', (cache_record.api_verification_result = 'VALID'),
            'api_verification_result', cache_record.api_verification_result,
            'api_verification_data', cache_record.api_verification_data,
            'api_last_checked', cache_record.api_last_checked,
            'business_registration_number', clean_brn,
            'cached', true
        );
        
        -- API 오류가 있었다면 오류 메시지 포함
        IF cache_record.api_error_message IS NOT NULL THEN
            result := result || jsonb_build_object('api_error', cache_record.api_error_message);
        END IF;
        
        RETURN result;
    END IF;
    
    -- 캐시에 체크섬 결과만 저장 (API 검증은 별도 프로세스에서 수행)
    INSERT INTO business_registration_cache (
        business_registration_number,
        checksum_valid,
        api_verification_result
    ) VALUES (
        clean_brn,
        checksum_result,
        'PENDING'
    ) ON CONFLICT (business_registration_number) 
    DO UPDATE SET
        checksum_valid = EXCLUDED.checksum_valid,
        updated_at = now();
    
    -- 체크섬만 검증된 결과 반환
    RETURN jsonb_build_object(
        'valid', checksum_result,
        'checksum_valid', checksum_result,
        'api_verified', false,
        'api_verification_result', 'PENDING',
        'business_registration_number', clean_brn,
        'cached', false,
        'message', '체크섬 검증 완료. API 검증은 별도로 수행됩니다.'
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN jsonb_build_object(
            'valid', false,
            'checksum_valid', false,
            'api_verified', false,
            'error', '검증 중 오류가 발생했습니다: ' || SQLERRM,
            'business_registration_number', clean_brn
        );
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 국세청 API 연동을 위한 인터페이스 함수
-- =====================================================

-- API 검증 결과 업데이트 함수
CREATE OR REPLACE FUNCTION update_business_registration_api_result(
    brn TEXT,
    verification_result business_verification_result,
    verification_data JSONB DEFAULT '{}',
    error_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $
BEGIN
    UPDATE business_registration_cache 
    SET 
        api_verification_result = verification_result,
        api_verification_data = verification_data,
        api_last_checked = now(),
        api_error_message = error_message,
        cache_expires_at = CASE 
            WHEN verification_result = 'VALID' THEN now() + INTERVAL '30 days'
            WHEN verification_result = 'INVALID' THEN now() + INTERVAL '7 days'
            ELSE now() + INTERVAL '1 day'
        END,
        updated_at = now()
    WHERE business_registration_number = REGEXP_REPLACE(TRIM(COALESCE(brn, '')), '[^0-9]', '', 'g');
    
    RETURN FOUND;
END;
$ LANGUAGE plpgsql;

-- API 검증이 필요한 사업자등록번호 조회 함수
CREATE OR REPLACE FUNCTION get_pending_business_registrations(limit_count INTEGER DEFAULT 100)
RETURNS TABLE (
    business_registration_number VARCHAR(20),
    created_at TIMESTAMPTZ,
    checksum_valid BOOLEAN
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        brc.business_registration_number,
        brc.created_at,
        brc.checksum_valid
    FROM business_registration_cache brc
    WHERE brc.api_verification_result = 'PENDING'
      AND brc.checksum_valid = true
      AND (brc.api_last_checked IS NULL OR brc.api_last_checked < now() - INTERVAL '1 hour')
    ORDER BY brc.created_at ASC
    LIMIT limit_count;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 재검증 로직 함수
-- =====================================================

-- 만료된 캐시 정리 함수
CREATE OR REPLACE FUNCTION cleanup_expired_business_cache()
RETURNS INTEGER AS $
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM business_registration_cache 
    WHERE cache_expires_at < now();
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$ LANGUAGE plpgsql;

-- 특정 사업자등록번호 재검증 요청 함수
CREATE OR REPLACE FUNCTION request_business_registration_reverification(brn TEXT)
RETURNS BOOLEAN AS $
DECLARE
    clean_brn TEXT;
BEGIN
    clean_brn := REGEXP_REPLACE(TRIM(COALESCE(brn, '')), '[^0-9]', '', 'g');
    
    UPDATE business_registration_cache 
    SET 
        api_verification_result = 'PENDING',
        api_last_checked = NULL,
        api_error_message = NULL,
        cache_expires_at = now() + INTERVAL '1 day',
        updated_at = now()
    WHERE business_registration_number = clean_brn;
    
    RETURN FOUND;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 통계 및 모니터링 함수
-- =====================================================

-- 검증 통계 조회 함수
CREATE OR REPLACE FUNCTION get_business_registration_stats()
RETURNS JSONB AS $
DECLARE
    stats JSONB;
BEGIN
    SELECT jsonb_build_object(
        'total_cached', COUNT(*),
        'checksum_valid', COUNT(*) FILTER (WHERE checksum_valid = true),
        'checksum_invalid', COUNT(*) FILTER (WHERE checksum_valid = false),
        'api_verified', COUNT(*) FILTER (WHERE api_verification_result = 'VALID'),
        'api_invalid', COUNT(*) FILTER (WHERE api_verification_result = 'INVALID'),
        'api_pending', COUNT(*) FILTER (WHERE api_verification_result = 'PENDING'),
        'api_error', COUNT(*) FILTER (WHERE api_verification_result = 'API_ERROR'),
        'expired_cache', COUNT(*) FILTER (WHERE cache_expires_at < now())
    ) INTO stats
    FROM business_registration_cache;
    
    RETURN stats;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 7. 트리거 및 자동화
-- =====================================================

-- updated_at 자동 업데이트 함수 (존재하지 않는 경우)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 캐시 테이블 updated_at 트리거
CREATE TRIGGER business_cache_updated_at_trigger
    BEFORE UPDATE ON business_registration_cache
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 8. 권한 설정
-- =====================================================

-- 애플리케이션 역할에 필요한 권한 부여
GRANT SELECT, INSERT, UPDATE ON business_registration_cache TO application_role;
GRANT EXECUTE ON FUNCTION validate_business_registration_checksum(TEXT) TO application_role;
GRANT EXECUTE ON FUNCTION validate_business_registration_number(TEXT) TO application_role;
GRANT EXECUTE ON FUNCTION update_business_registration_api_result(TEXT, business_verification_result, JSONB, TEXT) TO application_role;
GRANT EXECUTE ON FUNCTION get_pending_business_registrations(INTEGER) TO application_role;
GRANT EXECUTE ON FUNCTION request_business_registration_reverification(TEXT) TO application_role;
GRANT EXECUTE ON FUNCTION get_business_registration_stats() TO application_role;

-- =====================================================
-- 9. 코멘트 추가
-- =====================================================

COMMENT ON TABLE business_registration_cache IS '사업자등록번호 검증 결과 캐시 테이블';
COMMENT ON COLUMN business_registration_cache.business_registration_number IS '사업자등록번호 (10자리 숫자)';
COMMENT ON COLUMN business_registration_cache.checksum_valid IS '체크섬 검증 결과';
COMMENT ON COLUMN business_registration_cache.api_verification_result IS 'API 검증 결과 (VALID, INVALID, API_ERROR, PENDING)';
COMMENT ON COLUMN business_registration_cache.api_verification_data IS 'API에서 받은 사업자 정보 데이터';
COMMENT ON COLUMN business_registration_cache.api_last_checked IS 'API 마지막 검증 시간';
COMMENT ON COLUMN business_registration_cache.api_error_message IS 'API 검증 실패 시 오류 메시지';
COMMENT ON COLUMN business_registration_cache.cache_expires_at IS '캐시 만료 시간';

COMMENT ON FUNCTION validate_business_registration_checksum(TEXT) IS '사업자등록번호 체크섬 검증 함수';
COMMENT ON FUNCTION validate_business_registration_number(TEXT) IS '사업자등록번호 종합 검증 함수 (캐시 포함)';
COMMENT ON FUNCTION update_business_registration_api_result(TEXT, business_verification_result, JSONB, TEXT) IS 'API 검증 결과 업데이트 함수';
COMMENT ON FUNCTION get_pending_business_registrations(INTEGER) IS 'API 검증이 필요한 사업자등록번호 조회 함수';
COMMENT ON FUNCTION cleanup_expired_business_cache() IS '만료된 캐시 정리 함수';
COMMENT ON FUNCTION request_business_registration_reverification(TEXT) IS '사업자등록번호 재검증 요청 함수';
COMMENT ON FUNCTION get_business_registration_stats() IS '검증 통계 조회 함수';