-- =====================================================
-- 관리비 항목 마스터 테이블 확장 스크립트
-- Phase 2.1.1: 관리비 항목 마스터 테이블 확장
-- =====================================================

-- 1. 기존 관리비 항목 테이블 확장 (이미 존재하는 경우 컬럼 추가)
-- 기존 테이블 구조 확인 후 필요한 컬럼 추가

-- 관리비 항목 분류 테이블 생성
CREATE TABLE IF NOT EXISTS bms.fee_item_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 분류 정보
    category_code VARCHAR(20) NOT NULL,                 -- 분류 코드
    category_name VARCHAR(100) NOT NULL,                -- 분류명
    category_description TEXT,                          -- 분류 설명
    
    -- 표시 정보
    display_order INTEGER DEFAULT 0,                    -- 표시 순서
    icon_name VARCHAR(50),                              -- 아이콘명
    color_code VARCHAR(7),                              -- 색상 코드 (#RRGGBB)
    
    -- 계산 기본 설정
    default_calculation_method VARCHAR(20),             -- 기본 계산 방식
    is_utility_category BOOLEAN DEFAULT false,          -- 공과금 분류 여부
    is_common_area_category BOOLEAN DEFAULT false,      -- 공용 구역 분류 여부
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_fee_categories_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_fee_categories_code UNIQUE (company_id, category_code),
    
    -- 체크 제약조건
    CONSTRAINT chk_default_calculation_method CHECK (default_calculation_method IN (
        'FIXED_AMOUNT',         -- 정액
        'AREA_BASED',          -- 면적 비례
        'USAGE_BASED',         -- 사용량 비례
        'HOUSEHOLD_BASED',     -- 세대수 비례
        'MIXED',               -- 혼합 방식
        'CUSTOM'               -- 사용자 정의
    ))
);

-- 2. 확장된 관리비 항목 마스터 테이블
CREATE TABLE IF NOT EXISTS bms.maintenance_fee_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    category_id UUID,                                   -- 분류 ID
    
    -- 기본 정보
    item_code VARCHAR(20) NOT NULL,                     -- 항목 코드
    item_name VARCHAR(100) NOT NULL,                    -- 항목명
    item_description TEXT,                              -- 항목 설명
    
    -- 계산 방식
    calculation_method VARCHAR(20) NOT NULL,            -- 계산 방식
    calculation_formula TEXT,                           -- 계산 공식
    
    -- 단가 정보
    unit_price DECIMAL(15,4),                           -- 단가
    unit_type VARCHAR(20),                              -- 단위 유형
    
    -- 요율 정보 (비례 계산용)
    rate_percentage DECIMAL(8,4),                       -- 요율 (%)
    base_amount DECIMAL(15,4),                          -- 기준 금액
    
    -- 구간별 요금제 설정
    has_tier_pricing BOOLEAN DEFAULT false,             -- 구간별 요금제 사용 여부
    tier_config JSONB,                                  -- 구간별 설정 (JSON)
    
    -- 적용 범위
    applies_to_all_units BOOLEAN DEFAULT true,          -- 전체 호실 적용 여부
    applicable_unit_types TEXT[],                       -- 적용 호실 유형
    excluded_unit_types TEXT[],                         -- 제외 호실 유형
    
    -- 시기별 설정
    is_seasonal BOOLEAN DEFAULT false,                  -- 계절별 적용 여부
    seasonal_config JSONB,                              -- 계절별 설정
    
    -- 공용 구역 배분 설정
    common_area_allocation_method VARCHAR(20),          -- 공용 구역 배분 방식
    common_area_ratio DECIMAL(8,4),                     -- 공용 구역 비율
    
    -- 외부 연동 설정
    external_source VARCHAR(50),                        -- 외부 데이터 소스
    external_item_code VARCHAR(50),                     -- 외부 항목 코드
    auto_import_enabled BOOLEAN DEFAULT false,          -- 자동 가져오기 활성화
    
    -- 표시 설정
    display_order INTEGER DEFAULT 0,                    -- 표시 순서
    is_visible_to_tenant BOOLEAN DEFAULT true,          -- 입주자에게 표시 여부
    is_detailed_breakdown BOOLEAN DEFAULT false,        -- 세부 내역 표시 여부
    
    -- 승인 설정
    requires_approval BOOLEAN DEFAULT false,            -- 승인 필요 여부
    approval_threshold DECIMAL(15,4),                   -- 승인 임계값
    
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
    CONSTRAINT fk_fee_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fee_items_category FOREIGN KEY (category_id) REFERENCES bms.fee_item_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_fee_items_code UNIQUE (company_id, item_code),
    
    -- 체크 제약조건
    CONSTRAINT chk_calculation_method CHECK (calculation_method IN (
        'FIXED_AMOUNT',         -- 정액
        'AREA_BASED',          -- 면적 비례
        'USAGE_BASED',         -- 사용량 비례
        'HOUSEHOLD_BASED',     -- 세대수 비례
        'PROGRESSIVE',         -- 누진제
        'MIXED',               -- 혼합 방식
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_unit_type CHECK (unit_type IN (
        'KRW',                 -- 원
        'KWH',                 -- 킬로와트시
        'M3',                  -- 세제곱미터
        'M2',                  -- 제곱미터
        'HOUSEHOLD',           -- 세대
        'PERSON',              -- 인원
        'UNIT',                -- 단위
        'PERCENTAGE'           -- 퍼센트
    )),
    CONSTRAINT chk_common_area_allocation CHECK (common_area_allocation_method IN (
        'AREA_RATIO',          -- 면적 비율
        'HOUSEHOLD_RATIO',     -- 세대수 비율
        'USAGE_RATIO',         -- 사용량 비율
        'EQUAL_SPLIT',         -- 균등 분할
        'CUSTOM_RATIO'         -- 사용자 정의 비율
    )),
    CONSTRAINT chk_rate_percentage CHECK (rate_percentage IS NULL OR (rate_percentage >= 0 AND rate_percentage <= 100)),
    CONSTRAINT chk_common_area_ratio CHECK (common_area_ratio IS NULL OR (common_area_ratio >= 0 AND common_area_ratio <= 100)),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 3. 관리비 항목별 단가 이력 테이블
CREATE TABLE IF NOT EXISTS bms.fee_item_price_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 단가 정보
    unit_price DECIMAL(15,4) NOT NULL,                  -- 단가
    rate_percentage DECIMAL(8,4),                       -- 요율
    
    -- 변경 정보
    change_reason TEXT,                                 -- 변경 사유
    change_type VARCHAR(20) NOT NULL,                   -- 변경 유형
    
    -- 유효 기간
    effective_start_date DATE NOT NULL,
    effective_end_date DATE,
    
    -- 승인 정보
    approved_by UUID,                                   -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,              -- 승인 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_price_history_item FOREIGN KEY (item_id) REFERENCES bms.maintenance_fee_items(item_id) ON DELETE CASCADE,
    CONSTRAINT fk_price_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_price_history_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_change_type CHECK (change_type IN ('INITIAL', 'INCREASE', 'DECREASE', 'ADJUSTMENT', 'CORRECTION')),
    CONSTRAINT chk_price_history_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 4. 건물별 관리비 항목 설정 테이블
CREATE TABLE IF NOT EXISTS bms.building_fee_item_settings (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    building_id UUID NOT NULL,
    item_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 건물별 개별 설정
    custom_unit_price DECIMAL(15,4),                    -- 건물별 개별 단가
    custom_rate_percentage DECIMAL(8,4),                -- 건물별 개별 요율
    custom_calculation_method VARCHAR(20),              -- 건물별 계산 방식
    
    -- 적용 설정
    is_enabled BOOLEAN DEFAULT true,                    -- 해당 건물에서 사용 여부
    override_default BOOLEAN DEFAULT false,             -- 기본 설정 무시 여부
    
    -- 특별 설정
    special_conditions JSONB,                           -- 특별 조건 (JSON)
    notes TEXT,                                         -- 비고
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_building_fee_settings_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_building_fee_settings_item FOREIGN KEY (item_id) REFERENCES bms.maintenance_fee_items(item_id) ON DELETE CASCADE,
    CONSTRAINT fk_building_fee_settings_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_building_fee_settings UNIQUE (building_id, item_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_custom_calculation_method CHECK (custom_calculation_method IS NULL OR custom_calculation_method IN (
        'FIXED_AMOUNT', 'AREA_BASED', 'USAGE_BASED', 'HOUSEHOLD_BASED', 'PROGRESSIVE', 'MIXED', 'CUSTOM'
    )),
    CONSTRAINT chk_building_fee_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.fee_item_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.maintenance_fee_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_item_price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.building_fee_item_settings ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY fee_item_categories_isolation_policy ON bms.fee_item_categories
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY maintenance_fee_items_isolation_policy ON bms.maintenance_fee_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_item_price_history_isolation_policy ON bms.fee_item_price_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY building_fee_item_settings_isolation_policy ON bms.building_fee_item_settings
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 관리비 항목 분류 인덱스
CREATE INDEX idx_fee_categories_company_id ON bms.fee_item_categories(company_id);
CREATE INDEX idx_fee_categories_code ON bms.fee_item_categories(category_code);
CREATE INDEX idx_fee_categories_active ON bms.fee_item_categories(is_active);

-- 관리비 항목 인덱스
CREATE INDEX idx_fee_items_company_id ON bms.maintenance_fee_items(company_id);
CREATE INDEX idx_fee_items_category_id ON bms.maintenance_fee_items(category_id);
CREATE INDEX idx_fee_items_code ON bms.maintenance_fee_items(item_code);
CREATE INDEX idx_fee_items_calculation_method ON bms.maintenance_fee_items(calculation_method);
CREATE INDEX idx_fee_items_active ON bms.maintenance_fee_items(is_active);
CREATE INDEX idx_fee_items_effective_dates ON bms.maintenance_fee_items(effective_start_date, effective_end_date);

-- 단가 이력 인덱스
CREATE INDEX idx_price_history_item_id ON bms.fee_item_price_history(item_id);
CREATE INDEX idx_price_history_company_id ON bms.fee_item_price_history(company_id);
CREATE INDEX idx_price_history_effective_dates ON bms.fee_item_price_history(effective_start_date, effective_end_date);
CREATE INDEX idx_price_history_created_at ON bms.fee_item_price_history(created_at DESC);

-- 건물별 설정 인덱스
CREATE INDEX idx_building_fee_settings_building_id ON bms.building_fee_item_settings(building_id);
CREATE INDEX idx_building_fee_settings_item_id ON bms.building_fee_item_settings(item_id);
CREATE INDEX idx_building_fee_settings_company_id ON bms.building_fee_item_settings(company_id);
CREATE INDEX idx_building_fee_settings_enabled ON bms.building_fee_item_settings(is_enabled);

-- 복합 인덱스
CREATE INDEX idx_fee_items_company_category ON bms.maintenance_fee_items(company_id, category_id);
CREATE INDEX idx_fee_items_company_active ON bms.maintenance_fee_items(company_id, is_active);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER fee_item_categories_updated_at_trigger
    BEFORE UPDATE ON bms.fee_item_categories
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER maintenance_fee_items_updated_at_trigger
    BEFORE UPDATE ON bms.maintenance_fee_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER building_fee_item_settings_updated_at_trigger
    BEFORE UPDATE ON bms.building_fee_item_settings
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 관리비 항목 조회 뷰 생성
CREATE OR REPLACE VIEW bms.v_active_fee_items AS
SELECT 
    mfi.item_id,
    mfi.company_id,
    c.company_name,
    mfi.category_id,
    fic.category_name,
    fic.category_code,
    mfi.item_code,
    mfi.item_name,
    mfi.item_description,
    mfi.calculation_method,
    mfi.unit_price,
    mfi.unit_type,
    mfi.rate_percentage,
    mfi.has_tier_pricing,
    mfi.applies_to_all_units,
    mfi.is_seasonal,
    mfi.common_area_allocation_method,
    mfi.common_area_ratio,
    mfi.display_order,
    mfi.is_visible_to_tenant,
    mfi.effective_start_date,
    mfi.effective_end_date
FROM bms.maintenance_fee_items mfi
JOIN bms.companies c ON mfi.company_id = c.company_id
LEFT JOIN bms.fee_item_categories fic ON mfi.category_id = fic.category_id
WHERE mfi.is_active = true
  AND mfi.effective_start_date <= CURRENT_DATE
  AND (mfi.effective_end_date IS NULL OR mfi.effective_end_date >= CURRENT_DATE)
ORDER BY fic.display_order, mfi.display_order, mfi.item_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_active_fee_items OWNER TO qiro;

-- 10. 관리비 항목 관리 함수들
-- 현재 유효한 단가 조회 함수
CREATE OR REPLACE FUNCTION bms.get_current_fee_item_price(
    p_item_id UUID,
    p_reference_date DATE DEFAULT CURRENT_DATE
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    v_unit_price DECIMAL(15,4);
BEGIN
    -- 단가 이력에서 현재 유효한 단가 조회
    SELECT unit_price INTO v_unit_price
    FROM bms.fee_item_price_history
    WHERE item_id = p_item_id
      AND effective_start_date <= p_reference_date
      AND (effective_end_date IS NULL OR effective_end_date >= p_reference_date)
    ORDER BY effective_start_date DESC
    LIMIT 1;
    
    -- 이력이 없으면 마스터 테이블에서 조회
    IF v_unit_price IS NULL THEN
        SELECT unit_price INTO v_unit_price
        FROM bms.maintenance_fee_items
        WHERE item_id = p_item_id
          AND is_active = true;
    END IF;
    
    RETURN COALESCE(v_unit_price, 0);
END;
$$ LANGUAGE plpgsql;

-- 건물별 관리비 항목 조회 함수
CREATE OR REPLACE FUNCTION bms.get_building_fee_items(
    p_building_id UUID,
    p_reference_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    item_id UUID,
    item_code VARCHAR(20),
    item_name VARCHAR(100),
    calculation_method VARCHAR(20),
    unit_price DECIMAL(15,4),
    unit_type VARCHAR(20),
    rate_percentage DECIMAL(8,4)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        mfi.item_id,
        mfi.item_code,
        mfi.item_name,
        COALESCE(bfis.custom_calculation_method, mfi.calculation_method) as calculation_method,
        COALESCE(bfis.custom_unit_price, bms.get_current_fee_item_price(mfi.item_id, p_reference_date)) as unit_price,
        mfi.unit_type,
        COALESCE(bfis.custom_rate_percentage, mfi.rate_percentage) as rate_percentage
    FROM bms.maintenance_fee_items mfi
    LEFT JOIN bms.building_fee_item_settings bfis ON mfi.item_id = bfis.item_id AND bfis.building_id = p_building_id
    WHERE mfi.is_active = true
      AND mfi.effective_start_date <= p_reference_date
      AND (mfi.effective_end_date IS NULL OR mfi.effective_end_date >= p_reference_date)
      AND (bfis.is_enabled IS NULL OR bfis.is_enabled = true)
      AND (bfis.effective_start_date IS NULL OR bfis.effective_start_date <= p_reference_date)
      AND (bfis.effective_end_date IS NULL OR bfis.effective_end_date >= p_reference_date)
    ORDER BY mfi.display_order, mfi.item_name;
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 1.1 관리비 항목 마스터 테이블 확장이 완료되었습니다!' as result;