-- =====================================================
-- 계약 상태 관리 시스템 함수 생성 스크립트
-- Phase 3.3: 계약 상태 관리 함수
-- =====================================================

-- 1. 계약 상태 워크플로우 실행 함수
CREATE OR REPLACE FUNCTION bms.execute_status_workflow(
    p_contract_id UUID,
    p_new_status VARCHAR(20),
    p_change_reason VARCHAR(20),
    p_description TEXT DEFAULT NULL,
    p_changed_by UUID DEFAULT NULL,
    p_force_transition BOOLEAN DEFAULT false
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_workflow RECORD;
    v_history_id UUID;
    v_approval_required BOOLEAN := false;
    v_can_transition BOOLEAN := false;
BEGIN
    -- 계약 정보 조회
    SELECT * INTO v_contract
    FROM bms.lease_contracts
    WHERE contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 강제 전이가 아닌 경우 워크플로우 규칙 확인
    IF NOT p_force_transition THEN
        SELECT * INTO v_workflow
        FROM bms.contract_status_workflows
        WHERE company_id = v_contract.company_id
        AND (contract_type = v_contract.contract_type OR contract_type = 'ALL')
        AND from_status = v_contract.contract_status
        AND to_status = p_new_status
        AND is_active = true
        ORDER BY execution_order
        LIMIT 1;
        
        IF NOT FOUND THEN
            RAISE EXCEPTION '허용되지 않는 상태 전이입니다: % -> %', v_contract.contract_status, p_new_status;
        END IF;
        
        v_approval_required := v_workflow.approval_required;
        v_can_transition := true;
    ELSE
        v_can_transition := true;
    END IF;
    
    -- 상태 변경 이력 생성
    INSERT INTO bms.contract_status_history (
        contract_id,
        company_id,
        previous_status,
        new_status,
        change_reason,
        change_description,
        changed_by
    ) VALUES (
        p_contract_id,
        v_contract.company_id,
        v_contract.contract_status,
        p_new_status,
        p_change_reason,
        p_description,
        p_changed_by
    ) RETURNING history_id INTO v_history_id;
    
    -- 승인이 필요한 경우 승인 요청 생성
    IF v_approval_required THEN
        PERFORM bms.create_status_approval_request(
            v_history_id,
            v_workflow.approver_role,
            v_workflow.approval_level
        );
        
        -- 승인 대기 상태로 설정
        UPDATE bms.contract_status_history
        SET change_description = COALESCE(change_description, '') || ' (승인 대기중)'
        WHERE history_id = v_history_id;
        
    ELSE
        -- 승인이 필요하지 않은 경우 즉시 상태 변경
        PERFORM bms.apply_status_change(v_history_id);
    END IF;
    
    -- 자동화 규칙 실행
    PERFORM bms.execute_status_automation(p_contract_id, p_new_status, 'STATUS_CHANGED');
    
    RETURN v_can_transition;
END;
$$;

-- 2. 계약 상태 승인 요청 생성 함수
CREATE OR REPLACE FUNCTION bms.create_status_approval_request(
    p_history_id UUID,
    p_approver_role VARCHAR(20),
    p_approval_level INTEGER DEFAULT 1
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_approval_id UUID;
    v_company_id UUID;
    v_deadline TIMESTAMP WITH TIME ZONE;
BEGIN
    -- 회사 ID 조회
    SELECT csh.company_id INTO v_company_id
    FROM bms.contract_status_history csh
    WHERE csh.history_id = p_history_id;
    
    -- 승인 마감일 설정 (3일 후)
    v_deadline := NOW() + INTERVAL '3 days';
    
    -- 승인 요청 생성
    INSERT INTO bms.contract_status_approvals (
        history_id,
        company_id,
        approval_level,
        approver_role,
        approval_deadline
    ) VALUES (
        p_history_id,
        v_company_id,
        p_approval_level,
        p_approver_role,
        v_deadline
    ) RETURNING approval_id INTO v_approval_id;
    
    -- 승인 요청 알림 발송
    PERFORM bms.send_status_notification(
        p_history_id,
        v_approval_id,
        'APPROVAL_REQUEST',
        'URGENT',
        p_approver_role
    );
    
    RETURN v_approval_id;
END;
$$;

-- 3. 계약 상태 승인 처리 함수
CREATE OR REPLACE FUNCTION bms.process_status_approval(
    p_approval_id UUID,
    p_approver_id UUID,
    p_decision VARCHAR(20),
    p_comments TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_approval RECORD;
    v_history_id UUID;
    v_approved BOOLEAN := false;
BEGIN
    -- 승인 정보 조회
    SELECT * INTO v_approval
    FROM bms.contract_status_approvals
    WHERE approval_id = p_approval_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '승인 요청을 찾을 수 없습니다: %', p_approval_id;
    END IF;
    
    -- 이미 처리된 승인인지 확인
    IF v_approval.approval_status != 'PENDING' THEN
        RAISE EXCEPTION '이미 처리된 승인 요청입니다: %', v_approval.approval_status;
    END IF;
    
    v_history_id := v_approval.history_id;
    
    -- 승인 결과 업데이트
    UPDATE bms.contract_status_approvals
    SET approval_status = CASE 
            WHEN p_decision = 'APPROVE' THEN 'APPROVED'
            WHEN p_decision = 'REJECT' THEN 'REJECTED'
            ELSE 'PENDING'
        END,
        approver_id = p_approver_id,
        approved_at = NOW(),
        approval_decision = p_decision,
        approval_comments = p_comments,
        updated_at = NOW()
    WHERE approval_id = p_approval_id;
    
    -- 승인된 경우 상태 변경 적용
    IF p_decision = 'APPROVE' THEN
        PERFORM bms.apply_status_change(v_history_id);
        v_approved := true;
        
        -- 승인 완료 알림 발송
        PERFORM bms.send_status_notification(
            v_history_id,
            p_approval_id,
            'APPROVAL_RESULT',
            'IMPORTANT',
            'SYSTEM'
        );
    ELSIF p_decision = 'REJECT' THEN
        -- 거부 알림 발송
        PERFORM bms.send_status_notification(
            v_history_id,
            p_approval_id,
            'APPROVAL_RESULT',
            'IMPORTANT',
            'SYSTEM'
        );
    END IF;
    
    RETURN v_approved;
END;
$$;

-- 4. 계약 상태 변경 적용 함수
CREATE OR REPLACE FUNCTION bms.apply_status_change(
    p_history_id UUID
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_history RECORD;
BEGIN
    -- 상태 변경 이력 조회
    SELECT * INTO v_history
    FROM bms.contract_status_history
    WHERE history_id = p_history_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '상태 변경 이력을 찾을 수 없습니다: %', p_history_id;
    END IF;
    
    -- 계약 상태 업데이트
    UPDATE bms.lease_contracts
    SET contract_status = v_history.new_status,
        updated_at = NOW()
    WHERE contract_id = v_history.contract_id;
    
    -- 상태 변경 이력에 승인 정보 업데이트
    UPDATE bms.contract_status_history
    SET approved_by = COALESCE(
            (SELECT approver_id FROM bms.contract_status_approvals 
             WHERE history_id = p_history_id AND approval_status = 'APPROVED' 
             ORDER BY approved_at DESC LIMIT 1),
            v_history.changed_by
        ),
        approval_date = COALESCE(
            (SELECT approved_at FROM bms.contract_status_approvals 
             WHERE history_id = p_history_id AND approval_status = 'APPROVED' 
             ORDER BY approved_at DESC LIMIT 1),
            NOW()
        )
    WHERE history_id = p_history_id;
    
    -- 상태 변경 알림 발송
    PERFORM bms.send_status_notification(
        p_history_id,
        NULL,
        'STATUS_CHANGE',
        'NORMAL',
        'PARTY'
    );
    
    RETURN true;
END;
$$;

-- 5. 계약 상태 자동화 실행 함수
CREATE OR REPLACE FUNCTION bms.execute_status_automation(
    p_contract_id UUID,
    p_current_status VARCHAR(20),
    p_trigger_event VARCHAR(20)
) RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE
    v_contract RECORD;
    v_automation RECORD;
    v_executed_count INTEGER := 0;
    v_condition_met BOOLEAN;
BEGIN
    -- 계약 정보 조회
    SELECT * INTO v_contract
    FROM bms.lease_contracts
    WHERE contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- 해당 트리거 이벤트에 대한 자동화 규칙 조회
    FOR v_automation IN
        SELECT * FROM bms.contract_status_automation
        WHERE company_id = v_contract.company_id
        AND trigger_event = p_trigger_event
        AND (target_contract_type IS NULL OR target_contract_type = v_contract.contract_type)
        AND (target_status IS NULL OR target_status = p_current_status)
        AND is_active = true
        AND (max_execution_count IS NULL OR execution_count < max_execution_count)
        ORDER BY created_at
    LOOP
        -- 조건 확인 (간단한 예시)
        v_condition_met := true;
        
        -- 조건이 충족된 경우 액션 실행
        IF v_condition_met THEN
            CASE v_automation.action_type
                WHEN 'CHANGE_STATUS' THEN
                    -- 상태 변경
                    IF v_automation.new_status IS NOT NULL THEN
                        PERFORM bms.execute_status_workflow(
                            p_contract_id,
                            v_automation.new_status,
                            'SYSTEM_UPDATE',
                            '자동화 규칙에 의한 상태 변경: ' || v_automation.rule_name,
                            NULL,
                            true
                        );
                    END IF;
                    
                WHEN 'SEND_NOTIFICATION' THEN
                    -- 알림 발송
                    PERFORM bms.send_status_notification(
                        NULL,
                        NULL,
                        'SYSTEM_ALERT',
                        'NORMAL',
                        'SYSTEM'
                    );
                    
                -- 다른 액션 유형들은 필요에 따라 구현
            END CASE;
            
            -- 실행 횟수 업데이트
            UPDATE bms.contract_status_automation
            SET execution_count = execution_count + 1,
                last_executed_at = NOW()
            WHERE automation_id = v_automation.automation_id;
            
            v_executed_count := v_executed_count + 1;
        END IF;
    END LOOP;
    
    RETURN v_executed_count;
END;
$$;

-- 6. 계약 상태 알림 발송 함수
CREATE OR REPLACE FUNCTION bms.send_status_notification(
    p_history_id UUID,
    p_approval_id UUID,
    p_notification_type VARCHAR(20),
    p_category VARCHAR(20),
    p_recipient_type VARCHAR(20)
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_notification_id UUID;
    v_company_id UUID;
    v_title VARCHAR(200);
    v_content TEXT;
    v_contract RECORD;
    v_history RECORD;
BEGIN
    -- 기본 정보 조회
    IF p_history_id IS NOT NULL THEN
        SELECT csh.*, lc.contract_number, u.unit_number
        INTO v_history
        FROM bms.contract_status_history csh
        JOIN bms.lease_contracts lc ON csh.contract_id = lc.contract_id
        JOIN bms.units u ON lc.unit_id = u.unit_id
        WHERE csh.history_id = p_history_id;
        
        v_company_id := v_history.company_id;
    END IF;
    
    -- 알림 제목 및 내용 생성
    CASE p_notification_type
        WHEN 'STATUS_CHANGE' THEN
            v_title := format('[계약상태변경] %s호 계약 상태가 변경되었습니다', v_history.unit_number);
            v_content := format(
                E'계약번호: %s\n' ||
                E'세대: %s호\n' ||
                E'이전 상태: %s\n' ||
                E'새로운 상태: %s\n' ||
                E'변경 사유: %s\n' ||
                E'변경 일시: %s',
                v_history.contract_number,
                v_history.unit_number,
                v_history.previous_status,
                v_history.new_status,
                v_history.change_reason,
                v_history.status_change_date
            );
            
        WHEN 'APPROVAL_REQUEST' THEN
            v_title := format('[승인요청] %s호 계약 상태 변경 승인이 필요합니다', v_history.unit_number);
            v_content := format(
                E'계약번호: %s\n' ||
                E'세대: %s호\n' ||
                E'요청 상태 변경: %s → %s\n' ||
                E'변경 사유: %s\n' ||
                E'승인 마감일: 3일 이내',
                v_history.contract_number,
                v_history.unit_number,
                v_history.previous_status,
                v_history.new_status,
                v_history.change_reason
            );
            
        WHEN 'APPROVAL_RESULT' THEN
            v_title := format('[승인결과] %s호 계약 상태 변경 승인이 처리되었습니다', v_history.unit_number);
            v_content := format(
                E'계약번호: %s\n' ||
                E'세대: %s호\n' ||
                E'승인 결과: 처리 완료\n' ||
                E'처리 일시: %s',
                v_history.contract_number,
                v_history.unit_number,
                NOW()
            );
            
        ELSE
            v_title := '계약 관련 알림';
            v_content := '계약 상태와 관련된 알림입니다.';
    END CASE;
    
    -- 알림 생성
    INSERT INTO bms.contract_status_notifications (
        history_id,
        approval_id,
        company_id,
        notification_type,
        notification_category,
        recipient_type,
        notification_title,
        notification_content,
        delivery_method,
        scheduled_at
    ) VALUES (
        p_history_id,
        p_approval_id,
        v_company_id,
        p_notification_type,
        p_category,
        p_recipient_type,
        v_title,
        v_content,
        'EMAIL',
        NOW()
    ) RETURNING notification_id INTO v_notification_id;
    
    RETURN v_notification_id;
END;
$$;

-- 7. 계약 상태 대시보드 뷰
CREATE OR REPLACE VIEW bms.v_contract_status_dashboard AS
SELECT 
    lc.contract_id,
    lc.company_id,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- 현재 상태 정보
    lc.contract_status,
    CASE lc.contract_status
        WHEN 'DRAFT' THEN '초안'
        WHEN 'PENDING' THEN '검토중'
        WHEN 'APPROVED' THEN '승인됨'
        WHEN 'ACTIVE' THEN '활성'
        WHEN 'EXPIRED' THEN '만료'
        WHEN 'TERMINATED' THEN '해지'
        WHEN 'CANCELLED' THEN '취소'
        WHEN 'RENEWED' THEN '갱신'
        ELSE lc.contract_status
    END as status_display,
    
    -- 최근 상태 변경 정보
    latest_history.previous_status,
    latest_history.status_change_date as last_status_change,
    latest_history.change_reason as last_change_reason,
    latest_history.changed_by as last_changed_by,
    
    -- 대기중인 승인 정보
    pending_approval.approval_id,
    pending_approval.approver_role,
    pending_approval.approval_deadline,
    pending_approval.requested_at as approval_requested_at,
    
    -- 계약 기본 정보
    lc.contract_start_date,
    lc.contract_end_date,
    lc.monthly_rent,
    lc.deposit_amount,
    
    -- 임차인 정보
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone,
    
    -- 우선순위 계산
    CASE 
        WHEN pending_approval.approval_deadline <= NOW() + INTERVAL '1 day' THEN 100
        WHEN pending_approval.approval_deadline <= NOW() + INTERVAL '3 days' THEN 90
        WHEN lc.contract_status = 'PENDING' THEN 80
        WHEN lc.contract_end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 70
        ELSE 50
    END as priority_score,
    
    -- 상태 표시 색상
    CASE lc.contract_status
        WHEN 'DRAFT' THEN 'gray'
        WHEN 'PENDING' THEN 'yellow'
        WHEN 'APPROVED' THEN 'blue'
        WHEN 'ACTIVE' THEN 'green'
        WHEN 'EXPIRED' THEN 'orange'
        WHEN 'TERMINATED' THEN 'red'
        WHEN 'CANCELLED' THEN 'red'
        WHEN 'RENEWED' THEN 'purple'
        ELSE 'gray'
    END as status_color
    
FROM bms.lease_contracts lc
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN LATERAL (
    SELECT * FROM bms.contract_status_history 
    WHERE contract_id = lc.contract_id 
    ORDER BY status_change_date DESC 
    LIMIT 1
) latest_history ON true
LEFT JOIN LATERAL (
    SELECT csa.* FROM bms.contract_status_approvals csa
    JOIN bms.contract_status_history csh ON csa.history_id = csh.history_id
    WHERE csh.contract_id = lc.contract_id 
    AND csa.approval_status = 'PENDING'
    ORDER BY csa.requested_at DESC 
    LIMIT 1
) pending_approval ON true
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true;

-- 8. 코멘트 추가
COMMENT ON TABLE bms.contract_status_workflows IS '계약 상태 워크플로우 정의 테이블 - 상태 전이 규칙과 승인 프로세스를 정의';
COMMENT ON TABLE bms.contract_status_approvals IS '계약 상태 승인 테이블 - 상태 변경에 대한 승인 요청과 처리 결과를 관리';
COMMENT ON TABLE bms.contract_status_automation IS '계약 상태 자동화 규칙 테이블 - 상태 변경에 따른 자동화 액션을 정의';
COMMENT ON TABLE bms.contract_status_notifications IS '계약 상태 알림 이력 테이블 - 상태 변경 관련 알림 발송 내역을 기록';

COMMENT ON FUNCTION bms.execute_status_workflow(UUID, VARCHAR, VARCHAR, TEXT, UUID, BOOLEAN) IS '계약 상태 워크플로우 실행 함수 - 워크플로우 규칙에 따라 상태 변경을 처리';
COMMENT ON FUNCTION bms.create_status_approval_request(UUID, VARCHAR, INTEGER) IS '계약 상태 승인 요청 생성 함수 - 상태 변경에 대한 승인 요청을 생성';
COMMENT ON FUNCTION bms.process_status_approval(UUID, UUID, VARCHAR, TEXT) IS '계약 상태 승인 처리 함수 - 승인 요청에 대한 결정을 처리';
COMMENT ON FUNCTION bms.apply_status_change(UUID) IS '계약 상태 변경 적용 함수 - 승인된 상태 변경을 실제로 적용';
COMMENT ON FUNCTION bms.execute_status_automation(UUID, VARCHAR, VARCHAR) IS '계약 상태 자동화 실행 함수 - 트리거 이벤트에 따른 자동화 규칙을 실행';
COMMENT ON FUNCTION bms.send_status_notification(UUID, UUID, VARCHAR, VARCHAR, VARCHAR) IS '계약 상태 알림 발송 함수 - 상태 변경 관련 알림을 발송';

COMMENT ON VIEW bms.v_contract_status_dashboard IS '계약 상태 대시보드 뷰 - 계약 상태 현황과 대기중인 승인 요청을 종합 조회';

-- 스크립트 완료 메시지
SELECT '계약 상태 관리 시스템 함수 생성이 완료되었습니다.' as message;