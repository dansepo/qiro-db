-- =====================================================
-- 시설 유지보수 관리 테스트 데이터
-- =====================================================

-- 테스트 데이터 삽입 전 기존 데이터 정리
DELETE FROM facility_lifecycle_history;
DELETE FROM facility_inspection_results;
DELETE FROM facility_inspection_schedules;
DELETE FROM maintenance_cost_details;
DELETE FROM maintenance_work_progress;
DELETE FROM maintenance_works;
DELETE FROM maintenance_requests;
DELETE FROM vendor_blacklist;
DELETE FROM vendor_work_history_summary;
DELETE FROM vendor_evaluations;
DELETE FROM vendor_contracts;
DELETE FROM facility_vendors;
DELETE FROM facilities;

-- =====================================================
-- 1. 시설물 정보 테스트 데이터
-- =====================================================
INSERT INTO facilities (
    building_id, facility_code, facility_name, category, subcategory,
    location_description, floor_number, manufacturer, model_number, serial_number,
    installation_date, warranty_start_date, warranty_end_date, warranty_provider,
    maintenance_cycle_months, expected_lifespan_years, status,
    specifications, notes, created_by
) VALUES 
-- 건물 1의 시설물들
(1, 'ELV-001', '승객용 엘리베이터 #1', 'ELEVATOR', '승객용', 
 '1층 로비', 1, '현대엘리베이터', 'HE-2000', 'HE2000-001-2023',
 '2023-01-15', '2023-01-15', '2025-01-14', '현대엘리베이터',
 1, 20, 'ACTIVE',
 '{"capacity": "15인승", "speed": "60m/min", "floors": "B1-10F"}',
 '정기점검 필요', 1),

(1, 'ELV-002', '화물용 엘리베이터 #1', 'ELEVATOR', '화물용',
 '지하1층 주차장', -1, '현대엘리베이터', 'HE-3000', 'HE3000-001-2023',
 '2023-01-20', '2023-01-20', '2025-01-19', '현대엘리베이터',
 1, 20, 'ACTIVE',
 '{"capacity": "3000kg", "speed": "45m/min", "floors": "B1-10F"}',
 '화물 전용', 1),

(1, 'HVAC-B1-001', '중앙 냉난방 시스템', 'HVAC', '중앙공조',
 '지하1층 기계실', -1, '삼성공조', 'SC-5000', 'SC5000-001-2023',
 '2023-02-01', '2023-02-01', '2025-01-31', '삼성공조',
 3, 15, 'ACTIVE',
 '{"cooling_capacity": "500RT", "heating_capacity": "400RT"}',
 '계절별 점검 필요', 1),

(1, 'FIRE-001', '자동화재탐지설비', 'FIRE_SAFETY', '화재탐지',
 '전층', NULL, '한국소방', 'KF-2023', 'KF2023-001',
 '2023-01-10', '2023-01-10', '2025-01-09', '한국소방',
 6, 10, 'ACTIVE',
 '{"zones": 50, "detectors": 200, "type": "연기감지기"}',
 '법정점검 대상', 1),

-- 건물 2의 시설물들
(2, 'ELV-001', '승객용 엘리베이터 #1', 'ELEVATOR', '승객용',
 '1층 로비', 1, 'LG엘리베이터', 'LG-1500', 'LG1500-002-2022',
 '2022-12-01', '2022-12-01', '2024-11-30', 'LG엘리베이터',
 1, 20, 'MAINTENANCE',
 '{"capacity": "12인승", "speed": "45m/min", "floors": "1-8F"}',
 '현재 정기점검 중', 1),

(2, 'SEC-001', 'CCTV 통합관제시스템', 'SECURITY', 'CCTV',
 '1층 관리사무소', 1, '한화테크윈', 'HT-NVR64', 'HT64-002-2022',
 '2022-11-15', '2022-11-15', '2024-11-14', '한화테크윈',
 6, 7, 'ACTIVE',
 '{"channels": 64, "storage": "30TB", "resolution": "4K"}',
 '정상 작동 중', 1);

-- =====================================================
-- 2. 협력업체 정보 테스트 데이터
-- =====================================================
INSERT INTO facility_vendors (
    company_name, vendor_type, business_registration_number,
    contact_person, contact_phone, contact_email, address,
    specialization, certifications, establishment_date, employee_count,
    overall_grade, quality_score, reliability_score, cost_competitiveness_score,
    preferred_vendor, status, created_by
) VALUES 
('현대엘리베이터서비스', 'CORPORATION', '123-45-67890',
 '김기술', '02-1234-5678', 'tech@hyundai-elevator.co.kr', '서울시 강남구 테헤란로 123',
 '["엘리베이터", "에스컬레이터", "무빙워크"]', '["승강기 정비업 등록증", "ISO 9001"]',
 '1990-03-15', 150, 'A', 4.2, 4.5, 3.8, true, 'ACTIVE', 1),

('삼성공조기술', 'CORPORATION', '234-56-78901',
 '이냉방', '02-2345-6789', 'service@samsung-hvac.co.kr', '서울시 서초구 서초대로 456',
 '["냉난방", "환기설비", "공조시스템"]', '["냉동공조기능사", "건축기계설비기술사"]',
 '1985-07-20', 80, 'A', 4.0, 4.2, 4.1, true, 'ACTIVE', 1),

('한국소방안전', 'CORPORATION', '345-67-89012',
 '박소방', '02-3456-7890', 'safety@korea-fire.co.kr', '서울시 영등포구 여의도동 789',
 '["소방설비", "방재시설", "안전점검"]', '["소방설비기사", "소방안전관리자"]',
 '1995-11-10', 45, 'B', 3.8, 4.0, 3.5, false, 'ACTIVE', 1),

('대한전기공사', 'CORPORATION', '456-78-90123',
 '최전기', '02-4567-8901', 'electric@daehan-elec.co.kr', '서울시 마포구 상암동 101',
 '["전기설비", "조명시설", "전력설비"]', '["전기기사", "전기공사기사"]',
 '2000-05-25', 25, 'B', 3.5, 3.8, 4.0, false, 'ACTIVE', 1),

('신속수리서비스', 'INDIVIDUAL', '567-89-01234',
 '정수리', '010-1234-5678', 'repair@quick-service.co.kr', '서울시 동작구 상도동 202',
 '["일반수리", "긴급수리", "소규모공사"]', '["건축기능사"]',
 '2018-03-01', 5, 'C', 3.2, 3.0, 4.5, false, 'ACTIVE', 1);

-- =====================================================
-- 3. 협력업체 계약 정보 테스트 데이터
-- =====================================================
INSERT INTO vendor_contracts (
    vendor_id, contract_number, contract_name, contract_type,
    start_date, end_date, contract_amount, payment_terms,
    service_scope, response_time_hours, status, signed_date,
    company_signatory, vendor_signatory, created_by
) VALUES 
(1, 'CON-2024-001', '엘리베이터 정기점검 계약', 'MAINTENANCE',
 '2024-01-01', '2024-12-31', 12000000, '월말 지급',
 '엘리베이터 월 1회 정기점검 및 긴급수리', 2, 'ACTIVE', '2023-12-15',
 '김관리', '김기술', 1),

(2, 'CON-2024-002', '냉난방시설 유지보수 계약', 'MAINTENANCE',
 '2024-01-01', '2024-12-31', 8000000, '분기별 지급',
 '냉난방시설 계절별 점검 및 필터교체', 4, 'ACTIVE', '2023-12-20',
 '김관리', '이냉방', 1),

(3, 'CON-2024-003', '소방설비 법정점검 계약', 'INSPECTION',
 '2024-01-01', '2024-12-31', 3000000, '점검 완료 후 지급',
 '소방설비 법정점검 및 점검결과서 작성', 24, 'ACTIVE', '2023-12-10',
 '김관리', '박소방', 1);

-- =====================================================
-- 4. 시설물 점검 일정 테스트 데이터
-- =====================================================
INSERT INTO facility_inspection_schedules (
    facility_id, inspection_type, inspection_name, description,
    scheduled_date, estimated_duration_hours, assigned_to, vendor_id,
    inspection_checklist, status, estimated_cost, created_by
) VALUES 
(1, 'ROUTINE', '엘리베이터 월례점검', '승객용 엘리베이터 정기점검',
 '2024-02-15', 2.0, NULL, 1,
 '{"items": ["모터점검", "와이어로프점검", "브레이크점검", "안전장치점검"]}',
 'COMPLETED', 100000, 1),

(1, 'ROUTINE', '엘리베이터 월례점검', '승객용 엘리베이터 정기점검',
 '2024-03-15', 2.0, NULL, 1,
 '{"items": ["모터점검", "와이어로프점검", "브레이크점검", "안전장치점검"]}',
 'SCHEDULED', 100000, 1),

(3, 'ROUTINE', '냉난방시설 계절점검', '겨울철 난방시설 점검',
 '2024-02-01', 4.0, NULL, 2,
 '{"items": ["보일러점검", "배관점검", "온도조절기점검", "필터교체"]}',
 'COMPLETED', 200000, 1),

(4, 'LEGAL_REQUIRED', '소방설비 법정점검', '연 2회 법정점검',
 '2024-01-30', 6.0, NULL, 3,
 '{"items": ["화재탐지기점검", "스프링클러점검", "소화기점검", "비상구점검"]}',
 'COMPLETED', 150000, 1);

-- =====================================================
-- 5. 시설물 점검 결과 테스트 데이터
-- =====================================================
INSERT INTO facility_inspection_results (
    schedule_id, facility_id, inspection_date, inspector_name, inspector_certification,
    overall_condition, detailed_findings, issues_found, recommendations,
    next_inspection_due_date, next_inspection_type, created_by
) VALUES 
(1, 1, '2024-02-15', '김기술', '승강기정비기사',
 'GOOD', '{"motor": "정상", "wire_rope": "양호", "brake": "정상", "safety_device": "정상"}',
 '[]', '다음 점검까지 정상 운행 가능',
 '2024-03-15', 'ROUTINE', 1),

(3, 3, '2024-02-01', '이냉방', '냉동공조기능사',
 'FAIR', '{"boiler": "정상", "piping": "일부 누수", "thermostat": "정상", "filter": "교체완료"}',
 '[{"issue": "지하1층 배관 미세누수", "severity": "LOW"}]',
 '배관 누수 부분 조기 수리 권장',
 '2024-05-01', 'ROUTINE', 1),

(4, 4, '2024-01-30', '박소방', '소방설비기사',
 'EXCELLENT', '{"detectors": "정상", "sprinkler": "정상", "extinguisher": "정상", "exit": "정상"}',
 '[]', '모든 소방설비 정상 작동',
 '2024-07-30', 'LEGAL_REQUIRED', 1);

-- =====================================================
-- 6. 유지보수 요청 테스트 데이터
-- =====================================================
INSERT INTO maintenance_requests (
    building_id, facility_id, unit_id, request_type, title, description,
    requester_name, requester_contact, requester_type, priority,
    preferred_date, assigned_to, estimated_cost, status, created_by
) VALUES 
(1, 1, NULL, 'REPAIR', '엘리베이터 이상음 발생', 
 '승객용 엘리베이터에서 운행 중 이상음이 발생합니다. 확인 및 수리 요청드립니다.',
 '김입주', '010-1111-2222', 'TENANT', 'HIGH',
 '2024-02-20', 1, 150000, 'COMPLETED', 1),

(1, 3, NULL, 'MAINTENANCE', '냉난방 온도 조절 불량',
 '사무실 온도가 설정 온도와 다르게 나옵니다. 점검 요청합니다.',
 '이관리', '010-3333-4444', 'MANAGER', 'MEDIUM',
 '2024-02-25', 1, 80000, 'IN_PROGRESS', 1),

(2, 5, 201, 'EMERGENCY', '엘리베이터 갇힘 사고',
 '엘리베이터에 사람이 갇혔습니다. 긴급 출동 요청합니다.',
 '박긴급', '010-5555-6666', 'TENANT', 'CRITICAL',
 '2024-02-28', 1, 200000, 'COMPLETED', 1),

(1, NULL, 105, 'REPAIR', '화장실 배수 불량',
 '105호 화장실 배수가 잘 안됩니다. 수리 요청합니다.',
 '최세입', '010-7777-8888', 'TENANT', 'MEDIUM',
 '2024-03-01', 1, 50000, 'ASSIGNED', 1);

-- =====================================================
-- 7. 유지보수 작업 테스트 데이터
-- =====================================================
INSERT INTO maintenance_works (
    request_id, facility_id, vendor_id, work_title, work_description, work_type,
    scheduled_start_date, scheduled_end_date, actual_start_time, actual_end_time,
    primary_worker_name, labor_cost, material_cost, equipment_cost,
    status, work_quality_rating, completion_percentage, work_result_summary,
    created_by
) VALUES 
(1, 1, 1, '엘리베이터 베어링 교체', '이상음 원인인 베어링 교체 작업', 'REPAIR',
 '2024-02-20', '2024-02-20', '2024-02-20 09:00:00', '2024-02-20 12:00:00',
 '김기술', 80000, 60000, 10000, 'COMPLETED', 5, 100,
 '베어링 교체 완료, 이상음 해결됨', 1),

(2, 3, 2, '온도조절기 센서 교체', '온도 센서 불량으로 인한 교체 작업', 'REPAIR',
 '2024-02-25', '2024-02-25', '2024-02-25 14:00:00', NULL,
 '이냉방', 50000, 25000, 5000, 'IN_PROGRESS', NULL, 70,
 '센서 교체 중, 70% 완료', 1),

(3, 5, 1, '엘리베이터 긴급 구조', '갇힌 승객 구조 및 시스템 점검', 'EMERGENCY',
 '2024-02-28', '2024-02-28', '2024-02-28 15:30:00', '2024-02-28 16:30:00',
 '김기술', 100000, 0, 50000, 'COMPLETED', 4, 100,
 '승객 구조 완료, 도어 센서 조정', 1);

-- =====================================================
-- 8. 작업 진행 상황 테스트 데이터
-- =====================================================
INSERT INTO maintenance_work_progress (
    work_id, progress_date, progress_percentage, status_description,
    work_performed, time_spent_hours, reported_by, reporter_role, created_by
) VALUES 
(2, '2024-02-25', 30, '작업 시작 - 기존 센서 제거',
 '기존 온도센서 제거 및 배선 점검', 1.5, '이냉방', '기술자', 1),

(2, '2024-02-25', 70, '새 센서 설치 중',
 '새 온도센서 설치 및 배선 연결', 2.0, '이냉방', '기술자', 1);

-- =====================================================
-- 9. 비용 상세 테스트 데이터
-- =====================================================
INSERT INTO maintenance_cost_details (
    work_id, cost_category, item_name, item_description,
    quantity, unit, unit_price, supplier_name, is_taxable, created_by
) VALUES 
(1, 'MATERIAL', '엘리베이터 베어링', '승객용 엘리베이터 메인 베어링',
 2, '개', 30000, '현대엘리베이터부품', true, 1),

(1, 'LABOR', '기술자 인건비', '베어링 교체 작업 인건비',
 3, '시간', 26667, '현대엘리베이터서비스', true, 1),

(2, 'MATERIAL', '온도센서', '디지털 온도센서 TH-100',
 1, '개', 25000, '삼성공조부품', true, 1),

(3, 'LABOR', '긴급출동 인건비', '긴급 구조 작업 인건비',
 1, '건', 100000, '현대엘리베이터서비스', true, 1);

-- =====================================================
-- 10. 협력업체 평가 테스트 데이터
-- =====================================================
INSERT INTO vendor_evaluations (
    vendor_id, work_id, evaluation_period_start, evaluation_period_end,
    evaluation_type, work_quality_score, schedule_adherence_score,
    cost_effectiveness_score, communication_score, safety_compliance_score,
    customer_satisfaction_score, final_grade, strengths, weaknesses,
    evaluator_name, evaluator_position, created_by
) VALUES 
(1, 1, '2024-02-01', '2024-02-29', 'WORK_BASED',
 5, 5, 4, 4, 5, 5, 'A',
 '기술력 우수, 신속한 대응', '비용이 다소 높음',
 '김관리', '시설관리팀장', 1),

(1, 3, '2024-02-01', '2024-02-29', 'WORK_BASED',
 4, 5, 3, 4, 5, 4, 'A',
 '긴급상황 대응 우수', '비용 부담',
 '김관리', '시설관리팀장', 1),

(2, 2, '2024-02-01', '2024-02-29', 'WORK_BASED',
 4, 3, 4, 4, 4, NULL, 'B',
 '기술력 양호', '일정 지연',
 '김관리', '시설관리팀장', 1);

-- =====================================================
-- 11. 시설물 생애주기 이력 테스트 데이터
-- =====================================================
INSERT INTO facility_lifecycle_history (
    facility_id, event_type, event_date, event_description,
    cost, vendor_id, previous_status, new_status, created_by
) VALUES 
(1, 'INSTALLED', '2023-01-15', '승객용 엘리베이터 설치 완료',
 50000000, 1, NULL, 'ACTIVE', 1),

(1, 'MAINTAINED', '2024-02-15', '정기점검 실시',
 100000, 1, 'ACTIVE', 'ACTIVE', 1),

(1, 'REPAIRED', '2024-02-20', '베어링 교체 수리',
 150000, 1, 'ACTIVE', 'ACTIVE', 1),

(5, 'MAINTAINED', '2024-02-28', '긴급 수리 및 점검',
 200000, 1, 'MAINTENANCE', 'ACTIVE', 1);

-- =====================================================
-- 12. 협력업체 작업 이력 요약 업데이트
-- =====================================================
-- 2024년 협력업체별 작업 이력 요약 생성
SELECT update_vendor_work_history_summary(1, 2024);
SELECT update_vendor_work_history_summary(2, 2024);
SELECT update_vendor_work_history_summary(3, 2024);

-- =====================================================
-- 테스트 쿼리 실행
-- =====================================================

-- 1. 시설물 현황 요약 조회
SELECT * FROM facility_status_summary ORDER BY building_id, category;

-- 2. 점검 일정 현황 조회
SELECT * FROM inspection_schedule_overview ORDER BY scheduled_date;

-- 3. 유지보수 요청 대시보드 조회
SELECT * FROM maintenance_request_dashboard ORDER BY building_id, status;

-- 4. 협력업체 성과 대시보드 조회
SELECT * FROM vendor_performance_dashboard ORDER BY overall_grade DESC, company_name;

-- 5. 협력업체 계약 현황 조회
SELECT * FROM vendor_contract_status ORDER BY end_date;

-- 6. 작업자별 성과 현황 조회
SELECT * FROM worker_performance_summary ORDER BY completion_rate DESC;

-- 7. 시설물별 유지보수 이력 요약 조회
SELECT * FROM facility_maintenance_summary ORDER BY total_maintenance_cost DESC;

-- =====================================================
-- 데이터 검증 쿼리
-- =====================================================

-- 시설물 수 확인
SELECT COUNT(*) as total_facilities FROM facilities;

-- 협력업체 수 확인
SELECT COUNT(*) as total_vendors FROM facility_vendors;

-- 유지보수 요청 수 확인
SELECT status, COUNT(*) as count FROM maintenance_requests GROUP BY status;

-- 유지보수 작업 수 확인
SELECT status, COUNT(*) as count FROM maintenance_works GROUP BY status;

-- 평가 점수 평균 확인
SELECT 
    vendor_id,
    AVG(total_score) as avg_score,
    COUNT(*) as evaluation_count
FROM vendor_evaluations 
GROUP BY vendor_id;

COMMIT;