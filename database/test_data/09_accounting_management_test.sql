-- =====================================================
-- 회계 관리 테스트 데이터 (Accounting Management Test Data)
-- =====================================================

-- 테스트용 회계 기간 생성
INSERT INTO accounting_periods (building_id, period_year, period_month, start_date, end_date, status) VALUES
(1, 2024, 1, '2024-01-01', '2024-01-31', 'CLOSED'),
(1, 2024, 2, '2024-02-01', '2024-02-29', 'CLOSED'),
(1, 2024, 3, '2024-03-01', '2024-03-31', 'OPEN'),
(2, 2024, 1, '2024-01-01', '2024-01-31', 'CLOSED'),
(2, 2024, 2, '2024-02-01', '2024-02-29', 'OPEN');

-- 테스트용 회계 전표 데이터
INSERT INTO journal_entries (building_id, entry_date, reference_number, description, total_debit, total_credit, status, created_by, posted_by, posted_at) VALUES
-- 1월 임대료 수익 전표
(1, '2024-01-05', 'JE-2024-001', '1월 임대료 수익', 5000000.00, 5000000.00, 'POSTED', 1, 1, '2024-01-05 10:00:00'),
-- 1월 관리비 수익 전표
(1, '2024-01-10', 'JE-2024-002', '1월 관리비 수익', 2000000.00, 2000000.00, 'POSTED', 1, 1, '2024-01-10 10:00:00'),
-- 1월 건물 관리비 지출 전표
(1, '2024-01-15', 'JE-2024-003', '1월 건물 관리비 지출', 1500000.00, 1500000.00, 'POSTED', 1, 1, '2024-01-15 10:00:00'),
-- 1월 수선비 지출 전표
(1, '2024-01-20', 'JE-2024-004', '엘리베이터 수리비', 800000.00, 800000.00, 'POSTED', 1, 1, '2024-01-20 10:00:00'),
-- 2월 임대료 수익 전표
(1, '2024-02-05', 'JE-2024-005', '2월 임대료 수익', 5200000.00, 5200000.00, 'POSTED', 1, 1, '2024-02-05 10:00:00'),
-- 3월 초안 전표 (아직 전기되지 않음)
(1, '2024-03-05', 'JE-2024-006', '3월 임대료 수익', 5300000.00, 5300000.00, 'DRAFT', 1, NULL, NULL);

-- 테스트용 회계 전표 상세 데이터
INSERT INTO journal_entry_details (journal_entry_id, account_id, debit_amount, credit_amount, description) VALUES
-- JE-2024-001: 1월 임대료 수익
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 5000000.00, 0, '1월 임대료 입금'),
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '4100'), 0, 5000000.00, '1월 임대료 수익'),

-- JE-2024-002: 1월 관리비 수익
(2, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 2000000.00, 0, '1월 관리비 입금'),
(2, (SELECT id FROM chart_of_accounts WHERE account_code = '4200'), 0, 2000000.00, '1월 관리비 수익'),

-- JE-2024-003: 1월 건물 관리비 지출
(3, (SELECT id FROM chart_of_accounts WHERE account_code = '5100'), 1500000.00, 0, '1월 건물 관리비'),
(3, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 0, 1500000.00, '관리비 지출'),

-- JE-2024-004: 1월 수선비 지출
(4, (SELECT id FROM chart_of_accounts WHERE account_code = '5200'), 800000.00, 0, '엘리베이터 수리비'),
(4, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 0, 800000.00, '수리비 지출'),

-- JE-2024-005: 2월 임대료 수익
(5, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 5200000.00, 0, '2월 임대료 입금'),
(5, (SELECT id FROM chart_of_accounts WHERE account_code = '4100'), 0, 5200000.00, '2월 임대료 수익'),

-- JE-2024-006: 3월 임대료 수익 (초안)
(6, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 5300000.00, 0, '3월 임대료 입금'),
(6, (SELECT id FROM chart_of_accounts WHERE account_code = '4100'), 0, 5300000.00, '3월 임대료 수익');

-- 테스트용 계정 잔액 데이터 (1월, 2월 마감 기준)
INSERT INTO account_balances (building_id, account_id, period_id, opening_balance, debit_total, credit_total, closing_balance) VALUES
-- 건물 1, 2024년 1월
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 1, 0, 7000000.00, 2300000.00, 4700000.00), -- 예금
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '4100'), 1, 0, 0, 5000000.00, 5000000.00), -- 임대료수익
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '4200'), 1, 0, 0, 2000000.00, 2000000.00), -- 관리비수익
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '5100'), 1, 0, 1500000.00, 0, 1500000.00), -- 관리비
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '5200'), 1, 0, 800000.00, 0, 800000.00), -- 수선비

-- 건물 1, 2024년 2월
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '1200'), 2, 4700000.00, 5200000.00, 0, 9900000.00), -- 예금
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '4100'), 2, 5000000.00, 0, 5200000.00, 10200000.00); -- 임대료수익

-- 테스트 쿼리 예제들
-- 1. 손익계산서 조회 (2024년 1월)
/*
SELECT 
    account_name,
    CASE 
        WHEN account_type = 'REVENUE' THEN closing_balance
        ELSE 0
    END as revenue,
    CASE 
        WHEN account_type = 'EXPENSE' THEN closing_balance
        ELSE 0
    END as expense
FROM v_income_statement
WHERE building_id = 1 AND period_year = 2024 AND period_month = 1
ORDER BY account_code;
*/

-- 2. 월별 손익 요약 조회
/*
SELECT 
    period_year,
    period_month,
    total_revenue,
    total_expense,
    net_income
FROM v_monthly_pnl_summary
WHERE building_id = 1
ORDER BY period_year, period_month;
*/

-- 3. 계정별 원장 조회 (예금 계정)
/*
SELECT 
    entry_date,
    reference_number,
    journal_description,
    debit_amount,
    credit_amount,
    detail_description
FROM v_general_ledger
WHERE building_id = 1 
    AND account_code = '1200'
    AND entry_date BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY entry_date, journal_description;
*/

-- 4. 복식부기 검증 쿼리
/*
SELECT 
    je.reference_number,
    je.description,
    je.total_debit,
    je.total_credit,
    CASE 
        WHEN je.total_debit = je.total_credit THEN '균형'
        ELSE '불균형'
    END as balance_status
FROM journal_entries je
WHERE je.building_id = 1
ORDER BY je.entry_date;
*/

-- 코멘트
COMMENT ON TABLE accounting_periods IS '회계 기간별 마감 상태를 관리하는 테스트 데이터';
COMMENT ON TABLE journal_entries IS '다양한 거래 유형의 회계 전표 테스트 데이터';
COMMENT ON TABLE journal_entry_details IS '복식부기 원칙을 준수하는 전표 상세 테스트 데이터';
COMMENT ON TABLE account_balances IS '기간별 계정 잔액 테스트 데이터';