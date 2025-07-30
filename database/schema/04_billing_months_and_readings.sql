-- =====================================================
-- 월별 관리비 처리 워크플로우 - 청구월 및 검침 데이터
-- =====================================================

-- 청구월 상태 ENUM
CREATE TYPE billing_month_status AS ENUM (
    'DRAFT',        -- 초안 (생성됨)
    'DATA_INPUT',   -- 데이터 입력 중
    'CALCULATING',  -- 계산 중
    'CALCULATED',   -- 계산 완료
    'INVOICED',     -- 고지서 발급 완료
    'CLOSED'        -- 마감
);

-- 검침 데이터 유형 ENUM
CREATE TYPE meter_type AS ENUM (
    'ELECTRICITY',  -- 전기
    'WATER',        -- 수도
    'GAS',          -- 가스
    'HEATING',      -- 난방
    'HOT_WATER',    -- 온수
    'COMMON_ELECTRICITY', -- 공용전기
    'COMMON_WATER'  -- 공용수도
);

-- 청구월 관리 테이블
CREATE TABLE billing_months (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    billing_year INTEGER NOT NULL CHECK (billing_year >= 2020 AND billing_year <= 2100),
    billing_month INTEGER NOT NULL CHECK (billing_month >= 1 AND billing_month <= 12),
    status billing_month_status DEFAULT 'DRAFT' NOT NULL,
    
    -- 청구월 메타데이터
    due_date DATE NOT NULL,
    calculation_completed_at TIMESTAMP,
    invoice_generation_completed_at TIMESTAMP,
    closed_at TIMESTAMP,
    
    -- 외부 고지서 총액 (한전, 수도 등)
    external_bill_total_amount DECIMAL(15,2) DEFAULT 0 CHECK (external_bill_total_amount >= 0),
    external_bill_input_completed BOOLEAN DEFAULT false,
    
    -- 검침 데이터 입력 완료 여부
    meter_reading_completed BOOLEAN DEFAULT false,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    
    -- 제약조건
    UNIQUE(building_id, billing_year, billing_month),
    
    -- 상태 전환 검증
    CONSTRAINT check_calculation_completed_when_calculated 
        CHECK (status != 'CALCULATED' OR calculation_completed_at IS NOT NULL),
    CONSTRAINT check_invoice_completed_when_invoiced 
        CHECK (status != 'INVOICED' OR invoice_generation_completed_at IS NOT NULL),
    CONSTRAINT check_closed_when_closed 
        CHECK (status != 'CLOSED' OR closed_at IS NOT NULL)
);

-- 청구월 테이블 인덱스
CREATE INDEX idx_billing_months_building_year_month ON billing_months(building_id, billing_year, billing_month);
CREATE INDEX idx_billing_months_status ON billing_months(status);
CREATE INDEX idx_billing_months_due_date ON billing_months(due_date);
CREATE INDEX idx_billing_months_created_at ON billing_months(created_at);

-- 호실별 검침 데이터 테이블
CREATE TABLE unit_meter_readings (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    meter_type meter_type NOT NULL,
    
    -- 검침 데이터
    previous_reading DECIMAL(12,3) CHECK (previous_reading >= 0),
    current_reading DECIMAL(12,3) CHECK (current_reading >= 0),
    usage_amount DECIMAL(12,3) GENERATED ALWAYS AS (
        CASE 
            WHEN current_reading IS NOT NULL AND previous_reading IS NOT NULL 
            THEN current_reading - previous_reading
            ELSE NULL
        END
    ) STORED,
    
    -- 단가 정보 (해당 월 기준)
    unit_price DECIMAL(10,4) CHECK (unit_price >= 0),
    calculated_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        CASE 
            WHEN usage_amount IS NOT NULL AND unit_price IS NOT NULL 
            THEN usage_amount * unit_price
            ELSE NULL
        END
    ) STORED,
    
    -- 검침 메타데이터
    reading_date DATE,
    meter_serial_number VARCHAR(50),
    reader_name VARCHAR(100),
    notes TEXT,
    
    -- 데이터 검증 플래그
    is_estimated BOOLEAN DEFAULT false, -- 추정 검침 여부
    is_verified BOOLEAN DEFAULT false,  -- 검증 완료 여부
    verification_notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    
    -- 제약조건
    UNIQUE(billing_month_id, unit_id, meter_type),
    
    -- 검침 데이터 유효성 검증
    CONSTRAINT check_current_reading_gte_previous 
        CHECK (current_reading IS NULL OR previous_reading IS NULL OR current_reading >= previous_reading),
    CONSTRAINT check_usage_amount_positive 
        CHECK (usage_amount IS NULL OR usage_amount >= 0),
    CONSTRAINT check_reading_date_reasonable 
        CHECK (reading_date IS NULL OR reading_date >= '2020-01-01' AND reading_date <= CURRENT_DATE + INTERVAL '1 month')
);

-- 검침 데이터 테이블 인덱스
CREATE INDEX idx_unit_meter_readings_billing_month ON unit_meter_readings(billing_month_id);
CREATE INDEX idx_unit_meter_readings_unit ON unit_meter_readings(unit_id);
CREATE INDEX idx_unit_meter_readings_type ON unit_meter_readings(meter_type);
CREATE INDEX idx_unit_meter_readings_billing_unit_type ON unit_meter_readings(billing_month_id, unit_id, meter_type);
CREATE INDEX idx_unit_meter_readings_reading_date ON unit_meter_readings(reading_date);
CREATE INDEX idx_unit_meter_readings_verification ON unit_meter_readings(is_verified) WHERE is_verified = false;

-- 공용 시설 검침 데이터 테이블
CREATE TABLE common_meter_readings (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    meter_type meter_type NOT NULL,
    
    -- 검침 데이터
    previous_reading DECIMAL(12,3) CHECK (previous_reading >= 0),
    current_reading DECIMAL(12,3) CHECK (current_reading >= 0),
    usage_amount DECIMAL(12,3) GENERATED ALWAYS AS (
        CASE 
            WHEN current_reading IS NOT NULL AND previous_reading IS NOT NULL 
            THEN current_reading - previous_reading
            ELSE NULL
        END
    ) STORED,
    
    -- 단가 및 총액 정보
    unit_price DECIMAL(10,4) CHECK (unit_price >= 0),
    total_amount DECIMAL(15,2) CHECK (total_amount >= 0),
    
    -- 검침 메타데이터
    reading_date DATE,
    meter_serial_number VARCHAR(50),
    meter_location VARCHAR(200),
    reader_name VARCHAR(100),
    notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    
    -- 제약조건
    UNIQUE(billing_month_id, building_id, meter_type, meter_serial_number),
    
    -- 검침 데이터 유효성 검증
    CONSTRAINT check_common_current_reading_gte_previous 
        CHECK (current_reading IS NULL OR previous_reading IS NULL OR current_reading >= previous_reading),
    CONSTRAINT check_common_usage_amount_positive 
        CHECK (usage_amount IS NULL OR usage_amount >= 0)
);

-- 공용 검침 데이터 테이블 인덱스
CREATE INDEX idx_common_meter_readings_billing_month ON common_meter_readings(billing_month_id);
CREATE INDEX idx_common_meter_readings_building ON common_meter_readings(building_id);
CREATE INDEX idx_common_meter_readings_type ON common_meter_readings(meter_type);

-- 월별 데이터 분할을 위한 파티션 테이블 (향후 확장용)
-- 대용량 데이터 처리를 위해 연도별로 파티션 분할 가능하도록 설계

-- 청구월 상태 변경 이력 테이블
CREATE TABLE billing_month_status_history (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    from_status billing_month_status,
    to_status billing_month_status NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    changed_by BIGINT REFERENCES users(id),
    change_reason TEXT,
    
    -- 인덱스
    INDEX idx_billing_month_status_history_billing_month (billing_month_id),
    INDEX idx_billing_month_status_history_changed_at (changed_at)
);

-- 검침 데이터 유효성 검증을 위한 함수
CREATE OR REPLACE FUNCTION validate_meter_reading_consistency()
RETURNS TRIGGER AS $$
BEGIN
    -- 이전 월의 현재 검침값과 이번 월의 이전 검침값이 일치하는지 확인
    IF NEW.previous_reading IS NOT NULL THEN
        -- 이전 월 데이터 조회 및 검증 로직
        -- (실제 구현에서는 더 복잡한 검증 로직 필요)
        NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 검침 데이터 검증 트리거
CREATE TRIGGER trigger_validate_meter_reading_consistency
    BEFORE INSERT OR UPDATE ON unit_meter_readings
    FOR EACH ROW
    EXECUTE FUNCTION validate_meter_reading_consistency();

-- 청구월 상태 변경 이력 기록 함수
CREATE OR REPLACE FUNCTION record_billing_month_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO billing_month_status_history (
            billing_month_id, 
            from_status, 
            to_status, 
            changed_by
        ) VALUES (
            NEW.id, 
            OLD.status, 
            NEW.status, 
            NEW.updated_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 청구월 상태 변경 이력 트리거
CREATE TRIGGER trigger_record_billing_month_status_change
    AFTER UPDATE ON billing_months
    FOR EACH ROW
    EXECUTE FUNCTION record_billing_month_status_change();

-- 데이터 아카이빙을 위한 뷰 (3년 이상 된 데이터)
CREATE VIEW archivable_billing_data AS
SELECT 
    bm.id as billing_month_id,
    bm.building_id,
    bm.billing_year,
    bm.billing_month,
    bm.status,
    bm.created_at
FROM billing_months bm
WHERE bm.billing_year <= EXTRACT(YEAR FROM CURRENT_DATE) - 3
  AND bm.status = 'CLOSED';

-- 검침 데이터 통계 뷰
CREATE VIEW meter_reading_statistics AS
SELECT 
    bm.building_id,
    bm.billing_year,
    bm.billing_month,
    umr.meter_type,
    COUNT(*) as total_readings,
    COUNT(CASE WHEN umr.is_estimated THEN 1 END) as estimated_readings,
    COUNT(CASE WHEN umr.is_verified THEN 1 END) as verified_readings,
    AVG(umr.usage_amount) as avg_usage,
    SUM(umr.calculated_amount) as total_amount
FROM billing_months bm
JOIN unit_meter_readings umr ON bm.id = umr.billing_month_id
GROUP BY bm.building_id, bm.billing_year, bm.billing_month, umr.meter_type;

-- 코멘트 추가
COMMENT ON TABLE billing_months IS '청구월 관리 테이블 - 월별 관리비 처리 워크플로우의 중심';
COMMENT ON TABLE unit_meter_readings IS '호실별 검침 데이터 테이블 - 전기, 수도, 가스 등 개별 검침';
COMMENT ON TABLE common_meter_readings IS '공용 시설 검침 데이터 테이블 - 공용 전기, 수도 등';
COMMENT ON TABLE billing_month_status_history IS '청구월 상태 변경 이력 테이블';

COMMENT ON COLUMN billing_months.status IS '청구월 처리 상태 (DRAFT -> DATA_INPUT -> CALCULATING -> CALCULATED -> INVOICED -> CLOSED)';
COMMENT ON COLUMN billing_months.external_bill_total_amount IS '외부 고지서 총액 (한전, 수도 등)';
COMMENT ON COLUMN unit_meter_readings.usage_amount IS '사용량 (현재검침 - 이전검침, 자동계산)';
COMMENT ON COLUMN unit_meter_readings.calculated_amount IS '계산된 금액 (사용량 × 단가, 자동계산)';
COMMENT ON COLUMN unit_meter_readings.is_estimated IS '추정 검침 여부 (실제 검침이 불가능한 경우)';
-- ===
==================================================
-- 관리비 산정 및 고지서 테이블
-- =====================================================

-- 고지서 상태 ENUM
CREATE TYPE invoice_status AS ENUM (
    'DRAFT',        -- 초안
    'ISSUED',       -- 발급됨
    'SENT',         -- 발송됨
    'VIEWED',       -- 열람됨
    'PAID',         -- 납부완료
    'OVERDUE',      -- 연체
    'CANCELLED'     -- 취소됨
);

-- 관리비 계산 방식 ENUM
CREATE TYPE fee_calculation_method AS ENUM (
    'FIXED_AMOUNT',     -- 고정금액
    'UNIT_BASED',       -- 단위기준 (면적, 세대수 등)
    'USAGE_BASED',      -- 사용량기준 (검침데이터)
    'RATIO_BASED',      -- 비율기준 (총액 배분)
    'EXTERNAL_BILL'     -- 외부고지서 연동
);

-- 월별 관리비 산정 결과 테이블
CREATE TABLE monthly_fees (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id) ON DELETE RESTRICT,
    
    -- 계산 기준 정보
    calculation_method fee_calculation_method NOT NULL,
    base_amount DECIMAL(15,2), -- 기준 금액 (총액 등)
    unit_price DECIMAL(12,4),  -- 단가
    quantity DECIMAL(12,3),    -- 수량 (면적, 사용량 등)
    ratio_percentage DECIMAL(5,2), -- 배분 비율 (%)
    
    -- 계산 결과
    calculated_amount DECIMAL(12,2) NOT NULL CHECK (calculated_amount >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    final_amount DECIMAL(12,2) GENERATED ALWAYS AS (calculated_amount + tax_amount) STORED,
    
    -- 계산 메타데이터
    calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    calculation_notes TEXT,
    is_manual_adjustment BOOLEAN DEFAULT false,
    adjustment_reason TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    
    -- 제약조건
    UNIQUE(billing_month_id, unit_id, fee_item_id),
    
    -- 계산 방식별 필수 필드 검증
    CONSTRAINT check_fixed_amount_calculation 
        CHECK (calculation_method != 'FIXED_AMOUNT' OR calculated_amount IS NOT NULL),
    CONSTRAINT check_unit_based_calculation 
        CHECK (calculation_method != 'UNIT_BASED' OR (unit_price IS NOT NULL AND quantity IS NOT NULL)),
    CONSTRAINT check_usage_based_calculation 
        CHECK (calculation_method != 'USAGE_BASED' OR (unit_price IS NOT NULL AND quantity IS NOT NULL)),
    CONSTRAINT check_ratio_based_calculation 
        CHECK (calculation_method != 'RATIO_BASED' OR (base_amount IS NOT NULL AND ratio_percentage IS NOT NULL)),
    CONSTRAINT check_ratio_percentage_valid 
        CHECK (ratio_percentage IS NULL OR (ratio_percentage >= 0 AND ratio_percentage <= 100)),
    CONSTRAINT check_manual_adjustment_reason 
        CHECK (is_manual_adjustment = false OR adjustment_reason IS NOT NULL)
);

-- 월별 관리비 테이블 인덱스
CREATE INDEX idx_monthly_fees_billing_month ON monthly_fees(billing_month_id);
CREATE INDEX idx_monthly_fees_unit ON monthly_fees(unit_id);
CREATE INDEX idx_monthly_fees_fee_item ON monthly_fees(fee_item_id);
CREATE INDEX idx_monthly_fees_calculation_method ON monthly_fees(calculation_method);
CREATE INDEX idx_monthly_fees_manual_adjustment ON monthly_fees(is_manual_adjustment) WHERE is_manual_adjustment = true;

-- 관리비 계산 검증 테이블 (복식부기 원칙 적용)
CREATE TABLE fee_calculation_verification (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    fee_item_id BIGINT NOT NULL REFERENCES fee_items(id) ON DELETE RESTRICT,
    
    -- 총액 검증
    total_base_amount DECIMAL(15,2), -- 배분 기준 총액
    total_calculated_amount DECIMAL(15,2) NOT NULL, -- 계산된 총액
    total_allocated_amount DECIMAL(15,2) NOT NULL, -- 실제 배분된 총액
    variance_amount DECIMAL(15,2) GENERATED ALWAYS AS (total_calculated_amount - total_allocated_amount) STORED,
    
    -- 검증 결과
    is_balanced BOOLEAN GENERATED ALWAYS AS (ABS(variance_amount) < 0.01) STORED,
    verification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_by BIGINT REFERENCES users(id),
    
    -- 제약조건
    UNIQUE(billing_month_id, fee_item_id)
);

-- 고지서 테이블
CREATE TABLE invoices (
    id BIGSERIAL PRIMARY KEY,
    billing_month_id BIGINT NOT NULL REFERENCES billing_months(id) ON DELETE CASCADE,
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE CASCADE,
    
    -- 고지서 기본 정보
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    issue_date DATE DEFAULT CURRENT_DATE NOT NULL,
    due_date DATE NOT NULL,
    
    -- 금액 정보
    subtotal_amount DECIMAL(12,2) NOT NULL CHECK (subtotal_amount >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(12,2) GENERATED ALWAYS AS (subtotal_amount + tax_amount) STORED,
    
    -- 이전 미납액
    previous_balance DECIMAL(12,2) DEFAULT 0 CHECK (previous_balance >= 0),
    late_fee DECIMAL(12,2) DEFAULT 0 CHECK (late_fee >= 0),
    
    -- 최종 청구 금액
    final_amount DECIMAL(12,2) GENERATED ALWAYS AS (total_amount + previous_balance + late_fee) STORED,
    
    -- 고지서 상태
    status invoice_status DEFAULT 'DRAFT' NOT NULL,
    
    -- 발송 정보
    delivery_method VARCHAR(20), -- EMAIL, SMS, POSTAL, ONLINE
    delivery_address TEXT,
    sent_at TIMESTAMP,
    viewed_at TIMESTAMP,
    
    -- 납부 정보
    paid_amount DECIMAL(12,2) DEFAULT 0 CHECK (paid_amount >= 0),
    remaining_amount DECIMAL(12,2) GENERATED ALWAYS AS (final_amount - paid_amount) STORED,
    fully_paid_at TIMESTAMP,
    
    -- 메모 및 특이사항
    notes TEXT,
    special_instructions TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by BIGINT REFERENCES users(id),
    updated_by BIGINT REFERENCES users(id),
    
    -- 제약조건
    UNIQUE(billing_month_id, unit_id),
    CONSTRAINT check_due_date_after_issue_date CHECK (due_date >= issue_date),
    CONSTRAINT check_paid_amount_not_exceed_final CHECK (paid_amount <= final_amount),
    CONSTRAINT check_sent_when_sent_status CHECK (status != 'SENT' OR sent_at IS NOT NULL),
    CONSTRAINT check_viewed_when_viewed_status CHECK (status != 'VIEWED' OR viewed_at IS NOT NULL),
    CONSTRAINT check_fully_paid_when_paid_status CHECK (status != 'PAID' OR fully_paid_at IS NOT NULL)
);

-- 고지서 테이블 인덱스
CREATE INDEX idx_invoices_billing_month ON invoices(billing_month_id);
CREATE INDEX idx_invoices_unit ON invoices(unit_id);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_invoices_issue_date ON invoices(issue_date);
CREATE INDEX idx_invoices_remaining_amount ON invoices(remaining_amount) WHERE remaining_amount > 0;

-- 고지서 상세 항목 테이블
CREATE TABLE invoice_line_items (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    monthly_fee_id BIGINT NOT NULL REFERENCES monthly_fees(id) ON DELETE CASCADE,
    
    -- 항목 정보
    fee_item_name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- 금액 정보
    quantity DECIMAL(12,3),
    unit_price DECIMAL(12,4),
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    tax_rate DECIMAL(5,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    line_total DECIMAL(12,2) GENERATED ALWAYS AS (amount + tax_amount) STORED,
    
    -- 정렬 순서
    display_order INTEGER DEFAULT 0,
    
    -- 제약조건
    UNIQUE(invoice_id, monthly_fee_id)
);

-- 고지서 상세 항목 인덱스
CREATE INDEX idx_invoice_line_items_invoice ON invoice_line_items(invoice_id);
CREATE INDEX idx_invoice_line_items_monthly_fee ON invoice_line_items(monthly_fee_id);
CREATE INDEX idx_invoice_line_items_display_order ON invoice_line_items(invoice_id, display_order);

-- 고지서 상태 변경 이력 테이블
CREATE TABLE invoice_status_history (
    id BIGSERIAL PRIMARY KEY,
    invoice_id BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    from_status invoice_status,
    to_status invoice_status NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    changed_by BIGINT REFERENCES users(id),
    change_reason TEXT,
    
    INDEX idx_invoice_status_history_invoice (invoice_id),
    INDEX idx_invoice_status_history_changed_at (changed_at)
);

-- 관리비 계산 결과 검증 함수
CREATE OR REPLACE FUNCTION verify_fee_calculation_balance()
RETURNS TRIGGER AS $$
DECLARE
    total_calculated DECIMAL(15,2);
    total_allocated DECIMAL(15,2);
    base_amount DECIMAL(15,2);
BEGIN
    -- 해당 청구월, 관리비 항목의 총 계산 금액 조회
    SELECT 
        COALESCE(SUM(mf.calculated_amount), 0),
        MAX(CASE WHEN mf.calculation_method = 'RATIO_BASED' THEN mf.base_amount END)
    INTO total_allocated, base_amount
    FROM monthly_fees mf
    WHERE mf.billing_month_id = NEW.billing_month_id 
      AND mf.fee_item_id = NEW.fee_item_id;
    
    -- 검증 레코드 업데이트 또는 생성
    INSERT INTO fee_calculation_verification (
        billing_month_id, 
        fee_item_id, 
        total_base_amount,
        total_calculated_amount,
        total_allocated_amount,
        verified_by
    ) VALUES (
        NEW.billing_month_id, 
        NEW.fee_item_id, 
        base_amount,
        COALESCE(base_amount, total_allocated),
        total_allocated,
        NEW.updated_by
    )
    ON CONFLICT (billing_month_id, fee_item_id) 
    DO UPDATE SET
        total_base_amount = EXCLUDED.total_base_amount,
        total_calculated_amount = EXCLUDED.total_calculated_amount,
        total_allocated_amount = EXCLUDED.total_allocated_amount,
        verification_date = CURRENT_TIMESTAMP,
        verified_by = EXCLUDED.verified_by;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 관리비 계산 검증 트리거
CREATE TRIGGER trigger_verify_fee_calculation_balance
    AFTER INSERT OR UPDATE OR DELETE ON monthly_fees
    FOR EACH ROW
    EXECUTE FUNCTION verify_fee_calculation_balance();

-- 고지서 상태 변경 이력 기록 함수
CREATE OR REPLACE FUNCTION record_invoice_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO invoice_status_history (
            invoice_id, 
            from_status, 
            to_status, 
            changed_by
        ) VALUES (
            NEW.id, 
            OLD.status, 
            NEW.status, 
            NEW.updated_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 고지서 상태 변경 이력 트리거
CREATE TRIGGER trigger_record_invoice_status_change
    AFTER UPDATE ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION record_invoice_status_change();

-- 고지서 번호 자동 생성 함수
CREATE OR REPLACE FUNCTION generate_invoice_number(
    p_building_id BIGINT,
    p_billing_year INTEGER,
    p_billing_month INTEGER
) RETURNS VARCHAR(50) AS $$
DECLARE
    sequence_num INTEGER;
    invoice_number VARCHAR(50);
BEGIN
    -- 해당 건물, 연월의 순번 조회
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(invoice_number FROM '[0-9]+$') AS INTEGER)
    ), 0) + 1
    INTO sequence_num
    FROM invoices i
    JOIN billing_months bm ON i.billing_month_id = bm.id
    WHERE bm.building_id = p_building_id
      AND bm.billing_year = p_billing_year
      AND bm.billing_month = p_billing_month;
    
    -- 고지서 번호 생성 (예: B001-2024-03-0001)
    invoice_number := FORMAT('B%03d-%04d-%02d-%04d', 
        p_building_id, p_billing_year, p_billing_month, sequence_num);
    
    RETURN invoice_number;
END;
$$ LANGUAGE plpgsql;

-- 관리비 산정 현황 뷰
CREATE VIEW monthly_fee_summary AS
SELECT 
    bm.building_id,
    bm.billing_year,
    bm.billing_month,
    fi.name as fee_item_name,
    fi.fee_type,
    COUNT(mf.id) as unit_count,
    SUM(mf.calculated_amount) as total_calculated,
    SUM(mf.tax_amount) as total_tax,
    SUM(mf.final_amount) as total_final,
    AVG(mf.final_amount) as avg_amount_per_unit,
    fcv.is_balanced,
    fcv.variance_amount
FROM billing_months bm
JOIN monthly_fees mf ON bm.id = mf.billing_month_id
JOIN fee_items fi ON mf.fee_item_id = fi.id
LEFT JOIN fee_calculation_verification fcv ON bm.id = fcv.billing_month_id AND fi.id = fcv.fee_item_id
GROUP BY bm.building_id, bm.billing_year, bm.billing_month, fi.id, fi.name, fi.fee_type, fcv.is_balanced, fcv.variance_amount;

-- 고지서 발급 현황 뷰
CREATE VIEW invoice_issuance_summary AS
SELECT 
    bm.building_id,
    bm.billing_year,
    bm.billing_month,
    COUNT(i.id) as total_invoices,
    COUNT(CASE WHEN i.status = 'ISSUED' THEN 1 END) as issued_count,
    COUNT(CASE WHEN i.status = 'SENT' THEN 1 END) as sent_count,
    COUNT(CASE WHEN i.status = 'PAID' THEN 1 END) as paid_count,
    COUNT(CASE WHEN i.status = 'OVERDUE' THEN 1 END) as overdue_count,
    SUM(i.total_amount) as total_billed,
    SUM(i.paid_amount) as total_collected,
    SUM(i.remaining_amount) as total_outstanding
FROM billing_months bm
JOIN invoices i ON bm.id = i.billing_month_id
GROUP BY bm.building_id, bm.billing_year, bm.billing_month;

-- 코멘트 추가
COMMENT ON TABLE monthly_fees IS '월별 관리비 산정 결과 테이블 - 호실별, 항목별 계산 결과';
COMMENT ON TABLE fee_calculation_verification IS '관리비 계산 검증 테이블 - 복식부기 원칙 적용';
COMMENT ON TABLE invoices IS '고지서 테이블 - 월별 관리비 고지서';
COMMENT ON TABLE invoice_line_items IS '고지서 상세 항목 테이블';
COMMENT ON TABLE invoice_status_history IS '고지서 상태 변경 이력 테이블';

COMMENT ON COLUMN monthly_fees.calculation_method IS '계산 방식 (고정금액, 단위기준, 사용량기준, 비율기준, 외부고지서)';
COMMENT ON COLUMN monthly_fees.final_amount IS '최종 금액 (계산금액 + 세금, 자동계산)';
COMMENT ON COLUMN invoices.invoice_number IS '고지서 번호 (건물별 연월 순번)';
COMMENT ON COLUMN invoices.final_amount IS '최종 청구 금액 (관리비 + 이전미납 + 연체료, 자동계산)';
COMMENT ON COLUMN invoices.remaining_amount IS '미납 금액 (최종청구 - 납부금액, 자동계산)';