-- =====================================================
-- 계약 상태 관리 시스템 테이블 생성 스크립트
-- Phase 3.3: 계약 상태 관리
-- =====================================================

-- 1. 계약 상태 워크플로우 정의 테이블
CREATE TABLE IF NOT EXISTS bms.contract_status_workflows (
    workflow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 워크플로우 기본 정보
    workflow_name VARCHAR(100) NOT NULL,                   -- 워크플로우명
    workflow_description TEXT,                             -- 워크플로우 설명
    contract_type VARCHAR(20) NOT NULL,                    -- 적용 계약 유형
    
    -- 상태 전이 규칙
    from_status VARCHAR(20) NOT NULL,                      -- 시작 상태
    to_status VARCHAR(20) NOT NULL,                        -- 종료 상태
    transition_condition TEXT,                             -- 전이 조건
    
    -- 승인 요구사항
    approval_required BOOLEAN DEFAULT false,               -- 승인 필요 여부
    approver_role VARCHAR(20),                             -- 승인자 역할
    approval_level INTEGER DEFAULT 1,                      -- 승인 단계
    
    -- 자동화 설정
    auto_transition BOOLEAN DEFAULT false,                 -- 자동 전이 여부
    auto_condition JSONB,                                  -- 자동 전이 조건
    trigger_event VARCHAR(20),                             -- 트리거 이벤트
    
    -- 알림 설정
    notification_enabled BOOLEAN DEFAULT true,             -- 알림 활성화
    notification_recipients TEXT[],                        -- 알림 수신자
    notification_template VARCHAR(100),                    -- 알림 템플릿
    
    -- 상태 정보
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    execution_order INTEGER DEFAULT 1,                     -- 실행 순서
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_status_workflows_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_status_workflows_transition UNIQUE (company_id, contract_type, from_status, to_status),
    
    -- 체크 제약조건
    CONSTRAINT chk_contract_type_workflow CHECK (contract_type IN (
        'LEASE', 'SUBLEASE', 'RENEWAL', 'AMENDMENT', 'ALL'
    )),
    CONSTRAINT chk_from_status CHECK (from_status IN (
        'DRAFT', 'PENDING', 'APPROVED', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'CANCELLED', 'RENEWED'
    )),
    CONSTRAINT chk_to_status CHECK (to_status IN (
        'DRAFT', 'PENDING', 'APPROVED', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'CANCELLED', 'RENEWED'
    )),
    CONSTRAINT chk_approver_role CHECK (approver_role IN (
        'MANAGER', 'DIRECTOR', 'OWNER', 'LEGAL', 'FINANCE', 'ADMIN'
    )),
    CONSTRAINT chk_trigger_event CHECK (trigger_event IN (
        'DATE_REACHED',        -- 날짜 도달
        'PAYMENT_RECEIVED',    -- 납부 완료
        'DOCUMENT_SIGNED',     -- 서명 완료
        'APPROVAL_COMPLETED',  -- 승인 완료
        'CONDITION_MET',       -- 조건 충족
        'MANUAL_TRIGGER'       -- 수동 트리거
    )),
    CONSTRAINT chk_approval_level CHECK (approval_level BETWEEN 1 AND 5),
    CONSTRAINT chk_execution_order CHECK (execution_order > 0),
    CONSTRAINT chk_different_status CHECK (from_status != to_status)
);

-- 2. 계약 상태 승인 테이블
CREATE TABLE IF NOT EXISTS bms.contract_status_approvals (
    approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    history_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 승인 기본 정보
    approval_level INTEGER NOT NULL,                       -- 승인 단계
    approval_status VARCHAR(20) DEFAULT 'PENDING',         -- 승인 상태
    
    -- 승인자 정보
    approver_id UUID,                                      -- 승인자 ID
    approver_role VARCHAR(20),                             -- 승인자 역할
    approver_name VARCHAR(100),                            -- 승인자명
    
    -- 승인 처리
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),   -- 승인 요청일시
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_deadline TIMESTAMP WITH TIME ZONE,           -- 승인 마감일시
    
    -- 승인 결과
    approval_decision VARCHAR(20),                         -- 승인 결정
    approval_comments TEXT,                                -- 승인 의견
    rejection_reason VARCHAR(20),                          -- 거부 사유
    
    -- 위임 정보
    delegated_to UUID,                                     -- 위임 대상자
    delegation_reason TEXT,                                -- 위임 사유
    delegation_date TIMESTAMP WITH TIME ZONE,             -- 위임 일시
    
    -- 알림 정보
    notification_sent BOOLEAN DEFAULT false,              -- 알림 발송 여부
    reminder_count INTEGER DEFAULT 0,                     -- 리마인더 횟수
    last_reminder_sent TIMESTAMP WITH TIME ZONE,          -- 마지막 리마인더 발송일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_status_approvals_history FOREIGN KEY (history_id) REFERENCES bms.contract_status_history(history_id) ON DELETE CASCADE,
    CONSTRAINT fk_status_approvals_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_approval_status CHECK (approval_status IN (
        'PENDING',             -- 대기중
        'APPROVED',            -- 승인됨
        'REJECTED',            -- 거부됨
        'DELEGATED',           -- 위임됨
        'EXPIRED',             -- 만료됨
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_approval_decision CHECK (approval_decision IN (
        'APPROVE',             -- 승인
        'REJECT',              -- 거부
        'CONDITIONAL_APPROVE', -- 조건부 승인
        'REQUEST_MODIFICATION', -- 수정 요청
        'DELEGATE'             -- 위임
    )),
    CONSTRAINT chk_rejection_reason CHECK (rejection_reason IN (
        'INSUFFICIENT_INFO',   -- 정보 부족
        'POLICY_VIOLATION',    -- 정책 위반
        'LEGAL_ISSUE',         -- 법적 문제
        'FINANCIAL_CONCERN',   -- 재무적 우려
        'DOCUMENTATION_ERROR', -- 서류 오류
        'UNAUTHORIZED',        -- 권한 없음
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_approval_level_range CHECK (approval_level BETWEEN 1 AND 5),
    CONSTRAINT chk_reminder_count CHECK (reminder_count >= 0)
);

-- 3. 계약 상태 자동화 규칙 테이블
CREATE TABLE IF NOT EXISTS bms.contract_status_automation (
    automation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 자동화 규칙 기본 정보
    rule_name VARCHAR(100) NOT NULL,                       -- 규칙명
    rule_description TEXT,                                 -- 규칙 설명
    rule_type VARCHAR(20) NOT NULL,                        -- 규칙 유형
    
    -- 트리거 조건
    trigger_event VARCHAR(20) NOT NULL,                    -- 트리거 이벤트
    trigger_condition JSONB,                               -- 트리거 조건
    
    -- 대상 계약 조건
    target_contract_type VARCHAR(20),                      -- 대상 계약 유형
    target_status VARCHAR(20),                             -- 대상 상태
    target_condition JSONB,                                -- 대상 조건
    
    -- 실행 액션
    action_type VARCHAR(20) NOT NULL,                      -- 액션 유형
    action_parameters JSONB,                               -- 액션 매개변수
    new_status VARCHAR(20),                                -- 새로운 상태
    
    -- 실행 조건
    execution_delay_minutes INTEGER DEFAULT 0,            -- 실행 지연 시간 (분)
    execution_condition JSONB,                             -- 실행 조건
    max_execution_count INTEGER,                           -- 최대 실행 횟수
    
    -- 알림 설정
    send_notification BOOLEAN DEFAULT false,               -- 알림 발송 여부
    notification_recipients TEXT[],                        -- 알림 수신자
    notification_message TEXT,                             -- 알림 메시지
    
    -- 상태 정보
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    execution_count INTEGER DEFAULT 0,                     -- 실행 횟수
    last_executed_at TIMESTAMP WITH TIME ZONE,            -- 마지막 실행일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_status_automation_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_status_automation_name UNIQUE (company_id, rule_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_rule_type CHECK (rule_type IN (
        'STATUS_TRANSITION',   -- 상태 전이
        'NOTIFICATION',        -- 알림
        'DOCUMENT_GENERATION', -- 문서 생성
        'PAYMENT_PROCESSING',  -- 결제 처리
        'VALIDATION',          -- 검증
        'CLEANUP'              -- 정리
    )),
    CONSTRAINT chk_trigger_event_auto CHECK (trigger_event IN (
        'CONTRACT_CREATED',    -- 계약 생성
        'STATUS_CHANGED',      -- 상태 변경
        'DATE_REACHED',        -- 날짜 도달
        'PAYMENT_RECEIVED',    -- 결제 수신
        'DOCUMENT_UPLOADED',   -- 문서 업로드
        'APPROVAL_COMPLETED',  -- 승인 완료
        'SCHEDULE_TRIGGERED'   -- 스케줄 트리거
    )),
    CONSTRAINT chk_action_type CHECK (action_type IN (
        'CHANGE_STATUS',       -- 상태 변경
        'SEND_NOTIFICATION',   -- 알림 발송
        'GENERATE_DOCUMENT',   -- 문서 생성
        'CREATE_TASK',         -- 작업 생성
        'UPDATE_FIELD',        -- 필드 업데이트
        'EXECUTE_FUNCTION'     -- 함수 실행
    )),
    CONSTRAINT chk_execution_delay CHECK (execution_delay_minutes >= 0),
    CONSTRAINT chk_max_execution_count CHECK (max_execution_count IS NULL OR max_execution_count > 0),
    CONSTRAINT chk_execution_count CHECK (execution_count >= 0)
);

-- 4. 계약 상태 알림 이력 테이블
CREATE TABLE IF NOT EXISTS bms.contract_status_notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    history_id UUID,
    approval_id UUID,
    company_id UUID NOT NULL,
    
    -- 알림 기본 정보
    notification_type VARCHAR(20) NOT NULL,                -- 알림 유형
    notification_category VARCHAR(20) NOT NULL,            -- 알림 카테고리
    
    -- 수신자 정보
    recipient_type VARCHAR(20) NOT NULL,                   -- 수신자 유형
    recipient_id UUID,                                     -- 수신자 ID
    recipient_name VARCHAR(100),                           -- 수신자명
    recipient_contact VARCHAR(255),                        -- 수신자 연락처
    
    -- 알림 내용
    notification_title VARCHAR(200),                       -- 알림 제목
    notification_content TEXT,                             -- 알림 내용
    notification_priority VARCHAR(20) DEFAULT 'NORMAL',    -- 알림 우선순위
    
    -- 발송 정보
    delivery_method VARCHAR(20) NOT NULL,                  -- 발송 방법
    scheduled_at TIMESTAMP WITH TIME ZONE,                 -- 예약 일시
    sent_at TIMESTAMP WITH TIME ZONE,                     -- 발송 일시
    delivery_status VARCHAR(20) DEFAULT 'PENDING',         -- 발송 상태
    
    -- 응답 정보
    is_read BOOLEAN DEFAULT false,                         -- 읽음 여부
    read_at TIMESTAMP WITH TIME ZONE,                     -- 읽은 일시
    response_required BOOLEAN DEFAULT false,               -- 응답 필요 여부
    response_deadline TIMESTAMP WITH TIME ZONE,           -- 응답 마감일시
    response_received BOOLEAN DEFAULT false,               -- 응답 수신 여부
    response_content TEXT,                                 -- 응답 내용
    
    -- 재시도 정보
    retry_count INTEGER DEFAULT 0,                         -- 재시도 횟수
    max_retry_count INTEGER DEFAULT 3,                     -- 최대 재시도 횟수
    next_retry_at TIMESTAMP WITH TIME ZONE,               -- 다음 재시도 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_status_notifications_history FOREIGN KEY (history_id) REFERENCES bms.contract_status_history(history_id) ON DELETE CASCADE,
    CONSTRAINT fk_status_notifications_approval FOREIGN KEY (approval_id) REFERENCES bms.contract_status_approvals(approval_id) ON DELETE CASCADE,
    CONSTRAINT fk_status_notifications_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_notification_type CHECK (notification_type IN (
        'STATUS_CHANGE',       -- 상태 변경
        'APPROVAL_REQUEST',    -- 승인 요청
        'APPROVAL_RESULT',     -- 승인 결과
        'DEADLINE_REMINDER',   -- 마감일 알림
        'DOCUMENT_REQUEST',    -- 문서 요청
        'PAYMENT_DUE',         -- 결제 만료
        'CONTRACT_EXPIRY',     -- 계약 만료
        'SYSTEM_ALERT'         -- 시스템 알림
    )),
    CONSTRAINT chk_notification_category CHECK (notification_category IN (
        'URGENT',              -- 긴급
        'IMPORTANT',           -- 중요
        'NORMAL',              -- 일반
        'INFORMATIONAL'        -- 정보성
    )),
    CONSTRAINT chk_recipient_type CHECK (recipient_type IN (
        'USER',                -- 사용자
        'ROLE',                -- 역할
        'PARTY',               -- 계약 당사자
        'EXTERNAL',            -- 외부
        'SYSTEM'               -- 시스템
    )),
    CONSTRAINT chk_notification_priority CHECK (notification_priority IN (
        'HIGH', 'NORMAL', 'LOW'
    )),
    CONSTRAINT chk_delivery_method CHECK (delivery_method IN (
        'EMAIL', 'SMS', 'PUSH', 'KAKAO_TALK', 'SYSTEM_MESSAGE'
    )),
    CONSTRAINT chk_delivery_status CHECK (delivery_status IN (
        'PENDING', 'SENT', 'DELIVERED', 'FAILED', 'CANCELLED'
    )),
    CONSTRAINT chk_retry_counts CHECK (retry_count >= 0 AND max_retry_count >= 0 AND retry_count <= max_retry_count)
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.contract_status_workflows ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_status_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_status_automation ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_status_notifications ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY contract_status_workflows_isolation_policy ON bms.contract_status_workflows
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_status_approvals_isolation_policy ON bms.contract_status_approvals
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_status_automation_isolation_policy ON bms.contract_status_automation
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_status_notifications_isolation_policy ON bms.contract_status_notifications
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 계약 상태 워크플로우 인덱스
CREATE INDEX IF NOT EXISTS idx_status_workflows_company_id ON bms.contract_status_workflows(company_id);
CREATE INDEX IF NOT EXISTS idx_status_workflows_contract_type ON bms.contract_status_workflows(contract_type);
CREATE INDEX IF NOT EXISTS idx_status_workflows_from_status ON bms.contract_status_workflows(from_status);
CREATE INDEX IF NOT EXISTS idx_status_workflows_to_status ON bms.contract_status_workflows(to_status);
CREATE INDEX IF NOT EXISTS idx_status_workflows_active ON bms.contract_status_workflows(is_active);
CREATE INDEX IF NOT EXISTS idx_status_workflows_auto ON bms.contract_status_workflows(auto_transition);

-- 계약 상태 승인 인덱스
CREATE INDEX IF NOT EXISTS idx_status_approvals_history_id ON bms.contract_status_approvals(history_id);
CREATE INDEX IF NOT EXISTS idx_status_approvals_company_id ON bms.contract_status_approvals(company_id);
CREATE INDEX IF NOT EXISTS idx_status_approvals_status ON bms.contract_status_approvals(approval_status);
CREATE INDEX IF NOT EXISTS idx_status_approvals_approver ON bms.contract_status_approvals(approver_id);
CREATE INDEX IF NOT EXISTS idx_status_approvals_deadline ON bms.contract_status_approvals(approval_deadline);
CREATE INDEX IF NOT EXISTS idx_status_approvals_requested_at ON bms.contract_status_approvals(requested_at DESC);

-- 계약 상태 자동화 인덱스
CREATE INDEX IF NOT EXISTS idx_status_automation_company_id ON bms.contract_status_automation(company_id);
CREATE INDEX IF NOT EXISTS idx_status_automation_rule_type ON bms.contract_status_automation(rule_type);
CREATE INDEX IF NOT EXISTS idx_status_automation_trigger ON bms.contract_status_automation(trigger_event);
CREATE INDEX IF NOT EXISTS idx_status_automation_active ON bms.contract_status_automation(is_active);
CREATE INDEX IF NOT EXISTS idx_status_automation_target_status ON bms.contract_status_automation(target_status);

-- 계약 상태 알림 인덱스
CREATE INDEX IF NOT EXISTS idx_status_notifications_history_id ON bms.contract_status_notifications(history_id);
CREATE INDEX IF NOT EXISTS idx_status_notifications_approval_id ON bms.contract_status_notifications(approval_id);
CREATE INDEX IF NOT EXISTS idx_status_notifications_company_id ON bms.contract_status_notifications(company_id);
CREATE INDEX IF NOT EXISTS idx_status_notifications_type ON bms.contract_status_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_status_notifications_recipient ON bms.contract_status_notifications(recipient_id);
CREATE INDEX IF NOT EXISTS idx_status_notifications_delivery_status ON bms.contract_status_notifications(delivery_status);
CREATE INDEX IF NOT EXISTS idx_status_notifications_scheduled_at ON bms.contract_status_notifications(scheduled_at);
CREATE INDEX IF NOT EXISTS idx_status_notifications_sent_at ON bms.contract_status_notifications(sent_at DESC);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_status_workflows_transition ON bms.contract_status_workflows(company_id, contract_type, from_status, to_status);
CREATE INDEX IF NOT EXISTS idx_status_approvals_pending ON bms.contract_status_approvals(company_id, approval_status, approval_deadline);
CREATE INDEX IF NOT EXISTS idx_status_automation_trigger_active ON bms.contract_status_automation(trigger_event, is_active);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER contract_status_workflows_updated_at_trigger
    BEFORE UPDATE ON bms.contract_status_workflows
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_status_approvals_updated_at_trigger
    BEFORE UPDATE ON bms.contract_status_approvals
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_status_automation_updated_at_trigger
    BEFORE UPDATE ON bms.contract_status_automation
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 스크립트 완료 메시지
SELECT '계약 상태 관리 시스템 테이블 생성이 완료되었습니다.' as message;