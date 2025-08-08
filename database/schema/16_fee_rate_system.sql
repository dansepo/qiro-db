-- =====================================================
-- 요금 체계 테이블 생성 스크립트
-- Phase 2.1.3: 요금 체계 테이블 생성
-- =====================================================

-- 1. 요금 체계 마스터 테이블
CREATE TABLE IF NOT EXISTS bms.fee_rate_systems (
    rate_system_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    item_id UUID NOT NULL,                              -- 관리비 항목 ID
    
    -- 요금 체계 기본 정보
    system_name VARCHAR(100) NOT NULL,                  -- 요금 체계명
    system_description TEXT,                            -- 요금 체계 설명
    system_type VARCHAR(20) NOT NULL,                   -- 요금 체계 유형
    
    -- 기본 요금 정보
    base_rate DECIMAL(15,4),                            -- 기본 요금
    base_unit DECIMAL(15,4),                            -- 기본 단위
    unit_type VARCHAR(20),                              -- 단위 유형
    
    -- 구간별 요금제 설정
    has_tier_rates BOOLEAN DEFAULT false,               -- 구간별 요금제 사용 여부
    tier_calculation_method VARCHAR(20),                -- 구간별 계산 방식
    
    -- 시간대별 요금제 설정
    has_time_based_rates BOOLEAN DEFAULT false,         -- 시간대별 요금제 사용 여부
    time_zone_config JSONB,                             -- 시간대 설정 (JSON)
    
    -- 계절별 요금제 설정
    has_seasonal_rates BOOLEAN DEFAULT false,           -- 계절별 요금제 사용 여부
    seasonal_config JSONB,                              -- 계절별 설정 (JSON)
    
    -- 할인/할증 설정
    discount_config JSONB,                              -- 할인 설정 (JSON)
    surcharge_config JSONB,                             -- 할증 설정 (JSON)
    
    -- 최소/최대 요금 설정
    minimum_charge DECIMAL(15,4),                       -- 최소 요금
    maximum_charge DECIMAL(15,4),                       -- 최대 요금
    
    -- 반올림 설정
    rounding_method VARCHAR(20) DEFAULT 'ROUND',        -- 반올림 방식
    rounding_unit INTEGER DEFAULT 1,                    -- 반올림 단위
    
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
    CONSTRAINT fk_rate_systems_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_rate_systems_item FOREIGN KEY (item_id) REFERENCES bms.maintenance_fee_items(item_id) ON DELETE CASCADE,
    CONSTRAINT uk_rate_systems_item UNIQUE (item_id, effective_start_date),
    
    -- 체크 제약조건
    CONSTRAINT chk_system_type CHECK (system_type IN (
        'FLAT_RATE',           -- 정액제
        'UNIT_RATE',           -- 단위제
        'TIER_RATE',           -- 구간제
        'PROGRESSIVE',         -- 누진제
        'TIME_BASED',          -- 시간대별
        'SEASONAL',            -- 계절별
        'MIXED'                -- 혼합형
    )),
    CONSTRAINT chk_tier_calculation_method CHECK (tier_calculation_method IN (
        'CUMULATIVE',          -- 누적 계산
        'NON_CUMULATIVE',      -- 비누적 계산
        'BLOCK_RATE'           -- 블록 요금제
    )),
    CONSTRAINT chk_rounding_method CHECK (rounding_method IN (
        'ROUND',               -- 반올림
        'FLOOR',               -- 내림
        'CEIL'                 -- 올림
    )),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 2. 구간별 요금 테이블
CREATE TABLE IF NOT EXISTS bms.fee_tier_rates (
    tier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_system_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 구간 정보
    tier_level INTEGER NOT NULL,                        -- 구간 레벨 (1, 2, 3, ...)
    tier_name VARCHAR(50),                              -- 구간명
    
    -- 구간 범위
    min_usage DECIMAL(15,4),                            -- 최소 사용량
    max_usage DECIMAL(15,4),                            -- 최대 사용량 (NULL이면 무제한)
    
    -- 요금 정보
    unit_rate DECIMAL(15,4) NOT NULL,                   -- 단위 요금
    fixed_charge DECIMAL(15,4),                         -- 고정 요금
    
    -- 계산 방식
    calculation_method VARCHAR(20) DEFAULT 'STANDARD',  -- 계산 방식
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_tier_rates_system FOREIGN KEY (rate_system_id) REFERENCES bms.fee_rate_systems(rate_system_id) ON DELETE CASCADE,
    CONSTRAINT fk_tier_rates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_tier_rates_level UNIQUE (rate_system_id, tier_level),
    
    -- 체크 제약조건
    CONSTRAINT chk_tier_level CHECK (tier_level > 0),
    CONSTRAINT chk_tier_usage_range CHECK (max_usage IS NULL OR max_usage > min_usage),
    CONSTRAINT chk_calculation_method CHECK (calculation_method IN (
        'STANDARD',            -- 표준 계산
        'BLOCK',               -- 블록 계산
        'PROGRESSIVE'          -- 누진 계산
    ))
);

-- 3. 시간대별 요금 테이블
CREATE TABLE IF NOT EXISTS bms.fee_time_rates (
    time_rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_system_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 시간대 정보
    time_slot_name VARCHAR(50) NOT NULL,                -- 시간대명
    start_time TIME NOT NULL,                           -- 시작 시간
    end_time TIME NOT NULL,                             -- 종료 시간
    
    -- 요일 설정
    applicable_days INTEGER[] NOT NULL,                 -- 적용 요일 (1=월, 2=화, ..., 7=일)
    
    -- 요금 정보
    rate_multiplier DECIMAL(8,4) DEFAULT 1.0,           -- 요금 배수
    fixed_adjustment DECIMAL(15,4) DEFAULT 0,           -- 고정 조정 금액
    
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
    CONSTRAINT fk_time_rates_system FOREIGN KEY (rate_system_id) REFERENCES bms.fee_rate_systems(rate_system_id) ON DELETE CASCADE,
    CONSTRAINT fk_time_rates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_applicable_days CHECK (
        applicable_days <@ ARRAY[1,2,3,4,5,6,7] AND 
        array_length(applicable_days, 1) > 0
    ),
    CONSTRAINT chk_rate_multiplier CHECK (rate_multiplier > 0),
    CONSTRAINT chk_priority_order CHECK (priority_order > 0)
);

-- 4. 계절별 요금 테이블
CREATE TABLE IF NOT EXISTS bms.fee_seasonal_rates (
    seasonal_rate_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_system_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 계절 정보
    season_name VARCHAR(50) NOT NULL,                   -- 계절명
    start_month INTEGER NOT NULL,                       -- 시작 월
    start_day INTEGER NOT NULL,                         -- 시작 일
    end_month INTEGER NOT NULL,                         -- 종료 월
    end_day INTEGER NOT NULL,                           -- 종료 일
    
    -- 요금 정보
    rate_multiplier DECIMAL(8,4) DEFAULT 1.0,           -- 요금 배수
    fixed_adjustment DECIMAL(15,4) DEFAULT 0,           -- 고정 조정 금액
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_seasonal_rates_system FOREIGN KEY (rate_system_id) REFERENCES bms.fee_rate_systems(rate_system_id) ON DELETE CASCADE,
    CONSTRAINT fk_seasonal_rates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_start_month CHECK (start_month BETWEEN 1 AND 12),
    CONSTRAINT chk_end_month CHECK (end_month BETWEEN 1 AND 12),
    CONSTRAINT chk_start_day CHECK (start_day BETWEEN 1 AND 31),
    CONSTRAINT chk_end_day CHECK (end_day BETWEEN 1 AND 31),
    CONSTRAINT chk_seasonal_rate_multiplier CHECK (rate_multiplier > 0)
);

-- 5. 요금 체계 변경 이력 테이블
CREATE TABLE IF NOT EXISTS bms.fee_rate_change_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rate_system_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 변경 정보
    change_type VARCHAR(20) NOT NULL,                   -- 변경 유형
    changed_component VARCHAR(20) NOT NULL,             -- 변경된 구성요소
    old_values JSONB,                                   -- 이전 값들
    new_values JSONB,                                   -- 새 값들
    
    -- 변경 사유
    change_reason TEXT NOT NULL,                        -- 변경 사유
    change_description TEXT,                            -- 변경 설명
    
    -- 승인 정보
    requested_by UUID,                                  -- 요청자
    approved_by UUID,                                   -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,              -- 승인 일시
    
    -- 적용 정보
    effective_date DATE,                                -- 적용일
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_rate_history_system FOREIGN KEY (rate_system_id) REFERENCES bms.fee_rate_systems(rate_system_id) ON DELETE CASCADE,
    CONSTRAINT fk_rate_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_rate_history_requester FOREIGN KEY (requested_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_rate_history_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_rate_change_type CHECK (change_type IN (
        'CREATE',              -- 생성
        'UPDATE',              -- 수정
        'DELETE',              -- 삭제
        'ACTIVATE',            -- 활성화
        'DEACTIVATE'           -- 비활성화
    )),
    CONSTRAINT chk_changed_component CHECK (changed_component IN (
        'BASE_RATE',           -- 기본 요금
        'TIER_RATE',           -- 구간 요금
        'TIME_RATE',           -- 시간대 요금
        'SEASONAL_RATE',       -- 계절 요금
        'DISCOUNT',            -- 할인
        'SURCHARGE',           -- 할증
        'SYSTEM_CONFIG'        -- 시스템 설정
    ))
);

-- 6. RLS 정책 활성화
ALTER TABLE bms.fee_rate_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_tier_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_time_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_seasonal_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_rate_change_history ENABLE ROW LEVEL SECURITY;

-- 7. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY fee_rate_systems_isolation_policy ON bms.fee_rate_systems
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_tier_rates_isolation_policy ON bms.fee_tier_rates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_time_rates_isolation_policy ON bms.fee_time_rates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_seasonal_rates_isolation_policy ON bms.fee_seasonal_rates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_rate_change_history_isolation_policy ON bms.fee_rate_change_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 8. 성능 최적화 인덱스 생성
-- 요금 체계 마스터 인덱스
CREATE INDEX idx_rate_systems_company_id ON bms.fee_rate_systems(company_id);
CREATE INDEX idx_rate_systems_item_id ON bms.fee_rate_systems(item_id);
CREATE INDEX idx_rate_systems_system_type ON bms.fee_rate_systems(system_type);
CREATE INDEX idx_rate_systems_is_active ON bms.fee_rate_systems(is_active);
CREATE INDEX idx_rate_systems_effective_dates ON bms.fee_rate_systems(effective_start_date, effective_end_date);

-- 구간별 요금 인덱스
CREATE INDEX idx_tier_rates_system_id ON bms.fee_tier_rates(rate_system_id);
CREATE INDEX idx_tier_rates_company_id ON bms.fee_tier_rates(company_id);
CREATE INDEX idx_tier_rates_tier_level ON bms.fee_tier_rates(tier_level);
CREATE INDEX idx_tier_rates_usage_range ON bms.fee_tier_rates(min_usage, max_usage);

-- 시간대별 요금 인덱스
CREATE INDEX idx_time_rates_system_id ON bms.fee_time_rates(rate_system_id);
CREATE INDEX idx_time_rates_company_id ON bms.fee_time_rates(company_id);
CREATE INDEX idx_time_rates_time_slot ON bms.fee_time_rates(start_time, end_time);

-- 계절별 요금 인덱스
CREATE INDEX idx_seasonal_rates_system_id ON bms.fee_seasonal_rates(rate_system_id);
CREATE INDEX idx_seasonal_rates_company_id ON bms.fee_seasonal_rates(company_id);
CREATE INDEX idx_seasonal_rates_season ON bms.fee_seasonal_rates(start_month, start_day, end_month, end_day);

-- 변경 이력 인덱스
CREATE INDEX idx_rate_history_system_id ON bms.fee_rate_change_history(rate_system_id);
CREATE INDEX idx_rate_history_company_id ON bms.fee_rate_change_history(company_id);
CREATE INDEX idx_rate_history_created_at ON bms.fee_rate_change_history(created_at DESC);

-- 복합 인덱스
CREATE INDEX idx_rate_systems_company_active ON bms.fee_rate_systems(company_id, is_active);
CREATE INDEX idx_tier_rates_system_level ON bms.fee_tier_rates(rate_system_id, tier_level);

-- 9. updated_at 자동 업데이트 트리거
CREATE TRIGGER fee_rate_systems_updated_at_trigger
    BEFORE UPDATE ON bms.fee_rate_systems
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fee_tier_rates_updated_at_trigger
    BEFORE UPDATE ON bms.fee_tier_rates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fee_time_rates_updated_at_trigger
    BEFORE UPDATE ON bms.fee_time_rates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fee_seasonal_rates_updated_at_trigger
    BEFORE UPDATE ON bms.fee_seasonal_rates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 10. 요금 계산 함수들
-- 구간별 요금 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_tier_rate(
    p_rate_system_id UUID,
    p_usage_amount DECIMAL(15,4)
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    v_total_charge DECIMAL(15,4) := 0;
    v_remaining_usage DECIMAL(15,4) := p_usage_amount;
    v_tier_rec RECORD;
    v_tier_usage DECIMAL(15,4);
    v_tier_charge DECIMAL(15,4);
BEGIN
    -- 구간별 요금 조회 (레벨 순으로)
    FOR v_tier_rec IN 
        SELECT tier_level, min_usage, max_usage, unit_rate, fixed_charge, calculation_method
        FROM bms.fee_tier_rates
        WHERE rate_system_id = p_rate_system_id
          AND is_active = true
        ORDER BY tier_level
    LOOP
        -- 해당 구간에서 사용할 사용량 계산
        IF v_remaining_usage <= 0 THEN
            EXIT;
        END IF;
        
        IF v_tier_rec.max_usage IS NULL THEN
            -- 최상위 구간 (무제한)
            v_tier_usage := v_remaining_usage;
        ELSE
            -- 일반 구간
            v_tier_usage := LEAST(v_remaining_usage, v_tier_rec.max_usage - v_tier_rec.min_usage);
        END IF;
        
        -- 구간별 요금 계산
        CASE v_tier_rec.calculation_method
            WHEN 'BLOCK' THEN
                -- 블록 요금제: 해당 구간에 속하면 전체 사용량에 해당 구간 요금 적용
                IF p_usage_amount >= v_tier_rec.min_usage AND 
                   (v_tier_rec.max_usage IS NULL OR p_usage_amount <= v_tier_rec.max_usage) THEN
                    v_total_charge := p_usage_amount * v_tier_rec.unit_rate + COALESCE(v_tier_rec.fixed_charge, 0);
                    EXIT;
                END IF;
            ELSE
                -- 표준/누진: 구간별 사용량에 해당 구간 요금 적용
                v_tier_charge := v_tier_usage * v_tier_rec.unit_rate + COALESCE(v_tier_rec.fixed_charge, 0);
                v_total_charge := v_total_charge + v_tier_charge;
        END CASE;
        
        v_remaining_usage := v_remaining_usage - v_tier_usage;
    END LOOP;
    
    RETURN v_total_charge;
END;
$$ LANGUAGE plpgsql;

-- 시간대별 요금 배수 조회 함수
CREATE OR REPLACE FUNCTION bms.get_time_rate_multiplier(
    p_rate_system_id UUID,
    p_timestamp TIMESTAMP WITH TIME ZONE
)
RETURNS DECIMAL(8,4) AS $$
DECLARE
    v_multiplier DECIMAL(8,4) := 1.0;
    v_time TIME := p_timestamp::TIME;
    v_day_of_week INTEGER := EXTRACT(DOW FROM p_timestamp) + 1; -- PostgreSQL DOW: 0=일요일, 1=월요일
BEGIN
    -- 해당 시간대의 요금 배수 조회
    SELECT rate_multiplier INTO v_multiplier
    FROM bms.fee_time_rates
    WHERE rate_system_id = p_rate_system_id
      AND is_active = true
      AND v_time BETWEEN start_time AND end_time
      AND v_day_of_week = ANY(applicable_days)
    ORDER BY priority_order
    LIMIT 1;
    
    RETURN COALESCE(v_multiplier, 1.0);
END;
$$ LANGUAGE plpgsql;

-- 계절별 요금 배수 조회 함수
CREATE OR REPLACE FUNCTION bms.get_seasonal_rate_multiplier(
    p_rate_system_id UUID,
    p_date DATE
)
RETURNS DECIMAL(8,4) AS $$
DECLARE
    v_multiplier DECIMAL(8,4) := 1.0;
    v_month INTEGER := EXTRACT(MONTH FROM p_date);
    v_day INTEGER := EXTRACT(DAY FROM p_date);
BEGIN
    -- 해당 날짜의 계절별 요금 배수 조회
    SELECT rate_multiplier INTO v_multiplier
    FROM bms.fee_seasonal_rates
    WHERE rate_system_id = p_rate_system_id
      AND is_active = true
      AND (
          -- 같은 연도 내 계절
          (start_month <= end_month AND v_month BETWEEN start_month AND end_month AND
           CASE 
               WHEN v_month = start_month THEN v_day >= start_day
               WHEN v_month = end_month THEN v_day <= end_day
               ELSE true
           END)
          OR
          -- 연도를 넘나드는 계절 (예: 겨울)
          (start_month > end_month AND (
              (v_month >= start_month AND (v_month > start_month OR v_day >= start_day))
              OR
              (v_month <= end_month AND (v_month < end_month OR v_day <= end_day))
          ))
      )
    LIMIT 1;
    
    RETURN COALESCE(v_multiplier, 1.0);
END;
$$ LANGUAGE plpgsql;

-- 11. 요금 체계 뷰 생성
CREATE OR REPLACE VIEW bms.v_active_rate_systems AS
SELECT 
    frs.rate_system_id,
    frs.company_id,
    c.company_name,
    frs.item_id,
    mfi.item_name,
    frs.system_name,
    frs.system_type,
    frs.base_rate,
    frs.unit_type,
    frs.has_tier_rates,
    frs.has_time_based_rates,
    frs.has_seasonal_rates,
    frs.minimum_charge,
    frs.maximum_charge,
    frs.effective_start_date,
    frs.effective_end_date
FROM bms.fee_rate_systems frs
JOIN bms.companies c ON frs.company_id = c.company_id
JOIN bms.maintenance_fee_items mfi ON frs.item_id = mfi.item_id
WHERE frs.is_active = true
  AND frs.effective_start_date <= CURRENT_DATE
  AND (frs.effective_end_date IS NULL OR frs.effective_end_date >= CURRENT_DATE)
ORDER BY c.company_name, mfi.item_name, frs.system_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_active_rate_systems OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 1.3 요금 체계 테이블 생성이 완료되었습니다!' as result;