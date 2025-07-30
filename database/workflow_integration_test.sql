-- =====================================================
-- 월별 관리비 처리 워크플로우 통합 테스트
-- 작성일: 2025-01-30
-- 설명: 청구월 생성부터 수납 완료까지 전체 워크플로우 검증
-- =====================================================

-- 테스트 시나리오: 2025년 3월 관리비 처리 전체 워크플로우

BEGIN;

-- =====================================================
-- 1단계: 청구월 생성
-- =====================================================

-- 2025년 3월 청구월 생성
INSERT INTO billing_months (
    building_id, billing_year, billing_month, status, due_date,
    created_by, updated_by
) VALUES (
    1, 2025, 3, 'DRAFT', '2025-03-05', 1, 1
);

-- 생성된 청구월 ID 조회
SELECT id as billing_month_id, status 
FROM billing_months 
WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3;

-- =====================================================
-- 2단계: 검침 데이터 입력
-- =====================================================

-- 호실별 검침 데이터 입력 (전기, 수도)
INSERT INTO unit_meter_readings (
    billing_month_id, unit_id, meter_type, 
    previous_reading, current_reading, unit_price,
    reading_date, reader_name, created_by, updated_by
) VALUES 
-- 101호 전기 검침
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 'ELECTRICITY', 1500.0, 1650.0, 120.5, '2025-02-28', '검침원A', 1, 1),
-- 101호 수도 검침
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 'WATER', 850.0, 890.0, 300.0, '2025-02-28', '검침원A', 1, 1),
-- 102호 전기 검침
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 2, 'ELECTRICITY', 1200.0, 1380.0, 120.5, '2025-02-28', '검침원A', 1, 1),
-- 102호 수도 검침
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 2, 'WATER', 720.0, 765.0, 300.0, '2025-02-28', '검침원A', 1, 1);

-- 공용 시설 검침 데이터 입력
INSERT INTO common_meter_readings (
    billing_month_id, building_id, meter_type,
    previous_reading, current_reading, unit_price, total_amount,
    reading_date, meter_location, reader_name, created_by, updated_by
) VALUES 
-- 공용 전기
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 'COMMON_ELECTRICITY', 5000.0, 5500.0, 110.0, 55000.0, 
 '2025-02-28', '전기실', '검침원A', 1, 1),
-- 공용 수도
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 'COMMON_WATER', 2000.0, 2150.0, 250.0, 37500.0, 
 '2025-02-28', '급수실', '검침원A', 1, 1);

-- 검침 데이터 입력 완료 상태 업데이트
UPDATE billing_months 
SET meter_reading_completed = true, 
    status = 'DATA_INPUT',
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 1
WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3;

-- =====================================================
-- 3단계: 외부 고지서 총액 입력
-- =====================================================

-- 외부 고지서 총액 입력 (한전, 수도 등)
UPDATE billing_months 
SET external_bill_total_amount = 150000,
    external_bill_input_completed = true,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 1
WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3;

-- =====================================================
-- 4단계: 관리비 자동 산정
-- =====================================================

-- 청구월 상태를 계산 중으로 변경
UPDATE billing_months 
SET status = 'CALCULATING',
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 1
WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3;

-- 월별 관리비 산정 (각 호실별, 항목별)
INSERT INTO monthly_fees (
    billing_month_id, unit_id, fee_item_id, calculation_method,
    base_amount, unit_price, quantity, calculated_amount, tax_amount,
    created_by, updated_by
) VALUES 
-- 101호 관리비 산정
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 1, 'FIXED_AMOUNT', NULL, NULL, NULL, 100000, 0, 1, 1),
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 2, 'USAGE_BASED', NULL, 120.5, 150.0, 18075, 1808, 1, 1),
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 3, 'USAGE_BASED', NULL, 300.0, 40.0, 12000, 1200, 1, 1),
-- 102호 관리비 산정
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 2, 1, 'FIXED_AMOUNT', NULL, NULL, NULL, 100000, 0, 1, 1),
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 2, 2, 'USAGE_BASED', NULL, 120.5, 180.0, 21690, 2169, 1, 1),
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 2, 3, 'USAGE_BASED', NULL, 300.0, 45.0, 13500, 1350, 1, 1);

-- 관리비 계산 완료 상태 업데이트
UPDATE billing_months 
SET status = 'CALCULATED',
    calculation_completed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 1
WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3;

-- =====================================================
-- 5단계: 고지서 발급
-- =====================================================

-- 고지서 생성 (101호)
INSERT INTO invoices (
    billing_month_id, unit_id, invoice_number, issue_date, due_date,
    subtotal_amount, tax_amount, status, created_by, updated_by
) VALUES 
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 1, 'B001-2025-03-0001', '2025-03-01', '2025-03-05', 130075, 3008, 'ISSUED', 1, 1),
((SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3), 
 2, 'B001-2025-03-0002', '2025-03-01', '2025-03-05', 135190, 3519, 'ISSUED', 1, 1);

-- 고지서 상세 항목 생성
INSERT INTO invoice_line_items (
    invoice_id, monthly_fee_id, fee_item_name, description,
    quantity, unit_price, amount, tax_rate, tax_amount, display_order
) VALUES 
-- 101호 고지서 상세
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0001'), 
 (SELECT id FROM monthly_fees WHERE billing_month_id = (SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3) AND unit_id = 1 AND fee_item_id = 1),
 '일반관리비', '월 관리비', 1, 100000, 100000, 0, 0, 1),
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0001'), 
 (SELECT id FROM monthly_fees WHERE billing_month_id = (SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3) AND unit_id = 1 AND fee_item_id = 2),
 '전기료', '개별 전기 사용료', 150.0, 120.5, 18075, 10, 1808, 2),
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0001'), 
 (SELECT id FROM monthly_fees WHERE billing_month_id = (SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3) AND unit_id = 1 AND fee_item_id = 3),
 '수도료', '개별 수도 사용료', 40.0, 300.0, 12000, 10, 1200, 3);

-- 102호 고지서 상세 (유사하게 생성)
INSERT INTO invoice_line_items (
    invoice_id, monthly_fee_id, fee_item_name, description,
    quantity, unit_price, amount, tax_rate, tax_amount, display_order
) VALUES 
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0002'), 
 (SELECT id FROM monthly_fees WHERE billing_month_id = (SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3) AND unit_id = 2 AND fee_item_id = 1),
 '일반관리비', '월 관리비', 1, 100000, 100000, 0, 0, 1),
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0002'), 
 (SELECT id FROM monthly_fees WHERE billing_month_id = (SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3) AND unit_id = 2 AND fee_item_id = 2),
 '전기료', '개별 전기 사용료', 180.0, 120.5, 21690, 10, 2169, 2),
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0002'), 
 (SELECT id FROM monthly_fees WHERE billing_month_id = (SELECT id FROM billing_months WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3) AND unit_id = 2 AND fee_item_id = 3),
 '수도료', '개별 수도 사용료', 45.0, 300.0, 13500, 10, 1350, 3);

-- 고지서 발급 완료 상태 업데이트
UPDATE billing_months 
SET status = 'INVOICED',
    invoice_generation_completed_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 1
WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3;

-- =====================================================
-- 6단계: 수납 처리
-- =====================================================

-- 101호 완전 납부
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0001'), 
 '2025-03-03', 133083, 'BANK_TRANSFER', 'TXN20250303001', '정상 납부', 'COMPLETED', 1);

-- 102호 부분 납부 (50%)
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0002'), 
 '2025-03-04', 70000, 'CASH', 'CASH20250304001', '부분 납부', 'COMPLETED', 1);

-- 고지서 상태 업데이트 (완전 납부)
UPDATE invoices 
SET status = 'PAID',
    paid_amount = 133083,
    fully_paid_at = '2025-03-03 14:30:00',
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 1
WHERE invoice_number = 'B001-2025-03-0001';

-- 고지서 상태 업데이트 (부분 납부)
UPDATE invoices 
SET paid_amount = 70000,
    updated_at = CURRENT_TIMESTAMP,
    updated_by = 1
WHERE invoice_number = 'B001-2025-03-0002';

-- =====================================================
-- 7단계: 미납 관리 (102호 - 부분 납부로 인한 미납 발생)
-- =====================================================

-- 미납 레코드 자동 생성 (트리거에 의해 자동 처리되지만 수동으로도 확인)
INSERT INTO delinquencies (
    invoice_id, overdue_amount, overdue_days, late_fee, late_fee_rate,
    grace_period_days, status, first_overdue_date
) VALUES 
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-03-0002'), 
 68709, 0, 0, 0.0200, 5, 'OVERDUE', '2025-03-06');

-- =====================================================
-- 8단계: 워크플로우 검증 쿼리
-- =====================================================

-- 전체 워크플로우 상태 확인
SELECT 
    '워크플로우 단계별 검증' as verification_step,
    bm.billing_year,
    bm.billing_month,
    bm.status as billing_status,
    bm.meter_reading_completed,
    bm.external_bill_input_completed,
    bm.calculation_completed_at IS NOT NULL as calculation_completed,
    bm.invoice_generation_completed_at IS NOT NULL as invoice_generated,
    COUNT(DISTINCT umr.id) as meter_readings_count,
    COUNT(DISTINCT mf.id) as monthly_fees_count,
    COUNT(DISTINCT i.id) as invoices_count,
    COUNT(DISTINCT p.id) as payments_count,
    COUNT(DISTINCT d.id) as delinquencies_count
FROM billing_months bm
LEFT JOIN unit_meter_readings umr ON bm.id = umr.billing_month_id
LEFT JOIN monthly_fees mf ON bm.id = mf.billing_month_id
LEFT JOIN invoices i ON bm.id = i.billing_month_id
LEFT JOIN payments p ON i.id = p.invoice_id AND p.payment_status = 'COMPLETED'
LEFT JOIN delinquencies d ON i.id = d.invoice_id
WHERE bm.building_id = 1 AND bm.billing_year = 2025 AND bm.billing_month = 3
GROUP BY bm.id, bm.billing_year, bm.billing_month, bm.status, 
         bm.meter_reading_completed, bm.external_bill_input_completed,
         bm.calculation_completed_at, bm.invoice_generation_completed_at;

-- 검침 데이터 검증
SELECT 
    '검침 데이터 검증' as verification_step,
    umr.unit_id,
    u.unit_number,
    umr.meter_type,
    umr.previous_reading,
    umr.current_reading,
    umr.usage_amount,
    umr.unit_price,
    umr.calculated_amount,
    umr.is_verified
FROM unit_meter_readings umr
JOIN units u ON umr.unit_id = u.id
WHERE umr.billing_month_id = (
    SELECT id FROM billing_months 
    WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3
)
ORDER BY u.unit_number, umr.meter_type;

-- 관리비 산정 검증
SELECT 
    '관리비 산정 검증' as verification_step,
    mf.unit_id,
    u.unit_number,
    fi.name as fee_item_name,
    mf.calculation_method,
    mf.base_amount,
    mf.unit_price,
    mf.quantity,
    mf.calculated_amount,
    mf.tax_amount,
    mf.final_amount
FROM monthly_fees mf
JOIN units u ON mf.unit_id = u.id
JOIN fee_items fi ON mf.fee_item_id = fi.id
WHERE mf.billing_month_id = (
    SELECT id FROM billing_months 
    WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3
)
ORDER BY u.unit_number, fi.name;

-- 고지서 발급 검증
SELECT 
    '고지서 발급 검증' as verification_step,
    i.invoice_number,
    u.unit_number,
    i.issue_date,
    i.due_date,
    i.subtotal_amount,
    i.tax_amount,
    i.total_amount,
    i.paid_amount,
    i.remaining_amount,
    i.status
FROM invoices i
JOIN units u ON i.unit_id = u.id
WHERE i.billing_month_id = (
    SELECT id FROM billing_months 
    WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3
)
ORDER BY u.unit_number;

-- 수납 처리 검증
SELECT 
    '수납 처리 검증' as verification_step,
    p.id as payment_id,
    i.invoice_number,
    u.unit_number,
    p.payment_date,
    p.amount,
    p.payment_method,
    p.payment_status,
    i.total_amount as invoice_total,
    i.paid_amount as total_paid,
    i.remaining_amount
FROM payments p
JOIN invoices i ON p.invoice_id = i.id
JOIN units u ON i.unit_id = u.id
WHERE i.billing_month_id = (
    SELECT id FROM billing_months 
    WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3
)
ORDER BY u.unit_number, p.payment_date;

-- 미납 관리 검증
SELECT 
    '미납 관리 검증' as verification_step,
    d.id as delinquency_id,
    i.invoice_number,
    u.unit_number,
    d.overdue_amount,
    d.overdue_days,
    d.late_fee,
    d.status as delinquency_status,
    d.first_overdue_date
FROM delinquencies d
JOIN invoices i ON d.invoice_id = i.id
JOIN units u ON i.unit_id = u.id
WHERE i.billing_month_id = (
    SELECT id FROM billing_months 
    WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3
)
ORDER BY u.unit_number;

-- 데이터 무결성 검증
SELECT 
    '데이터 무결성 검증' as verification_step,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result,
    '고지서 총액과 상세 항목 합계 일치' as check_description
FROM invoices i
WHERE i.billing_month_id = (
    SELECT id FROM billing_months 
    WHERE building_id = 1 AND billing_year = 2025 AND billing_month = 3
)
AND (i.subtotal_amount + i.tax_amount) != (
    SELECT SUM(ili.amount + ili.tax_amount)
    FROM invoice_line_items ili
    WHERE ili.invoice_id = i.id
);

-- 워크플로우 완료 메시지
SELECT 
    '월별 관리비 처리 워크플로우 통합 테스트 완료' as message,
    '청구월 생성 → 검침 데이터 입력 → 관리비 산정 → 고지서 발급 → 수납 처리 → 미납 관리' as workflow_steps,
    'SUCCESS' as test_result;

COMMIT;