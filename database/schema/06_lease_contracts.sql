-- ============================================================================
-- 임대차 관리 워크플로우 - 임대 계약 관리 테이블
-- ============================================================================

-- 임대 계약 상태 ENUM 타입
CREATE TYPE lease_contract_status AS ENUM (
    'DRAFT',        -- 초안
    'ACTIVE',       -- 활성
    'EXPIRED',      -- 만료
    'TERMINATED',   -- 중도해지
    'RENEWED'       -- 갱신됨
);

-- 계약 유형 ENUM 타입
CREATE TYPE contract_type AS ENUM (
    'NEW',          -- 신규계약
    'RENEWAL',      -- 갱신계약
    'TRANSFER'      -- 승계계약
);

-- 임대 계약 테이블
CREATE TABLE lease_contracts (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    contract_number VARCHAR(50) UNIQUE NOT NULL,  -- 계약번호
    unit_id BIGINT NOT NULL REFERENCES units(id) ON DELETE RESTRICT,
    tenant_id BIGINT NOT NULL REFERENCES tenants(id) ON DELETE RESTRICT,
    lessor_id BIGINT NOT NULL REFERENCES lessors(id) ON DELETE RESTRICT,
    
    -- 계약 기간
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- 금액 정보
    monthly_rent DECIMAL(12,2) NOT NULL CHECK (monthly_rent >= 0),
    deposit DECIMAL(12,2) NOT NULL CHECK (deposit >= 0),
    maintenance_fee DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_fee >= 0),
    
    -- 계약 조건
    contract_type contract_type NOT NULL DEFAULT 'NEW',
    contract_terms TEXT,
    special_conditions TEXT,
    
    -- 상태 관리
    status lease_contract_status NOT NULL DEFAULT 'DRAFT',
    
    -- 이전 계약 연결 (갱신/승계의 경우)
    previous_contract_id BIGINT REFERENCES lease_contracts(id),
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT chk_lease_contract_dates CHECK (end_date > start_date),
    CONSTRAINT chk_lease_contract_amounts CHECK (monthly_rent > 0 OR deposit > 0)
);

-- 계약 상태 변경 이력 테이블
CREATE TABLE lease_contract_status_history (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE CASCADE,
    
    -- 상태 변경 정보
    previous_status lease_contract_status,
    new_status lease_contract_status NOT NULL,
    change_reason VARCHAR(255),
    change_description TEXT,
    
    -- 변경자 정보
    changed_by BIGINT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 관련 문서
    supporting_documents JSONB
);

-- 계약 갱신 알림 설정 테이블
CREATE TABLE lease_contract_renewal_alerts (
    id BIGSERIAL PRIMARY KEY,
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE CASCADE,
    
    -- 알림 설정
    alert_days_before INTEGER NOT NULL DEFAULT 30,  -- 만료 며칠 전 알림
    is_enabled BOOLEAN DEFAULT true,
    
    -- 알림 대상
    notify_lessor BOOLEAN DEFAULT true,
    notify_tenant BOOLEAN DEFAULT true,
    notify_manager BOOLEAN DEFAULT true,
    
    -- 알림 이력
    last_notification_sent_at TIMESTAMP,
    notification_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 인덱스 설계
-- ============================================================================

-- 기본 조회 성능을 위한 인덱스
CREATE INDEX idx_lease_contracts_unit_id ON lease_contracts(unit_id);
CREATE INDEX idx_lease_contracts_tenant_id ON lease_contracts(tenant_id);
CREATE INDEX idx_lease_contracts_lessor_id ON lease_contracts(lessor_id);
CREATE INDEX idx_lease_contracts_status ON lease_contracts(status);

-- 계약 기간 조회를 위한 인덱스
CREATE INDEX idx_lease_contracts_dates ON lease_contracts(start_date, end_date);
CREATE INDEX idx_lease_contracts_end_date ON lease_contracts(end_date) WHERE status = 'ACTIVE';

-- 계약번호 조회를 위한 인덱스
CREATE INDEX idx_lease_contracts_contract_number ON lease_contracts(contract_number);

-- 계약 중복 방지를 위한 복합 인덱스
CREATE UNIQUE INDEX idx_lease_contracts_unit_period_unique 
ON lease_contracts(unit_id, start_date, end_date) 
WHERE status IN ('ACTIVE', 'DRAFT');

-- 상태 이력 조회를 위한 인덱스
CREATE INDEX idx_lease_contract_status_history_contract_id ON lease_contract_status_history(lease_contract_id);
CREATE INDEX idx_lease_contract_status_history_changed_at ON lease_contract_status_history(changed_at);

-- 갱신 알림을 위한 인덱스
CREATE INDEX idx_lease_contract_renewal_alerts_contract_id ON lease_contract_renewal_alerts(lease_contract_id);

-- ============================================================================
-- 계약 만료 알림을 위한 뷰
-- ============================================================================

-- 만료 예정 계약 뷰
CREATE VIEW v_expiring_contracts AS
SELECT 
    lc.id,
    lc.contract_number,
    lc.unit_id,
    u.unit_number,
    b.name as building_name,
    lc.tenant_id,
    t.name as tenant_name,
    t.contact_phone as tenant_phone,
    lc.lessor_id,
    l.name as lessor_name,
    l.contact_phone as lessor_phone,
    lc.start_date,
    lc.end_date,
    lc.monthly_rent,
    lc.deposit,
    lc.status,
    (lc.end_date - CURRENT_DATE) as days_until_expiry,
    lra.alert_days_before,
    lra.is_enabled as alert_enabled,
    lra.last_notification_sent_at
FROM lease_contracts lc
JOIN units u ON lc.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
JOIN tenants t ON lc.tenant_id = t.id
JOIN lessors l ON lc.lessor_id = l.id
LEFT JOIN lease_contract_renewal_alerts lra ON lc.id = lra.lease_contract_id
WHERE lc.status = 'ACTIVE'
  AND lc.end_date > CURRENT_DATE
  AND lc.end_date <= CURRENT_DATE + INTERVAL '90 days';

-- 현재 활성 계약 요약 뷰
CREATE VIEW v_active_contracts_summary AS
SELECT 
    lc.id,
    lc.contract_number,
    lc.unit_id,
    u.unit_number,
    b.name as building_name,
    lc.tenant_id,
    t.name as tenant_name,
    lc.start_date,
    lc.end_date,
    lc.monthly_rent,
    lc.deposit,
    lc.status,
    CASE 
        WHEN lc.end_date <= CURRENT_DATE THEN 'EXPIRED'
        WHEN lc.end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        ELSE 'ACTIVE'
    END as contract_health_status
FROM lease_contracts lc
JOIN units u ON lc.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
JOIN tenants t ON lc.tenant_id = t.id
WHERE lc.status = 'ACTIVE';

-- ============================================================================
-- 트리거 함수들
-- ============================================================================

-- 계약 상태 변경 이력 자동 기록 함수
CREATE OR REPLACE FUNCTION fn_record_lease_contract_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 이력 기록
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO lease_contract_status_history (
            lease_contract_id,
            previous_status,
            new_status,
            change_reason,
            changed_by,
            changed_at
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            CASE 
                WHEN NEW.status = 'EXPIRED' AND OLD.status = 'ACTIVE' THEN '계약 만료'
                WHEN NEW.status = 'TERMINATED' AND OLD.status = 'ACTIVE' THEN '중도 해지'
                WHEN NEW.status = 'ACTIVE' AND OLD.status = 'DRAFT' THEN '계약 체결'
                ELSE '상태 변경'
            END,
            NEW.updated_by,
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 계약 상태 변경 트리거
CREATE TRIGGER tr_lease_contract_status_change
    AFTER UPDATE ON lease_contracts
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_lease_contract_status_change();

-- 호실 상태 자동 업데이트 함수
CREATE OR REPLACE FUNCTION fn_update_unit_status_on_contract_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 계약이 활성화되면 호실을 임대중으로 변경
    IF NEW.status = 'ACTIVE' AND (OLD.status IS NULL OR OLD.status != 'ACTIVE') THEN
        UPDATE units 
        SET status = 'OCCUPIED', updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.unit_id;
    END IF;
    
    -- 계약이 종료되면 호실을 공실로 변경 (다른 활성 계약이 없는 경우)
    IF NEW.status IN ('EXPIRED', 'TERMINATED') AND OLD.status = 'ACTIVE' THEN
        -- 해당 호실에 다른 활성 계약이 있는지 확인
        IF NOT EXISTS (
            SELECT 1 FROM lease_contracts 
            WHERE unit_id = NEW.unit_id 
              AND status = 'ACTIVE' 
              AND id != NEW.id
        ) THEN
            UPDATE units 
            SET status = 'AVAILABLE', updated_at = CURRENT_TIMESTAMP
            WHERE id = NEW.unit_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 호실 상태 업데이트 트리거
CREATE TRIGGER tr_update_unit_status_on_contract_change
    AFTER INSERT OR UPDATE ON lease_contracts
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_unit_status_on_contract_change();

-- 계약 갱신 알림 자동 생성 함수
CREATE OR REPLACE FUNCTION fn_create_renewal_alert_on_contract_creation()
RETURNS TRIGGER AS $$
BEGIN
    -- 새로운 활성 계약에 대해 갱신 알림 설정 자동 생성
    IF NEW.status = 'ACTIVE' THEN
        INSERT INTO lease_contract_renewal_alerts (
            lease_contract_id,
            alert_days_before,
            is_enabled,
            notify_lessor,
            notify_tenant,
            notify_manager
        ) VALUES (
            NEW.id,
            30,  -- 기본 30일 전 알림
            true,
            true,
            true,
            true
        ) ON CONFLICT DO NOTHING;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 갱신 알림 자동 생성 트리거
CREATE TRIGGER tr_create_renewal_alert_on_contract_creation
    AFTER INSERT OR UPDATE ON lease_contracts
    FOR EACH ROW
    EXECUTE FUNCTION fn_create_renewal_alert_on_contract_creation();

-- ============================================================================
-- 제약조건 및 비즈니스 규칙
-- ============================================================================

-- 계약 기간 중복 방지 함수
CREATE OR REPLACE FUNCTION fn_check_contract_overlap()
RETURNS TRIGGER AS $$
BEGIN
    -- 동일 호실에 대한 기간 중복 계약 방지 (ACTIVE, DRAFT 상태만)
    IF NEW.status IN ('ACTIVE', 'DRAFT') THEN
        IF EXISTS (
            SELECT 1 FROM lease_contracts 
            WHERE unit_id = NEW.unit_id 
              AND status IN ('ACTIVE', 'DRAFT')
              AND id != COALESCE(NEW.id, 0)
              AND (
                  (NEW.start_date BETWEEN start_date AND end_date) OR
                  (NEW.end_date BETWEEN start_date AND end_date) OR
                  (start_date BETWEEN NEW.start_date AND NEW.end_date) OR
                  (end_date BETWEEN NEW.start_date AND NEW.end_date)
              )
        ) THEN
            RAISE EXCEPTION '동일 호실에 대한 계약 기간이 중복됩니다. 호실: %, 기간: % ~ %', 
                NEW.unit_id, NEW.start_date, NEW.end_date;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 계약 중복 방지 트리거
CREATE TRIGGER tr_check_contract_overlap
    BEFORE INSERT OR UPDATE ON lease_contracts
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_contract_overlap();

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER tr_lease_contracts_updated_at
    BEFORE UPDATE ON lease_contracts
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_updated_at_column();

CREATE TRIGGER tr_lease_contract_renewal_alerts_updated_at
    BEFORE UPDATE ON lease_contract_renewal_alerts
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_updated_at_column();

-- ============================================================================
-- 코멘트
-- ============================================================================

COMMENT ON TABLE lease_contracts IS '임대 계약 정보를 관리하는 테이블';
COMMENT ON COLUMN lease_contracts.contract_number IS '계약번호 (고유)';
COMMENT ON COLUMN lease_contracts.unit_id IS '임대 호실 ID';
COMMENT ON COLUMN lease_contracts.tenant_id IS '임차인 ID';
COMMENT ON COLUMN lease_contracts.lessor_id IS '임대인 ID';
COMMENT ON COLUMN lease_contracts.start_date IS '계약 시작일';
COMMENT ON COLUMN lease_contracts.end_date IS '계약 종료일';
COMMENT ON COLUMN lease_contracts.monthly_rent IS '월 임대료';
COMMENT ON COLUMN lease_contracts.deposit IS '보증금';
COMMENT ON COLUMN lease_contracts.maintenance_fee IS '관리비';
COMMENT ON COLUMN lease_contracts.contract_type IS '계약 유형 (신규/갱신/승계)';
COMMENT ON COLUMN lease_contracts.status IS '계약 상태';
COMMENT ON COLUMN lease_contracts.previous_contract_id IS '이전 계약 ID (갱신/승계시)';

COMMENT ON TABLE lease_contract_status_history IS '계약 상태 변경 이력';
COMMENT ON TABLE lease_contract_renewal_alerts IS '계약 갱신 알림 설정';

COMMENT ON VIEW v_expiring_contracts IS '만료 예정 계약 조회 뷰';
COMMENT ON VIEW v_active_contracts_summary IS '현재 활성 계약 요약 뷰';

-- ============================================================================
-- 임대료 관리 테이블
-- ============================================================================

-- 임대료 납부 상태 ENUM 타입
CREATE TYPE rent_payment_status AS ENUM (
    'PENDING',      -- 미납
    'PARTIAL',      -- 부분납부
    'PAID',         -- 완납
    'OVERDUE',      -- 연체
    'WAIVED'        -- 면제
);

-- 월별 임대료 관리 테이블
CREATE TABLE monthly_rents (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE RESTRICT,
    rent_year INTEGER NOT NULL,
    rent_month INTEGER NOT NULL CHECK (rent_month BETWEEN 1 AND 12),
    
    -- 임대료 정보
    rent_amount DECIMAL(12,2) NOT NULL CHECK (rent_amount >= 0),
    maintenance_fee DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_fee >= 0),
    total_amount DECIMAL(12,2) GENERATED ALWAYS AS (rent_amount + maintenance_fee) STORED,
    
    -- 납부 정보
    due_date DATE NOT NULL,
    payment_status rent_payment_status NOT NULL DEFAULT 'PENDING',
    paid_amount DECIMAL(12,2) DEFAULT 0 CHECK (paid_amount >= 0),
    remaining_amount DECIMAL(12,2) GENERATED ALWAYS AS (rent_amount + maintenance_fee - paid_amount) STORED,
    paid_date DATE,
    
    -- 연체 정보
    overdue_days INTEGER DEFAULT 0 CHECK (overdue_days >= 0),
    late_fee_rate DECIMAL(5,4) DEFAULT 0.0000 CHECK (late_fee_rate >= 0),
    late_fee_amount DECIMAL(12,2) DEFAULT 0 CHECK (late_fee_amount >= 0),
    
    -- 납부 방법 및 메모
    payment_method VARCHAR(50),
    payment_reference VARCHAR(100),  -- 입금자명, 계좌이체 참조번호 등
    notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT uk_monthly_rents_contract_period UNIQUE (lease_contract_id, rent_year, rent_month),
    CONSTRAINT chk_monthly_rents_paid_amount CHECK (paid_amount <= rent_amount + maintenance_fee + late_fee_amount)
);

-- 임대료 납부 내역 테이블 (부분납부 지원)
CREATE TABLE rent_payments (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    monthly_rent_id BIGINT NOT NULL REFERENCES monthly_rents(id) ON DELETE RESTRICT,
    
    -- 납부 정보
    payment_date DATE NOT NULL,
    payment_amount DECIMAL(12,2) NOT NULL CHECK (payment_amount > 0),
    payment_method VARCHAR(50) NOT NULL,
    payment_reference VARCHAR(100),  -- 입금자명, 계좌이체 참조번호 등
    
    -- 납부 분할 정보
    rent_portion DECIMAL(12,2) DEFAULT 0 CHECK (rent_portion >= 0),
    maintenance_portion DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_portion >= 0),
    late_fee_portion DECIMAL(12,2) DEFAULT 0 CHECK (late_fee_portion >= 0),
    
    -- 메모 및 첨부
    notes TEXT,
    receipt_file_path VARCHAR(500),
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    
    -- 제약조건
    CONSTRAINT chk_rent_payments_portions CHECK (
        rent_portion + maintenance_portion + late_fee_portion = payment_amount
    )
);

-- 임대료 연체 관리 테이블
CREATE TABLE rent_delinquencies (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    monthly_rent_id BIGINT NOT NULL REFERENCES monthly_rents(id) ON DELETE CASCADE,
    
    -- 연체 정보
    overdue_amount DECIMAL(12,2) NOT NULL CHECK (overdue_amount > 0),
    overdue_start_date DATE NOT NULL,
    overdue_days INTEGER NOT NULL CHECK (overdue_days > 0),
    
    -- 연체료 계산
    late_fee_rate DECIMAL(5,4) NOT NULL CHECK (late_fee_rate >= 0),
    calculated_late_fee DECIMAL(12,2) NOT NULL CHECK (calculated_late_fee >= 0),
    applied_late_fee DECIMAL(12,2) NOT NULL CHECK (applied_late_fee >= 0),
    
    -- 연체 해결
    is_resolved BOOLEAN DEFAULT false,
    resolved_date DATE,
    resolution_method VARCHAR(50),  -- 'PAYMENT', 'WAIVER', 'SETTLEMENT'
    resolution_notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT chk_rent_delinquencies_resolved CHECK (
        (is_resolved = false AND resolved_date IS NULL) OR
        (is_resolved = true AND resolved_date IS NOT NULL)
    )
);

-- ============================================================================
-- 임대료 관리 인덱스
-- ============================================================================

-- 기본 조회 성능을 위한 인덱스
CREATE INDEX idx_monthly_rents_lease_contract_id ON monthly_rents(lease_contract_id);
CREATE INDEX idx_monthly_rents_period ON monthly_rents(rent_year, rent_month);
CREATE INDEX idx_monthly_rents_due_date ON monthly_rents(due_date);
CREATE INDEX idx_monthly_rents_payment_status ON monthly_rents(payment_status);

-- 연체 관리를 위한 인덱스
CREATE INDEX idx_monthly_rents_overdue ON monthly_rents(payment_status, due_date) 
WHERE payment_status IN ('PENDING', 'PARTIAL', 'OVERDUE');

-- 납부 내역 조회를 위한 인덱스
CREATE INDEX idx_rent_payments_monthly_rent_id ON rent_payments(monthly_rent_id);
CREATE INDEX idx_rent_payments_payment_date ON rent_payments(payment_date);

-- 연체 관리를 위한 인덱스
CREATE INDEX idx_rent_delinquencies_monthly_rent_id ON rent_delinquencies(monthly_rent_id);
CREATE INDEX idx_rent_delinquencies_overdue_start_date ON rent_delinquencies(overdue_start_date);
CREATE INDEX idx_rent_delinquencies_unresolved ON rent_delinquencies(is_resolved, overdue_start_date) 
WHERE is_resolved = false;

-- ============================================================================
-- 임대료 관리 뷰
-- ============================================================================

-- 임대료 현황 요약 뷰
CREATE VIEW v_rent_status_summary AS
SELECT 
    mr.id,
    mr.lease_contract_id,
    lc.contract_number,
    lc.unit_id,
    u.unit_number,
    b.name as building_name,
    t.name as tenant_name,
    t.contact_phone as tenant_phone,
    mr.rent_year,
    mr.rent_month,
    mr.rent_amount,
    mr.maintenance_fee,
    mr.total_amount,
    mr.due_date,
    mr.payment_status,
    mr.paid_amount,
    mr.remaining_amount,
    mr.paid_date,
    mr.overdue_days,
    mr.late_fee_amount,
    CASE 
        WHEN mr.payment_status = 'PAID' THEN 0
        WHEN mr.due_date < CURRENT_DATE THEN CURRENT_DATE - mr.due_date
        ELSE 0
    END as current_overdue_days,
    CASE 
        WHEN mr.payment_status IN ('PENDING', 'PARTIAL') AND mr.due_date < CURRENT_DATE THEN true
        ELSE false
    END as is_currently_overdue
FROM monthly_rents mr
JOIN lease_contracts lc ON mr.lease_contract_id = lc.id
JOIN units u ON lc.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
JOIN tenants t ON lc.tenant_id = t.id;

-- 연체 현황 뷰
CREATE VIEW v_rent_delinquency_summary AS
SELECT 
    rd.id,
    rd.monthly_rent_id,
    mr.lease_contract_id,
    lc.contract_number,
    lc.unit_id,
    u.unit_number,
    b.name as building_name,
    t.name as tenant_name,
    t.contact_phone as tenant_phone,
    mr.rent_year,
    mr.rent_month,
    rd.overdue_amount,
    rd.overdue_start_date,
    rd.overdue_days,
    rd.calculated_late_fee,
    rd.applied_late_fee,
    rd.is_resolved,
    rd.resolved_date,
    CURRENT_DATE - rd.overdue_start_date as total_overdue_days
FROM rent_delinquencies rd
JOIN monthly_rents mr ON rd.monthly_rent_id = mr.id
JOIN lease_contracts lc ON mr.lease_contract_id = lc.id
JOIN units u ON lc.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
JOIN tenants t ON lc.tenant_id = t.id;

-- 월별 임대료 수납 현황 뷰
CREATE VIEW v_monthly_rent_collection_summary AS
SELECT 
    rent_year,
    rent_month,
    COUNT(*) as total_units,
    COUNT(CASE WHEN payment_status = 'PAID' THEN 1 END) as paid_units,
    COUNT(CASE WHEN payment_status IN ('PENDING', 'PARTIAL', 'OVERDUE') THEN 1 END) as unpaid_units,
    SUM(total_amount) as total_rent_amount,
    SUM(paid_amount) as total_paid_amount,
    SUM(remaining_amount) as total_remaining_amount,
    SUM(late_fee_amount) as total_late_fee_amount,
    ROUND(
        (COUNT(CASE WHEN payment_status = 'PAID' THEN 1 END)::DECIMAL / COUNT(*)) * 100, 2
    ) as collection_rate_percent
FROM monthly_rents
GROUP BY rent_year, rent_month
ORDER BY rent_year DESC, rent_month DESC;

-- ============================================================================
-- 임대료 관리 트리거 함수들
-- ============================================================================

-- 임대료 납부 상태 자동 업데이트 함수
CREATE OR REPLACE FUNCTION fn_update_rent_payment_status()
RETURNS TRIGGER AS $$
DECLARE
    total_due DECIMAL(12,2);
    total_paid DECIMAL(12,2);
BEGIN
    -- 해당 월 임대료의 총 납부해야 할 금액과 납부된 금액 계산
    SELECT 
        mr.rent_amount + mr.maintenance_fee + mr.late_fee_amount,
        COALESCE(SUM(rp.payment_amount), 0)
    INTO total_due, total_paid
    FROM monthly_rents mr
    LEFT JOIN rent_payments rp ON mr.id = rp.monthly_rent_id
    WHERE mr.id = COALESCE(NEW.monthly_rent_id, OLD.monthly_rent_id)
    GROUP BY mr.id, mr.rent_amount, mr.maintenance_fee, mr.late_fee_amount;
    
    -- 납부 상태 업데이트
    UPDATE monthly_rents 
    SET 
        paid_amount = total_paid,
        payment_status = CASE 
            WHEN total_paid = 0 THEN 
                CASE WHEN due_date < CURRENT_DATE THEN 'OVERDUE' ELSE 'PENDING' END
            WHEN total_paid >= total_due THEN 'PAID'
            ELSE 
                CASE WHEN due_date < CURRENT_DATE THEN 'OVERDUE' ELSE 'PARTIAL' END
        END,
        paid_date = CASE 
            WHEN total_paid >= total_due AND paid_date IS NULL THEN CURRENT_DATE
            WHEN total_paid < total_due THEN NULL
            ELSE paid_date
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.monthly_rent_id, OLD.monthly_rent_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 임대료 납부 상태 업데이트 트리거
CREATE TRIGGER tr_update_rent_payment_status_on_payment
    AFTER INSERT OR UPDATE OR DELETE ON rent_payments
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_rent_payment_status();

-- 연체료 자동 계산 함수
CREATE OR REPLACE FUNCTION fn_calculate_late_fees()
RETURNS TRIGGER AS $$
DECLARE
    current_overdue_days INTEGER;
    base_late_fee_rate DECIMAL(5,4);
    calculated_fee DECIMAL(12,2);
BEGIN
    -- 연체 일수 계산
    IF NEW.payment_status IN ('PENDING', 'PARTIAL', 'OVERDUE') AND NEW.due_date < CURRENT_DATE THEN
        current_overdue_days := CURRENT_DATE - NEW.due_date;
        
        -- 기본 연체료율 가져오기 (계약에서 또는 시스템 기본값)
        SELECT COALESCE(pp.late_fee_rate, 0.0005) -- 기본 0.05% (연 18.25%)
        INTO base_late_fee_rate
        FROM lease_contracts lc
        LEFT JOIN units u ON lc.unit_id = u.id
        LEFT JOIN buildings b ON u.building_id = b.id
        LEFT JOIN payment_policies pp ON b.id = pp.building_id
        WHERE lc.id = NEW.lease_contract_id
        LIMIT 1;
        
        -- 연체료 계산 (일할 계산)
        calculated_fee := (NEW.rent_amount + NEW.maintenance_fee - NEW.paid_amount) * base_late_fee_rate * current_overdue_days;
        
        -- 연체 정보 업데이트
        NEW.overdue_days := current_overdue_days;
        NEW.late_fee_rate := base_late_fee_rate;
        NEW.late_fee_amount := GREATEST(calculated_fee, 0);
        
        -- 연체 관리 테이블에 레코드 생성 또는 업데이트
        INSERT INTO rent_delinquencies (
            monthly_rent_id,
            overdue_amount,
            overdue_start_date,
            overdue_days,
            late_fee_rate,
            calculated_late_fee,
            applied_late_fee,
            created_by
        ) VALUES (
            NEW.id,
            NEW.rent_amount + NEW.maintenance_fee - NEW.paid_amount,
            NEW.due_date + INTERVAL '1 day',
            current_overdue_days,
            base_late_fee_rate,
            calculated_fee,
            calculated_fee,
            NEW.updated_by
        ) ON CONFLICT (monthly_rent_id) DO UPDATE SET
            overdue_amount = EXCLUDED.overdue_amount,
            overdue_days = EXCLUDED.overdue_days,
            calculated_late_fee = EXCLUDED.calculated_late_fee,
            applied_late_fee = EXCLUDED.applied_late_fee,
            updated_at = CURRENT_TIMESTAMP;
            
    ELSE
        -- 연체가 해결된 경우
        NEW.overdue_days := 0;
        NEW.late_fee_amount := 0;
        
        -- 연체 관리 테이블에서 해결 처리
        UPDATE rent_delinquencies 
        SET 
            is_resolved = true,
            resolved_date = CURRENT_DATE,
            resolution_method = 'PAYMENT',
            updated_at = CURRENT_TIMESTAMP
        WHERE monthly_rent_id = NEW.id AND is_resolved = false;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 연체료 자동 계산 트리거
CREATE TRIGGER tr_calculate_late_fees
    BEFORE UPDATE ON monthly_rents
    FOR EACH ROW
    EXECUTE FUNCTION fn_calculate_late_fees();

-- 임대료 납부 내역 분할 자동 계산 함수
CREATE OR REPLACE FUNCTION fn_auto_allocate_rent_payment()
RETURNS TRIGGER AS $$
DECLARE
    mr_record monthly_rents%ROWTYPE;
    remaining_payment DECIMAL(12,2);
BEGIN
    -- 해당 월 임대료 정보 조회
    SELECT * INTO mr_record 
    FROM monthly_rents 
    WHERE id = NEW.monthly_rent_id;
    
    remaining_payment := NEW.payment_amount;
    
    -- 자동 분할 로직 (우선순위: 연체료 -> 임대료 -> 관리비)
    IF mr_record.late_fee_amount > 0 AND remaining_payment > 0 THEN
        NEW.late_fee_portion := LEAST(remaining_payment, mr_record.late_fee_amount);
        remaining_payment := remaining_payment - NEW.late_fee_portion;
    ELSE
        NEW.late_fee_portion := 0;
    END IF;
    
    IF mr_record.rent_amount > 0 AND remaining_payment > 0 THEN
        NEW.rent_portion := LEAST(remaining_payment, mr_record.rent_amount);
        remaining_payment := remaining_payment - NEW.rent_portion;
    ELSE
        NEW.rent_portion := 0;
    END IF;
    
    IF mr_record.maintenance_fee > 0 AND remaining_payment > 0 THEN
        NEW.maintenance_portion := LEAST(remaining_payment, mr_record.maintenance_fee);
    ELSE
        NEW.maintenance_portion := 0;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 임대료 납부 분할 자동 계산 트리거
CREATE TRIGGER tr_auto_allocate_rent_payment
    BEFORE INSERT ON rent_payments
    FOR EACH ROW
    EXECUTE FUNCTION fn_auto_allocate_rent_payment();

-- updated_at 자동 업데이트 트리거들
CREATE TRIGGER tr_monthly_rents_updated_at
    BEFORE UPDATE ON monthly_rents
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_updated_at_column();

CREATE TRIGGER tr_rent_delinquencies_updated_at
    BEFORE UPDATE ON rent_delinquencies
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_updated_at_column();

-- ============================================================================
-- 코멘트
-- ============================================================================

COMMENT ON TABLE monthly_rents IS '월별 임대료 관리 테이블';
COMMENT ON COLUMN monthly_rents.lease_contract_id IS '임대 계약 ID';
COMMENT ON COLUMN monthly_rents.rent_year IS '임대료 년도';
COMMENT ON COLUMN monthly_rents.rent_month IS '임대료 월';
COMMENT ON COLUMN monthly_rents.rent_amount IS '임대료';
COMMENT ON COLUMN monthly_rents.maintenance_fee IS '관리비';
COMMENT ON COLUMN monthly_rents.total_amount IS '총 납부 금액 (임대료 + 관리비)';
COMMENT ON COLUMN monthly_rents.due_date IS '납부 기한';
COMMENT ON COLUMN monthly_rents.payment_status IS '납부 상태';
COMMENT ON COLUMN monthly_rents.paid_amount IS '납부된 금액';
COMMENT ON COLUMN monthly_rents.remaining_amount IS '미납 금액';
COMMENT ON COLUMN monthly_rents.overdue_days IS '연체 일수';
COMMENT ON COLUMN monthly_rents.late_fee_amount IS '연체료';

COMMENT ON TABLE rent_payments IS '임대료 납부 내역 테이블 (부분납부 지원)';
COMMENT ON COLUMN rent_payments.rent_portion IS '임대료 납부 부분';
COMMENT ON COLUMN rent_payments.maintenance_portion IS '관리비 납부 부분';
COMMENT ON COLUMN rent_payments.late_fee_portion IS '연체료 납부 부분';

COMMENT ON TABLE rent_delinquencies IS '임대료 연체 관리 테이블';
COMMENT ON COLUMN rent_delinquencies.overdue_amount IS '연체 금액';
COMMENT ON COLUMN rent_delinquencies.calculated_late_fee IS '계산된 연체료';
COMMENT ON COLUMN rent_delinquencies.applied_late_fee IS '적용된 연체료';

COMMENT ON VIEW v_rent_status_summary IS '임대료 현황 요약 뷰';
COMMENT ON VIEW v_rent_delinquency_summary IS '연체 현황 요약 뷰';
COMMENT ON VIEW v_monthly_rent_collection_summary IS '월별 임대료 수납 현황 뷰';-- ===
=========================================================================
-- 퇴실 정산 관리 테이블
-- ============================================================================

-- 정산 상태 ENUM 타입
CREATE TYPE settlement_status AS ENUM (
    'PENDING',      -- 정산 대기
    'IN_PROGRESS',  -- 정산 진행중
    'COMPLETED',    -- 정산 완료
    'DISPUTED',     -- 분쟁 중
    'CANCELLED'     -- 정산 취소
);

-- 정산 항목 유형 ENUM 타입
CREATE TYPE settlement_item_type AS ENUM (
    'DEPOSIT_REFUND',       -- 보증금 환급
    'UNPAID_RENT',          -- 미납 임대료
    'UNPAID_MAINTENANCE',   -- 미납 관리비
    'LATE_FEE',            -- 연체료
    'UTILITY_SETTLEMENT',   -- 공과금 정산
    'REPAIR_COST',         -- 수리비
    'CLEANING_FEE',        -- 청소비
    'KEY_REPLACEMENT',     -- 열쇠 교체비
    'OTHER_DEDUCTION',     -- 기타 공제
    'OTHER_REFUND'         -- 기타 환급
);

-- 퇴실 정산 메인 테이블
CREATE TABLE move_out_settlements (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    lease_contract_id BIGINT NOT NULL REFERENCES lease_contracts(id) ON DELETE RESTRICT,
    settlement_number VARCHAR(50) UNIQUE NOT NULL,  -- 정산번호
    
    -- 퇴실 정보
    move_out_date DATE NOT NULL,
    move_out_reason VARCHAR(100),
    notice_date DATE,  -- 퇴실 통보일
    
    -- 정산 기간
    settlement_start_date DATE NOT NULL,
    settlement_end_date DATE NOT NULL,
    
    -- 기본 금액 정보
    original_deposit DECIMAL(12,2) NOT NULL CHECK (original_deposit >= 0),
    total_deductions DECIMAL(12,2) DEFAULT 0 CHECK (total_deductions >= 0),
    total_additional_charges DECIMAL(12,2) DEFAULT 0 CHECK (total_additional_charges >= 0),
    final_refund_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        original_deposit - total_deductions + total_additional_charges
    ) STORED,
    
    -- 정산 상태
    status settlement_status NOT NULL DEFAULT 'PENDING',
    
    -- 정산 완료 정보
    settlement_date DATE,
    refund_method VARCHAR(50),  -- 'BANK_TRANSFER', 'CASH', 'CHECK', 'OFFSET'
    refund_account_info JSONB,  -- 환급 계좌 정보
    refund_completed_date DATE,
    
    -- 메모 및 첨부
    notes TEXT,
    supporting_documents JSONB,  -- 첨부 문서 정보
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT chk_move_out_settlement_dates CHECK (settlement_end_date >= settlement_start_date),
    CONSTRAINT chk_move_out_settlement_completion CHECK (
        (status = 'COMPLETED' AND settlement_date IS NOT NULL) OR
        (status != 'COMPLETED' AND settlement_date IS NULL)
    )
);

-- 정산 항목 상세 테이블
CREATE TABLE settlement_items (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    settlement_id BIGINT NOT NULL REFERENCES move_out_settlements(id) ON DELETE CASCADE,
    item_type settlement_item_type NOT NULL,
    
    -- 항목 정보
    description VARCHAR(255) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    is_deduction BOOLEAN NOT NULL DEFAULT true,  -- true: 공제, false: 추가 환급
    
    -- 관련 정보
    related_period_start DATE,
    related_period_end DATE,
    reference_document VARCHAR(255),
    
    -- 승인 정보
    is_approved BOOLEAN DEFAULT false,
    approved_by BIGINT,
    approved_at TIMESTAMP,
    approval_notes TEXT,
    
    -- 메모
    notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT
);

-- 정산 상태 변경 이력 테이블
CREATE TABLE settlement_status_history (
    id BIGSERIAL PRIMARY KEY,
    settlement_id BIGINT NOT NULL REFERENCES move_out_settlements(id) ON DELETE CASCADE,
    
    -- 상태 변경 정보
    previous_status settlement_status,
    new_status settlement_status NOT NULL,
    change_reason VARCHAR(255),
    change_description TEXT,
    
    -- 변경자 정보
    changed_by BIGINT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 정산 분쟁 관리 테이블
CREATE TABLE settlement_disputes (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    settlement_id BIGINT NOT NULL REFERENCES move_out_settlements(id) ON DELETE CASCADE,
    dispute_number VARCHAR(50) UNIQUE NOT NULL,
    
    -- 분쟁 정보
    dispute_reason TEXT NOT NULL,
    disputed_amount DECIMAL(12,2) NOT NULL,
    dispute_date DATE NOT NULL,
    
    -- 당사자 정보
    disputant_name VARCHAR(255) NOT NULL,
    disputant_contact VARCHAR(100),
    
    -- 해결 정보
    is_resolved BOOLEAN DEFAULT false,
    resolution_date DATE,
    resolution_method VARCHAR(100),  -- '합의', '중재', '소송' 등
    resolution_amount DECIMAL(12,2),
    resolution_notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT chk_settlement_disputes_resolution CHECK (
        (is_resolved = false AND resolution_date IS NULL) OR
        (is_resolved = true AND resolution_date IS NOT NULL)
    )
);

-- ============================================================================
-- 퇴실 정산 인덱스
-- ============================================================================

-- 기본 조회 성능을 위한 인덱스
CREATE INDEX idx_move_out_settlements_lease_contract_id ON move_out_settlements(lease_contract_id);
CREATE INDEX idx_move_out_settlements_move_out_date ON move_out_settlements(move_out_date);
CREATE INDEX idx_move_out_settlements_status ON move_out_settlements(status);
CREATE INDEX idx_move_out_settlements_settlement_date ON move_out_settlements(settlement_date);

-- 정산번호 조회를 위한 인덱스
CREATE INDEX idx_move_out_settlements_settlement_number ON move_out_settlements(settlement_number);

-- 정산 항목 조회를 위한 인덱스
CREATE INDEX idx_settlement_items_settlement_id ON settlement_items(settlement_id);
CREATE INDEX idx_settlement_items_type ON settlement_items(item_type);
CREATE INDEX idx_settlement_items_approval ON settlement_items(is_approved);

-- 상태 이력 조회를 위한 인덱스
CREATE INDEX idx_settlement_status_history_settlement_id ON settlement_status_history(settlement_id);
CREATE INDEX idx_settlement_status_history_changed_at ON settlement_status_history(changed_at);

-- 분쟁 관리를 위한 인덱스
CREATE INDEX idx_settlement_disputes_settlement_id ON settlement_disputes(settlement_id);
CREATE INDEX idx_settlement_disputes_dispute_date ON settlement_disputes(dispute_date);
CREATE INDEX idx_settlement_disputes_unresolved ON settlement_disputes(is_resolved, dispute_date) 
WHERE is_resolved = false;

-- ============================================================================
-- 퇴실 정산 뷰
-- ============================================================================

-- 정산 현황 요약 뷰
CREATE VIEW v_settlement_summary AS
SELECT 
    mos.id,
    mos.settlement_number,
    mos.lease_contract_id,
    lc.contract_number,
    lc.unit_id,
    u.unit_number,
    b.name as building_name,
    t.name as tenant_name,
    t.contact_phone as tenant_phone,
    l.name as lessor_name,
    mos.move_out_date,
    mos.settlement_start_date,
    mos.settlement_end_date,
    mos.original_deposit,
    mos.total_deductions,
    mos.total_additional_charges,
    mos.final_refund_amount,
    mos.status,
    mos.settlement_date,
    mos.refund_completed_date,
    CASE 
        WHEN mos.status = 'COMPLETED' THEN 0
        ELSE CURRENT_DATE - mos.move_out_date
    END as days_since_move_out,
    -- 정산 항목 요약
    (SELECT COUNT(*) FROM settlement_items si WHERE si.settlement_id = mos.id) as total_items,
    (SELECT COUNT(*) FROM settlement_items si WHERE si.settlement_id = mos.id AND si.is_approved = false) as pending_approvals,
    -- 분쟁 여부
    EXISTS(SELECT 1 FROM settlement_disputes sd WHERE sd.settlement_id = mos.id AND sd.is_resolved = false) as has_active_dispute
FROM move_out_settlements mos
JOIN lease_contracts lc ON mos.lease_contract_id = lc.id
JOIN units u ON lc.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
JOIN tenants t ON lc.tenant_id = t.id
JOIN lessors l ON lc.lessor_id = l.id;

-- 정산 항목 상세 뷰
CREATE VIEW v_settlement_items_detail AS
SELECT 
    si.id,
    si.settlement_id,
    mos.settlement_number,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    t.name as tenant_name,
    si.item_type,
    si.description,
    si.amount,
    si.is_deduction,
    CASE 
        WHEN si.is_deduction THEN si.amount
        ELSE 0
    END as deduction_amount,
    CASE 
        WHEN NOT si.is_deduction THEN si.amount
        ELSE 0
    END as refund_amount,
    si.related_period_start,
    si.related_period_end,
    si.is_approved,
    si.approved_by,
    si.approved_at,
    si.notes
FROM settlement_items si
JOIN move_out_settlements mos ON si.settlement_id = mos.id
JOIN lease_contracts lc ON mos.lease_contract_id = lc.id
JOIN units u ON lc.unit_id = u.id
JOIN buildings b ON u.building_id = b.id
JOIN tenants t ON lc.tenant_id = t.id;

-- 월별 정산 통계 뷰
CREATE VIEW v_monthly_settlement_stats AS
SELECT 
    EXTRACT(YEAR FROM settlement_date) as settlement_year,
    EXTRACT(MONTH FROM settlement_date) as settlement_month,
    COUNT(*) as total_settlements,
    COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_settlements,
    COUNT(CASE WHEN status = 'DISPUTED' THEN 1 END) as disputed_settlements,
    AVG(original_deposit) as avg_original_deposit,
    AVG(total_deductions) as avg_total_deductions,
    AVG(final_refund_amount) as avg_final_refund,
    SUM(original_deposit) as total_original_deposits,
    SUM(total_deductions) as total_deductions_sum,
    SUM(final_refund_amount) as total_refunds
FROM move_out_settlements
WHERE settlement_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM settlement_date), EXTRACT(MONTH FROM settlement_date)
ORDER BY settlement_year DESC, settlement_month DESC;

-- ============================================================================
-- 퇴실 정산 트리거 함수들
-- ============================================================================

-- 정산 항목 합계 자동 업데이트 함수
CREATE OR REPLACE FUNCTION fn_update_settlement_totals()
RETURNS TRIGGER AS $$
DECLARE
    settlement_id_to_update BIGINT;
    total_deductions_calc DECIMAL(12,2);
    total_additional_calc DECIMAL(12,2);
BEGIN
    -- 업데이트할 정산 ID 결정
    settlement_id_to_update := COALESCE(NEW.settlement_id, OLD.settlement_id);
    
    -- 정산 항목별 합계 계산
    SELECT 
        COALESCE(SUM(CASE WHEN is_deduction = true AND is_approved = true THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN is_deduction = false AND is_approved = true THEN amount ELSE 0 END), 0)
    INTO total_deductions_calc, total_additional_calc
    FROM settlement_items
    WHERE settlement_id = settlement_id_to_update;
    
    -- 메인 정산 테이블 업데이트
    UPDATE move_out_settlements
    SET 
        total_deductions = total_deductions_calc,
        total_additional_charges = total_additional_calc,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = settlement_id_to_update;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 정산 항목 변경 시 합계 업데이트 트리거
CREATE TRIGGER tr_update_settlement_totals
    AFTER INSERT OR UPDATE OR DELETE ON settlement_items
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_settlement_totals();

-- 정산 상태 변경 이력 자동 기록 함수
CREATE OR REPLACE FUNCTION fn_record_settlement_status_change()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 이력 기록
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO settlement_status_history (
            settlement_id,
            previous_status,
            new_status,
            change_reason,
            changed_by,
            changed_at
        ) VALUES (
            NEW.id,
            OLD.status,
            NEW.status,
            CASE 
                WHEN NEW.status = 'COMPLETED' THEN '정산 완료'
                WHEN NEW.status = 'DISPUTED' THEN '분쟁 발생'
                WHEN NEW.status = 'CANCELLED' THEN '정산 취소'
                ELSE '상태 변경'
            END,
            NEW.updated_by,
            CURRENT_TIMESTAMP
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 정산 상태 변경 이력 트리거
CREATE TRIGGER tr_record_settlement_status_change
    AFTER UPDATE ON move_out_settlements
    FOR EACH ROW
    EXECUTE FUNCTION fn_record_settlement_status_change();

-- 정산 완료 시 계약 상태 업데이트 함수
CREATE OR REPLACE FUNCTION fn_update_contract_on_settlement_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- 정산이 완료되면 계약 상태를 TERMINATED로 변경
    IF NEW.status = 'COMPLETED' AND (OLD.status IS NULL OR OLD.status != 'COMPLETED') THEN
        UPDATE lease_contracts
        SET 
            status = 'TERMINATED',
            updated_at = CURRENT_TIMESTAMP,
            updated_by = NEW.updated_by
        WHERE id = NEW.lease_contract_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 정산 완료 시 계약 상태 업데이트 트리거
CREATE TRIGGER tr_update_contract_on_settlement_completion
    AFTER UPDATE ON move_out_settlements
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_contract_on_settlement_completion();

-- 정산번호 자동 생성 함수
CREATE OR REPLACE FUNCTION fn_generate_settlement_number()
RETURNS TRIGGER AS $$
DECLARE
    year_part VARCHAR(4);
    sequence_part VARCHAR(6);
    new_settlement_number VARCHAR(50);
BEGIN
    -- 정산번호가 없는 경우에만 자동 생성
    IF NEW.settlement_number IS NULL OR NEW.settlement_number = '' THEN
        year_part := EXTRACT(YEAR FROM NEW.move_out_date)::VARCHAR;
        
        -- 해당 연도의 다음 순번 계산
        SELECT LPAD((COUNT(*) + 1)::VARCHAR, 6, '0')
        INTO sequence_part
        FROM move_out_settlements
        WHERE EXTRACT(YEAR FROM move_out_date) = EXTRACT(YEAR FROM NEW.move_out_date);
        
        new_settlement_number := 'ST' || year_part || sequence_part;
        NEW.settlement_number := new_settlement_number;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 정산번호 자동 생성 트리거
CREATE TRIGGER tr_generate_settlement_number
    BEFORE INSERT ON move_out_settlements
    FOR EACH ROW
    EXECUTE FUNCTION fn_generate_settlement_number();

-- updated_at 자동 업데이트 트리거들
CREATE TRIGGER tr_move_out_settlements_updated_at
    BEFORE UPDATE ON move_out_settlements
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_updated_at_column();

CREATE TRIGGER tr_settlement_items_updated_at
    BEFORE UPDATE ON settlement_items
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_updated_at_column();

CREATE TRIGGER tr_settlement_disputes_updated_at
    BEFORE UPDATE ON settlement_disputes
    FOR EACH ROW
    EXECUTE FUNCTION fn_update_updated_at_column();

-- ============================================================================
-- 데이터 아카이빙 전략
-- ============================================================================

-- 완료된 정산 데이터 아카이빙을 위한 파티션 테이블 (선택적)
-- 대용량 데이터 처리 시 연도별 파티셔닝 고려

-- 아카이빙 대상 정산 조회 함수
CREATE OR REPLACE FUNCTION fn_get_archivable_settlements(archive_after_years INTEGER DEFAULT 3)
RETURNS TABLE (
    settlement_id BIGINT,
    settlement_number VARCHAR(50),
    settlement_date DATE,
    final_refund_amount DECIMAL(12,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mos.id,
        mos.settlement_number,
        mos.settlement_date,
        mos.final_refund_amount
    FROM move_out_settlements mos
    WHERE mos.status = 'COMPLETED'
      AND mos.settlement_date < CURRENT_DATE - INTERVAL '1 year' * archive_after_years
      AND NOT EXISTS (
          SELECT 1 FROM settlement_disputes sd 
          WHERE sd.settlement_id = mos.id AND sd.is_resolved = false
      );
END;
$$ LANGUAGE plpgsql;

-- 정산 데이터 아카이빙 프로시저 (실제 아카이빙은 별도 스케줄러에서 실행)
CREATE OR REPLACE FUNCTION fn_archive_completed_settlements(archive_after_years INTEGER DEFAULT 3)
RETURNS INTEGER AS $$
DECLARE
    archived_count INTEGER := 0;
    settlement_record RECORD;
BEGIN
    -- 아카이빙 대상 정산 처리
    FOR settlement_record IN 
        SELECT * FROM fn_get_archivable_settlements(archive_after_years)
    LOOP
        -- 여기서 실제 아카이빙 로직 구현
        -- 예: 별도 아카이브 테이블로 이동, 파일 백업 등
        
        -- 로그 기록
        INSERT INTO audit_logs (
            table_name,
            record_id,
            action,
            old_values,
            changed_at
        ) VALUES (
            'move_out_settlements',
            settlement_record.settlement_id,
            'ARCHIVED',
            jsonb_build_object(
                'settlement_number', settlement_record.settlement_number,
                'settlement_date', settlement_record.settlement_date,
                'final_refund_amount', settlement_record.final_refund_amount
            ),
            CURRENT_TIMESTAMP
        );
        
        archived_count := archived_count + 1;
    END LOOP;
    
    RETURN archived_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 코멘트
-- ============================================================================

COMMENT ON TABLE move_out_settlements IS '퇴실 정산 메인 테이블';
COMMENT ON COLUMN move_out_settlements.settlement_number IS '정산번호 (고유)';
COMMENT ON COLUMN move_out_settlements.move_out_date IS '퇴실일';
COMMENT ON COLUMN move_out_settlements.settlement_start_date IS '정산 시작일';
COMMENT ON COLUMN move_out_settlements.settlement_end_date IS '정산 종료일';
COMMENT ON COLUMN move_out_settlements.original_deposit IS '원래 보증금';
COMMENT ON COLUMN move_out_settlements.total_deductions IS '총 공제 금액';
COMMENT ON COLUMN move_out_settlements.total_additional_charges IS '총 추가 환급 금액';
COMMENT ON COLUMN move_out_settlements.final_refund_amount IS '최종 환급 금액';

COMMENT ON TABLE settlement_items IS '정산 항목 상세 테이블';
COMMENT ON COLUMN settlement_items.item_type IS '정산 항목 유형';
COMMENT ON COLUMN settlement_items.is_deduction IS '공제 여부 (true: 공제, false: 추가 환급)';
COMMENT ON COLUMN settlement_items.is_approved IS '승인 여부';

COMMENT ON TABLE settlement_status_history IS '정산 상태 변경 이력';
COMMENT ON TABLE settlement_disputes IS '정산 분쟁 관리 테이블';

COMMENT ON VIEW v_settlement_summary IS '정산 현황 요약 뷰';
COMMENT ON VIEW v_settlement_items_detail IS '정산 항목 상세 뷰';
COMMENT ON VIEW v_monthly_settlement_stats IS '월별 정산 통계 뷰';

COMMENT ON FUNCTION fn_get_archivable_settlements IS '아카이빙 대상 정산 조회 함수';
COMMENT ON FUNCTION fn_archive_completed_settlements IS '완료된 정산 아카이빙 함수';