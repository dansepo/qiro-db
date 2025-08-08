-- =====================================================
-- 데이터 검증 및 비즈니스 규칙 시스템 스키마
-- =====================================================

-- 비즈니스 규칙 테이블
CREATE TABLE IF NOT EXISTS bms.business_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name VARCHAR(100) NOT NULL,
    rule_code VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    rule_type VARCHAR(20) NOT NULL CHECK (rule_type IN ('VALIDATION', 'CONSTRAINT', 'WORKFLOW', 'CALCULATION', 'NOTIFICATION', 'APPROVAL', 'AUTOMATION')),
    entity_type VARCHAR(50) NOT NULL,
    condition TEXT NOT NULL,
    action TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 100,
    is_active BOOLEAN NOT NULL DEFAULT true,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id),
    updated_at TIMESTAMP WITH TIME ZONE,
    updated_by UUID REFERENCES bms.users(user_id)
);

-- 비즈니스 규칙 인덱스
CREATE INDEX IF NOT EXISTS idx_business_rule_code ON bms.business_rules(rule_code);
CREATE INDEX IF NOT EXISTS idx_business_rule_type ON bms.business_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_business_rule_entity_type ON bms.business_rules(entity_type);
CREATE INDEX IF NOT EXISTS idx_business_rule_active ON bms.business_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_business_rule_priority ON bms.business_rules(priority);
CREATE INDEX IF NOT EXISTS idx_business_rule_company ON bms.business_rules(company_id);

-- 검증 설정 테이블
CREATE TABLE IF NOT EXISTS bms.validation_configs (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type VARCHAR(50) NOT NULL,
    field VARCHAR(50) NOT NULL,
    validation_type VARCHAR(30) NOT NULL,
    configuration JSONB NOT NULL DEFAULT '{}',
    is_required BOOLEAN NOT NULL DEFAULT false,
    error_message VARCHAR(200),
    warning_message VARCHAR(200),
    is_active BOOLEAN NOT NULL DEFAULT true,
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL REFERENCES bms.users(user_id)
);

-- 검증 설정 인덱스
CREATE INDEX IF NOT EXISTS idx_validation_config_entity_field ON bms.validation_configs(entity_type, field);
CREATE INDEX IF NOT EXISTS idx_validation_config_type ON bms.validation_configs(validation_type);
CREATE INDEX IF NOT EXISTS idx_validation_config_active ON bms.validation_configs(is_active);
CREATE INDEX IF NOT EXISTS idx_validation_config_company ON bms.validation_configs(company_id);

-- 규칙 실행 로그 테이블
CREATE TABLE IF NOT EXISTS bms.rule_execution_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID NOT NULL,
    rule_name VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id UUID NOT NULL,
    executed BOOLEAN NOT NULL,
    success BOOLEAN NOT NULL,
    result JSONB,
    error_message TEXT,
    execution_time BIGINT NOT NULL,
    executed_by UUID NOT NULL REFERENCES bms.users(user_id),
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    executed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 규칙 실행 로그 인덱스
CREATE INDEX IF NOT EXISTS idx_rule_execution_rule_id ON bms.rule_execution_logs(rule_id);
CREATE INDEX IF NOT EXISTS idx_rule_execution_entity ON bms.rule_execution_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_rule_execution_date ON bms.rule_execution_logs(executed_at);
CREATE INDEX IF NOT EXISTS idx_rule_execution_success ON bms.rule_execution_logs(success);
CREATE INDEX IF NOT EXISTS idx_rule_execution_company ON bms.rule_execution_logs(company_id);

-- 데이터 무결성 검사 로그 테이블
CREATE TABLE IF NOT EXISTS bms.data_integrity_logs (
    check_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_name VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    total_records BIGINT NOT NULL,
    valid_records BIGINT NOT NULL,
    invalid_records BIGINT NOT NULL,
    issues JSONB NOT NULL DEFAULT '[]',
    duration BIGINT NOT NULL,
    checked_by UUID NOT NULL REFERENCES bms.users(user_id),
    company_id UUID NOT NULL REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    checked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 데이터 무결성 로그 인덱스
CREATE INDEX IF NOT EXISTS idx_data_integrity_entity_type ON bms.data_integrity_logs(entity_type);
CREATE INDEX IF NOT EXISTS idx_data_integrity_check_date ON bms.data_integrity_logs(checked_at);
CREATE INDEX IF NOT EXISTS idx_data_integrity_issues ON bms.data_integrity_logs(invalid_records);
CREATE INDEX IF NOT EXISTS idx_data_integrity_company ON bms.data_integrity_logs(company_id);

-- =====================================================
-- 검증 관련 함수들
-- =====================================================

-- 자산 번호 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_asset_number(asset_number TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- 자산 번호 형식: XX-XXXXXX-XX (2-3자리 영문 + 4-6자리 숫자 + 2자리 숫자)
    RETURN asset_number ~ '^[A-Z]{2,3}-\d{4,6}-\d{2}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 한국 전화번호 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_korean_phone(phone_number TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    -- 한국 전화번호 형식들
    RETURN phone_number ~ '^(010-\d{4}-\d{4}|02-\d{3,4}-\d{4}|0[3-6]\d-\d{3,4}-\d{4}|070-\d{4}-\d{4}|1[5-9]\d{2}-\d{4})$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 사업자등록번호 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_business_registration_number(brn TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    clean_brn TEXT;
    weights INTEGER[] := ARRAY[1,3,7,1,3,7,1,3,5];
    sum_val INTEGER := 0;
    check_digit INTEGER;
    i INTEGER;
BEGIN
    -- 하이픈 제거
    clean_brn := REPLACE(brn, '-', '');
    
    -- 길이 체크
    IF LENGTH(clean_brn) != 10 THEN
        RETURN FALSE;
    END IF;
    
    -- 숫자만 포함하는지 체크
    IF clean_brn !~ '^\d{10}$' THEN
        RETURN FALSE;
    END IF;
    
    -- 체크섬 계산
    FOR i IN 1..9 LOOP
        sum_val := sum_val + (SUBSTRING(clean_brn, i, 1)::INTEGER * weights[i]);
    END LOOP;
    
    sum_val := sum_val + ((SUBSTRING(clean_brn, 9, 1)::INTEGER * 5) / 10);
    check_digit := (10 - (sum_val % 10)) % 10;
    
    RETURN check_digit = SUBSTRING(clean_brn, 10, 1)::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 이메일 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_email(email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 날짜 범위 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_date_range(start_date DATE, end_date DATE)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN start_date <= end_date;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 시간 범위 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_time_range(start_time TIMESTAMP, end_time TIMESTAMP, max_hours INTEGER DEFAULT 24)
RETURNS BOOLEAN AS $$
BEGIN
    IF start_time > end_time THEN
        RETURN FALSE;
    END IF;
    
    RETURN EXTRACT(EPOCH FROM (end_time - start_time)) / 3600 <= max_hours;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =====================================================
-- 데이터 무결성 검사 함수들
-- =====================================================

-- 필수 필드 누락 검사
CREATE OR REPLACE FUNCTION bms.check_missing_required_fields(
    p_entity_type TEXT,
    p_company_id UUID
)
RETURNS TABLE(
    entity_id UUID,
    field_name TEXT,
    issue_description TEXT
) AS $$
BEGIN
    CASE p_entity_type
        WHEN 'FACILITY' THEN
            RETURN QUERY
            SELECT 
                f.facility_id,
                'facility_name'::TEXT,
                '시설물명이 누락되었습니다'::TEXT
            FROM bms.facilities f
            WHERE f.company_id = p_company_id 
            AND (f.facility_name IS NULL OR f.facility_name = '');
            
            RETURN QUERY
            SELECT 
                f.facility_id,
                'location'::TEXT,
                '위치 정보가 누락되었습니다'::TEXT
            FROM bms.facilities f
            WHERE f.company_id = p_company_id 
            AND (f.location IS NULL OR f.location = '');
            
        WHEN 'WORK_ORDER' THEN
            RETURN QUERY
            SELECT 
                w.work_order_id,
                'title'::TEXT,
                '작업지시서 제목이 누락되었습니다'::TEXT
            FROM bms.work_orders w
            WHERE w.company_id = p_company_id 
            AND (w.title IS NULL OR w.title = '');
            
        WHEN 'USER' THEN
            RETURN QUERY
            SELECT 
                u.user_id,
                'username'::TEXT,
                '사용자명이 누락되었습니다'::TEXT
            FROM bms.users u
            WHERE u.company_id = p_company_id 
            AND (u.username IS NULL OR u.username = '');
            
            RETURN QUERY
            SELECT 
                u.user_id,
                'email'::TEXT,
                '이메일이 누락되었습니다'::TEXT
            FROM bms.users u
            WHERE u.company_id = p_company_id 
            AND (u.email IS NULL OR u.email = '');
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 데이터 형식 오류 검사
CREATE OR REPLACE FUNCTION bms.check_data_format_issues(
    p_entity_type TEXT,
    p_company_id UUID
)
RETURNS TABLE(
    entity_id UUID,
    field_name TEXT,
    current_value TEXT,
    issue_description TEXT
) AS $$
BEGIN
    CASE p_entity_type
        WHEN 'FACILITY' THEN
            -- 자산 번호 형식 검사
            RETURN QUERY
            SELECT 
                f.facility_id,
                'asset_number'::TEXT,
                f.asset_number,
                '자산 번호 형식이 올바르지 않습니다'::TEXT
            FROM bms.facilities f
            WHERE f.company_id = p_company_id 
            AND f.asset_number IS NOT NULL
            AND NOT bms.validate_asset_number(f.asset_number);
            
        WHEN 'COMPANY' THEN
            -- 사업자등록번호 형식 검사
            RETURN QUERY
            SELECT 
                c.company_id,
                'business_registration_number'::TEXT,
                c.business_registration_number,
                '사업자등록번호 형식이 올바르지 않습니다'::TEXT
            FROM bms.companies c
            WHERE c.company_id = p_company_id 
            AND c.business_registration_number IS NOT NULL
            AND NOT bms.validate_business_registration_number(c.business_registration_number);
            
        WHEN 'USER' THEN
            -- 이메일 형식 검사
            RETURN QUERY
            SELECT 
                u.user_id,
                'email'::TEXT,
                u.email,
                '이메일 형식이 올바르지 않습니다'::TEXT
            FROM bms.users u
            WHERE u.company_id = p_company_id 
            AND u.email IS NOT NULL
            AND NOT bms.validate_email(u.email);
            
            -- 전화번호 형식 검사
            RETURN QUERY
            SELECT 
                u.user_id,
                'phone'::TEXT,
                u.phone,
                '전화번호 형식이 올바르지 않습니다'::TEXT
            FROM bms.users u
            WHERE u.company_id = p_company_id 
            AND u.phone IS NOT NULL
            AND NOT bms.validate_korean_phone(u.phone);
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 중복 데이터 검사
CREATE OR REPLACE FUNCTION bms.check_duplicate_data(
    p_entity_type TEXT,
    p_company_id UUID
)
RETURNS TABLE(
    entity_id UUID,
    field_name TEXT,
    duplicate_value TEXT,
    duplicate_count BIGINT
) AS $$
BEGIN
    CASE p_entity_type
        WHEN 'FACILITY' THEN
            -- 자산 번호 중복 검사
            RETURN QUERY
            SELECT 
                f.facility_id,
                'asset_number'::TEXT,
                f.asset_number,
                COUNT(*) OVER (PARTITION BY f.asset_number)
            FROM bms.facilities f
            WHERE f.company_id = p_company_id 
            AND f.asset_number IS NOT NULL
            AND f.asset_number IN (
                SELECT asset_number 
                FROM bms.facilities 
                WHERE company_id = p_company_id 
                AND asset_number IS NOT NULL
                GROUP BY asset_number 
                HAVING COUNT(*) > 1
            );
            
        WHEN 'USER' THEN
            -- 사용자명 중복 검사
            RETURN QUERY
            SELECT 
                u.user_id,
                'username'::TEXT,
                u.username,
                COUNT(*) OVER (PARTITION BY u.username)
            FROM bms.users u
            WHERE u.company_id = p_company_id 
            AND u.username IS NOT NULL
            AND u.username IN (
                SELECT username 
                FROM bms.users 
                WHERE company_id = p_company_id 
                AND username IS NOT NULL
                GROUP BY username 
                HAVING COUNT(*) > 1
            );
            
            -- 이메일 중복 검사
            RETURN QUERY
            SELECT 
                u.user_id,
                'email'::TEXT,
                u.email,
                COUNT(*) OVER (PARTITION BY u.email)
            FROM bms.users u
            WHERE u.company_id = p_company_id 
            AND u.email IS NOT NULL
            AND u.email IN (
                SELECT email 
                FROM bms.users 
                WHERE company_id = p_company_id 
                AND email IS NOT NULL
                GROUP BY email 
                HAVING COUNT(*) > 1
            );
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 참조 무결성 검사
CREATE OR REPLACE FUNCTION bms.check_reference_integrity(
    p_entity_type TEXT,
    p_company_id UUID
)
RETURNS TABLE(
    entity_id UUID,
    field_name TEXT,
    reference_value UUID,
    issue_description TEXT
) AS $$
BEGIN
    CASE p_entity_type
        WHEN 'FACILITY' THEN
            -- 생성자 참조 무결성 검사
            RETURN QUERY
            SELECT 
                f.facility_id,
                'created_by'::TEXT,
                f.created_by,
                '생성자 정보가 존재하지 않습니다'::TEXT
            FROM bms.facilities f
            LEFT JOIN bms.users u ON f.created_by = u.user_id
            WHERE f.company_id = p_company_id 
            AND f.created_by IS NOT NULL
            AND u.user_id IS NULL;
            
        WHEN 'WORK_ORDER' THEN
            -- 시설물 참조 무결성 검사
            RETURN QUERY
            SELECT 
                w.work_order_id,
                'facility_id'::TEXT,
                w.facility_id,
                '참조하는 시설물이 존재하지 않습니다'::TEXT
            FROM bms.work_orders w
            LEFT JOIN bms.facilities f ON w.facility_id = f.facility_id
            WHERE w.company_id = p_company_id 
            AND w.facility_id IS NOT NULL
            AND f.facility_id IS NULL;
            
            -- 담당자 참조 무결성 검사
            RETURN QUERY
            SELECT 
                w.work_order_id,
                'assigned_to'::TEXT,
                w.assigned_to,
                '담당자 정보가 존재하지 않습니다'::TEXT
            FROM bms.work_orders w
            LEFT JOIN bms.users u ON w.assigned_to = u.user_id
            WHERE w.company_id = p_company_id 
            AND w.assigned_to IS NOT NULL
            AND u.user_id IS NULL;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 비즈니스 규칙 위반 검사
CREATE OR REPLACE FUNCTION bms.check_business_rule_violations(
    p_entity_type TEXT,
    p_company_id UUID
)
RETURNS TABLE(
    entity_id UUID,
    field_name TEXT,
    current_value TEXT,
    issue_description TEXT
) AS $$
BEGIN
    CASE p_entity_type
        WHEN 'WORK_ORDER' THEN
            -- 시작일이 종료일보다 늦은 경우
            RETURN QUERY
            SELECT 
                w.work_order_id,
                'start_date,end_date'::TEXT,
                CONCAT('시작일: ', w.start_date, ', 종료일: ', w.end_date),
                '시작일이 종료일보다 늦습니다'::TEXT
            FROM bms.work_orders w
            WHERE w.company_id = p_company_id 
            AND w.start_date IS NOT NULL 
            AND w.end_date IS NOT NULL 
            AND w.start_date > w.end_date;
            
        WHEN 'BUDGET_MANAGEMENT' THEN
            -- 사용 금액이 할당 금액을 초과하는 경우
            RETURN QUERY
            SELECT 
                b.budget_id,
                'used_amount'::TEXT,
                b.used_amount::TEXT,
                '사용 금액이 할당 금액을 초과했습니다'::TEXT
            FROM bms.budget_management b
            WHERE b.company_id = p_company_id 
            AND b.allocated_amount IS NOT NULL 
            AND b.used_amount IS NOT NULL 
            AND b.used_amount > b.allocated_amount;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 기본 검증 설정 데이터
-- =====================================================

-- 시설물 검증 설정
INSERT INTO bms.validation_configs (entity_type, field, validation_type, configuration, is_required, error_message, company_id, created_by)
SELECT 
    'FACILITY',
    'facility_name',
    'NOT_EMPTY',
    '{}',
    true,
    '시설물명은 필수 입력 항목입니다',
    c.company_id,
    u.user_id
FROM bms.companies c
CROSS JOIN (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1) u
ON CONFLICT DO NOTHING;

INSERT INTO bms.validation_configs (entity_type, field, validation_type, configuration, is_required, error_message, company_id, created_by)
SELECT 
    'FACILITY',
    'asset_number',
    'PATTERN',
    '{"pattern": "^[A-Z]{2,3}-\\\\d{4,6}-\\\\d{2}$"}',
    false,
    '자산 번호 형식이 올바르지 않습니다 (예: ABC-123456-01)',
    c.company_id,
    u.user_id
FROM bms.companies c
CROSS JOIN (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1) u
ON CONFLICT DO NOTHING;

-- 사용자 검증 설정
INSERT INTO bms.validation_configs (entity_type, field, validation_type, configuration, is_required, error_message, company_id, created_by)
SELECT 
    'USER',
    'email',
    'EMAIL',
    '{}',
    true,
    '올바른 이메일 형식을 입력해주세요',
    c.company_id,
    u.user_id
FROM bms.companies c
CROSS JOIN (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1) u
ON CONFLICT DO NOTHING;

INSERT INTO bms.validation_configs (entity_type, field, validation_type, configuration, is_required, error_message, company_id, created_by)
SELECT 
    'USER',
    'phone',
    'PHONE',
    '{}',
    false,
    '올바른 전화번호 형식을 입력해주세요',
    c.company_id,
    u.user_id
FROM bms.companies c
CROSS JOIN (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1) u
ON CONFLICT DO NOTHING;

-- =====================================================
-- 테이블 코멘트
-- =====================================================

COMMENT ON TABLE bms.business_rules IS '비즈니스 규칙 정보를 저장하는 테이블';
COMMENT ON COLUMN bms.business_rules.rule_id IS '규칙 고유 식별자';
COMMENT ON COLUMN bms.business_rules.rule_name IS '규칙 이름';
COMMENT ON COLUMN bms.business_rules.rule_code IS '규칙 코드 (고유)';
COMMENT ON COLUMN bms.business_rules.description IS '규칙 설명';
COMMENT ON COLUMN bms.business_rules.rule_type IS '규칙 타입 (VALIDATION, CONSTRAINT, WORKFLOW, CALCULATION, NOTIFICATION, APPROVAL, AUTOMATION)';
COMMENT ON COLUMN bms.business_rules.entity_type IS '적용 대상 엔티티 타입';
COMMENT ON COLUMN bms.business_rules.condition IS '규칙 조건 (JSON 또는 표현식)';
COMMENT ON COLUMN bms.business_rules.action IS '규칙 액션 (JSON 또는 표현식)';
COMMENT ON COLUMN bms.business_rules.priority IS '우선순위 (낮은 숫자가 높은 우선순위)';
COMMENT ON COLUMN bms.business_rules.is_active IS '활성화 여부';

COMMENT ON TABLE bms.validation_configs IS '검증 설정 정보를 저장하는 테이블';
COMMENT ON COLUMN bms.validation_configs.config_id IS '설정 고유 식별자';
COMMENT ON COLUMN bms.validation_configs.entity_type IS '적용 대상 엔티티 타입';
COMMENT ON COLUMN bms.validation_configs.field IS '검증 대상 필드';
COMMENT ON COLUMN bms.validation_configs.validation_type IS '검증 타입';
COMMENT ON COLUMN bms.validation_configs.configuration IS '검증 설정 (JSON)';
COMMENT ON COLUMN bms.validation_configs.is_required IS '필수 여부';
COMMENT ON COLUMN bms.validation_configs.error_message IS '오류 메시지';
COMMENT ON COLUMN bms.validation_configs.warning_message IS '경고 메시지';

COMMENT ON TABLE bms.rule_execution_logs IS '규칙 실행 로그를 저장하는 테이블';
COMMENT ON COLUMN bms.rule_execution_logs.log_id IS '로그 고유 식별자';
COMMENT ON COLUMN bms.rule_execution_logs.rule_id IS '실행된 규칙 ID';
COMMENT ON COLUMN bms.rule_execution_logs.rule_name IS '규칙 이름 (스냅샷)';
COMMENT ON COLUMN bms.rule_execution_logs.entity_type IS '대상 엔티티 타입';
COMMENT ON COLUMN bms.rule_execution_logs.entity_id IS '대상 엔티티 ID';
COMMENT ON COLUMN bms.rule_execution_logs.executed IS '실행 여부';
COMMENT ON COLUMN bms.rule_execution_logs.success IS '성공 여부';
COMMENT ON COLUMN bms.rule_execution_logs.result IS '실행 결과 (JSON)';
COMMENT ON COLUMN bms.rule_execution_logs.error_message IS '오류 메시지';
COMMENT ON COLUMN bms.rule_execution_logs.execution_time IS '실행 시간 (밀리초)';

COMMENT ON TABLE bms.data_integrity_logs IS '데이터 무결성 검사 로그를 저장하는 테이블';
COMMENT ON COLUMN bms.data_integrity_logs.check_id IS '검사 고유 식별자';
COMMENT ON COLUMN bms.data_integrity_logs.check_name IS '검사 이름';
COMMENT ON COLUMN bms.data_integrity_logs.entity_type IS '대상 엔티티 타입';
COMMENT ON COLUMN bms.data_integrity_logs.total_records IS '전체 레코드 수';
COMMENT ON COLUMN bms.data_integrity_logs.valid_records IS '유효한 레코드 수';
COMMENT ON COLUMN bms.data_integrity_logs.invalid_records IS '무효한 레코드 수';
COMMENT ON COLUMN bms.data_integrity_logs.issues IS '검사 결과 상세 (JSON)';
COMMENT ON COLUMN bms.data_integrity_logs.duration IS '검사 소요 시간 (밀리초)';