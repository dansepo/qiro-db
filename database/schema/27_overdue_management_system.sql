-- =====================================================
-- 연체 관리 시스템 테이블 생성 스크립트
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
    
    -- 연체료 계산 설정
    late_fee_calculation_method VARCHAR(20) NOT NULL,      -- 연체료 계산 방법
    daily_rate DECIMAL(8,4) DEFAULT 0.025,                 -- 일일 연체료율 (%)
    monthly_rate DECIMAL(8,4),                             -- 월별 연체료율 (%)
    annual_rate DECIMAL(8,4),                              -- 연간 연체료율 (%)
    
    -- 연체료 한도 설정
    max_late_fee_rate DECIMAL(8,4) DEFAULT 25.0,           -- 최대 연체료율 (%)
    max_late_fee_amount DECIMAL(15,2),                     -- 최대 연체료 금액
    min_late_fee_amount DECIMAL(15,2) DEFAULT 0,           -- 최소 연체료 금액
    
    -- 유예 기간 설정
    grace_period_days INTEGER DEFAULT 0,                   -- 유예 기간 (일)
    first_notice_days INTEGER DEFAULT 7,                   -- 1차 독촉 (일)
    second_notice_days INTEGER DEFAULT 15,                 -- 2차 독촉 (일)
    final_notice_days INTEGER DEFAULT 30,                  -- 최종 독촉 (일)
    legal_action_days INTEGER DEFAULT 60,                  -- 법적 조치 (일)
    
    -- 연체료 면제 설정
    exemption_enabled BOOLEAN DEFAULT false,               -- 면제 허용 여부
    exemption_conditions JSONB,                            -- 면제 조건
    auto_exemption_threshold DECIMAL(15,2),                -- 자동 면제 임계값
    
    -- 복리 계산 설정
    compound_interest BOOLEAN DEFAULT false,               -- 복리 적용 여부
    compound_frequency VARCHAR(20) DEFAULT 'MONTHLY',      -- 복리 계산 주기
    
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
    CONSTRAINT chk_calculation_method CHECK (late_fee_calculation_method IN (
        'DAILY_SIMPLE',        -- 일일 단리
        'DAILY_COMPOUND',      -- 일일 복리
        'MONTHLY_SIMPLE',      -- 월별 단리
        'MONTHLY_COMPOUND',    -- 월별 복리
        'ANNUAL_SIMPLE',       -- 연간 단리
        'ANNUAL_COMPOUND',     -- 연간 복리
        'FIXED_AMOUNT',        -- 고정 금액
        'TIERED'               -- 구간별 차등
    )),
    CONSTRAINT chk_compound_frequency CHECK (compound_frequency IN (
        'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUALLY'
    )),
    CONSTRAINT chk_rates CHECK (
        daily_rate >= 0 AND daily_rate <= 100 AND
        (monthly_rate IS NULL OR (monthly_rate >= 0 AND monthly_rate <= 100)) AND
        (annual_rate IS NULL OR (annual_rate >= 0 AND annual_rate <= 100)) AND
        max_late_fee_rate >= 0 AND max_late_fee_rate <= 100
    )),
    CONSTRAINT chk_amounts CHECK (
        (max_late_fee_amount IS NULL OR max_late_fee_amount >= 0) AND
        min_late_fee_amount >= 0 AND
        (auto_exemption_threshold IS NULL OR auto_exemption_threshold >= 0)
    )),
    CONSTRAINT chk_notice_days CHECK (
        grace_period_days >= 0 AND first_notice_days > 0 AND
        second_notice_days > first_notice_days AND
        final_notice_days > second_notice_days AND
        legal_action_days > final_notice_days
    )),
    CONSTRAINT chk_effective_dates CHECK (
        effective_end_date IS NULL OR effective_end_date >= effective_start_date
    )
);--
 2. 연체 현황 테이블
CREATE TABLE IF NOT EXISTS bms.overdue_accounts (
    overdue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    issuance_id UUID NOT NULL,
    policy_id UUID NOT NULL,
    
    -- 연체 기본 정보
    overdue_status VARCHAR(20) DEFAULT 'ACTIVE',           -- 연체 상태
    overdue_stage VARCHAR(20) DEFAULT 'GRACE',             -- 연체 단계
    
    -- 원금 정보
    principal_amount DECIMAL(15,2) NOT NULL,               -- 원금
    paid_amount DECIMAL(15,2) DEFAULT 0,                   -- 납부 금액
    remaining_amount DECIMAL(15,2) NOT NULL,               -- 잔여 금액
    
    -- 연체료 정보
    calculated_late_fee DECIMAL(15,2) DEFAULT 0,           -- 계산된 연체료
    applied_late_fee DECIMAL(15,2) DEFAULT 0,              -- 적용된 연체료
    exempted_late_fee DECIMAL(15,2) DEFAULT 0,             -- 면제된 연체료
    
    -- 연체 기간
    original_due_date DATE NOT NULL,                       -- 원래 납부 기한
    overdue_start_date DATE NOT NULL,                      -- 연체 시작일
    overdue_days INTEGER DEFAULT 0,                        -- 연체 일수
    
    -- 독촉 정보
    notice_count INTEGER DEFAULT 0,                        -- 독촉 횟수
    last_notice_date DATE,                                 -- 마지막 독촉일
    next_notice_date DATE,                                 -- 다음 독촉일
    
    -- 법적 조치 정보
    legal_action_initiated BOOLEAN DEFAULT false,          -- 법적 조치 개시 여부
    legal_action_date DATE,                                -- 법적 조치 일자
    legal_action_type VARCHAR(20),                         -- 법적 조치 유형
    legal_action_reference VARCHAR(100),                   -- 법적 조치 참조번호
    
    -- 해결 정보
    is_resolved BOOLEAN DEFAULT false,                     -- 해결 여부
    resolved_date DATE,                                    -- 해결일
    resolution_method VARCHAR(20),                         -- 해결 방법
    resolution_notes TEXT,                                 -- 해결 메모
    
    -- 담당자 정보
    assigned_to UUID,                                      -- 담당자
    assigned_at TIMESTAMP WITH TIME ZONE,                 -- 배정 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_overdue_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_issuance FOREIGN KEY (issuance_id) REFERENCES bms.bill_issuances(issuance_id) ON DELETE CASCADE,
    CONSTRAINT fk_overdue_policy FOREIGN KEY (policy_id) REFERENCES bms.overdue_policies(policy_id) ON DELETE RESTRICT,
    CONSTRAINT fk_overdue_assignee FOREIGN KEY (assigned_to) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_overdue_issuance UNIQUE (issuance_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_overdue_status CHECK (overdue_status IN (
        'ACTIVE',              -- 활성 연체
        'SUSPENDED',           -- 일시 중단
        'RESOLVED',            -- 해결됨
        'WRITTEN_OFF',         -- 손실 처리
        'LEGAL_ACTION'         -- 법적 조치중
    )),
    CONSTRAINT chk_overdue_stage CHECK (overdue_stage IN (
        'GRACE',               -- 유예 기간
        'FIRST_NOTICE',        -- 1차 독촉
        'SECOND_NOTICE',       -- 2차 독촉
        'FINAL_NOTICE',        -- 최종 독촉
        'LEGAL_ACTION',        -- 법적 조치
        'COLLECTION_AGENCY'    -- 추심 업체
    )),
    CONSTRAINT chk_legal_action_type CHECK (legal_action_type IN (
        'COURT_ORDER',         -- 법원 명령
        'GARNISHMENT',         -- 압류
        'LIEN',                -- 유치권
        'LAWSUIT',             -- 소송
        'COLLECTION_AGENCY'    -- 추심 업체
    )),
    CONSTRAINT chk_resolution_method CHECK (resolution_method IN (
        'FULL_PAYMENT',        -- 전액 납부
        'PARTIAL_PAYMENT',     -- 부분 납부
        'PAYMENT_PLAN',        -- 분할 납부
        'SETTLEMENT',          -- 합의
        'WRITE_OFF',           -- 손실 처리
        'LEGAL_RESOLUTION'     -- 법적 해결
    )),
    CONSTRAINT chk_amounts_overdue CHECK (
        principal_amount >= 0 AND paid_amount >= 0 AND
        remaining_amount >= 0 AND calculated_late_fee >= 0 AND
        applied_late_fee >= 0 AND exempted_late_fee >= 0 AND
        paid_amount <= principal_amount AND
        remaining_amount = principal_amount - paid_amount
    )),
    CONSTRAINT chk_overdue_days CHECK (overdue_days >= 0),
    CONSTRAINT chk_notice_count CHECK (notice_count >= 0)
);-
- 3. 독촉 이력 테이블
CREATE TABLE IF NOT EXISTS bms.notice_history (
    notice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    overdue_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 독촉 기본 정보
    notice_type VARCHAR(20) NOT NULL,                      -- 독촉 유형
    notice_method VARCHAR(20) NOT NULL,                    -- 독촉 방법
    notice_stage VARCHAR(20) NOT NULL,                     -- 독촉 단계
    
    -- 독촉 내용
    notice_title VARCHAR(200),                             -- 독촉 제목
    notice_content TEXT,                                   -- 독촉 내용
    template_id UUID,                                      -- 사용된 템플릿
    
    -- 발송 정보
    sent_date DATE NOT NULL,                               -- 발송일
    sent_method VARCHAR(20) NOT NULL,                      -- 발송 방법
    recipient_info JSONB,                                  -- 수신자 정보
    
    -- 응답 정보
    response_received BOOLEAN DEFAULT false,               -- 응답 수신 여부
    response_date DATE,                                    -- 응답일
    response_content TEXT,                                 -- 응답 내용
    response_type VARCHAR(20),                             -- 응답 유형
    
    -- 효과 측정
    payment_received BOOLEAN DEFAULT false,                -- 납부 여부
    payment_amount DECIMAL(15,2) DEFAULT 0,                -- 납부 금액
    payment_date DATE,                                     -- 납부일
    
    -- 비용 정보
    notice_cost DECIMAL(10,2) DEFAULT 0,                   -- 독촉 비용
    delivery_cost DECIMAL(10,2) DEFAULT 0,                 -- 배송 비용
    
    -- 법적 효력
    legal_validity BOOLEAN DEFAULT false,                  -- 법적 효력 여부
    legal_service_date DATE,                               -- 송달일
    legal_reference VARCHAR(100),                          -- 법적 참조번호
    
    -- 처리자 정보
    sent_by UUID,                                          -- 발송자
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_notice_overdue FOREIGN KEY (overdue_id) REFERENCES bms.overdue_accounts(overdue_id) ON DELETE CASCADE,
    CONSTRAINT fk_notice_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_notice_template FOREIGN KEY (template_id) REFERENCES bms.bill_templates(template_id) ON DELETE SET NULL,
    CONSTRAINT fk_notice_sender FOREIGN KEY (sent_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_notice_type CHECK (notice_type IN (
        'REMINDER',            -- 안내
        'FIRST_NOTICE',        -- 1차 독촉
        'SECOND_NOTICE',       -- 2차 독촉
        'FINAL_NOTICE',        -- 최종 독촉
        'LEGAL_NOTICE',        -- 법적 고지
        'COLLECTION_NOTICE'    -- 추심 고지
    )),
    CONSTRAINT chk_notice_method CHECK (notice_method IN (
        'EMAIL',               -- 이메일
        'SMS',                 -- SMS
        'KAKAO_TALK',          -- 카카오톡
        'POSTAL_MAIL',         -- 우편
        'REGISTERED_MAIL',     -- 등기우편
        'CERTIFIED_MAIL',      -- 내용증명
        'PHONE_CALL',          -- 전화
        'VISIT',               -- 방문
        'LEGAL_SERVICE'        -- 법적 송달
    )),
    CONSTRAINT chk_notice_stage CHECK (notice_stage IN (
        'GRACE', 'FIRST_NOTICE', 'SECOND_NOTICE', 'FINAL_NOTICE', 'LEGAL_ACTION'
    )),
    CONSTRAINT chk_sent_method CHECK (sent_method IN (
        'EMAIL', 'SMS', 'KAKAO_TALK', 'POSTAL_MAIL', 'REGISTERED_MAIL', 
        'CERTIFIED_MAIL', 'PHONE_CALL', 'VISIT', 'LEGAL_SERVICE'
    )),
    CONSTRAINT chk_response_type CHECK (response_type IN (
        'PAYMENT_PROMISE',     -- 납부 약속
        'DISPUTE',             -- 이의 제기
        'HARDSHIP',            -- 경제적 어려움
        'PAYMENT_PLAN_REQUEST', -- 분할 납부 요청
        'IGNORE',              -- 무시
        'LEGAL_CHALLENGE'      -- 법적 이의
    )),
    CONSTRAINT chk_costs CHECK (notice_cost >= 0 AND delivery_cost >= 0),
    CONSTRAINT chk_payment_amount CHECK (payment_amount >= 0)
);-
- 4. 분할 납부 계획 테이블
CREATE TABLE IF NOT EXISTS bms.payment_plans (
    plan_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    overdue_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 계획 기본 정보
    plan_name VARCHAR(100),                                -- 계획명
    plan_type VARCHAR(20) NOT NULL,                        -- 계획 유형
    plan_status VARCHAR(20) DEFAULT 'PROPOSED',            -- 계획 상태
    
    -- 금액 정보
    total_amount DECIMAL(15,2) NOT NULL,                   -- 총 금액
    down_payment DECIMAL(15,2) DEFAULT 0,                  -- 계약금
    installment_amount DECIMAL(15,2) NOT NULL,             -- 할부 금액
    installment_count INTEGER NOT NULL,                    -- 할부 횟수
    
    -- 일정 정보
    start_date DATE NOT NULL,                              -- 시작일
    payment_day INTEGER NOT NULL,                          -- 납부일 (매월)
    payment_interval VARCHAR(20) DEFAULT 'MONTHLY',        -- 납부 주기
    
    -- 이자 및 수수료
    interest_rate DECIMAL(8,4) DEFAULT 0,                  -- 이자율 (%)
    setup_fee DECIMAL(10,2) DEFAULT 0,                     -- 설정 수수료
    late_penalty_rate DECIMAL(8,4) DEFAULT 0,              -- 연체 가산금율 (%)
    
    -- 보증 정보
    guarantor_required BOOLEAN DEFAULT false,              -- 보증인 필요 여부
    guarantor_info JSONB,                                  -- 보증인 정보
    collateral_required BOOLEAN DEFAULT false,             -- 담보 필요 여부
    collateral_info JSONB,                                 -- 담보 정보
    
    -- 계약 정보
    contract_date DATE,                                    -- 계약일
    contract_document_path TEXT,                           -- 계약서 경로
    contract_terms JSONB,                                  -- 계약 조건
    
    -- 승인 정보
    proposed_by UUID,                                      -- 제안자
    proposed_at TIMESTAMP WITH TIME ZONE,                 -- 제안 일시
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 실행 정보
    payments_made INTEGER DEFAULT 0,                       -- 완료된 납부 횟수
    total_paid DECIMAL(15,2) DEFAULT 0,                    -- 총 납부 금액
    last_payment_date DATE,                                -- 마지막 납부일
    next_payment_date DATE,                                -- 다음 납부일
    
    -- 완료 정보
    is_completed BOOLEAN DEFAULT false,                    -- 완료 여부
    completed_date DATE,                                   -- 완료일
    completion_method VARCHAR(20),                         -- 완료 방법
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_plans_overdue FOREIGN KEY (overdue_id) REFERENCES bms.overdue_accounts(overdue_id) ON DELETE CASCADE,
    CONSTRAINT fk_plans_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_plans_proposer FOREIGN KEY (proposed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_plans_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_plan_type CHECK (plan_type IN (
        'STANDARD',            -- 표준 분할
        'EXTENDED',            -- 연장 분할
        'HARDSHIP',            -- 경제적 어려움
        'SETTLEMENT',          -- 합의 분할
        'COURT_ORDERED'        -- 법원 명령
    )),
    CONSTRAINT chk_plan_status CHECK (plan_status IN (
        'PROPOSED',            -- 제안됨
        'UNDER_REVIEW',        -- 검토중
        'APPROVED',            -- 승인됨
        'ACTIVE',              -- 활성
        'SUSPENDED',           -- 중단됨
        'COMPLETED',           -- 완료됨
        'CANCELLED',           -- 취소됨
        'DEFAULTED'            -- 불이행
    )),
    CONSTRAINT chk_payment_interval CHECK (payment_interval IN (
        'WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL'
    )),
    CONSTRAINT chk_completion_method CHECK (completion_method IN (
        'FULL_PAYMENT',        -- 전액 납부
        'EARLY_SETTLEMENT',    -- 조기 정산
        'FINAL_PAYMENT',       -- 최종 납부
        'WRITE_OFF'            -- 손실 처리
    )),
    CONSTRAINT chk_amounts_plan CHECK (
        total_amount > 0 AND down_payment >= 0 AND
        installment_amount > 0 AND installment_count > 0 AND
        down_payment <= total_amount AND
        interest_rate >= 0 AND setup_fee >= 0 AND
        late_penalty_rate >= 0 AND total_paid >= 0 AND
        payments_made >= 0 AND payments_made <= installment_count
    )),
    CONSTRAINT chk_payment_day CHECK (payment_day >= 1 AND payment_day <= 31),
    CONSTRAINT chk_dates_plan CHECK (
        (contract_date IS NULL OR contract_date >= start_date) AND
        (approved_at IS NULL OR proposed_at IS NULL OR approved_at >= proposed_at) AND
        (completed_date IS NULL OR completed_date >= start_date)
    )
); 
   o.overdue_id,
    o.company_id,
    bi.building_id,
    bi.unit_id,
    u.unit_number,
    u.unit_type,
    r.resident_name,
    
    -- 청구 정보
    bi.bill_year,
    bi.bill_month,
    bi.total_amount as original_amount,
    o.outstanding_amount,
    o.late_fee_amount,
    o.total_overdue_amount,
    
    -- 연체 정보
    o.overdue_status,
    o.overdue_stage,
    o.due_date,
    o.overdue_start_date,
    o.overdue_days,
    
    -- 정책 정보
    op.policy_name,
    op.daily_late_fee_rate,
    op.max_late_fee_rate,
    
    -- 알림 정보
    o.notification_count,
    o.last_notification_date,
    o.next_notification_date,
    
    -- 조치 정보
    o.warning_issued,
    o.legal_action_initiated,
    o.is_exempted,
    o.is_resolved,
    
    -- 계산된 필드
    CASE 
        WHEN o.overdue_days <= 30 THEN '1개월 이내'
        WHEN o.overdue_days <= 90 THEN '3개월 이내'
        WHEN o.overdue_days <= 180 THEN '6개월 이내'
        ELSE '6개월 초과'
    END as overdue_period_category,
    
    CASE 
        WHEN o.total_overdue_amount < 100000 THEN '10만원 미만'
        WHEN o.total_overdue_amount < 500000 THEN '50만원 미만'
        WHEN o.total_overdue_amount < 1000000 THEN '100만원 미만'
        ELSE '100만원 이상'
    END as amount_category,
    
    -- 우선순위 계산 (연체일수 * 금액 가중치)
    (o.overdue_days * 0.1 + o.total_overdue_amount / 10000) as priority_score
    
FROM bms.overdue_records o
JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
JOIN bms.units u ON bi.unit_id = u.unit_id
LEFT JOIN bms.residents r ON u.unit_id = r.unit_id AND r.is_primary = true AND r.is_active = true
JOIN bms.overdue_policies op ON o.policy_id = op.policy_id
WHERE o.overdue_status = 'ACTIVE';

-- 10. 연체료 계산 함수
CREATE OR REPLACE FUNCTION bms.calculate_late_fee(
    p_overdue_id UUID,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    late_fee_amount DECIMAL(15,2),
    calculation_details JSONB
) LANGUAGE plpgsql AS $$
DECLARE
    v_record RECORD;
    v_policy RECORD;
    v_days_overdue INTEGER;
    v_calculated_fee DECIMAL(15,2) := 0;
    v_details JSONB := '{}';
    v_daily_rate DECIMAL(8,4);
    v_base_amount DECIMAL(15,2);
BEGIN
    -- 연체 기록과 정책 정보 조회
    SELECT o.*, bi.total_amount
    INTO v_record
    FROM bms.overdue_records o
    JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
    WHERE o.overdue_id = p_overdue_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '연체 기록을 찾을 수 없습니다: %', p_overdue_id;
    END IF;
    
    -- 정책 정보 조회
    SELECT * INTO v_policy
    FROM bms.overdue_policies
    WHERE policy_id = v_record.policy_id;
    
    -- 연체 일수 계산
    v_days_overdue := p_calculation_date - v_record.overdue_start_date;
    
    -- 기준 금액 설정 (미납 금액 기준)
    v_base_amount := v_record.outstanding_amount;
    
    -- 연체료 계산 방법에 따른 처리
    CASE v_policy.late_fee_calculation_method
        WHEN 'DAILY_RATE' THEN
            -- 일일 요율 계산
            v_daily_rate := v_policy.daily_late_fee_rate / 100;
            v_calculated_fee := v_base_amount * v_daily_rate * v_days_overdue;
            
            v_details := jsonb_build_object(
                'method', 'DAILY_RATE',
                'base_amount', v_base_amount,
                'daily_rate', v_policy.daily_late_fee_rate,
                'days_overdue', v_days_overdue,
                'calculation', format('%s × %s%% × %s일', v_base_amount, v_policy.daily_late_fee_rate, v_days_overdue)
            );
            
        WHEN 'MONTHLY_RATE' THEN
            -- 월별 요율 계산
            v_calculated_fee := v_base_amount * (v_policy.monthly_late_fee_rate / 100) * (v_days_overdue / 30.0);
            
            v_details := jsonb_build_object(
                'method', 'MONTHLY_RATE',
                'base_amount', v_base_amount,
                'monthly_rate', v_policy.monthly_late_fee_rate,
                'days_overdue', v_days_overdue,
                'months_overdue', ROUND(v_days_overdue / 30.0, 2),
                'calculation', format('%s × %s%% × %s개월', v_base_amount, v_policy.monthly_late_fee_rate, ROUND(v_days_overdue / 30.0, 2))
            );
            
        WHEN 'FIXED_AMOUNT' THEN
            -- 고정 금액
            v_calculated_fee := COALESCE(v_policy.fixed_late_fee_amount, 0);
            
            v_details := jsonb_build_object(
                'method', 'FIXED_AMOUNT',
                'fixed_amount', v_policy.fixed_late_fee_amount,
                'calculation', format('고정 연체료: %s원', v_policy.fixed_late_fee_amount)
            );
            
        WHEN 'TIERED_RATE' THEN
            -- 단계별 요율 (JSON 설정 기반)
            -- 여기서는 기본 일일 요율 적용
            v_daily_rate := v_policy.daily_late_fee_rate / 100;
            v_calculated_fee := v_base_amount * v_daily_rate * v_days_overdue;
            
            v_details := jsonb_build_object(
                'method', 'TIERED_RATE',
                'base_amount', v_base_amount,
                'applied_rate', v_policy.daily_late_fee_rate,
                'days_overdue', v_days_overdue,
                'calculation', '단계별 요율 적용'
            );
            
        ELSE
            -- 기본값: 일일 요율
            v_daily_rate := COALESCE(v_policy.daily_late_fee_rate, 0.025) / 100;
            v_calculated_fee := v_base_amount * v_daily_rate * v_days_overdue;
            
            v_details := jsonb_build_object(
                'method', 'DEFAULT_DAILY',
                'base_amount', v_base_amount,
                'daily_rate', COALESCE(v_policy.daily_late_fee_rate, 0.025),
                'days_overdue', v_days_overdue,
                'calculation', '기본 일일 요율 적용'
            );
    END CASE;
    
    -- 최대/최소 연체료 제한 적용
    IF v_policy.max_late_fee_amount IS NOT NULL THEN
        v_calculated_fee := LEAST(v_calculated_fee, v_policy.max_late_fee_amount);
    END IF;
    
    IF v_policy.max_late_fee_rate IS NOT NULL THEN
        v_calculated_fee := LEAST(v_calculated_fee, v_base_amount * v_policy.max_late_fee_rate / 100);
    END IF;
    
    v_calculated_fee := GREATEST(v_calculated_fee, COALESCE(v_policy.min_late_fee_amount, 0));
    
    -- 상세 정보에 제한 적용 내역 추가
    v_details := v_details || jsonb_build_object(
        'max_late_fee_amount', v_policy.max_late_fee_amount,
        'max_late_fee_rate', v_policy.max_late_fee_rate,
        'min_late_fee_amount', v_policy.min_late_fee_amount,
        'final_amount', v_calculated_fee,
        'calculation_date', p_calculation_date
    );
    
    RETURN QUERY SELECT v_calculated_fee, v_details;
END;
$$;

-- 11. 연체 현황 업데이트 함수
CREATE OR REPLACE FUNCTION bms.update_overdue_status(
    p_company_id UUID DEFAULT NULL,
    p_calculation_date DATE DEFAULT CURRENT_DATE
) RETURNS TABLE (
    updated_count INTEGER,
    total_late_fee DECIMAL(15,2)
) LANGUAGE plpgsql AS $$
DECLARE
    v_record RECORD;
    v_late_fee_result RECORD;
    v_updated_count INTEGER := 0;
    v_total_late_fee DECIMAL(15,2) := 0;
    v_new_stage VARCHAR(20);
    v_policy RECORD;
BEGIN
    -- 활성 연체 기록들을 순회
    FOR v_record IN 
        SELECT o.*, op.overdue_threshold_days, op.legal_action_threshold_days
        FROM bms.overdue_records o
        JOIN bms.overdue_policies op ON o.policy_id = op.policy_id
        WHERE o.overdue_status = 'ACTIVE'
        AND (p_company_id IS NULL OR o.company_id = p_company_id)
    LOOP
        -- 연체 일수 업데이트
        UPDATE bms.overdue_records 
        SET overdue_days = p_calculation_date - overdue_start_date
        WHERE overdue_id = v_record.overdue_id;
        
        -- 연체료 계산
        SELECT * INTO v_late_fee_result
        FROM bms.calculate_late_fee(v_record.overdue_id, p_calculation_date);
        
        -- 연체 단계 결정
        v_new_stage := CASE 
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 7 THEN 'INITIAL'
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 30 THEN 'WARNING'
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 60 THEN 'DEMAND'
            WHEN (p_calculation_date - v_record.overdue_start_date) <= 90 THEN 'FINAL_NOTICE'
            WHEN v_record.legal_action_threshold_days IS NOT NULL 
                 AND (p_calculation_date - v_record.overdue_start_date) >= v_record.legal_action_threshold_days 
                 THEN 'LEGAL_ACTION'
            ELSE 'LEGAL_PREPARATION'
        END;
        
        -- 연체 기록 업데이트
        UPDATE bms.overdue_records 
        SET 
            overdue_days = p_calculation_date - overdue_start_date,
            overdue_stage = v_new_stage,
            late_fee_amount = v_late_fee_result.late_fee_amount,
            total_overdue_amount = outstanding_amount + v_late_fee_result.late_fee_amount,
            late_fee_calculation_date = p_calculation_date,
            late_fee_calculation_details = v_late_fee_result.calculation_details,
            updated_at = NOW()
        WHERE overdue_id = v_record.overdue_id;
        
        v_updated_count := v_updated_count + 1;
        v_total_late_fee := v_total_late_fee + v_late_fee_result.late_fee_amount;
    END LOOP;
    
    RETURN QUERY SELECT v_updated_count, v_total_late_fee;
END;
$$;

-- 12. 연체 알림 생성 함수
CREATE OR REPLACE FUNCTION bms.create_overdue_notification(
    p_overdue_id UUID,
    p_notification_type VARCHAR(20),
    p_notification_method VARCHAR(20),
    p_scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_notification_id UUID;
    v_overdue_record RECORD;
    v_unit_info RECORD;
    v_resident_info RECORD;
    v_title VARCHAR(200);
    v_content TEXT;
BEGIN
    -- 연체 기록 정보 조회
    SELECT o.*, bi.bill_year, bi.bill_month, bi.total_amount
    INTO v_overdue_record
    FROM bms.overdue_records o
    JOIN bms.bill_issuances bi ON o.issuance_id = bi.issuance_id
    WHERE o.overdue_id = p_overdue_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '연체 기록을 찾을 수 없습니다: %', p_overdue_id;
    END IF;
    
    -- 세대 및 입주자 정보 조회
    SELECT u.unit_number, u.unit_type, b.building_name
    INTO v_unit_info
    FROM bms.bill_issuances bi
    JOIN bms.units u ON bi.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE bi.issuance_id = v_overdue_record.issuance_id;
    
    SELECT resident_name, phone_number, email, address
    INTO v_resident_info
    FROM bms.residents r
    JOIN bms.bill_issuances bi ON r.unit_id = bi.unit_id
    WHERE bi.issuance_id = v_overdue_record.issuance_id
    AND r.is_primary = true AND r.is_active = true;
    
    -- 알림 제목 및 내용 생성
    v_title := CASE p_notification_type
        WHEN 'REMINDER' THEN format('[%s] 관리비 납부 안내', v_unit_info.building_name)
        WHEN 'WARNING' THEN format('[%s] 관리비 연체 경고', v_unit_info.building_name)
        WHEN 'DEMAND' THEN format('[%s] 관리비 납부 독촉', v_unit_info.building_name)
        WHEN 'FINAL_NOTICE' THEN format('[%s] 관리비 최종 납부 통지', v_unit_info.building_name)
        WHEN 'LEGAL_NOTICE' THEN format('[%s] 법적 조치 예고 통지', v_unit_info.building_name)
        ELSE format('[%s] 관리비 관련 안내', v_unit_info.building_name)
    END;
    
    v_content := format(
        E'안녕하세요. %s입니다.\n\n' ||
        E'%s호 %s년 %s월 관리비가 연체되었습니다.\n\n' ||
        E'연체 정보:\n' ||
        E'- 원금: %s원\n' ||
        E'- 연체료: %s원\n' ||
        E'- 총 연체금액: %s원\n' ||
        E'- 연체일수: %s일\n\n' ||
        E'빠른 시일 내에 납부해 주시기 바랍니다.',
        v_unit_info.building_name,
        v_unit_info.unit_number,
        v_overdue_record.bill_year,
        v_overdue_record.bill_month,
        v_overdue_record.outstanding_amount,
        v_overdue_record.late_fee_amount,
        v_overdue_record.total_overdue_amount,
        v_overdue_record.overdue_days
    );
    
    -- 알림 기록 생성
    INSERT INTO bms.overdue_notifications (
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
        scheduled_at
    ) VALUES (
        p_overdue_id,
        v_overdue_record.company_id,
        p_notification_type,
        v_overdue_record.overdue_stage,
        p_notification_method,
        v_title,
        v_content,
        v_resident_info.resident_name,
        CASE p_notification_method
            WHEN 'EMAIL' THEN v_resident_info.email
            WHEN 'SMS' THEN v_resident_info.phone_number
            WHEN 'KAKAO_TALK' THEN v_resident_info.phone_number
            ELSE v_resident_info.address
        END,
        v_resident_info.address,
        p_scheduled_at
    ) RETURNING notification_id INTO v_notification_id;
    
    -- 연체 기록의 알림 정보 업데이트
    UPDATE bms.overdue_records 
    SET 
        notification_count = notification_count + 1,
        last_notification_date = CURRENT_DATE,
        next_notification_date = CURRENT_DATE + INTERVAL '7 days'
    WHERE overdue_id = p_overdue_id;
    
    RETURN v_notification_id;
END;
$$;

-- 13. 연체 통계 뷰
CREATE OR REPLACE VIEW bms.v_overdue_statistics AS
SELECT 
    company_id,
    
    -- 전체 통계
    COUNT(*) as total_overdue_count,
    SUM(total_overdue_amount) as total_overdue_amount,
    AVG(overdue_days) as avg_overdue_days,
    
    -- 상태별 통계
    COUNT(*) FILTER (WHERE overdue_status = 'ACTIVE') as active_count,
    COUNT(*) FILTER (WHERE overdue_status = 'RESOLVED') as resolved_count,
    COUNT(*) FILTER (WHERE overdue_status = 'EXEMPTED') as exempted_count,
    
    -- 단계별 통계
    COUNT(*) FILTER (WHERE overdue_stage = 'INITIAL') as initial_stage_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'WARNING') as warning_stage_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'DEMAND') as demand_stage_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'FINAL_NOTICE') as final_notice_count,
    COUNT(*) FILTER (WHERE overdue_stage = 'LEGAL_ACTION') as legal_action_count,
    
    -- 금액별 통계
    COUNT(*) FILTER (WHERE total_overdue_amount < 100000) as under_100k_count,
    COUNT(*) FILTER (WHERE total_overdue_amount BETWEEN 100000 AND 499999) as between_100k_500k_count,
    COUNT(*) FILTER (WHERE total_overdue_amount BETWEEN 500000 AND 999999) as between_500k_1m_count,
    COUNT(*) FILTER (WHERE total_overdue_amount >= 1000000) as over_1m_count,
    
    -- 기간별 통계
    COUNT(*) FILTER (WHERE overdue_days <= 30) as within_30days_count,
    COUNT(*) FILTER (WHERE overdue_days BETWEEN 31 AND 90) as between_31_90days_count,
    COUNT(*) FILTER (WHERE overdue_days BETWEEN 91 AND 180) as between_91_180days_count,
    COUNT(*) FILTER (WHERE overdue_days > 180) as over_180days_count,
    
    -- 금액 통계
    SUM(outstanding_amount) as total_outstanding_amount,
    SUM(late_fee_amount) as total_late_fee_amount,
    
    -- 최신 업데이트 시간
    MAX(updated_at) as last_updated_at
    
FROM bms.overdue_records
GROUP BY company_id;

-- 14. 코멘트 추가
COMMENT ON TABLE bms.overdue_policies IS '연체 정책 설정 테이블 - 회사별/건물별 연체 관리 정책을 정의';
COMMENT ON TABLE bms.overdue_records IS '연체 현황 테이블 - 개별 청구서의 연체 상태와 연체료를 관리';
COMMENT ON TABLE bms.overdue_notifications IS '연체 알림 이력 테이블 - 연체자에게 발송된 알림 내역을 기록';
COMMENT ON TABLE bms.overdue_actions IS '연체 조치 이력 테이블 - 연체에 대한 각종 조치 활동을 기록';

COMMENT ON COLUMN bms.overdue_policies.late_fee_calculation_method IS '연체료 계산 방법: DAILY_RATE(일일요율), MONTHLY_RATE(월별요율), FIXED_AMOUNT(고정금액), TIERED_RATE(단계별요율), COMPOUND_RATE(복리요율)';
COMMENT ON COLUMN bms.overdue_policies.stage_configurations IS '단계별 설정 JSON: 각 연체 단계별 세부 설정 정보';
COMMENT ON COLUMN bms.overdue_policies.exemption_conditions IS '면제 조건 JSON: 연체료 면제 조건 및 기준';

COMMENT ON COLUMN bms.overdue_records.overdue_stage IS '연체 단계: INITIAL(초기), WARNING(경고), DEMAND(독촉), FINAL_NOTICE(최종통지), LEGAL_PREPARATION(법적조치준비), LEGAL_ACTION(법적조치)';
COMMENT ON COLUMN bms.overdue_records.late_fee_calculation_details IS '연체료 계산 상세 JSON: 연체료 계산 과정과 적용된 요율 정보';

COMMENT ON FUNCTION bms.calculate_late_fee(UUID, DATE) IS '연체료 계산 함수 - 연체 정책에 따라 연체료를 계산하고 상세 내역을 반환';
COMMENT ON FUNCTION bms.update_overdue_status(UUID, DATE) IS '연체 현황 업데이트 함수 - 연체 일수, 단계, 연체료를 일괄 업데이트';
COMMENT ON FUNCTION bms.create_overdue_notification(UUID, VARCHAR, VARCHAR, TIMESTAMP WITH TIME ZONE) IS '연체 알림 생성 함수 - 연체자에게 발송할 알림을 생성';

COMMENT ON VIEW bms.v_overdue_dashboard IS '연체 관리 대시보드 뷰 - 연체 현황을 종합적으로 조회';
COMMENT ON VIEW bms.v_overdue_statistics IS '연체 통계 뷰 - 회사별 연체 현황 통계 정보';

-- 스크립트 완료 메시지
SELECT '연체 관리 시스템 테이블 및 함수 생성이 완료되었습니다.' as message;