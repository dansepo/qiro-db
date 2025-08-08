-- =====================================================
-- 외부 고지서 관리 시스템 테이블 생성 스크립트
-- Phase 2.3: 외부 고지서 관리 테이블
-- =====================================================

-- 1. 외부 공급업체 정보 테이블
CREATE TABLE IF NOT EXISTS bms.external_suppliers (
    supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 공급업체 기본 정보
    supplier_name VARCHAR(100) NOT NULL,                   -- 공급업체명
    supplier_code VARCHAR(50),                             -- 공급업체 코드
    supplier_type VARCHAR(20) NOT NULL,                    -- 공급업체 유형
    
    -- 연락처 정보
    contact_person VARCHAR(100),                           -- 담당자명
    phone_number VARCHAR(20),                              -- 전화번호
    email VARCHAR(100),                                    -- 이메일
    fax_number VARCHAR(20),                                -- 팩스번호
    
    -- 주소 정보
    address TEXT,                                          -- 주소
    postal_code VARCHAR(10),                               -- 우편번호
    
    -- 사업자 정보
    business_number VARCHAR(20),                           -- 사업자등록번호
    tax_invoice_email VARCHAR(100),                        -- 세금계산서 이메일
    
    -- 계약 정보
    contract_number VARCHAR(50),                           -- 계약번호
    contract_start_date DATE,                              -- 계약 시작일
    contract_end_date DATE,                                -- 계약 종료일
    
    -- 고지서 관련 설정
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY',           -- 고지 주기
    billing_day INTEGER DEFAULT 1,                         -- 고지일
    payment_due_days INTEGER DEFAULT 30,                   -- 납부 기한 (일)
    
    -- 자동화 설정
    auto_import_enabled BOOLEAN DEFAULT false,             -- 자동 가져오기 활성화
    import_method VARCHAR(20),                             -- 가져오기 방법
    api_endpoint TEXT,                                     -- API 엔드포인트
    api_credentials JSONB,                                 -- API 인증 정보 (암호화)
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_suppliers_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_supplier_type CHECK (supplier_type IN (
        'ELECTRIC',            -- 전력회사
        'WATER',               -- 수도회사
        'GAS',                 -- 가스회사
        'HEATING',             -- 난방회사
        'TELECOM',             -- 통신회사
        'WASTE',               -- 폐기물처리업체
        'SECURITY',            -- 보안업체
        'CLEANING',            -- 청소업체
        'MAINTENANCE',         -- 유지보수업체
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_billing_cycle CHECK (billing_cycle IN (
        'MONTHLY',             -- 월별
        'QUARTERLY',           -- 분기별
        'SEMI_ANNUAL',         -- 반기별
        'ANNUAL',              -- 연간
        'IRREGULAR'            -- 불규칙
    )),
    CONSTRAINT chk_import_method CHECK (import_method IN (
        'MANUAL',              -- 수동 입력
        'EMAIL',               -- 이메일 자동 파싱
        'API',                 -- API 연동
        'FILE_UPLOAD',         -- 파일 업로드
        'WEB_SCRAPING'         -- 웹 스크래핑
    )),
    CONSTRAINT chk_billing_day CHECK (billing_day >= 1 AND billing_day <= 31),
    CONSTRAINT chk_payment_due_days CHECK (payment_due_days > 0),
    CONSTRAINT chk_contract_dates CHECK (contract_end_date IS NULL OR contract_end_date >= contract_start_date)
);

-- 2. 외부 고지서 정보 테이블
CREATE TABLE IF NOT EXISTS bms.external_bills (
    bill_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    supplier_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체 고지서
    
    -- 고지서 기본 정보
    bill_number VARCHAR(100) NOT NULL,                     -- 고지서 번호
    bill_type VARCHAR(20) NOT NULL,                        -- 고지서 유형
    bill_period_start DATE NOT NULL,                       -- 고지 기간 시작
    bill_period_end DATE NOT NULL,                         -- 고지 기간 종료
    issue_date DATE NOT NULL,                              -- 발행일
    due_date DATE NOT NULL,                                -- 납부 기한
    
    -- 사용량 정보
    previous_reading DECIMAL(15,4),                        -- 전월 지시수
    current_reading DECIMAL(15,4),                         -- 당월 지시수
    usage_amount DECIMAL(15,4),                            -- 사용량
    usage_unit VARCHAR(20),                                -- 사용량 단위
    
    -- 요금 정보
    basic_charge DECIMAL(15,2) DEFAULT 0,                  -- 기본요금
    usage_charge DECIMAL(15,2) DEFAULT 0,                  -- 사용요금
    additional_charges DECIMAL(15,2) DEFAULT 0,            -- 추가요금
    discount_amount DECIMAL(15,2) DEFAULT 0,               -- 할인금액
    tax_amount DECIMAL(15,2) DEFAULT 0,                    -- 세금
    total_amount DECIMAL(15,2) NOT NULL,                   -- 총 금액
    
    -- 요금 상세 내역 (JSON)
    charge_details JSONB,                                  -- 요금 상세 내역
    
    -- 고지서 파일 정보
    original_file_path TEXT,                               -- 원본 파일 경로
    original_file_name VARCHAR(255),                       -- 원본 파일명
    file_size BIGINT,                                      -- 파일 크기 (bytes)
    file_hash VARCHAR(64),                                 -- 파일 해시 (중복 방지)
    
    -- 처리 상태
    import_status VARCHAR(20) DEFAULT 'PENDING',           -- 가져오기 상태
    import_method VARCHAR(20) NOT NULL,                    -- 가져오기 방법
    imported_at TIMESTAMP WITH TIME ZONE,                 -- 가져온 일시
    imported_by UUID,                                      -- 가져온 사용자
    
    -- 검증 상태
    validation_status VARCHAR(20) DEFAULT 'PENDING',       -- 검증 상태
    validation_errors JSONB,                               -- 검증 오류 내역
    validated_by UUID,                                     -- 검증자
    validated_at TIMESTAMP WITH TIME ZONE,                -- 검증 일시
    
    -- 승인 상태
    approval_status VARCHAR(20) DEFAULT 'PENDING',         -- 승인 상태
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 결제 상태
    payment_status VARCHAR(20) DEFAULT 'UNPAID',           -- 결제 상태
    paid_amount DECIMAL(15,2) DEFAULT 0,                   -- 지불 금액
    paid_date DATE,                                        -- 지불일
    payment_method VARCHAR(20),                            -- 결제 방법
    payment_reference VARCHAR(100),                        -- 결제 참조번호
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_bills_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_bills_supplier FOREIGN KEY (supplier_id) REFERENCES bms.external_suppliers(supplier_id) ON DELETE CASCADE,
    CONSTRAINT fk_bills_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_bills_importer FOREIGN KEY (imported_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_bills_validator FOREIGN KEY (validated_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_bills_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_bills_number_supplier UNIQUE (supplier_id, bill_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_bill_type CHECK (bill_type IN (
        'UTILITY',             -- 공과금
        'MAINTENANCE',         -- 유지보수비
        'SERVICE',             -- 서비스비
        'INSURANCE',           -- 보험료
        'TAX',                 -- 세금
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_import_status CHECK (import_status IN (
        'PENDING',             -- 대기중
        'PROCESSING',          -- 처리중
        'COMPLETED',           -- 완료
        'FAILED',              -- 실패
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_validation_status CHECK (validation_status IN (
        'PENDING',             -- 대기중
        'PASSED',              -- 통과
        'FAILED',              -- 실패
        'MANUAL_REVIEW'        -- 수동 검토 필요
    )),
    CONSTRAINT chk_approval_status CHECK (approval_status IN (
        'PENDING',             -- 대기중
        'APPROVED',            -- 승인
        'REJECTED',            -- 반려
        'AUTO_APPROVED'        -- 자동 승인
    )),
    CONSTRAINT chk_payment_status CHECK (payment_status IN (
        'UNPAID',              -- 미지불
        'PARTIAL',             -- 부분 지불
        'PAID',                -- 지불 완료
        'OVERDUE',             -- 연체
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_payment_method CHECK (payment_method IN (
        'BANK_TRANSFER',       -- 계좌이체
        'CREDIT_CARD',         -- 신용카드
        'DEBIT_CARD',          -- 체크카드
        'CASH',                -- 현금
        'CHECK',               -- 수표
        'AUTO_DEBIT',          -- 자동이체
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_bill_period CHECK (bill_period_end >= bill_period_start),
    CONSTRAINT chk_due_date CHECK (due_date >= issue_date),
    CONSTRAINT chk_total_amount CHECK (total_amount >= 0),
    CONSTRAINT chk_paid_amount CHECK (paid_amount >= 0 AND paid_amount <= total_amount)
);

-- 3. 고지서 처리 이력 테이블
CREATE TABLE IF NOT EXISTS bms.bill_processing_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 처리 정보
    action_type VARCHAR(20) NOT NULL,                      -- 처리 유형
    action_description TEXT,                               -- 처리 설명
    previous_status VARCHAR(20),                           -- 이전 상태
    new_status VARCHAR(20),                                -- 새 상태
    
    -- 처리 결과
    processing_result VARCHAR(20) NOT NULL,                -- 처리 결과
    error_message TEXT,                                    -- 오류 메시지
    processing_details JSONB,                              -- 처리 상세 정보
    
    -- 처리자 정보
    processed_by UUID,                                     -- 처리자
    processing_method VARCHAR(20),                         -- 처리 방법
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_history_bill FOREIGN KEY (bill_id) REFERENCES bms.external_bills(bill_id) ON DELETE CASCADE,
    CONSTRAINT fk_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_history_processor FOREIGN KEY (processed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_action_type CHECK (action_type IN (
        'IMPORT',              -- 가져오기
        'VALIDATE',            -- 검증
        'APPROVE',             -- 승인
        'REJECT',              -- 반려
        'MODIFY',              -- 수정
        'DELETE',              -- 삭제
        'PAYMENT',             -- 결제
        'CANCEL'               -- 취소
    )),
    CONSTRAINT chk_processing_result CHECK (processing_result IN (
        'SUCCESS',             -- 성공
        'FAILED',              -- 실패
        'WARNING',             -- 경고
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_processing_method CHECK (processing_method IN (
        'MANUAL',              -- 수동
        'AUTOMATIC',           -- 자동
        'BATCH',               -- 배치
        'API'                  -- API
    ))
);

-- 4. 고지서 자동 가져오기 설정 테이블
CREATE TABLE IF NOT EXISTS bms.bill_import_configurations (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    supplier_id UUID NOT NULL,
    
    -- 설정 기본 정보
    config_name VARCHAR(100) NOT NULL,                     -- 설정명
    config_description TEXT,                               -- 설정 설명
    
    -- 가져오기 설정
    import_method VARCHAR(20) NOT NULL,                    -- 가져오기 방법
    import_schedule VARCHAR(50),                           -- 가져오기 일정 (cron 표현식)
    
    -- 파일 처리 설정
    file_path_pattern TEXT,                                -- 파일 경로 패턴
    file_name_pattern TEXT,                                -- 파일명 패턴
    file_format VARCHAR(20),                               -- 파일 형식
    encoding VARCHAR(20) DEFAULT 'UTF-8',                  -- 파일 인코딩
    
    -- 파싱 설정
    parsing_rules JSONB,                                   -- 파싱 규칙 (JSON)
    field_mappings JSONB,                                  -- 필드 매핑 (JSON)
    validation_rules JSONB,                                -- 검증 규칙 (JSON)
    
    -- 자동화 설정
    auto_validation BOOLEAN DEFAULT false,                 -- 자동 검증
    auto_approval BOOLEAN DEFAULT false,                   -- 자동 승인
    auto_approval_threshold DECIMAL(15,2),                 -- 자동 승인 임계값
    
    -- 알림 설정
    notification_enabled BOOLEAN DEFAULT true,             -- 알림 활성화
    notification_recipients TEXT[],                        -- 알림 수신자
    notification_conditions JSONB,                         -- 알림 조건
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    last_execution_at TIMESTAMP WITH TIME ZONE,            -- 마지막 실행 시간
    next_execution_at TIMESTAMP WITH TIME ZONE,            -- 다음 실행 시간
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_config_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_config_supplier FOREIGN KEY (supplier_id) REFERENCES bms.external_suppliers(supplier_id) ON DELETE CASCADE,
    CONSTRAINT uk_config_name_company UNIQUE (company_id, config_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_config_import_method CHECK (import_method IN (
        'EMAIL',               -- 이메일
        'FTP',                 -- FTP
        'SFTP',                -- SFTP
        'API',                 -- API
        'WEB_SCRAPING',        -- 웹 스크래핑
        'FILE_WATCH'           -- 파일 감시
    )),
    CONSTRAINT chk_file_format CHECK (file_format IN (
        'PDF',                 -- PDF
        'EXCEL',               -- Excel
        'CSV',                 -- CSV
        'XML',                 -- XML
        'JSON',                -- JSON
        'TEXT',                -- 텍스트
        'IMAGE'                -- 이미지 (OCR)
    ))
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.external_suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.external_bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.bill_processing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.bill_import_configurations ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY external_suppliers_isolation_policy ON bms.external_suppliers
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY external_bills_isolation_policy ON bms.external_bills
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY bill_processing_history_isolation_policy ON bms.bill_processing_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY bill_import_configurations_isolation_policy ON bms.bill_import_configurations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 외부 공급업체 인덱스
CREATE INDEX idx_suppliers_company_id ON bms.external_suppliers(company_id);
CREATE INDEX idx_suppliers_type ON bms.external_suppliers(supplier_type);
CREATE INDEX idx_suppliers_active ON bms.external_suppliers(is_active);
CREATE INDEX idx_suppliers_contract_dates ON bms.external_suppliers(contract_start_date, contract_end_date);

-- 외부 고지서 인덱스
CREATE INDEX idx_bills_company_id ON bms.external_bills(company_id);
CREATE INDEX idx_bills_supplier_id ON bms.external_bills(supplier_id);
CREATE INDEX idx_bills_building_id ON bms.external_bills(building_id);
CREATE INDEX idx_bills_type ON bms.external_bills(bill_type);
CREATE INDEX idx_bills_period ON bms.external_bills(bill_period_start, bill_period_end);
CREATE INDEX idx_bills_issue_date ON bms.external_bills(issue_date DESC);
CREATE INDEX idx_bills_due_date ON bms.external_bills(due_date);
CREATE INDEX idx_bills_import_status ON bms.external_bills(import_status);
CREATE INDEX idx_bills_validation_status ON bms.external_bills(validation_status);
CREATE INDEX idx_bills_approval_status ON bms.external_bills(approval_status);
CREATE INDEX idx_bills_payment_status ON bms.external_bills(payment_status);
CREATE INDEX idx_bills_file_hash ON bms.external_bills(file_hash);

-- 고지서 처리 이력 인덱스
CREATE INDEX idx_history_bill_id ON bms.bill_processing_history(bill_id);
CREATE INDEX idx_history_company_id ON bms.bill_processing_history(company_id);
CREATE INDEX idx_history_action_type ON bms.bill_processing_history(action_type);
CREATE INDEX idx_history_created_at ON bms.bill_processing_history(created_at DESC);

-- 가져오기 설정 인덱스
CREATE INDEX idx_config_company_id ON bms.bill_import_configurations(company_id);
CREATE INDEX idx_config_supplier_id ON bms.bill_import_configurations(supplier_id);
CREATE INDEX idx_config_active ON bms.bill_import_configurations(is_active);
CREATE INDEX idx_config_next_execution ON bms.bill_import_configurations(next_execution_at);

-- 복합 인덱스
CREATE INDEX idx_bills_company_period ON bms.external_bills(company_id, bill_period_start DESC);
CREATE INDEX idx_bills_supplier_period ON bms.external_bills(supplier_id, bill_period_start DESC);
CREATE INDEX idx_bills_status_combo ON bms.external_bills(import_status, validation_status, approval_status);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER external_suppliers_updated_at_trigger
    BEFORE UPDATE ON bms.external_suppliers
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER external_bills_updated_at_trigger
    BEFORE UPDATE ON bms.external_bills
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER bill_import_configurations_updated_at_trigger
    BEFORE UPDATE ON bms.bill_import_configurations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 고지서 관리 뷰 생성
CREATE OR REPLACE VIEW bms.v_external_bills_summary AS
SELECT 
    eb.bill_id,
    eb.company_id,
    c.company_name,
    eb.building_id,
    b.name as building_name,
    es.supplier_name,
    es.supplier_type,
    eb.bill_number,
    eb.bill_type,
    eb.bill_period_start,
    eb.bill_period_end,
    eb.issue_date,
    eb.due_date,
    eb.usage_amount,
    eb.usage_unit,
    eb.total_amount,
    eb.paid_amount,
    eb.import_status,
    eb.validation_status,
    eb.approval_status,
    eb.payment_status,
    CASE 
        WHEN eb.due_date < CURRENT_DATE AND eb.payment_status = 'UNPAID' THEN true
        ELSE false
    END as is_overdue,
    eb.created_at
FROM bms.external_bills eb
JOIN bms.companies c ON eb.company_id = c.company_id
JOIN bms.external_suppliers es ON eb.supplier_id = es.supplier_id
LEFT JOIN bms.buildings b ON eb.building_id = b.building_id
ORDER BY eb.issue_date DESC, c.company_name, es.supplier_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_external_bills_summary OWNER TO qiro;

-- 10. 고지서 처리 함수들
-- 고지서 자동 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_external_bill(p_bill_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_bill_rec RECORD;
    v_validation_errors JSONB := '[]'::jsonb;
    v_is_valid BOOLEAN := true;
BEGIN
    -- 고지서 정보 조회
    SELECT * INTO v_bill_rec
    FROM bms.external_bills
    WHERE bill_id = p_bill_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- 기본 필수 필드 검증
    IF v_bill_rec.bill_number IS NULL OR v_bill_rec.bill_number = '' THEN
        v_validation_errors := v_validation_errors || jsonb_build_object('field', 'bill_number', 'error', '고지서 번호가 없습니다');
        v_is_valid := false;
    END IF;
    
    IF v_bill_rec.total_amount IS NULL OR v_bill_rec.total_amount < 0 THEN
        v_validation_errors := v_validation_errors || jsonb_build_object('field', 'total_amount', 'error', '총 금액이 유효하지 않습니다');
        v_is_valid := false;
    END IF;
    
    IF v_bill_rec.bill_period_start IS NULL OR v_bill_rec.bill_period_end IS NULL THEN
        v_validation_errors := v_validation_errors || jsonb_build_object('field', 'bill_period', 'error', '고지 기간이 설정되지 않았습니다');
        v_is_valid := false;
    END IF;
    
    -- 기간 검증
    IF v_bill_rec.bill_period_start > v_bill_rec.bill_period_end THEN
        v_validation_errors := v_validation_errors || jsonb_build_object('field', 'bill_period', 'error', '고지 기간이 올바르지 않습니다');
        v_is_valid := false;
    END IF;
    
    -- 중복 고지서 검증
    IF EXISTS (
        SELECT 1 FROM bms.external_bills
        WHERE supplier_id = v_bill_rec.supplier_id
          AND bill_number = v_bill_rec.bill_number
          AND bill_id != p_bill_id
          AND import_status != 'CANCELLED'
    ) THEN
        v_validation_errors := v_validation_errors || jsonb_build_object('field', 'bill_number', 'error', '중복된 고지서 번호입니다');
        v_is_valid := false;
    END IF;
    
    -- 검증 결과 업데이트
    UPDATE bms.external_bills
    SET validation_status = CASE WHEN v_is_valid THEN 'PASSED' ELSE 'FAILED' END,
        validation_errors = CASE WHEN v_is_valid THEN NULL ELSE v_validation_errors END,
        validated_at = NOW()
    WHERE bill_id = p_bill_id;
    
    -- 처리 이력 기록
    INSERT INTO bms.bill_processing_history (
        bill_id, company_id, action_type, action_description,
        processing_result, processing_details, processing_method
    ) VALUES (
        p_bill_id, v_bill_rec.company_id, 'VALIDATE', '고지서 자동 검증',
        CASE WHEN v_is_valid THEN 'SUCCESS' ELSE 'FAILED' END,
        jsonb_build_object('validation_errors', v_validation_errors),
        'AUTOMATIC'
    );
    
    RETURN v_is_valid;
END;
$$ LANGUAGE plpgsql;

-- 고지서 자동 승인 함수
CREATE OR REPLACE FUNCTION bms.auto_approve_bill(p_bill_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_bill_rec RECORD;
    v_config_rec RECORD;
    v_can_auto_approve BOOLEAN := false;
BEGIN
    -- 고지서 정보 조회
    SELECT eb.*, es.supplier_id INTO v_bill_rec
    FROM bms.external_bills eb
    JOIN bms.external_suppliers es ON eb.supplier_id = es.supplier_id
    WHERE eb.bill_id = p_bill_id
      AND eb.validation_status = 'PASSED';
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- 자동 승인 설정 조회
    SELECT * INTO v_config_rec
    FROM bms.bill_import_configurations
    WHERE supplier_id = v_bill_rec.supplier_id
      AND auto_approval = true
      AND is_active = true;
    
    IF FOUND THEN
        -- 임계값 검증
        IF v_config_rec.auto_approval_threshold IS NULL OR 
           v_bill_rec.total_amount <= v_config_rec.auto_approval_threshold THEN
            v_can_auto_approve := true;
        END IF;
    END IF;
    
    -- 자동 승인 실행
    IF v_can_auto_approve THEN
        UPDATE bms.external_bills
        SET approval_status = 'AUTO_APPROVED',
            approved_at = NOW()
        WHERE bill_id = p_bill_id;
        
        -- 처리 이력 기록
        INSERT INTO bms.bill_processing_history (
            bill_id, company_id, action_type, action_description,
            processing_result, processing_method
        ) VALUES (
            p_bill_id, v_bill_rec.company_id, 'APPROVE', '고지서 자동 승인',
            'SUCCESS', 'AUTOMATIC'
        );
        
        RETURN true;
    END IF;
    
    RETURN false;
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 2.3 외부 고지서 관리 테이블 생성이 완료되었습니다!' as result;