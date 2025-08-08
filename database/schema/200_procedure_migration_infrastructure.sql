-- =====================================================
-- 프로시저 이관 인프라 스키마 (PostgreSQL 호환)
-- 작성일: 2025-01-04
-- 설명: 데이터베이스 프로시저를 백엔드 서비스로 이관하기 위한 추적 및 관리 테이블
-- =====================================================

-- 1. 프로시저 이관 추적 테이블
-- 각 프로시저의 이관 상태와 진행 상황을 추적
CREATE TABLE IF NOT EXISTS bms.procedure_migration_log (
    id BIGSERIAL PRIMARY KEY,
    procedure_name VARCHAR(255) NOT NULL,
    service_class VARCHAR(255) NOT NULL,
    service_method VARCHAR(255) NOT NULL,
    migration_status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    migration_phase INTEGER NOT NULL DEFAULT 1,
    priority_level VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    migration_date TIMESTAMP,
    test_passed BOOLEAN DEFAULT FALSE,
    performance_comparison JSONB,
    rollback_reason TEXT,
    created_by VARCHAR(100) NOT NULL DEFAULT 'system',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by VARCHAR(100),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_procedure_migration_log_name UNIQUE (procedure_name),
    CONSTRAINT ck_migration_status CHECK (migration_status IN ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'FAILED', 'ROLLBACK')),
    CONSTRAINT ck_priority_level CHECK (priority_level IN ('HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT ck_migration_phase CHECK (migration_phase BETWEEN 1 AND 4)
);

-- 프로시저 이관 추적 테이블 컬럼 코멘트
COMMENT ON COLUMN bms.procedure_migration_log.procedure_name IS '이관할 프로시저명';
COMMENT ON COLUMN bms.procedure_migration_log.service_class IS '대상 백엔드 서비스 클래스명';
COMMENT ON COLUMN bms.procedure_migration_log.service_method IS '대상 백엔드 서비스 메서드명';
COMMENT ON COLUMN bms.procedure_migration_log.migration_status IS '이관 상태 (PENDING, IN_PROGRESS, COMPLETED, FAILED, ROLLBACK)';
COMMENT ON COLUMN bms.procedure_migration_log.migration_phase IS '이관 단계 (1: 테스트/유틸리티, 2: 핵심데이터, 3: 비즈니스도메인, 4: 보안/분석)';
COMMENT ON COLUMN bms.procedure_migration_log.priority_level IS '우선순위 (HIGH, MEDIUM, LOW)';
COMMENT ON COLUMN bms.procedure_migration_log.migration_date IS '이관 완료 일시';
COMMENT ON COLUMN bms.procedure_migration_log.test_passed IS '테스트 통과 여부';
COMMENT ON COLUMN bms.procedure_migration_log.performance_comparison IS '성능 비교 결과 (JSON 형태)';
COMMENT ON COLUMN bms.procedure_migration_log.rollback_reason IS '롤백 사유';
COMMENT ON COLUMN bms.procedure_migration_log.created_by IS '생성자';
COMMENT ON COLUMN bms.procedure_migration_log.created_at IS '생성일시';
COMMENT ON COLUMN bms.procedure_migration_log.updated_by IS '수정자';
COMMENT ON COLUMN bms.procedure_migration_log.updated_at IS '수정일시';

-- 프로시저 이관 추적 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_procedure_migration_log_status ON bms.procedure_migration_log(migration_status);
CREATE INDEX IF NOT EXISTS idx_procedure_migration_log_phase ON bms.procedure_migration_log(migration_phase);
CREATE INDEX IF NOT EXISTS idx_procedure_migration_log_priority ON bms.procedure_migration_log(priority_level);
CREATE INDEX IF NOT EXISTS idx_procedure_migration_log_created_at ON bms.procedure_migration_log(created_at);

-- 2. 프로시저 의존성 테이블
-- 프로시저 간의 의존 관계를 추적하여 안전한 이관 순서 결정
CREATE TABLE IF NOT EXISTS bms.procedure_dependencies (
    id BIGSERIAL PRIMARY KEY,
    procedure_name VARCHAR(255) NOT NULL,
    depends_on VARCHAR(255) NOT NULL,
    dependency_type VARCHAR(50) NOT NULL,
    dependency_level INTEGER NOT NULL DEFAULT 1,
    is_critical BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_procedure_dependencies UNIQUE (procedure_name, depends_on),
    CONSTRAINT ck_dependency_type CHECK (dependency_type IN ('CALLS', 'REFERENCES', 'TRIGGERS', 'DATA_DEPENDENCY'))
);

-- 프로시저 의존성 테이블 컬럼 코멘트
COMMENT ON COLUMN bms.procedure_dependencies.procedure_name IS '프로시저명';
COMMENT ON COLUMN bms.procedure_dependencies.depends_on IS '의존하는 프로시저명';
COMMENT ON COLUMN bms.procedure_dependencies.dependency_type IS '의존성 유형 (CALLS, REFERENCES, TRIGGERS, DATA_DEPENDENCY)';
COMMENT ON COLUMN bms.procedure_dependencies.dependency_level IS '의존성 깊이 (1: 직접의존, 2이상: 간접의존)';
COMMENT ON COLUMN bms.procedure_dependencies.is_critical IS '중요 의존성 여부';
COMMENT ON COLUMN bms.procedure_dependencies.description IS '의존성 설명';
COMMENT ON COLUMN bms.procedure_dependencies.created_at IS '생성일시';
COMMENT ON COLUMN bms.procedure_dependencies.updated_at IS '수정일시';

-- 프로시저 의존성 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_procedure_dependencies_name ON bms.procedure_dependencies(procedure_name);
CREATE INDEX IF NOT EXISTS idx_procedure_dependencies_depends_on ON bms.procedure_dependencies(depends_on);
CREATE INDEX IF NOT EXISTS idx_procedure_dependencies_type ON bms.procedure_dependencies(dependency_type);
CREATE INDEX IF NOT EXISTS idx_procedure_dependencies_critical ON bms.procedure_dependencies(is_critical);

-- 3. 성능 테스트 결과 테이블
-- 프로시저와 백엔드 서비스의 성능 비교 결과 저장
CREATE TABLE IF NOT EXISTS bms.performance_test_results (
    id BIGSERIAL PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    procedure_name VARCHAR(255) NOT NULL,
    service_class VARCHAR(255),
    service_method VARCHAR(255),
    test_type VARCHAR(50) NOT NULL DEFAULT 'PERFORMANCE',
    procedure_execution_time_ms BIGINT,
    service_execution_time_ms BIGINT,
    memory_usage_procedure_mb DECIMAL(10,2),
    memory_usage_service_mb DECIMAL(10,2),
    cpu_usage_procedure_percent DECIMAL(5,2),
    cpu_usage_service_percent DECIMAL(5,2),
    test_data_size INTEGER NOT NULL DEFAULT 0,
    iterations INTEGER NOT NULL DEFAULT 1,
    success_rate_procedure DECIMAL(5,2) DEFAULT 100.00,
    success_rate_service DECIMAL(5,2) DEFAULT 100.00,
    performance_ratio DECIMAL(10,4),
    test_environment VARCHAR(100),
    test_result VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    error_details TEXT,
    test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT ck_test_type CHECK (test_type IN ('PERFORMANCE', 'FUNCTIONAL', 'LOAD', 'STRESS')),
    CONSTRAINT ck_test_result CHECK (test_result IN ('PASS', 'FAIL', 'PENDING')),
    CONSTRAINT ck_success_rate_procedure CHECK (success_rate_procedure BETWEEN 0 AND 100),
    CONSTRAINT ck_success_rate_service CHECK (success_rate_service BETWEEN 0 AND 100)
);

-- 성능 테스트 결과 테이블 컬럼 코멘트
COMMENT ON COLUMN bms.performance_test_results.test_name IS '테스트명';
COMMENT ON COLUMN bms.performance_test_results.procedure_name IS '테스트한 프로시저명';
COMMENT ON COLUMN bms.performance_test_results.service_class IS '비교한 서비스 클래스명';
COMMENT ON COLUMN bms.performance_test_results.service_method IS '비교한 서비스 메서드명';
COMMENT ON COLUMN bms.performance_test_results.test_type IS '테스트 유형 (PERFORMANCE, FUNCTIONAL, LOAD, STRESS)';
COMMENT ON COLUMN bms.performance_test_results.procedure_execution_time_ms IS '프로시저 실행 시간 (밀리초)';
COMMENT ON COLUMN bms.performance_test_results.service_execution_time_ms IS '서비스 실행 시간 (밀리초)';
COMMENT ON COLUMN bms.performance_test_results.memory_usage_procedure_mb IS '프로시저 메모리 사용량 (MB)';
COMMENT ON COLUMN bms.performance_test_results.memory_usage_service_mb IS '서비스 메모리 사용량 (MB)';
COMMENT ON COLUMN bms.performance_test_results.cpu_usage_procedure_percent IS '프로시저 CPU 사용률 (%)';
COMMENT ON COLUMN bms.performance_test_results.cpu_usage_service_percent IS '서비스 CPU 사용률 (%)';
COMMENT ON COLUMN bms.performance_test_results.test_data_size IS '테스트 데이터 크기';
COMMENT ON COLUMN bms.performance_test_results.iterations IS '테스트 반복 횟수';
COMMENT ON COLUMN bms.performance_test_results.success_rate_procedure IS '프로시저 성공률 (%)';
COMMENT ON COLUMN bms.performance_test_results.success_rate_service IS '서비스 성공률 (%)';
COMMENT ON COLUMN bms.performance_test_results.performance_ratio IS '성능 비율 (서비스시간/프로시저시간)';
COMMENT ON COLUMN bms.performance_test_results.test_environment IS '테스트 환경 (DEV, TEST, STAGING)';
COMMENT ON COLUMN bms.performance_test_results.test_result IS '테스트 결과 (PASS, FAIL, PENDING)';
COMMENT ON COLUMN bms.performance_test_results.error_details IS '오류 상세 내용';
COMMENT ON COLUMN bms.performance_test_results.test_date IS '테스트 실행 일시';
COMMENT ON COLUMN bms.performance_test_results.created_at IS '생성일시';

-- 성능 테스트 결과 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_test_results_procedure ON bms.performance_test_results(procedure_name);
CREATE INDEX IF NOT EXISTS idx_performance_test_results_service ON bms.performance_test_results(service_class, service_method);
CREATE INDEX IF NOT EXISTS idx_performance_test_results_type ON bms.performance_test_results(test_type);
CREATE INDEX IF NOT EXISTS idx_performance_test_results_result ON bms.performance_test_results(test_result);
CREATE INDEX IF NOT EXISTS idx_performance_test_results_date ON bms.performance_test_results(test_date);

-- 4. 이관 작업 로그 테이블
-- 이관 과정에서 발생하는 모든 작업을 상세히 기록
CREATE TABLE IF NOT EXISTS bms.migration_work_log (
    id BIGSERIAL PRIMARY KEY,
    procedure_name VARCHAR(255) NOT NULL,
    work_type VARCHAR(50) NOT NULL,
    work_status VARCHAR(20) NOT NULL DEFAULT 'STARTED',
    work_description TEXT NOT NULL,
    work_result TEXT,
    error_message TEXT,
    stack_trace TEXT,
    execution_time_ms BIGINT,
    worker_id VARCHAR(100) NOT NULL,
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT ck_work_type CHECK (work_type IN ('ANALYSIS', 'IMPLEMENTATION', 'TEST', 'DEPLOY', 'ROLLBACK')),
    CONSTRAINT ck_work_status CHECK (work_status IN ('STARTED', 'IN_PROGRESS', 'COMPLETED', 'FAILED'))
);

-- 이관 작업 로그 테이블 컬럼 코멘트
COMMENT ON COLUMN bms.migration_work_log.procedure_name IS '작업 대상 프로시저명';
COMMENT ON COLUMN bms.migration_work_log.work_type IS '작업 유형 (ANALYSIS, IMPLEMENTATION, TEST, DEPLOY, ROLLBACK)';
COMMENT ON COLUMN bms.migration_work_log.work_status IS '작업 상태 (STARTED, IN_PROGRESS, COMPLETED, FAILED)';
COMMENT ON COLUMN bms.migration_work_log.work_description IS '작업 설명';
COMMENT ON COLUMN bms.migration_work_log.work_result IS '작업 결과';
COMMENT ON COLUMN bms.migration_work_log.error_message IS '오류 메시지';
COMMENT ON COLUMN bms.migration_work_log.stack_trace IS '스택 트레이스';
COMMENT ON COLUMN bms.migration_work_log.execution_time_ms IS '작업 실행 시간 (밀리초)';
COMMENT ON COLUMN bms.migration_work_log.worker_id IS '작업자 ID';
COMMENT ON COLUMN bms.migration_work_log.started_at IS '작업 시작 시간';
COMMENT ON COLUMN bms.migration_work_log.completed_at IS '작업 완료 시간';
COMMENT ON COLUMN bms.migration_work_log.created_at IS '생성일시';

-- 이관 작업 로그 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_migration_work_log_procedure ON bms.migration_work_log(procedure_name);
CREATE INDEX IF NOT EXISTS idx_migration_work_log_type ON bms.migration_work_log(work_type);
CREATE INDEX IF NOT EXISTS idx_migration_work_log_status ON bms.migration_work_log(work_status);
CREATE INDEX IF NOT EXISTS idx_migration_work_log_worker ON bms.migration_work_log(worker_id);
CREATE INDEX IF NOT EXISTS idx_migration_work_log_started_at ON bms.migration_work_log(started_at);

-- 5. 프로시저 메타데이터 테이블
-- 이관할 프로시저들의 메타 정보 저장
CREATE TABLE IF NOT EXISTS bms.procedure_metadata (
    id BIGSERIAL PRIMARY KEY,
    procedure_name VARCHAR(255) NOT NULL,
    schema_name VARCHAR(100) NOT NULL DEFAULT 'bms',
    procedure_type VARCHAR(50) NOT NULL,
    return_type VARCHAR(100),
    parameter_count INTEGER DEFAULT 0,
    parameters_info JSONB,
    business_domain VARCHAR(100),
    complexity_level VARCHAR(20) DEFAULT 'MEDIUM',
    estimated_effort_hours INTEGER,
    source_code TEXT,
    documentation TEXT,
    last_modified TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_procedure_metadata_name UNIQUE (procedure_name, schema_name),
    CONSTRAINT ck_procedure_type CHECK (procedure_type IN ('FUNCTION', 'PROCEDURE', 'TRIGGER')),
    CONSTRAINT ck_complexity_level CHECK (complexity_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL'))
);

-- 프로시저 메타데이터 테이블 컬럼 코멘트
COMMENT ON COLUMN bms.procedure_metadata.procedure_name IS '프로시저명';
COMMENT ON COLUMN bms.procedure_metadata.schema_name IS '스키마명';
COMMENT ON COLUMN bms.procedure_metadata.procedure_type IS '프로시저 유형 (FUNCTION, PROCEDURE, TRIGGER)';
COMMENT ON COLUMN bms.procedure_metadata.return_type IS '반환 타입';
COMMENT ON COLUMN bms.procedure_metadata.parameter_count IS '매개변수 개수';
COMMENT ON COLUMN bms.procedure_metadata.parameters_info IS '매개변수 정보 (JSON 형태)';
COMMENT ON COLUMN bms.procedure_metadata.business_domain IS '비즈니스 도메인 (FACILITY, BILLING, LEASE, INVENTORY 등)';
COMMENT ON COLUMN bms.procedure_metadata.complexity_level IS '복잡도 (LOW, MEDIUM, HIGH, CRITICAL)';
COMMENT ON COLUMN bms.procedure_metadata.estimated_effort_hours IS '예상 작업 시간 (시간)';
COMMENT ON COLUMN bms.procedure_metadata.source_code IS '프로시저 소스 코드';
COMMENT ON COLUMN bms.procedure_metadata.documentation IS '프로시저 문서화';
COMMENT ON COLUMN bms.procedure_metadata.last_modified IS '마지막 수정 일시';
COMMENT ON COLUMN bms.procedure_metadata.is_active IS '활성 상태';
COMMENT ON COLUMN bms.procedure_metadata.created_at IS '생성일시';
COMMENT ON COLUMN bms.procedure_metadata.updated_at IS '수정일시';

-- 프로시저 메타데이터 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_procedure_metadata_name ON bms.procedure_metadata(procedure_name);
CREATE INDEX IF NOT EXISTS idx_procedure_metadata_domain ON bms.procedure_metadata(business_domain);
CREATE INDEX IF NOT EXISTS idx_procedure_metadata_complexity ON bms.procedure_metadata(complexity_level);
CREATE INDEX IF NOT EXISTS idx_procedure_metadata_active ON bms.procedure_metadata(is_active);

-- 6. 트리거 생성 (자동 업데이트 시간 관리)
CREATE OR REPLACE FUNCTION bms.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 각 테이블에 updated_at 자동 업데이트 트리거 적용
CREATE TRIGGER trigger_procedure_migration_log_updated_at
    BEFORE UPDATE ON bms.procedure_migration_log
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER trigger_procedure_dependencies_updated_at
    BEFORE UPDATE ON bms.procedure_dependencies
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER trigger_procedure_metadata_updated_at
    BEFORE UPDATE ON bms.procedure_metadata
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 7. 초기 데이터 삽입 (프로시저 목록)
-- 이관할 프로시저들의 기본 정보를 삽입
INSERT INTO bms.procedure_migration_log (procedure_name, service_class, service_method, migration_phase, priority_level) VALUES
-- Phase 1: 테스트 및 유틸리티 (우선순위: 높음)
('generate_test_companies', 'TestExecutionService', 'generateTestCompanies', 1, 'HIGH'),
('generate_performance_test_data', 'PerformanceMonitoringService', 'generatePerformanceTestData', 1, 'HIGH'),
('generate_account_number', 'NumberGenerationService', 'generateAccountNumber', 1, 'HIGH'),
('generate_notice_number', 'NumberGenerationService', 'generateNoticeNumber', 1, 'HIGH'),
('generate_reservation_number', 'NumberGenerationService', 'generateReservationNumber', 1, 'HIGH'),

-- Phase 2: 핵심 데이터 서비스 (우선순위: 높음)
('validate_business_registration_number', 'DataIntegrityService', 'validateBusinessRegistrationNumber', 2, 'HIGH'),
('validate_building_data', 'DataIntegrityService', 'validateBuildingData', 2, 'HIGH'),
('get_code_name', 'DataIntegrityService', 'getCodeName', 2, 'HIGH'),
('log_user_activity', 'AuditService', 'logUserActivity', 2, 'HIGH'),
('create_default_common_codes', 'SystemInitializationService', 'createDefaultCommonCodes', 2, 'HIGH'),

-- Phase 3: 비즈니스 도메인 서비스 (우선순위: 중간)
('create_work_order', 'FacilityService', 'createWorkOrder', 3, 'MEDIUM'),
('calculate_monthly_fee', 'BillingService', 'calculateMonthlyFee', 3, 'MEDIUM'),
('create_lease_contract', 'LeaseService', 'createLeaseContract', 3, 'MEDIUM'),
('update_inventory_stock', 'InventoryService', 'updateInventoryStock', 3, 'MEDIUM'),

-- Phase 4: 보안 및 분석 서비스 (우선순위: 낮음)
('check_security_access', 'SecurityService', 'checkSecurityAccess', 4, 'LOW'),
('generate_safety_report', 'SafetyComplianceService', 'generateSafetyReport', 4, 'LOW'),
('generate_performance_analytics', 'AnalyticsService', 'generatePerformanceAnalytics', 4, 'LOW')
ON CONFLICT (procedure_name) DO NOTHING;

-- 8. 뷰 생성 (이관 현황 조회용)
CREATE OR REPLACE VIEW bms.v_migration_status_summary AS
SELECT 
    migration_phase,
    priority_level,
    migration_status,
    COUNT(*) as procedure_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM bms.procedure_migration_log
GROUP BY migration_phase, priority_level, migration_status
ORDER BY migration_phase, priority_level, migration_status;

-- 이관 진행률 뷰
CREATE OR REPLACE VIEW bms.v_migration_progress AS
SELECT 
    migration_phase,
    CASE migration_phase
        WHEN 1 THEN '테스트/유틸리티'
        WHEN 2 THEN '핵심데이터'
        WHEN 3 THEN '비즈니스도메인'
        WHEN 4 THEN '보안/분석'
    END as phase_name,
    COUNT(*) as total_procedures,
    COUNT(CASE WHEN migration_status = 'COMPLETED' THEN 1 END) as completed_procedures,
    COUNT(CASE WHEN migration_status = 'IN_PROGRESS' THEN 1 END) as in_progress_procedures,
    COUNT(CASE WHEN migration_status = 'FAILED' THEN 1 END) as failed_procedures,
    ROUND(
        COUNT(CASE WHEN migration_status = 'COMPLETED' THEN 1 END) * 100.0 / COUNT(*), 2
    ) as completion_percentage
FROM bms.procedure_migration_log
GROUP BY migration_phase
ORDER BY migration_phase;

-- 성능 비교 요약 뷰
CREATE OR REPLACE VIEW bms.v_performance_comparison_summary AS
SELECT 
    ptr.procedure_name,
    pml.service_class,
    pml.service_method,
    AVG(ptr.procedure_execution_time_ms) as avg_procedure_time_ms,
    AVG(ptr.service_execution_time_ms) as avg_service_time_ms,
    AVG(ptr.performance_ratio) as avg_performance_ratio,
    COUNT(ptr.id) as test_count,
    MAX(ptr.test_date) as last_test_date
FROM bms.performance_test_results ptr
JOIN bms.procedure_migration_log pml ON ptr.procedure_name = pml.procedure_name
WHERE ptr.test_result = 'PASS'
GROUP BY ptr.procedure_name, pml.service_class, pml.service_method
ORDER BY avg_performance_ratio DESC;

-- 권한 설정
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA bms TO qiro;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA bms TO qiro;

-- 테이블 코멘트 추가
COMMENT ON TABLE bms.procedure_migration_log IS '프로시저 이관 추적 테이블 - 각 프로시저의 이관 상태와 진행 상황을 관리';
COMMENT ON TABLE bms.procedure_dependencies IS '프로시저 의존성 테이블 - 프로시저 간의 의존 관계를 추적하여 안전한 이관 순서 결정';
COMMENT ON TABLE bms.performance_test_results IS '성능 테스트 결과 테이블 - 프로시저와 백엔드 서비스의 성능 비교 결과 저장';
COMMENT ON TABLE bms.migration_work_log IS '이관 작업 로그 테이블 - 이관 과정에서 발생하는 모든 작업을 상세히 기록';
COMMENT ON TABLE bms.procedure_metadata IS '프로시저 메타데이터 테이블 - 이관할 프로시저들의 메타 정보 저장';

COMMENT ON VIEW bms.v_migration_status_summary IS '이관 현황 요약 뷰 - 단계별, 우선순위별, 상태별 프로시저 개수와 비율';
COMMENT ON VIEW bms.v_migration_progress IS '이관 진행률 뷰 - 각 단계별 이관 진행 상황과 완료율';
COMMENT ON VIEW bms.v_performance_comparison_summary IS '성능 비교 요약 뷰 - 프로시저와 서비스의 평균 성능 비교 결과';