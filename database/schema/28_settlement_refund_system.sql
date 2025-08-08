-- =====================================================
-- 정산 및 환불 관리 시스템 테이블 생성 스크립트
-- Phase 5.3: 정산 및 환불 관리 시스템
-- =====================================================

-- 1. 정산 정책 설정 테이블
CREATE TABLE IF NOT EXISTS bms.settlement_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체
    
    -- 정책 기본 정보
    policy_name VARCHAR(100) NOT NULL,                     -- 정책명
    policy_description TEXT,                               -- 정책 설명
    policy_type VARCHAR(20) NOT NULL,                      -- 정책 유형
    
    -- 정산 기준
    settlement_threshold_amount DECIMAL(15,2) DEFAULT 1000, -- 정산 기준 금액
    auto_settlement_enabled BOOLEAN DEFAULT false,         -- 자동 정산 활성화
    auto_settlement_threshold DECIMAL(15,2),               -- 자동 정산 기준 금액
    
    -- 환불 설정
    refund_method VARCHAR(20) DEFAULT 'BANK_TRANSFER',     -- 기본 환불 방법
    refund_processing_days INTEGER DEFAULT 7,              -- 환불 처리 기간 (일)
    refund_fee DECIMAL(10,2) DEFAULT 0,                    -- 환불 수수료
    
    -- 차액 정산 설정
    balance_carry_forward BOOLEAN DEFAULT true,            -- 차액 이월 여부
    carry_forward_threshold DECIMAL(15,2) DEFAULT 10000,   -- 이월 기준 금액
    
    -- 승인 설정
    approval_required BOOLEAN DEFAULT true,                -- 승인 필요 여부
    approval_threshold_amount DECIMAL(15,2) DEFAULT 50000, -- 승인 필요 기준 금액
    
    -- 알림 설정
    notification_enabled BOOLEAN DEFAULT true,             -- 알림 활성화
    notification_methods TEXT[],                           -- 알림 방법
    
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
    CONSTRAINT fk_settlement_policies_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlement_policies_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_settlement_policies_name UNIQUE (company_id, building_id, policy_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_policy_type CHECK (policy_type IN (
        'STANDARD',            -- 표준 정책
        'IMMEDIATE',           -- 즉시 정산
        'MONTHLY',             -- 월별 정산
        'QUARTERLY',           -- 분기별 정산
        'ANNUAL'               -- 연간 정산
    )),
    CONSTRAINT chk_refund_method CHECK (refund_method IN (
        'BANK_TRANSFER',       -- 계좌 이체
        'CASH',                -- 현금
        'CHECK',               -- 수표
        'CREDIT_CARD_CANCEL',  -- 신용카드 취소
        'NEXT_BILL_CREDIT'     -- 다음 청구서 차감
    )),
    CONSTRAINT chk_amounts_policy CHECK (
        settlement_threshold_amount >= 0 AND
        (auto_settlement_threshold IS NULL OR auto_settlement_threshold >= 0) AND
        refund_fee >= 0 AND
        (carry_forward_threshold IS NULL OR carry_forward_threshold >= 0) AND
        (approval_threshold_amount IS NULL OR approval_threshold_amount >= 0)
    ),
    CONSTRAINT chk_processing_days CHECK (refund_processing_days > 0),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 2. 정산 요청 테이블
CREATE TABLE IF NOT EXISTS bms.settlement_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    policy_id UUID NOT NULL,
    
    -- 요청 기본 정보
    request_number VARCHAR(50) NOT NULL,                   -- 요청 번호
    request_type VARCHAR(20) NOT NULL,                     -- 요청 유형
    request_status VARCHAR(20) DEFAULT 'PENDING',          -- 요청 상태
    
    -- 정산 대상
    target_period_start DATE NOT NULL,                     -- 정산 대상 시작일
    target_period_end DATE NOT NULL,                       -- 정산 대상 종료일
    related_issuance_ids UUID[],                           -- 관련 청구서 ID 목록
    
    -- 금액 정보
    total_charged_amount DECIMAL(15,2) NOT NULL,           -- 총 청구 금액
    total_paid_amount DECIMAL(15,2) NOT NULL,              -- 총 납부 금액
    settlement_amount DECIMAL(15,2) NOT NULL,              -- 정산 금액 (+ 환불, - 추가징수)
    refund_fee_amount DECIMAL(15,2) DEFAULT 0,             -- 환불 수수료
    final_settlement_amount DECIMAL(15,2) NOT NULL,        -- 최종 정산 금액
    
    -- 정산 사유
    settlement_reason VARCHAR(20) NOT NULL,                -- 정산 사유
    settlement_description TEXT,                           -- 정산 상세 설명
    supporting_documents JSONB,                            -- 증빙 서류 정보
    
    -- 요청자 정보
    requested_by UUID,                                     -- 요청자
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),   -- 요청 일시
    request_notes TEXT,                                    -- 요청 메모
    
    -- 승인 정보
    approval_required BOOLEAN DEFAULT true,                -- 승인 필요 여부
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 거부 정보
    rejected_by UUID,                                      -- 거부자
    rejected_at TIMESTAMP WITH TIME ZONE,                 -- 거부 일시
    rejection_reason TEXT,                                 -- 거부 사유
    
    -- 처리 정보
    processed_by UUID,                                     -- 처리자
    processed_at TIMESTAMP WITH TIME ZONE,                -- 처리 일시
    processing_notes TEXT,                                 -- 처리 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_settlement_requests_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlement_requests_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlement_requests_policy FOREIGN KEY (policy_id) REFERENCES bms.settlement_policies(policy_id) ON DELETE RESTRICT,
    CONSTRAINT uk_settlement_requests_number UNIQUE (company_id, request_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_request_type CHECK (request_type IN (
        'OVERPAYMENT_REFUND',  -- 과납금 환불
        'UNDERPAYMENT_CHARGE', -- 미납금 추가 징수
        'RATE_ADJUSTMENT',     -- 요율 조정
        'BILLING_ERROR',       -- 청구 오류
        'METER_CORRECTION',    -- 검침 정정
        'POLICY_CHANGE',       -- 정책 변경
        'MANUAL_ADJUSTMENT'    -- 수동 조정
    )),
    CONSTRAINT chk_request_status CHECK (request_status IN (
        'PENDING',             -- 대기중
        'UNDER_REVIEW',        -- 검토중
        'APPROVED',            -- 승인됨
        'REJECTED',            -- 거부됨
        'PROCESSING',          -- 처리중
        'COMPLETED',           -- 완료됨
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_settlement_reason CHECK (settlement_reason IN (
        'OVERPAYMENT',         -- 과납
        'UNDERPAYMENT',        -- 미납
        'RATE_ERROR',          -- 요율 오류
        'METER_ERROR',         -- 검침 오류
        'BILLING_ERROR',       -- 청구 오류
        'POLICY_CHANGE',       -- 정책 변경
        'SYSTEM_ERROR',        -- 시스템 오류
        'CUSTOMER_REQUEST',    -- 고객 요청
        'AUDIT_ADJUSTMENT'     -- 감사 조정
    )),
    CONSTRAINT chk_amounts_request CHECK (
        total_charged_amount >= 0 AND total_paid_amount >= 0 AND
        refund_fee_amount >= 0 AND
        final_settlement_amount = settlement_amount - refund_fee_amount
    ),
    CONSTRAINT chk_period CHECK (target_period_end >= target_period_start)
);

-- 3. 환불 처리 테이블
CREATE TABLE IF NOT EXISTS bms.refund_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    request_id UUID NOT NULL,
    
    -- 환불 기본 정보
    transaction_number VARCHAR(50) NOT NULL,               -- 거래 번호
    refund_method VARCHAR(20) NOT NULL,                    -- 환불 방법
    refund_amount DECIMAL(15,2) NOT NULL,                  -- 환불 금액
    refund_fee DECIMAL(10,2) DEFAULT 0,                    -- 환불 수수료
    net_refund_amount DECIMAL(15,2) NOT NULL,              -- 실 환불 금액
    
    -- 환불 대상 정보
    recipient_name VARCHAR(100) NOT NULL,                  -- 수취인명
    recipient_account_info JSONB,                          -- 수취인 계좌 정보
    recipient_contact VARCHAR(255),                        -- 수취인 연락처
    
    -- 처리 상태
    transaction_status VARCHAR(20) DEFAULT 'PENDING',      -- 거래 상태
    
    -- 은행 이체 정보
    bank_name VARCHAR(100),                                -- 은행명
    account_number VARCHAR(50),                            -- 계좌번호
    account_holder VARCHAR(100),                           -- 예금주
    transfer_reference VARCHAR(100),                       -- 이체 참조번호
    
    -- 처리 일정
    scheduled_date DATE,                                   -- 예정일
    processed_date DATE,                                   -- 처리일
    completed_date DATE,                                   -- 완료일
    
    -- 처리 결과
    processing_result VARCHAR(20),                         -- 처리 결과
    result_message TEXT,                                   -- 결과 메시지
    external_reference VARCHAR(100),                       -- 외부 참조번호 (은행 등)
    
    -- 담당자 정보
    processed_by UUID,                                     -- 처리자
    verified_by UUID,                                      -- 확인자
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_refund_transactions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_refund_transactions_request FOREIGN KEY (request_id) REFERENCES bms.settlement_requests(request_id) ON DELETE CASCADE,
    CONSTRAINT uk_refund_transactions_number UNIQUE (company_id, transaction_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_refund_method CHECK (refund_method IN (
        'BANK_TRANSFER',       -- 계좌 이체
        'CASH',                -- 현금
        'CHECK',               -- 수표
        'CREDIT_CARD_CANCEL',  -- 신용카드 취소
        'NEXT_BILL_CREDIT'     -- 다음 청구서 차감
    )),
    CONSTRAINT chk_transaction_status CHECK (transaction_status IN (
        'PENDING',             -- 대기중
        'SCHEDULED',           -- 예약됨
        'PROCESSING',          -- 처리중
        'COMPLETED',           -- 완료됨
        'FAILED',              -- 실패
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_processing_result CHECK (processing_result IN (
        'SUCCESS',             -- 성공
        'FAILED',              -- 실패
        'PARTIAL',             -- 부분 성공
        'CANCELLED',           -- 취소
        'PENDING'              -- 대기중
    )),
    CONSTRAINT chk_amounts_refund CHECK (
        refund_amount > 0 AND refund_fee >= 0 AND
        net_refund_amount = refund_amount - refund_fee
    ),
    CONSTRAINT chk_dates_refund CHECK (
        (processed_date IS NULL OR scheduled_date IS NULL OR processed_date >= scheduled_date) AND
        (completed_date IS NULL OR processed_date IS NULL OR completed_date >= processed_date)
    )
);

-- 4. 차액 정산 이력 테이블
CREATE TABLE IF NOT EXISTS bms.balance_adjustments (
    adjustment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    request_id UUID,                                       -- 관련 정산 요청 (선택사항)
    
    -- 조정 기본 정보
    adjustment_number VARCHAR(50) NOT NULL,                -- 조정 번호
    adjustment_type VARCHAR(20) NOT NULL,                  -- 조정 유형
    adjustment_reason VARCHAR(20) NOT NULL,                -- 조정 사유
    
    -- 조정 대상 기간
    target_period_start DATE NOT NULL,                     -- 대상 시작일
    target_period_end DATE NOT NULL,                       -- 대상 종료일
    
    -- 금액 정보
    original_amount DECIMAL(15,2) NOT NULL,                -- 원래 금액
    adjusted_amount DECIMAL(15,2) NOT NULL,                -- 조정 금액
    adjustment_difference DECIMAL(15,2) NOT NULL,          -- 조정 차액
    
    -- 조정 상세
    adjustment_description TEXT,                           -- 조정 설명
    calculation_details JSONB,                             -- 계산 상세
    supporting_evidence JSONB,                             -- 증빙 자료
    
    -- 처리 정보
    adjustment_status VARCHAR(20) DEFAULT 'PENDING',       -- 조정 상태
    applied_to_next_bill BOOLEAN DEFAULT false,            -- 다음 청구서 반영 여부
    next_bill_credit_amount DECIMAL(15,2) DEFAULT 0,       -- 다음 청구서 차감 금액
    
    -- 승인 정보
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 적용 정보
    applied_by UUID,                                       -- 적용자
    applied_at TIMESTAMP WITH TIME ZONE,                  -- 적용 일시
    application_notes TEXT,                                -- 적용 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_balance_adjustments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_balance_adjustments_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_balance_adjustments_request FOREIGN KEY (request_id) REFERENCES bms.settlement_requests(request_id) ON DELETE SET NULL,
    CONSTRAINT uk_balance_adjustments_number UNIQUE (company_id, adjustment_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_adjustment_type CHECK (adjustment_type IN (
        'CREDIT',              -- 차감 (고객에게 유리)
        'DEBIT',               -- 추가 (고객에게 불리)
        'CORRECTION',          -- 정정
        'CARRY_FORWARD',       -- 이월
        'WRITE_OFF'            -- 손실 처리
    )),
    CONSTRAINT chk_adjustment_reason CHECK (adjustment_reason IN (
        'OVERPAYMENT',         -- 과납
        'UNDERPAYMENT',        -- 미납
        'RATE_CORRECTION',     -- 요율 정정
        'METER_CORRECTION',    -- 검침 정정
        'BILLING_ERROR',       -- 청구 오류
        'POLICY_CHANGE',       -- 정책 변경
        'SYSTEM_ERROR',        -- 시스템 오류
        'MANUAL_ADJUSTMENT',   -- 수동 조정
        'AUDIT_FINDING'        -- 감사 지적
    )),
    CONSTRAINT chk_adjustment_status CHECK (adjustment_status IN (
        'PENDING',             -- 대기중
        'APPROVED',            -- 승인됨
        'APPLIED',             -- 적용됨
        'REJECTED',            -- 거부됨
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_amounts_adjustment CHECK (
        original_amount >= 0 AND adjusted_amount >= 0 AND
        adjustment_difference = adjusted_amount - original_amount AND
        next_bill_credit_amount >= 0
    ),
    CONSTRAINT chk_period_adjustment CHECK (target_period_end >= target_period_start)
);

-- 5. 정산 알림 이력 테이블
CREATE TABLE IF NOT EXISTS bms.settlement_notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    request_id UUID,                                       -- 관련 정산 요청
    transaction_id UUID,                                   -- 관련 환불 거래
    
    -- 알림 기본 정보
    notification_type VARCHAR(20) NOT NULL,                -- 알림 유형
    notification_method VARCHAR(20) NOT NULL,              -- 알림 방법
    notification_status VARCHAR(20) DEFAULT 'PENDING',     -- 알림 상태
    
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
    
    -- 비용 정보
    notification_cost DECIMAL(10,4) DEFAULT 0,             -- 알림 비용
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_settlement_notifications_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlement_notifications_request FOREIGN KEY (request_id) REFERENCES bms.settlement_requests(request_id) ON DELETE CASCADE,
    CONSTRAINT fk_settlement_notifications_transaction FOREIGN KEY (transaction_id) REFERENCES bms.refund_transactions(transaction_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_notification_type CHECK (notification_type IN (
        'REQUEST_SUBMITTED',   -- 요청 접수
        'REQUEST_APPROVED',    -- 요청 승인
        'REQUEST_REJECTED',    -- 요청 거부
        'REFUND_SCHEDULED',    -- 환불 예약
        'REFUND_COMPLETED',    -- 환불 완료
        'REFUND_FAILED',       -- 환불 실패
        'ADJUSTMENT_APPLIED',  -- 조정 적용
        'BALANCE_UPDATED'      -- 잔액 업데이트
    )),
    CONSTRAINT chk_notification_method CHECK (notification_method IN (
        'EMAIL',               -- 이메일
        'SMS',                 -- SMS
        'KAKAO_TALK',          -- 카카오톡
        'POSTAL',              -- 우편
        'PHONE_CALL',          -- 전화
        'MOBILE_PUSH'          -- 모바일 푸시
    )),
    CONSTRAINT chk_notification_status CHECK (notification_status IN (
        'PENDING',             -- 대기중
        'SCHEDULED',           -- 예약됨
        'SENT',                -- 발송됨
        'DELIVERED',           -- 배달됨
        'FAILED',              -- 실패
        'CANCELLED'            -- 취소됨
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

-- 6. RLS 정책 활성화
ALTER TABLE bms.settlement_policies ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.settlement_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.refund_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.balance_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.settlement_notifications ENABLE ROW LEVEL SECURITY;

-- 7. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY settlement_policies_isolation_policy ON bms.settlement_policies
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY settlement_requests_isolation_policy ON bms.settlement_requests
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY refund_transactions_isolation_policy ON bms.refund_transactions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY balance_adjustments_isolation_policy ON bms.balance_adjustments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY settlement_notifications_isolation_policy ON bms.settlement_notifications
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 8. 성능 최적화 인덱스 생성
-- 정산 정책 인덱스
CREATE INDEX IF NOT EXISTS idx_settlement_policies_company_id ON bms.settlement_policies(company_id);
CREATE INDEX IF NOT EXISTS idx_settlement_policies_building_id ON bms.settlement_policies(building_id);
CREATE INDEX IF NOT EXISTS idx_settlement_policies_type ON bms.settlement_policies(policy_type);
CREATE INDEX IF NOT EXISTS idx_settlement_policies_active ON bms.settlement_policies(is_active);

-- 정산 요청 인덱스
CREATE INDEX IF NOT EXISTS idx_settlement_requests_company_id ON bms.settlement_requests(company_id);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_unit_id ON bms.settlement_requests(unit_id);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_policy_id ON bms.settlement_requests(policy_id);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_status ON bms.settlement_requests(request_status);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_type ON bms.settlement_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_period ON bms.settlement_requests(target_period_start, target_period_end);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_amount ON bms.settlement_requests(final_settlement_amount DESC);
CREATE INDEX IF NOT EXISTS idx_settlement_requests_requested_at ON bms.settlement_requests(requested_at DESC);

-- 환불 거래 인덱스
CREATE INDEX IF NOT EXISTS idx_refund_transactions_company_id ON bms.refund_transactions(company_id);
CREATE INDEX IF NOT EXISTS idx_refund_transactions_request_id ON bms.refund_transactions(request_id);
CREATE INDEX IF NOT EXISTS idx_refund_transactions_status ON bms.refund_transactions(transaction_status);
CREATE INDEX IF NOT EXISTS idx_refund_transactions_method ON bms.refund_transactions(refund_method);
CREATE INDEX IF NOT EXISTS idx_refund_transactions_scheduled_date ON bms.refund_transactions(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_refund_transactions_processed_date ON bms.refund_transactions(processed_date DESC);

-- 차액 조정 인덱스
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_company_id ON bms.balance_adjustments(company_id);
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_unit_id ON bms.balance_adjustments(unit_id);
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_request_id ON bms.balance_adjustments(request_id);
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_status ON bms.balance_adjustments(adjustment_status);
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_type ON bms.balance_adjustments(adjustment_type);
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_period ON bms.balance_adjustments(target_period_start, target_period_end);

-- 정산 알림 인덱스
CREATE INDEX IF NOT EXISTS idx_settlement_notifications_company_id ON bms.settlement_notifications(company_id);
CREATE INDEX IF NOT EXISTS idx_settlement_notifications_request_id ON bms.settlement_notifications(request_id);
CREATE INDEX IF NOT EXISTS idx_settlement_notifications_transaction_id ON bms.settlement_notifications(transaction_id);
CREATE INDEX IF NOT EXISTS idx_settlement_notifications_type ON bms.settlement_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_settlement_notifications_status ON bms.settlement_notifications(notification_status);
CREATE INDEX IF NOT EXISTS idx_settlement_notifications_sent_at ON bms.settlement_notifications(sent_at DESC);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_settlement_requests_company_status ON bms.settlement_requests(company_id, request_status);
CREATE INDEX IF NOT EXISTS idx_refund_transactions_company_status ON bms.refund_transactions(company_id, transaction_status);
CREATE INDEX IF NOT EXISTS idx_balance_adjustments_company_status ON bms.balance_adjustments(company_id, adjustment_status);

-- 9. updated_at 자동 업데이트 트리거
CREATE TRIGGER settlement_policies_updated_at_trigger
    BEFORE UPDATE ON bms.settlement_policies
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER settlement_requests_updated_at_trigger
    BEFORE UPDATE ON bms.settlement_requests
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER refund_transactions_updated_at_trigger
    BEFORE UPDATE ON bms.refund_transactions
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER balance_adjustments_updated_at_trigger
    BEFORE UPDATE ON bms.balance_adjustments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 스크립트 완료 메시지
SELECT '정산 및 환불 관리 시스템 테이블 생성이 완료되었습니다.' as message;