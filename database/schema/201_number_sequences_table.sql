-- =====================================================
-- 번호 시퀀스 관리 테이블
-- 각종 번호 생성을 위한 시퀀스 관리
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 번호 시퀀스 테이블 생성
-- =====================================================

CREATE TABLE IF NOT EXISTS bms.number_sequences (
    sequence_id BIGSERIAL PRIMARY KEY,
    sequence_key VARCHAR(255) UNIQUE NOT NULL,
    current_value BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT chk_current_value_positive CHECK (current_value >= 0)
);

-- =====================================================
-- 2. 인덱스 생성
-- =====================================================

-- 시퀀스 키 검색용 인덱스 (이미 UNIQUE 제약조건으로 생성됨)
-- 업데이트 시간 기준 정렬용 인덱스
CREATE INDEX IF NOT EXISTS idx_number_sequences_updated_at ON bms.number_sequences(updated_at DESC);

-- =====================================================
-- 3. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 함수 (존재하지 않는 경우에만 생성)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- updated_at 자동 업데이트 트리거
DROP TRIGGER IF EXISTS number_sequences_updated_at_trigger ON bms.number_sequences;
CREATE TRIGGER number_sequences_updated_at_trigger
    BEFORE UPDATE ON bms.number_sequences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 4. Row Level Security (RLS) 설정
-- =====================================================

-- RLS 활성화
ALTER TABLE bms.number_sequences ENABLE ROW LEVEL SECURITY;

-- 애플리케이션 역할에 대한 정책 (회사별 격리)
CREATE POLICY number_sequences_company_policy ON bms.number_sequences
    FOR ALL
    TO application_role
    USING (
        sequence_key LIKE '%' || current_setting('app.current_company_id', true) || '%'
        OR current_setting('app.current_user_role', true) = 'SUPER_ADMIN'
    );

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY number_sequences_admin_policy ON bms.number_sequences
    FOR ALL
    TO postgres
    USING (true);

-- =====================================================
-- 5. 권한 설정
-- =====================================================

-- 애플리케이션 역할에 테이블 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON bms.number_sequences TO application_role;
GRANT USAGE, SELECT ON SEQUENCE bms.number_sequences_sequence_id_seq TO application_role;

-- =====================================================
-- 6. 코멘트 추가
-- =====================================================

COMMENT ON TABLE bms.number_sequences IS '번호 시퀀스 관리 테이블 - 각종 번호 생성을 위한 시퀀스 저장';
COMMENT ON COLUMN bms.number_sequences.sequence_id IS '시퀀스 고유 식별자';
COMMENT ON COLUMN bms.number_sequences.sequence_key IS '시퀀스 키 (회사ID_번호유형_기간 형태)';
COMMENT ON COLUMN bms.number_sequences.current_value IS '현재 시퀀스 값';
COMMENT ON COLUMN bms.number_sequences.created_at IS '생성일시';
COMMENT ON COLUMN bms.number_sequences.updated_at IS '수정일시';

-- =====================================================
-- 7. 초기 데이터 삽입 (예시)
-- =====================================================

-- 테스트용 시퀀스 데이터 (필요시 주석 해제)
/*
INSERT INTO bms.number_sequences (sequence_key, current_value) VALUES
('accounting_test_INCOME_202501', 0),
('notice_test_GENERAL_202501', 0),
('work_order_test_MAINTENANCE_202501', 0),
('fault_report_test_HIGH_20250130', 0)
ON CONFLICT (sequence_key) DO NOTHING;
*/

-- =====================================================
-- 8. 시퀀스 관리 함수들
-- =====================================================

-- 다음 시퀀스 값 조회 함수
CREATE OR REPLACE FUNCTION bms.get_next_sequence_value(p_sequence_key VARCHAR)
RETURNS BIGINT AS $$
DECLARE
    next_value BIGINT;
BEGIN
    -- 시퀀스 값 증가 및 반환
    INSERT INTO bms.number_sequences (sequence_key, current_value)
    VALUES (p_sequence_key, 1)
    ON CONFLICT (sequence_key) 
    DO UPDATE SET 
        current_value = bms.number_sequences.current_value + 1,
        updated_at = NOW()
    RETURNING current_value INTO next_value;
    
    RETURN next_value;
END;
$$ LANGUAGE plpgsql;

-- 시퀀스 초기화 함수
CREATE OR REPLACE FUNCTION bms.reset_sequence(p_sequence_key VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
    DELETE FROM bms.number_sequences WHERE sequence_key = p_sequence_key;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

-- 시퀀스 현재 값 조회 함수
CREATE OR REPLACE FUNCTION bms.get_current_sequence_value(p_sequence_key VARCHAR)
RETURNS BIGINT AS $$
DECLARE
    current_val BIGINT;
BEGIN
    SELECT current_value INTO current_val
    FROM bms.number_sequences
    WHERE sequence_key = p_sequence_key;
    
    RETURN COALESCE(current_val, 0);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 9. 시퀀스 정리 작업 (유지보수용)
-- =====================================================

-- 오래된 시퀀스 정리 함수 (30일 이상 사용되지 않은 시퀀스)
CREATE OR REPLACE FUNCTION bms.cleanup_old_sequences()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM bms.number_sequences
    WHERE updated_at < NOW() - INTERVAL '30 days';
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 시퀀스 통계 조회 함수
CREATE OR REPLACE FUNCTION bms.get_sequence_statistics()
RETURNS TABLE (
    total_sequences BIGINT,
    active_sequences BIGINT,
    inactive_sequences BIGINT,
    avg_sequence_value NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_sequences,
        COUNT(*) FILTER (WHERE updated_at > NOW() - INTERVAL '7 days') as active_sequences,
        COUNT(*) FILTER (WHERE updated_at <= NOW() - INTERVAL '7 days') as inactive_sequences,
        AVG(current_value) as avg_sequence_value
    FROM bms.number_sequences;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 10. 함수 권한 설정
-- =====================================================

-- 애플리케이션 역할에 함수 실행 권한 부여
GRANT EXECUTE ON FUNCTION bms.get_next_sequence_value(VARCHAR) TO application_role;
GRANT EXECUTE ON FUNCTION bms.reset_sequence(VARCHAR) TO application_role;
GRANT EXECUTE ON FUNCTION bms.get_current_sequence_value(VARCHAR) TO application_role;
GRANT EXECUTE ON FUNCTION bms.cleanup_old_sequences() TO application_role;
GRANT EXECUTE ON FUNCTION bms.get_sequence_statistics() TO application_role;

-- =====================================================
-- 11. 함수 코멘트
-- =====================================================

COMMENT ON FUNCTION bms.get_next_sequence_value(VARCHAR) IS '다음 시퀀스 값을 조회하고 증가시키는 함수';
COMMENT ON FUNCTION bms.reset_sequence(VARCHAR) IS '지정된 시퀀스를 초기화하는 함수';
COMMENT ON FUNCTION bms.get_current_sequence_value(VARCHAR) IS '현재 시퀀스 값을 조회하는 함수';
COMMENT ON FUNCTION bms.cleanup_old_sequences() IS '오래된 시퀀스를 정리하는 함수';
COMMENT ON FUNCTION bms.get_sequence_statistics() IS '시퀀스 통계 정보를 조회하는 함수';