-- =====================================================
-- Repair Work Management Test Data
-- Phase 4.3.2: Test Data for Repair Work Management
-- =====================================================

-- Use existing company
SET app.current_company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f';

-- 1. Insert work order templates
INSERT INTO bms.work_order_templates (
    company_id, template_code, template_name, template_description,
    work_category, work_type, default_priority, estimated_duration_hours,
    required_skill_level, requires_specialist, requires_contractor,
    work_instructions, safety_precautions, is_active
) VALUES 
-- Electrical templates
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ELEC_OUTLET_REPAIR', '콘센트 수리', '콘센트 고장 및 교체 작업', 'CORRECTIVE', 'ELECTRICAL', 'MEDIUM', 2.0, 'INTERMEDIATE', false, false, 
'1. 전원 차단 확인\n2. 기존 콘센트 제거\n3. 배선 점검\n4. 새 콘센트 설치\n5. 동작 테스트', 
'전기 작업 시 반드시 전원을 차단하고 절연장갑 착용', true),

('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ELEC_LIGHTING_MAINT', '조명 유지보수', '조명 교체 및 점검 작업', 'PREVENTIVE', 'LIGHTING', 'LOW', 1.5, 'BASIC', false, false,
'1. 조명 상태 점검\n2. 전구/LED 교체\n3. 안정기 점검\n4. 조도 측정\n5. 청소 및 정리',
'사다리 사용 시 안전 확인, 전기 안전 수칙 준수', true),

-- Plumbing templates
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'PLUMB_LEAK_REPAIR', '누수 수리', '파이프 누수 및 배관 수리', 'EMERGENCY', 'PLUMBING', 'HIGH', 3.0, 'INTERMEDIATE', false, false,
'1. 누수 위치 확인\n2. 급수 차단\n3. 손상 부위 교체\n4. 배관 연결\n5. 누수 테스트',
'급수 차단 확인, 작업 공간 안전 확보', true),

('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'PLUMB_DRAIN_CLEAN', '배수관 청소', '배수관 막힘 제거 및 청소', 'CORRECTIVE', 'PLUMBING', 'MEDIUM', 2.5, 'BASIC', false, false,
'1. 막힘 위치 확인\n2. 청소 도구 준비\n3. 막힌 부분 제거\n4. 배수 테스트\n5. 예방 조치',
'화학 세정제 사용 시 환기 필수, 보호장비 착용', true),

-- HVAC templates
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'HVAC_FILTER_CHANGE', '에어컨 필터 교체', '에어컨 필터 정기 교체', 'PREVENTIVE', 'HVAC', 'LOW', 0.5, 'BASIC', false, false,
'1. 에어컨 전원 차단\n2. 필터 위치 확인\n3. 기존 필터 제거\n4. 새 필터 설치\n5. 동작 확인',
'전원 차단 확인, 필터 규격 확인', true),

('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'HVAC_BOILER_MAINT', '보일러 정비', '보일러 정기 점검 및 정비', 'PREVENTIVE', 'HVAC', 'HIGH', 4.0, 'ADVANCED', true, false,
'1. 보일러 안전 점검\n2. 연소실 청소\n3. 배관 점검\n4. 안전장치 테스트\n5. 성능 확인',
'가스 안전 수칙 준수, 전문 기술자 작업', true);

-- 2. Insert sample work orders
INSERT INTO bms.work_orders (
    company_id, building_id, unit_id, fault_report_id, work_order_number, work_order_title, work_description,
    work_category, work_type, work_priority, work_urgency, template_id,
    requested_by, work_location, work_scope, estimated_duration_hours, estimated_cost,
    work_status, work_phase, progress_percentage, created_by
) VALUES 
-- Active work orders
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT building_id FROM bms.buildings WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    (SELECT unit_id FROM bms.units WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    (SELECT report_id FROM bms.fault_reports WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'WO-20250130-001',
    '101호 콘센트 수리',
    '101호 거실 콘센트가 작동하지 않아 교체가 필요합니다.',
    'CORRECTIVE',
    'ELECTRICAL',
    'MEDIUM',
    'NORMAL',
    (SELECT template_id FROM bms.work_order_templates WHERE template_code = 'ELEC_OUTLET_REPAIR'),
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    '101호 거실',
    '콘센트 1개 교체, 배선 점검',
    2.0,
    50000,
    'SCHEDULED',
    'PLANNING',
    0,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT building_id FROM bms.buildings WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    (SELECT unit_id FROM bms.units WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1 OFFSET 1),
    (SELECT report_id FROM bms.fault_reports WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1 OFFSET 1),
    'WO-20250130-002',
    '202호 누수 수리',
    '202호 화장실 세면대 아래 누수 수리가 필요합니다.',
    'EMERGENCY',
    'PLUMBING',
    'HIGH',
    'HIGH',
    (SELECT template_id FROM bms.work_order_templates WHERE template_code = 'PLUMB_LEAK_REPAIR'),
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    '202호 화장실',
    '누수 부위 확인 및 배관 교체',
    3.0,
    120000,
    'IN_PROGRESS',
    'EXECUTION',
    60,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT building_id FROM bms.buildings WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    NULL,
    NULL,
    'WO-20250129-003',
    '3층 복도 조명 교체',
    '3층 복도 LED 조명 정기 교체 작업입니다.',
    'PREVENTIVE',
    'LIGHTING',
    'LOW',
    'LOW',
    (SELECT template_id FROM bms.work_order_templates WHERE template_code = 'ELEC_LIGHTING_MAINT'),
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    '3층 복도',
    'LED 조명 5개 교체',
    1.5,
    75000,
    'COMPLETED',
    'COMPLETION',
    100,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- Update work orders with scheduling and assignment
UPDATE bms.work_orders 
SET scheduled_start_date = NOW() + INTERVAL '2 hours',
    scheduled_end_date = NOW() + INTERVAL '4 hours',
    assigned_to = (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    assignment_date = NOW()
WHERE work_order_number = 'WO-20250130-001';

UPDATE bms.work_orders 
SET scheduled_start_date = NOW() - INTERVAL '2 hours',
    scheduled_end_date = NOW() + INTERVAL '1 hour',
    actual_start_date = NOW() - INTERVAL '2 hours',
    assigned_to = (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    assignment_date = NOW() - INTERVAL '2.5 hours',
    actual_duration_hours = 2.0
WHERE work_order_number = 'WO-20250130-002';

UPDATE bms.work_orders 
SET scheduled_start_date = NOW() - INTERVAL '1 day',
    scheduled_end_date = NOW() - INTERVAL '22 hours',
    actual_start_date = NOW() - INTERVAL '1 day',
    actual_end_date = NOW() - INTERVAL '22.5 hours',
    assigned_to = (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    assignment_date = NOW() - INTERVAL '1 day' - INTERVAL '30 minutes',
    actual_duration_hours = 1.5,
    actual_cost = 75000,
    quality_rating = 9.0,
    work_completion_notes = 'LED 조명 5개 교체 완료. 모든 조명이 정상 작동합니다.',
    closed_by = (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    closed_date = NOW() - INTERVAL '22.5 hours'
WHERE work_order_number = 'WO-20250129-003';-- 3.
 Insert work order assignments
INSERT INTO bms.work_order_assignments (
    company_id, work_order_id, assigned_to, assignment_role, assignment_type,
    allocated_hours, expected_start_date, expected_end_date,
    assignment_status, acceptance_status, assignment_notes, created_by
) VALUES 
-- Assignment for outlet repair
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-001'),
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'PRIMARY_TECHNICIAN',
    'INTERNAL',
    2.0,
    NOW() + INTERVAL '2 hours',
    NOW() + INTERVAL '4 hours',
    'ASSIGNED',
    'ACCEPTED',
    '콘센트 교체 작업 배정',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Assignment for leak repair
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002'),
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'PRIMARY_TECHNICIAN',
    'INTERNAL',
    3.0,
    NOW() - INTERVAL '2 hours',
    NOW() + INTERVAL '1 hour',
    'IN_PROGRESS',
    'ACCEPTED',
    '누수 수리 긴급 작업',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Assignment for completed lighting work
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003'),
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'PRIMARY_TECHNICIAN',
    'INTERNAL',
    1.5,
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '22 hours',
    'COMPLETED',
    'ACCEPTED',
    '조명 교체 정기 작업',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- Update assignment completion for completed work
UPDATE bms.work_order_assignments 
SET actual_hours = 1.5,
    work_percentage = 100,
    performance_rating = 9.0,
    quality_score = 9.5,
    timeliness_score = 8.5,
    completed_date = NOW() - INTERVAL '22.5 hours',
    completed_by = (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    completion_notes = '조명 교체 작업 완료. 품질 우수.'
WHERE work_order_id = (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003');

-- 4. Insert work order materials
INSERT INTO bms.work_order_materials (
    company_id, work_order_id, material_code, material_name, material_category,
    required_quantity, unit_of_measure, unit_cost, total_estimated_cost,
    material_status, procurement_status, supplier_name, created_by
) VALUES 
-- Materials for outlet repair
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-001'),
    'ELEC-OUTLET-001',
    '220V 콘센트',
    'ELECTRICAL',
    1.0,
    'EA',
    15000,
    15000,
    'REQUIRED',
    'PENDING',
    '전기자재상',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-001'),
    'ELEC-WIRE-001',
    '전선 (2.5sq)',
    'ELECTRICAL',
    2.0,
    'M',
    3000,
    6000,
    'REQUIRED',
    'PENDING',
    '전기자재상',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Materials for leak repair
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002'),
    'PLUMB-PIPE-001',
    'PVC 파이프 (20mm)',
    'PLUMBING',
    1.0,
    'M',
    8000,
    8000,
    'ALLOCATED',
    'DELIVERED',
    '배관자재상',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002'),
    'PLUMB-JOINT-001',
    'PVC 조인트',
    'PLUMBING',
    2.0,
    'EA',
    5000,
    10000,
    'ALLOCATED',
    'DELIVERED',
    '배관자재상',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Materials for completed lighting work
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003'),
    'LIGHT-LED-001',
    'LED 조명 (20W)',
    'LIGHTING',
    5.0,
    'EA',
    12000,
    60000,
    'USED',
    'RECEIVED',
    '조명전문업체',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- Update material usage for completed work
UPDATE bms.work_order_materials 
SET used_quantity = required_quantity,
    total_actual_cost = total_estimated_cost,
    usage_date = NOW() - INTERVAL '23 hours',
    used_by = (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    usage_notes = 'LED 조명 5개 모두 사용 완료'
WHERE work_order_id = (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003');

-- 5. Insert work order progress records
INSERT INTO bms.work_order_progress (
    company_id, work_order_id, progress_percentage, work_phase,
    work_completed, work_remaining, hours_worked, cumulative_hours,
    next_steps, reported_by
) VALUES 
-- Progress for leak repair
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002'),
    30,
    'EXECUTION',
    '누수 위치 확인 완료, 급수 차단 완료',
    '손상된 파이프 교체, 연결 작업, 테스트',
    1.0,
    1.0,
    '파이프 교체 작업 진행',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002'),
    60,
    'EXECUTION',
    '파이프 교체 완료, 연결 작업 진행 중',
    '누수 테스트, 마무리 작업',
    1.0,
    2.0,
    '누수 테스트 및 마무리',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Progress for completed lighting work
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003'),
    100,
    'COMPLETION',
    'LED 조명 5개 교체 완료, 동작 테스트 완료',
    '작업 완료',
    1.5,
    1.5,
    '작업 완료',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- 6. Test basic queries
SELECT 'Testing repair work management queries...' as test_step;

-- Get work order templates
SELECT template_code, template_name, work_category, work_type, is_active
FROM bms.work_order_templates
WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY template_code;

-- Get work orders
SELECT work_order_number, work_order_title, work_category, work_status, work_phase, progress_percentage
FROM bms.work_orders
WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY request_date DESC;

-- Get work order assignments
SELECT wa.assignment_role, wa.assignment_status, wo.work_order_number
FROM bms.work_order_assignments wa
JOIN bms.work_orders wo ON wa.work_order_id = wo.work_order_id
WHERE wa.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY wa.assigned_date DESC;

-- Get work order materials
SELECT wm.material_name, wm.required_quantity, wm.material_status, wo.work_order_number
FROM bms.work_order_materials wm
JOIN bms.work_orders wo ON wm.work_order_id = wo.work_order_id
WHERE wm.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY wm.created_at DESC;

-- Get work order progress
SELECT wp.progress_percentage, wp.work_phase, wp.work_completed, wo.work_order_number
FROM bms.work_order_progress wp
JOIN bms.work_orders wo ON wp.work_order_id = wo.work_order_id
WHERE wp.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY wp.progress_date DESC;

-- Script completion message
SELECT 'Repair work management test data created successfully.' as message;