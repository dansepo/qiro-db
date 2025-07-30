-- =====================================================
-- 수납 및 미납 관리 테스트 데이터
-- 작성일: 2025-01-30
-- 설명: 다양한 수납 시나리오 및 미납 관리 테스트 데이터
-- =====================================================

-- 테스트 시나리오별 데이터 생성

-- =====================================================
-- 1. 정상 수납 시나리오 테스트 데이터
-- =====================================================

-- 완전 납부 케이스
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
-- 기존 고지서에 대한 완전 납부
(1, '2025-02-03', 263758, 'BANK_TRANSFER', 'TXN20250203001', '정상 완전 납부', 'COMPLETED', 1),
(2, '2025-02-05', 299909, 'VIRTUAL_ACCOUNT', 'VA20250205001', '가상계좌 완전 납부', 'COMPLETED', 1);

-- 수납 상세 내역 (완전 납부)
INSERT INTO payment_details (payment_id, fee_item_id, allocated_amount, is_late_fee) VALUES
-- 첫 번째 완전 납부 상세
(1, 1, 100500, false),  -- 일반관리비
(1, 2, 50250, false),   -- 청소비
(1, 3, 50000, false),   -- 보안비
(1, 4, 30000, false),   -- 승강기유지비
(1, 5, 18075, false),   -- 전기료
(1, 6, 12000, false),   -- 수도료
(1, NULL, 1808, true),  -- 전기료 부가세
(1, NULL, 1200, true),  -- 수도료 부가세
-- 두 번째 완전 납부 상세
(2, 7, 120200, false),  -- 일반관리비
(2, 8, 60100, false),   -- 청소비
(2, 9, 50000, false),   -- 보안비
(2, 10, 30000, false),  -- 승강기유지비
(2, 11, 21690, false),  -- 전기료
(2, 12, 14400, false),  -- 수도료
(2, NULL, 2169, true),  -- 전기료 부가세
(2, NULL, 1440, true);  -- 수도료 부가세

-- =====================================================
-- 2. 부분 수납 시나리오 테스트 데이터
-- =====================================================

-- 부분 수납 케이스 (우선순위 적용)
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
-- 50% 부분 납부
(3, '2025-02-10', 150000, 'CASH', 'CASH20250210001', '부분 납부 (50%)', 'COMPLETED', 1),
-- 30% 부분 납부
(4, '2025-02-12', 100000, 'CARD', 'CARD20250212001', '부분 납부 (30%)', 'COMPLETED', 1);

-- 부분 수납 상세 내역 (우선순위: 관리비 > 공과금 > 부가세)
INSERT INTO payment_details (payment_id, fee_item_id, allocated_amount, is_late_fee) VALUES
-- 첫 번째 부분 납부 (관리비 우선 배분)
(3, (SELECT id FROM fee_items WHERE name = '일반관리비' AND building_id = 1 LIMIT 1), 100000, false),
(3, (SELECT id FROM fee_items WHERE name = '청소비' AND building_id = 1 LIMIT 1), 50000, false),
-- 두 번째 부분 납부 (관리비 우선 배분)
(4, (SELECT id FROM fee_items WHERE name = '일반관리비' AND building_id = 1 LIMIT 1), 80000, false),
(4, (SELECT id FROM fee_items WHERE name = '청소비' AND building_id = 1 LIMIT 1), 20000, false);

-- =====================================================
-- 3. 연체 및 연체료 시나리오 테스트 데이터
-- =====================================================

-- 연체 발생 케이스 (납부기한 경과)
INSERT INTO invoices (
    billing_month_id, unit_id, invoice_number, issue_date, due_date,
    subtotal_amount, tax_amount, status, created_by, updated_by
) VALUES 
-- 연체 고지서 (30일 경과)
(2, 4, 'B001-2025-01-0005', '2025-01-30', '2025-02-05', 180000, 18000, 'OVERDUE', 1, 1),
-- 연체 고지서 (15일 경과)
(2, 5, 'B001-2025-01-0006', '2025-01-30', '2025-02-05', 220000, 22000, 'OVERDUE', 1, 1);

-- 연체 관리 데이터
INSERT INTO delinquencies (
    invoice_id, overdue_amount, overdue_start_date, overdue_days,
    late_fee_rate, calculated_late_fee, applied_late_fee, is_resolved, created_by, updated_by
) VALUES 
-- 30일 연체 (연체료 적용)
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-01-0005'), 198000, '2025-02-06', 30, 0.0200, 3960, 3960, false, 1, 1),
-- 15일 연체 (유예기간 내)
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-01-0006'), 242000, '2025-02-06', 15, 0.0200, 0, 0, false, 1, 1);

-- =====================================================
-- 4. 다양한 결제 수단 테스트 데이터
-- =====================================================

-- 현금 수납
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(3, '2025-02-08', 263758, 'CASH', 'CASH20250208001', '현금 수납', 'COMPLETED', 1);

-- 카드 수납
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(4, '2025-02-09', 299909, 'CARD', 'CARD20250209001', '신용카드 수납', 'COMPLETED', 1);

-- 계좌이체 수납
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(5, '2025-02-11', 198000, 'BANK_TRANSFER', 'TXN20250211001', '계좌이체 수납', 'COMPLETED', 1);

-- CMS 자동이체 수납
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(6, '2025-02-05', 242000, 'CMS', 'CMS20250205001', 'CMS 자동이체', 'COMPLETED', 1);

-- 가상계좌 수납
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(7, '2025-02-07', 180000, 'VIRTUAL_ACCOUNT', 'VA20250207001', '가상계좌 수납', 'COMPLETED', 1);

-- =====================================================
-- 5. 수납 취소 및 환불 시나리오 테스트 데이터
-- =====================================================

-- 수납 취소 케이스
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(8, '2025-02-13', 220000, 'BANK_TRANSFER', 'TXN20250213001', '수납 후 취소', 'CANCELLED', 1);

-- 환불 케이스 (과납)
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(9, '2025-02-14', 300000, 'CASH', 'CASH20250214001', '과납으로 인한 환불 필요', 'REFUND_REQUIRED', 1);

-- 환불 처리 내역
INSERT INTO payment_refunds (
    payment_id, refund_date, refund_amount, refund_method, refund_reference,
    refund_reason, refund_status, processed_by
) VALUES 
((SELECT id FROM payments WHERE payment_reference = 'CASH20250214001'), '2025-02-15', 50000, 'CASH', 'REFUND20250215001', '과납 환불', 'COMPLETED', 1);

-- =====================================================
-- 6. 분할 납부 시나리오 테스트 데이터
-- =====================================================

-- 분할 납부 계획
INSERT INTO payment_plans (
    invoice_id, plan_name, total_amount, installment_count, 
    first_payment_date, monthly_payment_amount, status, created_by
) VALUES 
(10, '3개월 분할납부', 300000, 3, '2025-02-20', 100000, 'ACTIVE', 1),
(11, '6개월 분할납부', 600000, 6, '2025-02-25', 100000, 'ACTIVE', 1);

-- 분할 납부 실행
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by, payment_plan_id
) VALUES 
-- 첫 번째 분할납부 1회차
(10, '2025-02-20', 100000, 'BANK_TRANSFER', 'TXN20250220001', '분할납부 1/3', 'COMPLETED', 1, 1),
-- 첫 번째 분할납부 2회차
(10, '2025-03-20', 100000, 'BANK_TRANSFER', 'TXN20250320001', '분할납부 2/3', 'COMPLETED', 1, 1);

-- =====================================================
-- 7. 연체료 계산 및 적용 테스트 데이터
-- =====================================================

-- 연체료 계산 테스트 케이스
INSERT INTO late_fee_calculations (
    delinquency_id, calculation_date, base_amount, overdue_days,
    daily_rate, calculated_amount, applied_amount, calculation_method
) VALUES 
-- 일할 계산 방식
(1, '2025-02-20', 198000, 30, 0.000667, 3960, 3960, 'DAILY'),
-- 월할 계산 방식  
(2, '2025-02-20', 242000, 15, 0.0200, 0, 0, 'MONTHLY');

-- 연체료 수납
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by, is_late_fee_payment
) VALUES 
((SELECT id FROM invoices WHERE invoice_number = 'B001-2025-01-0005'), '2025-02-21', 3960, 'CASH', 'LATE20250221001', '연체료 납부', 'COMPLETED', 1, true);

-- =====================================================
-- 8. 수납 통계 및 집계 테스트 데이터
-- =====================================================

-- 일별 수납 집계 (자동 생성되는 뷰 테스트용)
CREATE OR REPLACE VIEW daily_payment_summary AS
SELECT 
    payment_date,
    COUNT(*) as payment_count,
    SUM(amount) as total_amount,
    SUM(CASE WHEN payment_method = 'CASH' THEN amount ELSE 0 END) as cash_amount,
    SUM(CASE WHEN payment_method = 'BANK_TRANSFER' THEN amount ELSE 0 END) as transfer_amount,
    SUM(CASE WHEN payment_method = 'CARD' THEN amount ELSE 0 END) as card_amount,
    SUM(CASE WHEN payment_method = 'CMS' THEN amount ELSE 0 END) as cms_amount,
    SUM(CASE WHEN payment_method = 'VIRTUAL_ACCOUNT' THEN amount ELSE 0 END) as va_amount
FROM payments 
WHERE payment_status = 'COMPLETED'
GROUP BY payment_date
ORDER BY payment_date;

-- 월별 수납률 집계
CREATE OR REPLACE VIEW monthly_collection_rate AS
SELECT 
    bm.billing_year,
    bm.billing_month,
    b.name as building_name,
    COUNT(i.id) as total_invoices,
    COUNT(CASE WHEN i.status = 'PAID' THEN 1 END) as paid_invoices,
    SUM(i.subtotal_amount + i.tax_amount) as total_billed,
    SUM(CASE WHEN i.status = 'PAID' THEN i.subtotal_amount + i.tax_amount ELSE 0 END) as total_collected,
    ROUND(
        COUNT(CASE WHEN i.status = 'PAID' THEN 1 END)::DECIMAL / COUNT(i.id) * 100, 2
    ) as collection_rate_by_count,
    ROUND(
        SUM(CASE WHEN i.status = 'PAID' THEN i.subtotal_amount + i.tax_amount ELSE 0 END)::DECIMAL / 
        SUM(i.subtotal_amount + i.tax_amount) * 100, 2
    ) as collection_rate_by_amount
FROM billing_months bm
JOIN buildings b ON bm.building_id = b.id
JOIN invoices i ON bm.id = i.billing_month_id
GROUP BY bm.billing_year, bm.billing_month, b.id, b.name
ORDER BY bm.billing_year, bm.billing_month, b.name;

-- =====================================================
-- 9. 데이터 검증 쿼리
-- =====================================================

-- 수납 데이터 무결성 검증
SELECT 
    '수납 및 미납 관리 테스트 데이터 생성 완료' as message,
    (SELECT COUNT(*) FROM payments WHERE payment_status = 'COMPLETED') as completed_payments,
    (SELECT COUNT(*) FROM payments WHERE payment_status = 'CANCELLED') as cancelled_payments,
    (SELECT COUNT(*) FROM payments WHERE payment_status = 'REFUND_REQUIRED') as refund_required_payments,
    (SELECT COUNT(*) FROM delinquencies WHERE is_resolved = false) as active_delinquencies,
    (SELECT COUNT(*) FROM payment_plans WHERE status = 'ACTIVE') as active_payment_plans,
    (SELECT SUM(amount) FROM payments WHERE payment_status = 'COMPLETED') as total_collected_amount;

-- 수납 금액 검증
SELECT 
    p.id as payment_id,
    p.amount as payment_amount,
    COALESCE(SUM(pd.allocated_amount), 0) as allocated_total,
    CASE WHEN p.amount = COALESCE(SUM(pd.allocated_amount), p.amount) 
         THEN 'PASS' ELSE 'FAIL' END as validation_result
FROM payments p
LEFT JOIN payment_details pd ON p.id = pd.payment_id
WHERE p.payment_status = 'COMPLETED'
GROUP BY p.id, p.amount
ORDER BY p.id;

-- 연체료 계산 검증
SELECT 
    d.id as delinquency_id,
    d.overdue_amount,
    d.overdue_days,
    d.late_fee_rate,
    d.calculated_late_fee,
    CASE WHEN d.overdue_days <= (SELECT grace_period_days FROM payment_policies WHERE building_id = 1 LIMIT 1)
         THEN 0
         ELSE ROUND(d.overdue_amount * d.late_fee_rate * (d.overdue_days - (SELECT grace_period_days FROM payment_policies WHERE building_id = 1 LIMIT 1)) / 30.0, 0)
    END as expected_late_fee,
    CASE WHEN d.calculated_late_fee = 
         CASE WHEN d.overdue_days <= (SELECT grace_period_days FROM payment_policies WHERE building_id = 1 LIMIT 1)
              THEN 0
              ELSE ROUND(d.overdue_amount * d.late_fee_rate * (d.overdue_days - (SELECT grace_period_days FROM payment_policies WHERE building_id = 1 LIMIT 1)) / 30.0, 0)
         END
         THEN 'PASS' ELSE 'FAIL' END as validation_result
FROM delinquencies d;

COMMIT;