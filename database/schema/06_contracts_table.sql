-- =====================================================
-- 계약 관리 테이블 생성 스크립트
-- Phase 2.3: 계약 관리 테이블 생성
-- =====================================================

-- 1. 임대차 계약 테이블 생성
CREATE TABLE IF NOT EXISTS bms.lease_contracts (
    contract_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    lessor_id UUID NOT NULL,
    tenant_id UUID NOT NULL,
    
    -- 계약 기본 정보
    contract_number VARCHAR(50) NOT NULL,               -- 계약번호
    contract_type VARCHAR(30) NOT NULL DEFAULT 'LEASE', -- 계약 유형
    contract_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT', -- 계약 상태
    
    -- 계약 기간
    contract_start_date DATE NOT NULL,                  -- 계약 시작일
    contract_end_date DATE NOT NULL,                    -- 계약 종료일
    contract_duration_months INTEGER,                   -- 계약 기간 (개월)
    auto_renewal BOOLEAN DEFAULT false,                 -- 자동 갱신 여부
    renewal_notice_days INTEGER DEFAULT 30,             -- 갱신 통지 기간 (일)
    
    -- 금액 정보
    deposit_amount DECIMAL(15,2) NOT NULL DEFAULT 0,    -- 보증금
    monthly_rent DECIMAL(12,2) NOT NULL DEFAULT 0,      -- 월 임대료
    maintenance_fee DECIMAL(10,2) DEFAULT 0,            -- 월 관리비
    key_money DECIMAL(15,2) DEFAULT 0,                  -- 권리금
    
    -- 지급 조건
    rent_payment_day INTEGER DEFAULT 1,                 -- 임대료 지급일
    payment_method VARCHAR(50) DEFAULT '계좌이체',       -- 지급 방법
    late_fee_rate DECIMAL(5,2) DEFAULT 0,              -- 연체료율 (%)
    grace_period_days INTEGER DEFAULT 5,                -- 유예 기간 (일)
    
    -- 계약 조건
    purpose_of_use VARCHAR(100),                        -- 사용 목적
    subletting_allowed BOOLEAN DEFAULT false,           -- 전대 허용 여부
    renovation_allowed BOOLEAN DEFAULT false,           -- 개조 허용 여부
    pet_allowed BOOLEAN DEFAULT false,                  -- 반려동물 허용 여부
    smoking_allowed BOOLEAN DEFAULT false,              -- 흡연 허용 여부
    
    -- 특약 사항
    special_terms TEXT,                                 -- 특약 사항
    lessor_obligations TEXT,                            -- 임대인 의무사항
    tenant_obligations TEXT,                            -- 임차인 의무사항
    
    -- 계약서 관리
    contract_file_path VARCHAR(500),                    -- 계약서 파일 경로
    contract_signed_date DATE,                          -- 계약 체결일
    lessor_signature BOOLEAN DEFAULT false,             -- 임대인 서명 여부
    tenant_signature BOOLEAN DEFAULT false,             -- 임차인 서명 여부
    witness_name VARCHAR(200),                          -- 증인 이름
    witness_phone VARCHAR(20),                          -- 증인 연락처
    
    -- 갱신 정보
    previous_contract_id UUID,                          -- 이전 계약 ID
    renewal_count INTEGER DEFAULT 0,                    -- 갱신 횟수
    next_renewal_date DATE,                             -- 다음 갱신 예정일
    
    -- 종료 정보
    termination_date DATE,                              -- 계약 해지일
    termination_reason VARCHAR(200),                    -- 해지 사유
    early_termination_fee DECIMAL(12,2),               -- 조기 해지 위약금
    deposit_return_amount DECIMAL(15,2),               -- 보증금 반환액
    deposit_return_date DATE,                           -- 보증금 반환일
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_contracts_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contracts_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_contracts_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_contracts_lessor FOREIGN KEY (lessor_id) REFERENCES bms.lessors(lessor_id) ON DELETE CASCADE,
    CONSTRAINT fk_contracts_tenant FOREIGN KEY (tenant_id) REFERENCES bms.tenants(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_contracts_previous FOREIGN KEY (previous_contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE SET NULL,
    CONSTRAINT uk_contracts_number UNIQUE (company_id, contract_number), -- 회사 내 계약번호 중복 방지
    
    -- 체크 제약조건
    CONSTRAINT chk_contract_type CHECK (contract_type IN ('LEASE', 'SUBLEASE', 'RENEWAL', 'AMENDMENT')),
    CONSTRAINT chk_contract_status CHECK (contract_status IN ('DRAFT', 'PENDING', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'RENEWED')),
    CONSTRAINT chk_contract_dates CHECK (contract_end_date > contract_start_date),
    CONSTRAINT chk_deposit_amount CHECK (deposit_amount >= 0),
    CONSTRAINT chk_monthly_rent CHECK (monthly_rent >= 0),
    CONSTRAINT chk_maintenance_fee CHECK (maintenance_fee >= 0),
    CONSTRAINT chk_key_money CHECK (key_money >= 0),
    CONSTRAINT chk_rent_payment_day CHECK (rent_payment_day >= 1 AND rent_payment_day <= 31),
    CONSTRAINT chk_late_fee_rate CHECK (late_fee_rate >= 0 AND late_fee_rate <= 100),
    CONSTRAINT chk_grace_period_days CHECK (grace_period_days >= 0),
    CONSTRAINT chk_renewal_notice_days CHECK (renewal_notice_days >= 0),
    CONSTRAINT chk_renewal_count CHECK (renewal_count >= 0),
    CONSTRAINT chk_termination_dates CHECK (termination_date IS NULL OR termination_date >= contract_start_date),
    CONSTRAINT chk_deposit_return CHECK (deposit_return_amount IS NULL OR deposit_return_amount <= deposit_amount)
);

-- 2. RLS 정책 활성화
ALTER TABLE bms.lease_contracts ENABLE ROW LEVEL SECURITY;

-- 3. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY contract_isolation_policy ON bms.lease_contracts
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 4. 성능 최적화 인덱스 생성
CREATE INDEX idx_contracts_company_id ON bms.lease_contracts(company_id);
CREATE INDEX idx_contracts_building_id ON bms.lease_contracts(building_id);
CREATE INDEX idx_contracts_unit_id ON bms.lease_contracts(unit_id);
CREATE INDEX idx_contracts_lessor_id ON bms.lease_contracts(lessor_id);
CREATE INDEX idx_contracts_tenant_id ON bms.lease_contracts(tenant_id);
CREATE INDEX idx_contracts_contract_number ON bms.lease_contracts(contract_number);
CREATE INDEX idx_contracts_contract_status ON bms.lease_contracts(contract_status);
CREATE INDEX idx_contracts_contract_start_date ON bms.lease_contracts(contract_start_date);
CREATE INDEX idx_contracts_contract_end_date ON bms.lease_contracts(contract_end_date);
CREATE INDEX idx_contracts_next_renewal_date ON bms.lease_contracts(next_renewal_date);
CREATE INDEX idx_contracts_termination_date ON bms.lease_contracts(termination_date);

-- 복합 인덱스 (자주 함께 조회되는 컬럼들)
CREATE INDEX idx_contracts_company_status ON bms.lease_contracts(company_id, contract_status);
CREATE INDEX idx_contracts_building_unit ON bms.lease_contracts(building_id, unit_id);
CREATE INDEX idx_contracts_status_dates ON bms.lease_contracts(contract_status, contract_start_date, contract_end_date);
CREATE INDEX idx_contracts_lessor_tenant ON bms.lease_contracts(lessor_id, tenant_id);

-- 5. updated_at 자동 업데이트 트리거
CREATE TRIGGER contracts_updated_at_trigger
    BEFORE UPDATE ON bms.lease_contracts
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 6. 계약 정보 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_contract_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 계약 기간 검증
    IF NEW.contract_end_date <= NEW.contract_start_date THEN
        RAISE EXCEPTION '계약 종료일은 시작일보다 늦어야 합니다.';
    END IF;
    
    -- 계약 기간 (개월) 자동 계산
    NEW.contract_duration_months := EXTRACT(YEAR FROM AGE(NEW.contract_end_date, NEW.contract_start_date)) * 12 + 
                                    EXTRACT(MONTH FROM AGE(NEW.contract_end_date, NEW.contract_start_date));
    
    -- 다음 갱신 예정일 자동 설정 (자동 갱신인 경우)
    IF NEW.auto_renewal = true AND NEW.next_renewal_date IS NULL THEN
        NEW.next_renewal_date := NEW.contract_end_date;
    END IF;
    
    -- 임대료 지급일 검증
    IF NEW.rent_payment_day < 1 OR NEW.rent_payment_day > 31 THEN
        RAISE EXCEPTION '임대료 지급일은 1-31일 범위여야 합니다.';
    END IF;
    
    -- 연체료율 검증
    IF NEW.late_fee_rate < 0 OR NEW.late_fee_rate > 100 THEN
        RAISE EXCEPTION '연체료율은 0-100% 범위여야 합니다.';
    END IF;
    
    -- 보증금 반환액 검증
    IF NEW.deposit_return_amount IS NOT NULL AND NEW.deposit_return_amount > NEW.deposit_amount THEN
        RAISE EXCEPTION '보증금 반환액은 보증금을 초과할 수 없습니다.';
    END IF;
    
    -- 계약 상태별 검증
    IF NEW.contract_status = 'ACTIVE' THEN
        -- 활성 계약은 서명이 완료되어야 함
        IF NEW.lessor_signature = false OR NEW.tenant_signature = false THEN
            RAISE EXCEPTION '활성 계약은 임대인과 임차인 모두 서명이 완료되어야 합니다.';
        END IF;
        
        -- 계약 체결일이 설정되어야 함
        IF NEW.contract_signed_date IS NULL THEN
            NEW.contract_signed_date := CURRENT_DATE;
        END IF;
    END IF;
    
    -- 해지된 계약은 해지일과 사유가 있어야 함
    IF NEW.contract_status = 'TERMINATED' THEN
        IF NEW.termination_date IS NULL THEN
            NEW.termination_date := CURRENT_DATE;
        END IF;
        IF NEW.termination_reason IS NULL THEN
            RAISE EXCEPTION '해지된 계약은 해지 사유가 필요합니다.';
        END IF;
    END IF;
    
    -- 만료된 계약 자동 처리
    IF NEW.contract_status = 'ACTIVE' AND NEW.contract_end_date < CURRENT_DATE THEN
        NEW.contract_status := 'EXPIRED';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. 계약 검증 트리거 생성
CREATE TRIGGER trg_validate_contract_data
    BEFORE INSERT OR UPDATE ON bms.lease_contracts
    FOR EACH ROW EXECUTE FUNCTION bms.validate_contract_data();

-- 8. 계약 상태 변경 이력 함수
CREATE OR REPLACE FUNCTION bms.log_contract_status_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 로그 기록
    IF TG_OP = 'UPDATE' AND OLD.contract_status IS DISTINCT FROM NEW.contract_status THEN
        -- 상태 변경 이력 테이블이 있다면 여기에 로그 기록
        -- 현재는 주석 처리 (4.1 태스크에서 구현 예정)
        RAISE NOTICE '계약 % 상태가 %에서 %로 변경되었습니다.', NEW.contract_number, OLD.contract_status, NEW.contract_status;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 9. 상태 변경 이력 트리거 생성
CREATE TRIGGER trg_log_contract_status_changes
    AFTER UPDATE ON bms.lease_contracts
    FOR EACH ROW EXECUTE FUNCTION bms.log_contract_status_changes();

-- 10. 계약 요약 뷰 생성
CREATE OR REPLACE VIEW bms.v_contract_summary AS
SELECT 
    c.contract_id,
    c.company_id,
    c.contract_number,
    c.contract_type,
    c.contract_status,
    b.name as building_name,
    u.unit_number,
    l.lessor_name,
    t.tenant_name,
    c.contract_start_date,
    c.contract_end_date,
    c.contract_duration_months,
    c.deposit_amount,
    c.monthly_rent,
    c.maintenance_fee,
    c.rent_payment_day,
    c.auto_renewal,
    c.next_renewal_date,
    c.termination_date,
    c.termination_reason,
    CASE 
        WHEN c.contract_status = 'ACTIVE' AND c.contract_end_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN c.contract_status = 'ACTIVE' AND c.contract_end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        WHEN c.contract_status = 'ACTIVE' AND c.contract_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 'EXPIRING_IN_3_MONTHS'
        ELSE c.contract_status
    END as effective_status,
    c.created_at,
    c.updated_at
FROM bms.lease_contracts c
JOIN bms.buildings b ON c.building_id = b.building_id
JOIN bms.units u ON c.unit_id = u.unit_id
JOIN bms.lessors l ON c.lessor_id = l.lessor_id
JOIN bms.tenants t ON c.tenant_id = t.tenant_id;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_contract_summary OWNER TO qiro;

-- 11. 계약 만료 예정 뷰 생성
CREATE OR REPLACE VIEW bms.v_contract_expiration_schedule AS
SELECT 
    c.contract_id,
    c.company_id,
    c.contract_number,
    b.name as building_name,
    u.unit_number,
    l.lessor_name,
    l.primary_phone as lessor_phone,
    t.tenant_name,
    t.primary_phone as tenant_phone,
    c.contract_start_date,
    c.contract_end_date,
    c.monthly_rent,
    c.deposit_amount,
    c.auto_renewal,
    c.renewal_notice_days,
    CASE 
        WHEN c.contract_end_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN c.contract_end_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'EXPIRING_THIS_WEEK'
        WHEN c.contract_end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_THIS_MONTH'
        WHEN c.contract_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 'EXPIRING_IN_3_MONTHS'
        ELSE 'FUTURE'
    END as expiration_urgency,
    CURRENT_DATE - c.contract_end_date as days_expired,
    c.contract_end_date - CURRENT_DATE as days_until_expiration
FROM bms.lease_contracts c
JOIN bms.buildings b ON c.building_id = b.building_id
JOIN bms.units u ON c.unit_id = u.unit_id
JOIN bms.lessors l ON c.lessor_id = l.lessor_id
JOIN bms.tenants t ON c.tenant_id = t.tenant_id
WHERE c.contract_status = 'ACTIVE'
ORDER BY c.contract_end_date;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_contract_expiration_schedule OWNER TO qiro;

-- 12. 계약 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_contract_statistics AS
SELECT 
    c.company_id,
    COUNT(*) as total_contracts,
    COUNT(CASE WHEN c.contract_status = 'ACTIVE' THEN 1 END) as active_contracts,
    COUNT(CASE WHEN c.contract_status = 'EXPIRED' THEN 1 END) as expired_contracts,
    COUNT(CASE WHEN c.contract_status = 'TERMINATED' THEN 1 END) as terminated_contracts,
    COUNT(CASE WHEN c.auto_renewal = true THEN 1 END) as auto_renewal_contracts,
    SUM(CASE WHEN c.contract_status = 'ACTIVE' THEN c.monthly_rent ELSE 0 END) as total_monthly_rent,
    AVG(CASE WHEN c.contract_status = 'ACTIVE' THEN c.monthly_rent END) as avg_monthly_rent,
    SUM(CASE WHEN c.contract_status = 'ACTIVE' THEN c.deposit_amount ELSE 0 END) as total_deposits,
    AVG(CASE WHEN c.contract_status = 'ACTIVE' THEN c.deposit_amount END) as avg_deposit,
    AVG(c.contract_duration_months) as avg_contract_duration,
    COUNT(CASE WHEN c.contract_end_date <= CURRENT_DATE + INTERVAL '30 days' AND c.contract_status = 'ACTIVE' THEN 1 END) as expiring_soon_count
FROM bms.lease_contracts c
GROUP BY c.company_id;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_contract_statistics OWNER TO qiro;

-- 13. 임대료 수납 일정 뷰 생성
CREATE OR REPLACE VIEW bms.v_rent_payment_schedule AS
SELECT 
    c.contract_id,
    c.company_id,
    c.contract_number,
    b.name as building_name,
    u.unit_number,
    l.lessor_name,
    t.tenant_name,
    t.primary_phone as tenant_phone,
    c.monthly_rent,
    c.maintenance_fee,
    c.rent_payment_day,
    c.payment_method,
    c.late_fee_rate,
    c.grace_period_days,
    CASE 
        WHEN c.rent_payment_day <= 5 THEN 'EARLY_MONTH'
        WHEN c.rent_payment_day <= 15 THEN 'MID_MONTH'
        WHEN c.rent_payment_day <= 25 THEN 'LATE_MONTH'
        ELSE 'END_MONTH'
    END as payment_period
FROM bms.lease_contracts c
JOIN bms.buildings b ON c.building_id = b.building_id
JOIN bms.units u ON c.unit_id = u.unit_id
JOIN bms.lessors l ON c.lessor_id = l.lessor_id
JOIN bms.tenants t ON c.tenant_id = t.tenant_id
WHERE c.contract_status = 'ACTIVE'
ORDER BY c.rent_payment_day, b.name, u.unit_number;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_rent_payment_schedule OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 2.3 계약 관리 테이블 생성이 완료되었습니다!' as result;