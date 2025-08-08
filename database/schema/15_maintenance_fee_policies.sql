-- =====================================================
-- 관리비 정책 테이블 생성 스크립트
-- Phase 2.1.2: 관리비 정책 테이블 생성
-- =====================================================

-- 1. 관리비 부과 정책 테이블
CREATE TABLE IF NOT EXISTS bms.maintenance_fee_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                   -- NULL이면 회사 전체 정책
    
    -- 정책 기본 정보
    policy_name VARCHAR(100) NOT NULL,                  -- 정책명
    policy_description TEXT,                            -- 정책 설명
    policy_type VARCHAR(20) NOT NULL,                   -- 정책 유형
    
    -- 부과 주기 설정
    billing_cycle VARCHAR(20) NOT NULL,                 -- 부과 주기
    billing_day INTEGER NOT NULL,                       -- 부과일 (매월 몇일)
    billing_advance_days INTEGER DEFAULT 0,             -- 사전 부과 일수
    
    -- 납부 기한 설정
    payment_due_days INTEGER NOT NULL,                  -- 납부 기한 (부과일로부터 며칠)
    grace_period_days INTEGER DEFAULT 0,                -- 유예 기간 (일)
    
    -- 연체료 정책
    late_fee_enabled BOOLEAN DEFAULT true,              -- 연체료 적용 여부
    late_fee_rate DECIMAL(8,4),                         -- 연체료율 (% per month)
    late_fee_calculation_method VARCHAR(20),            -- 연체료 계산 방식
    late_fee_min_amount DECIMAL(15,4),                  -- 최소 연체료
    late_fee_max_amount DECIMAL(15,4),                  -- 최대 연체료
    compound_interest BOOLEAN DEFAULT false,            -- 복리 적용 여부
    
    -- 할인 정책
    early_payment_discount_enabled BOOLEAN DEFAULT false, -- 조기 납부 할인 여부
    early_payment_discount_rate DECIMAL(8,4),           -- 조기 납부 할인율 (%)
    early_payment_discount_days INTEGER,                -- 조기 납부 기준 일수
    
    -- 감면 정책
    exemption_enabled BOOLEAN DEFAULT false,            -- 감면 적용 여부
    exemption_criteria JSONB,                           -- 감면 기준 (JSON)
    
    -- 부분 납부 정책
    partial_payment_allowed BOOLEAN DEFAULT true,       -- 부분 납부 허용 여부
    partial_payment_allocation_method VARCHAR(20),      -- 부분 납부 배분 방식
    minimum_payment_ratio DECIMAL(8,4),                 -- 최소 납부 비율 (%)
    
    -- 선납 정책
    advance_payment_allowed BOOLEAN DEFAULT true,       -- 선납 허용 여부
    advance_payment_max_months INTEGER DEFAULT 12,      -- 최대 선납 개월 수
    advance_payment_discount_rate DECIMAL(8,4),         -- 선납 할인율 (%)
    
    -- 자동화 설정
    auto_billing_enabled BOOLEAN DEFAULT true,          -- 자동 부과 여부
    auto_late_fee_enabled BOOLEAN DEFAULT true,         -- 자동 연체료 부과 여부
    auto_reminder_enabled BOOLEAN DEFAULT true,         -- 자동 알림 발송 여부
    
    -- 알림 설정
    reminder_schedule JSONB,                            -- 알림 일정 (JSON)
    notification_methods TEXT[],                        -- 알림 방법 목록
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_fee_policies_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fee_policies_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_policy_type CHECK (policy_type IN (
        'STANDARD',             -- 표준 정책
        'PREMIUM',              -- 프리미엄 정책
        'SOCIAL',               -- 사회적 배려 정책
        'COMMERCIAL',           -- 상업용 정책
        'CUSTOM'                -- 사용자 정의 정책
    )),
    CONSTRAINT chk_billing_cycle CHECK (billing_cycle IN (
        'MONTHLY',              -- 월별
        'QUARTERLY',            -- 분기별
        'SEMI_ANNUAL',          -- 반기별
        'ANNUAL'                -- 연간
    )),
    CONSTRAINT chk_billing_day CHECK (billing_day BETWEEN 1 AND 31),
    CONSTRAINT chk_payment_due_days CHECK (payment_due_days > 0),
    CONSTRAINT chk_grace_period_days CHECK (grace_period_days >= 0),
    CONSTRAINT chk_late_fee_rate CHECK (late_fee_rate IS NULL OR (late_fee_rate >= 0 AND late_fee_rate <= 100)),
    CONSTRAINT chk_late_fee_calculation_method CHECK (late_fee_calculation_method IN (
        'SIMPLE_INTEREST',      -- 단리
        'COMPOUND_INTEREST',    -- 복리
        'FIXED_AMOUNT',         -- 정액
        'PROGRESSIVE'           -- 누진
    )),
    CONSTRAINT chk_early_payment_discount_rate CHECK (early_payment_discount_rate IS NULL OR (early_payment_discount_rate >= 0 AND early_payment_discount_rate <= 100)),
    CONSTRAINT chk_partial_payment_allocation CHECK (partial_payment_allocation_method IN (
        'PRINCIPAL_FIRST',      -- 원금 우선
        'INTEREST_FIRST',       -- 이자 우선
        'PROPORTIONAL',         -- 비례 배분
        'OLDEST_FIRST'          -- 오래된 것 우선
    )),
    CONSTRAINT chk_minimum_payment_ratio CHECK (minimum_payment_ratio IS NULL OR (minimum_payment_ratio >= 0 AND minimum_payment_ratio <= 100)),
    CONSTRAINT chk_advance_payment_max_months CHECK (advance_payment_max_months > 0),
    CONSTRAINT chk_advance_payment_discount_rate CHECK (advance_payment_discount_rate IS NULL OR (advance_payment_discount_rate >= 0 AND advance_payment_discount_rate <= 100)),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 2. 호실별 개별 정책 설정 테이블
CREATE TABLE IF NOT EXISTS bms.unit_fee_policy_overrides (
    override_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unit_id UUID NOT NULL,
    policy_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 개별 설정 항목들
    custom_billing_day INTEGER,                         -- 개별 부과일
    custom_payment_due_days INTEGER,                    -- 개별 납부 기한
    custom_late_fee_rate DECIMAL(8,4),                  -- 개별 연체료율
    custom_discount_rate DECIMAL(8,4),                  -- 개별 할인율
    
    -- 특별 조건
    special_conditions JSONB,                           -- 특별 조건 (JSON)
    exemption_reason TEXT,                              -- 감면 사유
    exemption_amount DECIMAL(15,4),                     -- 감면 금액
    exemption_percentage DECIMAL(8,4),                  -- 감면 비율
    
    -- 승인 정보
    approved_by UUID,                                   -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,              -- 승인 일시
    approval_reason TEXT,                               -- 승인 사유
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_unit_policy_overrides_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_policy_overrides_policy FOREIGN KEY (policy_id) REFERENCES bms.maintenance_fee_policies(policy_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_policy_overrides_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_policy_overrides_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_unit_policy_overrides UNIQUE (unit_id, policy_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_custom_billing_day CHECK (custom_billing_day IS NULL OR custom_billing_day BETWEEN 1 AND 31),
    CONSTRAINT chk_custom_payment_due_days CHECK (custom_payment_due_days IS NULL OR custom_payment_due_days > 0),
    CONSTRAINT chk_custom_late_fee_rate CHECK (custom_late_fee_rate IS NULL OR (custom_late_fee_rate >= 0 AND custom_late_fee_rate <= 100)),
    CONSTRAINT chk_custom_discount_rate CHECK (custom_discount_rate IS NULL OR (custom_discount_rate >= 0 AND custom_discount_rate <= 100)),
    CONSTRAINT chk_exemption_percentage CHECK (exemption_percentage IS NULL OR (exemption_percentage >= 0 AND exemption_percentage <= 100)),
    CONSTRAINT chk_override_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 3. 관리비 정책 변경 이력 테이블
CREATE TABLE IF NOT EXISTS bms.fee_policy_change_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 변경 정보
    change_type VARCHAR(20) NOT NULL,                   -- 변경 유형
    changed_fields JSONB,                               -- 변경된 필드들 (JSON)
    old_values JSONB,                                   -- 이전 값들
    new_values JSONB,                                   -- 새 값들
    
    -- 변경 사유
    change_reason TEXT NOT NULL,                        -- 변경 사유
    change_description TEXT,                            -- 변경 설명
    impact_assessment TEXT,                             -- 영향 평가
    
    -- 승인 정보
    requested_by UUID,                                  -- 요청자
    approved_by UUID,                                   -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,              -- 승인 일시
    
    -- 적용 정보
    scheduled_effective_date DATE,                      -- 예정 적용일
    actual_effective_date DATE,                         -- 실제 적용일
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_policy_history_policy FOREIGN KEY (policy_id) REFERENCES bms.maintenance_fee_policies(policy_id) ON DELETE CASCADE,
    CONSTRAINT fk_policy_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_policy_history_requester FOREIGN KEY (requested_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_policy_history_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_change_type CHECK (change_type IN (
        'CREATE',               -- 생성
        'UPDATE',               -- 수정
        'DELETE',               -- 삭제
        'ACTIVATE',             -- 활성화
        'DEACTIVATE',           -- 비활성화
        'SCHEDULE'              -- 예약 변경
    ))
);

-- 4. 관리비 정책 템플릿 테이블
CREATE TABLE IF NOT EXISTS bms.fee_policy_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 템플릿 정보
    template_name VARCHAR(100) NOT NULL,                -- 템플릿명
    template_description TEXT,                          -- 템플릿 설명
    template_category VARCHAR(20) NOT NULL,             -- 템플릿 분류
    
    -- 정책 설정 (JSON으로 저장)
    policy_config JSONB NOT NULL,                       -- 정책 설정
    
    -- 적용 범위
    applicable_building_types TEXT[],                   -- 적용 가능한 건물 유형
    applicable_unit_types TEXT[],                       -- 적용 가능한 호실 유형
    
    -- 사용 통계
    usage_count INTEGER DEFAULT 0,                      -- 사용 횟수
    last_used_at TIMESTAMP WITH TIME ZONE,             -- 마지막 사용 일시
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    is_system_template BOOLEAN DEFAULT false,           -- 시스템 기본 템플릿 여부
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_policy_templates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_policy_templates_name UNIQUE (company_id, template_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_template_category CHECK (template_category IN (
        'RESIDENTIAL',          -- 주거용
        'COMMERCIAL',           -- 상업용
        'MIXED',                -- 복합용
        'PREMIUM',              -- 프리미엄
        'SOCIAL',               -- 사회적 배려
        'CUSTOM'                -- 사용자 정의
    ))
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.maintenance_fee_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.unit_fee_policy_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_policy_change_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_policy_templates ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY maintenance_fee_policies_isolation_policy ON bms.maintenance_fee_policies
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY unit_fee_policy_overrides_isolation_policy ON bms.unit_fee_policy_overrides
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_policy_change_history_isolation_policy ON bms.fee_policy_change_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_policy_templates_isolation_policy ON bms.fee_policy_templates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 관리비 정책 인덱스
CREATE INDEX idx_fee_policies_company_id ON bms.maintenance_fee_policies(company_id);
CREATE INDEX idx_fee_policies_building_id ON bms.maintenance_fee_policies(building_id);
CREATE INDEX idx_fee_policies_policy_type ON bms.maintenance_fee_policies(policy_type);
CREATE INDEX idx_fee_policies_billing_cycle ON bms.maintenance_fee_policies(billing_cycle);
CREATE INDEX idx_fee_policies_is_active ON bms.maintenance_fee_policies(is_active);
CREATE INDEX idx_fee_policies_effective_dates ON bms.maintenance_fee_policies(effective_start_date, effective_end_date);

-- 호실별 개별 정책 인덱스
CREATE INDEX idx_unit_policy_overrides_unit_id ON bms.unit_fee_policy_overrides(unit_id);
CREATE INDEX idx_unit_policy_overrides_policy_id ON bms.unit_fee_policy_overrides(policy_id);
CREATE INDEX idx_unit_policy_overrides_company_id ON bms.unit_fee_policy_overrides(company_id);
CREATE INDEX idx_unit_policy_overrides_is_active ON bms.unit_fee_policy_overrides(is_active);

-- 정책 변경 이력 인덱스
CREATE INDEX idx_policy_history_policy_id ON bms.fee_policy_change_history(policy_id);
CREATE INDEX idx_policy_history_company_id ON bms.fee_policy_change_history(company_id);
CREATE INDEX idx_policy_history_change_type ON bms.fee_policy_change_history(change_type);
CREATE INDEX idx_policy_history_created_at ON bms.fee_policy_change_history(created_at DESC);

-- 정책 템플릿 인덱스
CREATE INDEX idx_policy_templates_company_id ON bms.fee_policy_templates(company_id);
CREATE INDEX idx_policy_templates_category ON bms.fee_policy_templates(template_category);
CREATE INDEX idx_policy_templates_is_active ON bms.fee_policy_templates(is_active);

-- 복합 인덱스
CREATE INDEX idx_fee_policies_company_active ON bms.maintenance_fee_policies(company_id, is_active);
CREATE INDEX idx_fee_policies_building_active ON bms.maintenance_fee_policies(building_id, is_active);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER maintenance_fee_policies_updated_at_trigger
    BEFORE UPDATE ON bms.maintenance_fee_policies
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER unit_fee_policy_overrides_updated_at_trigger
    BEFORE UPDATE ON bms.unit_fee_policy_overrides
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fee_policy_templates_updated_at_trigger
    BEFORE UPDATE ON bms.fee_policy_templates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 관리비 정책 관리 함수들
-- 유효한 정책 조회 함수
CREATE OR REPLACE FUNCTION bms.get_effective_fee_policy(
    p_building_id UUID DEFAULT NULL,
    p_unit_id UUID DEFAULT NULL,
    p_reference_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    policy_id UUID,
    policy_name VARCHAR(100),
    billing_cycle VARCHAR(20),
    billing_day INTEGER,
    payment_due_days INTEGER,
    late_fee_rate DECIMAL(8,4),
    early_payment_discount_rate DECIMAL(8,4)
) AS $$
DECLARE
    v_company_id UUID;
BEGIN
    -- 회사 ID 가져오기
    IF p_building_id IS NOT NULL THEN
        SELECT company_id INTO v_company_id
        FROM bms.buildings
        WHERE building_id = p_building_id;
    ELSIF p_unit_id IS NOT NULL THEN
        SELECT b.company_id INTO v_company_id
        FROM bms.units u
        JOIN bms.buildings b ON u.building_id = b.building_id
        WHERE u.unit_id = p_unit_id;
    ELSE
        v_company_id := (current_setting('app.current_company_id', true))::uuid;
    END IF;
    
    RETURN QUERY
    SELECT 
        mfp.policy_id,
        mfp.policy_name,
        mfp.billing_cycle,
        COALESCE(upo.custom_billing_day, mfp.billing_day) as billing_day,
        COALESCE(upo.custom_payment_due_days, mfp.payment_due_days) as payment_due_days,
        COALESCE(upo.custom_late_fee_rate, mfp.late_fee_rate) as late_fee_rate,
        COALESCE(upo.custom_discount_rate, mfp.early_payment_discount_rate) as early_payment_discount_rate
    FROM bms.maintenance_fee_policies mfp
    LEFT JOIN bms.unit_fee_policy_overrides upo ON mfp.policy_id = upo.policy_id AND upo.unit_id = p_unit_id
    WHERE mfp.company_id = v_company_id
      AND (mfp.building_id = p_building_id OR mfp.building_id IS NULL)
      AND mfp.is_active = true
      AND mfp.effective_start_date <= p_reference_date
      AND (mfp.effective_end_date IS NULL OR mfp.effective_end_date >= p_reference_date)
      AND (upo.is_active IS NULL OR upo.is_active = true)
    ORDER BY mfp.building_id NULLS LAST  -- 건물별 정책을 우선
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 연체료 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_late_fee(
    p_principal_amount DECIMAL(15,4),
    p_overdue_days INTEGER,
    p_late_fee_rate DECIMAL(8,4),
    p_calculation_method VARCHAR(20) DEFAULT 'SIMPLE_INTEREST',
    p_min_amount DECIMAL(15,4) DEFAULT NULL,
    p_max_amount DECIMAL(15,4) DEFAULT NULL
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    v_late_fee DECIMAL(15,4) := 0;
    v_monthly_rate DECIMAL(8,4);
BEGIN
    -- 연체일이 0 이하이면 연체료 없음
    IF p_overdue_days <= 0 OR p_late_fee_rate IS NULL OR p_late_fee_rate = 0 THEN
        RETURN 0;
    END IF;
    
    -- 월 이율 계산
    v_monthly_rate := p_late_fee_rate / 100;
    
    -- 계산 방식에 따른 연체료 계산
    CASE p_calculation_method
        WHEN 'SIMPLE_INTEREST' THEN
            -- 단리: 원금 × 연체료율 × (연체일수 / 30)
            v_late_fee := p_principal_amount * v_monthly_rate * (p_overdue_days::DECIMAL / 30);
            
        WHEN 'COMPOUND_INTEREST' THEN
            -- 복리: 원금 × ((1 + 월이율)^(연체일수/30) - 1)
            v_late_fee := p_principal_amount * (POWER(1 + v_monthly_rate, p_overdue_days::DECIMAL / 30) - 1);
            
        WHEN 'FIXED_AMOUNT' THEN
            -- 정액: 연체료율을 정액으로 간주
            v_late_fee := p_late_fee_rate * CEIL(p_overdue_days::DECIMAL / 30);
            
        WHEN 'PROGRESSIVE' THEN
            -- 누진: 연체 기간에 따라 요율 증가
            DECLARE
                v_base_rate DECIMAL(8,4) := v_monthly_rate;
                v_months INTEGER := CEIL(p_overdue_days::DECIMAL / 30);
            BEGIN
                FOR i IN 1..v_months LOOP
                    v_late_fee := v_late_fee + (p_principal_amount * v_base_rate * (1 + (i-1) * 0.1));
                END LOOP;
            END;
            
        ELSE
            -- 기본값: 단리 계산
            v_late_fee := p_principal_amount * v_monthly_rate * (p_overdue_days::DECIMAL / 30);
    END CASE;
    
    -- 최소/최대 금액 적용
    IF p_min_amount IS NOT NULL AND v_late_fee < p_min_amount THEN
        v_late_fee := p_min_amount;
    END IF;
    
    IF p_max_amount IS NOT NULL AND v_late_fee > p_max_amount THEN
        v_late_fee := p_max_amount;
    END IF;
    
    RETURN ROUND(v_late_fee, 0);  -- 원 단위로 반올림
END;
$$ LANGUAGE plpgsql;

-- 10. 관리비 정책 뷰 생성
CREATE OR REPLACE VIEW bms.v_active_fee_policies AS
SELECT 
    mfp.policy_id,
    mfp.company_id,
    c.company_name,
    mfp.building_id,
    b.name as building_name,
    mfp.policy_name,
    mfp.policy_type,
    mfp.billing_cycle,
    mfp.billing_day,
    mfp.payment_due_days,
    mfp.grace_period_days,
    mfp.late_fee_enabled,
    mfp.late_fee_rate,
    mfp.late_fee_calculation_method,
    mfp.early_payment_discount_enabled,
    mfp.early_payment_discount_rate,
    mfp.partial_payment_allowed,
    mfp.advance_payment_allowed,
    mfp.auto_billing_enabled,
    mfp.effective_start_date,
    mfp.effective_end_date
FROM bms.maintenance_fee_policies mfp
JOIN bms.companies c ON mfp.company_id = c.company_id
LEFT JOIN bms.buildings b ON mfp.building_id = b.building_id
WHERE mfp.is_active = true
  AND mfp.effective_start_date <= CURRENT_DATE
  AND (mfp.effective_end_date IS NULL OR mfp.effective_end_date >= CURRENT_DATE)
ORDER BY c.company_name, b.name NULLS FIRST, mfp.policy_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_active_fee_policies OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 1.2 관리비 정책 테이블 생성이 완료되었습니다!' as result;