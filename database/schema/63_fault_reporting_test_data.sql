-- =====================================================
-- Fault Reporting System Test Data
-- Phase 4.3.1: Test Data for Fault Reporting System
-- =====================================================

-- Set company context
SET app.current_company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e';

-- 1. Insert fault categories
INSERT INTO bms.fault_categories (
    company_id, category_code, category_name, category_description,
    default_priority, default_urgency, response_time_hours, resolution_time_hours,
    escalation_enabled, escalation_hours, auto_assign_enabled, is_active
) VALUES 
-- Electrical faults
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'ELEC_POWER', '전력 장애', '정전, 전력 공급 문제', 'URGENT', 'CRITICAL', 1, 4, true, 2, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'ELEC_LIGHT', '조명 문제', '조명 고장, 전구 교체', 'MEDIUM', 'NORMAL', 8, 24, true, 4, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'ELEC_OUTLET', '콘센트 문제', '콘센트 고장, 전기 접촉 불량', 'MEDIUM', 'NORMAL', 12, 48, true, 6, false, true),

-- Plumbing faults
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'PLUMB_LEAK', '누수 문제', '파이프 누수, 물 새는 문제', 'HIGH', 'HIGH', 2, 8, true, 2, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'PLUMB_BLOCK', '배수 막힘', '하수구 막힘, 배수 불량', 'MEDIUM', 'NORMAL', 4, 12, true, 4, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'PLUMB_PRESS', '수압 문제', '수압 부족, 물 안 나옴', 'HIGH', 'HIGH', 2, 6, true, 3, false, true),

-- HVAC faults
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'HVAC_HEAT', '난방 문제', '보일러 고장, 난방 불량', 'HIGH', 'HIGH', 2, 8, true, 3, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'HVAC_COOL', '냉방 문제', '에어컨 고장, 냉방 불량', 'MEDIUM', 'NORMAL', 4, 12, true, 4, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'HVAC_VENT', '환기 문제', '환풍기 고장, 환기 불량', 'MEDIUM', 'NORMAL', 8, 24, true, 6, false, true),

-- Safety and security
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'SAFE_FIRE', '화재 안전', '화재 경보기, 소화기 문제', 'EMERGENCY', 'CRITICAL', 0.5, 2, true, 1, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'SAFE_LOCK', '보안 문제', '도어락, 출입 통제 문제', 'HIGH', 'HIGH', 1, 4, true, 2, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'SAFE_EMRG', '비상 설비', '비상등, 비상구 문제', 'HIGH', 'HIGH', 1, 4, true, 2, false, true),

-- Structural and maintenance
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'STRUCT_WALL', '벽체 문제', '벽 균열, 페인트 벗겨짐', 'LOW', 'LOW', 72, 168, false, 24, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'STRUCT_FLOOR', '바닥 문제', '바닥 손상, 타일 깨짐', 'MEDIUM', 'NORMAL', 24, 72, true, 12, false, true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'STRUCT_DOOR', '문 문제', '문 고장, 손잡이 문제', 'MEDIUM', 'NORMAL', 12, 48, true, 8, false, true);

-- 2. Insert sample fault reports
INSERT INTO bms.fault_reports (
    company_id, building_id, unit_id, category_id, report_number, report_title, report_description,
    reporter_type, reporter_name, reporter_contact, fault_type, fault_severity, fault_location,
    priority_level, urgency_level, report_status, resolution_status, reported_at, created_by
) VALUES 
-- Recent reports
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT building_id FROM bms.buildings WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT unit_id FROM bms.units WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT category_id FROM bms.fault_categories WHERE category_code = 'ELEC_POWER'),
    'FR-20250130-001',
    '101호 정전 발생',
    '오늘 오전 9시경부터 101호 전체 정전이 발생했습니다. 브레이커를 확인했지만 문제를 찾을 수 없습니다.',
    'TENANT',
    '김철수',
    '010-1234-5678',
    'ELECTRICAL',
    'CRITICAL',
    '101호 전체',
    'URGENT',
    'CRITICAL',
    'SUBMITTED',
    'PENDING',
    NOW() - INTERVAL '2 hours',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
),
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT building_id FROM bms.buildings WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT unit_id FROM bms.units WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1 OFFSET 1),
    (SELECT category_id FROM bms.fault_categories WHERE category_code = 'PLUMB_LEAK'),
    'FR-20250130-002',
    '화장실 누수 문제',
    '화장실 세면대 아래에서 물이 계속 새고 있습니다. 바닥이 젖어서 곰팡이가 생길 것 같습니다.',
    'TENANT',
    '이영희',
    '010-2345-6789',
    'PLUMBING',
    'MAJOR',
    '202호 화장실',
    'HIGH',
    'HIGH',
    'ACKNOWLEDGED',
    'IN_PROGRESS',
    NOW() - INTERVAL '4 hours',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
),
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT building_id FROM bms.buildings WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT unit_id FROM bms.units WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1 OFFSET 2),
    (SELECT category_id FROM bms.fault_categories WHERE category_code = 'HVAC_HEAT'),
    'FR-20250129-003',
    '보일러 작동 불량',
    '어제부터 보일러가 제대로 작동하지 않아 난방이 안 됩니다. 온도 조절이 전혀 되지 않습니다.',
    'TENANT',
    '박민수',
    '010-3456-7890',
    'HVAC',
    'MAJOR',
    '303호 보일러실',
    'HIGH',
    'HIGH',
    'IN_PROGRESS',
    'IN_PROGRESS',
    NOW() - INTERVAL '1 day',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
);

-- Update some reports with assignment and resolution
UPDATE bms.fault_reports 
SET assigned_to = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    assignment_date = NOW() - INTERVAL '3 hours',
    acknowledged_at = NOW() - INTERVAL '3.5 hours',
    acknowledged_by = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    response_started_at = NOW() - INTERVAL '3 hours'
WHERE report_number = 'FR-20250130-002';

UPDATE bms.fault_reports 
SET assigned_to = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    assignment_date = NOW() - INTERVAL '20 hours',
    acknowledged_at = NOW() - INTERVAL '22 hours',
    acknowledged_by = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    response_started_at = NOW() - INTERVAL '20 hours'
WHERE report_number = 'FR-20250129-003';-- 3
. Insert historical resolved reports
INSERT INTO bms.fault_reports (
    company_id, building_id, unit_id, category_id, report_number, report_title, report_description,
    reporter_type, reporter_name, reporter_contact, fault_type, fault_severity, fault_location,
    priority_level, urgency_level, report_status, resolution_status, 
    reported_at, acknowledged_at, response_started_at, resolved_at,
    assigned_to, acknowledged_by, resolved_by, resolution_method, resolution_description,
    reporter_satisfaction_rating, resolution_quality_rating, created_by
) VALUES 
-- Resolved electrical issue
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT building_id FROM bms.buildings WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT unit_id FROM bms.units WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1 OFFSET 3),
    (SELECT category_id FROM bms.fault_categories WHERE category_code = 'ELEC_LIGHT'),
    'FR-20250128-004',
    '복도 조명 고장',
    '3층 복도 조명 3개가 깜빡거리다가 꺼졌습니다.',
    'STAFF',
    '관리사무소',
    '02-1234-5678',
    'ELECTRICAL',
    'MODERATE',
    '3층 복도',
    'MEDIUM',
    'NORMAL',
    'RESOLVED',
    'RESOLVED',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days' + INTERVAL '30 minutes',
    NOW() - INTERVAL '2 days' + INTERVAL '1 hour',
    NOW() - INTERVAL '1 day' + INTERVAL '2 hours',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    'PART_REPLACEMENT',
    'LED 전구 3개 교체 완료. 안정기도 함께 점검하여 교체했습니다.',
    8.5,
    9.0,
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
),
-- Resolved plumbing issue
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT building_id FROM bms.buildings WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT unit_id FROM bms.units WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1 OFFSET 4),
    (SELECT category_id FROM bms.fault_categories WHERE category_code = 'PLUMB_BLOCK'),
    'FR-20250127-005',
    '주방 싱크대 배수 막힘',
    '주방 싱크대에서 물이 빠지지 않고 역류합니다.',
    'TENANT',
    '최정민',
    '010-4567-8901',
    'PLUMBING',
    'MODERATE',
    '404호 주방',
    'MEDIUM',
    'NORMAL',
    'RESOLVED',
    'RESOLVED',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days' + INTERVAL '45 minutes',
    NOW() - INTERVAL '3 days' + INTERVAL '2 hours',
    NOW() - INTERVAL '2 days' + INTERVAL '4 hours',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    'CLEANING_REPAIR',
    '배수관 청소 및 막힌 부분 제거 완료. 예방을 위해 배수망 설치했습니다.',
    7.5,
    8.0,
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
);

-- 4. Insert communication records
INSERT INTO bms.fault_report_communications (
    company_id, report_id, communication_type, communication_direction, communication_method,
    sender_type, sender_name, sender_contact, recipient_type, recipient_name,
    subject, message_content, sent_at, delivered_at, delivery_status, created_by
) VALUES 
-- Communications for power outage report
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250130-001'),
    'ACKNOWLEDGMENT',
    'OUTBOUND',
    'SMS',
    'STAFF',
    '관리사무소',
    '02-1234-5678',
    'TENANT',
    '김철수',
    '고장신고 접수 확인',
    '고장신고가 접수되었습니다. 신속히 처리하겠습니다. [관리사무소]',
    NOW() - INTERVAL '1.5 hours',
    NOW() - INTERVAL '1.5 hours',
    'DELIVERED',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
),
-- Communications for leak report
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250130-002'),
    'STATUS_UPDATE',
    'OUTBOUND',
    'PHONE',
    'STAFF',
    '수리기사',
    '010-9876-5432',
    'TENANT',
    '이영희',
    '누수 수리 진행 상황',
    '현재 누수 원인을 파악했으며, 부품 교체 중입니다. 1시간 내 완료 예정입니다.',
    NOW() - INTERVAL '1 hour',
    NOW() - INTERVAL '1 hour',
    'DELIVERED',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
),
-- Communications for resolved lighting issue
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250128-004'),
    'RESOLUTION_NOTICE',
    'OUTBOUND',
    'EMAIL',
    'STAFF',
    '관리사무소',
    'admin@building.com',
    'STAFF',
    '관리사무소',
    '조명 수리 완료 알림',
    '3층 복도 조명 수리가 완료되었습니다. LED 전구 3개와 안정기를 교체했습니다.',
    NOW() - INTERVAL '1 day' + INTERVAL '2 hours',
    NOW() - INTERVAL '1 day' + INTERVAL '2 hours',
    'DELIVERED',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
);

-- 5. Insert feedback records
INSERT INTO bms.fault_report_feedback (
    company_id, report_id, feedback_provider_type, feedback_provider_name, feedback_provider_contact,
    feedback_type, feedback_category, overall_satisfaction, response_time_rating,
    communication_quality_rating, resolution_quality_rating, staff_professionalism_rating,
    positive_aspects, areas_for_improvement, additional_comments,
    would_recommend, issue_fully_resolved, resolution_met_expectations, submission_method
) VALUES 
-- Feedback for resolved lighting issue
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250128-004'),
    'STAFF',
    '관리사무소',
    '02-1234-5678',
    'SATISFACTION_SURVEY',
    'TECHNICAL_QUALITY',
    8.5,
    9.0,
    8.0,
    9.0,
    8.5,
    '신속한 대응과 정확한 수리가 좋았습니다.',
    '사전 예방점검을 더 자주 했으면 좋겠습니다.',
    '전반적으로 만족스러운 서비스였습니다.',
    true,
    true,
    true,
    'WEB_PORTAL'
),
-- Feedback for resolved plumbing issue
(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e',
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250127-005'),
    'TENANT',
    '최정민',
    '010-4567-8901',
    'SATISFACTION_SURVEY',
    'GENERAL',
    7.5,
    7.0,
    8.0,
    8.0,
    8.5,
    '기사님이 친절하고 꼼꼼하게 작업해주셨습니다.',
    '좀 더 빨리 와주셨으면 좋았을 것 같습니다.',
    '배수망까지 설치해주셔서 감사합니다.',
    true,
    true,
    true,
    'MOBILE_APP'
);

-- 6. Test function calls
-- Test creating a new fault report
SELECT 'Testing fault report creation...' as test_step;

SELECT bms.create_fault_report(
    'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e'::UUID,
    '엘리베이터 고장',
    '1층 엘리베이터가 문이 열리지 않고 멈춰있습니다. 승객은 없는 상태입니다.',
    (SELECT category_id FROM bms.fault_categories WHERE category_code = 'SAFE_EMRG'),
    'MECHANICAL',
    'MAJOR',
    'VISITOR',
    '방문객',
    '010-1111-2222',
    (SELECT building_id FROM bms.buildings WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    NULL,
    NULL,
    '1층 엘리베이터',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
) as new_report_id;

-- Test getting fault reports
SELECT 'Testing fault report retrieval...' as test_step;

SELECT report_number, report_title, fault_severity, report_status, reporter_name
FROM bms.get_fault_reports('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e'::UUID, 10, 0)
ORDER BY reported_at DESC;

-- Test getting statistics
SELECT 'Testing fault report statistics...' as test_step;

SELECT total_reports, open_reports, resolved_reports, 
       ROUND(avg_response_time_hours, 2) as avg_response_hours,
       ROUND(avg_resolution_time_hours, 2) as avg_resolution_hours,
       ROUND(avg_satisfaction_rating, 1) as avg_satisfaction
FROM bms.get_fault_report_statistics('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e'::UUID);

-- Script completion message
SELECT 'Fault reporting system test data created and tested successfully.' as message;