-- =====================================================
-- 데이터 검증 및 비즈니스 규칙 시스템 테스트 데이터
-- =====================================================

-- 테스트용 비즈니스 규칙 데이터
INSERT INTO bms.business_rules (
    rule_name, rule_code, description, rule_type, entity_type, 
    condition, action, priority, is_active, company_id, created_by
) VALUES 
-- 시설물 관련 규칙
(
    '시설물 정기점검 알림',
    'FACILITY_MAINTENANCE_DUE',
    '시설물 정기점검 일정이 도래했을 때 알림을 발송합니다',
    'NOTIFICATION',
    'FACILITY',
    'CUSTOM_MAINTENANCE_DUE',
    'SEND_NOTIFICATION:maintenance_due:정기점검이 필요합니다',
    100,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    '자산 번호 형식 검증',
    'FACILITY_ASSET_NUMBER_FORMAT',
    '시설물 자산 번호가 올바른 형식인지 검증합니다',
    'VALIDATION',
    'FACILITY',
    'FIELD_NOT_NULL:asset_number',
    'VALIDATE_FORMAT:asset_number:^[A-Z]{2,3}-\\d{4,6}-\\d{2}$',
    50,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    '시설물 위치 필수 입력',
    'FACILITY_LOCATION_REQUIRED',
    '시설물 위치는 필수 입력 항목입니다',
    'VALIDATION',
    'FACILITY',
    'FIELD_EMPTY:location',
    'VALIDATE_REQUIRED:location',
    10,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),

-- 작업지시서 관련 규칙
(
    '긴급 작업지시서 승인 필요',
    'URGENT_WORKORDER_APPROVAL',
    '긴급 작업지시서는 관리자 승인이 필요합니다',
    'APPROVAL',
    'WORK_ORDER',
    'FIELD_EQUALS:priority:URGENT',
    'SET_STATUS:PENDING_APPROVAL',
    20,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    '작업 시간 유효성 검증',
    'WORKORDER_TIME_VALIDATION',
    '작업 시작일이 종료일보다 늦을 수 없습니다',
    'VALIDATION',
    'WORK_ORDER',
    'DATE_AFTER:start_date:end_date',
    'VALIDATE_RANGE:start_date,end_date',
    30,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    '작업지시서 제목 길이 제한',
    'WORKORDER_TITLE_LENGTH',
    '작업지시서 제목은 100자를 초과할 수 없습니다',
    'VALIDATION',
    'WORK_ORDER',
    'FIELD_NOT_EMPTY:title',
    'VALIDATE_FORMAT:title:length<=100',
    40,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),

-- 예산 관리 관련 규칙
(
    '예산 초과 경고',
    'BUDGET_EXCEEDED_WARNING',
    '예산 사용량이 80%를 초과하면 경고를 발송합니다',
    'NOTIFICATION',
    'BUDGET_MANAGEMENT',
    'CUSTOM_BUDGET_LIMIT',
    'SEND_NOTIFICATION:budget_warning:예산 사용량이 80%를 초과했습니다',
    60,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    '예산 할당 금액 검증',
    'BUDGET_ALLOCATION_VALIDATION',
    '예산 할당 금액은 0보다 커야 합니다',
    'VALIDATION',
    'BUDGET_MANAGEMENT',
    'RANGE_GREATER_THAN:allocated_amount:0',
    'VALIDATE_RANGE:allocated_amount:min=0',
    70,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),

-- 사용자 관련 규칙
(
    '사용자 이메일 중복 검증',
    'USER_EMAIL_UNIQUE',
    '사용자 이메일은 중복될 수 없습니다',
    'VALIDATION',
    'USER',
    'FIELD_NOT_EMPTY:email',
    'VALIDATE_UNIQUE:email',
    80,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    '사용자 전화번호 형식 검증',
    'USER_PHONE_FORMAT',
    '사용자 전화번호는 올바른 한국 전화번호 형식이어야 합니다',
    'VALIDATION',
    'USER',
    'FIELD_NOT_NULL:phone',
    'VALIDATE_FORMAT:phone:korean_phone',
    90,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),

-- 워크플로우 관련 규칙
(
    '작업 완료 시 알림 발송',
    'WORKORDER_COMPLETION_NOTIFICATION',
    '작업이 완료되면 관련자들에게 알림을 발송합니다',
    'WORKFLOW',
    'WORK_ORDER',
    'STATUS_EQUALS:status:COMPLETED',
    'SEND_NOTIFICATION:work_completed:작업이 완료되었습니다',
    110,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    '정비 계획 자동 생성',
    'AUTO_MAINTENANCE_PLAN_CREATION',
    '시설물 등록 시 기본 정비 계획을 자동으로 생성합니다',
    'AUTOMATION',
    'FACILITY',
    'FIELD_EQUALS:operation:CREATE',
    'CREATE_MAINTENANCE_PLAN:default_template',
    120,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
);

-- 테스트용 검증 설정 데이터
INSERT INTO bms.validation_configs (
    entity_type, field, validation_type, configuration, is_required, 
    error_message, warning_message, is_active, company_id, created_by
) VALUES 
-- 시설물 검증 설정
(
    'FACILITY',
    'facility_name',
    'NOT_EMPTY',
    '{}',
    true,
    '시설물명은 필수 입력 항목입니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'FACILITY',
    'facility_name',
    'MAX_LENGTH',
    '{"maxLength": 100}',
    false,
    '시설물명은 100자를 초과할 수 없습니다',
    '시설물명이 너무 깁니다',
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'FACILITY',
    'asset_number',
    'PATTERN',
    '{"pattern": "^[A-Z]{2,3}-\\\\d{4,6}-\\\\d{2}$"}',
    false,
    '자산 번호 형식이 올바르지 않습니다 (예: ABC-123456-01)',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'FACILITY',
    'location',
    'NOT_EMPTY',
    '{}',
    true,
    '위치 정보는 필수 입력 항목입니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'FACILITY',
    'location',
    'MAX_LENGTH',
    '{"maxLength": 200}',
    false,
    '위치 정보는 200자를 초과할 수 없습니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),

-- 작업지시서 검증 설정
(
    'WORK_ORDER',
    'title',
    'NOT_EMPTY',
    '{}',
    true,
    '작업지시서 제목은 필수 입력 항목입니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'WORK_ORDER',
    'title',
    'MAX_LENGTH',
    '{"maxLength": 100}',
    false,
    '작업지시서 제목은 100자를 초과할 수 없습니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'WORK_ORDER',
    'priority',
    'ENUM_VALUE',
    '{"allowedValues": ["LOW", "NORMAL", "HIGH", "URGENT", "CRITICAL"]}',
    true,
    '올바른 우선순위를 선택해주세요',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'WORK_ORDER',
    'estimated_hours',
    'NUMBER_RANGE',
    '{"min": 0.5, "max": 1000}',
    false,
    '예상 작업 시간은 0.5시간 이상 1000시간 이하여야 합니다',
    '작업 시간이 너무 길거나 짧습니다',
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),

-- 사용자 검증 설정
(
    'USER',
    'username',
    'NOT_EMPTY',
    '{}',
    true,
    '사용자명은 필수 입력 항목입니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'USER',
    'username',
    'MIN_LENGTH',
    '{"minLength": 3}',
    false,
    '사용자명은 최소 3자 이상이어야 합니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'USER',
    'username',
    'MAX_LENGTH',
    '{"maxLength": 50}',
    false,
    '사용자명은 50자를 초과할 수 없습니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'USER',
    'email',
    'EMAIL',
    '{}',
    true,
    '올바른 이메일 형식을 입력해주세요',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'USER',
    'phone',
    'PHONE',
    '{}',
    false,
    '올바른 전화번호 형식을 입력해주세요 (예: 010-1234-5678)',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),

-- 예산 관리 검증 설정
(
    'BUDGET_MANAGEMENT',
    'budget_name',
    'NOT_EMPTY',
    '{}',
    true,
    '예산명은 필수 입력 항목입니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'BUDGET_MANAGEMENT',
    'allocated_amount',
    'NUMBER_RANGE',
    '{"min": 0, "max": 999999999999}',
    true,
    '할당 금액은 0 이상이어야 합니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
),
(
    'BUDGET_MANAGEMENT',
    'used_amount',
    'NUMBER_RANGE',
    '{"min": 0, "max": 999999999999}',
    false,
    '사용 금액은 0 이상이어야 합니다',
    null,
    true,
    (SELECT company_id FROM bms.companies LIMIT 1),
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1)
);

-- 테스트용 규칙 실행 로그 데이터
INSERT INTO bms.rule_execution_logs (
    rule_id, rule_name, entity_type, entity_id, executed, success, 
    result, error_message, execution_time, executed_by, company_id
) VALUES 
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'FACILITY_ASSET_NUMBER_FORMAT' LIMIT 1),
    '자산 번호 형식 검증',
    'FACILITY',
    (SELECT facility_id FROM bms.facilities LIMIT 1),
    true,
    true,
    '{"validation_result": "passed", "asset_number": "ABC-123456-01"}',
    null,
    15,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
),
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'URGENT_WORKORDER_APPROVAL' LIMIT 1),
    '긴급 작업지시서 승인 필요',
    'WORK_ORDER',
    (SELECT work_order_id FROM bms.work_orders WHERE priority = 'URGENT' LIMIT 1),
    true,
    true,
    '{"status_changed": "PENDING_APPROVAL", "previous_status": "CREATED"}',
    null,
    8,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
),
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'BUDGET_EXCEEDED_WARNING' LIMIT 1),
    '예산 초과 경고',
    'BUDGET_MANAGEMENT',
    (SELECT budget_id FROM bms.budget_management LIMIT 1),
    true,
    false,
    null,
    '예산 사용률 계산 중 오류 발생',
    25,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
),
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'USER_EMAIL_UNIQUE' LIMIT 1),
    '사용자 이메일 중복 검증',
    'USER',
    (SELECT user_id FROM bms.users LIMIT 1),
    true,
    true,
    '{"unique_check": "passed", "email": "admin@example.com"}',
    null,
    12,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
),
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'WORKORDER_TIME_VALIDATION' LIMIT 1),
    '작업 시간 유효성 검증',
    'WORK_ORDER',
    (SELECT work_order_id FROM bms.work_orders LIMIT 1),
    true,
    true,
    '{"time_validation": "passed", "start_date": "2024-01-15", "end_date": "2024-01-20"}',
    null,
    18,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
);

-- 테스트용 데이터 무결성 검사 로그 데이터
INSERT INTO bms.data_integrity_logs (
    check_name, entity_type, total_records, valid_records, invalid_records, 
    issues, duration, checked_by, company_id
) VALUES 
(
    '시설물 데이터 무결성 검사',
    'FACILITY',
    150,
    145,
    5,
    '[
        {
            "issue_id": "' || gen_random_uuid() || '",
            "issue_type": "MISSING_REQUIRED_FIELD",
            "entity_id": "' || (SELECT facility_id FROM bms.facilities LIMIT 1) || '",
            "field": "location",
            "description": "위치 정보가 누락되었습니다",
            "severity": "ERROR"
        },
        {
            "issue_id": "' || gen_random_uuid() || '",
            "issue_type": "INVALID_FORMAT",
            "entity_id": "' || (SELECT facility_id FROM bms.facilities OFFSET 1 LIMIT 1) || '",
            "field": "asset_number",
            "description": "자산 번호 형식이 올바르지 않습니다",
            "severity": "ERROR"
        }
    ]',
    2500,
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
),
(
    '작업지시서 데이터 무결성 검사',
    'WORK_ORDER',
    75,
    72,
    3,
    '[
        {
            "issue_id": "' || gen_random_uuid() || '",
            "issue_type": "BUSINESS_RULE_VIOLATION",
            "entity_id": "' || (SELECT work_order_id FROM bms.work_orders LIMIT 1) || '",
            "field": "start_date,end_date",
            "description": "시작일이 종료일보다 늦습니다",
            "severity": "ERROR"
        }
    ]',
    1800,
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
),
(
    '사용자 데이터 무결성 검사',
    'USER',
    25,
    23,
    2,
    '[
        {
            "issue_id": "' || gen_random_uuid() || '",
            "issue_type": "DUPLICATE_VALUE",
            "entity_id": "' || (SELECT user_id FROM bms.users LIMIT 1) || '",
            "field": "email",
            "description": "중복된 이메일이 발견되었습니다",
            "severity": "ERROR"
        }
    ]',
    1200,
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
),
(
    '예산 관리 데이터 무결성 검사',
    'BUDGET_MANAGEMENT',
    12,
    11,
    1,
    '[
        {
            "issue_id": "' || gen_random_uuid() || '",
            "issue_type": "BUSINESS_RULE_VIOLATION",
            "entity_id": "' || (SELECT budget_id FROM bms.budget_management LIMIT 1) || '",
            "field": "used_amount",
            "description": "사용 금액이 할당 금액을 초과했습니다",
            "severity": "WARNING"
        }
    ]',
    800,
    (SELECT user_id FROM bms.users WHERE role_id = (SELECT role_id FROM bms.roles WHERE role_name = 'ADMIN') LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1)
);

-- 추가 테스트 데이터 (다양한 시나리오)
INSERT INTO bms.rule_execution_logs (
    rule_id, rule_name, entity_type, entity_id, executed, success, 
    result, error_message, execution_time, executed_by, company_id, executed_at
) VALUES 
-- 성공적인 실행들
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'FACILITY_LOCATION_REQUIRED' LIMIT 1),
    '시설물 위치 필수 입력',
    'FACILITY',
    (SELECT facility_id FROM bms.facilities LIMIT 1),
    true,
    true,
    '{"validation_result": "passed"}',
    null,
    5,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1),
    CURRENT_TIMESTAMP - INTERVAL '1 hour'
),
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'WORKORDER_TITLE_LENGTH' LIMIT 1),
    '작업지시서 제목 길이 제한',
    'WORK_ORDER',
    (SELECT work_order_id FROM bms.work_orders LIMIT 1),
    true,
    true,
    '{"validation_result": "passed", "title_length": 45}',
    null,
    7,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1),
    CURRENT_TIMESTAMP - INTERVAL '2 hours'
),
-- 실패한 실행들
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'BUDGET_ALLOCATION_VALIDATION' LIMIT 1),
    '예산 할당 금액 검증',
    'BUDGET_MANAGEMENT',
    (SELECT budget_id FROM bms.budget_management LIMIT 1),
    true,
    false,
    null,
    '할당 금액이 0보다 작습니다',
    10,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1),
    CURRENT_TIMESTAMP - INTERVAL '3 hours'
),
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'USER_PHONE_FORMAT' LIMIT 1),
    '사용자 전화번호 형식 검증',
    'USER',
    (SELECT user_id FROM bms.users LIMIT 1),
    true,
    false,
    null,
    '전화번호 형식이 올바르지 않습니다',
    6,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1),
    CURRENT_TIMESTAMP - INTERVAL '4 hours'
),
-- 조건 불만족으로 실행되지 않은 경우들
(
    (SELECT rule_id FROM bms.business_rules WHERE rule_code = 'WORKORDER_COMPLETION_NOTIFICATION' LIMIT 1),
    '작업 완료 시 알림 발송',
    'WORK_ORDER',
    (SELECT work_order_id FROM bms.work_orders WHERE status != 'COMPLETED' LIMIT 1),
    false,
    true,
    '{"condition_result": "not_met", "current_status": "IN_PROGRESS"}',
    null,
    3,
    (SELECT user_id FROM bms.users LIMIT 1),
    (SELECT company_id FROM bms.companies LIMIT 1),
    CURRENT_TIMESTAMP - INTERVAL '5 hours'
);

-- 성능 테스트를 위한 대량 로그 데이터 (선택적)
-- INSERT INTO bms.rule_execution_logs (
--     rule_id, rule_name, entity_type, entity_id, executed, success, 
--     result, execution_time, executed_by, company_id, executed_at
-- )
-- SELECT 
--     (SELECT rule_id FROM bms.business_rules ORDER BY RANDOM() LIMIT 1),
--     'Performance Test Rule',
--     'FACILITY',
--     (SELECT facility_id FROM bms.facilities ORDER BY RANDOM() LIMIT 1),
--     true,
--     CASE WHEN RANDOM() > 0.1 THEN true ELSE false END,
--     '{"test": "performance"}',
--     (RANDOM() * 100)::INTEGER,
--     (SELECT user_id FROM bms.users LIMIT 1),
--     (SELECT company_id FROM bms.companies LIMIT 1),
--     CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '30 days')
-- FROM generate_series(1, 1000);

-- 검증 시스템 상태 확인을 위한 뷰 생성
CREATE OR REPLACE VIEW bms.validation_system_status AS
SELECT 
    'business_rules' as component,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE is_active = true) as active_count,
    COUNT(*) FILTER (WHERE is_active = false) as inactive_count
FROM bms.business_rules
UNION ALL
SELECT 
    'validation_configs' as component,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE is_active = true) as active_count,
    COUNT(*) FILTER (WHERE is_active = false) as inactive_count
FROM bms.validation_configs
UNION ALL
SELECT 
    'rule_executions_today' as component,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE success = true) as active_count,
    COUNT(*) FILTER (WHERE success = false) as inactive_count
FROM bms.rule_execution_logs
WHERE executed_at >= CURRENT_DATE
UNION ALL
SELECT 
    'integrity_checks_today' as component,
    COUNT(*) as total_count,
    SUM(valid_records)::INTEGER as active_count,
    SUM(invalid_records)::INTEGER as inactive_count
FROM bms.data_integrity_logs
WHERE checked_at >= CURRENT_DATE;

-- 검증 시스템 통계를 위한 뷰 생성
CREATE OR REPLACE VIEW bms.validation_statistics AS
SELECT 
    br.rule_type,
    br.entity_type,
    COUNT(br.rule_id) as rule_count,
    COUNT(rel.log_id) as execution_count,
    COUNT(rel.log_id) FILTER (WHERE rel.success = true) as success_count,
    COUNT(rel.log_id) FILTER (WHERE rel.success = false) as failure_count,
    ROUND(AVG(rel.execution_time), 2) as avg_execution_time
FROM bms.business_rules br
LEFT JOIN bms.rule_execution_logs rel ON br.rule_id = rel.rule_id
WHERE br.is_active = true
GROUP BY br.rule_type, br.entity_type
ORDER BY br.rule_type, br.entity_type;