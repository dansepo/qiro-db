-- =====================================================
-- Inventory Management Test Data
-- Phase 4.4.2: Sample data for inventory management system
-- =====================================================

-- Set company context for testing
SET app.current_company_id = 'c1234567-89ab-cdef-0123-456789abcdef';

-- 1. Insert inventory locations
INSERT INTO bms.inventory_locations (
    company_id, location_code, location_name, location_description, location_type,
    floor_level, room_number, area_size, capacity_volume, capacity_weight,
    location_manager_id, location_status
) VALUES 
-- Main warehouse
('c1234567-89ab-cdef-0123-456789abcdef', 'WH-001', '메인 창고', '건물 관리 자재 메인 창고', 'WAREHOUSE', 
 1, 'B101', 500.00, 2000.000, 10000.000, 
 'u1234567-89ab-cdef-0123-456789abcdef', 'ACTIVE'),

-- Storage rooms
('c1234567-89ab-cdef-0123-456789abcdef', 'SR-001', '전기 자재실', '전기 관련 자재 보관실', 'STORAGE_ROOM', 
 1, '101', 50.00, 200.000, 1000.000, 
 'u1234567-89ab-cdef-0123-456789abcdef', 'ACTIVE'),

('c1234567-89ab-cdef-0123-456789abcdef', 'SR-002', '배관 자재실', '배관 관련 자재 보관실', 'STORAGE_ROOM', 
 1, '102', 60.00, 250.000, 1500.000, 
 'u1234567-89ab-cdef-0123-456789abcdef', 'ACTIVE'),

('c1234567-89ab-cdef-0123-456789abcdef', 'SR-003', '청소 용품실', '청소 및 위생 용품 보관실', 'STORAGE_ROOM', 
 2, '201', 30.00, 100.000, 500.000, 
 'u1234567-89ab-cdef-0123-456789abcdef', 'ACTIVE'),

-- Cabinets and shelves
('c1234567-89ab-cdef-0123-456789abcdef', 'CAB-001', '소형 부품 캐비닛', '소형 전기 부품 보관 캐비닛', 'CABINET', 
 1, '101', 2.00, 5.000, 50.000, 
 'u1234567-89ab-cdef-0123-456789abcdef', 'ACTIVE'),

('c1234567-89ab-cdef-0123-456789abcdef', 'SH-001', '도구 선반', '수공구 및 소형 장비 선반', 'SHELF', 
 1, '101', 10.00, 20.000, 200.000, 
 'u1234567-89ab-cdef-0123-456789abcdef', 'ACTIVE'),

-- Outdoor yard
('c1234567-89ab-cdef-0123-456789abcdef', 'YD-001', '야외 보관소', '대형 자재 야외 보관 구역', 'YARD', 
 0, 'YARD-A', 1000.00, 5000.000, 50000.000, 
 'u1234567-89ab-cdef-0123-456789abcdef', 'ACTIVE');

-- 2. Insert initial inventory balances
INSERT INTO bms.inventory_balances (
    company_id, material_id, location_id, unit_id,
    current_quantity, available_quantity, good_quantity,
    average_unit_cost, total_value,
    minimum_quantity, maximum_quantity, reorder_point, reorder_quantity
) VALUES 
-- LED 전구 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 150.000000, 150.000000, 150.000000, 15000.00, 2250000.00,
 50.000000, 500.000000, 100.000000, 200.000000),

-- 형광등 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'FL-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 80.000000, 80.000000, 80.000000, 25000.00, 2000000.00,
 30.000000, 200.000000, 50.000000, 100.000000),

-- 전선 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'WIRE-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
 500.000000, 500.000000, 500.000000, 3000.00, 1500000.00,
 100.000000, 1000.000000, 200.000000, 300.000000),

-- PVC 파이프 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'PIPE-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
 200.000000, 200.000000, 200.000000, 8000.00, 1600000.00,
 50.000000, 500.000000, 100.000000, 150.000000),

-- 배관 피팅 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'FIT-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 100.000000, 100.000000, 100.000000, 5000.00, 500000.00,
 20.000000, 200.000000, 40.000000, 80.000000),

-- 청소용 세제 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'CLEAN-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-003'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'L'),
 50.000000, 50.000000, 50.000000, 12000.00, 600000.00,
 10.000000, 100.000000, 20.000000, 30.000000),

-- 화장지 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'TISSUE-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-003'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'ROLL'),
 200.000000, 200.000000, 200.000000, 1500.00, 300000.00,
 50.000000, 500.000000, 100.000000, 200.000000),

-- 드릴 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'DRILL-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SH-001'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 5.000000, 5.000000, 5.000000, 150000.00, 750000.00,
 2.000000, 10.000000, 3.000000, 5.000000),

-- 렌치 세트 재고
('c1234567-89ab-cdef-0123-456789abcdef', 
 (SELECT material_id FROM bms.materials WHERE material_code = 'WRENCH-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SH-001'),
 (SELECT unit_id FROM bms.material_units WHERE unit_code = 'SET'),
 8.000000, 8.000000, 8.000000, 80000.00, 640000.00,
 3.000000, 15.000000, 5.000000, 7.000000);

-- 3. Insert sample inventory transactions
INSERT INTO bms.inventory_transactions (
    company_id, transaction_number, transaction_type, transaction_date,
    material_id, location_id, quantity, unit_id,
    unit_cost, total_cost, batch_number,
    reference_type, reference_number,
    transaction_reason, transaction_notes,
    supplier_id, created_by
) VALUES 
-- LED 전구 입고
('c1234567-89ab-cdef-0123-456789abcdef', 'REC-20241201-001', 'RECEIPT', '2024-12-01 09:00:00+09',
 (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 100.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 15000.00, 1500000.00, 'LED-2024120101',
 'PURCHASE_ORDER', 'PO-2024-001',
 '정기 보충', 'LED 전구 정기 입고',
 (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'SUP-001'),
 'u1234567-89ab-cdef-0123-456789abcdef'),

-- 형광등 입고
('c1234567-89ab-cdef-0123-456789abcdef', 'REC-20241201-002', 'RECEIPT', '2024-12-01 10:30:00+09',
 (SELECT material_id FROM bms.materials WHERE material_code = 'FL-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 50.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 25000.00, 1250000.00, 'FL-2024120101',
 'PURCHASE_ORDER', 'PO-2024-002',
 '정기 보충', '형광등 정기 입고',
 (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'SUP-001'),
 'u1234567-89ab-cdef-0123-456789abcdef'),

-- LED 전구 출고 (작업 지시서)
('c1234567-89ab-cdef-0123-456789abcdef', 'ISS-20241202-001', 'ISSUE', '2024-12-02 14:00:00+09',
 (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 -20.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 15000.00, 300000.00, 'LED-2024120101',
 'WORK_ORDER', 'WO-2024-001',
 '조명 교체 작업', '1층 복도 LED 전구 교체',
 NULL, 'u1234567-89ab-cdef-0123-456789abcdef'),

-- 전선 출고 (유지보수)
('c1234567-89ab-cdef-0123-456789abcdef', 'ISS-20241203-001', 'ISSUE', '2024-12-03 11:00:00+09',
 (SELECT material_id FROM bms.materials WHERE material_code = 'WIRE-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 -50.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
 3000.00, 150000.00, NULL,
 'MAINTENANCE_REQUEST', 'MR-2024-001',
 '전기 배선 수리', '지하 전기실 배선 교체',
 NULL, 'u1234567-89ab-cdef-0123-456789abcdef'),

-- PVC 파이프 출고
('c1234567-89ab-cdef-0123-456789abcdef', 'ISS-20241204-001', 'ISSUE', '2024-12-04 15:30:00+09',
 (SELECT material_id FROM bms.materials WHERE material_code = 'PIPE-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002'),
 -30.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
 8000.00, 240000.00, NULL,
 'WORK_ORDER', 'WO-2024-002',
 '배관 수리', '화장실 급수관 교체',
 NULL, 'u1234567-89ab-cdef-0123-456789abcdef'),

-- 청소용 세제 출고
('c1234567-89ab-cdef-0123-456789abcdef', 'ISS-20241205-001', 'ISSUE', '2024-12-05 09:00:00+09',
 (SELECT material_id FROM bms.materials WHERE material_code = 'CLEAN-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-003'),
 -10.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'L'),
 12000.00, 120000.00, NULL,
 'DEPARTMENT', 'CLEAN-DEPT',
 '정기 청소', '월간 정기 청소용',
 NULL, 'u1234567-89ab-cdef-0123-456789abcdef'),

-- 재고 조정 (손상품 처리)
('c1234567-89ab-cdef-0123-456789abcdef', 'ADJ-20241206-001', 'ADJUSTMENT', '2024-12-06 16:00:00+09',
 (SELECT material_id FROM bms.materials WHERE material_code = 'FL-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 -5.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 25000.00, 125000.00, NULL,
 'STOCK_ADJUSTMENT', 'ADJ-2024-001',
 '손상품 처리', '운송 중 파손된 형광등 처리',
 NULL, 'u1234567-89ab-cdef-0123-456789abcdef');

-- 4. Insert inventory reservations
INSERT INTO bms.inventory_reservations (
    company_id, reservation_number, reservation_type,
    material_id, location_id, reserved_quantity, unit_id,
    reserved_for_type, reserved_for_id, reserved_for_reference,
    reservation_date, required_date,
    priority_level, reservation_notes,
    requested_by, created_by
) VALUES 
-- LED 전구 예약 (예정된 작업)
('c1234567-89ab-cdef-0123-456789abcdef', 'RSV-20241207-001', 'PLANNED',
 (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 30.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
 'WORK_ORDER', NULL, 'WO-2024-003',
 '2024-12-07 10:00:00+09', '2024-12-10 09:00:00+09',
 'NORMAL', '2층 사무실 조명 교체 예정',
 'u1234567-89ab-cdef-0123-456789abcdef', 'u1234567-89ab-cdef-0123-456789abcdef'),

-- 전선 예약 (긴급 수리)
('c1234567-89ab-cdef-0123-456789abcdef', 'RSV-20241207-002', 'EMERGENCY',
 (SELECT material_id FROM bms.materials WHERE material_code = 'WIRE-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 100.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
 'MAINTENANCE_REQUEST', NULL, 'MR-2024-002',
 '2024-12-07 14:00:00+09', '2024-12-08 08:00:00+09',
 'URGENT', '엘리베이터 전기 시스템 긴급 수리',
 'u1234567-89ab-cdef-0123-456789abcdef', 'u1234567-89ab-cdef-0123-456789abcdef'),

-- PVC 파이프 예약 (프로젝트)
('c1234567-89ab-cdef-0123-456789abcdef', 'RSV-20241207-003', 'PROJECT',
 (SELECT material_id FROM bms.materials WHERE material_code = 'PIPE-001'),
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002'),
 80.000000, (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
 'PROJECT', NULL, 'PROJ-2024-001',
 '2024-12-07 16:00:00+09', '2024-12-15 09:00:00+09',
 'HIGH', '신규 화장실 설치 프로젝트',
 'u1234567-89ab-cdef-0123-456789abcdef', 'u1234567-89ab-cdef-0123-456789abcdef');

-- 5. Create cycle count
INSERT INTO bms.inventory_cycle_counts (
    company_id, count_number, count_name, count_type,
    location_id, scheduled_date, start_date,
    count_method, primary_counter_id, supervisor_id,
    count_instructions, count_status,
    created_by
) VALUES 
-- 전기 자재실 순환 재고 조사
('c1234567-89ab-cdef-0123-456789abcdef', 'CC-20241208-001', '전기 자재실 월간 재고조사', 'CYCLE_COUNT',
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001'),
 '2024-12-08', '2024-12-08 09:00:00+09',
 'MANUAL', 'u1234567-89ab-cdef-0123-456789abcdef', 'u1234567-89ab-cdef-0123-456789abcdef',
 '모든 전기 자재의 실제 수량을 확인하고 시스템 수량과 비교하세요.', 'IN_PROGRESS',
 'u1234567-89ab-cdef-0123-456789abcdef'),

-- 배관 자재실 순환 재고 조사
('c1234567-89ab-cdef-0123-456789abcdef', 'CC-20241209-001', '배관 자재실 월간 재고조사', 'CYCLE_COUNT',
 (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002'),
 '2024-12-09', NULL,
 'MANUAL', 'u1234567-89ab-cdef-0123-456789abcdef', 'u1234567-89ab-cdef-0123-456789abcdef',
 '배관 관련 자재의 실제 수량을 확인하고 손상품이 있는지 점검하세요.', 'PLANNED',
 'u1234567-89ab-cdef-0123-456789abcdef');

-- Update inventory balances to reflect transactions and reservations
UPDATE bms.inventory_balances 
SET 
    current_quantity = 230.000000,  -- 150 + 100 - 20
    available_quantity = 200.000000, -- 230 - 30 (reserved)
    reserved_quantity = 30.000000,
    total_value = 3450000.00,  -- Updated based on transactions
    last_receipt_date = '2024-12-01 09:00:00+09',
    last_issue_date = '2024-12-02 14:00:00+09',
    updated_at = NOW()
WHERE material_id = (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001')
  AND location_id = (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001');

UPDATE bms.inventory_balances 
SET 
    current_quantity = 125.000000,  -- 80 + 50 - 5
    available_quantity = 125.000000,
    total_value = 3125000.00,
    last_receipt_date = '2024-12-01 10:30:00+09',
    updated_at = NOW()
WHERE material_id = (SELECT material_id FROM bms.materials WHERE material_code = 'FL-001')
  AND location_id = (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001');

UPDATE bms.inventory_balances 
SET 
    current_quantity = 450.000000,  -- 500 - 50
    available_quantity = 350.000000, -- 450 - 100 (reserved)
    reserved_quantity = 100.000000,
    total_value = 1350000.00,
    last_issue_date = '2024-12-03 11:00:00+09',
    updated_at = NOW()
WHERE material_id = (SELECT material_id FROM bms.materials WHERE material_code = 'WIRE-001')
  AND location_id = (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001');

UPDATE bms.inventory_balances 
SET 
    current_quantity = 170.000000,  -- 200 - 30
    available_quantity = 90.000000,  -- 170 - 80 (reserved)
    reserved_quantity = 80.000000,
    total_value = 1360000.00,
    last_issue_date = '2024-12-04 15:30:00+09',
    updated_at = NOW()
WHERE material_id = (SELECT material_id FROM bms.materials WHERE material_code = 'PIPE-001')
  AND location_id = (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002');

UPDATE bms.inventory_balances 
SET 
    current_quantity = 40.000000,  -- 50 - 10
    available_quantity = 40.000000,
    total_value = 480000.00,
    last_issue_date = '2024-12-05 09:00:00+09',
    needs_reorder = true,  -- Below reorder point of 20
    updated_at = NOW()
WHERE material_id = (SELECT material_id FROM bms.materials WHERE material_code = 'CLEAN-001')
  AND location_id = (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-003');

-- Script completion message
SELECT 'Inventory Management test data inserted successfully!' as status,
       COUNT(*) as locations_count
FROM bms.inventory_locations 
WHERE company_id = 'c1234567-89ab-cdef-0123-456789abcdef';