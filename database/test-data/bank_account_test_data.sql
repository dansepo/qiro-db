-- 은행 계좌 관리 시스템 테스트 데이터

-- 테스트 회사 ID 조회 후 은행 계좌 생성
WITH test_company AS (
    SELECT company_id FROM bms.companies WHERE verification_status = 'VERIFIED' LIMIT 1
)
INSERT INTO bms.bank_accounts (
    bank_account_id, company_id, account_name, bank_name, account_number,
    account_type, currency, current_balance, available_balance
)
SELECT 
    gen_random_uuid(), tc.company_id, 
    account_data.account_name, account_data.bank_name, account_data.account_number,
    account_data.account_type, 'KRW', account_data.current_balance, account_data.available_balance
FROM test_company tc,
(VALUES 
    ('주거래 계좌', '국민은행', '123-456-789012', 'CHECKING', 500000000.00, 500000000.00),
    ('적금 계좌', '신한은행', '987-654-321098', 'SAVINGS', 200000000.00, 200000000.00),
    ('예금 계좌', '우리은행', '555-777-999111', 'DEPOSIT', 1000000000.00, 1000000000.00)
) AS account_data(account_name, bank_name, account_number, account_type, current_balance, available_balance);

-- 은행 거래 내역 생성
WITH test_accounts AS (
    SELECT ba.bank_account_id, ba.company_id, ba.account_name
    FROM bms.bank_accounts ba
    JOIN bms.companies c ON ba.company_id = c.company_id
    WHERE c.verification_status = 'VERIFIED'
)
INSERT INTO bms.bank_transactions (
    bank_transaction_id, bank_account_id, company_id, transaction_date, transaction_time,
    transaction_type, amount, balance_after, counterpart_name, counterpart_account, description
)
SELECT 
    gen_random_uuid(), ta.bank_account_id, ta.company_id, 
    transaction_data.transaction_date::DATE, transaction_data.transaction_time::TIME,
    transaction_data.transaction_type, transaction_data.amount, transaction_data.balance_after,
    transaction_data.counterpart_name, transaction_data.counterpart_account, transaction_data.description
FROM test_accounts ta,
(VALUES 
    ('주거래 계좌', '2025-01-15', '09:30:00', 'DEPOSIT', 50000000.00, 550000000.00, '관리비 입금', '101-202-303404', '1월 관리비 수입'),
    ('주거래 계좌', '2025-01-20', '14:15:00', 'WITHDRAWAL', 15000000.00, 535000000.00, '유지보수업체', '777-888-999000', '엘리베이터 점검비'),
    ('주거래 계좌', '2025-01-25', '11:45:00', 'TRANSFER_OUT', 5000000.00, 530000000.00, '적금계좌', '987-654-321098', '적금 이체'),
    ('적금 계좌', '2025-01-25', '11:46:00', 'TRANSFER_IN', 5000000.00, 205000000.00, '주거래계좌', '123-456-789012', '적금 입금'),
    ('예금 계좌', '2025-01-31', '16:00:00', 'INTEREST', 2000000.00, 1002000000.00, '이자 지급', '', '1월 이자 수입')
) AS transaction_data(account_name, transaction_date, transaction_time, transaction_type, amount, balance_after, counterpart_name, counterpart_account, description)
WHERE ta.account_name = transaction_data.account_name;

-- 자동 매칭 규칙 생성
WITH test_company AS (
    SELECT company_id FROM bms.companies WHERE verification_status = 'VERIFIED' LIMIT 1
)
INSERT INTO bms.bank_matching_rules (
    rule_id, company_id, rule_name, rule_type, pattern, priority
)
SELECT 
    gen_random_uuid(), tc.company_id,
    rule_data.rule_name, rule_data.rule_type, rule_data.pattern, rule_data.priority
FROM test_company tc,
(VALUES 
    ('관리비 수입 매칭', 'DESCRIPTION', '%관리비%', 1),
    ('유지보수비 매칭', 'COUNTERPART_NAME', '%유지보수%', 2),
    ('공과금 매칭', 'DESCRIPTION', '%전기%|%가스%|%수도%', 3),
    ('이자 수입 매칭', 'DESCRIPTION', '%이자%', 4)
) AS rule_data(rule_name, rule_type, pattern, priority);