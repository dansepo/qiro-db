-- =====================================================
-- Material Master Management Test Data
-- Phase 4.4.1: Test Data for Material Master Management
-- =====================================================

-- Use existing company
SET app.current_company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f';

-- 1. Insert material categories
INSERT INTO bms.material_categories (
    company_id, category_code, category_name, category_description,
    category_level, requires_serial_number, requires_batch_tracking,
    expense_category, is_active
) VALUES 
-- Main categories
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ELEC', '전기자재', '전기 관련 자재 및 부품', 1, false, false, 'MAINTENANCE', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'PLUMB', '배관자재', '배관 및 급배수 관련 자재', 1, false, false, 'MAINTENANCE', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'HVAC', '냉난방자재', 'HVAC 시스템 관련 자재', 1, false, false, 'MAINTENANCE', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'LIGHT', '조명자재', '조명 및 전구 관련 자재', 1, false, false, 'MAINTENANCE', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'CLEAN', '청소용품', '청소 및 위생 관련 용품', 1, false, true, 'CLEANING', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'SAFE', '안전용품', '안전 및 보안 관련 용품', 1, true, false, 'SAFETY', true),

-- Sub categories
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ELEC-WIRE', '전선/케이블', '각종 전선 및 케이블', 2, false, false, 'MAINTENANCE', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ELEC-OUTLET', '콘센트/스위치', '콘센트 및 스위치류', 2, false, false, 'MAINTENANCE', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'PLUMB-PIPE', '파이프', '각종 배관 파이프', 2, false, false, 'MAINTENANCE', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'PLUMB-FITTING', '배관부속', '배관 연결 부속품', 2, false, false, 'MAINTENANCE', true);

-- Update parent relationships
UPDATE bms.material_categories 
SET parent_category_id = (SELECT category_id FROM bms.material_categories WHERE category_code = 'ELEC' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f')
WHERE category_code IN ('ELEC-WIRE', 'ELEC-OUTLET') AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f';

UPDATE bms.material_categories 
SET parent_category_id = (SELECT category_id FROM bms.material_categories WHERE category_code = 'PLUMB' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f')
WHERE category_code IN ('PLUMB-PIPE', 'PLUMB-FITTING') AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f';

-- 2. Insert material units
INSERT INTO bms.material_units (
    company_id, unit_code, unit_name, unit_description, unit_type,
    conversion_factor, precision_digits, symbol, is_active
) VALUES 
-- Basic units
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'EA', '개', '개수 단위', 'COUNT', 1.0, 0, 'ea', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'M', '미터', '길이 단위', 'LENGTH', 1.0, 2, 'm', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'KG', '킬로그램', '무게 단위', 'WEIGHT', 1.0, 3, 'kg', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'L', '리터', '부피 단위', 'VOLUME', 1.0, 2, 'L', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'BOX', '박스', '포장 단위', 'COUNT', 1.0, 0, 'box', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ROLL', '롤', '롤 단위', 'COUNT', 1.0, 0, 'roll', true),

-- Derived units
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'CM', '센티미터', '센티미터', 'LENGTH', 0.01, 1, 'cm', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'MM', '밀리미터', '밀리미터', 'LENGTH', 0.001, 0, 'mm', true),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'G', '그램', '그램', 'WEIGHT', 0.001, 1, 'g', true);

-- Update base unit relationships
UPDATE bms.material_units 
SET base_unit_id = (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f')
WHERE unit_code IN ('CM', 'MM') AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f';

UPDATE bms.material_units 
SET base_unit_id = (SELECT unit_id FROM bms.material_units WHERE unit_code = 'KG' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f')
WHERE unit_code = 'G' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f';

-- 3. Insert suppliers
INSERT INTO bms.suppliers (
    company_id, supplier_code, supplier_name, supplier_type,
    contact_person, phone_number, email, address_line1, city,
    business_category, payment_terms, lead_time_days, quality_rating,
    supplier_status, created_by
) VALUES 
-- Electrical suppliers
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ELEC001', '대한전기자재', 'DISTRIBUTOR', '김전기', '02-1234-5678', 'kim@electric.co.kr', '서울시 강남구 테헤란로 123', '서울', '전기자재', '월말 30일', 7, 8.5, 'ACTIVE', (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'ELEC002', '서울조명', 'MANUFACTURER', '이조명', '02-2345-6789', 'lee@lighting.co.kr', '서울시 마포구 월드컵로 456', '서울', '조명기구', '현금 즉시', 5, 9.0, 'ACTIVE', (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)),

-- Plumbing suppliers
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'PLUMB001', '한국배관', 'WHOLESALER', '박배관', '02-3456-7890', 'park@plumbing.co.kr', '서울시 영등포구 여의도로 789', '서울', '배관자재', '월말 45일', 10, 8.0, 'ACTIVE', (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)),
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'PLUMB002', '부산파이프', 'DISTRIBUTOR', '최파이프', '051-4567-8901', 'choi@pipe.co.kr', '부산시 해운대구 센텀로 101', '부산', '파이프', '현금 10일', 14, 7.5, 'ACTIVE', (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)),

-- Cleaning suppliers
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'CLEAN001', '청소나라', 'RETAILER', '정청소', '02-5678-9012', 'jung@clean.co.kr', '서울시 송파구 올림픽로 202', '서울', '청소용품', '현금 즉시', 3, 8.8, 'ACTIVE', (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)),

-- Safety suppliers
('7182f8fb-3065-4635-98cc-b1f85ba7fd2f', 'SAFE001', '안전제일', 'DISTRIBUTOR', '강안전', '02-6789-0123', 'kang@safety.co.kr', '서울시 구로구 디지털로 303', '서울', '안전용품', '월말 30일', 7, 9.2, 'ACTIVE', (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1));

-- 4. Insert materials
INSERT INTO bms.materials (
    company_id, material_code, material_name, material_description, category_id,
    material_type, brand, model_number, part_number, base_unit_id,
    standard_cost, minimum_stock_level, reorder_point, reorder_quantity,
    primary_supplier_id, lead_time_days, material_status, created_by
) VALUES 
-- Electrical materials
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    'ELEC-WIRE-001',
    '전선 2.5sq',
    '2.5mm² 단선 전선 (흑색)',
    (SELECT category_id FROM bms.material_categories WHERE category_code = 'ELEC-WIRE' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'COMPONENT',
    '대한전선',
    'DH-2.5SQ-BK',
    'DH25BK',
    (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    3000,
    100,
    50,
    200,
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'ELEC001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    7,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    'ELEC-OUTLET-001',
    '220V 콘센트',
    '220V 일반형 콘센트 (접지형)',
    (SELECT category_id FROM bms.material_categories WHERE category_code = 'ELEC-OUTLET' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'COMPONENT',
    '한국전기',
    'KE-220V-GND',
    'KE220G',
    (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    15000,
    20,
    10,
    50,
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'ELEC001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    7,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),

-- Lighting materials
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    'LIGHT-LED-001',
    'LED 조명 20W',
    '20W LED 직관형 조명 (주광색)',
    (SELECT category_id FROM bms.material_categories WHERE category_code = 'LIGHT' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'COMPONENT',
    '서울LED',
    'SL-LED-20W-DL',
    'SL20DL',
    (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    12000,
    50,
    25,
    100,
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'ELEC002' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    5,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),

-- Plumbing materials
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    'PLUMB-PIPE-001',
    'PVC 파이프 20mm',
    '20mm PVC 급수용 파이프',
    (SELECT category_id FROM bms.material_categories WHERE category_code = 'PLUMB-PIPE' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'RAW_MATERIAL',
    '한국파이프',
    'KP-PVC-20',
    'KP20',
    (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    8000,
    200,
    100,
    500,
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'PLUMB001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    10,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    'PLUMB-FITTING-001',
    'PVC 엘보 20mm',
    '20mm PVC 90도 엘보 조인트',
    (SELECT category_id FROM bms.material_categories WHERE category_code = 'PLUMB-FITTING' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    'COMPONENT',
    '한국파이프',
    'KP-ELBOW-20',
    'KPE20',
    (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    5000,
    100,
    50,
    200,
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'PLUMB001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    10,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- Script completion message
SELECT 'Material master management test data created successfully.' as message;-- 5. Ins
ert material supplier relationships
INSERT INTO bms.material_suppliers (
    company_id, material_id, supplier_id, supplier_priority, is_primary_supplier,
    unit_price, minimum_order_quantity, lead_time_days, payment_terms,
    quality_rating, delivery_performance, relationship_status, created_by
) VALUES 
-- Primary suppliers (already set in materials table)
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT material_id FROM bms.materials WHERE material_code = 'ELEC-WIRE-001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'ELEC001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    1,
    true,
    3000,
    100,
    7,
    '월말 30일',
    8.5,
    95.0,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT material_id FROM bms.materials WHERE material_code = 'ELEC-OUTLET-001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'ELEC001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    1,
    true,
    15000,
    10,
    7,
    '월말 30일',
    8.5,
    95.0,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT material_id FROM bms.materials WHERE material_code = 'LIGHT-LED-001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'ELEC002' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    1,
    true,
    12000,
    25,
    5,
    '현금 즉시',
    9.0,
    98.0,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),

-- Alternative suppliers
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT material_id FROM bms.materials WHERE material_code = 'ELEC-WIRE-001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'ELEC002' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    2,
    false,
    3200,
    50,
    5,
    '현금 즉시',
    9.0,
    98.0,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
),
(
    '7182f8fb-3065-4635-98cc-b1f85ba7fd2f',
    (SELECT material_id FROM bms.materials WHERE material_code = 'PLUMB-PIPE-001' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'PLUMB002' AND company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'),
    2,
    false,
    8500,
    100,
    14,
    '현금 10일',
    7.5,
    85.0,
    'ACTIVE',
    (SELECT user_id FROM bms.users WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f' LIMIT 1)
);

-- 6. Test basic queries
SELECT 'Testing material master management queries...' as test_step;

-- Get material categories
SELECT category_code, category_name, category_level, is_active
FROM bms.material_categories
WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY category_level, category_code;

-- Get material units
SELECT unit_code, unit_name, unit_type, conversion_factor, symbol
FROM bms.material_units
WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY unit_type, unit_code;

-- Get suppliers
SELECT supplier_code, supplier_name, supplier_type, contact_person, quality_rating
FROM bms.suppliers
WHERE company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY supplier_code;

-- Get materials with categories and suppliers
SELECT m.material_code, m.material_name, mc.category_name, m.material_type, 
       m.standard_cost, s.supplier_name as primary_supplier
FROM bms.materials m
LEFT JOIN bms.material_categories mc ON m.category_id = mc.category_id
LEFT JOIN bms.suppliers s ON m.primary_supplier_id = s.supplier_id
WHERE m.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY m.material_code;

-- Get material supplier relationships
SELECT m.material_code, s.supplier_name, ms.supplier_priority, 
       ms.is_primary_supplier, ms.unit_price, ms.relationship_status
FROM bms.material_suppliers ms
JOIN bms.materials m ON ms.material_id = m.material_id
JOIN bms.suppliers s ON ms.supplier_id = s.supplier_id
WHERE ms.company_id = '7182f8fb-3065-4635-98cc-b1f85ba7fd2f'
ORDER BY m.material_code, ms.supplier_priority;

-- Test function calls
SELECT 'Testing material master functions...' as test_step;

-- Test get_materials function
SELECT material_code, material_name, category_name, material_type, standard_cost
FROM bms.get_materials('7182f8fb-3065-4635-98cc-b1f85ba7fd2f'::UUID, 10, 0)
ORDER BY material_code;

-- Test get_suppliers function
SELECT supplier_code, supplier_name, supplier_type, quality_rating
FROM bms.get_suppliers('7182f8fb-3065-4635-98cc-b1f85ba7fd2f'::UUID, 10, 0)
ORDER BY supplier_code;

-- Test get_material_statistics function
SELECT total_materials, active_materials, suppliers_count, avg_material_cost
FROM bms.get_material_statistics('7182f8fb-3065-4635-98cc-b1f85ba7fd2f'::UUID);

-- Script completion message
SELECT 'Material master management test data and tests completed successfully.' as message;