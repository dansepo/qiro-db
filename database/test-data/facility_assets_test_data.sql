-- 시설물 자산 관리 테스트 데이터
-- 다양한 유형의 시설물 자산 샘플 데이터

-- 전기 시설 자산
INSERT INTO bms.facility_assets (
    asset_code, asset_name, asset_category, asset_type, manufacturer, model_name, serial_number,
    location, building_id, floor_number, purchase_date, purchase_amount, installation_date,
    warranty_start_date, warranty_end_date, asset_status, usage_status, importance_level,
    maintenance_cycle_days, next_maintenance_date, description, manager_id, created_by
) VALUES 
-- 승강기
('ELV-001', '승강기 #1', '승강기', '승객용 승강기', '현대엘리베이터', 'HE-2000', 'HE2000-001',
 '1동 승강기실', 1, 1, '2023-01-15', 50000000.00, '2023-02-01',
 '2023-02-01', '2025-02-01', 'NORMAL', 'IN_USE', 'HIGH',
 30, '2024-08-15', '1동 메인 승강기', 1, 1),

('ELV-002', '승강기 #2', '승강기', '승객용 승강기', '현대엘리베이터', 'HE-2000', 'HE2000-002',
 '1동 승강기실', 1, 1, '2023-01-15', 50000000.00, '2023-02-01',
 '2023-02-01', '2025-02-01', 'NORMAL', 'IN_USE', 'HIGH',
 30, '2024-08-15', '1동 보조 승강기', 1, 1),

-- 소방 시설
('FIRE-001', '소화펌프', '소방', '소화설비', '한국소방', 'KF-P500', 'KFP500-001',
 '지하1층 기계실', 1, -1, '2023-03-10', 15000000.00, '2023-03-20',
 '2023-03-20', '2025-03-20', 'NORMAL', 'IN_USE', 'HIGH',
 90, '2024-09-20', '메인 소화펌프', 2, 1),

('FIRE-002', '스프링클러 제어반', '소방', '소화설비', '한국소방', 'KF-SP100', 'KFSP100-001',
 '지하1층 소방실', 1, -1, '2023-03-10', 8000000.00, '2023-03-20',
 '2023-03-20', '2025-03-20', 'NORMAL', 'IN_USE', 'HIGH',
 180, '2024-09-20', '스프링클러 시스템 제어반', 2, 1),

-- 기계 시설
('HVAC-001', '중앙공조기 #1', '기계', '공조설비', 'LG전자', 'LG-AHU-1000', 'LGAHU1000-001',
 '옥상 기계실', 1, 10, '2023-02-20', 30000000.00, '2023-03-01',
 '2023-03-01', '2025-03-01', 'NORMAL', 'IN_USE', 'HIGH',
 60, '2024-09-01', '1동 중앙공조기', 3, 1),

('HVAC-002', '중앙공조기 #2', '기계', '공조설비', 'LG전자', 'LG-AHU-1000', 'LGAHU1000-002',
 '옥상 기계실', 1, 10, '2023-02-20', 30000000.00, '2023-03-01',
 '2023-03-01', '2025-03-01', 'INSPECTION_REQUIRED', 'IN_USE', 'HIGH',
 60, '2024-07-15', '1동 중앙공조기 백업', 3, 1),

-- 전기 시설
('ELEC-001', '고압 수전반', '전기', '수배전설비', '한국전력기기', 'KE-HV-500', 'KEHV500-001',
 '지하1층 전기실', 1, -1, '2023-01-10', 25000000.00, '2023-01-25',
 '2023-01-25', '2025-01-25', 'NORMAL', 'IN_USE', 'HIGH',
 365, '2024-01-25', '메인 고압 수전반', 4, 1),

('ELEC-002', '비상발전기', '전기', '발전설비', '대우건설기계', 'DW-GEN-300', 'DWGEN300-001',
 '지하1층 발전기실', 1, -1, '2023-01-20', 40000000.00, '2023-02-05',
 '2023-02-05', '2025-02-05', 'NORMAL', 'STANDBY', 'HIGH',
 30, '2024-08-05', '비상용 디젤발전기 300kW', 4, 1),

-- 보안 시설
('SEC-001', 'CCTV 서버', '보안', 'CCTV', '한화테크윈', 'HT-NVR-64', 'HTNVR64-001',
 '1층 보안실', 1, 1, '2023-04-01', 5000000.00, '2023-04-10',
 '2023-04-10', '2025-04-10', 'NORMAL', 'IN_USE', 'MEDIUM',
 180, '2024-10-10', '64채널 NVR 서버', 5, 1),

('SEC-002', '출입통제 서버', '보안', '출입통제', '한화테크윈', 'HT-ACS-100', 'HTACS100-001',
 '1층 보안실', 1, 1, '2023-04-01', 3000000.00, '2023-04-10',
 '2023-04-10', '2025-04-10', 'NORMAL', 'IN_USE', 'MEDIUM',
 180, '2024-10-10', '출입통제 시스템 서버', 5, 1),

-- 통신 시설
('COMM-001', '네트워크 스위치', '통신', '네트워크', 'Cisco', 'C9300-48P', 'C930048P-001',
 '1층 통신실', 1, 1, '2023-05-01', 8000000.00, '2023-05-10',
 '2023-05-10', '2026-05-10', 'NORMAL', 'IN_USE', 'MEDIUM',
 365, '2024-05-10', '48포트 네트워크 스위치', 6, 1),

('COMM-002', 'UPS', '통신', '전원공급', 'APC', 'SMT3000RMI2U', 'SMT3000-001',
 '1층 통신실', 1, 1, '2023-05-01', 2000000.00, '2023-05-10',
 '2023-05-10', '2025-05-10', 'NORMAL', 'IN_USE', 'MEDIUM',
 180, '2024-11-10', '3kVA UPS', 6, 1),

-- 급수 시설
('WATER-001', '급수펌프 #1', '급수', '급수설비', '한국펌프', 'KP-W-100', 'KPW100-001',
 '지하1층 급수실', 1, -1, '2023-02-15', 12000000.00, '2023-02-25',
 '2023-02-25', '2025-02-25', 'NORMAL', 'IN_USE', 'HIGH',
 90, '2024-08-25', '메인 급수펌프', 7, 1),

('WATER-002', '급수펌프 #2', '급수', '급수설비', '한국펌프', 'KP-W-100', 'KPW100-002',
 '지하1층 급수실', 1, -1, '2023-02-15', 12000000.00, '2023-02-25',
 '2023-02-25', '2025-02-25', 'UNDER_REPAIR', 'MAINTENANCE', 'HIGH',
 90, '2024-08-25', '보조 급수펌프 (현재 수리중)', 7, 1),

-- 오수 처리 시설
('WASTE-001', '오수펌프', '오수처리', '오수설비', '한국환경', 'KE-WP-50', 'KEWP50-001',
 '지하2층 오수처리실', 1, -2, '2023-03-01', 8000000.00, '2023-03-10',
 '2023-03-10', '2025-03-10', 'NORMAL', 'IN_USE', 'MEDIUM',
 60, '2024-09-10', '오수처리 펌프', 8, 1),

-- 주차 시설
('PARK-001', '주차관제 서버', '주차', '주차관제', '파크랜드', 'PL-PCS-100', 'PLPCS100-001',
 '지하1층 주차관제실', 1, -1, '2023-04-15', 10000000.00, '2023-04-25',
 '2023-04-25', '2025-04-25', 'NORMAL', 'IN_USE', 'MEDIUM',
 180, '2024-10-25', '주차관제 시스템', 9, 1),

('PARK-002', '차단기 #1', '주차', '주차관제', '파크랜드', 'PL-GATE-01', 'PLGATE01-001',
 '지하1층 주차장 입구', 1, -1, '2023-04-15', 2000000.00, '2023-04-25',
 '2023-04-25', '2025-04-25', 'OUT_OF_ORDER', 'NOT_IN_USE', 'MEDIUM',
 90, '2024-07-25', '주차장 입구 차단기 (고장)', 9, 1);

-- 자산 분류별 통계를 위한 추가 데이터
INSERT INTO bms.facility_assets (
    asset_code, asset_name, asset_category, asset_type, location, building_id, floor_number,
    asset_status, usage_status, importance_level, maintenance_cycle_days, created_by
) VALUES 
-- 추가 CCTV 카메라들
('SEC-003', 'CCTV 카메라 #1', '보안', 'CCTV', '1층 로비', 1, 1, 'NORMAL', 'IN_USE', 'LOW', 365, 1),
('SEC-004', 'CCTV 카메라 #2', '보안', 'CCTV', '지하1층 주차장', 1, -1, 'NORMAL', 'IN_USE', 'LOW', 365, 1),
('SEC-005', 'CCTV 카메라 #3', '보안', 'CCTV', '옥상', 1, 10, 'NORMAL', 'IN_USE', 'LOW', 365, 1),

-- 추가 조명 시설
('LIGHT-001', 'LED 조명 #1', '전기', '조명', '1층 복도', 1, 1, 'NORMAL', 'IN_USE', 'LOW', 730, 1),
('LIGHT-002', 'LED 조명 #2', '전기', '조명', '2층 복도', 1, 2, 'NORMAL', 'IN_USE', 'LOW', 730, 1),
('LIGHT-003', '비상조명', '전기', '조명', '계단실', 1, 1, 'NORMAL', 'IN_USE', 'MEDIUM', 365, 1),

-- 추가 소방 시설
('FIRE-003', '소화기 #1', '소방', '소화기', '1층 복도', 1, 1, 'NORMAL', 'IN_USE', 'MEDIUM', 365, 1),
('FIRE-004', '소화기 #2', '소방', '소화기', '2층 복도', 1, 2, 'NORMAL', 'IN_USE', 'MEDIUM', 365, 1),
('FIRE-005', '화재감지기', '소방', '감지설비', '1층 사무실', 1, 1, 'NORMAL', 'IN_USE', 'HIGH', 180, 1);

-- 통계 확인을 위한 쿼리 (주석)
/*
-- 자산 분류별 통계
SELECT asset_category, COUNT(*) as count 
FROM bms.facility_assets 
WHERE is_active = TRUE 
GROUP BY asset_category 
ORDER BY count DESC;

-- 자산 상태별 통계
SELECT asset_status, COUNT(*) as count 
FROM bms.facility_assets 
WHERE is_active = TRUE 
GROUP BY asset_status;

-- 중요도별 통계
SELECT importance_level, COUNT(*) as count 
FROM bms.facility_assets 
WHERE is_active = TRUE 
GROUP BY importance_level;

-- 보증 만료 예정 자산 (30일 이내)
SELECT asset_code, asset_name, warranty_end_date,
       DATEDIFF(warranty_end_date, CURDATE()) as days_until_expiry
FROM bms.facility_assets 
WHERE warranty_end_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 30 DAY)
AND is_active = TRUE
ORDER BY warranty_end_date;

-- 점검 필요 자산
SELECT asset_code, asset_name, next_maintenance_date,
       DATEDIFF(next_maintenance_date, CURDATE()) as days_until_maintenance
FROM bms.facility_assets 
WHERE next_maintenance_date <= CURDATE()
AND is_active = TRUE
ORDER BY next_maintenance_date;
*/