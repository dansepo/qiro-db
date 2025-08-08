-- =====================================================
-- 작업 인력 투입 시간 및 비용 추적 시스템
-- 태스크 4.2: 작업 인력 투입 시간 및 비용 추적 기능 구현
-- =====================================================

-- 1. 작업 인력 시간 추적 테이블 (기존 work_order_assignments 확장)
CREATE TABLE IF NOT EXISTS bms.work_order_labor_tracking (
    labor_tracking_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    assignment_id UUID NOT NULL, -- work_order_assignments 테이블 참조
    
    -- 작업자 정보
    worker_id UUID NOT NULL,
    worker_role VARCHAR(30) NOT NULL,
    skill_level VARCHAR(20) DEFAULT 'BASIC',
    
    -- 시간 추적
    work_date DATE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    break_duration_minutes INTEGER DEFAULT 0,
    actual_work_hours DECIMAL(8,2) NOT NULL,
    
    -- 작업 내용
    work_description TEXT,
    work_location TEXT,
    work_phase VARCHAR(30),
    
    -- 비용 정보
    hourly_rate DECIMAL(10,2) DEFAULT 0,
    overtime_rate DECIMAL(10,2) DEFAULT 0,
    regular_hours DECIMAL(8,2) DEFAULT 0,
    overtime_hours DECIMAL(8,2) DEFAULT 0,
    total_labor_cost DECIMAL(12,2) DEFAULT 0,
    
    -- 성과 지표
    productivity_score DECIMAL(3,1) DEFAULT 0, -- 0-10 점수
    quality_score DECIMAL(3,1) DEFAULT 0,
    safety_score DECIMAL(3,1) DEFAULT 0,
    
    -- 도구 및 장비 사용
    tools_used JSONB,
    equipment_used JSONB,
    
    -- 상태 및 승인
    tracking_status VARCHAR(20) DEFAULT 'RECORDED',
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_labor_tracking_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_labor_tracking_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_labor_tracking_assignment FOREIGN KEY (assignment_id) REFERENCES bms.work_order_assignments(assignment_id) ON DELETE CASCADE,
    
    -- 체크 제약 조건
    CONSTRAINT chk_labor_work_hours CHECK (
        actual_work_hours > 0 AND
        regular_hours >= 0 AND
        overtime_hours >= 0 AND
        actual_work_hours = regular_hours + overtime_hours
    ),
    CONSTRAINT chk_labor_rates CHECK (
        hourly_rate >= 0 AND
        overtime_rate >= 0 AND
        total_labor_cost >= 0
    ),
    CONSTRAINT chk_labor_scores CHECK (
        productivity_score >= 0 AND productivity_score <= 10 AND
        quality_score >= 0 AND quality_score <= 10 AND
        safety_score >= 0 AND safety_score <= 10
    ),
    CONSTRAINT chk_labor_times CHECK (
        end_time IS NULL OR start_time IS NULL OR end_time > start_time
    ),
    CONSTRAINT chk_worker_role CHECK (worker_role IN (
        'PRIMARY_TECHNICIAN', 'ASSISTANT_TECHNICIAN', 'SUPERVISOR', 
        'SPECIALIST', 'CONTRACTOR', 'INSPECTOR', 'COORDINATOR', 'HELPER'
    )),
    CONSTRAINT chk_skill_level CHECK (skill_level IN (
        'BASIC', 'INTERMEDIATE', 'ADVANCED', 'EXPERT', 'SPECIALIST'
    )),
    CONSTRAINT chk_work_phase_labor CHECK (work_phase IN (
        'PLANNING', 'PREPARATION', 'EXECUTION', 'TESTING', 'COMPLETION', 'CLEANUP'
    )),
    CONSTRAINT chk_tracking_status CHECK (tracking_status IN (
        'RECORDED', 'SUBMITTED', 'APPROVED', 'REJECTED', 'REVISED'
    ))
);

-- 2. 인력 비용 계산 및 집계 테이블
CREATE TABLE IF NOT EXISTS bms.work_order_labor_costs (
    labor_cost_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- 집계 기간
    cost_date DATE NOT NULL,
    cost_period VARCHAR(20) DEFAULT 'DAILY', -- DAILY, WEEKLY, MONTHLY
    
    -- 인력 비용 집계
    total_regular_hours DECIMAL(10,2) DEFAULT 0,
    total_overtime_hours DECIMAL(10,2) DEFAULT 0,
    total_work_hours DECIMAL(10,2) DEFAULT 0,
    
    -- 비용 집계
    total_regular_cost DECIMAL(12,2) DEFAULT 0,
    total_overtime_cost DECIMAL(12,2) DEFAULT 0,
    total_labor_cost DECIMAL(12,2) DEFAULT 0,
    
    -- 인력 수
    worker_count INTEGER DEFAULT 0,
    contractor_count INTEGER DEFAULT 0,
    
    -- 평균 비율
    average_hourly_rate DECIMAL(10,2) DEFAULT 0,
    average_productivity DECIMAL(3,1) DEFAULT 0,
    average_quality_score DECIMAL(3,1) DEFAULT 0,
    
    -- 비용 분류
    internal_labor_cost DECIMAL(12,2) DEFAULT 0,
    external_labor_cost DECIMAL(12,2) DEFAULT 0,
    contractor_cost DECIMAL(12,2) DEFAULT 0,
    
    -- 상태
    calculation_status VARCHAR(20) DEFAULT 'CALCULATED',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_labor_costs_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_labor_costs_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    CONSTRAINT uk_labor_costs_work_order_date UNIQUE (work_order_id, cost_date, cost_period),
    
    -- 체크 제약 조건
    CONSTRAINT chk_labor_cost_hours CHECK (
        total_regular_hours >= 0 AND
        total_overtime_hours >= 0 AND
        total_work_hours >= 0 AND
        total_work_hours = total_regular_hours + total_overtime_hours
    ),
    CONSTRAINT chk_labor_cost_amounts CHECK (
        total_regular_cost >= 0 AND
        total_overtime_cost >= 0 AND
        total_labor_cost >= 0 AND
        internal_labor_cost >= 0 AND
        external_labor_cost >= 0 AND
        contractor_cost >= 0
    ),
    CONSTRAINT chk_labor_cost_counts CHECK (
        worker_count >= 0 AND
        contractor_count >= 0
    ),
    CONSTRAINT chk_cost_period CHECK (cost_period IN (
        'DAILY', 'WEEKLY', 'MONTHLY', 'PROJECT'
    )),
    CONSTRAINT chk_calculation_status CHECK (calculation_status IN (
        'CALCULATED', 'APPROVED', 'ADJUSTED', 'FINALIZED'
    ))
);

-- 3. 인력 성과 평가 테이블
CREATE TABLE IF NOT EXISTS bms.worker_performance_evaluation (
    evaluation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    worker_id UUID NOT NULL,
    
    -- 평가 기간
    evaluation_date DATE NOT NULL,
    evaluation_period VARCHAR(20) DEFAULT 'WORK_ORDER',
    
    -- 성과 지표
    total_hours_worked DECIMAL(10,2) DEFAULT 0,
    tasks_completed INTEGER DEFAULT 0,
    tasks_assigned INTEGER DEFAULT 0,
    completion_rate DECIMAL(5,2) DEFAULT 0, -- 완료율 (%)
    
    -- 품질 지표
    quality_score DECIMAL(3,1) DEFAULT 0,
    rework_incidents INTEGER DEFAULT 0,
    customer_complaints INTEGER DEFAULT 0,
    
    -- 안전 지표
    safety_score DECIMAL(3,1) DEFAULT 0,
    safety_incidents INTEGER DEFAULT 0,
    safety_training_hours DECIMAL(8,2) DEFAULT 0,
    
    -- 효율성 지표
    productivity_score DECIMAL(3,1) DEFAULT 0,
    average_task_time DECIMAL(8,2) DEFAULT 0,
    overtime_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- 협업 지표
    teamwork_score DECIMAL(3,1) DEFAULT 0,
    communication_score DECIMAL(3,1) DEFAULT 0,
    leadership_score DECIMAL(3,1) DEFAULT 0,
    
    -- 종합 평가
    overall_rating DECIMAL(3,1) DEFAULT 0,
    performance_grade VARCHAR(2), -- A+, A, B+, B, C+, C, D, F
    
    -- 평가자 정보
    evaluated_by UUID,
    evaluation_notes TEXT,
    improvement_suggestions TEXT,
    
    -- 상태
    evaluation_status VARCHAR(20) DEFAULT 'DRAFT',
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_performance_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_performance_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    
    -- 체크 제약 조건
    CONSTRAINT chk_performance_scores CHECK (
        quality_score >= 0 AND quality_score <= 10 AND
        safety_score >= 0 AND safety_score <= 10 AND
        productivity_score >= 0 AND productivity_score <= 10 AND
        teamwork_score >= 0 AND teamwork_score <= 10 AND
        communication_score >= 0 AND communication_score <= 10 AND
        leadership_score >= 0 AND leadership_score <= 10 AND
        overall_rating >= 0 AND overall_rating <= 10
    ),
    CONSTRAINT chk_performance_rates CHECK (
        completion_rate >= 0 AND completion_rate <= 100 AND
        overtime_percentage >= 0 AND overtime_percentage <= 100
    ),
    CONSTRAINT chk_performance_counts CHECK (
        tasks_completed >= 0 AND
        tasks_assigned >= 0 AND
        tasks_completed <= tasks_assigned AND
        rework_incidents >= 0 AND
        customer_complaints >= 0 AND
        safety_incidents >= 0
    ),
    CONSTRAINT chk_evaluation_period CHECK (evaluation_period IN (
        'WORK_ORDER', 'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUAL'
    )),
    CONSTRAINT chk_performance_grade CHECK (performance_grade IN (
        'A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F'
    )),
    CONSTRAINT chk_evaluation_status CHECK (evaluation_status IN (
        'DRAFT', 'SUBMITTED', 'REVIEWED', 'APPROVED', 'FINALIZED'
    ))
);

-- 4. RLS 정책 설정
ALTER TABLE bms.work_order_labor_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.work_order_labor_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.worker_performance_evaluation ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성
CREATE POLICY work_order_labor_tracking_isolation_policy ON bms.work_order_labor_tracking
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY work_order_labor_costs_isolation_policy ON bms.work_order_labor_costs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY worker_performance_evaluation_isolation_policy ON bms.worker_performance_evaluation
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 5. 인덱스 생성
-- work_order_labor_tracking 인덱스
CREATE INDEX IF NOT EXISTS idx_labor_tracking_company_id ON bms.work_order_labor_tracking(company_id);
CREATE INDEX IF NOT EXISTS idx_labor_tracking_work_order ON bms.work_order_labor_tracking(work_order_id);
CREATE INDEX IF NOT EXISTS idx_labor_tracking_assignment ON bms.work_order_labor_tracking(assignment_id);
CREATE INDEX IF NOT EXISTS idx_labor_tracking_worker ON bms.work_order_labor_tracking(worker_id);
CREATE INDEX IF NOT EXISTS idx_labor_tracking_date ON bms.work_order_labor_tracking(work_date);
CREATE INDEX IF NOT EXISTS idx_labor_tracking_status ON bms.work_order_labor_tracking(tracking_status);

-- work_order_labor_costs 인덱스
CREATE INDEX IF NOT EXISTS idx_labor_costs_company_id ON bms.work_order_labor_costs(company_id);
CREATE INDEX IF NOT EXISTS idx_labor_costs_work_order ON bms.work_order_labor_costs(work_order_id);
CREATE INDEX IF NOT EXISTS idx_labor_costs_date ON bms.work_order_labor_costs(cost_date);
CREATE INDEX IF NOT EXISTS idx_labor_costs_period ON bms.work_order_labor_costs(cost_period);
CREATE INDEX IF NOT EXISTS idx_labor_costs_status ON bms.work_order_labor_costs(calculation_status);

-- worker_performance_evaluation 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_company_id ON bms.worker_performance_evaluation(company_id);
CREATE INDEX IF NOT EXISTS idx_performance_work_order ON bms.worker_performance_evaluation(work_order_id);
CREATE INDEX IF NOT EXISTS idx_performance_worker ON bms.worker_performance_evaluation(worker_id);
CREATE INDEX IF NOT EXISTS idx_performance_date ON bms.worker_performance_evaluation(evaluation_date);
CREATE INDEX IF NOT EXISTS idx_performance_grade ON bms.worker_performance_evaluation(performance_grade);
CREATE INDEX IF NOT EXISTS idx_performance_status ON bms.worker_performance_evaluation(evaluation_status);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_labor_tracking_worker_date ON bms.work_order_labor_tracking(worker_id, work_date);
CREATE INDEX IF NOT EXISTS idx_labor_costs_work_order_period ON bms.work_order_labor_costs(work_order_id, cost_period);
CREATE INDEX IF NOT EXISTS idx_performance_worker_period ON bms.worker_performance_evaluation(worker_id, evaluation_period);

-- 6. 업데이트 트리거 설정
CREATE TRIGGER work_order_labor_tracking_updated_at_trigger
    BEFORE UPDATE ON bms.work_order_labor_tracking
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER work_order_labor_costs_updated_at_trigger
    BEFORE UPDATE ON bms.work_order_labor_costs
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER worker_performance_evaluation_updated_at_trigger
    BEFORE UPDATE ON bms.worker_performance_evaluation
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 7. 테이블 코멘트
COMMENT ON TABLE bms.work_order_labor_tracking IS '작업 지시서 인력 시간 추적 - 작업자별 시간 및 비용 상세 추적';
COMMENT ON TABLE bms.work_order_labor_costs IS '작업 지시서 인력 비용 집계 - 인력 비용의 집계 및 분석';
COMMENT ON TABLE bms.worker_performance_evaluation IS '작업자 성과 평가 - 작업자별 성과 지표 및 평가 관리';

-- 스크립트 완료 메시지
SELECT '작업 인력 투입 시간 및 비용 추적 기능이 성공적으로 생성되었습니다.' as message;