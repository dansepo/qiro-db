-- =====================================================
-- 연체 관리 시스템 테이블 생성 스크립트 (수정본)
-- Phase 5.2: 연체 관리 시스템
-- =====================================================

-- 1. 연체 정책 설정 테이블
CREATE TABLE IF NOT EXISTS bms.overdue_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체
    
    -- 정책 기본 정보
    policy_name VARCHAR(100) NOT NULL,                     -- 정책명
    policy_description TEXT,                               -- 정책 설명
    policy_type VARCHAR(20) NOT NULL,                      -- 정책 유형
    
    -- 연체 기준
    grace_period_days INTEGER DEFAULT 0,                   -- 유예 기간 (일)
    overdue_threshold_days INTEGER NOT NULL,               -- 연체 기준일
    
    -- 연체료 설정
    late_fee_calculation_method VARCHAR(20) NOT NULL,      -- 연체료 계산 방법
    daily_late_fee_rate DECIMAL(8,4) DEFAULT 0.025,        -- 일일 연체료율 (%)
    monthly_late_fee_rate DECIMAL(8,4),                    -- 월별 연체료율 (%)
    fixed_late_fee_amount DECIMAL(15,2),                   -- 고정 연체료
    
    -- 연체료 한도
    max_late_fee_rate DECIMAL(8,4) DEFAULT 25.0,           -- 최대 연체료율 (%)
    max_late_fee_amount DECIMAL(15,2),                     -- 최대 연체료 금액
    min_late_fee_amount DECIMAL(15,2) DEFAULT 0,           -- 최소 연체료 금액
    
    -- 연체 단계별 설정
    stage_configurations JSONB,                            -- 단계별 설정 (JSON)
    
    -- 면제 조건
    exemption_conditions JSONB,                            -- 면제 조건 (JSON)
    auto_exemption_enabled BOOLEAN DEFAULT false,          -- 자동 면제 활성화
    
    -- 알림 설정
    notification_enabled BOOLEAN DEFAULT true,             -- 알림 활성화
    notification_stages TEXT[],                            -- 알림 단계
    notification_channels TEXT[],                          -- 알림 채널
    
    -- 법적 조치 설정
    legal_action_enabled BOOLEAN DEFAULT false,            -- 법적 조치 활성화
    legal_action_threshold_days INTEGER,                   -- 법적 조치 기준일
    legal_action_threshold_amount DECIMAL(15,2),           -- 법적 조치 기준 금액
    
    -- 상태 및 기간
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    effective_start_date DATE DEFAULT CURRENT_DATE,        -- 시작일
    effective_end_date DATE,                               -- 종료일
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_overdue_policies_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_policies_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_overdue_policies_name UNIQUE (company_id, building_id, policy_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_policy_type CHECK (policy_type IN (
        'STANDARD',            -- 표준 정책
        'LENIENT',             -- 관대한 정책
        'STRICT',              -- 엄격한 정책
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_late_fee_calculation_method CHECK (late_fee_calculation_method IN (
        'DAILY_RATE',          -- 일일 요율
        'MONTHLY_RATE',        -- 월별 요율
        'FIXED_AMOUNT',        -- 고정 금액
        'TIERED_RATE',         -- 단계별 요율
        'COMPOUND_RATE'        -- 복리 요율
    )),
    CONSTRAINT chk_periods CHECK (
        grace_period_days >= 0 AND overdue_threshold_days > 0 AND
        (legal_action_threshold_days IS NULL OR legal_action_threshold_days > overdue_threshold_days)
    ),
    CONSTRAINT chk_rates CHECK (
        daily_late_fee_rate >= 0 AND daily_late_fee_rate <= 100 AND
        (monthly_late_fee_rate IS NULL OR (monthly_late_fee_rate >= 0 AND monthly_late_fee_rate <= 100)) AND
        max_late_fee_rate >= 0 AND max_late_fee_rate <= 100
    ),
    CONSTRAINT chk_amounts CHECK (
        (fixed_late_fee_amount IS NULL OR fixed_late_fee_amount >= 0) AND
        (max_late_fee_amount IS NULL OR max_late_fee_amount >= 0) AND
        min_late_fee_amount >= 0 AND
        (legal_action_threshold_amount IS NULL OR legal_action_threshold_amount > 0)
    ),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 2. 연체 현황 테이블
CREATE TABLE IF NOT EXISTS bms.overdue_records (
    overdue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    issuance_id UUID NOT NULL,
    policy_id UUID NOT NULL,
    
    -- 연체 기본 정보
    overdue_status VARCHAR(20) DEFAULT 'ACTIVE',           -- 연체 상태
    overdue_stage VARCHAR(20) DEFAULT 'INITIAL',           -- 연체 단계
    
    -- 금액 정보
    original_amount DECIMAL(15,2) NOT NULL,                -- 원금
    outstanding_amount DECIMAL(15,2) NOT NULL,             -- 미납 금액
    late_fee_amount DECIMAL(15,2) DEFAULT 0,               -- 연체료
    total_overdue_amount DECIMAL(15,2) NOT NULL,           -- 총 연체 금액
    
    -- 연체 기간
    due_date DATE NOT NULL,                                -- 납부 기한
    overdue_start_date DATE NOT NULL,                      -- 연체 시작일
    overdue_days INTEGER NOT NULL DEFAULT 0,               -- 연체 일수
    
    -- 연체료 계산
    late_fee_calculation_date DATE,                        -- 연체료 계산일
    late_fee_rate_applied DECIMAL(8,4),                    -- 적용된 연체료율
    late_fee_calculation_details JSONB,                    -- 연체료 계산 상세
    
    -- 알림 이력
    notification_count INTEGER DEFAULT 0,                  -- 알림 횟수
    last_notification_date DATE,                           -- 마지막 알림일
    next_notification_date DATE,                           -- 다음 알림일
    
    -- 조치 이력
    warning_issued BOOLEAN DEFAULT false,                  -- 경고 발송 여부
    warning_issued_date DATE,                              -- 경고 발송일
    legal_action_initiated BOOLEAN DEFAULT false,          -- 법적 조치 개시 여부
    legal_action_date DATE,                                -- 법적 조치 일자
    
    -- 면제 정보
    is_exempted BOOLEAN DEFAULT false,                     -- 면제 여부
    exemption_reason TEXT,                                 -- 면제 사유
    exempted_by UUID,                                      -- 면제 승인자
    exempted_at TIMESTAMP WITH TIME ZONE,                 -- 면제 일시
    
    -- 해결 정보
    is_resolved BOOLEAN DEFAULT false,                     -- 해결 여부
    resolved_date DATE,                                    -- 해결일
    resolution_method VARCHAR(20),                         -- 해결 방법
    resolution_amount DECIMAL(15,2),                       -- 해결 금액
    resolution_notes TEXT,                                 -- 해결 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_overdue_records_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_records_issuance FOREIGN KEY (issuance_id) REFERENCES bms.bill_issuances(issuance_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_records_policy FOREIGN KEY (policy_id) REFERENCES bms.overdue_policies(policy_id) ON DELETE RESTRICT,
    CONSTRAINT fk_overdue_records_exempter FOREIGN KEY (exempted_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_overdue_records_issuance UNIQUE (issuance_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_overdue_status CHECK (overdue_status IN (
        'ACTIVE',              -- 활성 연체
        'RESOLVED',            -- 해결됨
        'EXEMPTED',            -- 면제됨
        'WRITTEN_OFF',         -- 손실 처리
        'LEGAL_ACTION',        -- 법적 조치중
        'SUSPENDED'            -- 중단됨
    )),
    CONSTRAINT chk_overdue_stage CHECK (overdue_stage IN (
        'INITIAL',             -- 초기 연체
        'WARNING',             -- 경고 단계
        'DEMAND',              -- 독촉 단계
        'FINAL_NOTICE',        -- 최종 통지
        'LEGAL_PREPARATION',   -- 법적 조치 준비
        'LEGAL_ACTION'         -- 법적 조치
    )),
    CONSTRAINT chk_resolution_method CHECK (resolution_method IN (
        'FULL_PAYMENT',        -- 전액 납부
        'PARTIAL_PAYMENT',     -- 부분 납부
        'INSTALLMENT',         -- 분할 납부
        'SETTLEMENT',          -- 합의
        'WRITE_OFF',           -- 손실 처리
        'LEGAL_RECOVERY'       -- 법적 회수
    )),
    CONSTRAINT chk_amounts_overdue CHECK (
        original_amount >= 0 AND outstanding_amount >= 0 AND
        late_fee_amount >= 0 AND total_overdue_amount >= 0 AND
        (resolution_amount IS NULL OR resolution_amount >= 0)
    ),
    CONSTRAINT chk_overdue_days CHECK (overdue_days >= 0),
    CONSTRAINT chk_notification_count CHECK (notification_count >= 0),
    CONSTRAINT chk_dates_overdue CHECK (
        overdue_start_date >= due_date AND
        (late_fee_calculation_date IS NULL OR late_fee_calculation_date >= overdue_start_date) AND
        (resolved_date IS NULL OR resolved_date >= overdue_start_date)
    )
);

-- 3. 연체 알림 이력 테이블
CREATE TABLE IF NOT EXISTS bms.overdue_notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    overdue_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 알림 기본 정보
    notification_type VARCHAR(20) NOT NULL,                -- 알림 유형
    notification_stage VARCHAR(20) NOT NULL,               -- 알림 단계
    notification_method VARCHAR(20) NOT NULL,              -- 알림 방법
    
    -- 알림 내용
    notification_title VARCHAR(200),                       -- 알림 제목
    notification_content TEXT,                             -- 알림 내용
    template_id UUID,                                      -- 사용된 템플릿 ID
    
    -- 수신자 정보
    recipient_name VARCHAR(100),                           -- 수신자명
    recipient_contact VARCHAR(255),                        -- 수신자 연락처
    recipient_address TEXT,                                -- 수신자 주소
    
    -- 발송 정보
    scheduled_at TIMESTAMP WITH TIME ZONE,                 -- 예약 일시
    sent_at TIMESTAMP WITH TIME ZONE,                     -- 발송 일시
    delivery_status VARCHAR(20) DEFAULT 'PENDING',         -- 배송 상태
    
    -- 응답 정보
    is_read BOOLEAN DEFAULT false,                         -- 읽음 여부
    read_at TIMESTAMP WITH TIME ZONE,                     -- 읽은 일시
    response_received BOOLEAN DEFAULT false,               -- 응답 수신 여부
    response_content TEXT,                                 -- 응답 내용
    response_date DATE,                                    -- 응답 일자
    
    -- 비용 정보
    notification_cost DECIMAL(10,4) DEFAULT 0,             -- 알림 비용
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_overdue_notifications_overdue FOREIGN KEY (overdue_id) REFERENCES bms.overdue_records(overdue_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_notifications_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_notification_type CHECK (notification_type IN (
        'REMINDER',            -- 납부 안내
        'WARNING',             -- 경고
        'DEMAND',              -- 독촉
        'FINAL_NOTICE',        -- 최종 통지
        'LEGAL_NOTICE',        -- 법적 통지
        'SETTLEMENT_OFFER'     -- 합의 제안
    )),
    CONSTRAINT chk_notification_stage CHECK (notification_stage IN (
        'INITIAL', 'WARNING', 'DEMAND', 'FINAL_NOTICE', 'LEGAL_PREPARATION', 'LEGAL_ACTION'
    )),
    CONSTRAINT chk_notification_method CHECK (notification_method IN (
        'EMAIL',               -- 이메일
        'SMS',                 -- SMS
        'KAKAO_TALK',          -- 카카오톡
        'POSTAL',              -- 우편
        'PHONE_CALL',          -- 전화
        'VISIT',               -- 방문
        'LEGAL_DOCUMENT'       -- 법적 서면
    )),
    CONSTRAINT chk_delivery_status CHECK (delivery_status IN (
        'PENDING',             -- 대기중
        'SENT',                -- 발송됨
        'DELIVERED',           -- 배달됨
        'FAILED',              -- 실패
        'BOUNCED',             -- 반송됨
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_notification_cost CHECK (notification_cost >= 0)
);

-- 4. 연체 조치 이력 테이블
CREATE TABLE IF NOT EXISTS bms.overdue_actions (
    action_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    overdue_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 조치 기본 정보
    action_type VARCHAR(20) NOT NULL,                      -- 조치 유형
    action_stage VARCHAR(20) NOT NULL,                     -- 조치 단계
    action_description TEXT,                               -- 조치 설명
    
    -- 조치 일정
    scheduled_date DATE,                                   -- 예정일
    executed_date DATE,                                    -- 실행일
    due_date DATE,                                         -- 완료 기한
    
    -- 조치 상태
    action_status VARCHAR(20) DEFAULT 'PLANNED',           -- 조치 상태
    
    -- 담당자 정보
    assigned_to UUID,                                      -- 담당자
    executed_by UUID,                                      -- 실행자
    
    -- 조치 결과
    action_result VARCHAR(20),                             -- 조치 결과
    result_amount DECIMAL(15,2),                           -- 결과 금액
    result_description TEXT,                               -- 결과 설명
    
    -- 비용 정보
    action_cost DECIMAL(15,2) DEFAULT 0,                   -- 조치 비용
    recovery_amount DECIMAL(15,2) DEFAULT 0,               -- 회수 금액
    
    -- 문서 정보
    document_path TEXT,                                    -- 관련 문서 경로
    document_type VARCHAR(20),                             -- 문서 유형
    
    -- 법적 정보
    legal_reference VARCHAR(100),                          -- 법적 근거
    court_case_number VARCHAR(50),                         -- 법원 사건번호
    lawyer_info JSONB,                                     -- 변호사 정보
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_overdue_actions_overdue FOREIGN KEY (overdue_id) REFERENCES bms.overdue_records(overdue_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_actions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_actions_assignee FOREIGN KEY (assigned_to) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_overdue_actions_executor FOREIGN KEY (executed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_action_type CHECK (action_type IN (
        'PHONE_CALL',          -- 전화 독촉
        'EMAIL_REMINDER',      -- 이메일 독촉
        'POSTAL_NOTICE',       -- 우편 통지
        'VISIT',               -- 방문 독촉
        'PAYMENT_PLAN',        -- 납부 계획 수립
        'SETTLEMENT',          -- 합의 협상
        'LEGAL_CONSULTATION',  -- 법적 상담
        'COURT_FILING',        -- 법원 제출
        'ASSET_SEIZURE',       -- 자산 압류
        'WRITE_OFF'            -- 손실 처리
    )),
    CONSTRAINT chk_action_stage CHECK (action_stage IN (
        'INITIAL', 'WARNING', 'DEMAND', 'FINAL_NOTICE', 'LEGAL_PREPARATION', 'LEGAL_ACTION'
    )),
    CONSTRAINT chk_action_status CHECK (action_status IN (
        'PLANNED',             -- 계획됨
        'IN_PROGRESS',         -- 진행중
        'COMPLETED',           -- 완료
        'CANCELLED',           -- 취소
        'FAILED',              -- 실패
        'DEFERRED'             -- 연기
    )),
    CONSTRAINT chk_action_result CHECK (action_result IN (
        'SUCCESS',             -- 성공
        'PARTIAL_SUCCESS',     -- 부분 성공
        'NO_RESPONSE',         -- 무응답
        'REFUSED',             -- 거부
        'FAILED',              -- 실패
        'PENDING'              -- 대기중
    )),
    CONSTRAINT chk_document_type CHECK (document_type IN (
        'NOTICE',              -- 통지서
        'DEMAND_LETTER',       -- 독촉장
        'LEGAL_DOCUMENT',      -- 법적 서면
        'SETTLEMENT_AGREEMENT', -- 합의서
        'COURT_DOCUMENT',      -- 법원 서류
        'RECEIPT'              -- 영수증
    )),
    CONSTRAINT chk_amounts_action CHECK (
        action_cost >= 0 AND recovery_amount >= 0 AND
        (result_amount IS NULL OR result_amount >= 0)
    ),
    CONSTRAINT chk_dates_action CHECK (
        (executed_date IS NULL OR scheduled_date IS NULL OR executed_date >= scheduled_date) AND
        (due_date IS NULL OR scheduled_date IS NULL OR due_date >= scheduled_date)
    )
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.overdue_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.overdue_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.overdue_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.overdue_actions ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY overdue_policies_isolation_policy ON bms.overdue_policies
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY overdue_records_isolation_policy ON bms.overdue_records
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY overdue_notifications_isolation_policy ON bms.overdue_notifications
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY overdue_actions_isolation_policy ON bms.overdue_actions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 연체 정책 인덱스
CREATE INDEX IF NOT EXISTS idx_overdue_policies_company_id ON bms.overdue_policies(company_id);
CREATE INDEX IF NOT EXISTS idx_overdue_policies_building_id ON bms.overdue_policies(building_id);
CREATE INDEX IF NOT EXISTS idx_overdue_policies_type ON bms.overdue_policies(policy_type);
CREATE INDEX IF NOT EXISTS idx_overdue_policies_active ON bms.overdue_policies(is_active);
CREATE INDEX IF NOT EXISTS idx_overdue_policies_effective_dates ON bms.overdue_policies(effective_start_date, effective_end_date);

-- 연체 현황 인덱스
CREATE INDEX IF NOT EXISTS idx_overdue_records_company_id ON bms.overdue_records(company_id);
CREATE INDEX IF NOT EXISTS idx_overdue_records_issuance_id ON bms.overdue_records(issuance_id);
CREATE INDEX IF NOT EXISTS idx_overdue_records_policy_id ON bms.overdue_records(policy_id);
CREATE INDEX IF NOT EXISTS idx_overdue_records_status ON bms.overdue_records(overdue_status);
CREATE INDEX IF NOT EXISTS idx_overdue_records_stage ON bms.overdue_records(overdue_stage);
CREATE INDEX IF NOT EXISTS idx_overdue_records_due_date ON bms.overdue_records(due_date);
CREATE INDEX IF NOT EXISTS idx_overdue_records_overdue_days ON bms.overdue_records(overdue_days DESC);
CREATE INDEX IF NOT EXISTS idx_overdue_records_amount ON bms.overdue_records(total_overdue_amount DESC);
CREATE INDEX IF NOT EXISTS idx_overdue_records_resolved ON bms.overdue_records(is_resolved);

-- 연체 알림 인덱스
CREATE INDEX IF NOT EXISTS idx_overdue_notifications_overdue_id ON bms.overdue_notifications(overdue_id);
CREATE INDEX IF NOT EXISTS idx_overdue_notifications_company_id ON bms.overdue_notifications(company_id);
CREATE INDEX IF NOT EXISTS idx_overdue_notifications_type ON bms.overdue_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_overdue_notifications_method ON bms.overdue_notifications(notification_method);
CREATE INDEX IF NOT EXISTS idx_overdue_notifications_status ON bms.overdue_notifications(delivery_status);
CREATE INDEX IF NOT EXISTS idx_overdue_notifications_sent_at ON bms.overdue_notifications(sent_at DESC);

-- 연체 조치 인덱스
CREATE INDEX IF NOT EXISTS idx_overdue_actions_overdue_id ON bms.overdue_actions(overdue_id);
CREATE INDEX IF NOT EXISTS idx_overdue_actions_company_id ON bms.overdue_actions(company_id);
CREATE INDEX IF NOT EXISTS idx_overdue_actions_type ON bms.overdue_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_overdue_actions_status ON bms.overdue_actions(action_status);
CREATE INDEX IF NOT EXISTS idx_overdue_actions_assigned_to ON bms.overdue_actions(assigned_to);
CREATE INDEX IF NOT EXISTS idx_overdue_actions_scheduled_date ON bms.overdue_actions(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_overdue_actions_executed_date ON bms.overdue_actions(executed_date DESC);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_overdue_records_company_status ON bms.overdue_records(company_id, overdue_status);
CREATE INDEX IF NOT EXISTS idx_overdue_records_status_days ON bms.overdue_records(overdue_status, overdue_days DESC);
CREATE INDEX IF NOT EXISTS idx_overdue_notifications_overdue_type ON bms.overdue_notifications(overdue_id, notification_type);
CREATE INDEX IF NOT EXISTS idx_overdue_actions_overdue_status ON bms.overdue_actions(overdue_id, action_status);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER overdue_policies_updated_at_trigger
    BEFORE UPDATE ON bms.overdue_policies
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER overdue_records_updated_at_trigger
    BEFORE UPDATE ON bms.overdue_records
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER overdue_actions_updated_at_trigger
    BEFORE UPDATE ON bms.overdue_actions
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 스크립트 완료 메시지
SELECT '연체 관리 시스템 테이블 생성이 완료되었습니다.' as message;