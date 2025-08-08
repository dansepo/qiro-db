-- =====================================================
-- 수납 관리 시스템 테이블 생성 스크립트
-- Phase 5.1: 수납 관리 테이블
-- =====================================================

-- 1. 결제 방법 설정 테이블
CREATE TABLE IF NOT EXISTS bms.payment_methods (
    method_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체
    
    -- 결제 방법 기본 정보
    method_name VARCHAR(100) NOT NULL,                     -- 결제 방법명
    method_type VARCHAR(20) NOT NULL,                      -- 결제 방법 유형
    method_description TEXT,                               -- 결제 방법 설명
    
    -- 결제 서비스 제공업체 정보
    provider_name VARCHAR(100),                            -- 서비스 제공업체
    provider_code VARCHAR(50),                             -- 제공업체 코드
    api_endpoint TEXT,                                     -- API 엔드포인트
    api_credentials JSONB,                                 -- API 인증 정보 (암호화)
    
    -- 결제 설정
    min_amount DECIMAL(15,2) DEFAULT 0,                    -- 최소 결제 금액
    max_amount DECIMAL(15,2),                              -- 최대 결제 금액
    fee_rate DECIMAL(8,4) DEFAULT 0,                       -- 수수료율 (%)
    fixed_fee DECIMAL(10,2) DEFAULT 0,                     -- 고정 수수료
    
    -- 처리 설정
    auto_confirmation BOOLEAN DEFAULT false,               -- 자동 승인 여부
    confirmation_delay_minutes INTEGER DEFAULT 0,          -- 승인 지연 시간 (분)
    refund_supported BOOLEAN DEFAULT true,                 -- 환불 지원 여부
    partial_refund_supported BOOLEAN DEFAULT true,         -- 부분 환불 지원 여부
    
    -- 계좌 정보 (계좌이체용)
    bank_code VARCHAR(10),                                 -- 은행 코드
    bank_name VARCHAR(50),                                 -- 은행명
    account_number VARCHAR(50),                            -- 계좌번호
    account_holder VARCHAR(100),                           -- 예금주
    
    -- 가상계좌 설정
    virtual_account_enabled BOOLEAN DEFAULT false,         -- 가상계좌 사용 여부
    virtual_account_bank_codes TEXT[],                     -- 지원 은행 코드
    virtual_account_expire_hours INTEGER DEFAULT 72,       -- 가상계좌 만료 시간
    
    -- 상태 및 제한
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    daily_limit DECIMAL(15,2),                             -- 일일 한도
    monthly_limit DECIMAL(15,2),                           -- 월간 한도
    
    -- 통계
    total_transactions INTEGER DEFAULT 0,                  -- 총 거래 수
    total_amount DECIMAL(15,2) DEFAULT 0,                  -- 총 거래 금액
    success_rate DECIMAL(5,2) DEFAULT 0,                   -- 성공률
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_methods_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_methods_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_methods_name UNIQUE (company_id, building_id, method_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_method_type CHECK (method_type IN (
        'BANK_TRANSFER',       -- 계좌이체
        'VIRTUAL_ACCOUNT',     -- 가상계좌
        'CREDIT_CARD',         -- 신용카드
        'DEBIT_CARD',          -- 체크카드
        'MOBILE_PAYMENT',      -- 모바일 결제
        'CRYPTOCURRENCY',      -- 암호화폐
        'CASH',                -- 현금
        'CHECK',               -- 수표
        'MONEY_ORDER',         -- 우편환
        'WIRE_TRANSFER',       -- 전신환
        'AUTO_DEBIT',          -- 자동이체
        'ESCROW'               -- 에스크로
    )),
    CONSTRAINT chk_amounts CHECK (
        min_amount >= 0 AND 
        (max_amount IS NULL OR max_amount >= min_amount) AND
        fee_rate >= 0 AND fee_rate <= 100 AND
        fixed_fee >= 0
    ),
    CONSTRAINT chk_limits CHECK (
        (daily_limit IS NULL OR daily_limit > 0) AND
        (monthly_limit IS NULL OR monthly_limit > 0)
    ),
    CONSTRAINT chk_statistics CHECK (
        total_transactions >= 0 AND total_amount >= 0 AND
        success_rate >= 0 AND success_rate <= 100
    ),
    CONSTRAINT chk_confirmation_delay CHECK (confirmation_delay_minutes >= 0),
    CONSTRAINT chk_virtual_account_expire CHECK (virtual_account_expire_hours > 0)
);

-- 2. 수납 거래 테이블
CREATE TABLE IF NOT EXISTS bms.payment_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    issuance_id UUID NOT NULL,
    method_id UUID NOT NULL,
    
    -- 거래 기본 정보
    transaction_number VARCHAR(100) NOT NULL,              -- 거래 번호
    external_transaction_id VARCHAR(100),                  -- 외부 거래 ID
    payment_reference VARCHAR(100),                        -- 결제 참조번호
    
    -- 금액 정보
    bill_amount DECIMAL(15,2) NOT NULL,                    -- 청구 금액
    paid_amount DECIMAL(15,2) NOT NULL,                    -- 납부 금액
    fee_amount DECIMAL(15,2) DEFAULT 0,                    -- 수수료
    discount_amount DECIMAL(15,2) DEFAULT 0,               -- 할인 금액
    late_fee_amount DECIMAL(15,2) DEFAULT 0,               -- 연체료
    net_amount DECIMAL(15,2) NOT NULL,                     -- 실수령 금액
    
    -- 거래 상태
    transaction_status VARCHAR(20) DEFAULT 'PENDING',      -- 거래 상태
    payment_status VARCHAR(20) DEFAULT 'UNPAID',           -- 결제 상태
    
    -- 거래 일시
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 거래 일시
    payment_date TIMESTAMP WITH TIME ZONE,                 -- 결제 일시
    confirmation_date TIMESTAMP WITH TIME ZONE,            -- 승인 일시
    settlement_date TIMESTAMP WITH TIME ZONE,              -- 정산 일시
    
    -- 결제자 정보
    payer_name VARCHAR(100),                               -- 결제자명
    payer_phone VARCHAR(20),                               -- 결제자 전화번호
    payer_email VARCHAR(255),                              -- 결제자 이메일
    payer_account_info JSONB,                              -- 결제자 계좌 정보
    
    -- 가상계좌 정보
    virtual_account_number VARCHAR(50),                    -- 가상계좌 번호
    virtual_account_bank VARCHAR(50),                      -- 가상계좌 은행
    virtual_account_expire_at TIMESTAMP WITH TIME ZONE,    -- 가상계좌 만료일시
    
    -- 카드 정보 (마스킹)
    card_number_masked VARCHAR(20),                        -- 마스킹된 카드번호
    card_type VARCHAR(20),                                 -- 카드 유형
    card_company VARCHAR(50),                              -- 카드사
    installment_months INTEGER DEFAULT 0,                  -- 할부 개월수
    
    -- 처리 결과
    response_code VARCHAR(20),                             -- 응답 코드
    response_message TEXT,                                 -- 응답 메시지
    gateway_response JSONB,                                -- 게이트웨이 응답 (JSON)
    
    -- 취소/환불 정보
    is_cancelled BOOLEAN DEFAULT false,                    -- 취소 여부
    cancelled_at TIMESTAMP WITH TIME ZONE,                -- 취소 일시
    cancelled_by UUID,                                     -- 취소자
    cancel_reason TEXT,                                    -- 취소 사유
    refund_amount DECIMAL(15,2) DEFAULT 0,                 -- 환불 금액
    
    -- 정산 정보
    is_settled BOOLEAN DEFAULT false,                      -- 정산 완료 여부
    settlement_amount DECIMAL(15,2),                       -- 정산 금액
    settlement_reference VARCHAR(100),                     -- 정산 참조번호
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_transactions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_issuance FOREIGN KEY (issuance_id) REFERENCES bms.bill_issuances(issuance_id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_method FOREIGN KEY (method_id) REFERENCES bms.payment_methods(method_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transactions_canceller FOREIGN KEY (cancelled_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_transactions_number UNIQUE (company_id, transaction_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_transaction_status CHECK (transaction_status IN (
        'PENDING',             -- 대기중
        'PROCESSING',          -- 처리중
        'COMPLETED',           -- 완료
        'FAILED',              -- 실패
        'CANCELLED',           -- 취소
        'REFUNDED',            -- 환불
        'EXPIRED'              -- 만료
    )),
    CONSTRAINT chk_payment_status CHECK (payment_status IN (
        'UNPAID',              -- 미납
        'PARTIAL',             -- 부분납부
        'PAID',                -- 완납
        'OVERPAID',            -- 과납
        'REFUNDED',            -- 환불
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_card_type CHECK (card_type IN (
        'CREDIT',              -- 신용카드
        'DEBIT',               -- 체크카드
        'PREPAID',             -- 선불카드
        'GIFT'                 -- 상품권
    )),
    CONSTRAINT chk_amounts_transaction CHECK (
        bill_amount >= 0 AND paid_amount >= 0 AND
        fee_amount >= 0 AND discount_amount >= 0 AND
        late_fee_amount >= 0 AND net_amount >= 0 AND
        refund_amount >= 0 AND refund_amount <= paid_amount
    ),
    CONSTRAINT chk_installment_months CHECK (installment_months >= 0 AND installment_months <= 60),
    CONSTRAINT chk_dates_order CHECK (
        (payment_date IS NULL OR payment_date >= transaction_date) AND
        (confirmation_date IS NULL OR payment_date IS NULL OR confirmation_date >= payment_date) AND
        (settlement_date IS NULL OR confirmation_date IS NULL OR settlement_date >= confirmation_date) AND
        (cancelled_at IS NULL OR cancelled_at >= transaction_date)
    )
);

-- 3. 자동이체 설정 테이블
CREATE TABLE IF NOT EXISTS bms.auto_debit_settings (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    method_id UUID NOT NULL,
    
    -- 자동이체 기본 정보
    setting_name VARCHAR(100),                             -- 설정명
    debit_type VARCHAR(20) NOT NULL,                       -- 이체 유형
    
    -- 계좌 정보
    bank_code VARCHAR(10) NOT NULL,                        -- 은행 코드
    bank_name VARCHAR(50) NOT NULL,                        -- 은행명
    account_number VARCHAR(50) NOT NULL,                   -- 계좌번호
    account_holder VARCHAR(100) NOT NULL,                  -- 예금주
    
    -- 이체 설정
    debit_day INTEGER NOT NULL,                            -- 이체일 (1-31)
    debit_amount_type VARCHAR(20) DEFAULT 'FULL',          -- 이체 금액 유형
    fixed_amount DECIMAL(15,2),                            -- 고정 이체 금액
    max_amount DECIMAL(15,2),                              -- 최대 이체 금액
    
    -- 실패 처리
    retry_count INTEGER DEFAULT 3,                         -- 재시도 횟수
    retry_interval_days INTEGER DEFAULT 3,                 -- 재시도 간격 (일)
    failure_notification BOOLEAN DEFAULT true,             -- 실패 알림 여부
    
    -- 상태 및 기간
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    start_date DATE DEFAULT CURRENT_DATE,                  -- 시작일
    end_date DATE,                                         -- 종료일
    
    -- 승인 정보
    agreement_date DATE,                                   -- 동의일
    agreement_method VARCHAR(20),                          -- 동의 방법
    agreement_ip VARCHAR(45),                              -- 동의 IP
    agreement_document_path TEXT,                          -- 동의서 경로
    
    -- 통계
    total_attempts INTEGER DEFAULT 0,                      -- 총 시도 횟수
    successful_debits INTEGER DEFAULT 0,                   -- 성공한 이체 수
    failed_debits INTEGER DEFAULT 0,                       -- 실패한 이체 수
    last_debit_date DATE,                                  -- 마지막 이체일
    next_debit_date DATE,                                  -- 다음 이체일
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_auto_debit_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_auto_debit_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_auto_debit_method FOREIGN KEY (method_id) REFERENCES bms.payment_methods(method_id) ON DELETE RESTRICT,
    CONSTRAINT uk_auto_debit_unit UNIQUE (unit_id, bank_code, account_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_debit_type CHECK (debit_type IN (
        'CMS',                 -- 자동이체 (CMS)
        'DIRECT_DEBIT',        -- 직불이체
        'STANDING_ORDER'       -- 자동송금
    )),
    CONSTRAINT chk_debit_amount_type CHECK (debit_amount_type IN (
        'FULL',                -- 전액
        'FIXED',               -- 고정금액
        'PARTIAL'              -- 부분금액
    )),
    CONSTRAINT chk_agreement_method CHECK (agreement_method IN (
        'ONLINE',              -- 온라인
        'OFFLINE',             -- 오프라인
        'PHONE',               -- 전화
        'MOBILE_APP',          -- 모바일 앱
        'DOCUMENT'             -- 서면
    )),
    CONSTRAINT chk_debit_day CHECK (debit_day >= 1 AND debit_day <= 31),
    CONSTRAINT chk_retry_settings CHECK (
        retry_count >= 0 AND retry_count <= 10 AND
        retry_interval_days > 0 AND retry_interval_days <= 30
    ),
    CONSTRAINT chk_amounts_auto_debit CHECK (
        (fixed_amount IS NULL OR fixed_amount > 0) AND
        (max_amount IS NULL OR max_amount > 0)
    ),
    CONSTRAINT chk_dates_auto_debit CHECK (
        end_date IS NULL OR end_date >= start_date
    ),
    CONSTRAINT chk_statistics_auto_debit CHECK (
        total_attempts >= 0 AND successful_debits >= 0 AND
        failed_debits >= 0 AND successful_debits + failed_debits <= total_attempts
    )
);

-- 4. 수납 대사 테이블
CREATE TABLE IF NOT EXISTS bms.payment_reconciliation (
    reconciliation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 대사 기본 정보
    reconciliation_date DATE NOT NULL,                     -- 대사 기준일
    reconciliation_type VARCHAR(20) NOT NULL,              -- 대사 유형
    reconciliation_status VARCHAR(20) DEFAULT 'PENDING',   -- 대사 상태
    
    -- 대사 범위
    method_id UUID,                                        -- 결제 방법 (NULL이면 전체)
    start_date DATE NOT NULL,                              -- 시작일
    end_date DATE NOT NULL,                                -- 종료일
    
    -- 대사 결과
    total_transactions INTEGER DEFAULT 0,                  -- 총 거래 수
    matched_transactions INTEGER DEFAULT 0,                -- 일치 거래 수
    unmatched_transactions INTEGER DEFAULT 0,              -- 불일치 거래 수
    
    -- 금액 대사
    system_total_amount DECIMAL(15,2) DEFAULT 0,           -- 시스템 총액
    bank_total_amount DECIMAL(15,2) DEFAULT 0,             -- 은행 총액
    difference_amount DECIMAL(15,2) DEFAULT 0,             -- 차액
    
    -- 대사 파일 정보
    bank_statement_file_path TEXT,                         -- 은행 내역서 파일 경로
    bank_statement_file_name VARCHAR(255),                 -- 은행 내역서 파일명
    reconciliation_report_path TEXT,                       -- 대사 보고서 경로
    
    -- 처리 정보
    processed_by UUID,                                     -- 처리자
    processed_at TIMESTAMP WITH TIME ZONE,                -- 처리 일시
    processing_notes TEXT,                                 -- 처리 메모
    
    -- 승인 정보
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_reconciliation_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_reconciliation_method FOREIGN KEY (method_id) REFERENCES bms.payment_methods(method_id) ON DELETE SET NULL,
    CONSTRAINT fk_reconciliation_processor FOREIGN KEY (processed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_reconciliation_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_reconciliation_date UNIQUE (company_id, reconciliation_date, reconciliation_type, method_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_reconciliation_type CHECK (reconciliation_type IN (
        'DAILY',               -- 일별 대사
        'WEEKLY',              -- 주별 대사
        'MONTHLY',             -- 월별 대사
        'MANUAL'               -- 수동 대사
    )),
    CONSTRAINT chk_reconciliation_status CHECK (reconciliation_status IN (
        'PENDING',             -- 대기중
        'PROCESSING',          -- 처리중
        'COMPLETED',           -- 완료
        'FAILED',              -- 실패
        'APPROVED'             -- 승인완료
    )),
    CONSTRAINT chk_date_range CHECK (end_date >= start_date),
    CONSTRAINT chk_transaction_counts CHECK (
        total_transactions >= 0 AND matched_transactions >= 0 AND
        unmatched_transactions >= 0 AND 
        matched_transactions + unmatched_transactions <= total_transactions
    ),
    CONSTRAINT chk_amounts_reconciliation CHECK (
        system_total_amount >= 0 AND bank_total_amount >= 0
    )
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.auto_debit_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.payment_reconciliation ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY payment_methods_isolation_policy ON bms.payment_methods
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY payment_transactions_isolation_policy ON bms.payment_transactions
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY auto_debit_settings_isolation_policy ON bms.auto_debit_settings
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY payment_reconciliation_isolation_policy ON bms.payment_reconciliation
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 결제 방법 인덱스
CREATE INDEX idx_methods_company_id ON bms.payment_methods(company_id);
CREATE INDEX idx_methods_building_id ON bms.payment_methods(building_id);
CREATE INDEX idx_methods_type ON bms.payment_methods(method_type);
CREATE INDEX idx_methods_active ON bms.payment_methods(is_active);
CREATE INDEX idx_methods_provider ON bms.payment_methods(provider_name);

-- 수납 거래 인덱스
CREATE INDEX idx_transactions_company_id ON bms.payment_transactions(company_id);
CREATE INDEX idx_transactions_issuance_id ON bms.payment_transactions(issuance_id);
CREATE INDEX idx_transactions_method_id ON bms.payment_transactions(method_id);
CREATE INDEX idx_transactions_number ON bms.payment_transactions(transaction_number);
CREATE INDEX idx_transactions_status ON bms.payment_transactions(transaction_status);
CREATE INDEX idx_transactions_payment_status ON bms.payment_transactions(payment_status);
CREATE INDEX idx_transactions_date ON bms.payment_transactions(transaction_date DESC);
CREATE INDEX idx_transactions_payment_date ON bms.payment_transactions(payment_date DESC);
CREATE INDEX idx_transactions_payer_name ON bms.payment_transactions(payer_name);
CREATE INDEX idx_transactions_external_id ON bms.payment_transactions(external_transaction_id);

-- 자동이체 설정 인덱스
CREATE INDEX idx_auto_debit_company_id ON bms.auto_debit_settings(company_id);
CREATE INDEX idx_auto_debit_unit_id ON bms.auto_debit_settings(unit_id);
CREATE INDEX idx_auto_debit_method_id ON bms.auto_debit_settings(method_id);
CREATE INDEX idx_auto_debit_active ON bms.auto_debit_settings(is_active);
CREATE INDEX idx_auto_debit_day ON bms.auto_debit_settings(debit_day);
CREATE INDEX idx_auto_debit_next_date ON bms.auto_debit_settings(next_debit_date);
CREATE INDEX idx_auto_debit_account ON bms.auto_debit_settings(bank_code, account_number);

-- 수납 대사 인덱스
CREATE INDEX idx_reconciliation_company_id ON bms.payment_reconciliation(company_id);
CREATE INDEX idx_reconciliation_date ON bms.payment_reconciliation(reconciliation_date DESC);
CREATE INDEX idx_reconciliation_type ON bms.payment_reconciliation(reconciliation_type);
CREATE INDEX idx_reconciliation_status ON bms.payment_reconciliation(reconciliation_status);
CREATE INDEX idx_reconciliation_method_id ON bms.payment_reconciliation(method_id);
CREATE INDEX idx_reconciliation_period ON bms.payment_reconciliation(start_date, end_date);

-- 복합 인덱스
CREATE INDEX idx_methods_company_type_active ON bms.payment_methods(company_id, method_type, is_active);
CREATE INDEX idx_transactions_company_date ON bms.payment_transactions(company_id, transaction_date DESC);
CREATE INDEX idx_transactions_status_date ON bms.payment_transactions(transaction_status, transaction_date DESC);
CREATE INDEX idx_auto_debit_unit_active ON bms.auto_debit_settings(unit_id, is_active);
CREATE INDEX idx_reconciliation_company_date ON bms.payment_reconciliation(company_id, reconciliation_date DESC);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER payment_methods_updated_at_trigger
    BEFORE UPDATE ON bms.payment_methods
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER payment_transactions_updated_at_trigger
    BEFORE UPDATE ON bms.payment_transactions
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER auto_debit_settings_updated_at_trigger
    BEFORE UPDATE ON bms.auto_debit_settings
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER payment_reconciliation_updated_at_trigger
    BEFORE UPDATE ON bms.payment_reconciliation
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 수납 관리 뷰 생성
CREATE OR REPLACE VIEW bms.v_payment_summary AS
SELECT 
    pm.method_id,
    pm.company_id,
    c.company_name,
    pm.method_name,
    pm.method_type,
    pm.is_active,
    pm.total_transactions,
    pm.total_amount,
    pm.success_rate,
    COUNT(pt.transaction_id) as recent_transactions,
    COUNT(CASE WHEN pt.payment_status = 'PAID' THEN 1 END) as paid_transactions,
    COUNT(CASE WHEN pt.payment_status = 'FAILED' THEN 1 END) as failed_transactions,
    SUM(pt.paid_amount) as recent_total_amount,
    AVG(pt.paid_amount) as avg_transaction_amount,
    pm.created_at
FROM bms.payment_methods pm
JOIN bms.companies c ON pm.company_id = c.company_id
LEFT JOIN bms.payment_transactions pt ON pm.method_id = pt.method_id
    AND pt.transaction_date >= CURRENT_DATE - INTERVAL '30 days'  -- 최근 30일
GROUP BY pm.method_id, c.company_name
ORDER BY c.company_name, pm.method_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_payment_summary OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 5.1 수납 관리 테이블 생성이 완료되었습니다!' as result;