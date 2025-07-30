-- =====================================================
-- QIRO 사업자 인증 및 검증 시스템
-- Business Verification Records 테이블 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 인증 관련 ENUM 타입 정의
-- =====================================================

-- 인증 타입
CREATE TYPE verification_type AS ENUM (
    'BUSINESS_REGISTRATION',    -- 사업자등록번호 인증
    'PHONE_VERIFICATION',       -- 전화번호 인증
    'EMAIL_VERIFICATION'        -- 이메일 인증
);

-- 인증 상태
CREATE TYPE verification_record_status AS ENUM (
    'PENDING',      -- 인증 대기
    'SUCCESS',      -- 인증 성공
    'FAILED',       -- 인증 실패
    'EXPIRED'       -- 인증 만료
);

-- =====================================================
-- 2. Business Verification Records 테이블 생성
-- =====================================================

CREATE TABLE business_verification_records (
    verification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 인증 기본 정보
    verification_type verification_type NOT NULL,
    verification_status verification_record_status NOT NULL DEFAULT 'PENDING',
    
    -- 인증 데이터 (JSONB로 유연하게 저장)
    verification_data JSONB NOT NULL DEFAULT '{}',
    
    -- 인증 결과 및 메타데이터
    verification_result JSONB DEFAULT '{}',
    verification_date TIMESTAMPTZ,
    expiry_date TIMESTAMPTZ,
    
    -- 오류 정보
    error_message TEXT,
    error_code VARCHAR(50),
    retry_count INTEGER DEFAULT 0,
    
    -- 외부 API 연동 정보
    external_reference_id VARCHAR(255),
    external_api_response JSONB,
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES users(user_id),
    updated_by UUID REFERENCES users(user_id),
    
    -- 제약조건
    CONSTRAINT chk_expiry_date_future 
        CHECK (expiry_date IS NULL OR expiry_date > created_at),
    CONSTRAINT chk_retry_count_positive 
        CHECK (retry_count >= 0 AND retry_count <= 10),
    CONSTRAINT chk_verification_date_valid 
        CHECK (verification_date IS NULL OR verification_date >= created_at)
);

-- =====================================================
-- 3. 인덱스 생성
-- =====================================================

-- 회사별 인증 기록 조회용 인덱스
CREATE INDEX idx_business_verification_company_id 
    ON business_verification_records(company_id);

-- 인증 타입별 조회용 인덱스
CREATE INDEX idx_business_verification_type 
    ON business_verification_records(verification_type);

-- 인증 상태별 조회용 인덱스
CREATE INDEX idx_business_verification_status 
    ON business_verification_records(verification_status);

-- 생성일 기준 정렬용 인덱스
CREATE INDEX idx_business_verification_created_at 
    ON business_verification_records(created_at DESC);

-- 만료일 기준 조회용 인덱스 (만료된 인증 정리용)
CREATE INDEX idx_business_verification_expiry_date 
    ON business_verification_records(expiry_date) 
    WHERE expiry_date IS NOT NULL;

-- 복합 인덱스: 회사별 인증 타입별 최신 기록 조회용
CREATE INDEX idx_business_verification_company_type_date 
    ON business_verification_records(company_id, verification_type, created_at DESC);

-- 외부 참조 ID 조회용 인덱스
CREATE INDEX idx_business_verification_external_ref 
    ON business_verification_records(external_reference_id) 
    WHERE external_reference_id IS NOT NULL;

-- JSONB 데이터 검색용 GIN 인덱스
CREATE INDEX idx_business_verification_data_gin 
    ON business_verification_records USING gin(verification_data);

CREATE INDEX idx_business_verification_result_gin 
    ON business_verification_records USING gin(verification_result);

-- =====================================================
-- 4. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER business_verification_updated_at_trigger
    BEFORE UPDATE ON business_verification_records
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. 인증 관련 함수들
-- =====================================================

-- 사업자등록번호 인증 기록 생성 함수
CREATE OR REPLACE FUNCTION create_business_registration_verification(
    p_company_id UUID,
    p_business_registration_number VARCHAR(20),
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    v_verification_id UUID;
    v_verification_data JSONB;
BEGIN
    -- 인증 데이터 구성
    v_verification_data := jsonb_build_object(
        'business_registration_number', p_business_registration_number,
        'requested_at', now(),
        'ip_address', current_setting('app.client_ip', true)
    );
    
    -- 인증 기록 생성
    INSERT INTO business_verification_records (
        company_id,
        verification_type,
        verification_data,
        expiry_date,
        created_by
    ) VALUES (
        p_company_id,
        'BUSINESS_REGISTRATION',
        v_verification_data,
        now() + INTERVAL '24 hours',  -- 24시간 후 만료
        p_created_by
    ) RETURNING verification_id INTO v_verification_id;
    
    RETURN v_verification_id;
END;
$ LANGUAGE plpgsql;

-- 전화번호 인증 기록 생성 함수
CREATE OR REPLACE FUNCTION create_phone_verification(
    p_company_id UUID,
    p_phone_number VARCHAR(20),
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    v_verification_id UUID;
    v_verification_data JSONB;
BEGIN
    -- 인증 데이터 구성
    v_verification_data := jsonb_build_object(
        'phone_number', p_phone_number,
        'requested_at', now(),
        'ip_address', current_setting('app.client_ip', true)
    );
    
    -- 인증 기록 생성
    INSERT INTO business_verification_records (
        company_id,
        verification_type,
        verification_data,
        expiry_date,
        created_by
    ) VALUES (
        p_company_id,
        'PHONE_VERIFICATION',
        v_verification_data,
        now() + INTERVAL '10 minutes',  -- 10분 후 만료
        p_created_by
    ) RETURNING verification_id INTO v_verification_id;
    
    RETURN v_verification_id;
END;
$ LANGUAGE plpgsql;

-- 이메일 인증 기록 생성 함수
CREATE OR REPLACE FUNCTION create_email_verification(
    p_company_id UUID,
    p_email VARCHAR(255),
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    v_verification_id UUID;
    v_verification_data JSONB;
BEGIN
    -- 인증 데이터 구성
    v_verification_data := jsonb_build_object(
        'email', p_email,
        'requested_at', now(),
        'ip_address', current_setting('app.client_ip', true)
    );
    
    -- 인증 기록 생성
    INSERT INTO business_verification_records (
        company_id,
        verification_type,
        verification_data,
        expiry_date,
        created_by
    ) VALUES (
        p_company_id,
        'EMAIL_VERIFICATION',
        v_verification_data,
        now() + INTERVAL '1 hour',  -- 1시간 후 만료
        p_created_by
    ) RETURNING verification_id INTO v_verification_id;
    
    RETURN v_verification_id;
END;
$ LANGUAGE plpgsql;

-- 인증 성공 처리 함수
CREATE OR REPLACE FUNCTION complete_verification(
    p_verification_id UUID,
    p_verification_result JSONB DEFAULT '{}',
    p_external_reference_id VARCHAR(255) DEFAULT NULL,
    p_external_api_response JSONB DEFAULT NULL
)
RETURNS BOOLEAN AS $
DECLARE
    v_company_id UUID;
    v_verification_type verification_type;
BEGIN
    -- 인증 기록 업데이트
    UPDATE business_verification_records 
    SET 
        verification_status = 'SUCCESS',
        verification_date = now(),
        verification_result = p_verification_result,
        external_reference_id = p_external_reference_id,
        external_api_response = p_external_api_response,
        updated_at = now()
    WHERE 
        verification_id = p_verification_id
        AND verification_status = 'PENDING'
        AND (expiry_date IS NULL OR expiry_date > now())
    RETURNING company_id, verification_type INTO v_company_id, v_verification_type;
    
    -- 업데이트된 행이 없으면 실패
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- 회사 테이블의 인증 상태 업데이트 (사업자등록번호 인증인 경우)
    IF v_verification_type = 'BUSINESS_REGISTRATION' THEN
        UPDATE companies 
        SET 
            verification_status = 'VERIFIED',
            verification_date = now(),
            updated_at = now()
        WHERE company_id = v_company_id;
    END IF;
    
    RETURN TRUE;
END;
$ LANGUAGE plpgsql;

-- 인증 실패 처리 함수
CREATE OR REPLACE FUNCTION fail_verification(
    p_verification_id UUID,
    p_error_message TEXT,
    p_error_code VARCHAR(50) DEFAULT NULL,
    p_external_api_response JSONB DEFAULT NULL
)
RETURNS BOOLEAN AS $
BEGIN
    -- 인증 기록 업데이트
    UPDATE business_verification_records 
    SET 
        verification_status = 'FAILED',
        error_message = p_error_message,
        error_code = p_error_code,
        external_api_response = p_external_api_response,
        retry_count = retry_count + 1,
        updated_at = now()
    WHERE 
        verification_id = p_verification_id
        AND verification_status = 'PENDING';
    
    RETURN FOUND;
END;
$ LANGUAGE plpgsql;

-- 만료된 인증 기록 정리 함수
CREATE OR REPLACE FUNCTION cleanup_expired_verifications()
RETURNS INTEGER AS $
DECLARE
    expired_count INTEGER;
BEGIN
    -- 만료된 인증 기록을 EXPIRED 상태로 변경
    UPDATE business_verification_records 
    SET 
        verification_status = 'EXPIRED',
        updated_at = now()
    WHERE 
        verification_status = 'PENDING'
        AND expiry_date IS NOT NULL 
        AND expiry_date <= now();
    
    GET DIAGNOSTICS expired_count = ROW_COUNT;
    RETURN expired_count;
END;
$ LANGUAGE plpgsql;

-- 최신 인증 기록 조회 함수
CREATE OR REPLACE FUNCTION get_latest_verification(
    p_company_id UUID,
    p_verification_type verification_type
)
RETURNS business_verification_records AS $
DECLARE
    v_record business_verification_records;
BEGIN
    SELECT * INTO v_record
    FROM business_verification_records
    WHERE 
        company_id = p_company_id
        AND verification_type = p_verification_type
    ORDER BY created_at DESC
    LIMIT 1;
    
    RETURN v_record;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. Row Level Security (RLS) 설정
-- =====================================================

-- RLS 활성화
ALTER TABLE business_verification_records ENABLE ROW LEVEL SECURITY;

-- 조직별 데이터 격리 정책
CREATE POLICY business_verification_company_isolation_policy 
    ON business_verification_records
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY business_verification_admin_policy 
    ON business_verification_records
    FOR ALL
    TO postgres
    USING (true);

-- =====================================================
-- 7. 코멘트 추가
-- =====================================================

COMMENT ON TABLE business_verification_records IS '사업자 인증 및 검증 기록 관리 테이블';
COMMENT ON COLUMN business_verification_records.verification_id IS '인증 기록 고유 식별자 (UUID)';
COMMENT ON COLUMN business_verification_records.company_id IS '대상 회사 식별자 (외래키)';
COMMENT ON COLUMN business_verification_records.verification_type IS '인증 타입 (BUSINESS_REGISTRATION, PHONE_VERIFICATION, EMAIL_VERIFICATION)';
COMMENT ON COLUMN business_verification_records.verification_status IS '인증 상태 (PENDING, SUCCESS, FAILED, EXPIRED)';
COMMENT ON COLUMN business_verification_records.verification_data IS '인증 요청 데이터 (JSONB)';
COMMENT ON COLUMN business_verification_records.verification_result IS '인증 결과 데이터 (JSONB)';
COMMENT ON COLUMN business_verification_records.verification_date IS '인증 완료 시간';
COMMENT ON COLUMN business_verification_records.expiry_date IS '인증 만료 시간';
COMMENT ON COLUMN business_verification_records.error_message IS '인증 실패 시 오류 메시지';
COMMENT ON COLUMN business_verification_records.error_code IS '인증 실패 시 오류 코드';
COMMENT ON COLUMN business_verification_records.retry_count IS '재시도 횟수';
COMMENT ON COLUMN business_verification_records.external_reference_id IS '외부 API 참조 ID';
COMMENT ON COLUMN business_verification_records.external_api_response IS '외부 API 응답 데이터 (JSONB)';

-- =====================================================
-- 8. 샘플 데이터 및 테스트 함수 (개발용)
-- =====================================================

-- 개발 환경에서만 실행되는 샘플 데이터 생성 함수
CREATE OR REPLACE FUNCTION create_sample_verification_data()
RETURNS VOID AS $
DECLARE
    v_company_id UUID;
    v_verification_id UUID;
BEGIN
    -- 테스트용 회사가 있는지 확인
    SELECT company_id INTO v_company_id
    FROM companies 
    WHERE business_registration_number = '1234567890'
    LIMIT 1;
    
    IF v_company_id IS NOT NULL THEN
        -- 사업자등록번호 인증 기록 생성
        v_verification_id := create_business_registration_verification(
            v_company_id, 
            '1234567890'
        );
        
        -- 인증 성공 처리
        PERFORM complete_verification(
            v_verification_id,
            jsonb_build_object(
                'verified_company_name', '테스트 회사',
                'verified_representative', '홍길동',
                'verification_method', 'API'
            ),
            'NTS_REF_' || extract(epoch from now())::text
        );
        
        RAISE NOTICE '샘플 인증 데이터가 생성되었습니다. Company ID: %', v_company_id;
    ELSE
        RAISE NOTICE '테스트용 회사를 찾을 수 없습니다.';
    END IF;
END;
$ LANGUAGE plpgsql;