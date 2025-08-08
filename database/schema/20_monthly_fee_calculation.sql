-- =====================================================
-- 월별 관리비 산정 시스템 테이블 생성 스크립트
-- Phase 3.1: 월별 관리비 산정 테이블
-- =====================================================

-- 1. 월별 관리비 산정 헤더 테이블
CREATE TABLE IF NOT EXISTS bms.monthly_fee_calculations (
    calculation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID NOT NULL,
    
    -- 산정 기본 정보
    calculation_period DATE NOT NULL,                      -- 산정 기간 (YYYY-MM-01)
    calculation_name VARCHAR(100),                         -- 산정명
    calculation_type VARCHAR(20) NOT NULL,                 -- 산정 유형
    
    -- 산정 범위
    target_unit_count INTEGER NOT NULL DEFAULT 0,          -- 대상 호실 수
    included_unit_types TEXT[],                            -- 포함된 호실 유형
    excluded_unit_ids UUID[],                              -- 제외된 호실 ID
    
    -- 산정 상태
    calculation_status VARCHAR(20) DEFAULT 'DRAFT',        -- 산정 상태
    calculation_method VARCHAR(20) NOT NULL,               -- 산정 방법
    
    -- 총액 정보
    total_common_fees DECIMAL(15,2) DEFAULT 0,             -- 총 공통 관리비
    total_individual_fees DECIMAL(15,2) DEFAULT 0,         -- 총 개별 관리비
    total_utility_fees DECIMAL(15,2) DEFAULT 0,            -- 총 공과금
    total_amount DECIMAL(15,2) DEFAULT 0,                  -- 총 관리비
    
    -- 산정 기준 정보
    base_date DATE,                                        -- 기준일
    exchange_rate DECIMAL(10,4),                           -- 환율 (외화 관리비용)
    inflation_rate DECIMAL(8,4),                           -- 물가상승률
    
    -- 산정 설정
    calculation_rules JSONB,                               -- 산정 규칙 (JSON)
    rounding_method VARCHAR(20) DEFAULT 'ROUND',           -- 반올림 방법
    rounding_unit INTEGER DEFAULT 1,                       -- 반올림 단위
    
    -- 검증 정보
    is_validated BOOLEAN DEFAULT false,                    -- 검증 완료 여부
    validation_errors JSONB,                               -- 검증 오류 내역
    validated_by UUID,                                     -- 검증자 ID
    validated_at TIMESTAMP WITH TIME ZONE,                -- 검증 일시
    
    -- 승인 정보
    is_approved BOOLEAN DEFAULT false,                     -- 승인 여부
    approved_by UUID,                                      -- 승인자 ID
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 확정 정보
    is_finalized BOOLEAN DEFAULT false,                    -- 확정 여부
    finalized_by UUID,                                     -- 확정자 ID
    finalized_at TIMESTAMP WITH TIME ZONE,                -- 확정 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_calculations_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_calculations_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_calculations_validator FOREIGN KEY (validated_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_calculations_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_calculations_finalizer FOREIGN KEY (finalized_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_calculations_period UNIQUE (building_id, calculation_period, calculation_type),
    
    -- 체크 제약조건
    CONSTRAINT chk_calculation_type CHECK (calculation_type IN (
        'REGULAR',             -- 정기 산정
        'ADJUSTMENT',          -- 조정 산정
        'SPECIAL',             -- 특별 산정
        'CORRECTION',          -- 정정 산정
        'ESTIMATE'             -- 추정 산정
    )),
    CONSTRAINT chk_calculation_status CHECK (calculation_status IN (
        'DRAFT',               -- 초안
        'CALCULATING',         -- 계산중
        'CALCULATED',          -- 계산 완료
        'VALIDATED',           -- 검증 완료
        'APPROVED',            -- 승인 완료
        'FINALIZED',           -- 확정 완료
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_calculation_method CHECK (calculation_method IN (
        'AUTOMATIC',           -- 자동 산정
        'MANUAL',              -- 수동 산정
        'HYBRID',              -- 혼합 산정
        'IMPORTED'             -- 가져오기
    )),
    CONSTRAINT chk_rounding_method CHECK (rounding_method IN (
        'ROUND',               -- 반올림
        'FLOOR',               -- 내림
        'CEILING'              -- 올림
    )),
    CONSTRAINT chk_target_unit_count CHECK (target_unit_count >= 0),
    CONSTRAINT chk_total_amounts CHECK (
        total_common_fees >= 0 AND 
        total_individual_fees >= 0 AND 
        total_utility_fees >= 0 AND 
        total_amount >= 0
    ),
    CONSTRAINT chk_rounding_unit CHECK (rounding_unit > 0)
);

-- 2. 호실별 월별 관리비 상세 테이블
CREATE TABLE IF NOT EXISTS bms.unit_monthly_fees (
    fee_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calculation_id UUID NOT NULL,
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    
    -- 기본 정보
    fee_period DATE NOT NULL,                              -- 관리비 기간
    unit_number VARCHAR(20) NOT NULL,                      -- 호실번호
    unit_area DECIMAL(10,2),                               -- 호실 면적
    occupancy_status VARCHAR(20),                          -- 입주 상태
    
    -- 관리비 항목별 금액
    common_management_fee DECIMAL(15,2) DEFAULT 0,         -- 일반관리비
    cleaning_fee DECIMAL(15,2) DEFAULT 0,                  -- 청소비
    security_fee DECIMAL(15,2) DEFAULT 0,                  -- 경비비
    disinfection_fee DECIMAL(15,2) DEFAULT 0,              -- 소독비
    elevator_fee DECIMAL(15,2) DEFAULT 0,                  -- 승강기유지비
    facility_maintenance_fee DECIMAL(15,2) DEFAULT 0,      -- 시설보수비
    insurance_fee DECIMAL(15,2) DEFAULT 0,                 -- 보험료
    
    -- 공과금
    electricity_fee DECIMAL(15,2) DEFAULT 0,               -- 전기료
    water_fee DECIMAL(15,2) DEFAULT 0,                     -- 수도료
    gas_fee DECIMAL(15,2) DEFAULT 0,                       -- 가스료
    heating_fee DECIMAL(15,2) DEFAULT 0,                   -- 난방비
    hot_water_fee DECIMAL(15,2) DEFAULT 0,                 -- 온수료
    
    -- 기타 비용
    parking_fee DECIMAL(15,2) DEFAULT 0,                   -- 주차비
    cable_tv_fee DECIMAL(15,2) DEFAULT 0,                  -- 케이블TV비
    internet_fee DECIMAL(15,2) DEFAULT 0,                  -- 인터넷비
    other_fees DECIMAL(15,2) DEFAULT 0,                    -- 기타비용
    
    -- 할인 및 감면
    discount_amount DECIMAL(15,2) DEFAULT 0,               -- 할인금액
    exemption_amount DECIMAL(15,2) DEFAULT 0,              -- 감면금액
    late_fee DECIMAL(15,2) DEFAULT 0,                      -- 연체료
    
    -- 총액
    subtotal_amount DECIMAL(15,2) NOT NULL,                -- 소계
    adjustment_amount DECIMAL(15,2) DEFAULT 0,             -- 조정금액
    total_amount DECIMAL(15,2) NOT NULL,                   -- 총액
    
    -- 계산 상세 정보
    calculation_details JSONB,                             -- 계산 상세 내역 (JSON)
    applied_rates JSONB,                                   -- 적용된 요율 정보 (JSON)
    usage_data JSONB,                                      -- 사용량 데이터 (JSON)
    
    -- 조정 정보
    adjustment_reason TEXT,                                -- 조정 사유
    adjusted_by UUID,                                      -- 조정자
    adjusted_at TIMESTAMP WITH TIME ZONE,                 -- 조정 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_unit_fees_calculation FOREIGN KEY (calculation_id) REFERENCES bms.monthly_fee_calculations(calculation_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_fees_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_fees_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_unit_fees_adjuster FOREIGN KEY (adjusted_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_unit_fees_period UNIQUE (calculation_id, unit_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_occupancy_status CHECK (occupancy_status IN (
        'OCCUPIED',            -- 입주
        'VACANT',              -- 공실
        'MOVING_IN',           -- 입주중
        'MOVING_OUT',          -- 퇴거중
        'MAINTENANCE'          -- 보수중
    )),
    CONSTRAINT chk_fee_amounts CHECK (
        common_management_fee >= 0 AND cleaning_fee >= 0 AND security_fee >= 0 AND
        disinfection_fee >= 0 AND elevator_fee >= 0 AND facility_maintenance_fee >= 0 AND
        insurance_fee >= 0 AND electricity_fee >= 0 AND water_fee >= 0 AND
        gas_fee >= 0 AND heating_fee >= 0 AND hot_water_fee >= 0 AND
        parking_fee >= 0 AND cable_tv_fee >= 0 AND internet_fee >= 0 AND
        other_fees >= 0 AND discount_amount >= 0 AND exemption_amount >= 0 AND
        late_fee >= 0 AND subtotal_amount >= 0 AND total_amount >= 0
    )
);

-- 3. 관리비 계산 과정 추적 테이블
CREATE TABLE IF NOT EXISTS bms.fee_calculation_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calculation_id UUID NOT NULL,
    company_id UUID NOT NULL,
    unit_id UUID,                                          -- NULL이면 전체 계산 로그
    
    -- 로그 정보
    step_sequence INTEGER NOT NULL,                        -- 단계 순서
    step_name VARCHAR(100) NOT NULL,                       -- 단계명
    step_type VARCHAR(20) NOT NULL,                        -- 단계 유형
    step_description TEXT,                                 -- 단계 설명
    
    -- 계산 정보
    input_data JSONB,                                      -- 입력 데이터
    calculation_formula TEXT,                              -- 계산 공식
    calculation_result JSONB,                              -- 계산 결과
    
    -- 실행 정보
    execution_status VARCHAR(20) NOT NULL,                 -- 실행 상태
    execution_time_ms INTEGER,                             -- 실행 시간 (밀리초)
    error_message TEXT,                                    -- 오류 메시지
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_logs_calculation FOREIGN KEY (calculation_id) REFERENCES bms.monthly_fee_calculations(calculation_id) ON DELETE CASCADE,
    CONSTRAINT fk_logs_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_logs_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_step_type CHECK (step_type IN (
        'INITIALIZATION',      -- 초기화
        'DATA_COLLECTION',     -- 데이터 수집
        'RATE_CALCULATION',    -- 요율 계산
        'USAGE_CALCULATION',   -- 사용량 계산
        'FEE_CALCULATION',     -- 관리비 계산
        'ADJUSTMENT',          -- 조정
        'VALIDATION',          -- 검증
        'FINALIZATION'         -- 확정
    )),
    CONSTRAINT chk_execution_status CHECK (execution_status IN (
        'SUCCESS',             -- 성공
        'FAILED',              -- 실패
        'WARNING',             -- 경고
        'SKIPPED'              -- 건너뜀
    )),
    CONSTRAINT chk_step_sequence CHECK (step_sequence > 0),
    CONSTRAINT chk_execution_time CHECK (execution_time_ms >= 0)
);

-- 4. 관리비 조정 이력 테이블
CREATE TABLE IF NOT EXISTS bms.fee_adjustment_history (
    adjustment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calculation_id UUID NOT NULL,
    unit_fee_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 조정 정보
    adjustment_type VARCHAR(20) NOT NULL,                  -- 조정 유형
    adjustment_reason TEXT NOT NULL,                       -- 조정 사유
    adjustment_category VARCHAR(20),                       -- 조정 분류
    
    -- 조정 전후 금액
    original_amount DECIMAL(15,2) NOT NULL,                -- 원래 금액
    adjusted_amount DECIMAL(15,2) NOT NULL,                -- 조정 금액
    adjustment_difference DECIMAL(15,2) NOT NULL,          -- 조정 차액
    
    -- 조정 상세
    affected_fee_items TEXT[],                             -- 영향받은 관리비 항목
    adjustment_details JSONB,                              -- 조정 상세 내역
    
    -- 승인 정보
    requires_approval BOOLEAN DEFAULT true,                -- 승인 필요 여부
    approval_status VARCHAR(20) DEFAULT 'PENDING',         -- 승인 상태
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 처리자 정보
    requested_by UUID NOT NULL,                            -- 요청자
    processed_by UUID,                                     -- 처리자
    processed_at TIMESTAMP WITH TIME ZONE,                -- 처리 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_adjustments_calculation FOREIGN KEY (calculation_id) REFERENCES bms.monthly_fee_calculations(calculation_id) ON DELETE CASCADE,
    CONSTRAINT fk_adjustments_unit_fee FOREIGN KEY (unit_fee_id) REFERENCES bms.unit_monthly_fees(fee_id) ON DELETE CASCADE,
    CONSTRAINT fk_adjustments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_adjustments_requester FOREIGN KEY (requested_by) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_adjustments_processor FOREIGN KEY (processed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_adjustments_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_adjustment_type CHECK (adjustment_type IN (
        'MANUAL',              -- 수동 조정
        'SYSTEM',              -- 시스템 조정
        'CORRECTION',          -- 오류 정정
        'DISCOUNT',            -- 할인 적용
        'EXEMPTION',           -- 감면 적용
        'LATE_FEE',            -- 연체료 적용
        'REFUND'               -- 환불
    )),
    CONSTRAINT chk_adjustment_category CHECK (adjustment_category IN (
        'CALCULATION_ERROR',   -- 계산 오류
        'POLICY_CHANGE',       -- 정책 변경
        'SPECIAL_CASE',        -- 특별 사례
        'CUSTOMER_REQUEST',    -- 고객 요청
        'SYSTEM_ERROR',        -- 시스템 오류
        'DATA_CORRECTION'      -- 데이터 정정
    )),
    CONSTRAINT chk_adjustment_approval_status CHECK (approval_status IN (
        'PENDING',             -- 대기중
        'APPROVED',            -- 승인
        'REJECTED',            -- 반려
        'AUTO_APPROVED'        -- 자동 승인
    ))
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.monthly_fee_calculations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.unit_monthly_fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_calculation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fee_adjustment_history ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY monthly_fee_calculations_isolation_policy ON bms.monthly_fee_calculations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY unit_monthly_fees_isolation_policy ON bms.unit_monthly_fees
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_calculation_logs_isolation_policy ON bms.fee_calculation_logs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fee_adjustment_history_isolation_policy ON bms.fee_adjustment_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 월별 관리비 산정 헤더 인덱스
CREATE INDEX idx_calculations_company_id ON bms.monthly_fee_calculations(company_id);
CREATE INDEX idx_calculations_building_id ON bms.monthly_fee_calculations(building_id);
CREATE INDEX idx_calculations_period ON bms.monthly_fee_calculations(calculation_period DESC);
CREATE INDEX idx_calculations_status ON bms.monthly_fee_calculations(calculation_status);
CREATE INDEX idx_calculations_type ON bms.monthly_fee_calculations(calculation_type);
CREATE INDEX idx_calculations_method ON bms.monthly_fee_calculations(calculation_method);

-- 호실별 월별 관리비 인덱스
CREATE INDEX idx_unit_fees_calculation_id ON bms.unit_monthly_fees(calculation_id);
CREATE INDEX idx_unit_fees_company_id ON bms.unit_monthly_fees(company_id);
CREATE INDEX idx_unit_fees_unit_id ON bms.unit_monthly_fees(unit_id);
CREATE INDEX idx_unit_fees_period ON bms.unit_monthly_fees(fee_period DESC);
CREATE INDEX idx_unit_fees_unit_number ON bms.unit_monthly_fees(unit_number);
CREATE INDEX idx_unit_fees_occupancy ON bms.unit_monthly_fees(occupancy_status);

-- 계산 로그 인덱스
CREATE INDEX idx_logs_calculation_id ON bms.fee_calculation_logs(calculation_id);
CREATE INDEX idx_logs_company_id ON bms.fee_calculation_logs(company_id);
CREATE INDEX idx_logs_unit_id ON bms.fee_calculation_logs(unit_id);
CREATE INDEX idx_logs_step_sequence ON bms.fee_calculation_logs(step_sequence);
CREATE INDEX idx_logs_step_type ON bms.fee_calculation_logs(step_type);
CREATE INDEX idx_logs_status ON bms.fee_calculation_logs(execution_status);
CREATE INDEX idx_logs_created_at ON bms.fee_calculation_logs(created_at DESC);

-- 조정 이력 인덱스
CREATE INDEX idx_adjustments_calculation_id ON bms.fee_adjustment_history(calculation_id);
CREATE INDEX idx_adjustments_unit_fee_id ON bms.fee_adjustment_history(unit_fee_id);
CREATE INDEX idx_adjustments_company_id ON bms.fee_adjustment_history(company_id);
CREATE INDEX idx_adjustments_type ON bms.fee_adjustment_history(adjustment_type);
CREATE INDEX idx_adjustments_approval_status ON bms.fee_adjustment_history(approval_status);
CREATE INDEX idx_adjustments_requested_by ON bms.fee_adjustment_history(requested_by);
CREATE INDEX idx_adjustments_created_at ON bms.fee_adjustment_history(created_at DESC);

-- 복합 인덱스
CREATE INDEX idx_calculations_company_period ON bms.monthly_fee_calculations(company_id, calculation_period DESC);
CREATE INDEX idx_calculations_building_period ON bms.monthly_fee_calculations(building_id, calculation_period DESC);
CREATE INDEX idx_unit_fees_unit_period ON bms.unit_monthly_fees(unit_id, fee_period DESC);
CREATE INDEX idx_logs_calculation_sequence ON bms.fee_calculation_logs(calculation_id, step_sequence);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER monthly_fee_calculations_updated_at_trigger
    BEFORE UPDATE ON bms.monthly_fee_calculations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER unit_monthly_fees_updated_at_trigger
    BEFORE UPDATE ON bms.unit_monthly_fees
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fee_adjustment_history_updated_at_trigger
    BEFORE UPDATE ON bms.fee_adjustment_history
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 월별 관리비 산정 뷰 생성
CREATE OR REPLACE VIEW bms.v_monthly_fee_summary AS
SELECT 
    mfc.calculation_id,
    mfc.company_id,
    c.company_name,
    mfc.building_id,
    b.name as building_name,
    mfc.calculation_period,
    mfc.calculation_name,
    mfc.calculation_type,
    mfc.calculation_status,
    mfc.target_unit_count,
    mfc.total_amount,
    mfc.is_validated,
    mfc.is_approved,
    mfc.is_finalized,
    COUNT(umf.fee_id) as calculated_unit_count,
    SUM(umf.total_amount) as sum_unit_fees,
    AVG(umf.total_amount) as avg_unit_fee,
    mfc.created_at,
    mfc.updated_at
FROM bms.monthly_fee_calculations mfc
JOIN bms.companies c ON mfc.company_id = c.company_id
JOIN bms.buildings b ON mfc.building_id = b.building_id
LEFT JOIN bms.unit_monthly_fees umf ON mfc.calculation_id = umf.calculation_id
GROUP BY mfc.calculation_id, c.company_name, b.name
ORDER BY mfc.calculation_period DESC, c.company_name, b.name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_monthly_fee_summary OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 3.1 월별 관리비 산정 테이블 생성이 완료되었습니다!' as result;