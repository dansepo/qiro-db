-- =====================================================
-- 수납 관리 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    unit_rec RECORD;
    issuance_rec RECORD;
    method_count INTEGER := 0;
    transaction_count INTEGER := 0;
    auto_debit_count INTEGER := 0;
    reconciliation_count INTEGER := 0;
    
    -- 결제 방법 ID 저장용 변수들
    v_bank_transfer_id UUID;
    v_virtual_account_id UUID;
    v_credit_card_id UUID;
    v_auto_debit_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- 각 회사에 대해 수납 관리 시스템 데이터 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 수납 관리 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 관리자 사용자 ID 조회
        SELECT user_id INTO v_admin_user_id 
        FROM bms.users 
        WHERE company_id = company_rec.company_id 
        LIMIT 1;
        
        -- 1. 결제 방법 생성
        -- 계좌이체
        v_bank_transfer_id := gen_random_uuid();
        INSERT INTO bms.payment_methods (
            method_id, company_id, building_id,
            method_name, method_type, method_description,
            provider_name, provider_code,
            min_amount, max_amount, fee_rate, fixed_fee,
            auto_confirmation, confirmation_delay_minutes,
            refund_supported, partial_refund_supported,
            bank_code, bank_name, account_number, account_holder,
            is_active, daily_limit, monthly_limit,
            total_transactions, total_amount, success_rate,
            created_by
        ) VALUES (
            v_bank_transfer_id, company_rec.company_id, NULL,
            '계좌이체', 'BANK_TRANSFER', '은행 계좌이체를 통한 관리비 납부',
            '우리은행', 'WR',
            1000, 10000000, 0, 0,
            true, 0,
            true, true,
            '020', '우리은행', '1002-' || LPAD((100000 + random() * 899999)::integer::text, 6, '0'), company_rec.company_name,
            true, 50000000, 1000000000,
            (random() * 1000)::integer, (random() * 500000000)::integer, (85 + random() * 10)::numeric(5,2),
            v_admin_user_id
        );
        
        -- 가상계좌
        v_virtual_account_id := gen_random_uuid();
        INSERT INTO bms.payment_methods (
            method_id, company_id, building_id,
            method_name, method_type, method_description,
            provider_name, provider_code,
            min_amount, max_amount, fee_rate, fixed_fee,
            auto_confirmation, confirmation_delay_minutes,
            refund_supported, partial_refund_supported,
            virtual_account_enabled, virtual_account_bank_codes, virtual_account_expire_hours,
            is_active, daily_limit, monthly_limit,
            total_transactions, total_amount, success_rate,
            created_by
        ) VALUES (
            v_virtual_account_id, company_rec.company_id, NULL,
            '가상계좌', 'VIRTUAL_ACCOUNT', '개인별 가상계좌를 통한 관리비 납부',
            'KG이니시스', 'INICIS',
            1000, 10000000, 0.1, 100,
            true, 5,
            true, false,
            true, ARRAY['020', '011', '004', '088'], 72,
            true, 100000000, 2000000000,
            (random() * 800)::integer, (random() * 400000000)::integer, (90 + random() * 8)::numeric(5,2),
            v_admin_user_id
        );
        
        -- 신용카드
        v_credit_card_id := gen_random_uuid();
        INSERT INTO bms.payment_methods (
            method_id, company_id, building_id,
            method_name, method_type, method_description,
            provider_name, provider_code,
            min_amount, max_amount, fee_rate, fixed_fee,
            auto_confirmation, confirmation_delay_minutes,
            refund_supported, partial_refund_supported,
            is_active, daily_limit, monthly_limit,
            total_transactions, total_amount, success_rate,
            created_by
        ) VALUES (
            v_credit_card_id, company_rec.company_id, NULL,
            '신용카드', 'CREDIT_CARD', '신용카드를 통한 관리비 납부',
            'NHN KCP', 'KCP',
            1000, 5000000, 2.5, 0,
            true, 0,
            true, true,
            true, 20000000, 500000000,
            (random() * 600)::integer, (random() * 300000000)::integer, (88 + random() * 10)::numeric(5,2),
            v_admin_user_id
        );
        
        -- 자동이체
        v_auto_debit_id := gen_random_uuid();
        INSERT INTO bms.payment_methods (
            method_id, company_id, building_id,
            method_name, method_type, method_description,
            provider_name, provider_code,
            min_amount, max_amount, fee_rate, fixed_fee,
            auto_confirmation, confirmation_delay_minutes,
            refund_supported, partial_refund_supported,
            is_active, daily_limit, monthly_limit,
            total_transactions, total_amount, success_rate,
            created_by
        ) VALUES (
            v_auto_debit_id, company_rec.company_id, NULL,
            '자동이체 (CMS)', 'AUTO_DEBIT', 'CMS 자동이체를 통한 관리비 납부',
            '금융결제원', 'KFTC',
            10000, 10000000, 0.05, 50,
            true, 0,
            false, false,
            true, NULL, NULL,
            (random() * 1200)::integer, (random() * 600000000)::integer, (95 + random() * 4)::numeric(5,2),
            v_admin_user_id
        );
        
        method_count := method_count + 4;
        
        -- 2. 자동이체 설정 생성
        FOR unit_rec IN 
            SELECT unit_id, unit_number
            FROM bms.units
            WHERE company_id = company_rec.company_id
              AND unit_status = 'OCCUPIED'
            LIMIT 5  -- 각 회사당 5개 호실만
        LOOP
            -- 50% 확률로 자동이체 설정
            IF random() < 0.5 THEN
                INSERT INTO bms.auto_debit_settings (
                    company_id, unit_id, method_id,
                    setting_name, debit_type,
                    bank_code, bank_name, account_number, account_holder,
                    debit_day, debit_amount_type, max_amount,
                    retry_count, retry_interval_days, failure_notification,
                    is_active, start_date, end_date,
                    agreement_date, agreement_method, agreement_ip,
                    total_attempts, successful_debits, failed_debits,
                    last_debit_date, next_debit_date,
                    created_by
                ) VALUES (
                    company_rec.company_id, unit_rec.unit_id, v_auto_debit_id,
                    unit_rec.unit_number || '호 자동이체', 'CMS',
                    CASE (random() * 4)::integer
                        WHEN 0 THEN '020'  -- 우리은행
                        WHEN 1 THEN '011'  -- 농협
                        WHEN 2 THEN '004'  -- KB국민은행
                        ELSE '088'         -- 신한은행
                    END,
                    CASE (random() * 4)::integer
                        WHEN 0 THEN '우리은행'
                        WHEN 1 THEN '농협은행'
                        WHEN 2 THEN 'KB국민은행'
                        ELSE '신한은행'
                    END,
                    LPAD((100000000 + random() * 899999999)::bigint::text, 10, '0') || '-' || LPAD((10 + random() * 89)::integer::text, 2, '0'),
                    '입주자' || unit_rec.unit_number,
                    CASE (random() * 3)::integer
                        WHEN 0 THEN 25  -- 25일
                        WHEN 1 THEN 28  -- 28일
                        ELSE 5          -- 5일
                    END,
                    'FULL', 1000000,
                    3, 3, true,
                    true, CURRENT_DATE - INTERVAL '6 months', NULL,
                    CURRENT_DATE - INTERVAL '6 months', 'ONLINE', '192.168.1.' || (1 + random() * 254)::integer,
                    (random() * 12)::integer, (random() * 10)::integer, (random() * 2)::integer,
                    CASE WHEN random() < 0.8 THEN CURRENT_DATE - INTERVAL '1 month' ELSE NULL END,
                    DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' + ((CASE (random() * 3)::integer WHEN 0 THEN 25 WHEN 1 THEN 28 ELSE 5 END - 1) || ' days')::INTERVAL,
                    v_admin_user_id
                );
                
                auto_debit_count := auto_debit_count + 1;
            END IF;
        END LOOP;
        
        -- 3. 수납 거래 생성
        FOR issuance_rec IN 
            SELECT bi.issuance_id, bi.total_amount, bi.unit_id, bi.bill_period
            FROM bms.bill_issuances bi
            WHERE bi.company_id = company_rec.company_id
              AND bi.issuance_status = 'DELIVERED'
            LIMIT 15  -- 각 회사당 15개 고지서만
        LOOP
            DECLARE
                v_method_id UUID;
                v_transaction_status VARCHAR(20);
                v_payment_status VARCHAR(20);
                v_paid_amount DECIMAL(15,2);
                v_transaction_date TIMESTAMP WITH TIME ZONE;
                v_payment_date TIMESTAMP WITH TIME ZONE;
            BEGIN
                -- 랜덤 결제 방법 선택
                v_method_id := CASE (random() * 4)::integer
                    WHEN 0 THEN v_bank_transfer_id
                    WHEN 1 THEN v_virtual_account_id
                    WHEN 2 THEN v_credit_card_id
                    ELSE v_auto_debit_id
                END;
                
                -- 거래 상태 및 금액 설정
                CASE (random() * 10)::integer
                    WHEN 0, 1 THEN  -- 20% - 완전 납부
                        v_transaction_status := 'COMPLETED';
                        v_payment_status := 'PAID';
                        v_paid_amount := issuance_rec.total_amount;
                    WHEN 2 THEN      -- 10% - 부분 납부
                        v_transaction_status := 'COMPLETED';
                        v_payment_status := 'PARTIAL';
                        v_paid_amount := issuance_rec.total_amount * (0.3 + random() * 0.6);
                    WHEN 3 THEN      -- 10% - 과납
                        v_transaction_status := 'COMPLETED';
                        v_payment_status := 'OVERPAID';
                        v_paid_amount := issuance_rec.total_amount * (1.01 + random() * 0.1);
                    WHEN 4 THEN      -- 10% - 실패
                        v_transaction_status := 'FAILED';
                        v_payment_status := 'UNPAID';
                        v_paid_amount := 0;
                    WHEN 5 THEN      -- 10% - 취소
                        v_transaction_status := 'CANCELLED';
                        v_payment_status := 'CANCELLED';
                        v_paid_amount := 0;
                    WHEN 6 THEN      -- 10% - 처리중
                        v_transaction_status := 'PROCESSING';
                        v_payment_status := 'UNPAID';
                        v_paid_amount := 0;
                    ELSE             -- 30% - 미납
                        v_transaction_status := 'PENDING';
                        v_payment_status := 'UNPAID';
                        v_paid_amount := 0;
                END CASE;
                
                -- 거래 일시 설정
                v_transaction_date := issuance_rec.bill_period + INTERVAL '26 days' + (random() * 10 || ' days')::INTERVAL;
                v_payment_date := CASE 
                    WHEN v_transaction_status IN ('COMPLETED', 'CANCELLED') THEN 
                        v_transaction_date + (random() * 3600 || ' seconds')::INTERVAL
                    ELSE NULL
                END;
                
                -- 수납 거래 생성
                INSERT INTO bms.payment_transactions (
                    company_id, issuance_id, method_id,
                    transaction_number, external_transaction_id, payment_reference,
                    bill_amount, paid_amount, fee_amount, discount_amount, late_fee_amount, net_amount,
                    transaction_status, payment_status,
                    transaction_date, payment_date, confirmation_date, settlement_date,
                    payer_name, payer_phone, payer_email,
                    virtual_account_number, virtual_account_bank, virtual_account_expire_at,
                    card_number_masked, card_type, card_company, installment_months,
                    response_code, response_message, gateway_response,
                    is_cancelled, cancelled_at, cancel_reason, refund_amount,
                    is_settled, settlement_amount, settlement_reference
                ) VALUES (
                    company_rec.company_id, issuance_rec.issuance_id, v_method_id,
                    'TXN' || TO_CHAR(v_transaction_date, 'YYYYMMDD') || '-' || LPAD((random() * 999999)::integer::text, 6, '0'),
                    CASE WHEN v_method_id != v_bank_transfer_id THEN 'EXT' || LPAD((random() * 999999999)::bigint::text, 9, '0') ELSE NULL END,
                    'PAY' || TO_CHAR(v_transaction_date, 'YYYYMMDDHH24MISS') || LPAD((random() * 999)::integer::text, 3, '0'),
                    issuance_rec.total_amount, v_paid_amount,
                    CASE WHEN v_paid_amount > 0 THEN v_paid_amount * 0.025 ELSE 0 END,  -- 2.5% 수수료
                    CASE WHEN random() < 0.1 THEN v_paid_amount * 0.05 ELSE 0 END,      -- 5% 할인 (10% 확률)
                    CASE WHEN v_transaction_date > issuance_rec.bill_period + INTERVAL '45 days' THEN issuance_rec.total_amount * 0.03 ELSE 0 END,  -- 연체료
                    v_paid_amount - CASE WHEN v_paid_amount > 0 THEN v_paid_amount * 0.025 ELSE 0 END,
                    v_transaction_status, v_payment_status,
                    v_transaction_date, v_payment_date,
                    CASE WHEN v_payment_date IS NOT NULL THEN v_payment_date + INTERVAL '30 seconds' ELSE NULL END,
                    CASE WHEN v_payment_date IS NOT NULL AND v_transaction_status = 'COMPLETED' THEN v_payment_date + INTERVAL '1 day' ELSE NULL END,
                    '입주자' || (SELECT unit_number FROM bms.units WHERE unit_id = issuance_rec.unit_id),
                    '010-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0') || '-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0'),
                    'resident' || (SELECT unit_number FROM bms.units WHERE unit_id = issuance_rec.unit_id) || '@example.com',
                    CASE WHEN v_method_id = v_virtual_account_id THEN 
                        '9999' || LPAD((100000000 + random() * 899999999)::bigint::text, 9, '0')
                    ELSE NULL END,
                    CASE WHEN v_method_id = v_virtual_account_id THEN '우리은행' ELSE NULL END,
                    CASE WHEN v_method_id = v_virtual_account_id THEN v_transaction_date + INTERVAL '72 hours' ELSE NULL END,
                    CASE WHEN v_method_id = v_credit_card_id THEN 
                        LPAD((1000 + random() * 8999)::integer::text, 4, '0') || '-****-****-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0')
                    ELSE NULL END,
                    CASE WHEN v_method_id = v_credit_card_id THEN 'CREDIT' ELSE NULL END,
                    CASE WHEN v_method_id = v_credit_card_id THEN 
                        CASE (random() * 4)::integer
                            WHEN 0 THEN '삼성카드'
                            WHEN 1 THEN '현대카드'
                            WHEN 2 THEN 'KB국민카드'
                            ELSE '신한카드'
                        END
                    ELSE NULL END,
                    CASE WHEN v_method_id = v_credit_card_id AND random() < 0.3 THEN (random() * 11 + 1)::integer ELSE 0 END,
                    CASE 
                        WHEN v_transaction_status = 'COMPLETED' THEN '0000'
                        WHEN v_transaction_status = 'FAILED' THEN '9999'
                        WHEN v_transaction_status = 'CANCELLED' THEN '0001'
                        ELSE NULL
                    END,
                    CASE 
                        WHEN v_transaction_status = 'COMPLETED' THEN '정상 처리되었습니다'
                        WHEN v_transaction_status = 'FAILED' THEN '결제 실패: 잔액 부족'
                        WHEN v_transaction_status = 'CANCELLED' THEN '사용자 취소'
                        ELSE NULL
                    END,
                    CASE WHEN v_transaction_status != 'PENDING' THEN 
                        jsonb_build_object(
                            'gateway', CASE 
                                WHEN v_method_id = v_credit_card_id THEN 'KCP'
                                WHEN v_method_id = v_virtual_account_id THEN 'INICIS'
                                ELSE 'BANK'
                            END,
                            'response_time', (100 + random() * 2000)::integer,
                            'transaction_id', 'GW' || LPAD((random() * 999999999)::bigint::text, 9, '0')
                        )
                    ELSE NULL END,
                    v_transaction_status = 'CANCELLED',
                    CASE WHEN v_transaction_status = 'CANCELLED' THEN v_payment_date ELSE NULL END,
                    CASE WHEN v_transaction_status = 'CANCELLED' THEN '사용자 요청에 의한 취소' ELSE NULL END,
                    CASE WHEN v_transaction_status = 'CANCELLED' THEN v_paid_amount ELSE 0 END,
                    v_transaction_status = 'COMPLETED' AND v_payment_date IS NOT NULL,
                    CASE WHEN v_transaction_status = 'COMPLETED' THEN v_paid_amount - (v_paid_amount * 0.025) ELSE NULL END,
                    CASE WHEN v_transaction_status = 'COMPLETED' THEN 'SETTLE' || TO_CHAR(v_payment_date + INTERVAL '1 day', 'YYYYMMDD') ELSE NULL END
                );
                
                transaction_count := transaction_count + 1;
            END;
        END LOOP;
        
        -- 4. 수납 대사 생성 (최근 3개월)
        FOR i IN 0..2 LOOP
            DECLARE
                v_reconciliation_date DATE := DATE_TRUNC('month', CURRENT_DATE) - (i || ' months')::INTERVAL + INTERVAL '1 month' - INTERVAL '1 day';
                v_start_date DATE := DATE_TRUNC('month', v_reconciliation_date);
                v_end_date DATE := v_reconciliation_date;
                v_system_total DECIMAL(15,2);
                v_bank_total DECIMAL(15,2);
                v_transaction_count INTEGER;
            BEGIN
                -- 해당 월의 거래 통계 계산
                SELECT COUNT(*), COALESCE(SUM(paid_amount), 0) INTO v_transaction_count, v_system_total
                FROM bms.payment_transactions
                WHERE company_id = company_rec.company_id
                  AND transaction_date >= v_start_date
                  AND transaction_date <= v_end_date + INTERVAL '1 day'
                  AND transaction_status = 'COMPLETED';
                
                -- 은행 총액 (시스템 총액에서 약간의 차이)
                v_bank_total := v_system_total + (random() * 20000 - 10000);  -- ±1만원 차이
                
                IF v_transaction_count > 0 THEN
                    INSERT INTO bms.payment_reconciliation (
                        company_id, reconciliation_date, reconciliation_type, reconciliation_status,
                        start_date, end_date,
                        total_transactions, matched_transactions, unmatched_transactions,
                        system_total_amount, bank_total_amount, difference_amount,
                        bank_statement_file_path, bank_statement_file_name, reconciliation_report_path,
                        processed_by, processed_at, processing_notes,
                        approved_by, approved_at, approval_notes,
                        created_by
                    ) VALUES (
                        company_rec.company_id, v_reconciliation_date, 'MONTHLY',
                        CASE WHEN i = 0 THEN 'PENDING' WHEN i = 1 THEN 'COMPLETED' ELSE 'APPROVED' END,
                        v_start_date, v_end_date,
                        v_transaction_count, 
                        v_transaction_count - (CASE WHEN ABS(v_bank_total - v_system_total) > 1000 THEN 1 ELSE 0 END),
                        CASE WHEN ABS(v_bank_total - v_system_total) > 1000 THEN 1 ELSE 0 END,
                        v_system_total, v_bank_total, v_bank_total - v_system_total,
                        '/reconciliation/' || company_rec.company_id || '/' || TO_CHAR(v_reconciliation_date, 'YYYY-MM') || '/bank_statement.xlsx',
                        'bank_statement_' || TO_CHAR(v_reconciliation_date, 'YYYY_MM') || '.xlsx',
                        '/reconciliation/' || company_rec.company_id || '/' || TO_CHAR(v_reconciliation_date, 'YYYY-MM') || '/reconciliation_report.pdf',
                        CASE WHEN i <= 1 THEN v_admin_user_id ELSE NULL END,
                        CASE WHEN i <= 1 THEN v_reconciliation_date + INTERVAL '2 days' ELSE NULL END,
                        CASE WHEN i <= 1 THEN '월별 정기 대사 완료' ELSE NULL END,
                        CASE WHEN i = 2 THEN v_admin_user_id ELSE NULL END,
                        CASE WHEN i = 2 THEN v_reconciliation_date + INTERVAL '3 days' ELSE NULL END,
                        CASE WHEN i = 2 THEN '대사 결과 승인' ELSE NULL END,
                        v_admin_user_id
                    );
                    
                    reconciliation_count := reconciliation_count + 1;
                END IF;
            END;
        END LOOP;
        
        RAISE NOTICE '회사 % 수납 관리 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 수납 관리 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 결제 방법: %개', method_count;
    RAISE NOTICE '생성된 수납 거래: %개', transaction_count;
    RAISE NOTICE '생성된 자동이체 설정: %개', auto_debit_count;
    RAISE NOTICE '생성된 수납 대사: %개', reconciliation_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 수납 관리 시스템 테스트 데이터 생성이 완료되었습니다!' as result;