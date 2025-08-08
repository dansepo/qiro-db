-- =====================================================
-- 정산 및 환불 관리 시스템 함수 및 뷰 생성 스크립트
-- Phase 5.3: 정산 및 환불 관리 시스템 함수 및 뷰
-- =====================================================

-- 1. 정산 금액 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_settlement_amount(
    p_unit_id UUID,
    p_period_start DATE,
    p_period_end DATE
) RETURNS TABLE (
    total_charged DECIMAL(15,2),
    total_paid DECIMAL(15,2),
    settlement_amount DECIMAL(15,2),
    settlement_type VARCHAR(20),
    calculation_details JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_total_charged DECIMAL(15,2) := 0;
    v_total_paid DECIMAL(15,2) := 0;
    v_settlement_amount DECIMAL(15,2) := 0;
    v_settlement_type VARCHAR(20);
    v_details JSONB := '{}';
    v_issuance_record RECORD;
    v_payment_record RECORD;
BEGIN
    -- 해당 기간의 청구 금액 합계 계산
    SELECT COALESCE(SUM(bi.final_amount), 0)
    INTO v_total_charged
    FROM bms.bill_issuances bi
    WHERE bi.unit_id = p_unit_id
    AND bi.bill_period BETWEEN p_period_start AND p_period_end
    AND bi.issuance_status IN ('GENERATED', 'APPROVED', 'DELIVERED');
    
    -- 해당 기간의 납부 금액 합계 계산
    SELECT COALESCE(SUM(pt.paid_amount), 0)
    INTO v_total_paid
    FROM bms.payment_transactions pt
    JOIN bms.bill_issuances bi ON pt.issuance_id = bi.issuance_id
    WHERE bi.unit_id = p_unit_id
    AND bi.bill_period BETWEEN p_period_start AND p_period_end
    AND pt.payment_status = 'COMPLETED';
    
    -- 정산 금액 계산 (양수: 환불, 음수: 추가 징수)
    v_settlement_amount := v_total_paid - v_total_charged;
    
    -- 정산 유형 결정
    IF v_settlement_amount > 0 THEN
        v_settlement_type := 'REFUND';
    ELSIF v_settlement_amount < 0 THEN
        v_settlement_type := 'ADDITIONAL_CHARGE';
    ELSE
        v_settlement_type := 'BALANCED';
    END IF;
    
    -- 계산 상세 정보 생성
    v_details := jsonb_build_object(
        'period_start', p_period_start,
        'period_end', p_period_end,
        'total_charged', v_total_charged,
        'total_paid', v_total_paid,
        'settlement_amount', v_settlement_amount,
        'settlement_type', v_settlement_type,
        'calculation_date', CURRENT_DATE
    );
    
    RETURN QUERY SELECT v_total_charged, v_total_paid, v_settlement_amount, v_settlement_type, v_details;
END;
$$;

-- 2. 정산 요청 생성 함수
CREATE OR REPLACE FUNCTION bms.create_settlement_request(
    p_company_id UUID,
    p_unit_id UUID,
    p_policy_id UUID,
    p_request_type VARCHAR(20),
    p_period_start DATE,
    p_period_end DATE,
    p_settlement_reason VARCHAR(20),
    p_description TEXT DEFAULT NULL,
    p_requested_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_request_id UUID;
    v_request_number VARCHAR(50);
    v_settlement_calc RECORD;
    v_policy RECORD;
    v_refund_fee DECIMAL(10,2) := 0;
    v_final_amount DECIMAL(15,2);
BEGIN
    -- 정산 정책 조회
    SELECT * INTO v_policy
    FROM bms.settlement_policies
    WHERE policy_id = p_policy_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '정산 정책을 찾을 수 없습니다: %', p_policy_id;
    END IF;
    
    -- 정산 금액 계산
    SELECT * INTO v_settlement_calc
    FROM bms.calculate_settlement_amount(p_unit_id, p_period_start, p_period_end);
    
    -- 요청 번호 생성
    v_request_number := 'SR' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                       LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 10, '0');
    
    -- 환불 수수료 계산 (환불인 경우만)
    IF v_settlement_calc.settlement_amount > 0 THEN
        v_refund_fee := v_policy.refund_fee;
    END IF;
    
    -- 최종 정산 금액 계산
    v_final_amount := v_settlement_calc.settlement_amount - v_refund_fee;
    
    -- 정산 요청 생성
    INSERT INTO bms.settlement_requests (
        company_id,
        unit_id,
        policy_id,
        request_number,
        request_type,
        target_period_start,
        target_period_end,
        total_charged_amount,
        total_paid_amount,
        settlement_amount,
        refund_fee_amount,
        final_settlement_amount,
        settlement_reason,
        settlement_description,
        requested_by,
        approval_required
    ) VALUES (
        p_company_id,
        p_unit_id,
        p_policy_id,
        v_request_number,
        p_request_type,
        p_period_start,
        p_period_end,
        v_settlement_calc.total_charged,
        v_settlement_calc.total_paid,
        v_settlement_calc.settlement_amount,
        v_refund_fee,
        v_final_amount,
        p_settlement_reason,
        p_description,
        p_requested_by,
        CASE 
            WHEN ABS(v_final_amount) >= v_policy.approval_threshold_amount THEN true
            ELSE v_policy.approval_required
        END
    ) RETURNING request_id INTO v_request_id;
    
    RETURN v_request_id;
END;
$$;

-- 3. 환불 거래 생성 함수
CREATE OR REPLACE FUNCTION bms.create_refund_transaction(
    p_request_id UUID,
    p_refund_method VARCHAR(20),
    p_recipient_name VARCHAR(100),
    p_recipient_account_info JSONB DEFAULT NULL,
    p_scheduled_date DATE DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_transaction_id UUID;
    v_transaction_number VARCHAR(50);
    v_request RECORD;
    v_policy RECORD;
    v_net_amount DECIMAL(15,2);
BEGIN
    -- 정산 요청 정보 조회
    SELECT sr.*, sp.refund_processing_days, sp.refund_fee
    INTO v_request
    FROM bms.settlement_requests sr
    JOIN bms.settlement_policies sp ON sr.policy_id = sp.policy_id
    WHERE sr.request_id = p_request_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '정산 요청을 찾을 수 없습니다: %', p_request_id;
    END IF;
    
    -- 환불 가능 여부 확인
    IF v_request.final_settlement_amount <= 0 THEN
        RAISE EXCEPTION '환불 대상이 아닙니다. 정산 금액: %', v_request.final_settlement_amount;
    END IF;
    
    IF v_request.request_status NOT IN ('APPROVED', 'PROCESSING') THEN
        RAISE EXCEPTION '승인되지 않은 요청입니다. 상태: %', v_request.request_status;
    END IF;
    
    -- 거래 번호 생성
    v_transaction_number := 'RT' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                           LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 10, '0');
    
    -- 실 환불 금액 계산
    v_net_amount := v_request.final_settlement_amount;
    
    -- 예정일 설정 (지정되지 않은 경우 정책의 처리 기간 적용)
    IF p_scheduled_date IS NULL THEN
        p_scheduled_date := CURRENT_DATE + (v_request.refund_processing_days || ' days')::INTERVAL;
    END IF;
    
    -- 환불 거래 생성
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
        scheduled_date,
        transaction_status
    ) VALUES (
        v_request.company_id,
        p_request_id,
        v_transaction_number,
        p_refund_method,
        v_request.settlement_amount,
        v_request.refund_fee_amount,
        v_net_amount,
        p_recipient_name,
        p_recipient_account_info,
        p_scheduled_date,
        'PENDING'
    ) RETURNING transaction_id INTO v_transaction_id;
    
    -- 정산 요청 상태 업데이트
    UPDATE bms.settlement_requests
    SET request_status = 'PROCESSING',
        updated_at = NOW()
    WHERE request_id = p_request_id;
    
    RETURN v_transaction_id;
END;
$$;

-- 4. 차액 조정 생성 함수
CREATE OR REPLACE FUNCTION bms.create_balance_adjustment(
    p_company_id UUID,
    p_unit_id UUID,
    p_adjustment_type VARCHAR(20),
    p_adjustment_reason VARCHAR(20),
    p_original_amount DECIMAL(15,2),
    p_adjusted_amount DECIMAL(15,2),
    p_period_start DATE,
    p_period_end DATE,
    p_description TEXT DEFAULT NULL,
    p_request_id UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_adjustment_id UUID;
    v_adjustment_number VARCHAR(50);
    v_difference DECIMAL(15,2);
BEGIN
    -- 조정 번호 생성
    v_adjustment_number := 'BA' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                          LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 10, '0');
    
    -- 조정 차액 계산
    v_difference := p_adjusted_amount - p_original_amount;
    
    -- 차액 조정 생성
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
        calculation_details
    ) VALUES (
        p_company_id,
        p_unit_id,
        p_request_id,
        v_adjustment_number,
        p_adjustment_type,
        p_adjustment_reason,
        p_period_start,
        p_period_end,
        p_original_amount,
        p_adjusted_amount,
        v_difference,
        p_description,
        jsonb_build_object(
            'original_amount', p_original_amount,
            'adjusted_amount', p_adjusted_amount,
            'difference', v_difference,
            'adjustment_type', p_adjustment_type,
            'adjustment_reason', p_adjustment_reason,
            'created_date', CURRENT_DATE
        )
    ) RETURNING adjustment_id INTO v_adjustment_id;
    
    RETURN v_adjustment_id;
END;
$$;

-- 5. 정산 알림 생성 함수
CREATE OR REPLACE FUNCTION bms.create_settlement_notification(
    p_company_id UUID,
    p_request_id UUID,
    p_transaction_id UUID,
    p_notification_type VARCHAR(20),
    p_notification_method VARCHAR(20),
    p_recipient_name VARCHAR(100),
    p_recipient_contact VARCHAR(255)
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_notification_id UUID;
    v_title VARCHAR(200);
    v_content TEXT;
    v_request RECORD;
    v_transaction RECORD;
BEGIN
    -- 정산 요청 정보 조회
    IF p_request_id IS NOT NULL THEN
        SELECT sr.*, u.unit_number
        INTO v_request
        FROM bms.settlement_requests sr
        JOIN bms.units u ON sr.unit_id = u.unit_id
        WHERE sr.request_id = p_request_id;
    END IF;
    
    -- 환불 거래 정보 조회
    IF p_transaction_id IS NOT NULL THEN
        SELECT * INTO v_transaction
        FROM bms.refund_transactions
        WHERE transaction_id = p_transaction_id;
    END IF;
    
    -- 알림 제목 및 내용 생성
    CASE p_notification_type
        WHEN 'REQUEST_SUBMITTED' THEN
            v_title := '[정산요청] 정산 요청이 접수되었습니다';
            v_content := format(
                E'정산 요청이 접수되었습니다.\n\n' ||
                E'요청번호: %s\n' ||
                E'세대: %s호\n' ||
                E'정산금액: %s원\n' ||
                E'요청일시: %s',
                v_request.request_number,
                v_request.unit_number,
                v_request.final_settlement_amount,
                v_request.requested_at
            );
            
        WHEN 'REQUEST_APPROVED' THEN
            v_title := '[정산승인] 정산 요청이 승인되었습니다';
            v_content := format(
                E'정산 요청이 승인되었습니다.\n\n' ||
                E'요청번호: %s\n' ||
                E'세대: %s호\n' ||
                E'승인금액: %s원\n' ||
                E'승인일시: %s',
                v_request.request_number,
                v_request.unit_number,
                v_request.final_settlement_amount,
                v_request.approved_at
            );
            
        WHEN 'REFUND_COMPLETED' THEN
            v_title := '[환불완료] 환불이 완료되었습니다';
            v_content := format(
                E'환불이 완료되었습니다.\n\n' ||
                E'거래번호: %s\n' ||
                E'환불금액: %s원\n' ||
                E'환불방법: %s\n' ||
                E'완료일시: %s',
                v_transaction.transaction_number,
                v_transaction.net_refund_amount,
                v_transaction.refund_method,
                v_transaction.completed_date
            );
            
        ELSE
            v_title := '[정산알림] 정산 관련 알림';
            v_content := '정산 관련 알림입니다.';
    END CASE;
    
    -- 알림 생성
    INSERT INTO bms.settlement_notifications (
        company_id,
        request_id,
        transaction_id,
        notification_type,
        notification_method,
        notification_title,
        notification_content,
        recipient_name,
        recipient_contact,
        scheduled_at
    ) VALUES (
        p_company_id,
        p_request_id,
        p_transaction_id,
        p_notification_type,
        p_notification_method,
        v_title,
        v_content,
        p_recipient_name,
        p_recipient_contact,
        NOW()
    ) RETURNING notification_id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$;

-- 6. 정산 대시보드 뷰
CREATE OR REPLACE VIEW bms.v_settlement_dashboard AS
SELECT 
    sr.request_id,
    sr.company_id,
    sr.unit_id,
    u.unit_number,
    u.building_id,
    
    -- 요청 정보
    sr.request_number,
    sr.request_type,
    sr.request_status,
    sr.settlement_reason,
    
    -- 금액 정보
    sr.total_charged_amount,
    sr.total_paid_amount,
    sr.settlement_amount,
    sr.final_settlement_amount,
    
    -- 기간 정보
    sr.target_period_start,
    sr.target_period_end,
    
    -- 처리 정보
    sr.requested_at,
    sr.approved_at,
    sr.processed_at,
    sr.approval_required,
    
    -- 정책 정보
    sp.policy_name,
    sp.refund_method as default_refund_method,
    sp.refund_processing_days,
    
    -- 환불 거래 정보
    rt.transaction_id,
    rt.transaction_status,
    rt.refund_method,
    rt.scheduled_date as refund_scheduled_date,
    rt.completed_date as refund_completed_date,
    
    -- 계산된 필드
    CASE 
        WHEN sr.settlement_amount > 0 THEN '환불'
        WHEN sr.settlement_amount < 0 THEN '추가징수'
        ELSE '정산완료'
    END as settlement_type_display,
    
    CASE 
        WHEN sr.request_status = 'PENDING' THEN '대기중'
        WHEN sr.request_status = 'UNDER_REVIEW' THEN '검토중'
        WHEN sr.request_status = 'APPROVED' THEN '승인됨'
        WHEN sr.request_status = 'REJECTED' THEN '거부됨'
        WHEN sr.request_status = 'PROCESSING' THEN '처리중'
        WHEN sr.request_status = 'COMPLETED' THEN '완료됨'
        ELSE sr.request_status
    END as status_display,
    
    -- 우선순위 계산
    CASE 
        WHEN sr.request_status = 'PENDING' AND sr.approval_required THEN 100
        WHEN sr.request_status = 'APPROVED' THEN 90
        WHEN sr.request_status = 'PROCESSING' THEN 80
        ELSE 50
    END as priority_score
    
FROM bms.settlement_requests sr
JOIN bms.units u ON sr.unit_id = u.unit_id
JOIN bms.settlement_policies sp ON sr.policy_id = sp.policy_id
LEFT JOIN bms.refund_transactions rt ON sr.request_id = rt.request_id
WHERE sr.request_status != 'CANCELLED';

-- 7. 정산 통계 뷰
CREATE OR REPLACE VIEW bms.v_settlement_statistics AS
SELECT 
    company_id,
    
    -- 전체 통계
    COUNT(*) as total_requests,
    SUM(ABS(final_settlement_amount)) as total_settlement_amount,
    AVG(ABS(final_settlement_amount)) as avg_settlement_amount,
    
    -- 상태별 통계
    COUNT(*) FILTER (WHERE request_status = 'PENDING') as pending_count,
    COUNT(*) FILTER (WHERE request_status = 'APPROVED') as approved_count,
    COUNT(*) FILTER (WHERE request_status = 'COMPLETED') as completed_count,
    COUNT(*) FILTER (WHERE request_status = 'REJECTED') as rejected_count,
    
    -- 유형별 통계
    COUNT(*) FILTER (WHERE request_type = 'OVERPAYMENT_REFUND') as overpayment_refund_count,
    COUNT(*) FILTER (WHERE request_type = 'UNDERPAYMENT_CHARGE') as underpayment_charge_count,
    COUNT(*) FILTER (WHERE request_type = 'BILLING_ERROR') as billing_error_count,
    
    -- 금액별 통계
    SUM(final_settlement_amount) FILTER (WHERE final_settlement_amount > 0) as total_refund_amount,
    SUM(ABS(final_settlement_amount)) FILTER (WHERE final_settlement_amount < 0) as total_charge_amount,
    
    -- 환불 통계
    COUNT(*) FILTER (WHERE final_settlement_amount > 0) as refund_request_count,
    COUNT(*) FILTER (WHERE final_settlement_amount < 0) as charge_request_count,
    
    -- 처리 시간 통계
    AVG(EXTRACT(EPOCH FROM (approved_at - requested_at))/3600) FILTER (WHERE approved_at IS NOT NULL) as avg_approval_hours,
    AVG(EXTRACT(EPOCH FROM (processed_at - approved_at))/3600) FILTER (WHERE processed_at IS NOT NULL AND approved_at IS NOT NULL) as avg_processing_hours,
    
    -- 최신 업데이트 시간
    MAX(updated_at) as last_updated_at
    
FROM bms.settlement_requests
WHERE request_status != 'CANCELLED'
GROUP BY company_id;

-- 8. 환불 거래 현황 뷰
CREATE OR REPLACE VIEW bms.v_refund_status AS
SELECT 
    rt.transaction_id,
    rt.company_id,
    rt.transaction_number,
    rt.refund_method,
    rt.transaction_status,
    rt.refund_amount,
    rt.net_refund_amount,
    rt.recipient_name,
    rt.scheduled_date,
    rt.processed_date,
    rt.completed_date,
    
    -- 요청 정보
    sr.request_number,
    sr.request_type,
    u.unit_number,
    
    -- 처리 상태 표시
    CASE 
        WHEN rt.transaction_status = 'PENDING' THEN '대기중'
        WHEN rt.transaction_status = 'SCHEDULED' THEN '예약됨'
        WHEN rt.transaction_status = 'PROCESSING' THEN '처리중'
        WHEN rt.transaction_status = 'COMPLETED' THEN '완료됨'
        WHEN rt.transaction_status = 'FAILED' THEN '실패'
        ELSE rt.transaction_status
    END as status_display,
    
    -- 지연 여부
    CASE 
        WHEN rt.scheduled_date < CURRENT_DATE AND rt.transaction_status IN ('PENDING', 'SCHEDULED') THEN true
        ELSE false
    END as is_overdue,
    
    -- 처리 예정일까지 남은 일수
    CASE 
        WHEN rt.scheduled_date >= CURRENT_DATE THEN rt.scheduled_date - CURRENT_DATE
        ELSE 0
    END as days_until_scheduled
    
FROM bms.refund_transactions rt
JOIN bms.settlement_requests sr ON rt.request_id = sr.request_id
JOIN bms.units u ON sr.unit_id = u.unit_id
WHERE rt.transaction_status != 'CANCELLED';

-- 9. 코멘트 추가
COMMENT ON TABLE bms.settlement_policies IS '정산 정책 설정 테이블 - 회사별/건물별 정산 및 환불 정책을 정의';
COMMENT ON TABLE bms.settlement_requests IS '정산 요청 테이블 - 과납금 환불, 미납금 추가 징수 등의 정산 요청을 관리';
COMMENT ON TABLE bms.refund_transactions IS '환불 거래 테이블 - 환불 처리 과정과 결과를 관리';
COMMENT ON TABLE bms.balance_adjustments IS '차액 조정 이력 테이블 - 청구 금액 조정 내역을 관리';
COMMENT ON TABLE bms.settlement_notifications IS '정산 알림 이력 테이블 - 정산 관련 알림 발송 내역을 기록';

COMMENT ON COLUMN bms.settlement_policies.auto_settlement_enabled IS '자동 정산 활성화 - 기준 금액 이하 자동 처리 여부';
COMMENT ON COLUMN bms.settlement_requests.settlement_amount IS '정산 금액 - 양수는 환불, 음수는 추가 징수';
COMMENT ON COLUMN bms.refund_transactions.net_refund_amount IS '실 환불 금액 - 환불 수수료를 제외한 실제 지급 금액';
COMMENT ON COLUMN bms.balance_adjustments.adjustment_difference IS '조정 차액 - 조정 후 금액에서 원래 금액을 뺀 값';

COMMENT ON FUNCTION bms.calculate_settlement_amount(UUID, DATE, DATE) IS '정산 금액 계산 함수 - 특정 기간의 청구/납부 금액을 비교하여 정산 금액 계산';
COMMENT ON FUNCTION bms.create_settlement_request(UUID, UUID, UUID, VARCHAR, DATE, DATE, VARCHAR, TEXT, UUID) IS '정산 요청 생성 함수 - 정산 요청을 생성하고 승인 필요 여부 결정';
COMMENT ON FUNCTION bms.create_refund_transaction(UUID, VARCHAR, VARCHAR, JSONB, DATE) IS '환불 거래 생성 함수 - 승인된 정산 요청에 대한 환불 거래 생성';
COMMENT ON FUNCTION bms.create_balance_adjustment(UUID, UUID, VARCHAR, VARCHAR, DECIMAL, DECIMAL, DATE, DATE, TEXT, UUID) IS '차액 조정 생성 함수 - 청구 금액 조정 내역 생성';

COMMENT ON VIEW bms.v_settlement_dashboard IS '정산 대시보드 뷰 - 정산 요청 현황을 종합적으로 조회';
COMMENT ON VIEW bms.v_settlement_statistics IS '정산 통계 뷰 - 회사별 정산 현황 통계 정보';
COMMENT ON VIEW bms.v_refund_status IS '환불 거래 현황 뷰 - 환불 처리 상태와 일정 관리';

-- 스크립트 완료 메시지
SELECT '정산 및 환불 관리 시스템 함수 및 뷰 생성이 완료되었습니다.' as message;