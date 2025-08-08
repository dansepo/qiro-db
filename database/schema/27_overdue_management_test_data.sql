-- =====================================================
-- 연체 관리 시스템 테스트 데이터 생성 스크립트
-- Phase 5.2: 연체 관리 시스템 테스트 데이터
-- =====================================================

-- 현재 회사 ID 설정 (테스트용)
SET app.current_company_id = 'c1234567-89ab-cdef-0123-456789abcdef';

-- 1. 연체 정책 테스트 데이터
INSERT INTO bms.overdue_policies (
    policy_id,
    company_id,
    building_id,
    policy_name,
    policy_description,
    policy_type,
    grace_period_days,
    overdue_threshold_days,
    late_fee_calculation_method,
    daily_late_fee_rate,
    max_late_fee_rate,
    min_late_fee_amount,
    stage_configurations,
    exemption_conditions,
    notification_enabled,
    notification_stages,
    notification_channels,
    legal_action_enabled,
    legal_action_threshold_days,
    legal_action_threshold_amount,
    is_active,
    created_by
) VALUES 
-- 표준 연체 정책
(
    'op000001-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    NULL, -- 회사 전체 적용
    '표준 연체 정책',
    '일반적인 연체 관리를 위한 표준 정책',
    'STANDARD',
    5, -- 5일 유예기간
    10, -- 10일 후 연체 시작
    'DAILY_RATE',
    0.025, -- 일일 0.025% (연 9.125%)
    25.0, -- 최대 25%
    1000, -- 최소 1,000원
    '{
        "stages": [
            {"stage": "INITIAL", "days": 7, "actions": ["EMAIL", "SMS"]},
            {"stage": "WARNING", "days": 30, "actions": ["EMAIL", "SMS", "POSTAL"]},
            {"stage": "DEMAND", "days": 60, "actions": ["PHONE_CALL", "POSTAL"]},
            {"stage": "FINAL_NOTICE", "days": 90, "actions": ["POSTAL", "VISIT"]},
            {"stage": "LEGAL_ACTION", "days": 120, "actions": ["LEGAL_DOCUMENT"]}
        ]
    }',
    '{
        "conditions": [
            {"type": "SENIOR_CITIZEN", "age_threshold": 65, "discount_rate": 50},
            {"type": "LOW_INCOME", "income_threshold": 2000000, "discount_rate": 30},
            {"type": "DISABILITY", "discount_rate": 50}
        ]
    }',
    true,
    ARRAY['INITIAL', 'WARNING', 'DEMAND', 'FINAL_NOTICE'],
    ARRAY['EMAIL', 'SMS', 'KAKAO_TALK', 'POSTAL'],
    true,
    120, -- 120일 후 법적 조치
    500000, -- 50만원 이상시 법적 조치
    true,
    'u1234567-89ab-cdef-0123-456789abcdef'
),
-- 관대한 연체 정책 (고령자 건물용)
(
    'op000002-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'b1234567-89ab-cdef-0123-456789abcdef',
    '관대한 연체 정책',
    '고령자 거주 건물을 위한 관대한 연체 정책',
    'LENIENT',
    10, -- 10일 유예기간
    15, -- 15일 후 연체 시작
    'DAILY_RATE',
    0.015, -- 일일 0.015% (연 5.475%)
    15.0, -- 최대 15%
    500, -- 최소 500원
    '{
        "stages": [
            {"stage": "INITIAL", "days": 14, "actions": ["EMAIL"]},
            {"stage": "WARNING", "days": 45, "actions": ["EMAIL", "POSTAL"]},
            {"stage": "DEMAND", "days": 90, "actions": ["PHONE_CALL", "POSTAL"]},
            {"stage": "FINAL_NOTICE", "days": 150, "actions": ["POSTAL", "VISIT"]},
            {"stage": "LEGAL_ACTION", "days": 180, "actions": ["LEGAL_DOCUMENT"]}
        ]
    }',
    '{
        "conditions": [
            {"type": "SENIOR_CITIZEN", "age_threshold": 60, "discount_rate": 70},
            {"type": "MEDICAL_HARDSHIP", "discount_rate": 80}
        ]
    }',
    true,
    ARRAY['INITIAL', 'WARNING', 'DEMAND'],
    ARRAY['EMAIL', 'POSTAL'],
    true,
    180, -- 180일 후 법적 조치
    1000000, -- 100만원 이상시 법적 조치
    true,
    'u1234567-89ab-cdef-0123-456789abcdef'
),
-- 엄격한 연체 정책 (상업용 건물)
(
    'op000003-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'b2345678-9abc-def0-1234-56789abcdef0',
    '엄격한 연체 정책',
    '상업용 건물을 위한 엄격한 연체 정책',
    'STRICT',
    0, -- 유예기간 없음
    5, -- 5일 후 연체 시작
    'DAILY_RATE',
    0.05, -- 일일 0.05% (연 18.25%)
    30.0, -- 최대 30%
    5000, -- 최소 5,000원
    '{
        "stages": [
            {"stage": "INITIAL", "days": 3, "actions": ["EMAIL", "SMS"]},
            {"stage": "WARNING", "days": 15, "actions": ["EMAIL", "SMS", "PHONE_CALL"]},
            {"stage": "DEMAND", "days": 30, "actions": ["PHONE_CALL", "POSTAL", "VISIT"]},
            {"stage": "FINAL_NOTICE", "days": 45, "actions": ["POSTAL", "VISIT"]},
            {"stage": "LEGAL_ACTION", "days": 60, "actions": ["LEGAL_DOCUMENT"]}
        ]
    }',
    '{
        "conditions": [
            {"type": "REPEAT_OFFENDER", "threshold_count": 3, "penalty_rate": 150}
        ]
    }',
    true,
    ARRAY['INITIAL', 'WARNING', 'DEMAND', 'FINAL_NOTICE'],
    ARRAY['EMAIL', 'SMS', 'PHONE_CALL', 'POSTAL'],
    true,
    60, -- 60일 후 법적 조치
    200000, -- 20만원 이상시 법적 조치
    true,
    'u1234567-89ab-cdef-0123-456789abcdef'
);

-- 2. 연체 현황 테스트 데이터
-- 먼저 연체 대상 청구서들을 조회하여 연체 기록 생성
INSERT INTO bms.overdue_records (
    overdue_id,
    company_id,
    issuance_id,
    policy_id,
    overdue_status,
    overdue_stage,
    original_amount,
    outstanding_amount,
    late_fee_amount,
    total_overdue_amount,
    due_date,
    overdue_start_date,
    overdue_days,
    late_fee_calculation_date,
    late_fee_rate_applied,
    late_fee_calculation_details,
    notification_count,
    last_notification_date,
    next_notification_date
) VALUES 
-- 초기 연체 단계 (7일 연체)
(
    'or000001-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'bi000001-1234-5678-9abc-def123456789', -- 101호 2024년 11월
    'op000001-1234-5678-9abc-def123456789',
    'ACTIVE',
    'INITIAL',
    150000,
    150000,
    262.50, -- 150000 * 0.025% * 7일
    150262.50,
    '2024-12-05',
    '2024-12-15', -- 10일 후 연체 시작
    7, -- 현재 7일 연체
    CURRENT_DATE,
    0.025,
    '{
        "method": "DAILY_RATE",
        "base_amount": 150000,
        "daily_rate": 0.025,
        "days_overdue": 7,
        "calculation": "150000 × 0.025% × 7일",
        "final_amount": 262.50,
        "calculation_date": "2024-12-22"
    }',
    1,
    '2024-12-20',
    '2024-12-27'
),
-- 경고 단계 (35일 연체)
(
    'or000002-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'bi000002-1234-5678-9abc-def123456789', -- 102호 2024년 10월
    'op000001-1234-5678-9abc-def123456789',
    'ACTIVE',
    'WARNING',
    180000,
    180000,
    1575.00, -- 180000 * 0.025% * 35일
    181575.00,
    '2024-11-05',
    '2024-11-15', -- 10일 후 연체 시작
    35, -- 현재 35일 연체
    CURRENT_DATE,
    0.025,
    '{
        "method": "DAILY_RATE",
        "base_amount": 180000,
        "daily_rate": 0.025,
        "days_overdue": 35,
        "calculation": "180000 × 0.025% × 35일",
        "final_amount": 1575.00,
        "calculation_date": "2024-12-22"
    }',
    3,
    '2024-12-18',
    '2024-12-25'
),
-- 독촉 단계 (65일 연체)
(
    'or000003-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'bi000003-1234-5678-9abc-def123456789', -- 103호 2024년 9월
    'op000001-1234-5678-9abc-def123456789',
    'ACTIVE',
    'DEMAND',
    200000,
    200000,
    3250.00, -- 200000 * 0.025% * 65일
    203250.00,
    '2024-10-05',
    '2024-10-15', -- 10일 후 연체 시작
    65, -- 현재 65일 연체
    CURRENT_DATE,
    0.025,
    '{
        "method": "DAILY_RATE",
        "base_amount": 200000,
        "daily_rate": 0.025,
        "days_overdue": 65,
        "calculation": "200000 × 0.025% × 65일",
        "final_amount": 3250.00,
        "calculation_date": "2024-12-22"
    }',
    5,
    '2024-12-15',
    '2024-12-22',
    warning_issued = true,
    warning_issued_date = '2024-11-20'
),
-- 최종 통지 단계 (95일 연체)
(
    'or000004-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'bi000004-1234-5678-9abc-def123456789', -- 201호 2024년 8월
    'op000001-1234-5678-9abc-def123456789',
    'ACTIVE',
    'FINAL_NOTICE',
    250000,
    250000,
    5937.50, -- 250000 * 0.025% * 95일
    255937.50,
    '2024-09-05',
    '2024-09-15', -- 10일 후 연체 시작
    95, -- 현재 95일 연체
    CURRENT_DATE,
    0.025,
    '{
        "method": "DAILY_RATE",
        "base_amount": 250000,
        "daily_rate": 0.025,
        "days_overdue": 95,
        "calculation": "250000 × 0.025% × 95일",
        "final_amount": 5937.50,
        "calculation_date": "2024-12-22"
    }',
    7,
    '2024-12-10',
    '2024-12-17',
    warning_issued = true,
    warning_issued_date = '2024-10-15'
),
-- 법적 조치 단계 (130일 연체)
(
    'or000005-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'bi000005-1234-5678-9abc-def123456789', -- 202호 2024년 7월
    'op000001-1234-5678-9abc-def123456789',
    'ACTIVE',
    'LEGAL_ACTION',
    300000,
    300000,
    9750.00, -- 300000 * 0.025% * 130일
    309750.00,
    '2024-08-05',
    '2024-08-15', -- 10일 후 연체 시작
    130, -- 현재 130일 연체
    CURRENT_DATE,
    0.025,
    '{
        "method": "DAILY_RATE",
        "base_amount": 300000,
        "daily_rate": 0.025,
        "days_overdue": 130,
        "calculation": "300000 × 0.025% × 130일",
        "final_amount": 9750.00,
        "calculation_date": "2024-12-22"
    }',
    10,
    '2024-12-05',
    '2024-12-12',
    warning_issued = true,
    warning_issued_date = '2024-09-15',
    legal_action_initiated = true,
    legal_action_date = '2024-12-01'
),
-- 해결된 연체 (부분 납부)
(
    'or000006-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'bi000006-1234-5678-9abc-def123456789', -- 301호 2024년 10월
    'op000001-1234-5678-9abc-def123456789',
    'RESOLVED',
    'WARNING',
    170000,
    50000, -- 부분 납부 후 잔액
    875.00, -- 170000 * 0.025% * 35일 (해결 시점 기준)
    50875.00,
    '2024-11-05',
    '2024-11-15',
    35,
    '2024-12-20',
    0.025,
    '{
        "method": "DAILY_RATE",
        "base_amount": 170000,
        "daily_rate": 0.025,
        "days_overdue": 35,
        "calculation": "170000 × 0.025% × 35일",
        "final_amount": 875.00,
        "calculation_date": "2024-12-20"
    }',
    4,
    '2024-12-15',
    NULL,
    is_resolved = true,
    resolved_date = '2024-12-20',
    resolution_method = 'PARTIAL_PAYMENT',
    resolution_amount = 120000,
    resolution_notes = '원금 120,000원 부분 납부 완료'
),
-- 면제된 연체 (고령자)
(
    'or000007-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'bi000007-1234-5678-9abc-def123456789', -- 302호 2024년 11월
    'op000002-1234-5678-9abc-def123456789', -- 관대한 정책
    'EXEMPTED',
    'WARNING',
    160000,
    160000,
    0, -- 면제로 인해 연체료 0
    160000,
    '2024-12-05',
    '2024-12-20', -- 15일 후 연체 시작 (관대한 정책)
    2, -- 현재 2일 연체
    '2024-12-22',
    0.015,
    '{
        "method": "DAILY_RATE",
        "base_amount": 160000,
        "daily_rate": 0.015,
        "days_overdue": 2,
        "calculation": "160000 × 0.015% × 2일",
        "exemption_applied": true,
        "original_late_fee": 48.00,
        "final_amount": 0,
        "calculation_date": "2024-12-22"
    }',
    1,
    '2024-12-21',
    NULL,
    is_exempted = true,
    exemption_reason = '고령자 연체료 면제 (만 70세)',
    exempted_by = 'u1234567-89ab-cdef-0123-456789abcdef',
    exempted_at = '2024-12-22 10:30:00+09'
);

-- 3. 연체 알림 이력 테스트 데이터
INSERT INTO bms.overdue_notifications (
    notification_id,
    overdue_id,
    company_id,
    notification_type,
    notification_stage,
    notification_method,
    notification_title,
    notification_content,
    recipient_name,
    recipient_contact,
    recipient_address,
    scheduled_at,
    sent_at,
    delivery_status,
    is_read,
    read_at,
    notification_cost
) VALUES 
-- 101호 초기 알림
(
    'on000001-1234-5678-9abc-def123456789',
    'or000001-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'REMINDER',
    'INITIAL',
    'EMAIL',
    '[그린빌라] 관리비 납부 안내',
    E'안녕하세요. 그린빌라입니다.\n\n101호 2024년 11월 관리비가 연체되었습니다.\n\n연체 정보:\n- 원금: 150000원\n- 연체료: 262원\n- 총 연체금액: 150262원\n- 연체일수: 7일\n\n빠른 시일 내에 납부해 주시기 바랍니다.',
    '김철수',
    'kim.cs@email.com',
    '서울시 강남구 테헤란로 123, 101호',
    '2024-12-20 09:00:00+09',
    '2024-12-20 09:05:00+09',
    'DELIVERED',
    true,
    '2024-12-20 14:30:00+09',
    0
),
-- 102호 경고 알림 (SMS)
(
    'on000002-1234-5678-9abc-def123456789',
    'or000002-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'WARNING',
    'WARNING',
    'SMS',
    '[그린빌라] 관리비 연체 경고',
    '[그린빌라] 102호 관리비 35일 연체. 총 181,575원. 즉시 납부 바랍니다. 문의: 02-1234-5678',
    '이영희',
    '010-2345-6789',
    '서울시 강남구 테헤란로 123, 102호',
    '2024-12-18 10:00:00+09',
    '2024-12-18 10:01:00+09',
    'DELIVERED',
    false,
    NULL,
    50
),
-- 103호 독촉 알림 (우편)
(
    'on000003-1234-5678-9abc-def123456789',
    'or000003-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'DEMAND',
    'DEMAND',
    'POSTAL',
    '[그린빌라] 관리비 납부 독촉',
    E'안녕하세요. 그린빌라입니다.\n\n103호 2024년 9월 관리비가 65일간 연체되었습니다.\n\n연체 정보:\n- 원금: 200000원\n- 연체료: 3250원\n- 총 연체금액: 203250원\n- 연체일수: 65일\n\n더 이상 연체가 지속될 경우 법적 조치를 취할 수 있습니다.\n즉시 납부해 주시기 바랍니다.',
    '박민수',
    '010-3456-7890',
    '서울시 강남구 테헤란로 123, 103호',
    '2024-12-15 15:00:00+09',
    '2024-12-16 08:00:00+09',
    'DELIVERED',
    false,
    NULL,
    1500
),
-- 201호 최종 통지 (카카오톡)
(
    'on000004-1234-5678-9abc-def123456789',
    'or000004-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'FINAL_NOTICE',
    'FINAL_NOTICE',
    'KAKAO_TALK',
    '[그린빌라] 관리비 최종 납부 통지',
    E'[그린빌라 최종통지]\n\n201호 관리비 95일 연체\n총 255,937원\n\n법적조치 임박\n즉시 납부 필수\n\n문의: 02-1234-5678',
    '정수진',
    '010-4567-8901',
    '서울시 강남구 테헤란로 123, 201호',
    '2024-12-10 11:00:00+09',
    '2024-12-10 11:02:00+09',
    'DELIVERED',
    true,
    '2024-12-10 16:45:00+09',
    100
),
-- 202호 법적 통지
(
    'on000005-1234-5678-9abc-def123456789',
    'or000005-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'LEGAL_NOTICE',
    'LEGAL_ACTION',
    'POSTAL',
    '[그린빌라] 법적 조치 예고 통지',
    E'안녕하세요. 그린빌라입니다.\n\n202호 2024년 7월 관리비가 130일간 연체되어 법적 조치를 진행합니다.\n\n연체 정보:\n- 원금: 300000원\n- 연체료: 9750원\n- 총 연체금액: 309750원\n- 연체일수: 130일\n\n본 통지서 수령 후 7일 이내 납부하지 않을 경우\n법원에 지급명령 신청을 진행할 예정입니다.\n\n즉시 납부하여 주시기 바랍니다.',
    '최동호',
    '010-5678-9012',
    '서울시 강남구 테헤란로 123, 202호',
    '2024-12-05 14:00:00+09',
    '2024-12-06 09:00:00+09',
    'DELIVERED',
    false,
    NULL,
    2000
);

-- 4. 연체 조치 이력 테스트 데이터
INSERT INTO bms.overdue_actions (
    action_id,
    overdue_id,
    company_id,
    action_type,
    action_stage,
    action_description,
    scheduled_date,
    executed_date,
    action_status,
    assigned_to,
    executed_by,
    action_result,
    result_amount,
    result_description,
    action_cost,
    recovery_amount,
    document_type,
    legal_reference
) VALUES 
-- 102호 전화 독촉
(
    'oa000001-1234-5678-9abc-def123456789',
    'or000002-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'PHONE_CALL',
    'WARNING',
    '102호 이영희님께 전화 독촉 실시',
    '2024-12-18',
    '2024-12-18',
    'COMPLETED',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'NO_RESPONSE',
    0,
    '전화 연결되지 않음. 음성사서함 메시지 남김',
    0,
    0,
    'NOTICE',
    NULL
),
-- 103호 방문 독촉
(
    'oa000002-1234-5678-9abc-def123456789',
    'or000003-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'VISIT',
    'DEMAND',
    '103호 박민수님 댁 방문 독촉',
    '2024-12-16',
    '2024-12-16',
    'COMPLETED',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'PARTIAL_SUCCESS',
    50000,
    '방문하여 상황 설명. 50만원 부분 납부 약속 받음',
    5000, -- 교통비
    0,
    'NOTICE',
    NULL
),
-- 201호 납부 계획 수립
(
    'oa000003-1234-5678-9abc-def123456789',
    'or000004-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'PAYMENT_PLAN',
    'FINAL_NOTICE',
    '201호 정수진님과 분할 납부 계획 협의',
    '2024-12-12',
    '2024-12-12',
    'COMPLETED',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'SUCCESS',
    255937.50,
    '3개월 분할 납부 계획 수립. 월 85,000원씩 납부 약속',
    0,
    0,
    'SETTLEMENT_AGREEMENT',
    NULL
),
-- 202호 법적 상담
(
    'oa000004-1234-5678-9abc-def123456789',
    'or000005-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'LEGAL_CONSULTATION',
    'LEGAL_ACTION',
    '202호 연체 건에 대한 법무법인 상담',
    '2024-12-01',
    '2024-12-01',
    'COMPLETED',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'SUCCESS',
    0,
    '지급명령 신청 절차 확인. 필요 서류 준비 완료',
    100000, -- 법무 상담비
    0,
    'LEGAL_DOCUMENT',
    '민사집행법 제470조'
),
-- 202호 법원 제출 (예정)
(
    'oa000005-1234-5678-9abc-def123456789',
    'or000005-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'COURT_FILING',
    'LEGAL_ACTION',
    '202호 연체 건 지급명령 신청서 법원 제출',
    '2024-12-25',
    NULL,
    'PLANNED',
    'u1234567-89ab-cdef-0123-456789abcdef',
    NULL,
    NULL,
    309750.00,
    '지급명령 신청 예정',
    50000, -- 법원 수수료
    0,
    'COURT_DOCUMENT',
    '민사집행법 제470조'
),
-- 301호 합의 협상 (해결된 건)
(
    'oa000006-1234-5678-9abc-def123456789',
    'or000006-1234-5678-9abc-def123456789',
    'c1234567-89ab-cdef-0123-456789abcdef',
    'SETTLEMENT',
    'WARNING',
    '301호 연체료 감면 협상',
    '2024-12-19',
    '2024-12-20',
    'COMPLETED',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'u1234567-89ab-cdef-0123-456789abcdef',
    'SUCCESS',
    120000,
    '연체료 50% 감면 조건으로 원금 120,000원 즉시 납부 합의',
    0,
    120000,
    'SETTLEMENT_AGREEMENT',
    NULL
);

-- 5. 연체 관리 함수 테스트
-- 연체 현황 업데이트 테스트
SELECT '=== 연체 현황 업데이트 테스트 ===' as test_section;
SELECT * FROM bms.update_overdue_status('c1234567-89ab-cdef-0123-456789abcdef');

-- 연체료 계산 테스트
SELECT '=== 연체료 계산 테스트 ===' as test_section;
SELECT 
    'or000001 (7일 연체)' as case_name,
    * 
FROM bms.calculate_late_fee('or000001-1234-5678-9abc-def123456789');

SELECT 
    'or000003 (65일 연체)' as case_name,
    * 
FROM bms.calculate_late_fee('or000003-1234-5678-9abc-def123456789');

-- 연체 알림 생성 테스트
SELECT '=== 연체 알림 생성 테스트 ===' as test_section;
SELECT bms.create_overdue_notification(
    'or000001-1234-5678-9abc-def123456789',
    'REMINDER',
    'EMAIL'
) as new_notification_id;

-- 6. 연체 관리 뷰 테스트
SELECT '=== 연체 대시보드 뷰 테스트 ===' as test_section;
SELECT 
    unit_number,
    resident_name,
    overdue_status,
    overdue_stage,
    overdue_days,
    total_overdue_amount,
    overdue_period_category,
    amount_category,
    ROUND(priority_score, 2) as priority_score
FROM bms.v_overdue_dashboard 
ORDER BY priority_score DESC
LIMIT 10;

SELECT '=== 연체 통계 뷰 테스트 ===' as test_section;
SELECT 
    total_overdue_count,
    total_overdue_amount,
    ROUND(avg_overdue_days, 1) as avg_overdue_days,
    active_count,
    resolved_count,
    exempted_count,
    initial_stage_count,
    warning_stage_count,
    demand_stage_count,
    final_notice_count,
    legal_action_count
FROM bms.v_overdue_statistics;

-- 7. 연체 현황 상세 조회 테스트
SELECT '=== 연체 현황 상세 조회 테스트 ===' as test_section;
SELECT 
    o.overdue_id,
    bi.unit_id,
    u.unit_number,
    r.resident_name,
    o.overdue_status,
    o.overdue_stage,
    o.overdue_days,
    o.original_amount,
    o.late_fee_amount,
    o.total_overdue_amount,
    o.notification_count,
    o.warning_issued,
    o.legal_action_initiated,
    o.is_exempted,
    o.is_resolved
FROM bms.overdue_records o
JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
JOIN bms.units u ON bi.unit_id = u.unit_id
LEFT JOIN bms.residents r ON u.unit_id = r.unit_id AND r.is_primary = true AND r.is_active = true
ORDER BY o.overdue_days DESC, o.total_overdue_amount DESC;

-- 8. 알림 및 조치 이력 조회 테스트
SELECT '=== 알림 이력 조회 테스트 ===' as test_section;
SELECT 
    on.notification_type,
    on.notification_method,
    on.delivery_status,
    on.sent_at,
    on.is_read,
    on.notification_cost,
    u.unit_number,
    r.resident_name
FROM bms.overdue_notifications on
JOIN bms.overdue_records o ON on.overdue_id = o.overdue_id
JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
JOIN bms.units u ON bi.unit_id = u.unit_id
LEFT JOIN bms.residents r ON u.unit_id = r.unit_id AND r.is_primary = true AND r.is_active = true
ORDER BY on.sent_at DESC;

SELECT '=== 조치 이력 조회 테스트 ===' as test_section;
SELECT 
    oa.action_type,
    oa.action_status,
    oa.action_result,
    oa.executed_date,
    oa.result_amount,
    oa.recovery_amount,
    u.unit_number,
    r.resident_name
FROM bms.overdue_actions oa
JOIN bms.overdue_records o ON oa.overdue_id = o.overdue_id
JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
JOIN bms.units u ON bi.unit_id = u.unit_id
LEFT JOIN bms.residents r ON u.unit_id = r.unit_id AND r.is_primary = true AND r.is_active = true
ORDER BY oa.executed_date DESC NULLS LAST;

-- 테스트 완료 메시지
SELECT '연체 관리 시스템 테스트 데이터 생성 및 테스트가 완료되었습니다.' as message;