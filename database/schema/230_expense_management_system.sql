-- 지출 관리 시스템 스키마
-- 지출 유형별 분류 및 기록, 시설 관리 비용 연동, 정기 지출 자동 생성 기능

-- 지출 유형 테이블
CREATE TABLE IF NOT EXISTS bms.expense_types (
    expense_type_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    type_code VARCHAR(20) NOT NULL,
    type_name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    is_recurring BOOLEAN DEFAULT false,
    requires_approval BOOLEAN DEFAULT true,
    approval_limit DECIMAL(15,2),
    default_account_id UUID,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, type_code),
    CONSTRAINT chk_expense_category CHECK (category IN ('MAINTENANCE', 'UTILITIES', 'MANAGEMENT', 'FACILITY', 'ADMINISTRATIVE', 'OTHER'))
);

COMMENT ON TABLE bms.expense_types IS '지출 유형 관리 테이블';
COMMENT ON COLUMN bms.expense_types.expense_type_id IS '지출 유형 ID';
COMMENT ON COLUMN bms.expense_types.company_id IS '회사 ID';
COMMENT ON COLUMN bms.expense_types.type_code IS '지출 유형 코드 (MAINTENANCE_COST, UTILITY_BILL, MANAGEMENT_FEE, ETC)';
COMMENT ON COLUMN bms.expense_types.type_name IS '지출 유형명';
COMMENT ON COLUMN bms.expense_types.description IS '지출 유형 설명';
COMMENT ON COLUMN bms.expense_types.category IS '지출 카테고리 (MAINTENANCE, UTILITIES, MANAGEMENT, FACILITY, ADMINISTRATIVE, OTHER)';
COMMENT ON COLUMN bms.expense_types.is_recurring IS '정기 지출 여부';
COMMENT ON COLUMN bms.expense_types.requires_approval IS '승인 필요 여부';
COMMENT ON COLUMN bms.expense_types.approval_limit IS '승인 한도 금액';
COMMENT ON COLUMN bms.expense_types.default_account_id IS '기본 계정과목 ID';
COMMENT ON COLUMN bms.expense_types.is_active IS '활성 상태';

-- 지출 기록 테이블
CREATE TABLE IF NOT EXISTS bms.expense_records (
    expense_record_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    expense_type_id UUID NOT NULL REFERENCES bms.expense_types(expense_type_id),
    building_id UUID,
    unit_id UUID,
    vendor_id UUID,
    expense_date DATE NOT NULL,
    due_date DATE,
    amount DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    payment_method VARCHAR(50),
    bank_account_id UUID,
    reference_number VARCHAR(100),
    invoice_number VARCHAR(100),
    description TEXT,
    status VARCHAR(20) DEFAULT 'PENDING',
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    approved_by UUID,
    approved_at TIMESTAMP,
    paid_at TIMESTAMP,
    journal_entry_id UUID,
    created_by UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_expense_status CHECK (status IN ('PENDING', 'APPROVED', 'PAID', 'CANCELLED')),
    CONSTRAINT chk_approval_status CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED'))
);

COMMENT ON TABLE bms.expense_records IS '지출 기록 테이블';
COMMENT ON COLUMN bms.expense_records.expense_record_id IS '지출 기록 ID';
COMMENT ON COLUMN bms.expense_records.company_id IS '회사 ID';
COMMENT ON COLUMN bms.expense_records.expense_type_id IS '지출 유형 ID';
COMMENT ON COLUMN bms.expense_records.building_id IS '건물 ID';
COMMENT ON COLUMN bms.expense_records.unit_id IS '세대 ID';
COMMENT ON COLUMN bms.expense_records.vendor_id IS '업체 ID';
COMMENT ON COLUMN bms.expense_records.expense_date IS '지출 발생일';
COMMENT ON COLUMN bms.expense_records.due_date IS '지급 기한';
COMMENT ON COLUMN bms.expense_records.amount IS '기본 금액';
COMMENT ON COLUMN bms.expense_records.tax_amount IS '세금 금액';
COMMENT ON COLUMN bms.expense_records.total_amount IS '총 금액';
COMMENT ON COLUMN bms.expense_records.payment_method IS '결제 방법';
COMMENT ON COLUMN bms.expense_records.bank_account_id IS '은행 계좌 ID';
COMMENT ON COLUMN bms.expense_records.reference_number IS '참조 번호';
COMMENT ON COLUMN bms.expense_records.invoice_number IS '송장 번호';
COMMENT ON COLUMN bms.expense_records.description IS '설명';
COMMENT ON COLUMN bms.expense_records.status IS '상태 (PENDING, APPROVED, PAID, CANCELLED)';
COMMENT ON COLUMN bms.expense_records.approval_status IS '승인 상태 (PENDING, APPROVED, REJECTED)';
COMMENT ON COLUMN bms.expense_records.approved_by IS '승인자 ID';
COMMENT ON COLUMN bms.expense_records.approved_at IS '승인일시';
COMMENT ON COLUMN bms.expense_records.paid_at IS '지급일시';
COMMENT ON COLUMN bms.expense_records.journal_entry_id IS '분개 전표 ID';

-- 업체 정보 테이블
CREATE TABLE IF NOT EXISTS bms.vendors (
    vendor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    vendor_code VARCHAR(20) NOT NULL,
    vendor_name VARCHAR(100) NOT NULL,
    business_number VARCHAR(20),
    contact_person VARCHAR(50),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    bank_account VARCHAR(50),
    bank_name VARCHAR(50),
    account_holder VARCHAR(50),
    vendor_type VARCHAR(50),
    payment_terms INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(company_id, vendor_code)
);

COMMENT ON TABLE bms.vendors IS '업체 정보 테이블';
COMMENT ON COLUMN bms.vendors.vendor_id IS '업체 ID';
COMMENT ON COLUMN bms.vendors.company_id IS '회사 ID';
COMMENT ON COLUMN bms.vendors.vendor_code IS '업체 코드';
COMMENT ON COLUMN bms.vendors.vendor_name IS '업체명';
COMMENT ON COLUMN bms.vendors.business_number IS '사업자등록번호';
COMMENT ON COLUMN bms.vendors.contact_person IS '담당자명';
COMMENT ON COLUMN bms.vendors.phone_number IS '전화번호';
COMMENT ON COLUMN bms.vendors.email IS '이메일';
COMMENT ON COLUMN bms.vendors.address IS '주소';
COMMENT ON COLUMN bms.vendors.bank_account IS '계좌번호';
COMMENT ON COLUMN bms.vendors.bank_name IS '은행명';
COMMENT ON COLUMN bms.vendors.account_holder IS '예금주';
COMMENT ON COLUMN bms.vendors.vendor_type IS '업체 유형';
COMMENT ON COLUMN bms.vendors.payment_terms IS '결제 조건 (일)';
COMMENT ON COLUMN bms.vendors.is_active IS '활성 상태';

-- 정기 지출 스케줄 테이블
CREATE TABLE IF NOT EXISTS bms.recurring_expense_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    expense_type_id UUID NOT NULL REFERENCES bms.expense_types(expense_type_id),
    building_id UUID,
    unit_id UUID,
    vendor_id UUID REFERENCES bms.vendors(vendor_id),
    schedule_name VARCHAR(100) NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    interval_value INTEGER DEFAULT 1,
    amount DECIMAL(15,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    next_generation_date DATE NOT NULL,
    last_generated_date DATE,
    auto_approve BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_expense_frequency CHECK (frequency IN ('MONTHLY', 'QUARTERLY', 'SEMI_ANNUALLY', 'ANNUALLY'))
);

COMMENT ON TABLE bms.recurring_expense_schedules IS '정기 지출 스케줄 테이블';
COMMENT ON COLUMN bms.recurring_expense_schedules.schedule_id IS '스케줄 ID';
COMMENT ON COLUMN bms.recurring_expense_schedules.company_id IS '회사 ID';
COMMENT ON COLUMN bms.recurring_expense_schedules.expense_type_id IS '지출 유형 ID';
COMMENT ON COLUMN bms.recurring_expense_schedules.building_id IS '건물 ID';
COMMENT ON COLUMN bms.recurring_expense_schedules.unit_id IS '세대 ID';
COMMENT ON COLUMN bms.recurring_expense_schedules.vendor_id IS '업체 ID';
COMMENT ON COLUMN bms.recurring_expense_schedules.schedule_name IS '스케줄명';
COMMENT ON COLUMN bms.recurring_expense_schedules.frequency IS '주기 (MONTHLY, QUARTERLY, SEMI_ANNUALLY, ANNUALLY)';
COMMENT ON COLUMN bms.recurring_expense_schedules.interval_value IS '간격 값';
COMMENT ON COLUMN bms.recurring_expense_schedules.amount IS '금액';
COMMENT ON COLUMN bms.recurring_expense_schedules.start_date IS '시작일';
COMMENT ON COLUMN bms.recurring_expense_schedules.end_date IS '종료일';
COMMENT ON COLUMN bms.recurring_expense_schedules.next_generation_date IS '다음 생성일';
COMMENT ON COLUMN bms.recurring_expense_schedules.last_generated_date IS '최종 생성일';
COMMENT ON COLUMN bms.recurring_expense_schedules.auto_approve IS '자동 승인 여부';
COMMENT ON COLUMN bms.recurring_expense_schedules.is_active IS '활성 상태';

-- 지출 첨부파일 테이블
CREATE TABLE IF NOT EXISTS bms.expense_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expense_record_id UUID NOT NULL REFERENCES bms.expense_records(expense_record_id),
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_type VARCHAR(50) NOT NULL,
    mime_type VARCHAR(100),
    attachment_type VARCHAR(50) NOT NULL,
    description TEXT,
    uploaded_by UUID NOT NULL,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_attachment_type CHECK (attachment_type IN ('INVOICE', 'RECEIPT', 'CONTRACT', 'ESTIMATE', 'OTHER'))
);

COMMENT ON TABLE bms.expense_attachments IS '지출 첨부파일 테이블';
COMMENT ON COLUMN bms.expense_attachments.attachment_id IS '첨부파일 ID';
COMMENT ON COLUMN bms.expense_attachments.expense_record_id IS '지출 기록 ID';
COMMENT ON COLUMN bms.expense_attachments.file_name IS '파일명';
COMMENT ON COLUMN bms.expense_attachments.file_path IS '파일 경로';
COMMENT ON COLUMN bms.expense_attachments.file_size IS '파일 크기';
COMMENT ON COLUMN bms.expense_attachments.file_type IS '파일 유형';
COMMENT ON COLUMN bms.expense_attachments.mime_type IS 'MIME 타입';
COMMENT ON COLUMN bms.expense_attachments.attachment_type IS '첨부파일 유형 (INVOICE, RECEIPT, CONTRACT, ESTIMATE, OTHER)';
COMMENT ON COLUMN bms.expense_attachments.description IS '설명';
COMMENT ON COLUMN bms.expense_attachments.uploaded_by IS '업로드한 사용자 ID';
COMMENT ON COLUMN bms.expense_attachments.uploaded_at IS '업로드 일시';

-- 시설 관리 비용 연동 테이블
CREATE TABLE IF NOT EXISTS bms.facility_expense_links (
    link_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    expense_record_id UUID NOT NULL REFERENCES bms.expense_records(expense_record_id),
    work_order_id UUID,
    maintenance_task_id UUID,
    facility_id UUID,
    link_type VARCHAR(50) NOT NULL,
    linked_amount DECIMAL(15,2) NOT NULL,
    allocation_ratio DECIMAL(5,4) DEFAULT 1.0000,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_link_type CHECK (link_type IN ('WORK_ORDER', 'MAINTENANCE_TASK', 'FACILITY_REPAIR', 'PREVENTIVE_MAINTENANCE'))
);

COMMENT ON TABLE bms.facility_expense_links IS '시설 관리 비용 연동 테이블';
COMMENT ON COLUMN bms.facility_expense_links.link_id IS '연동 ID';
COMMENT ON COLUMN bms.facility_expense_links.company_id IS '회사 ID';
COMMENT ON COLUMN bms.facility_expense_links.expense_record_id IS '지출 기록 ID';
COMMENT ON COLUMN bms.facility_expense_links.work_order_id IS '작업 지시서 ID';
COMMENT ON COLUMN bms.facility_expense_links.maintenance_task_id IS '유지보수 작업 ID';
COMMENT ON COLUMN bms.facility_expense_links.facility_id IS '시설 ID';
COMMENT ON COLUMN bms.facility_expense_links.link_type IS '연동 유형 (WORK_ORDER, MAINTENANCE_TASK, FACILITY_REPAIR, PREVENTIVE_MAINTENANCE)';
COMMENT ON COLUMN bms.facility_expense_links.linked_amount IS '연동 금액';
COMMENT ON COLUMN bms.facility_expense_links.allocation_ratio IS '배분 비율';
COMMENT ON COLUMN bms.facility_expense_links.notes IS '비고';

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_expense_types_company_id ON bms.expense_types(company_id);
CREATE INDEX IF NOT EXISTS idx_expense_types_category ON bms.expense_types(company_id, category);
CREATE INDEX IF NOT EXISTS idx_expense_types_type_code ON bms.expense_types(company_id, type_code);

CREATE INDEX IF NOT EXISTS idx_expense_records_company_id ON bms.expense_records(company_id);
CREATE INDEX IF NOT EXISTS idx_expense_records_expense_date ON bms.expense_records(company_id, expense_date);
CREATE INDEX IF NOT EXISTS idx_expense_records_status ON bms.expense_records(company_id, status);
CREATE INDEX IF NOT EXISTS idx_expense_records_approval_status ON bms.expense_records(company_id, approval_status);
CREATE INDEX IF NOT EXISTS idx_expense_records_building_unit ON bms.expense_records(company_id, building_id, unit_id);
CREATE INDEX IF NOT EXISTS idx_expense_records_vendor ON bms.expense_records(company_id, vendor_id);

CREATE INDEX IF NOT EXISTS idx_vendors_company_id ON bms.vendors(company_id);
CREATE INDEX IF NOT EXISTS idx_vendors_vendor_code ON bms.vendors(company_id, vendor_code);
CREATE INDEX IF NOT EXISTS idx_vendors_vendor_name ON bms.vendors(company_id, vendor_name);

CREATE INDEX IF NOT EXISTS idx_recurring_expense_schedules_company_id ON bms.recurring_expense_schedules(company_id);
CREATE INDEX IF NOT EXISTS idx_recurring_expense_schedules_next_date ON bms.recurring_expense_schedules(company_id, next_generation_date);
CREATE INDEX IF NOT EXISTS idx_recurring_expense_schedules_active ON bms.recurring_expense_schedules(company_id, is_active);

CREATE INDEX IF NOT EXISTS idx_expense_attachments_expense_record ON bms.expense_attachments(expense_record_id);
CREATE INDEX IF NOT EXISTS idx_expense_attachments_type ON bms.expense_attachments(attachment_type);

CREATE INDEX IF NOT EXISTS idx_facility_expense_links_company_id ON bms.facility_expense_links(company_id);
CREATE INDEX IF NOT EXISTS idx_facility_expense_links_expense_record ON bms.facility_expense_links(expense_record_id);
CREATE INDEX IF NOT EXISTS idx_facility_expense_links_work_order ON bms.facility_expense_links(work_order_id);

-- 지출 승인 처리 함수
CREATE OR REPLACE FUNCTION bms.approve_expense_record(
    p_expense_record_id UUID,
    p_approved_by UUID,
    p_approval_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_expense_record RECORD;
    v_requires_approval BOOLEAN;
    v_approval_limit DECIMAL(15,2);
BEGIN
    -- 지출 기록 조회
    SELECT er.expense_record_id, er.approval_status, er.total_amount, et.requires_approval, et.approval_limit
    INTO v_expense_record
    FROM bms.expense_records er
    JOIN bms.expense_types et ON er.expense_type_id = et.expense_type_id
    WHERE er.expense_record_id = p_expense_record_id;
    
    v_requires_approval := (v_expense_record).requires_approval;
    v_approval_limit := (v_expense_record).approval_limit;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 지출 기록입니다: %', p_expense_record_id;
    END IF;
    
    -- 이미 승인된 경우
    IF (v_expense_record).approval_status = 'APPROVED' THEN
        RETURN FALSE;
    END IF;
    
    -- 승인이 필요하지 않은 경우
    IF NOT v_requires_approval THEN
        RETURN FALSE;
    END IF;
    
    -- 승인 한도 확인 (설정된 경우)
    IF v_approval_limit IS NOT NULL AND (v_expense_record).total_amount > v_approval_limit THEN
        RAISE EXCEPTION '승인 한도를 초과했습니다. 한도: %, 요청 금액: %', v_approval_limit, (v_expense_record).total_amount;
    END IF;
    
    -- 승인 처리
    UPDATE bms.expense_records
    SET approval_status = 'APPROVED',
        approved_by = p_approved_by,
        approved_at = CURRENT_TIMESTAMP,
        status = CASE WHEN status = 'PENDING' THEN 'APPROVED' ELSE status END,
        updated_at = CURRENT_TIMESTAMP
    WHERE expense_record_id = p_expense_record_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.approve_expense_record IS '지출 승인 처리 함수';

-- 지출 거부 처리 함수
CREATE OR REPLACE FUNCTION bms.reject_expense_record(
    p_expense_record_id UUID,
    p_rejected_by UUID,
    p_rejection_reason TEXT
) RETURNS BOOLEAN AS $$
BEGIN
    -- 지출 기록 존재 확인
    IF NOT EXISTS (SELECT 1 FROM bms.expense_records WHERE expense_record_id = p_expense_record_id) THEN
        RAISE EXCEPTION '존재하지 않는 지출 기록입니다: %', p_expense_record_id;
    END IF;
    
    -- 거부 처리
    UPDATE bms.expense_records
    SET approval_status = 'REJECTED',
        status = 'CANCELLED',
        updated_at = CURRENT_TIMESTAMP
    WHERE expense_record_id = p_expense_record_id
      AND approval_status = 'PENDING';
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.reject_expense_record IS '지출 거부 처리 함수';

-- 정기 지출 생성 함수
CREATE OR REPLACE FUNCTION bms.generate_recurring_expense(
    p_schedule_id UUID,
    p_generation_date DATE DEFAULT CURRENT_DATE
) RETURNS UUID AS $$
DECLARE
    v_schedule RECORD;
    v_expense_record_id UUID;
    v_next_date DATE;
    v_due_date DATE;
BEGIN
    -- 스케줄 정보 조회
    SELECT * INTO v_schedule
    FROM bms.recurring_expense_schedules
    WHERE schedule_id = p_schedule_id
      AND is_active = true
      AND next_generation_date <= p_generation_date;
    
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    
    -- 지급 기한 계산 (기본 30일 후)
    v_due_date := p_generation_date + INTERVAL '30 days';
    
    -- 지출 기록 생성
    INSERT INTO bms.expense_records (
        company_id, expense_type_id, building_id, unit_id, vendor_id,
        expense_date, due_date, amount, total_amount, description,
        status, approval_status, created_by
    ) VALUES (
        v_schedule.company_id, v_schedule.expense_type_id, v_schedule.building_id,
        v_schedule.unit_id, v_schedule.vendor_id,
        p_generation_date, v_due_date, v_schedule.amount, v_schedule.amount,
        v_schedule.schedule_name || ' - ' || TO_CHAR(p_generation_date, 'YYYY-MM'),
        CASE WHEN v_schedule.auto_approve THEN 'APPROVED' ELSE 'PENDING' END,
        CASE WHEN v_schedule.auto_approve THEN 'APPROVED' ELSE 'PENDING' END,
        '00000000-0000-0000-0000-000000000000'::UUID -- 시스템 생성
    ) RETURNING expense_record_id INTO v_expense_record_id;
    
    -- 다음 생성일 계산
    CASE v_schedule.frequency
        WHEN 'MONTHLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value || ' months')::INTERVAL;
        WHEN 'QUARTERLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value * 3 || ' months')::INTERVAL;
        WHEN 'SEMI_ANNUALLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value * 6 || ' months')::INTERVAL;
        WHEN 'ANNUALLY' THEN
            v_next_date := v_schedule.next_generation_date + (v_schedule.interval_value || ' years')::INTERVAL;
    END CASE;
    
    -- 스케줄 업데이트
    UPDATE bms.recurring_expense_schedules
    SET next_generation_date = v_next_date,
        last_generated_date = p_generation_date,
        updated_at = CURRENT_TIMESTAMP
    WHERE schedule_id = p_schedule_id;
    
    RETURN v_expense_record_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION bms.generate_recurring_expense IS '정기 지출 생성 함수';