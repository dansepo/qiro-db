-- =====================================================
-- 정산 및 환불 관리 시스템 테스트 데이터 생성 스크립트
-- Phase 5.3: 정산 및 환불 관리 시스템 테스트 데이터
-- =====================================================

-- 현재 회사 ID 설정 (테스트용)
SET app.current_company_id = 'c1234567-89ab-cdef-0123-456789abcdef';

-- 1. 정산 정책 테스트 데이터
INSERT INTO bms.settlement_policies (
    company_id,
    policy_name,
    policy_description,
    policy_type,
    settlement_threshold_amount,
    auto_settlement_enabled,
    auto_settlement_threshold,
    refund_method,
    refund_processing_days,
    refund_fee,
    balance_carry_forward,
    carry_forward_threshold,
    approval_required,
    approval_threshold_amount,
    notification_enabled,
    notification_methods,
    is_active
) VALUES 
-- 표준 정산 정책
(
    'c1234567-89ab-cdef-0123-456789abcdef',
    '표준 정산 정책',
    '일반적인 정산 및 환불을 위한 표준 정책',
    'STANDARD',
    1000,                      -- 1,000원 이상 정산 처리
    true,                      -- 자동 정산 활성화
    10000,                     -- 10,000원 이하 자동 처리
    'BANK_TRANSFER',           -- 기본 계좌 이체
    7,                         -- 7일 내 처리
    500,                       -- 환불 수수료 500원
    true,                      -- 차액 이월
    5000,                      -- 5,000원 이하 이월
    true,                      -- 승인 필요
    50000,                     -- 50,000원 이상 승인 필요
    true,                      -- 알림 활성화
    ARRAY['EMAIL', 'SMS'],     -- 이메일, SMS 알림
    true
),
-- 즉시 정산 정책 (VIP 고객용)
(
    'c1234567-89ab-cdef-0123-456789abcdef',
    '즉시 정산 정책',
    'VIP 고객을 위한 즉시 정산 정책',
    'IMMEDIATE',
    100,                       -- 100원 이상 즉시 정산
    true,                      -- 자동 정산 활성화
    100000,                    -- 100,000원 이하 자동 처리
    'BANK_TRANSFER',           -- 기본 계좌 이체
    1,                         -- 1일 내 처리
    0,                         -- 환불 수수료 없음
    false,                     -- 차액 이월 안함
    0,                         -- 이월 없음
    false,                     -- 승인 불필요
    1000000,                   -- 100만원 이상만 승인 필요
    true,                      -- 알림 활성화
    ARRAY['EMAIL', 'SMS', 'KAKAO_TALK'], -- 다채널 알림
    true
),
-- 월별 정산 정책
(
    'c1234567-89ab-cdef-0123-456789abcdef',
    '월별 정산 정책',
    '월말 일괄 정산을 위한 정책',
    'MONTHLY',
    5000,                      -- 5,000원 이상 정산
    false,                     -- 수동 정산
    NULL,                      -- 자동 정산 없음
    'NEXT_BILL_CREDIT',        -- 다음 청구서 차감
    30,                        -- 30일 내 처리
    0,                         -- 환불 수수료 없음
    true,                      -- 차액 이월
    20000,                     -- 20,000원 이하 이월
    true,                      -- 승인 필요
    30000,                     -- 30,000원 이상 승인 필요
    true,                      -- 알림 활성화
    ARRAY['EMAIL'],            -- 이메일 알림만
    true
);

-- 2. 정산 요청 테스트 데이터
-- 먼저 정산 정책 ID를 조회
DO $$
DECLARE
    v_standard_policy_id UUID;
    v_immediate_policy_id UUID;
    v_monthly_policy_id UUID;
    v_unit_id UUID;
BEGIN
    -- 정책 ID 조회
    SELECT policy_id INTO v_standard_policy_id 
    FROM bms.settlement_policies 
    WHERE policy_name = '표준 정산 정책' LIMIT 1;
    
    SELECT policy_id INTO v_immediate_policy_id 
    FROM bms.settlement_policies 
    WHERE policy_name = '즉시 정산 정책' LIMIT 1;
    
    SELECT policy_id INTO v_monthly_policy_id 
    FROM bms.settlement_policies 
    WHERE policy_name = '월별 정산 정책' LIMIT 1;
    
    -- 테스트용 세대 ID 조회 (첫 번째 세대 사용)
    SELECT unit_id INTO v_unit_id 
    FROM bms.units 
    WHERE company_id = 'c1234567-89ab-cdef-0123-456789abcdef' 
    LIMIT 1;
    
    -- 정산 요청 테스트 데이터 생성
    INSERT INTO bms.settlement_requests (
        company_id,
        unit_id,
        policy_id,
        request_number,
        request_type,
        request_status,
        target_period_start,
        target_period_end,
        total_charged_amount,
        total_paid_amount,
        settlement_amount,
        refund_fee_amount,
        final_settlement_amount,
        settlement_reason,
        settlement_description,
        approval_required,
        requested_at
    ) VALUES 
    -- 과납금 환불 요청 (승인 대기)
    (
        'c1234567-89ab-cdef-0123-456789abcdef',
        v_unit_id,
        v_standard_policy_id,
        'SR20241222-001',
        'OVERPAYMENT_REFUND',
        'PENDING',
        '2024-11-01',
        '2024-11-30',
        150000,                -- 청구 금액
        175000,                -- 납부 금액 (과납)
        25000,                 -- 정산 금액 (환불)
        500,                   -- 환불 수수료
        24500,                 -- 최종 환불 금액
        'OVERPAYMENT',
        '11월 관리비 과납으로 인한 환불 요청',
        true,
        NOW() - INTERVAL '2 days'
    ),
    -- 청구 오류로 인한 환불 요청 (승인됨)
    (
        'c1234567-89ab-cdef-0123-456789abcdef',
        v_unit_id,
        v_standard_policy_id,
        'SR20241222-002',
        'BILLING_ERROR',
        'APPROVED',
        '2024-10-01',
        '2024-10-31',
        200000,                -- 청구 금액
        200000,                -- 납부 금액
        15000,                 -- 정산 금액 (청구 오류 환불)
        500,                   -- 환불 수수료
        14500,                 -- 최종 환불 금액
        'BILLING_ERROR',
        '10월 관리비 청구 오류로 인한 환불',
        true,
        NOW() - INTERVAL '5 days',
        approved_at => NOW() - INTERVAL '1 day'
    ),
    -- 미납금 추가 징수 요청 (완료)
    (
        'c1234567-89ab-cdef-0123-456789abcdef',
        v_unit_id,
        v_monthly_policy_id,
        'SR20241222-003',
        'UNDERPAYMENT_CHARGE',
        'COMPLETED',
        '2024-09-01',
        '2024-09-30',
        180000,                -- 청구 금액
        160000,                -- 납부 금액 (미납)
        -20000,                -- 정산 금액 (추가 징수)
        0,                     -- 환불 수수료 없음
        -20000,                -- 최종 징수 금액
        'UNDERPAYMENT',
        '9월 관리비 미납분 추가 징수',
        true,
        NOW() - INTERVAL '10 days',
        approved_at => NOW() - INTERVAL '8 days',
        processed_at => NOW() - INTERVAL '3 days'
    ),
    -- 요율 조정으로 인한 환불 (처리중)
    (
        'c1234567-89ab-cdef-0123-456789abcdef',
        v_unit_id,
        v_immediate_policy_id,
        'SR20241222-004',
        'RATE_ADJUSTMENT',
        'PROCESSING',
        '2024-12-01',
        '2024-12-31',
        220000,                -- 청구 금액
        220000,                -- 납부 금액
        8000,                  -- 정산 금액 (요율 조정 환불)
        0,                     -- VIP는 수수료 없음
        8000,                  -- 최종 환불 금액
        'RATE_ERROR',
        '12월 관리비 요율 조정으로 인한 환불',
        false,                 -- 즉시 정산 정책으로 승인 불필요
        NOW() - INTERVAL '1 day',
        approved_at => NOW() - INTERVAL '1 day'
    );
END $$;

-- 3. 환불 거래 테스트 데이터
-- 승인된 정산 요청에 대한 환불 거래 생성
DO $$
DECLARE
    v_request_record RECORD;
BEGIN
    -- 승인된 환불 요청들에 대해 환불 거래 생성
    FOR v_request_record IN 
        SELECT request_id, company_id, final_settlement_amount
        FROM bms.settlement_requests 
        WHERE request_status IN ('APPROVED', 'PROCESSING') 
        AND final_settlement_amount > 0
    LOOP
        INSERT INTO bms.refund_transactions (
            company_id,
            request_id,
            transaction_number,
            refund_method,
            refund_amount,
            refund_fee,
            net_refund_amount,
            recipient_name,
            recipient_account_info,
            transaction_status,
            scheduled_date,
            processed_date,
            completed_date
        ) VALUES (
            v_request_record.company_id,
            v_request_record.request_id,
            'RT' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD((EXTRACT(EPOCH FROM NOW()) + random() * 1000)::INTEGER::TEXT, 6, '0'),
            'BANK_TRANSFER',
            v_request_record.final_settlement_amount + 500, -- 원래 환불 금액 + 수수료
            500,                                            -- 환불 수수료
            v_request_record.final_settlement_amount,       -- 실 환불 금액
            '김철수',
            jsonb_build_object(
                'bank_name', '국민은행',
                'account_number', '123-456-789012',
                'account_holder', '김철수'
            ),
            CASE 
                WHEN random() < 0.3 THEN 'COMPLETED'
                WHEN random() < 0.6 THEN 'PROCESSING'
                ELSE 'SCHEDULED'
            END,
            CURRENT_DATE + (random() * 7)::INTEGER,
            CASE WHEN random() < 0.5 THEN CURRENT_DATE + (random() * 3)::INTEGER ELSE NULL END,
            CASE WHEN random() < 0.3 THEN CURRENT_DATE + (random() * 5)::INTEGER ELSE NULL END
        );
    END LOOP;
END $$;

-- 4. 차액 조정 테스트 데이터
DO $$
DECLARE
    v_unit_id UUID;
    v_request_id UUID;
BEGIN
    -- 테스트용 세대 ID 조회
    SELECT unit_id INTO v_unit_id 
    FROM bms.units 
    WHERE company_id = 'c1234567-89ab-cdef-0123-456789abcdef' 
    LIMIT 1;
    
    -- 완료된 정산 요청 ID 조회
    SELECT request_id INTO v_request_id 
    FROM bms.settlement_requests 
    WHERE request_status = 'COMPLETED' 
    LIMIT 1;
    
    INSERT INTO bms.balance_adjustments (
        company_id,
        unit_id,
        request_id,
        adjustment_number,
        adjustment_type,
        adjustment_reason,
        target_period_start,
        target_period_end,
        original_amount,
        adjusted_amount,
        adjustment_difference,
        adjustment_description,
        adjustment_status,
        applied_to_next_bill,
        next_bill_credit_amount,
        approved_at,
        applied_at
    ) VALUES 
    -- 과납금 차감 조정
    (
        'c1234567-89ab-cdef-0123-456789abcdef',
        v_unit_id,
        v_request_id,
        'BA20241222-001',
        'CREDIT',
        'OVERPAYMENT',
        '2024-09-01',
        '2024-09-30',
        180000,                -- 원래 금액
        160000,                -- 조정 후 금액
        -20000,                -- 차액 (차감)
        '9월 관리비 과납분 다음 청구서 차감',
        'APPLIED',
        true,                  -- 다음 청구서 반영
        20000,                 -- 다음 청구서 차감 금액
        NOW() - INTERVAL '3 days',
        NOW() - INTERVAL '1 day'
    ),
    -- 요율 정정 조정
    (
        'c1234567-89ab-cdef-0123-456789abcdef',
        v_unit_id,
        NULL,                  -- 정산 요청과 무관한 조정
        'BA20241222-002',
        'CORRECTION',
        'RATE_CORRECTION',
        '2024-11-01',
        '2024-11-30',
        150000,                -- 원래 금액
        145000,                -- 조정 후 금액
        -5000,                 -- 차액 (차감)
        '11월 관리비 요율 정정으로 인한 조정',
        'APPROVED',
        false,                 -- 다음 청구서 미반영
        0,
        NOW() - INTERVAL '1 day',
        NULL
    ),
    -- 검침 정정 조정
    (
        'c1234567-89ab-cdef-0123-456789abcdef',
        v_unit_id,
        NULL,
        'BA20241222-003',
        'DEBIT',
        'METER_CORRECTION',
        '2024-10-01',
        '2024-10-31',
        200000,                -- 원래 금액
        210000,                -- 조정 후 금액
        10000,                 -- 차액 (추가)
        '10월 관리비 검침 정정으로 인한 추가 청구',
        'PENDING',
        false,
        0,
        NULL,
        NULL
    );
END $$;

-- 5. 정산 알림 테스트 데이터
DO $$
DECLARE
    v_request_record RECORD;
    v_transaction_record RECORD;
BEGIN
    -- 정산 요청에 대한 알림 생성
    FOR v_request_record IN 
        SELECT request_id, company_id, request_status
        FROM bms.settlement_requests 
        LIMIT 3
    LOOP
        -- 요청 접수 알림
        INSERT INTO bms.settlement_notifications (
            company_id,
            request_id,
            notification_type,
            notification_method,
            notification_status,
            notification_title,
            notification_content,
            recipient_name,
            recipient_contact,
            scheduled_at,
            sent_at,
            delivery_status,
            is_read
        ) VALUES (
            v_request_record.company_id,
            v_request_record.request_id,
            'REQUEST_SUBMITTED',
            'EMAIL',
            'SENT',
            '[정산요청] 정산 요청이 접수되었습니다',
            '정산 요청이 정상적으로 접수되었습니다. 검토 후 처리 결과를 안내드리겠습니다.',
            '김철수',
            'kim.cs@email.com',
            NOW() - INTERVAL '2 days',
            NOW() - INTERVAL '2 days',
            'DELIVERED',
            true
        );
        
        -- 승인된 요청에 대한 승인 알림
        IF v_request_record.request_status IN ('APPROVED', 'PROCESSING', 'COMPLETED') THEN
            INSERT INTO bms.settlement_notifications (
                company_id,
                request_id,
                notification_type,
                notification_method,
                notification_status,
                notification_title,
                notification_content,
                recipient_name,
                recipient_contact,
                scheduled_at,
                sent_at,
                delivery_status,
                is_read
            ) VALUES (
                v_request_record.company_id,
                v_request_record.request_id,
                'REQUEST_APPROVED',
                'SMS',
                'SENT',
                '[정산승인] 정산 요청이 승인되었습니다',
                '정산 요청이 승인되었습니다. 환불 처리를 진행하겠습니다.',
                '김철수',
                '010-1234-5678',
                NOW() - INTERVAL '1 day',
                NOW() - INTERVAL '1 day',
                'DELIVERED',
                false
            );
        END IF;
    END LOOP;
    
    -- 환불 거래에 대한 알림 생성
    FOR v_transaction_record IN 
        SELECT transaction_id, company_id, transaction_status
        FROM bms.refund_transactions 
        WHERE transaction_status = 'COMPLETED'
        LIMIT 2
    LOOP
        INSERT INTO bms.settlement_notifications (
            company_id,
            transaction_id,
            notification_type,
            notification_method,
            notification_status,
            notification_title,
            notification_content,
            recipient_name,
            recipient_contact,
            scheduled_at,
            sent_at,
            delivery_status,
            is_read
        ) VALUES (
            v_transaction_record.company_id,
            v_transaction_record.transaction_id,
            'REFUND_COMPLETED',
            'KAKAO_TALK',
            'SENT',
            '[환불완료] 환불이 완료되었습니다',
            '요청하신 환불이 완료되었습니다. 계좌를 확인해 주세요.',
            '김철수',
            '010-1234-5678',
            NOW() - INTERVAL '6 hours',
            NOW() - INTERVAL '6 hours',
            'DELIVERED',
            true
        );
    END LOOP;
END $$;

-- 6. 정산 관리 함수 테스트
SELECT '=== 정산 금액 계산 함수 테스트 ===' as test_section;

-- 테스트용 세대에 대한 정산 금액 계산
DO $$
DECLARE
    v_unit_id UUID;
    v_calc_result RECORD;
BEGIN
    SELECT unit_id INTO v_unit_id 
    FROM bms.units 
    WHERE company_id = 'c1234567-89ab-cdef-0123-456789abcdef' 
    LIMIT 1;
    
    IF v_unit_id IS NOT NULL THEN
        SELECT * INTO v_calc_result
        FROM bms.calculate_settlement_amount(v_unit_id, '2024-11-01', '2024-11-30');
        
        RAISE NOTICE '정산 계산 결과 - 청구: %, 납부: %, 정산: %, 유형: %', 
            v_calc_result.total_charged, 
            v_calc_result.total_paid, 
            v_calc_result.settlement_amount, 
            v_calc_result.settlement_type;
    END IF;
END $$;

-- 7. 정산 관리 뷰 테스트
SELECT '=== 정산 대시보드 뷰 테스트 ===' as test_section;
SELECT 
    request_number,
    unit_number,
    settlement_type_display,
    status_display,
    final_settlement_amount,
    requested_at::DATE,
    priority_score
FROM bms.v_settlement_dashboard 
ORDER BY priority_score DESC, requested_at DESC
LIMIT 5;

SELECT '=== 정산 통계 뷰 테스트 ===' as test_section;
SELECT 
    total_requests,
    pending_count,
    approved_count,
    completed_count,
    total_refund_amount,
    total_charge_amount,
    refund_request_count,
    charge_request_count
FROM bms.v_settlement_statistics;

SELECT '=== 환불 거래 현황 뷰 테스트 ===' as test_section;
SELECT 
    transaction_number,
    unit_number,
    status_display,
    refund_amount,
    net_refund_amount,
    scheduled_date,
    is_overdue,
    days_until_scheduled
FROM bms.v_refund_status 
ORDER BY scheduled_date
LIMIT 5;

-- 8. 정산 요청 상세 조회 테스트
SELECT '=== 정산 요청 상세 조회 테스트 ===' as test_section;
SELECT 
    sr.request_number,
    sr.request_type,
    sr.request_status,
    sr.settlement_reason,
    sr.total_charged_amount,
    sr.total_paid_amount,
    sr.settlement_amount,
    sr.final_settlement_amount,
    sr.requested_at::DATE,
    sr.approved_at::DATE,
    u.unit_number,
    sp.policy_name
FROM bms.settlement_requests sr
JOIN bms.units u ON sr.unit_id = u.unit_id
JOIN bms.settlement_policies sp ON sr.policy_id = sp.policy_id
ORDER BY sr.requested_at DESC;

-- 9. 환불 거래 상세 조회 테스트
SELECT '=== 환불 거래 상세 조회 테스트 ===' as test_section;
SELECT 
    rt.transaction_number,
    rt.refund_method,
    rt.transaction_status,
    rt.refund_amount,
    rt.net_refund_amount,
    rt.recipient_name,
    rt.scheduled_date,
    rt.processed_date,
    rt.completed_date,
    sr.request_number
FROM bms.refund_transactions rt
JOIN bms.settlement_requests sr ON rt.request_id = sr.request_id
ORDER BY rt.created_at DESC;

-- 10. 차액 조정 이력 조회 테스트
SELECT '=== 차액 조정 이력 조회 테스트 ===' as test_section;
SELECT 
    ba.adjustment_number,
    ba.adjustment_type,
    ba.adjustment_reason,
    ba.adjustment_status,
    ba.original_amount,
    ba.adjusted_amount,
    ba.adjustment_difference,
    ba.applied_to_next_bill,
    ba.next_bill_credit_amount,
    u.unit_number
FROM bms.balance_adjustments ba
JOIN bms.units u ON ba.unit_id = u.unit_id
ORDER BY ba.created_at DESC;

-- 11. 정산 알림 이력 조회 테스트
SELECT '=== 정산 알림 이력 조회 테스트 ===' as test_section;
SELECT 
    sn.notification_type,
    sn.notification_method,
    sn.notification_status,
    sn.delivery_status,
    sn.recipient_name,
    sn.sent_at::DATE,
    sn.is_read,
    sr.request_number
FROM bms.settlement_notifications sn
LEFT JOIN bms.settlement_requests sr ON sn.request_id = sr.request_id
ORDER BY sn.sent_at DESC;

-- 테스트 완료 메시지
SELECT '정산 및 환불 관리 시스템 테스트 데이터 생성 및 테스트가 완료되었습니다.' as message;