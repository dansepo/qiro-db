-- =====================================================
-- 관리비 항목 마스터 테이블 생성 스크립트
-- Phase 3.2: 관리비 항목 마스터 테이블
-- =====================================================

-- 1. 관리비 항목 마스터 테이블 생성
CREATE TABLE IF NOT EXISTS bms.fee_items (
    fee_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                   -- NULL이면 회사 전체 공통 항목
    
    -- 기본 정보
    item_code VARCHAR(50) NOT NULL,                     -- 항목 코드 (MGMT_FEE, ELECTRIC, WATER 등)
    item_name VARCHAR(200) NOT NULL,                    -- 항목명
    item_description TEXT,                              -- 항목 설명
    item_category VARCHAR(50) NOT NULL,                 -- 항목 분류
    
    -- 계산 방식
    calculation_method VARCHAR(30) NOT NULL DEFAULT 'FIXED', -- 계산 방식
    base_amount DECIMAL(12,2) DEFAULT 0,                -- 기본 금액
    unit_price DECIMAL(10,4) DEFAULT 0,                 -- 단가 (사용량 기준 시)
    calculation_unit VARCHAR(20),                       -- 계산 단위 (㎡, kWh, ㎥ 등)
    
    -- 적용 기준
    apply_to_all_units BOOLEAN DEFAULT true,            -- 모든 호실 적용 여부
    apply_to_unit_types TEXT[],                         -- 적용 호실 타입들 (배열)
    min_area DECIMAL(10,2),                             -- 최소 적용 면적
    max_area DECIMAL(10,2),                             -- 최대 적용 면적
    
    -- 요율 및 할인
    tax_rate DECIMAL(5,2) DEFAULT 0,                    -- 세율 (%)
    discount_rate DECIMAL(5,2) DEFAULT 0,               -- 할인율 (%)
    late_fee_rate DECIMAL(5,2) DEFAULT 0,               -- 연체료율 (%)
    
    -- 청구 주기
    billing_cycle VARCHAR(20) DEFAULT 'MONTHLY',        -- 청구 주기
    billing_day INTEGER DEFAULT 1,                      -- 청구일
    due_days INTEGER DEFAULT 30,                        -- 납부 기한 (일)
    
    -- 외부 연동
    external_system_code VARCHAR(100),                  -- 외부 시스템 코드
    meter_reading_required BOOLEAN DEFAULT false,       -- 검침 필요 여부
    auto_calculation BOOLEAN DEFAULT true,               -- 자동 계산 여부
    
    -- 표시 설정
    display_order INTEGER DEFAULT 0,                    -- 표시 순서
    show_in_invoice BOOLEAN DEFAULT true,                -- 고지서 표시 여부
    show_breakdown BOOLEAN DEFAULT false,                -- 세부 내역 표시 여부
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,     -- 유효 시작일
    effective_end_date DATE,                            -- 유효 종료일
    
    -- 상태 관리
    is_active BOOLEAN DEFAULT true,                     -- 활성 상태
    is_mandatory BOOLEAN DEFAULT false,                 -- 필수 항목 여부
    is_system_item BOOLEAN DEFAULT false,               -- 시스템 항목 여부
    
    -- 추가 설정 (JSON)
    calculation_formula TEXT,                           -- 계산 공식
    additional_settings JSONB DEFAULT '{}',             -- 추가 설정
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_fee_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fee_items_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    -- UNIQUE 제약조건은 별도 인덱스로 처리
    
    -- 체크 제약조건
    CONSTRAINT chk_calculation_method CHECK (calculation_method IN (
        'FIXED',           -- 정액
        'AREA_BASED',      -- 면적 비례
        'USAGE_BASED',     -- 사용량 비례
        'UNIT_COUNT',      -- 호실 수 기준
        'PERCENTAGE',      -- 비율 기준
        'FORMULA',         -- 공식 기준
        'EXTERNAL'         -- 외부 연동
    )),
    CONSTRAINT chk_item_category CHECK (item_category IN (
        'MANAGEMENT',      -- 일반 관리비
        'UTILITY',         -- 공과금
        'MAINTENANCE',     -- 유지보수비
        'INSURANCE',       -- 보험료
        'SECURITY',        -- 경비비
        'CLEANING',        -- 청소비
        'FACILITY',        -- 시설 이용료
        'PARKING',         -- 주차비
        'OTHER'            -- 기타
    )),
    CONSTRAINT chk_billing_cycle CHECK (billing_cycle IN (
        'MONTHLY',         -- 월별
        'QUARTERLY',       -- 분기별
        'SEMI_ANNUAL',     -- 반기별
        'ANNUAL',          -- 연별
        'ON_DEMAND'        -- 수시
    )),
    CONSTRAINT chk_base_amount CHECK (base_amount >= 0),
    CONSTRAINT chk_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_tax_rate CHECK (tax_rate >= 0 AND tax_rate <= 100),
    CONSTRAINT chk_discount_rate CHECK (discount_rate >= 0 AND discount_rate <= 100),
    CONSTRAINT chk_late_fee_rate CHECK (late_fee_rate >= 0 AND late_fee_rate <= 100),
    CONSTRAINT chk_billing_day CHECK (billing_day >= 1 AND billing_day <= 31),
    CONSTRAINT chk_due_days CHECK (due_days >= 0),
    CONSTRAINT chk_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date),
    CONSTRAINT chk_area_range CHECK (max_area IS NULL OR min_area IS NULL OR max_area >= min_area)
);

-- 2. 관리비 항목별 요율 테이블 생성 (시간대별, 계절별 요율 지원)
CREATE TABLE IF NOT EXISTS bms.fee_item_rates (
    rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    fee_item_id UUID NOT NULL,
    
    -- 요율 정보
    rate_name VARCHAR(200) NOT NULL,                    -- 요율명
    rate_type VARCHAR(30) NOT NULL DEFAULT 'STANDARD',  -- 요율 타입
    rate_value DECIMAL(10,4) NOT NULL,                  -- 요율 값
    
    -- 적용 조건
    apply_condition JSONB DEFAULT '{}',                 -- 적용 조건 (JSON)
    min_usage DECIMAL(12,2),                            -- 최소 사용량
    max_usage DECIMAL(12,2),                            -- 최대 사용량
    
    -- 시간 조건
    apply_start_time TIME,                              -- 적용 시작 시간
    apply_end_time TIME,                                -- 적용 종료 시간
    apply_weekdays INTEGER[],                           -- 적용 요일 (1=월, 7=일)
    apply_months INTEGER[],                             -- 적용 월 (1-12)
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_fee_rates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fee_rates_fee_item FOREIGN KEY (fee_item_id) REFERENCES bms.fee_items(fee_item_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_rate_type CHECK (rate_type IN (
        'STANDARD',        -- 표준 요율
        'PEAK',           -- 피크 요율
        'OFF_PEAK',       -- 비피크 요율
        'SEASONAL',       -- 계절 요율
        'PROGRESSIVE',    -- 누진 요율
        'DISCOUNT',       -- 할인 요율
        'PENALTY'         -- 가산 요율
    )),
    CONSTRAINT chk_rate_value CHECK (rate_value >= 0),
    CONSTRAINT chk_usage_range CHECK (max_usage IS NULL OR min_usage IS NULL OR max_usage >= min_usage),
    CONSTRAINT chk_time_range CHECK (apply_end_time IS NULL OR apply_start_time IS NULL OR apply_end_time >= apply_start_time),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 3. RLS 정책 활성화
ALTER TABLE bms.fee_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_item_rates ENABLE ROW LEVEL SECURITY;

-- 4. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY fee_items_isolation_policy ON bms.fee_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_item_rates_isolation_policy ON bms.fee_item_rates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 5. 성능 최적화 인덱스 생성
-- 관리비 항목 테이블 인덱스
CREATE INDEX idx_fee_items_company_id ON bms.fee_items(company_id);
CREATE INDEX idx_fee_items_building_id ON bms.fee_items(building_id);
CREATE INDEX idx_fee_items_item_code ON bms.fee_items(item_code);
CREATE INDEX idx_fee_items_item_category ON bms.fee_items(item_category);
CREATE INDEX idx_fee_items_calculation_method ON bms.fee_items(calculation_method);
CREATE INDEX idx_fee_items_is_active ON bms.fee_items(is_active);
CREATE INDEX idx_fee_items_effective_dates ON bms.fee_items(effective_start_date, effective_end_date);
CREATE INDEX idx_fee_items_billing_cycle ON bms.fee_items(billing_cycle);
CREATE INDEX idx_fee_items_display_order ON bms.fee_items(display_order);

-- 요율 테이블 인덱스
CREATE INDEX idx_fee_rates_company_id ON bms.fee_item_rates(company_id);
CREATE INDEX idx_fee_rates_fee_item_id ON bms.fee_item_rates(fee_item_id);
CREATE INDEX idx_fee_rates_rate_type ON bms.fee_item_rates(rate_type);
CREATE INDEX idx_fee_rates_is_active ON bms.fee_item_rates(is_active);
CREATE INDEX idx_fee_rates_effective_dates ON bms.fee_item_rates(effective_start_date, effective_end_date);

-- 복합 인덱스
CREATE INDEX idx_fee_items_company_building ON bms.fee_items(company_id, building_id);
CREATE INDEX idx_fee_items_company_active ON bms.fee_items(company_id, is_active);
CREATE INDEX idx_fee_items_category_active ON bms.fee_items(item_category, is_active);
CREATE INDEX idx_fee_rates_item_active ON bms.fee_item_rates(fee_item_id, is_active);

-- 유니크 인덱스 (NULL 값 처리를 위해)
CREATE UNIQUE INDEX uk_fee_items_company_building_code 
ON bms.fee_items(company_id, COALESCE(building_id, '00000000-0000-0000-0000-000000000000'::UUID), item_code);

-- 6. updated_at 자동 업데이트 트리거
CREATE TRIGGER fee_items_updated_at_trigger
    BEFORE UPDATE ON bms.fee_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fee_item_rates_updated_at_trigger
    BEFORE UPDATE ON bms.fee_item_rates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 7. 관리비 항목 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_fee_item_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 유효 기간 검증
    IF NEW.effective_end_date IS NOT NULL AND NEW.effective_end_date < NEW.effective_start_date THEN
        RAISE EXCEPTION '유효 종료일은 시작일보다 늦어야 합니다.';
    END IF;
    
    -- 면적 범위 검증
    IF NEW.max_area IS NOT NULL AND NEW.min_area IS NOT NULL AND NEW.max_area < NEW.min_area THEN
        RAISE EXCEPTION '최대 면적은 최소 면적보다 크거나 같아야 합니다.';
    END IF;
    
    -- 계산 방식별 필수 값 검증
    IF NEW.calculation_method = 'FIXED' AND NEW.base_amount = 0 THEN
        RAISE EXCEPTION '정액 방식은 기본 금액이 설정되어야 합니다.';
    END IF;
    
    IF NEW.calculation_method IN ('AREA_BASED', 'USAGE_BASED') AND NEW.unit_price = 0 THEN
        RAISE EXCEPTION '면적/사용량 기준 방식은 단가가 설정되어야 합니다.';
    END IF;
    
    IF NEW.calculation_method IN ('AREA_BASED', 'USAGE_BASED') AND NEW.calculation_unit IS NULL THEN
        RAISE EXCEPTION '면적/사용량 기준 방식은 계산 단위가 설정되어야 합니다.';
    END IF;
    
    IF NEW.calculation_method = 'FORMULA' AND NEW.calculation_formula IS NULL THEN
        RAISE EXCEPTION '공식 기준 방식은 계산 공식이 설정되어야 합니다.';
    END IF;
    
    -- 청구일 검증
    IF NEW.billing_day < 1 OR NEW.billing_day > 31 THEN
        RAISE EXCEPTION '청구일은 1-31일 범위여야 합니다.';
    END IF;
    
    -- 시스템 항목 수정 방지
    IF TG_OP = 'UPDATE' AND OLD.is_system_item = true THEN
        IF OLD.item_code IS DISTINCT FROM NEW.item_code OR
           OLD.calculation_method IS DISTINCT FROM NEW.calculation_method THEN
            RAISE EXCEPTION '시스템 항목의 핵심 설정은 수정할 수 없습니다.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. 관리비 항목 검증 트리거 생성
CREATE TRIGGER trg_validate_fee_item_data
    BEFORE INSERT OR UPDATE ON bms.fee_items
    FOR EACH ROW EXECUTE FUNCTION bms.validate_fee_item_data();

-- 9. 활성 관리비 항목 뷰 생성
CREATE OR REPLACE VIEW bms.v_active_fee_items AS
SELECT 
    f.fee_item_id,
    f.company_id,
    f.building_id,
    b.name as building_name,
    f.item_code,
    f.item_name,
    f.item_description,
    f.item_category,
    f.calculation_method,
    f.base_amount,
    f.unit_price,
    f.calculation_unit,
    f.apply_to_all_units,
    f.apply_to_unit_types,
    f.tax_rate,
    f.discount_rate,
    f.billing_cycle,
    f.billing_day,
    f.due_days,
    f.display_order,
    f.show_in_invoice,
    f.is_mandatory,
    f.meter_reading_required,
    f.effective_start_date,
    f.effective_end_date
FROM bms.fee_items f
LEFT JOIN bms.buildings b ON f.building_id = b.building_id
WHERE f.is_active = true
  AND f.effective_start_date <= CURRENT_DATE
  AND (f.effective_end_date IS NULL OR f.effective_end_date >= CURRENT_DATE)
ORDER BY f.display_order, f.item_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_active_fee_items OWNER TO qiro;

-- 10. 건물별 관리비 항목 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_building_fee_statistics AS
SELECT 
    COALESCE(f.building_id, '00000000-0000-0000-0000-000000000000'::UUID) as building_id,
    COALESCE(b.name, '전체 공통') as building_name,
    f.company_id,
    COUNT(*) as total_fee_items,
    COUNT(CASE WHEN f.is_active = true THEN 1 END) as active_fee_items,
    COUNT(CASE WHEN f.is_mandatory = true THEN 1 END) as mandatory_fee_items,
    COUNT(CASE WHEN f.calculation_method = 'FIXED' THEN 1 END) as fixed_fee_items,
    COUNT(CASE WHEN f.calculation_method = 'AREA_BASED' THEN 1 END) as area_based_items,
    COUNT(CASE WHEN f.calculation_method = 'USAGE_BASED' THEN 1 END) as usage_based_items,
    COUNT(CASE WHEN f.meter_reading_required = true THEN 1 END) as meter_reading_items,
    SUM(CASE WHEN f.calculation_method = 'FIXED' AND f.is_active = true THEN f.base_amount ELSE 0 END) as total_fixed_amount,
    AVG(CASE WHEN f.calculation_method = 'FIXED' AND f.is_active = true THEN f.base_amount END) as avg_fixed_amount
FROM bms.fee_items f
LEFT JOIN bms.buildings b ON f.building_id = b.building_id
GROUP BY COALESCE(f.building_id, '00000000-0000-0000-0000-000000000000'::UUID), COALESCE(b.name, '전체 공통'), f.company_id
ORDER BY building_name;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_fee_statistics OWNER TO qiro;

-- 11. 관리비 항목 분류별 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_fee_category_statistics AS
SELECT 
    f.company_id,
    f.item_category,
    COUNT(*) as total_items,
    COUNT(CASE WHEN f.is_active = true THEN 1 END) as active_items,
    COUNT(CASE WHEN f.calculation_method = 'FIXED' THEN 1 END) as fixed_items,
    COUNT(CASE WHEN f.calculation_method = 'AREA_BASED' THEN 1 END) as area_based_items,
    COUNT(CASE WHEN f.calculation_method = 'USAGE_BASED' THEN 1 END) as usage_based_items,
    AVG(f.base_amount) as avg_base_amount,
    AVG(f.unit_price) as avg_unit_price,
    COUNT(CASE WHEN f.is_mandatory = true THEN 1 END) as mandatory_items
FROM bms.fee_items f
GROUP BY f.company_id, f.item_category
ORDER BY f.item_category;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_fee_category_statistics OWNER TO qiro;

-- 12. 관리비 계산 함수 생성
CREATE OR REPLACE FUNCTION bms.calculate_fee_amount(
    p_fee_item_id UUID,
    p_unit_area DECIMAL DEFAULT NULL,
    p_usage_amount DECIMAL DEFAULT NULL,
    p_unit_count INTEGER DEFAULT 1
)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_fee_item RECORD;
    v_calculated_amount DECIMAL(15,2) := 0;
    v_tax_amount DECIMAL(15,2) := 0;
    v_discount_amount DECIMAL(15,2) := 0;
BEGIN
    -- 관리비 항목 정보 조회
    SELECT * INTO v_fee_item
    FROM bms.fee_items
    WHERE fee_item_id = p_fee_item_id
      AND is_active = true
      AND effective_start_date <= CURRENT_DATE
      AND (effective_end_date IS NULL OR effective_end_date >= CURRENT_DATE);
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- 계산 방식별 금액 계산
    CASE v_fee_item.calculation_method
        WHEN 'FIXED' THEN
            v_calculated_amount := v_fee_item.base_amount;
            
        WHEN 'AREA_BASED' THEN
            IF p_unit_area IS NOT NULL THEN
                v_calculated_amount := v_fee_item.unit_price * p_unit_area;
            END IF;
            
        WHEN 'USAGE_BASED' THEN
            IF p_usage_amount IS NOT NULL THEN
                v_calculated_amount := v_fee_item.unit_price * p_usage_amount;
            END IF;
            
        WHEN 'UNIT_COUNT' THEN
            v_calculated_amount := v_fee_item.base_amount * p_unit_count;
            
        ELSE
            v_calculated_amount := v_fee_item.base_amount;
    END CASE;
    
    -- 할인 적용
    IF v_fee_item.discount_rate > 0 THEN
        v_discount_amount := v_calculated_amount * (v_fee_item.discount_rate / 100);
        v_calculated_amount := v_calculated_amount - v_discount_amount;
    END IF;
    
    -- 세금 적용
    IF v_fee_item.tax_rate > 0 THEN
        v_tax_amount := v_calculated_amount * (v_fee_item.tax_rate / 100);
        v_calculated_amount := v_calculated_amount + v_tax_amount;
    END IF;
    
    RETURN ROUND(v_calculated_amount, 0);
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 3.2 관리비 항목 마스터 테이블 생성이 완료되었습니다!' as result;