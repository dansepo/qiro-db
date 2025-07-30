-- ============================================================================
-- 임대차 관리 워크플로우 테스트 데이터
-- ============================================================================

-- 테스트 데이터 삽입 전 기존 데이터 정리
DELETE FROM settlement_disputes;
DELETE FROM settlement_items;
DELETE FROM settlement_status_history;
DELETE FROM move_out_settlements;
DELETE FROM rent_delinquencies;
DELETE FROM rent_payments;
DELETE FROM monthly_rents;
DELETE FROM lease_contract_status_history;
DELETE FROM lease_contract_renewal_alerts;
DELETE FROM lease_contracts;

-- ============================================================================
-- 임대 계약 테스트 데이터
-- ============================================================================

-- 활성 임대 계약들
INSERT INTO lease_contracts (
    id, contract_number, unit_id, tenant_id, lessor_id, 
    start_date, end_date, monthly_rent, deposit, maintenance_fee,
    contract_type, status, created_by, updated_by
) VALUES 
-- 101호 - 활성 계약
(1, 'LC2024001', 1, 1, 1, '2024-01-01', '2025-12-31', 1500000, 15000000, 200000, 'NEW', 'ACTIVE', 1, 1),
-- 102호 - 활성 계약 (곧 만료 예정)
(2, 'LC2024002', 2, 2, 1, '2023-03-01', '2025-02-28', 1800000, 20000000, 250000, 'NEW', 'ACTIVE', 1, 1),
-- 201호 - 활성 계약
(3, 'LC2024003', 3, 3, 2, '2024-06-01', '2026-05-31', 2000000, 25000000, 300000, 'NEW', 'ACTIVE', 1, 1),
-- 202호 - 만료된 계약
(4, 'LC2023001', 4, 4, 2, '2023-01-01', '2024-12-31', 1700000, 18000000, 220000, 'NEW', 'EXPIRED', 1, 1),
-- 301호 - 중도해지된 계약
(5, 'LC2024004', 5, 5, 3, '2024-03-01', '2026-02-28', 2200000, 30000000, 350000, 'NEW', 'TERMINATED', 1, 1);

-- 갱신 계약 예시
INSERT INTO lease_contracts (
    id, contract_number, unit_id, tenant_id, lessor_id, 
    start_date, end_date, monthly_rent, deposit, maintenance_fee,
    contract_type, status, previous_contract_id, created_by, updated_by
) VALUES 
-- 202호 - 갱신 계약
(6, 'LC2025001', 4, 4, 2, '2025-01-01', '2026-12-31', 1800000, 18000000, 240000, 'RENEWAL', 'ACTIVE', 4, 1, 1);

-- ============================================================================
-- 월별 임대료 테스트 데이터
-- ============================================================================

-- 2024년 임대료 데이터
INSERT INTO monthly_rents (
    id, lease_contract_id, rent_year, rent_month, rent_amount, maintenance_fee,
    due_date, payment_status, paid_amount, paid_date, created_by, updated_by
) VALUES 
-- 101호 (계약 ID: 1) - 2024년 임대료
(1, 1, 2024, 1, 1500000, 200000, '2024-01-05', 'PAID', 1700000, '2024-01-03', 1, 1),
(2, 1, 2024, 2, 1500000, 200000, '2024-02-05', 'PAID', 1700000, '2024-02-04', 1, 1),
(3, 1, 2024, 3, 1500000, 200000, '2024-03-05', 'PAID', 1700000, '2024-03-02', 1, 1),
(4, 1, 2024, 4, 1500000, 200000, '2024-04-05', 'PARTIAL', 1000000, NULL, 1, 1),
(5, 1, 2024, 5, 1500000, 200000, '2024-05-05', 'OVERDUE', 0, NULL, 1, 1),

-- 102호 (계약 ID: 2) - 2024년 임대료
(6, 2, 2024, 1, 1800000, 250000, '2024-01-05', 'PAID', 2050000, '2024-01-05', 1, 1),
(7, 2, 2024, 2, 1800000, 250000, '2024-02-05', 'PAID', 2050000, '2024-02-03', 1, 1),
(8, 2, 2024, 3, 1800000, 250000, '2024-03-05', 'OVERDUE', 0, NULL, 1, 1),

-- 201호 (계약 ID: 3) - 2024년 하반기 임대료
(9, 3, 2024, 6, 2000000, 300000, '2024-06-05', 'PAID', 2300000, '2024-06-04', 1, 1),
(10, 3, 2024, 7, 2000000, 300000, '2024-07-05', 'PAID', 2300000, '2024-07-05', 1, 1),
(11, 3, 2024, 8, 2000000, 300000, '2024-08-05', 'PAID', 2300000, '2024-08-03', 1, 1),
(12, 3, 2024, 9, 2000000, 300000, '2024-09-05', 'PENDING', 0, NULL, 1, 1);

-- ============================================================================
-- 임대료 납부 내역 테스트 데이터
-- ============================================================================

-- 완납 케이스
INSERT INTO rent_payments (
    id, monthly_rent_id, payment_date, payment_amount, payment_method,
    payment_reference, rent_portion, maintenance_portion, late_fee_portion, created_by
) VALUES 
(1, 1, '2024-01-03', 1700000, 'BANK_TRANSFER', '김철수', 1500000, 200000, 0, 1),
(2, 2, '2024-02-04', 1700000, 'BANK_TRANSFER', '김철수', 1500000, 200000, 0, 1),
(3, 3, '2024-03-02', 1700000, 'BANK_TRANSFER', '김철수', 1500000, 200000, 0, 1);

-- 부분납부 케이스
INSERT INTO rent_payments (
    id, monthly_rent_id, payment_date, payment_amount, payment_method,
    payment_reference, rent_portion, maintenance_portion, late_fee_portion, created_by
) VALUES 
(4, 4, '2024-04-10', 1000000, 'BANK_TRANSFER', '김철수', 1000000, 0, 0, 1);

-- 102호 완납 케이스
INSERT INTO rent_payments (
    id, monthly_rent_id, payment_date, payment_amount, payment_method,
    payment_reference, rent_portion, maintenance_portion, late_fee_portion, created_by
) VALUES 
(5, 6, '2024-01-05', 2050000, 'BANK_TRANSFER', '박영희', 1800000, 250000, 0, 1),
(6, 7, '2024-02-03', 2050000, 'BANK_TRANSFER', '박영희', 1800000, 250000, 0, 1);

-- 201호 완납 케이스
INSERT INTO rent_payments (
    id, monthly_rent_id, payment_date, payment_amount, payment_method,
    payment_reference, rent_portion, maintenance_portion, late_fee_portion, created_by
) VALUES 
(7, 9, '2024-06-04', 2300000, 'BANK_TRANSFER', '이민수', 2000000, 300000, 0, 1),
(8, 10, '2024-07-05', 2300000, 'BANK_TRANSFER', '이민수', 2000000, 300000, 0, 1),
(9, 11, '2024-08-03', 2300000, 'BANK_TRANSFER', '이민수', 2000000, 300000, 0, 1);

-- ============================================================================
-- 임대료 연체 테스트 데이터
-- ============================================================================

INSERT INTO rent_delinquencies (
    id, monthly_rent_id, overdue_amount, overdue_start_date, overdue_days,
    late_fee_rate, calculated_late_fee, applied_late_fee, is_resolved, created_by, updated_by
) VALUES 
-- 101호 5월 연체
(1, 5, 1700000, '2024-05-06', 180, 0.0005, 153000, 153000, false, 1, 1),
-- 102호 3월 연체
(2, 8, 2050000, '2024-03-06', 270, 0.0005, 276750, 276750, false, 1, 1);

-- ============================================================================
-- 퇴실 정산 테스트 데이터
-- ============================================================================

-- 완료된 정산 (301호 - 중도해지)
INSERT INTO move_out_settlements (
    id, settlement_number, lease_contract_id, move_out_date, move_out_reason,
    notice_date, settlement_start_date, settlement_end_date, original_deposit,
    status, settlement_date, refund_method, refund_completed_date,
    notes, created_by, updated_by
) VALUES 
(1, 'ST2024000001', 5, '2024-10-15', '사업장 이전', '2024-09-15', 
 '2024-10-15', '2024-10-31', 30000000, 'COMPLETED', '2024-11-05', 
 'BANK_TRANSFER', '2024-11-07', '정상 정산 완료', 1, 1);

-- 진행중인 정산 (202호 - 만료)
INSERT INTO move_out_settlements (
    id, settlement_number, lease_contract_id, move_out_date, move_out_reason,
    notice_date, settlement_start_date, settlement_end_date, original_deposit,
    status, notes, created_by, updated_by
) VALUES 
(2, 'ST2025000001', 4, '2024-12-31', '계약 만료', '2024-11-30', 
 '2024-12-31', '2025-01-15', 18000000, 'IN_PROGRESS', '정산 진행중', 1, 1);

-- ============================================================================
-- 정산 항목 테스트 데이터
-- ============================================================================

-- 완료된 정산 (301호) 항목들
INSERT INTO settlement_items (
    id, settlement_id, item_type, description, amount, is_deduction,
    is_approved, approved_by, approved_at, created_by, updated_by
) VALUES 
-- 공제 항목들
(1, 1, 'UNPAID_RENT', '2024년 10월 미납 임대료', 2200000, true, true, 1, '2024-11-01', 1, 1),
(2, 1, 'UNPAID_MAINTENANCE', '2024년 10월 미납 관리비', 350000, true, true, 1, '2024-11-01', 1, 1),
(3, 1, 'REPAIR_COST', '벽지 교체 및 도배', 800000, true, true, 1, '2024-11-02', 1, 1),
(4, 1, 'CLEANING_FEE', '전문 청소 서비스', 300000, true, true, 1, '2024-11-02', 1, 1),
-- 추가 환급 항목
(5, 1, 'OTHER_REFUND', '선납 관리비 환급', 150000, false, true, 1, '2024-11-03', 1, 1);

-- 진행중인 정산 (202호) 항목들
INSERT INTO settlement_items (
    id, settlement_id, item_type, description, amount, is_deduction,
    is_approved, approved_by, approved_at, created_by, updated_by
) VALUES 
-- 승인된 항목들
(6, 2, 'UNPAID_RENT', '2024년 12월 미납 임대료', 1700000, true, true, 1, '2025-01-02', 1, 1),
(7, 2, 'CLEANING_FEE', '전문 청소 서비스', 250000, true, true, 1, '2025-01-02', 1, 1),
-- 승인 대기 항목들
(8, 2, 'REPAIR_COST', '싱크대 교체', 500000, true, false, NULL, NULL, 1, 1),
(9, 2, 'KEY_REPLACEMENT', '현관문 열쇠 교체', 80000, true, false, NULL, NULL, 1, 1);

-- ============================================================================
-- 정산 분쟁 테스트 데이터
-- ============================================================================

INSERT INTO settlement_disputes (
    id, settlement_id, dispute_number, dispute_reason, disputed_amount,
    dispute_date, disputant_name, disputant_contact, is_resolved,
    resolution_date, resolution_method, resolution_amount, resolution_notes,
    created_by, updated_by
) VALUES 
-- 해결된 분쟁
(1, 1, 'DP2024001', '수리비 과다 청구 이의제기', 300000, '2024-11-01', 
 '최영수', '010-5555-6666', true, '2024-11-03', '합의', 200000, 
 '수리비 100,000원 차감 합의', 1, 1),
-- 진행중인 분쟁
(2, 2, 'DP2025001', '싱크대 교체 필요성 이의제기', 500000, '2025-01-03', 
 '정미영', '010-7777-8888', false, NULL, NULL, NULL, 
 '임차인이 싱크대 교체 필요성에 대해 이의제기', 1, 1);

-- ============================================================================
-- 시퀀스 값 조정
-- ============================================================================

-- 각 테이블의 시퀀스를 현재 최대 ID + 1로 설정
SELECT setval('lease_contracts_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM lease_contracts));
SELECT setval('lease_contract_status_history_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM lease_contract_status_history));
SELECT setval('lease_contract_renewal_alerts_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM lease_contract_renewal_alerts));
SELECT setval('monthly_rents_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM monthly_rents));
SELECT setval('rent_payments_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM rent_payments));
SELECT setval('rent_delinquencies_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM rent_delinquencies));
SELECT setval('move_out_settlements_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM move_out_settlements));
SELECT setval('settlement_items_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM settlement_items));
SELECT setval('settlement_status_history_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM settlement_status_history));
SELECT setval('settlement_disputes_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM settlement_disputes));

-- ============================================================================
-- 테스트 데이터 검증 쿼리들
-- ============================================================================

-- 1. 임대 계약 현황 확인
SELECT 
    '임대 계약 현황' as category,
    status,
    COUNT(*) as count
FROM lease_contracts 
GROUP BY status
ORDER BY status;

-- 2. 임대료 납부 현황 확인
SELECT 
    '임대료 납부 현황' as category,
    payment_status,
    COUNT(*) as count,
    SUM(total_amount) as total_amount,
    SUM(paid_amount) as paid_amount
FROM monthly_rents 
GROUP BY payment_status
ORDER BY payment_status;

-- 3. 연체 현황 확인
SELECT 
    '연체 현황' as category,
    COUNT(*) as overdue_count,
    SUM(overdue_amount) as total_overdue_amount,
    SUM(applied_late_fee) as total_late_fee
FROM rent_delinquencies 
WHERE is_resolved = false;

-- 4. 정산 현황 확인
SELECT 
    '정산 현황' as category,
    status,
    COUNT(*) as count,
    AVG(original_deposit) as avg_deposit,
    AVG(final_refund_amount) as avg_refund
FROM move_out_settlements 
GROUP BY status
ORDER BY status;

-- 5. 분쟁 현황 확인
SELECT 
    '분쟁 현황' as category,
    is_resolved,
    COUNT(*) as count,
    SUM(disputed_amount) as total_disputed_amount
FROM settlement_disputes 
GROUP BY is_resolved
ORDER BY is_resolved;

-- ============================================================================
-- 뷰 테스트 쿼리들
-- ============================================================================

-- 만료 예정 계약 조회
SELECT '만료 예정 계약' as test_name, * FROM v_expiring_contracts LIMIT 5;

-- 임대료 현황 요약 조회
SELECT '임대료 현황 요약' as test_name, * FROM v_rent_status_summary WHERE is_currently_overdue = true LIMIT 5;

-- 연체 현황 조회
SELECT '연체 현황' as test_name, * FROM v_rent_delinquency_summary WHERE is_resolved = false LIMIT 5;

-- 정산 현황 요약 조회
SELECT '정산 현황 요약' as test_name, * FROM v_settlement_summary LIMIT 5;

-- 월별 임대료 수납 현황 조회
SELECT '월별 수납 현황' as test_name, * FROM v_monthly_rent_collection_summary 
WHERE rent_year = 2024 ORDER BY rent_month DESC LIMIT 5;

COMMIT;