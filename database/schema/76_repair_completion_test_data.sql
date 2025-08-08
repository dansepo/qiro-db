-- =====================================================
-- Repair Completion Management Test Data
-- Phase 4.3.3: Test Data for Repair Completion Management
-- =====================================================

-- Use existing company
SET app.current_company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f';

-- 1. Insert completion inspections for completed work orders
INSERT INTO bms.work_completion_inspections (
    company_id, work_order_id, inspection_type, inspector_id, inspector_role,
    overall_result, quality_score, safety_compliance_score, workmanship_score,
    inspection_notes, recommendations, requires_rework, created_by
) VALUES 
-- Inspection for completed lighting work
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'FINAL_INSPECTION',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'SUPERVISOR',
    'PASSED',
    9.0,
    9.5,
    8.5,
    'LED 조명 5개 모두 정상 작동 확인. 설치 품질 우수.',
    '정기 점검 시 조도 측정 권장',
    false,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Inspection for in-progress leak repair (pending)
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'QUALITY_CHECK',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'QUALITY_INSPECTOR',
    'PENDING',
    0,
    0,
    0,
    '중간 점검 예정',
    '누수 테스트 완료 후 최종 검사 필요',
    false,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- 2. Insert completion reports
INSERT INTO bms.work_completion_reports (
    company_id, work_order_id, report_number, work_summary, work_performed,
    total_hours_worked, labor_cost, material_cost, equipment_cost, total_cost,
    work_quality_rating, customer_satisfaction, completion_timeliness,
    technical_specifications_met, safety_standards_followed, environmental_compliance,
    warranty_period_months, warranty_terms, customer_acceptance,
    completed_by, supervised_by, report_status, created_by
) VALUES 
-- Completion report for lighting work
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'CR-20250129-001',
    '3층 복도 LED 조명 5개 교체 작업 완료',
    '기존 형광등 제거, LED 조명 설치, 동작 테스트, 조도 측정',
    1.5,
    45000,
    60000,
    0,
    105000,
    9.0,
    9.5,
    8.5,
    true,
    true,
    true,
    12,
    'LED 조명 12개월 품질보증, A/S 무상 제공',
    true,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'FINALIZED',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- 3. Insert cost settlements
INSERT INTO bms.work_cost_settlements (
    company_id, work_order_id, settlement_number, settlement_type,
    estimated_labor_cost, actual_labor_cost, estimated_material_cost, actual_material_cost,
    estimated_equipment_cost, actual_equipment_cost, overtime_cost, contractor_fees,
    total_estimated_cost, total_actual_cost, cost_variance, variance_percentage,
    approved_budget, budget_utilization_percentage, budget_variance,
    payment_status, settlement_status, created_by
) VALUES 
-- Cost settlement for lighting work
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'CS-20250129-001',
    'INTERNAL',
    40000,  -- estimated labor
    45000,  -- actual labor
    60000,  -- estimated material
    60000,  -- actual material
    0,      -- estimated equipment
    0,      -- actual equipment
    5000,   -- overtime
    0,      -- contractor fees
    100000, -- total estimated
    110000, -- total actual (45000 + 60000 + 5000)
    10000,  -- variance
    10.0,   -- variance percentage
    120000, -- approved budget
    91.67,  -- budget utilization
    10000,  -- budget variance (under budget)
    'PAID',
    'FINALIZED',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Cost settlement for leak repair (in progress)
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'CS-20250130-001',
    'INTERNAL',
    90000,  -- estimated labor
    120000, -- actual labor (ongoing)
    18000,  -- estimated material
    18000,  -- actual material
    0,      -- estimated equipment
    0,      -- actual equipment
    30000,  -- overtime (emergency)
    0,      -- contractor fees
    108000, -- total estimated
    168000, -- total actual (120000 + 18000 + 30000)
    60000,  -- variance
    55.56,  -- variance percentage
    150000, -- approved budget
    112.0,  -- budget utilization (over budget)
    18000,  -- budget variance (over budget)
    'PENDING',
    'DRAFT',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- 4. Insert prevention measures
INSERT INTO bms.prevention_measures (
    company_id, work_order_id, measure_code, measure_title, measure_description,
    root_cause_category, root_cause_description, prevention_type, prevention_category,
    preventive_actions, implementation_priority, estimated_cost, estimated_duration_days,
    responsible_person, implementation_status, created_by
) VALUES 
-- Prevention measure for lighting maintenance
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'PM-20250129-001',
    '조명 정기 점검 체계 구축',
    '조명 시설의 정기적인 점검 및 예방 정비 체계를 구축하여 갑작스러운 고장을 방지',
    'MAINTENANCE_NEGLECT',
    '정기적인 조명 점검 및 교체 주기 관리 부족으로 인한 일괄 고장 발생',
    'MAINTENANCE_ENHANCEMENT',
    'PROCEDURAL',
    '[{"action": "월 1회 조명 상태 점검", "responsible": "시설팀"}, {"action": "연 1회 조도 측정", "responsible": "외부업체"}, {"action": "LED 수명 추적 시스템 도입", "responsible": "관리팀"}]',
    'MEDIUM',
    500000,
    30,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'PLANNED',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
-- Prevention measure for plumbing maintenance
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250130-002' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'PM-20250130-001',
    '배관 노후화 모니터링 시스템',
    '배관 노후화 상태를 정기적으로 모니터링하여 누수 발생 전 예방 조치 실시',
    'WEAR_AND_TEAR',
    '오래된 배관의 자연적 노후화로 인한 누수 발생',
    'MONITORING_SYSTEM',
    'TECHNICAL',
    '[{"action": "배관 상태 정기 점검", "responsible": "시설팀"}, {"action": "누수 감지 센서 설치", "responsible": "외부업체"}, {"action": "배관 교체 계획 수립", "responsible": "관리팀"}]',
    'HIGH',
    2000000,
    60,
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1),
    'IN_PROGRESS',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- 5. Insert work warranties
INSERT INTO bms.work_warranties (
    company_id, work_order_id, warranty_number, warranty_type, warranty_provider,
    warranty_scope, warranty_start_date, warranty_end_date, warranty_duration_months,
    warranty_terms, warranty_contact_person, warranty_contact_phone, warranty_contact_email,
    warranty_status, created_by
) VALUES 
-- Warranty for lighting work
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT work_order_id FROM bms.work_orders WHERE work_order_number = 'WO-20250129-003' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'WR-20250129-001',
    'MANUFACTURER',
    '조명전문업체',
    'LED 조명 5개에 대한 품질보증 및 무상 A/S',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '12 months',
    12,
    '제품 하자 시 무상 교체, 설치 불량 시 무상 재설치, 정상 사용 중 고장 시 무상 수리',
    '김기술',
    '02-1234-5678',
    'tech@lighting.com',
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- 6. Test basic queries
SELECT 'Testing repair completion management queries...' as test_step;

-- Get completion inspections
SELECT wci.inspection_type, wci.overall_result, wci.quality_score, wo.work_order_number
FROM bms.work_completion_inspections wci
JOIN bms.work_orders wo ON wci.work_order_id = wo.work_order_id
WHERE wci.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY wci.inspection_date DESC;

-- Get completion reports
SELECT wcr.report_number, wcr.work_summary, wcr.total_cost, wcr.report_status, wo.work_order_number
FROM bms.work_completion_reports wcr
JOIN bms.work_orders wo ON wcr.work_order_id = wo.work_order_id
WHERE wcr.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY wcr.report_date DESC;

-- Get cost settlements
SELECT wcs.settlement_number, wcs.settlement_type, wcs.total_actual_cost, wcs.cost_variance, wo.work_order_number
FROM bms.work_cost_settlements wcs
JOIN bms.work_orders wo ON wcs.work_order_id = wo.work_order_id
WHERE wcs.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY wcs.settlement_date DESC;

-- Get prevention measures
SELECT pm.measure_code, pm.measure_title, pm.implementation_priority, pm.implementation_status
FROM bms.prevention_measures pm
WHERE pm.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY pm.created_at DESC;

-- Get work warranties
SELECT ww.warranty_number, ww.warranty_type, ww.warranty_provider, ww.warranty_status, wo.work_order_number
FROM bms.work_warranties ww
JOIN bms.work_orders wo ON ww.work_order_id = wo.work_order_id
WHERE ww.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY ww.warranty_start_date DESC;

-- Script completion message
SELECT 'Repair completion management test data created successfully.' as message;