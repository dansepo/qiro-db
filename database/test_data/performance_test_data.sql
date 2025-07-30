-- =====================================================
-- 성능 테스트용 대용량 데이터 생성 스크립트
-- 작성일: 2025-01-30
-- 설명: 성능 테스트를 위한 대용량 테스트 데이터 생성
-- =====================================================

-- 성능 테스트용 건물 생성 (10개)
INSERT INTO buildings (
    name, address, building_type, total_floors, basement_floors, total_area,
    construction_year, owner_name, owner_contact, management_company,
    status, created_by, updated_by
)
SELECT 
    '성능테스트빌딩' || i::text,
    '서울시 강남구 테헤란로 ' || (100 + i)::text,
    CASE (i % 4)
        WHEN 0 THEN 'COMMERCIAL'
        WHEN 1 THEN 'OFFICE'
        WHEN 2 THEN 'RESIDENTIAL'
        ELSE 'MIXED_USE'
    END,
    5 + (i % 15),  -- 5-20층
    1 + (i % 3),   -- 1-3층 지하
    1000.0 + (i * 500),  -- 1000-6000㎡
    2015 + (i % 10),  -- 2015-2024년
    '성능테스트소유자' || i::text,
    '010-' || LPAD((1000 + i)::text, 4, '0') || '-' || LPAD((i * 10)::text, 4, '0'),
    'QIRO 관리',
    'ACTIVE',
    1, 1
FROM generate_series(1, 10) as i;

COMMIT;-
- 성능 테스트용 호실 생성 (건물당 50개, 총 500개)
INSERT INTO units (
    building_id, unit_number, floor_number, unit_type, area, common_area,
    monthly_rent, deposit, maintenance_fee, status, room_count, bathroom_count,
    has_balcony, has_parking, created_by, updated_by
)
SELECT 
    ((i - 1) / 50) + (SELECT MIN(id) FROM buildings WHERE name LIKE '성능테스트빌딩%'),
    LPAD(((i - 1) % 50 + 1)::text, 3, '0'),
    ((i - 1) % 50) / 10 + 1,  -- 층수
    CASE ((i - 1) % 4)
        WHEN 0 THEN 'COMMERCIAL'
        WHEN 1 THEN 'OFFICE'
        WHEN 2 THEN 'RESIDENTIAL'
        ELSE 'RETAIL'
    END,
    30.0 + ((i % 100) * 0.5),  -- 30-80㎡
    5.0 + ((i % 20) * 0.5),    -- 5-15㎡
    800000 + ((i % 50) * 50000),  -- 80만-330만원
    8000000 + ((i % 50) * 500000), -- 800만-3300만원
    100000 + ((i % 30) * 10000),   -- 10만-40만원
    CASE (i % 5)
        WHEN 0 THEN 'AVAILABLE'
        WHEN 1 THEN 'MAINTENANCE'
        ELSE 'OCCUPIED'
    END,
    1 + (i % 5),  -- 1-5개 방
    1 + (i % 3),  -- 1-3개 화장실
    (i % 2) = 0,  -- 50% 발코니
    (i % 3) = 0,  -- 33% 주차
    1, 1
FROM generate_series(1, 500) as i;

COMMIT;-- 성능
 테스트용 임차인 생성 (300명)
INSERT INTO tenants (
    name, entity_type, business_registration_number, representative_name,
    primary_phone, email, current_address, occupation, monthly_income,
    family_members, is_active, privacy_consent, created_by, updated_by
)
SELECT 
    '성능테스트임차인' || i::text,
    CASE (i % 10)
        WHEN 0 THEN 'CORPORATION'
        ELSE 'INDIVIDUAL'
    END,
    CASE WHEN (i % 10) = 0 THEN 
        LPAD((100000000 + i)::text, 10, '0')
    ELSE NULL END,
    CASE WHEN (i % 10) = 0 THEN 
        '성능테스트대표' || i::text
    ELSE NULL END,
    '010-' || LPAD((2000 + i)::text, 4, '0') || '-' || LPAD((i * 13)::text, 4, '0'),
    'perf_tenant' || i::text || '@test.com',
    '서울시 강남구 테스트로 ' || i::text,
    CASE (i % 8)
        WHEN 0 THEN '회사원'
        WHEN 1 THEN '프리랜서'
        WHEN 2 THEN '의사'
        WHEN 3 THEN '변호사'
        WHEN 4 THEN '교사'
        WHEN 5 THEN '공무원'
        WHEN 6 THEN '사업자'
        ELSE '기타'
    END,
    2000000 + ((i % 50) * 100000),  -- 200만-700만원
    1 + (i % 5),  -- 1-5명 가족
    true, true, 1, 1
FROM generate_series(1, 300) as i;

COMMIT;-
- 성능 테스트용 임대 계약 생성 (300개)
INSERT INTO lease_contracts (
    contract_number, unit_id, tenant_id, lessor_id, start_date, end_date,
    monthly_rent, deposit, maintenance_fee, contract_type, status,
    created_by, updated_by
)
SELECT 
    'PERF' || LPAD(i::text, 6, '0'),
    (SELECT id FROM units WHERE building_id IN (SELECT id FROM buildings WHERE name LIKE '성능테스트빌딩%') 
     AND status = 'OCCUPIED' ORDER BY id LIMIT 1 OFFSET (i-1)),
    (SELECT id FROM tenants WHERE name LIKE '성능테스트임차인%' ORDER BY id LIMIT 1 OFFSET (i-1)),
    1,  -- 첫 번째 임대인
    '2024-01-01'::date + (i % 365),  -- 2024년 중 랜덤 시작일
    '2024-01-01'::date + (i % 365) + INTERVAL '2 years',  -- 2년 계약
    800000 + ((i % 50) * 50000),
    8000000 + ((i % 50) * 500000),
    100000 + ((i % 30) * 10000),
    'NEW',
    'ACTIVE',
    1, 1
FROM generate_series(1, 300) as i;

COMMIT;-- 성능
 테스트용 청구월 생성 (12개월 * 10개 건물 = 120개)
INSERT INTO billing_months (
    building_id, billing_year, billing_month, status, due_date,
    external_bill_input_completed, meter_reading_completed,
    created_by, updated_by
)
SELECT 
    b.id,
    2024,
    m.month_num,
    CASE 
        WHEN m.month_num <= 10 THEN 'CLOSED'
        WHEN m.month_num = 11 THEN 'INVOICED'
        ELSE 'CALCULATED'
    END,
    ('2024-' || LPAD(m.month_num::text, 2, '0') || '-05')::date,
    m.month_num <= 11,
    m.month_num <= 11,
    1, 1
FROM (SELECT id FROM buildings WHERE name LIKE '성능테스트빌딩%') b
CROSS JOIN (SELECT generate_series(1, 12) as month_num) m;

COMMIT;--
 성능 테스트용 고지서 생성 (대량 데이터 - 3000개)
INSERT INTO invoices (
    billing_month_id, unit_id, invoice_number, issue_date, due_date,
    subtotal_amount, tax_amount, status, created_by, updated_by
)
SELECT 
    bm.id,
    u.id,
    'PERF-' || b.name || '-' || bm.billing_year || '-' || LPAD(bm.billing_month::text, 2, '0') || '-' || LPAD(u.unit_number, 4, '0'),
    ('2024-' || LPAD(bm.billing_month::text, 2, '0') || '-25')::date,
    ('2024-' || LPAD(bm.billing_month::text, 2, '0') || '-05')::date + INTERVAL '1 month',
    150000 + ((u.id % 100) * 1000),  -- 15만-25만원
    15000 + ((u.id % 100) * 100),    -- 1.5만-2.5만원
    CASE 
        WHEN bm.billing_month <= 9 THEN 'PAID'
        WHEN bm.billing_month = 10 THEN 'PARTIAL_PAID'
        WHEN bm.billing_month = 11 THEN 'OVERDUE'
        ELSE 'ISSUED'
    END,
    1, 1
FROM billing_months bm
JOIN buildings b ON bm.building_id = b.id
JOIN units u ON b.id = u.building_id
WHERE b.name LIKE '성능테스트빌딩%'
  AND bm.billing_year = 2024
  AND u.status = 'OCCUPIED';

COMMIT;-
- 성능 테스트용 수납 데이터 생성 (2000개)
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
)
SELECT 
    i.id,
    i.due_date + INTERVAL '1 day' * (CASE 
        WHEN i.status = 'PAID' THEN -(random() * 5)::int
        WHEN i.status = 'PARTIAL_PAID' THEN (random() * 10)::int
        WHEN i.status = 'OVERDUE' THEN (random() * 30)::int + 10
        ELSE 0
    END),
    CASE 
        WHEN i.status = 'PAID' THEN i.subtotal_amount + i.tax_amount
        WHEN i.status = 'PARTIAL_PAID' THEN (i.subtotal_amount + i.tax_amount) * 0.7
        WHEN i.status = 'OVERDUE' THEN (i.subtotal_amount + i.tax_amount) * 0.3
        ELSE 0
    END,
    CASE ((i.id % 5))
        WHEN 0 THEN 'CASH'
        WHEN 1 THEN 'BANK_TRANSFER'
        WHEN 2 THEN 'CARD'
        WHEN 3 THEN 'CMS'
        ELSE 'VIRTUAL_ACCOUNT'
    END,
    'PERF' || LPAD(i.id::text, 8, '0'),
    '성능테스트 수납',
    'COMPLETED',
    1
FROM invoices i
WHERE i.invoice_number LIKE 'PERF-%'
  AND i.status IN ('PAID', 'PARTIAL_PAID', 'OVERDUE');

COMMIT;--
 성능 테스트 결과 확인
SELECT 
    '성능 테스트용 대용량 데이터 생성 완료' as message,
    (SELECT COUNT(*) FROM buildings WHERE name LIKE '성능테스트빌딩%') as test_buildings,
    (SELECT COUNT(*) FROM units WHERE building_id IN (SELECT id FROM buildings WHERE name LIKE '성능테스트빌딩%')) as test_units,
    (SELECT COUNT(*) FROM tenants WHERE name LIKE '성능테스트임차인%') as test_tenants,
    (SELECT COUNT(*) FROM lease_contracts WHERE contract_number LIKE 'PERF%') as test_contracts,
    (SELECT COUNT(*) FROM billing_months WHERE building_id IN (SELECT id FROM buildings WHERE name LIKE '성능테스트빌딩%')) as test_billing_months,
    (SELECT COUNT(*) FROM invoices WHERE invoice_number LIKE 'PERF-%') as test_invoices,
    (SELECT COUNT(*) FROM payments WHERE payment_reference LIKE 'PERF%') as test_payments;

-- 성능 테스트 쿼리 예시
-- 1. 건물별 월별 수납률 조회 (복잡한 집계 쿼리)
EXPLAIN ANALYZE
SELECT 
    b.name as building_name,
    bm.billing_year,
    bm.billing_month,
    COUNT(i.id) as total_invoices,
    COUNT(CASE WHEN i.status = 'PAID' THEN 1 END) as paid_invoices,
    SUM(i.subtotal_amount + i.tax_amount) as total_amount,
    SUM(COALESCE(p.amount, 0)) as collected_amount,
    ROUND(
        COUNT(CASE WHEN i.status = 'PAID' THEN 1 END)::DECIMAL / COUNT(i.id) * 100, 2
    ) as collection_rate
FROM buildings b
JOIN billing_months bm ON b.id = bm.building_id
JOIN invoices i ON bm.id = i.billing_month_id
LEFT JOIN payments p ON i.id = p.invoice_id AND p.payment_status = 'COMPLETED'
WHERE b.name LIKE '성능테스트빌딩%'
GROUP BY b.id, b.name, bm.billing_year, bm.billing_month
ORDER BY b.name, bm.billing_year, bm.billing_month;

COMMIT;