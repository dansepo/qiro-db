-- =====================================================
-- 외부 고지서 관리 시스템 테이블 생성 스크립트
-- Phase 2.2.3: 외부 고지서 관리 테이블
-- =====================================================

-- 1. 외부 공급업체 마스터 테이블
CREATE TABLE IF NOT EXISTS bms.utility_providers (
    provider_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 공급업체 기본 정보
    provider_name VARCHAR(100) NOT NULL,                -- 공급업체명
    provider_code VARCHAR(20) NOT NULL,                 -- 공급업체 코드
    provider_type VARCHAR(20) NOT NULL,                 -- 공급업체 유형
    
    -- 연락처 정보
    contact_person VARCHAR(100),                        -- 담당자명
    phone_number VARCHAR(20),                           -- 전화번호
    email VARCHAR(255),                                 -- 이메일
    fax_number VARCHAR(20),                             -- 팩스번호
    
    -- 주소 정보
    address TEXT,                                       -- 주소
    postal_code VARCHAR(10),                            -- 우편번호
    
    -- 계약 정보
    contract_number VARCHAR(50),                        -- 계약번호
    contract_start_date DATE,                           -- 계약 시작일
    contract_end_date DATE,                             -- 계약 종료일
    
    -- 고지서 설정
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY',        -- 고지 주기
    billing_day INTEGER DEFAULT 1,                      -- 고지일
    payment_due_days INTEGER DEFAULT 30,                -- 납부 기한
    
    -- 자동화 설정
    auto_import_enabled BOOLEAN DEFAULT false,          -- 자동 가져오기 활성화
    import_method VARCHAR(20),                          -- 가져오기 방식
    api_endpoint VARCHAR(200),                          -- API 엔드포인트
    api_credentials JSONB,                              -- API 인증 정보 (암호화)
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_providers_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_providers_code UNIQUE (company_id, provider_code),
    
    -- 체크 제약조건
    CONSTRAINT chk_provider_type CHECK (provider_type IN (
        'ELECTRIC',            -- 전력회사
        'WATER',               -- 수도공사
        'GAS',                 -- 가스공사
        'HEATING',             -- 난방공사
        'TELECOM',             -- 통신사
        'WASTE',               -- 폐기물처리
        'SECURITY',            -- 보안업체
        'MAINTENANCE',         -- 유지보수업체
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_billing_cycle_provider CHECK (billing_cycle IN (
        'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL'
    )),
    CONSTRAINT chk_import_method CHECK (import_method IN (
        'API',                 -- API 연동
        'EMAIL',               -- 이메일 수신
        'FTP',                 -- FTP 업로드
        'MANUAL',              -- 수동 입력
        'OCR'                  -- OCR 인식
    )),
    CONSTRAINT chk_billing_day_provider CHECK (billing_day BETWEEN 1 AND 31),
    CONSTRAINT chk_payment_due_days_provider CHECK (payment_due_days > 0)
);

-- 완료 메시지
SELECT '✅ 2.3 외부 고지서 관리 테이블 생성이 완료되었습니다!' as result;-
- 2. 외부 고지서 테이블
CREATE TABLE IF NOT EXISTS bms.external_bills (
    bill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    provider_id UUID NOT NULL,
    building_id UUID,                                   -- NULL이면 전체 건물 대상
    
    -- 고지서 기본 정보
    bill_number VARCHAR(50) NOT NULL,                   -- 고지서 번호
    bill_type VARCHAR(20) NOT NULL,                     -- 고지서 유형
    bill_period_start DATE NOT NULL,                    -- 고지 기간 시작
    bill_period_end DATE NOT NULL,                      -- 고지 기간 종료
    issue_date DATE NOT NULL,                           -- 발행일
    due_date DATE NOT NULL,                             -- 납부 기한
    
    -- 사용량 정보
    previous_reading DECIMAL(15,4),                     -- 이전 검침값
    current_reading DECIMAL(15,4),                      -- 현재 검침값
    usage_amount DECIMAL(15,4),                         -- 사용량
    usage_unit VARCHAR(20),                             -- 사용량 단위
    
    -- 요금 정보
    basic_charge DECIMAL(15,4) DEFAULT 0,               -- 기본요금
    usage_charge DECIMAL(15,4) DEFAULT 0,               -- 사용요금
    additional_charges DECIMAL(15,4) DEFAULT 0,         -- 추가요금
    tax_amount DECIMAL(15,4) DEFAULT 0,                 -- 세금
    total_amount DECIMAL(15,4) NOT NULL,                -- 총 금액
    
    -- 요금 상세 내역 (JSON)
    charge_details JSONB,                               -- 요금 상세 내역
    
    -- 고지서 상태
    bill_status VARCHAR(20) DEFAULT 'RECEIVED',         -- 고지서 상태
    payment_status VARCHAR(20) DEFAULT 'UNPAID',        -- 납부 상태
    
    -- 검증 정보
    is_validated BOOLEAN DEFAULT false,                 -- 검증 완료 여부
    validation_status VARCHAR(20),                      -- 검증 상태
    validation_notes TEXT,                              -- 검증 메모
    validated_by UUID,                                  -- 검증자 ID
    validated_at TIMESTAMP WITH TIME ZONE,             -- 검증 일시
    
    -- 오류 정보
    has_errors BOOLEAN DEFAULT false,                   -- 오류 여부
    error_details JSONB,                                -- 오류 상세 내역
    error_resolved BOOLEAN DEFAULT false,               -- 오류 해결 여부
    
    -- 파일 정보
    original_file_url TEXT,                             -- 원본 파일 URL
    processed_file_url TEXT,                            -- 처리된 파일 URL
    file_format VARCHAR(20),                            -- 파일 형식
    
    -- 가져오기 정보
    import_method VARCHAR(20),                          -- 가져오기 방식
    imported_at TIMESTAMP WITH TIME ZONE,              -- 가져오기 일시
    imported_by UUID,                                   -- 가져오기 담당자
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_bills_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_bills_provider FOREIGN KEY (provider_id) REFERENCES bms.utility_providers(provider_id) ON DELETE CASCADE,
    CONSTRAINT fk_bills_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_bills_validator FOREIGN KEY (validated_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_bills_importer FOREIGN KEY (imported_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_bills_number UNIQUE (company_id, provider_id, bill_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_bill_type CHECK (bill_type IN (
        'ELECTRIC',            -- 전기요금
        'WATER',               -- 수도요금
        'GAS',                 -- 가스요금
        'HEATING',             -- 난방요금
        'TELECOM',             -- 통신요금
        'WASTE',               -- 폐기물처리비
        'MAINTENANCE',         -- 유지보수비
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_bill_period CHECK (bill_period_end >= bill_period_start),
    CONSTRAINT chk_bill_status CHECK (bill_status IN (
        'RECEIVED',            -- 수신됨
        'PROCESSING',          -- 처리중
        'VALIDATED',           -- 검증됨
        'ERROR',               -- 오류
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_payment_status CHECK (payment_status IN (
        'UNPAID',              -- 미납
        'PAID',                -- 납부완료
        'PARTIAL',             -- 부분납부
        'OVERDUE'              -- 연체
    )),
    CONSTRAINT chk_validation_status_bill CHECK (validation_status IN (
        'PENDING',             -- 검증 대기
        'PASSED',              -- 검증 통과
        'FAILED',              -- 검증 실패
        'MANUAL_REVIEW'        -- 수동 검토 필요
    )),
    CONSTRAINT chk_import_method_bill CHECK (import_method IN (
        'API', 'EMAIL', 'FTP', 'MANUAL', 'OCR'
    )),
    CONSTRAINT chk_file_format CHECK (file_format IN (
        'PDF', 'EXCEL', 'CSV', 'XML', 'JSON', 'IMAGE'
    )),
    CONSTRAINT chk_total_amount CHECK (total_amount >= 0)
);-- 3. 고지
서 처리 이력 테이블
CREATE TABLE IF NOT EXISTS bms.bill_processing_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 처리 정보
    processing_step VARCHAR(20) NOT NULL,               -- 처리 단계
    processing_status VARCHAR(20) NOT NULL,             -- 처리 상태
    processing_result TEXT,                             -- 처리 결과
    
    -- 오류 정보
    error_code VARCHAR(20),                             -- 오류 코드
    error_message TEXT,                                 -- 오류 메시지
    error_details JSONB,                                -- 오류 상세 정보
    
    -- 처리자 정보
    processed_by UUID,                                  -- 처리자 ID
    processing_method VARCHAR(20),                      -- 처리 방식
    
    -- 시간 정보
    started_at TIMESTAMP WITH TIME ZONE,               -- 시작 시간
    completed_at TIMESTAMP WITH TIME ZONE,             -- 완료 시간
    duration_seconds INTEGER,                           -- 처리 시간 (초)
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_processing_history_bill FOREIGN KEY (bill_id) REFERENCES bms.external_bills(bill_id) ON DELETE CASCADE,
    CONSTRAINT fk_processing_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_processing_history_processor FOREIGN KEY (processed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_processing_step CHECK (processing_step IN (
        'IMPORT',              -- 가져오기
        'PARSE',               -- 파싱
        'VALIDATE',            -- 검증
        'TRANSFORM',           -- 변환
        'STORE',               -- 저장
        'NOTIFY'               -- 알림
    )),
    CONSTRAINT chk_processing_status_history CHECK (processing_status IN (
        'STARTED',             -- 시작됨
        'IN_PROGRESS',         -- 진행중
        'COMPLETED',           -- 완료됨
        'FAILED',              -- 실패
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_processing_method CHECK (processing_method IN (
        'AUTOMATIC',           -- 자동
        'MANUAL',              -- 수동
        'BATCH',               -- 배치
        'REAL_TIME'            -- 실시간
    ))
);

-- 4. 고지서 매핑 규칙 테이블
CREATE TABLE IF NOT EXISTS bms.bill_mapping_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    provider_id UUID NOT NULL,
    
    -- 규칙 정보
    rule_name VARCHAR(100) NOT NULL,                    -- 규칙명
    rule_description TEXT,                              -- 규칙 설명
    rule_type VARCHAR(20) NOT NULL,                     -- 규칙 유형
    
    -- 매핑 설정
    source_field VARCHAR(100) NOT NULL,                 -- 원본 필드
    target_field VARCHAR(100) NOT NULL,                 -- 대상 필드
    field_type VARCHAR(20) NOT NULL,                    -- 필드 유형
    
    -- 변환 규칙
    transformation_rule TEXT,                           -- 변환 규칙
    default_value TEXT,                                 -- 기본값
    validation_pattern VARCHAR(200),                    -- 검증 패턴
    
    -- 조건 설정
    condition_expression TEXT,                          -- 조건 표현식
    
    -- 우선순위
    priority_order INTEGER DEFAULT 1,                   -- 우선순위
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_mapping_rules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_mapping_rules_provider FOREIGN KEY (provider_id) REFERENCES bms.utility_providers(provider_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_rule_type_mapping CHECK (rule_type IN (
        'FIELD_MAPPING',       -- 필드 매핑
        'VALUE_TRANSFORMATION',-- 값 변환
        'VALIDATION',          -- 검증
        'CALCULATION',         -- 계산
        'CONDITIONAL'          -- 조건부
    )),
    CONSTRAINT chk_field_type CHECK (field_type IN (
        'STRING',              -- 문자열
        'NUMBER',              -- 숫자
        'DATE',                -- 날짜
        'BOOLEAN',             -- 불린
        'AMOUNT',              -- 금액
        'USAGE'                -- 사용량
    )),
    CONSTRAINT chk_priority_order_mapping CHECK (priority_order > 0)
);-- 5. RLS 
정책 활성화
ALTER TABLE bms.utility_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.external_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.bill_processing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.bill_mapping_rules ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY utility_providers_isolation_policy ON bms.utility_providers
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY external_bills_isolation_policy ON bms.external_bills
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY bill_processing_history_isolation_policy ON bms.bill_processing_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY bill_mapping_rules_isolation_policy ON bms.bill_mapping_rules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 공급업체 인덱스
CREATE INDEX idx_providers_company_id ON bms.utility_providers(company_id);
CREATE INDEX idx_providers_type ON bms.utility_providers(provider_type);
CREATE INDEX idx_providers_code ON bms.utility_providers(provider_code);
CREATE INDEX idx_providers_active ON bms.utility_providers(is_active);

-- 외부 고지서 인덱스
CREATE INDEX idx_bills_company_id ON bms.external_bills(company_id);
CREATE INDEX idx_bills_provider_id ON bms.external_bills(provider_id);
CREATE INDEX idx_bills_building_id ON bms.external_bills(building_id);
CREATE INDEX idx_bills_type ON bms.external_bills(bill_type);
CREATE INDEX idx_bills_period ON bms.external_bills(bill_period_start, bill_period_end);
CREATE INDEX idx_bills_issue_date ON bms.external_bills(issue_date DESC);
CREATE INDEX idx_bills_due_date ON bms.external_bills(due_date);
CREATE INDEX idx_bills_status ON bms.external_bills(bill_status);
CREATE INDEX idx_bills_payment_status ON bms.external_bills(payment_status);
CREATE INDEX idx_bills_validated ON bms.external_bills(is_validated);

-- 처리 이력 인덱스
CREATE INDEX idx_processing_history_bill_id ON bms.bill_processing_history(bill_id);
CREATE INDEX idx_processing_history_company_id ON bms.bill_processing_history(company_id);
CREATE INDEX idx_processing_history_step ON bms.bill_processing_history(processing_step);
CREATE INDEX idx_processing_history_status ON bms.bill_processing_history(processing_status);
CREATE INDEX idx_processing_history_created_at ON bms.bill_processing_history(created_at DESC);

-- 매핑 규칙 인덱스
CREATE INDEX idx_mapping_rules_company_id ON bms.bill_mapping_rules(company_id);
CREATE INDEX idx_mapping_rules_provider_id ON bms.bill_mapping_rules(provider_id);
CREATE INDEX idx_mapping_rules_type ON bms.bill_mapping_rules(rule_type);
CREATE INDEX idx_mapping_rules_priority ON bms.bill_mapping_rules(priority_order);
CREATE INDEX idx_mapping_rules_active ON bms.bill_mapping_rules(is_active);

-- 복합 인덱스
CREATE INDEX idx_bills_provider_period ON bms.external_bills(provider_id, bill_period_start, bill_period_end);
CREATE INDEX idx_bills_company_status ON bms.external_bills(company_id, bill_status);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER utility_providers_updated_at_trigger
    BEFORE UPDATE ON bms.utility_providers
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER external_bills_updated_at_trigger
    BEFORE UPDATE ON bms.external_bills
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER bill_mapping_rules_updated_at_trigger
    BEFORE UPDATE ON bms.bill_mapping_rules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();-- 9.
 고지서 처리 함수들
-- 고지서 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_external_bill(
    p_bill_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_bill_rec RECORD;
    v_provider_rec RECORD;
    v_is_valid BOOLEAN := true;
    v_error_details JSONB := '{}';
    v_validation_notes TEXT := '';
BEGIN
    -- 고지서 정보 조회
    SELECT * INTO v_bill_rec
    FROM bms.external_bills
    WHERE bill_id = p_bill_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '고지서를 찾을 수 없습니다: %', p_bill_id;
    END IF;
    
    -- 공급업체 정보 조회
    SELECT * INTO v_provider_rec
    FROM bms.utility_providers
    WHERE provider_id = v_bill_rec.provider_id;
    
    -- 1. 기본 필드 검증
    IF v_bill_rec.bill_number IS NULL OR LENGTH(v_bill_rec.bill_number) = 0 THEN
        v_is_valid := false;
        v_error_details := v_error_details || '{"bill_number": "고지서 번호가 없습니다"}';
    END IF;
    
    IF v_bill_rec.total_amount IS NULL OR v_bill_rec.total_amount < 0 THEN
        v_is_valid := false;
        v_error_details := v_error_details || '{"total_amount": "총 금액이 유효하지 않습니다"}';
    END IF;
    
    IF v_bill_rec.bill_period_start IS NULL OR v_bill_rec.bill_period_end IS NULL THEN
        v_is_valid := false;
        v_error_details := v_error_details || '{"period": "고지 기간이 설정되지 않았습니다"}';
    ELSIF v_bill_rec.bill_period_end < v_bill_rec.bill_period_start THEN
        v_is_valid := false;
        v_error_details := v_error_details || '{"period": "고지 기간이 올바르지 않습니다"}';
    END IF;
    
    -- 2. 사용량 검증 (사용량이 있는 경우)
    IF v_bill_rec.current_reading IS NOT NULL AND v_bill_rec.previous_reading IS NOT NULL THEN
        IF v_bill_rec.current_reading < v_bill_rec.previous_reading THEN
            -- 계량기 교체 등의 경우가 아니라면 오류
            IF v_bill_rec.usage_amount IS NULL OR v_bill_rec.usage_amount != v_bill_rec.current_reading THEN
                v_is_valid := false;
                v_error_details := v_error_details || '{"reading": "검침값이 올바르지 않습니다"}';
            END IF;
        ELSIF v_bill_rec.usage_amount IS NOT NULL AND 
              v_bill_rec.usage_amount != (v_bill_rec.current_reading - v_bill_rec.previous_reading) THEN
            v_is_valid := false;
            v_error_details := v_error_details || '{"usage": "사용량 계산이 올바르지 않습니다"}';
        END IF;
    END IF;
    
    -- 3. 금액 검증
    DECLARE
        v_calculated_total DECIMAL(15,4);
    BEGIN
        v_calculated_total := COALESCE(v_bill_rec.basic_charge, 0) + 
                             COALESCE(v_bill_rec.usage_charge, 0) + 
                             COALESCE(v_bill_rec.additional_charges, 0) + 
                             COALESCE(v_bill_rec.tax_amount, 0);
        
        IF ABS(v_calculated_total - v_bill_rec.total_amount) > 1 THEN  -- 1원 오차 허용
            v_is_valid := false;
            v_error_details := v_error_details || '{"amount": "총 금액 계산이 맞지 않습니다"}';
        END IF;
    END;
    
    -- 4. 날짜 검증
    IF v_bill_rec.due_date < v_bill_rec.issue_date THEN
        v_is_valid := false;
        v_error_details := v_error_details || '{"dates": "납부 기한이 발행일보다 빠릅니다"}';
    END IF;
    
    -- 검증 결과 업데이트
    IF v_is_valid THEN
        v_validation_notes := '모든 검증 항목 통과';
        UPDATE bms.external_bills
        SET is_validated = true,
            validation_status = 'PASSED',
            validation_notes = v_validation_notes,
            validated_at = NOW(),
            has_errors = false,
            error_details = NULL,
            updated_at = NOW()
        WHERE bill_id = p_bill_id;
    ELSE
        v_validation_notes := '검증 실패: ' || (v_error_details::TEXT);
        UPDATE bms.external_bills
        SET is_validated = false,
            validation_status = 'FAILED',
            validation_notes = v_validation_notes,
            validated_at = NOW(),
            has_errors = true,
            error_details = v_error_details,
            updated_at = NOW()
        WHERE bill_id = p_bill_id;
    END IF;
    
    RETURN v_is_valid;
END;
$$ LANGUAGE plpgsql;

-- 10. 외부 고지서 뷰 생성
CREATE OR REPLACE VIEW bms.v_external_bills_summary AS
SELECT 
    eb.bill_id,
    eb.company_id,
    c.company_name,
    up.provider_name,
    up.provider_type,
    eb.bill_number,
    eb.bill_type,
    eb.bill_period_start,
    eb.bill_period_end,
    eb.issue_date,
    eb.due_date,
    eb.usage_amount,
    eb.usage_unit,
    eb.total_amount,
    eb.bill_status,
    eb.payment_status,
    eb.is_validated,
    eb.validation_status,
    eb.has_errors,
    eb.created_at
FROM bms.external_bills eb
JOIN bms.companies c ON eb.company_id = c.company_id
JOIN bms.utility_providers up ON eb.provider_id = up.provider_id
ORDER BY eb.issue_date DESC, up.provider_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_external_bills_summary OWNER TO qiro;