-- =====================================================
-- 관리비 검증 시스템 테이블 생성 스크립트
-- Phase 3.3: 관리비 검증 시스템
-- =====================================================

-- 1. 검증 규칙 정의 테이블
CREATE TABLE IF NOT EXISTS bms.validation_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체 규칙
    
    -- 규칙 기본 정보
    rule_name VARCHAR(100) NOT NULL,                       -- 규칙명
    rule_description TEXT,                                 -- 규칙 설명
    rule_category VARCHAR(20) NOT NULL,                    -- 규칙 분류
    rule_type VARCHAR(20) NOT NULL,                        -- 규칙 유형
    
    -- 검증 대상
    target_scope VARCHAR(20) NOT NULL,                     -- 검증 범위
    target_fee_types TEXT[],                               -- 대상 관리비 유형
    
    -- 검증 조건
    validation_condition JSONB NOT NULL,                   -- 검증 조건 (JSON)
    threshold_values JSONB,                                -- 임계값 설정
    
    -- 규칙 설정
    severity_level VARCHAR(20) DEFAULT 'WARNING',          -- 심각도 수준
    auto_fix_enabled BOOLEAN DEFAULT false,                -- 자동 수정 활성화
    auto_fix_action JSONB,                                 -- 자동 수정 액션
    
    -- 알림 설정
    notification_enabled BOOLEAN DEFAULT true,             -- 알림 활성화
    notification_recipients TEXT[],                        -- 알림 수신자
    
    -- 우선순위 및 상태
    priority_order INTEGER DEFAULT 1,                      -- 우선순위
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_validation_rules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_validation_rules_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_validation_rules_name UNIQUE (company_id, building_id, rule_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_rule_category CHECK (rule_category IN (
        'AMOUNT_VALIDATION',   -- 금액 검증
        'CALCULATION_LOGIC',   -- 계산 로직 검증
        'DATA_CONSISTENCY',    -- 데이터 일관성 검증
        'BUSINESS_RULE',       -- 비즈니스 규칙 검증
        'ANOMALY_DETECTION'    -- 이상치 탐지
    )),
    CONSTRAINT chk_rule_type CHECK (rule_type IN (
        'RANGE_CHECK',         -- 범위 검사
        'COMPARISON',          -- 비교 검사
        'FORMULA_VALIDATION',  -- 공식 검증
        'PATTERN_MATCHING',    -- 패턴 매칭
        'STATISTICAL',         -- 통계적 검증
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_target_scope CHECK (target_scope IN (
        'CALCULATION',         -- 계산 단위
        'UNIT',                -- 호실 단위
        'BUILDING',            -- 건물 단위
        'COMPANY'              -- 회사 단위
    )),
    CONSTRAINT chk_severity_level CHECK (severity_level IN (
        'INFO',                -- 정보
        'WARNING',             -- 경고
        'ERROR',               -- 오류
        'CRITICAL'             -- 치명적
    )),
    CONSTRAINT chk_priority_order CHECK (priority_order > 0),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 2. 검증 실행 결과 테이블
CREATE TABLE IF NOT EXISTS bms.validation_results (
    result_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    calculation_id UUID NOT NULL,
    rule_id UUID NOT NULL,
    
    -- 검증 대상 정보
    target_type VARCHAR(20) NOT NULL,                      -- 검증 대상 유형
    target_id UUID,                                        -- 검증 대상 ID (unit_id 등)
    target_description TEXT,                               -- 검증 대상 설명
    
    -- 검증 결과
    validation_status VARCHAR(20) NOT NULL,                -- 검증 상태
    severity_level VARCHAR(20) NOT NULL,                   -- 심각도
    
    -- 검증 상세
    validation_message TEXT NOT NULL,                      -- 검증 메시지
    expected_value JSONB,                                  -- 예상값
    actual_value JSONB,                                    -- 실제값
    deviation_amount DECIMAL(15,2),                        -- 편차 금액
    deviation_percentage DECIMAL(8,4),                     -- 편차 비율
    
    -- 검증 컨텍스트
    validation_context JSONB,                              -- 검증 컨텍스트
    related_data JSONB,                                    -- 관련 데이터
    
    -- 처리 상태
    resolution_status VARCHAR(20) DEFAULT 'PENDING',       -- 해결 상태
    resolution_action TEXT,                                -- 해결 액션
    resolved_by UUID,                                      -- 해결자
    resolved_at TIMESTAMP WITH TIME ZONE,                 -- 해결 일시
    resolution_notes TEXT,                                 -- 해결 메모
    
    -- 자동 수정
    auto_fix_applied BOOLEAN DEFAULT false,                -- 자동 수정 적용 여부
    auto_fix_details JSONB,                                -- 자동 수정 상세
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_validation_results_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_validation_results_calculation FOREIGN KEY (calculation_id) REFERENCES bms.monthly_fee_calculations(calculation_id) ON DELETE CASCADE,
    CONSTRAINT fk_validation_results_rule FOREIGN KEY (rule_id) REFERENCES bms.validation_rules(rule_id) ON DELETE CASCADE,
    CONSTRAINT fk_validation_results_resolver FOREIGN KEY (resolved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_target_type CHECK (target_type IN (
        'CALCULATION',         -- 계산 전체
        'UNIT_FEE',            -- 호실별 관리비
        'FEE_COMPONENT',       -- 관리비 구성요소
        'TOTAL_AMOUNT',        -- 총액
        'RATE_APPLICATION'     -- 요율 적용
    )),
    CONSTRAINT chk_validation_status CHECK (validation_status IN (
        'PASSED',              -- 통과
        'FAILED',              -- 실패
        'WARNING',             -- 경고
        'SKIPPED'              -- 건너뜀
    )),
    CONSTRAINT chk_result_severity_level CHECK (severity_level IN (
        'INFO',                -- 정보
        'WARNING',             -- 경고
        'ERROR',               -- 오류
        'CRITICAL'             -- 치명적
    )),
    CONSTRAINT chk_resolution_status CHECK (resolution_status IN (
        'PENDING',             -- 대기중
        'IN_PROGRESS',         -- 처리중
        'RESOLVED',            -- 해결됨
        'IGNORED',             -- 무시됨
        'DEFERRED'             -- 연기됨
    ))
);

-- 3. 이상치 탐지 설정 테이블
CREATE TABLE IF NOT EXISTS bms.anomaly_detection_configs (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- 설정 기본 정보
    config_name VARCHAR(100) NOT NULL,                     -- 설정명
    config_description TEXT,                               -- 설정 설명
    detection_type VARCHAR(20) NOT NULL,                   -- 탐지 유형
    
    -- 탐지 대상
    target_fee_types TEXT[],                               -- 대상 관리비 유형
    target_metrics TEXT[],                                 -- 대상 지표
    
    -- 탐지 알고리즘 설정
    algorithm_type VARCHAR(20) NOT NULL,                   -- 알고리즘 유형
    algorithm_parameters JSONB,                            -- 알고리즘 매개변수
    
    -- 임계값 설정
    threshold_method VARCHAR(20) DEFAULT 'STATISTICAL',    -- 임계값 방법
    threshold_multiplier DECIMAL(8,4) DEFAULT 2.0,         -- 임계값 배수
    min_threshold DECIMAL(15,2),                           -- 최소 임계값
    max_threshold DECIMAL(15,2),                           -- 최대 임계값
    
    -- 학습 데이터 설정
    training_period_months INTEGER DEFAULT 12,             -- 학습 기간 (개월)
    min_data_points INTEGER DEFAULT 10,                    -- 최소 데이터 포인트
    exclude_outliers BOOLEAN DEFAULT true,                 -- 이상치 제외
    
    -- 실행 설정
    auto_execution BOOLEAN DEFAULT true,                   -- 자동 실행
    execution_schedule VARCHAR(50),                        -- 실행 일정
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    last_execution_at TIMESTAMP WITH TIME ZONE,
    next_execution_at TIMESTAMP WITH TIME ZONE,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_anomaly_configs_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_anomaly_configs_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_anomaly_configs_name UNIQUE (company_id, building_id, config_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_detection_type CHECK (detection_type IN (
        'AMOUNT_SPIKE',        -- 금액 급증
        'AMOUNT_DROP',         -- 금액 급감
        'PATTERN_CHANGE',      -- 패턴 변화
        'SEASONAL_ANOMALY',    -- 계절적 이상
        'COMPARATIVE_ANOMALY'  -- 비교 이상
    )),
    CONSTRAINT chk_algorithm_type CHECK (algorithm_type IN (
        'Z_SCORE',             -- Z-점수
        'IQR',                 -- 사분위수 범위
        'ISOLATION_FOREST',    -- 고립 숲
        'MOVING_AVERAGE',      -- 이동 평균
        'SEASONAL_DECOMPOSE'   -- 계절 분해
    )),
    CONSTRAINT chk_threshold_method CHECK (threshold_method IN (
        'STATISTICAL',         -- 통계적
        'PERCENTILE',          -- 백분위수
        'FIXED',               -- 고정값
        'ADAPTIVE'             -- 적응형
    )),
    CONSTRAINT chk_training_period CHECK (training_period_months > 0),
    CONSTRAINT chk_min_data_points CHECK (min_data_points > 0)
);

-- 4. 검증 실행 이력 테이블
CREATE TABLE IF NOT EXISTS bms.validation_execution_history (
    execution_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    calculation_id UUID NOT NULL,
    
    -- 실행 정보
    execution_type VARCHAR(20) NOT NULL,                   -- 실행 유형
    execution_trigger VARCHAR(20) NOT NULL,                -- 실행 트리거
    execution_status VARCHAR(20) NOT NULL,                 -- 실행 상태
    
    -- 실행 범위
    total_rules_count INTEGER NOT NULL DEFAULT 0,          -- 총 규칙 수
    executed_rules_count INTEGER NOT NULL DEFAULT 0,       -- 실행된 규칙 수
    
    -- 실행 결과 요약
    passed_count INTEGER DEFAULT 0,                        -- 통과 수
    warning_count INTEGER DEFAULT 0,                       -- 경고 수
    error_count INTEGER DEFAULT 0,                         -- 오류 수
    critical_count INTEGER DEFAULT 0,                      -- 치명적 오류 수
    
    -- 성능 정보
    execution_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    execution_end_time TIMESTAMP WITH TIME ZONE,
    execution_duration_ms INTEGER,                         -- 실행 시간 (밀리초)
    
    -- 실행 상세
    execution_summary JSONB,                               -- 실행 요약
    error_details JSONB,                                   -- 오류 상세
    
    -- 실행자 정보
    executed_by UUID,                                      -- 실행자
    execution_notes TEXT,                                  -- 실행 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_validation_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_validation_history_calculation FOREIGN KEY (calculation_id) REFERENCES bms.monthly_fee_calculations(calculation_id) ON DELETE CASCADE,
    CONSTRAINT fk_validation_history_executor FOREIGN KEY (executed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_execution_type CHECK (execution_type IN (
        'MANUAL',              -- 수동 실행
        'AUTOMATIC',           -- 자동 실행
        'SCHEDULED',           -- 예약 실행
        'TRIGGERED'            -- 트리거 실행
    )),
    CONSTRAINT chk_execution_trigger CHECK (execution_trigger IN (
        'USER_REQUEST',        -- 사용자 요청
        'CALCULATION_COMPLETE', -- 계산 완료
        'SCHEDULE',            -- 일정
        'DATA_CHANGE',         -- 데이터 변경
        'SYSTEM_EVENT'         -- 시스템 이벤트
    )),
    CONSTRAINT chk_execution_status CHECK (execution_status IN (
        'RUNNING',             -- 실행중
        'COMPLETED',           -- 완료
        'FAILED',              -- 실패
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_execution_counts CHECK (
        total_rules_count >= 0 AND executed_rules_count >= 0 AND
        passed_count >= 0 AND warning_count >= 0 AND 
        error_count >= 0 AND critical_count >= 0
    ),
    CONSTRAINT chk_execution_times CHECK (
        execution_end_time IS NULL OR execution_end_time >= execution_start_time
    )
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.validation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.validation_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.anomaly_detection_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.validation_execution_history ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY validation_rules_isolation_policy ON bms.validation_rules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY validation_results_isolation_policy ON bms.validation_results
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY anomaly_detection_configs_isolation_policy ON bms.anomaly_detection_configs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY validation_execution_history_isolation_policy ON bms.validation_execution_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 검증 규칙 인덱스
CREATE INDEX idx_validation_rules_company_id ON bms.validation_rules(company_id);
CREATE INDEX idx_validation_rules_building_id ON bms.validation_rules(building_id);
CREATE INDEX idx_validation_rules_category ON bms.validation_rules(rule_category);
CREATE INDEX idx_validation_rules_type ON bms.validation_rules(rule_type);
CREATE INDEX idx_validation_rules_active ON bms.validation_rules(is_active);
CREATE INDEX idx_validation_rules_priority ON bms.validation_rules(priority_order);

-- 검증 결과 인덱스
CREATE INDEX idx_validation_results_company_id ON bms.validation_results(company_id);
CREATE INDEX idx_validation_results_calculation_id ON bms.validation_results(calculation_id);
CREATE INDEX idx_validation_results_rule_id ON bms.validation_results(rule_id);
CREATE INDEX idx_validation_results_status ON bms.validation_results(validation_status);
CREATE INDEX idx_validation_results_severity ON bms.validation_results(severity_level);
CREATE INDEX idx_validation_results_resolution ON bms.validation_results(resolution_status);
CREATE INDEX idx_validation_results_created_at ON bms.validation_results(created_at DESC);

-- 이상치 탐지 설정 인덱스
CREATE INDEX idx_anomaly_configs_company_id ON bms.anomaly_detection_configs(company_id);
CREATE INDEX idx_anomaly_configs_building_id ON bms.anomaly_detection_configs(building_id);
CREATE INDEX idx_anomaly_configs_type ON bms.anomaly_detection_configs(detection_type);
CREATE INDEX idx_anomaly_configs_active ON bms.anomaly_detection_configs(is_active);
CREATE INDEX idx_anomaly_configs_next_execution ON bms.anomaly_detection_configs(next_execution_at);

-- 검증 실행 이력 인덱스
CREATE INDEX idx_validation_history_company_id ON bms.validation_execution_history(company_id);
CREATE INDEX idx_validation_history_calculation_id ON bms.validation_execution_history(calculation_id);
CREATE INDEX idx_validation_history_type ON bms.validation_execution_history(execution_type);
CREATE INDEX idx_validation_history_status ON bms.validation_execution_history(execution_status);
CREATE INDEX idx_validation_history_start_time ON bms.validation_execution_history(execution_start_time DESC);

-- 복합 인덱스
CREATE INDEX idx_validation_rules_company_active ON bms.validation_rules(company_id, is_active);
CREATE INDEX idx_validation_results_calc_status ON bms.validation_results(calculation_id, validation_status);
CREATE INDEX idx_validation_results_severity_resolution ON bms.validation_results(severity_level, resolution_status);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER validation_rules_updated_at_trigger
    BEFORE UPDATE ON bms.validation_rules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER validation_results_updated_at_trigger
    BEFORE UPDATE ON bms.validation_results
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER anomaly_detection_configs_updated_at_trigger
    BEFORE UPDATE ON bms.anomaly_detection_configs
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 검증 시스템 뷰 생성
CREATE OR REPLACE VIEW bms.v_validation_dashboard AS
SELECT 
    vr.rule_id,
    vr.company_id,
    c.company_name,
    vr.building_id,
    b.name as building_name,
    vr.rule_name,
    vr.rule_category,
    vr.severity_level,
    vr.is_active,
    COUNT(vres.result_id) as total_executions,
    COUNT(CASE WHEN vres.validation_status = 'PASSED' THEN 1 END) as passed_count,
    COUNT(CASE WHEN vres.validation_status = 'FAILED' THEN 1 END) as failed_count,
    COUNT(CASE WHEN vres.validation_status = 'WARNING' THEN 1 END) as warning_count,
    COUNT(CASE WHEN vres.resolution_status = 'PENDING' THEN 1 END) as pending_issues,
    MAX(vres.created_at) as last_execution_at
FROM bms.validation_rules vr
JOIN bms.companies c ON vr.company_id = c.company_id
LEFT JOIN bms.buildings b ON vr.building_id = b.building_id
LEFT JOIN bms.validation_results vres ON vr.rule_id = vres.rule_id
    AND vres.created_at >= CURRENT_DATE - INTERVAL '30 days'  -- 최근 30일
GROUP BY vr.rule_id, c.company_name, b.name, vr.rule_name, vr.rule_category, vr.severity_level, vr.is_active
ORDER BY c.company_name, b.name, vr.rule_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_validation_dashboard OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 3.3 관리비 검증 시스템 테이블 생성이 완료되었습니다!' as result;