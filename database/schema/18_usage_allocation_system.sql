-- =====================================================
-- 사용량 배분 시스템 테이블 생성 스크립트
-- Phase 2.2.2: 사용량 배분 테이블 생성
-- =====================================================

-- 1. 배분 규칙 마스터 테이블
CREATE TABLE IF NOT EXISTS bms.usage_allocation_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                   -- NULL이면 회사 전체 규칙
    
    -- 규칙 기본 정보
    rule_name VARCHAR(100) NOT NULL,                    -- 규칙명
    rule_description TEXT,                              -- 규칙 설명
    rule_type VARCHAR(20) NOT NULL,                     -- 규칙 유형
    
    -- 적용 대상
    meter_type VARCHAR(20) NOT NULL,                    -- 대상 계량기 유형
    source_meter_ids UUID[],                            -- 원본 계량기 ID 목록
    target_unit_types TEXT[],                           -- 대상 호실 유형
    
    -- 배분 방식
    allocation_method VARCHAR(20) NOT NULL,             -- 배분 방식
    allocation_basis VARCHAR(20) NOT NULL,              -- 배분 기준
    
    -- 배분 비율 설정
    fixed_ratios JSONB,                                 -- 고정 비율 (JSON)
    dynamic_calculation BOOLEAN DEFAULT false,          -- 동적 계산 여부
    calculation_formula TEXT,                           -- 계산 공식
    
    -- 최소/최대 배분량 설정
    min_allocation_amount DECIMAL(15,4),                -- 최소 배분량
    max_allocation_amount DECIMAL(15,4),                -- 최대 배분량
    min_allocation_ratio DECIMAL(8,4),                  -- 최소 배분 비율 (%)
    max_allocation_ratio DECIMAL(8,4),                  -- 최대 배분 비율 (%)
    
    -- 조정 설정
    adjustment_enabled BOOLEAN DEFAULT true,            -- 조정 허용 여부
    auto_adjustment BOOLEAN DEFAULT false,              -- 자동 조정 여부
    adjustment_threshold DECIMAL(8,4),                  -- 조정 임계값 (%)
    
    -- 검증 설정
    validation_enabled BOOLEAN DEFAULT true,            -- 검증 활성화
    tolerance_percentage DECIMAL(8,4) DEFAULT 5.0,      -- 허용 오차 (%)
    
    -- 우선순위
    priority_order INTEGER DEFAULT 1,                   -- 우선순위
    
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
    CONSTRAINT fk_allocation_rules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_allocation_rules_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_rule_type CHECK (rule_type IN (
        'COMMON_AREA',         -- 공용구역 배분
        'SHARED_UTILITY',      -- 공용 유틸리티 배분
        'PROPORTIONAL',        -- 비례 배분
        'EQUAL_SPLIT',         -- 균등 배분
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_meter_type_allocation CHECK (meter_type IN (
        'ELECTRIC', 'WATER', 'GAS', 'HEATING', 'HOT_WATER', 'STEAM', 'COMPRESSED_AIR', 'OTHER'
    )),
    CONSTRAINT chk_allocation_method CHECK (allocation_method IN (
        'PROPORTIONAL',        -- 비례 배분
        'EQUAL',               -- 균등 배분
        'WEIGHTED',            -- 가중 배분
        'TIERED',              -- 단계별 배분
        'FORMULA_BASED',       -- 공식 기반
        'MANUAL'               -- 수동 배분
    )),
    CONSTRAINT chk_allocation_basis CHECK (allocation_basis IN (
        'AREA',                -- 면적 기준
        'HOUSEHOLD',           -- 세대수 기준
        'OCCUPANCY',           -- 거주자수 기준
        'USAGE_HISTORY',       -- 사용 이력 기준
        'FIXED_RATIO',         -- 고정 비율
        'CUSTOM_WEIGHT'        -- 사용자 정의 가중치
    )),
    CONSTRAINT chk_min_max_allocation CHECK (
        (min_allocation_amount IS NULL OR max_allocation_amount IS NULL OR max_allocation_amount >= min_allocation_amount) AND
        (min_allocation_ratio IS NULL OR max_allocation_ratio IS NULL OR max_allocation_ratio >= min_allocation_ratio)
    ),
    CONSTRAINT chk_allocation_ratios CHECK (
        (min_allocation_ratio IS NULL OR (min_allocation_ratio >= 0 AND min_allocation_ratio <= 100)) AND
        (max_allocation_ratio IS NULL OR (max_allocation_ratio >= 0 AND max_allocation_ratio <= 100))
    ),
    CONSTRAINT chk_tolerance_percentage CHECK (tolerance_percentage >= 0 AND tolerance_percentage <= 100),
    CONSTRAINT chk_priority_order CHECK (priority_order > 0),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 2. 사용량 배분 결과 테이블
CREATE TABLE IF NOT EXISTS bms.usage_allocations (
    allocation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    rule_id UUID NOT NULL,
    
    -- 배분 기준 정보
    allocation_period_start DATE NOT NULL,              -- 배분 기간 시작
    allocation_period_end DATE NOT NULL,                -- 배분 기간 종료
    source_meter_id UUID NOT NULL,                      -- 원본 계량기 ID
    target_unit_id UUID NOT NULL,                       -- 대상 호실 ID
    
    -- 원본 사용량 정보
    total_source_usage DECIMAL(15,4) NOT NULL,          -- 총 원본 사용량
    source_reading_start DECIMAL(15,4),                 -- 시작 검침값
    source_reading_end DECIMAL(15,4),                   -- 종료 검침값
    
    -- 배분 계산 정보
    allocation_basis_value DECIMAL(15,4),               -- 배분 기준값 (면적, 세대수 등)
    allocation_ratio DECIMAL(8,4) NOT NULL,             -- 배분 비율 (%)
    calculated_amount DECIMAL(15,4) NOT NULL,           -- 계산된 배분량
    
    -- 조정 정보
    adjustment_amount DECIMAL(15,4) DEFAULT 0,          -- 조정량
    adjustment_reason TEXT,                             -- 조정 사유
    final_allocated_amount DECIMAL(15,4) NOT NULL,      -- 최종 배분량
    
    -- 검증 정보
    is_validated BOOLEAN DEFAULT false,                 -- 검증 완료 여부
    validation_status VARCHAR(20),                      -- 검증 상태
    validation_notes TEXT,                              -- 검증 메모
    validated_by UUID,                                  -- 검증자 ID
    validated_at TIMESTAMP WITH TIME ZONE,             -- 검증 일시
    
    -- 승인 정보
    approval_status VARCHAR(20) DEFAULT 'PENDING',      -- 승인 상태
    approved_by UUID,                                   -- 승인자 ID
    approved_at TIMESTAMP WITH TIME ZONE,              -- 승인 일시
    approval_notes TEXT,                                -- 승인 메모
    
    -- 배분 상태
    allocation_status VARCHAR(20) DEFAULT 'CALCULATED', -- 배분 상태
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_allocations_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_allocations_rule FOREIGN KEY (rule_id) REFERENCES bms.usage_allocation_rules(rule_id) ON DELETE CASCADE,
    CONSTRAINT fk_allocations_source_meter FOREIGN KEY (source_meter_id) REFERENCES bms.meters(meter_id) ON DELETE CASCADE,
    CONSTRAINT fk_allocations_target_unit FOREIGN KEY (target_unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_allocations_validator FOREIGN KEY (validated_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_allocations_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_allocations_period_unit UNIQUE (rule_id, allocation_period_start, allocation_period_end, target_unit_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_allocation_period CHECK (allocation_period_end >= allocation_period_start),
    CONSTRAINT chk_allocation_ratio CHECK (allocation_ratio >= 0 AND allocation_ratio <= 100),
    CONSTRAINT chk_calculated_amount CHECK (calculated_amount >= 0),
    CONSTRAINT chk_final_allocated_amount CHECK (final_allocated_amount >= 0),
    CONSTRAINT chk_validation_status CHECK (validation_status IN (
        'PENDING',             -- 검증 대기
        'PASSED',              -- 검증 통과
        'FAILED',              -- 검증 실패
        'MANUAL_REVIEW'        -- 수동 검토 필요
    )),
    CONSTRAINT chk_approval_status CHECK (approval_status IN (
        'PENDING',             -- 승인 대기
        'APPROVED',            -- 승인됨
        'REJECTED',            -- 거부됨
        'AUTO_APPROVED'        -- 자동 승인
    )),
    CONSTRAINT chk_allocation_status CHECK (allocation_status IN (
        'CALCULATED',          -- 계산됨
        'ADJUSTED',            -- 조정됨
        'VALIDATED',           -- 검증됨
        'APPROVED',            -- 승인됨
        'APPLIED',             -- 적용됨
        'CANCELLED'            -- 취소됨
    ))
);

-- 3. 배분 기준 데이터 테이블
CREATE TABLE IF NOT EXISTS bms.allocation_basis_data (
    basis_data_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    
    -- 기준 데이터 정보
    data_type VARCHAR(20) NOT NULL,                     -- 데이터 유형
    data_category VARCHAR(20),                          -- 데이터 분류
    
    -- 데이터 값
    numeric_value DECIMAL(15,4),                        -- 숫자 값
    text_value VARCHAR(200),                            -- 텍스트 값
    json_value JSONB,                                   -- JSON 값
    
    -- 가중치
    weight_factor DECIMAL(8,4) DEFAULT 1.0,             -- 가중치 계수
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 데이터 소스
    data_source VARCHAR(50),                            -- 데이터 출처
    last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_basis_data_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_basis_data_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT uk_basis_data_unit_type UNIQUE (unit_id, data_type, effective_start_date),
    
    -- 체크 제약조건
    CONSTRAINT chk_data_type CHECK (data_type IN (
        'AREA',                -- 면적
        'OCCUPANCY_COUNT',     -- 거주자수
        'HOUSEHOLD_COUNT',     -- 세대수
        'USAGE_WEIGHT',        -- 사용량 가중치
        'CUSTOM_FACTOR',       -- 사용자 정의 계수
        'HISTORICAL_USAGE',    -- 과거 사용량
        'EQUIPMENT_COUNT',     -- 장비 수량
        'BUSINESS_TYPE'        -- 업종 구분
    )),
    CONSTRAINT chk_data_category CHECK (data_category IN (
        'PHYSICAL',            -- 물리적 특성
        'DEMOGRAPHIC',         -- 인구통계학적
        'USAGE_PATTERN',       -- 사용 패턴
        'BUSINESS',            -- 사업 관련
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_weight_factor CHECK (weight_factor > 0),
    CONSTRAINT chk_basis_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 4. 배분 조정 이력 테이블
CREATE TABLE IF NOT EXISTS bms.allocation_adjustment_history (
    adjustment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    allocation_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 조정 정보
    adjustment_type VARCHAR(20) NOT NULL,               -- 조정 유형
    original_amount DECIMAL(15,4) NOT NULL,             -- 원래 금액
    adjusted_amount DECIMAL(15,4) NOT NULL,             -- 조정된 금액
    adjustment_difference DECIMAL(15,4) NOT NULL,       -- 조정 차액
    
    -- 조정 사유
    adjustment_reason TEXT NOT NULL,                    -- 조정 사유
    adjustment_description TEXT,                        -- 조정 설명
    supporting_documents TEXT[],                        -- 지원 문서 URL
    
    -- 승인 정보
    requested_by UUID,                                  -- 요청자
    approved_by UUID,                                   -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,              -- 승인 일시
    
    -- 적용 정보
    applied_at TIMESTAMP WITH TIME ZONE,               -- 적용 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_adjustment_history_allocation FOREIGN KEY (allocation_id) REFERENCES bms.usage_allocations(allocation_id) ON DELETE CASCADE,
    CONSTRAINT fk_adjustment_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_adjustment_history_requester FOREIGN KEY (requested_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_adjustment_history_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_adjustment_type CHECK (adjustment_type IN (
        'MANUAL',              -- 수동 조정
        'SYSTEM',              -- 시스템 조정
        'ERROR_CORRECTION',    -- 오류 수정
        'POLICY_CHANGE',       -- 정책 변경
        'DISPUTE_RESOLUTION'   -- 분쟁 해결
    ))
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.usage_allocation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.usage_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.allocation_basis_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.allocation_adjustment_history ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY usage_allocation_rules_isolation_policy ON bms.usage_allocation_rules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY usage_allocations_isolation_policy ON bms.usage_allocations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY allocation_basis_data_isolation_policy ON bms.allocation_basis_data
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY allocation_adjustment_history_isolation_policy ON bms.allocation_adjustment_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 배분 규칙 인덱스
CREATE INDEX idx_allocation_rules_company_id ON bms.usage_allocation_rules(company_id);
CREATE INDEX idx_allocation_rules_building_id ON bms.usage_allocation_rules(building_id);
CREATE INDEX idx_allocation_rules_meter_type ON bms.usage_allocation_rules(meter_type);
CREATE INDEX idx_allocation_rules_method ON bms.usage_allocation_rules(allocation_method);
CREATE INDEX idx_allocation_rules_active ON bms.usage_allocation_rules(is_active);
CREATE INDEX idx_allocation_rules_effective_dates ON bms.usage_allocation_rules(effective_start_date, effective_end_date);

-- 사용량 배분 인덱스
CREATE INDEX idx_allocations_company_id ON bms.usage_allocations(company_id);
CREATE INDEX idx_allocations_rule_id ON bms.usage_allocations(rule_id);
CREATE INDEX idx_allocations_source_meter ON bms.usage_allocations(source_meter_id);
CREATE INDEX idx_allocations_target_unit ON bms.usage_allocations(target_unit_id);
CREATE INDEX idx_allocations_period ON bms.usage_allocations(allocation_period_start, allocation_period_end);
CREATE INDEX idx_allocations_status ON bms.usage_allocations(allocation_status);
CREATE INDEX idx_allocations_approval_status ON bms.usage_allocations(approval_status);

-- 배분 기준 데이터 인덱스
CREATE INDEX idx_basis_data_company_id ON bms.allocation_basis_data(company_id);
CREATE INDEX idx_basis_data_unit_id ON bms.allocation_basis_data(unit_id);
CREATE INDEX idx_basis_data_type ON bms.allocation_basis_data(data_type);
CREATE INDEX idx_basis_data_effective_dates ON bms.allocation_basis_data(effective_start_date, effective_end_date);

-- 조정 이력 인덱스
CREATE INDEX idx_adjustment_history_allocation_id ON bms.allocation_adjustment_history(allocation_id);
CREATE INDEX idx_adjustment_history_company_id ON bms.allocation_adjustment_history(company_id);
CREATE INDEX idx_adjustment_history_created_at ON bms.allocation_adjustment_history(created_at DESC);

-- 복합 인덱스
CREATE INDEX idx_allocations_rule_period ON bms.usage_allocations(rule_id, allocation_period_start, allocation_period_end);
CREATE INDEX idx_allocations_unit_period ON bms.usage_allocations(target_unit_id, allocation_period_start, allocation_period_end);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER usage_allocation_rules_updated_at_trigger
    BEFORE UPDATE ON bms.usage_allocation_rules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER usage_allocations_updated_at_trigger
    BEFORE UPDATE ON bms.usage_allocations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER allocation_basis_data_updated_at_trigger
    BEFORE UPDATE ON bms.allocation_basis_data
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 사용량 배분 계산 함수들
-- 비례 배분 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_proportional_allocation(
    p_rule_id UUID,
    p_period_start DATE,
    p_period_end DATE,
    p_source_meter_id UUID,
    p_total_usage DECIMAL(15,4)
)
RETURNS TABLE (
    unit_id UUID,
    allocation_ratio DECIMAL(8,4),
    allocated_amount DECIMAL(15,4)
) AS $$
DECLARE
    v_rule_rec RECORD;
    v_total_basis_value DECIMAL(15,4) := 0;
    v_unit_rec RECORD;
BEGIN
    -- 배분 규칙 조회
    SELECT * INTO v_rule_rec
    FROM bms.usage_allocation_rules
    WHERE rule_id = p_rule_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '배분 규칙을 찾을 수 없습니다: %', p_rule_id;
    END IF;
    
    -- 총 기준값 계산
    SELECT SUM(abd.numeric_value * abd.weight_factor) INTO v_total_basis_value
    FROM bms.allocation_basis_data abd
    JOIN bms.units u ON abd.unit_id = u.unit_id
    WHERE abd.company_id = v_rule_rec.company_id
      AND abd.data_type = CASE v_rule_rec.allocation_basis
          WHEN 'AREA' THEN 'AREA'
          WHEN 'HOUSEHOLD' THEN 'HOUSEHOLD_COUNT'
          WHEN 'OCCUPANCY' THEN 'OCCUPANCY_COUNT'
          ELSE 'USAGE_WEIGHT'
      END
      AND abd.is_active = true
      AND abd.effective_start_date <= p_period_end
      AND (abd.effective_end_date IS NULL OR abd.effective_end_date >= p_period_start)
      AND (v_rule_rec.target_unit_types IS NULL OR u.unit_type = ANY(v_rule_rec.target_unit_types));
    
    -- 총 기준값이 0이면 균등 배분
    IF v_total_basis_value IS NULL OR v_total_basis_value = 0 THEN
        SELECT COUNT(*) INTO v_total_basis_value
        FROM bms.units u
        WHERE u.building_id = (SELECT building_id FROM bms.meters WHERE meter_id = p_source_meter_id)
          AND (v_rule_rec.target_unit_types IS NULL OR u.unit_type = ANY(v_rule_rec.target_unit_types));
        
        -- 균등 배분
        RETURN QUERY
        SELECT 
            u.unit_id,
            (100.0 / v_total_basis_value)::DECIMAL(8,4) as allocation_ratio,
            (p_total_usage / v_total_basis_value)::DECIMAL(15,4) as allocated_amount
        FROM bms.units u
        WHERE u.building_id = (SELECT building_id FROM bms.meters WHERE meter_id = p_source_meter_id)
          AND (v_rule_rec.target_unit_types IS NULL OR u.unit_type = ANY(v_rule_rec.target_unit_types));
    ELSE
        -- 비례 배분
        RETURN QUERY
        SELECT 
            u.unit_id,
            ((abd.numeric_value * abd.weight_factor / v_total_basis_value) * 100)::DECIMAL(8,4) as allocation_ratio,
            ((abd.numeric_value * abd.weight_factor / v_total_basis_value) * p_total_usage)::DECIMAL(15,4) as allocated_amount
        FROM bms.allocation_basis_data abd
        JOIN bms.units u ON abd.unit_id = u.unit_id
        WHERE abd.company_id = v_rule_rec.company_id
          AND abd.data_type = CASE v_rule_rec.allocation_basis
              WHEN 'AREA' THEN 'AREA'
              WHEN 'HOUSEHOLD' THEN 'HOUSEHOLD_COUNT'
              WHEN 'OCCUPANCY' THEN 'OCCUPANCY_COUNT'
              ELSE 'USAGE_WEIGHT'
          END
          AND abd.is_active = true
          AND abd.effective_start_date <= p_period_end
          AND (abd.effective_end_date IS NULL OR abd.effective_end_date >= p_period_start)
          AND (v_rule_rec.target_unit_types IS NULL OR u.unit_type = ANY(v_rule_rec.target_unit_types));
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 배분 실행 함수
CREATE OR REPLACE FUNCTION bms.execute_usage_allocation(
    p_rule_id UUID,
    p_period_start DATE,
    p_period_end DATE
)
RETURNS INTEGER AS $$
DECLARE
    v_rule_rec RECORD;
    v_source_meter_id UUID;
    v_total_usage DECIMAL(15,4);
    v_allocation_rec RECORD;
    v_inserted_count INTEGER := 0;
BEGIN
    -- 배분 규칙 조회
    SELECT * INTO v_rule_rec
    FROM bms.usage_allocation_rules
    WHERE rule_id = p_rule_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '배분 규칙을 찾을 수 없습니다: %', p_rule_id;
    END IF;
    
    -- 원본 계량기별 배분 실행
    FOR v_source_meter_id IN 
        SELECT UNNEST(v_rule_rec.source_meter_ids)
    LOOP
        -- 해당 기간의 총 사용량 계산
        SELECT SUM(usage_amount) INTO v_total_usage
        FROM bms.meter_readings
        WHERE meter_id = v_source_meter_id
          AND reading_date BETWEEN p_period_start AND p_period_end
          AND usage_amount IS NOT NULL;
        
        IF v_total_usage IS NULL OR v_total_usage = 0 THEN
            CONTINUE;
        END IF;
        
        -- 배분 계산 및 결과 저장
        FOR v_allocation_rec IN 
            SELECT * FROM bms.calculate_proportional_allocation(
                p_rule_id, p_period_start, p_period_end, v_source_meter_id, v_total_usage
            )
        LOOP
            INSERT INTO bms.usage_allocations (
                company_id, rule_id, allocation_period_start, allocation_period_end,
                source_meter_id, target_unit_id, total_source_usage,
                allocation_ratio, calculated_amount, final_allocated_amount,
                allocation_status, approval_status
            ) VALUES (
                v_rule_rec.company_id, p_rule_id, p_period_start, p_period_end,
                v_source_meter_id, v_allocation_rec.unit_id, v_total_usage,
                v_allocation_rec.allocation_ratio, v_allocation_rec.allocated_amount, v_allocation_rec.allocated_amount,
                'CALCULATED', 'AUTO_APPROVED'
            )
            ON CONFLICT (rule_id, allocation_period_start, allocation_period_end, target_unit_id)
            DO UPDATE SET
                total_source_usage = EXCLUDED.total_source_usage,
                allocation_ratio = EXCLUDED.allocation_ratio,
                calculated_amount = EXCLUDED.calculated_amount,
                final_allocated_amount = EXCLUDED.final_allocated_amount,
                updated_at = NOW();
            
            v_inserted_count := v_inserted_count + 1;
        END LOOP;
    END LOOP;
    
    RETURN v_inserted_count;
END;
$$ LANGUAGE plpgsql;

-- 10. 사용량 배분 뷰 생성
CREATE OR REPLACE VIEW bms.v_usage_allocation_summary AS
SELECT 
    ua.allocation_id,
    ua.company_id,
    c.company_name,
    ua.allocation_period_start,
    ua.allocation_period_end,
    uar.rule_name,
    uar.allocation_method,
    uar.allocation_basis,
    m.meter_number as source_meter,
    m.meter_type,
    b.name as building_name,
    u.unit_number,
    ua.total_source_usage,
    ua.allocation_ratio,
    ua.calculated_amount,
    ua.adjustment_amount,
    ua.final_allocated_amount,
    ua.allocation_status,
    ua.approval_status,
    ua.created_at
FROM bms.usage_allocations ua
JOIN bms.companies c ON ua.company_id = c.company_id
JOIN bms.usage_allocation_rules uar ON ua.rule_id = uar.rule_id
JOIN bms.meters m ON ua.source_meter_id = m.meter_id
JOIN bms.buildings b ON m.building_id = b.building_id
JOIN bms.units u ON ua.target_unit_id = u.unit_id
ORDER BY ua.allocation_period_start DESC, b.name, u.unit_number;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_usage_allocation_summary OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 2.2 사용량 배분 테이블 생성이 완료되었습니다!' as result;