-- =====================================================
-- 고장 신고 시스템 테스트 데이터
-- 설명: 고장 분류, 신고, 첨부파일 테스트 데이터 생성
-- =====================================================

-- 회사 컨텍스트 설정 (테스트용)
SET app.current_company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e';

-- 1. 고장 분류 테스트 데이터 삽입
INSERT INTO bms.fault_categories (
    company_id, category_code, category_name, category_description,
    default_priority, default_urgency, response_time_minutes, resolution_time_hours,
    requires_immediate_response, default_assigned_team, is_active
) VALUES 
-- 전기 관련 고장
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'ELEC_POWER', '전력 장애', '정전, 전력 공급 문제', 'URGENT', 'CRITICAL', 60, 4, true, '전기팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'ELEC_LIGHT', '조명 문제', '조명 고장, 전구 교체', 'MEDIUM', 'NORMAL', 480, 24, false, '전기팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'ELEC_OUTLET', '콘센트 문제', '콘센트 고장, 전기 접촉 불량', 'MEDIUM', 'NORMAL', 720, 48, false, '전기팀', true),

-- 배관 관련 고장
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'PLUMB_LEAK', '누수 문제', '파이프 누수, 물 새는 문제', 'HIGH', 'HIGH', 120, 8, true, '배관팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'PLUMB_BLOCK', '배수 막힘', '하수구 막힘, 배수 불량', 'MEDIUM', 'NORMAL', 240, 12, false, '배관팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'PLUMB_PRESS', '수압 문제', '수압 부족, 물 안 나옴', 'HIGH', 'HIGH', 120, 6, true, '배관팀', true),

-- 냉난방 관련 고장
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'HVAC_HEAT', '난방 문제', '보일러 고장, 난방 불량', 'HIGH', 'HIGH', 120, 8, true, '기계팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'HVAC_COOL', '냉방 문제', '에어컨 고장, 냉방 불량', 'MEDIUM', 'NORMAL', 240, 12, false, '기계팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'HVAC_VENT', '환기 문제', '환풍기 고장, 환기 불량', 'MEDIUM', 'NORMAL', 480, 24, false, '기계팀', true),

-- 안전 및 보안
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'SAFE_FIRE', '화재 안전', '화재 경보기, 소화기 문제', 'EMERGENCY', 'CRITICAL', 30, 2, true, '안전팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'SAFE_LOCK', '보안 문제', '도어락, 출입 통제 문제', 'HIGH', 'HIGH', 60, 4, true, '보안팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'SAFE_EMRG', '비상 설비', '비상등, 비상구 문제', 'HIGH', 'HIGH', 60, 4, true, '안전팀', true),

-- 구조물 및 유지보수
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'STRUCT_WALL', '벽체 문제', '벽 균열, 페인트 벗겨짐', 'LOW', 'LOW', 4320, 168, false, '시설팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'STRUCT_FLOOR', '바닥 문제', '바닥 손상, 타일 깨짐', 'MEDIUM', 'NORMAL', 1440, 72, false, '시설팀', true),
('c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e', 'STRUCT_DOOR', '문 문제', '문 고장, 손잡이 문제', 'MEDIUM', 'NORMAL', 720, 48, false, '시설팀', true);

-- 2. 고장 신고 테스트 데이터 삽입
INSERT INTO bms.fault_reports (
    company_id, building_id, unit_id, category_id, report_number, report_title, report_description,
    reporter_type, reporter_name, reporter_contact, fault_type, fault_severity, fault_location,
    fault_priority, fault_urgency, report_status, resolution_status, reported_at, created_by
) VALUES 
-- 최근 신고들
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
    '{"phone": "010-1234-5678", "email": "kim@example.com"}',
    'ELECTRICAL',
    'CRITICAL',
    '101호 전체',
    'URGENT',
    'CRITICAL',
    'OPEN',
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
    '{"phone": "010-2345-6789"}',
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
    '{"phone": "010-3456-7890", "email": "park@example.com"}',
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

-- 일부 신고에 배정 및 응답 정보 업데이트
UPDATE bms.fault_reports 
SET assigned_to = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    assigned_team = '배관팀',
    acknowledged_at = NOW() - INTERVAL '3.5 hours',
    acknowledged_by = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    first_response_at = NOW() - INTERVAL '3 hours',
    work_started_at = NOW() - INTERVAL '3 hours'
WHERE report_number = 'FR-20250130-002';

UPDATE bms.fault_reports 
SET assigned_to = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    assigned_team = '기계팀',
    acknowledged_at = NOW() - INTERVAL '22 hours',
    acknowledged_by = (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    first_response_at = NOW() - INTERVAL '20 hours',
    work_started_at = NOW() - INTERVAL '20 hours'
WHERE report_number = 'FR-20250129-003';

-- 3. 해결 완료된 신고 데이터 삽입
INSERT INTO bms.fault_reports (
    company_id, building_id, unit_id, category_id, report_number, report_title, report_description,
    reporter_type, reporter_name, reporter_contact, fault_type, fault_severity, fault_location,
    fault_priority, fault_urgency, report_status, resolution_status, 
    reported_at, acknowledged_at, first_response_at, work_started_at, resolved_at,
    assigned_to, assigned_team, acknowledged_by, resolved_by, resolution_method, resolution_description,
    reporter_satisfaction_rating, resolution_quality_rating, actual_repair_cost, created_by
) VALUES 
-- 해결된 전기 문제
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
    '{"phone": "02-1234-5678"}',
    'ELECTRICAL',
    'MODERATE',
    '3층 복도',
    'MEDIUM',
    'NORMAL',
    'RESOLVED',
    'COMPLETED',
    NOW() - INTERVAL '2 days',
    NOW() - INTERVAL '2 days' + INTERVAL '30 minutes',
    NOW() - INTERVAL '2 days' + INTERVAL '1 hour',
    NOW() - INTERVAL '2 days' + INTERVAL '1 hour',
    NOW() - INTERVAL '1 day' + INTERVAL '2 hours',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    '전기팀',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    'PART_REPLACEMENT',
    'LED 전구 3개 교체 완료. 안정기도 함께 점검하여 교체했습니다.',
    8.5,
    9.0,
    45000.00,
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
),
-- 해결된 배관 문제
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
    '{"phone": "010-4567-8901", "email": "choi@example.com"}',
    'PLUMBING',
    'MODERATE',
    '404호 주방',
    'MEDIUM',
    'NORMAL',
    'RESOLVED',
    'COMPLETED',
    NOW() - INTERVAL '3 days',
    NOW() - INTERVAL '3 days' + INTERVAL '45 minutes',
    NOW() - INTERVAL '3 days' + INTERVAL '2 hours',
    NOW() - INTERVAL '3 days' + INTERVAL '2 hours',
    NOW() - INTERVAL '2 days' + INTERVAL '4 hours',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    '배관팀',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    'CLEANING_REPAIR',
    '배수관 청소 및 막힌 부분 제거 완료. 예방을 위해 배수망 설치했습니다.',
    7.5,
    8.0,
    25000.00,
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1)
);

-- 4. 첨부파일 테스트 데이터 삽입
INSERT INTO bms.attachments (
    entity_id, entity_type, file_name, file_path, file_type, file_size,
    attachment_category, description, uploaded_by, is_public
) VALUES 
-- 정전 신고 관련 첨부파일
(
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250130-001'),
    'FAULT_REPORT',
    'power_outage_photo.jpg',
    '/uploads/fault_report/power_outage_photo.jpg',
    'image/jpeg',
    1024000,
    'INITIAL_PHOTO',
    '정전 상황 사진',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    false
),
-- 누수 신고 관련 첨부파일
(
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250130-002'),
    'FAULT_REPORT',
    'leak_damage.jpg',
    '/uploads/fault_report/leak_damage.jpg',
    'image/jpeg',
    2048000,
    'INITIAL_PHOTO',
    '누수로 인한 손상 사진',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    false
),
(
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250130-002'),
    'FAULT_REPORT',
    'repair_progress.mp4',
    '/uploads/fault_report/repair_progress.mp4',
    'video/mp4',
    15728640,
    'PROGRESS_PHOTO',
    '수리 진행 과정 동영상',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    false
),
-- 해결 완료된 신고의 완료 사진
(
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250128-004'),
    'FAULT_REPORT',
    'lighting_repair_complete.jpg',
    '/uploads/fault_report/lighting_repair_complete.jpg',
    'image/jpeg',
    1536000,
    'COMPLETION_PHOTO',
    '조명 수리 완료 사진',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    true
),
(
    (SELECT report_id FROM bms.fault_reports WHERE report_number = 'FR-20250127-005'),
    'FAULT_REPORT',
    'plumbing_repair_invoice.pdf',
    '/uploads/fault_report/plumbing_repair_invoice.pdf',
    'application/pdf',
    512000,
    'DOCUMENT',
    '배관 수리 견적서',
    (SELECT user_id FROM bms.user_profiles WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e' LIMIT 1),
    false
);

-- 5. 응답 시간 및 해결 기한 업데이트
UPDATE bms.fault_reports 
SET first_response_due = reported_at + INTERVAL '1 hour',
    resolution_due = reported_at + INTERVAL '4 hours'
WHERE report_number = 'FR-20250130-001';

UPDATE bms.fault_reports 
SET first_response_due = reported_at + INTERVAL '2 hours',
    resolution_due = reported_at + INTERVAL '8 hours'
WHERE report_number = 'FR-20250130-002';

UPDATE bms.fault_reports 
SET first_response_due = reported_at + INTERVAL '2 hours',
    resolution_due = reported_at + INTERVAL '8 hours'
WHERE report_number = 'FR-20250129-003';

-- 6. 통계 확인 쿼리
SELECT 
    '고장 분류 개수' as 항목,
    COUNT(*) as 개수
FROM bms.fault_categories 
WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e'

UNION ALL

SELECT 
    '고장 신고 개수' as 항목,
    COUNT(*) as 개수
FROM bms.fault_reports 
WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e'

UNION ALL

SELECT 
    '첨부파일 개수' as 항목,
    COUNT(*) as 개수
FROM bms.attachments 
WHERE entity_type = 'FAULT_REPORT';

-- 7. 상태별 신고 현황
SELECT 
    report_status as 상태,
    COUNT(*) as 건수
FROM bms.fault_reports 
WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e'
GROUP BY report_status
ORDER BY 건수 DESC;

-- 8. 우선순위별 신고 현황
SELECT 
    fault_priority as 우선순위,
    COUNT(*) as 건수
FROM bms.fault_reports 
WHERE company_id = 'c47e1e1e-1e1e-1e1e-1e1e-1e1e1e1e1e1e'
GROUP BY fault_priority
ORDER BY 
    CASE fault_priority
        WHEN 'EMERGENCY' THEN 1
        WHEN 'URGENT' THEN 2
        WHEN 'HIGH' THEN 3
        WHEN 'MEDIUM' THEN 4
        WHEN 'LOW' THEN 5
    END;

-- 스크립트 완료 메시지
SELECT '고장 신고 시스템 테스트 데이터가 성공적으로 생성되었습니다.' as message;