-- 현금 흐름 예측 시스템 스키마
-- 작성일: 2025-01-08
-- 설명: 현금 흐름 예측, 자금 부족 경고, 투자 및 대출 관리 기능

-- 1. 현금 흐름 예측 모델 테이블
CREATE TABLE IF NOT EXISTS cash_flow_predictions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    prediction_date DATE NOT NULL,
    prediction_period_start DATE NOT NULL,
    prediction_period_end DATE NOT NULL,
    prediction_type VARCHAR(20) NOT NULL CHECK (prediction_type IN ('DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY')),
    
    -- 예측 금액 정보
    opening_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    predicted_inflows DECIMAL(15,2) NOT NULL DEFAULT 0,
    predicted_outflows DECIMAL(15,2) NOT NULL DEFAULT 0,
    predicted_closing_balance DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- 예측 상세 분석
    predicted_income DECIMAL(15,2) NOT NULL DEFAULT 0,
    predicted_expenses DECIMAL(15,2) NOT NULL DEFAULT 0,
    predicted_investments DECIMAL(15,2) NOT NULL DEFAULT 0,
    predicted_loan_payments DECIMAL(15,2) NOT NULL DEFAULT 0,
    
    -- 예측 신뢰도 및 상태
    confidence_score DECIMAL(5,2) CHECK (confidence_score >= 0 AND confidence_score <= 100),
    prediction_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (prediction_status IN ('ACTIVE', 'OUTDATED', 'ARCHIVED')),
    
    -- 예측 모델 정보
    model_version VARCHAR(50),
    prediction_algorithm VARCHAR(100),
    historical_data_period INTEGER, -- 예측에 사용된 과거 데이터 기간 (일)
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    notes TEXT,
    
    CONSTRAINT fk_cash_flow_predictions_company FOREIGN KEY (company_id) REFERENCES companies(id)
);

-- 2. 자금 부족 경고 설정 테이블
CREATE TABLE IF NOT EXISTS cash_shortage_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    alert_name VARCHAR(100) NOT NULL,
    
    -- 경고 조건 설정
    minimum_balance_threshold DECIMAL(15,2) NOT NULL,
    days_ahead_warning INTEGER NOT NULL DEFAULT 7, -- 며칠 전에 경고할지
    alert_level VARCHAR(20) NOT NULL DEFAULT 'WARNING' CHECK (alert_level IN ('INFO', 'WARNING', 'CRITICAL', 'EMERGENCY')),
    
    -- 경고 대상 및 방법
    alert_recipients JSONB, -- 경고 수신자 목록 (이메일, 사용자 ID 등)
    notification_methods JSONB, -- 알림 방법 (EMAIL, SMS, PUSH, SLACK 등)
    
    -- 경고 활성화 설정
    is_active BOOLEAN NOT NULL DEFAULT true,
    alert_frequency VARCHAR(20) DEFAULT 'DAILY' CHECK (alert_frequency IN ('ONCE', 'DAILY', 'WEEKLY')),
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    
    CONSTRAINT fk_cash_shortage_alerts_company FOREIGN KEY (company_id) REFERENCES companies(id)
);

-- 3. 자금 부족 경고 이력 테이블
CREATE TABLE IF NOT EXISTS cash_shortage_alert_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alert_setting_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 경고 발생 정보
    alert_date DATE NOT NULL,
    predicted_shortage_date DATE NOT NULL,
    predicted_balance DECIMAL(15,2) NOT NULL,
    shortage_amount DECIMAL(15,2) NOT NULL,
    alert_level VARCHAR(20) NOT NULL,
    
    -- 경고 처리 정보
    alert_status VARCHAR(20) NOT NULL DEFAULT 'SENT' CHECK (alert_status IN ('SENT', 'ACKNOWLEDGED', 'RESOLVED', 'IGNORED')),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by UUID,
    resolution_notes TEXT,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_cash_shortage_alert_history_setting FOREIGN KEY (alert_setting_id) REFERENCES cash_shortage_alerts(id),
    CONSTRAINT fk_cash_shortage_alert_history_company FOREIGN KEY (company_id) REFERENCES companies(id)
);

-- 4. 투자 관리 테이블
CREATE TABLE IF NOT EXISTS investments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    investment_name VARCHAR(200) NOT NULL,
    
    -- 투자 기본 정보
    investment_type VARCHAR(50) NOT NULL CHECK (investment_type IN ('DEPOSIT', 'BOND', 'STOCK', 'FUND', 'REAL_ESTATE', 'OTHER')),
    investment_category VARCHAR(50), -- 단기, 중기, 장기 등
    
    -- 투자 금액 정보
    principal_amount DECIMAL(15,2) NOT NULL,
    current_value DECIMAL(15,2),
    expected_return_rate DECIMAL(5,4), -- 연 수익률 (예: 0.0350 = 3.5%)
    
    -- 투자 기간 정보
    investment_date DATE NOT NULL,
    maturity_date DATE,
    is_renewable BOOLEAN DEFAULT false,
    
    -- 투자 상태 및 관리
    investment_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (investment_status IN ('PLANNED', 'ACTIVE', 'MATURED', 'LIQUIDATED', 'CANCELLED')),
    liquidity_level VARCHAR(20) DEFAULT 'MEDIUM' CHECK (liquidity_level IN ('HIGH', 'MEDIUM', 'LOW')), -- 유동성 수준
    
    -- 투자 기관 정보
    financial_institution VARCHAR(200),
    account_number VARCHAR(100),
    contact_person VARCHAR(100),
    contact_phone VARCHAR(20),
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    notes TEXT,
    
    CONSTRAINT fk_investments_company FOREIGN KEY (company_id) REFERENCES companies(id)
);

-- 5. 대출 관리 테이블
CREATE TABLE IF NOT EXISTS loans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    loan_name VARCHAR(200) NOT NULL,
    
    -- 대출 기본 정보
    loan_type VARCHAR(50) NOT NULL CHECK (loan_type IN ('OPERATING', 'EQUIPMENT', 'REAL_ESTATE', 'BRIDGE', 'LINE_OF_CREDIT', 'OTHER')),
    loan_purpose TEXT,
    
    -- 대출 금액 정보
    loan_amount DECIMAL(15,2) NOT NULL,
    outstanding_balance DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,4) NOT NULL, -- 연 이자율
    
    -- 대출 기간 정보
    loan_date DATE NOT NULL,
    maturity_date DATE NOT NULL,
    payment_frequency VARCHAR(20) DEFAULT 'MONTHLY' CHECK (payment_frequency IN ('WEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUALLY')),
    
    -- 상환 정보
    monthly_payment DECIMAL(15,2),
    next_payment_date DATE,
    total_payments_made INTEGER DEFAULT 0,
    
    -- 대출 상태 및 관리
    loan_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' CHECK (loan_status IN ('APPROVED', 'ACTIVE', 'PAID_OFF', 'DEFAULTED', 'RESTRUCTURED')),
    
    -- 대출 기관 정보
    lender_name VARCHAR(200) NOT NULL,
    loan_officer VARCHAR(100),
    contact_phone VARCHAR(20),
    
    -- 담보 정보
    collateral_type VARCHAR(100),
    collateral_value DECIMAL(15,2),
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    notes TEXT,
    
    CONSTRAINT fk_loans_company FOREIGN KEY (company_id) REFERENCES companies(id)
);

-- 6. 현금 흐름 시나리오 분석 테이블
CREATE TABLE IF NOT EXISTS cash_flow_scenarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    scenario_name VARCHAR(200) NOT NULL,
    
    -- 시나리오 설정
    scenario_type VARCHAR(20) NOT NULL DEFAULT 'WHAT_IF' CHECK (scenario_type IN ('OPTIMISTIC', 'REALISTIC', 'PESSIMISTIC', 'WHAT_IF')),
    base_prediction_id UUID, -- 기준이 되는 예측 ID
    
    -- 시나리오 조정 요소
    income_adjustment_rate DECIMAL(5,4) DEFAULT 0, -- 수입 조정 비율 (예: 0.1 = 10% 증가)
    expense_adjustment_rate DECIMAL(5,4) DEFAULT 0, -- 지출 조정 비율
    investment_adjustment_rate DECIMAL(5,4) DEFAULT 0, -- 투자 조정 비율
    
    -- 시나리오 결과
    scenario_period_start DATE NOT NULL,
    scenario_period_end DATE NOT NULL,
    adjusted_closing_balance DECIMAL(15,2),
    risk_assessment TEXT,
    
    -- 시나리오 상태
    scenario_status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (scenario_status IN ('DRAFT', 'ACTIVE', 'ARCHIVED')),
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by UUID,
    description TEXT,
    
    CONSTRAINT fk_cash_flow_scenarios_company FOREIGN KEY (company_id) REFERENCES companies(id),
    CONSTRAINT fk_cash_flow_scenarios_prediction FOREIGN KEY (base_prediction_id) REFERENCES cash_flow_predictions(id)
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_cash_flow_predictions_company_date ON cash_flow_predictions(company_id, prediction_date);
CREATE INDEX IF NOT EXISTS idx_cash_flow_predictions_period ON cash_flow_predictions(prediction_period_start, prediction_period_end);
CREATE INDEX IF NOT EXISTS idx_cash_flow_predictions_status ON cash_flow_predictions(prediction_status);

CREATE INDEX IF NOT EXISTS idx_cash_shortage_alerts_company ON cash_shortage_alerts(company_id);
CREATE INDEX IF NOT EXISTS idx_cash_shortage_alerts_active ON cash_shortage_alerts(is_active);

CREATE INDEX IF NOT EXISTS idx_cash_shortage_alert_history_company_date ON cash_shortage_alert_history(company_id, alert_date);
CREATE INDEX IF NOT EXISTS idx_cash_shortage_alert_history_status ON cash_shortage_alert_history(alert_status);

CREATE INDEX IF NOT EXISTS idx_investments_company_status ON investments(company_id, investment_status);
CREATE INDEX IF NOT EXISTS idx_investments_maturity_date ON investments(maturity_date);
CREATE INDEX IF NOT EXISTS idx_investments_type ON investments(investment_type);

CREATE INDEX IF NOT EXISTS idx_loans_company_status ON loans(company_id, loan_status);
CREATE INDEX IF NOT EXISTS idx_loans_next_payment_date ON loans(next_payment_date);
CREATE INDEX IF NOT EXISTS idx_loans_maturity_date ON loans(maturity_date);

CREATE INDEX IF NOT EXISTS idx_cash_flow_scenarios_company ON cash_flow_scenarios(company_id);
CREATE INDEX IF NOT EXISTS idx_cash_flow_scenarios_status ON cash_flow_scenarios(scenario_status);

-- 현금 흐름 예측 계산 함수
CREATE OR REPLACE FUNCTION calculate_cash_flow_prediction(
    p_company_id UUID,
    p_prediction_start DATE,
    p_prediction_end DATE,
    p_prediction_type VARCHAR DEFAULT 'MONTHLY'
) RETURNS UUID AS $$
DECLARE
    v_prediction_id UUID;
    v_opening_balance DECIMAL(15,2) := 0;
    v_predicted_inflows DECIMAL(15,2) := 0;
    v_predicted_outflows DECIMAL(15,2) := 0;
    v_predicted_income DECIMAL(15,2) := 0;
    v_predicted_expenses DECIMAL(15,2) := 0;
    v_predicted_investments DECIMAL(15,2) := 0;
    v_predicted_loan_payments DECIMAL(15,2) := 0;
    v_confidence_score DECIMAL(5,2) := 75.0;
BEGIN
    -- 현재 현금 잔액 조회 (은행 계좌 잔액 합계)
    SELECT COALESCE(SUM(current_balance), 0)
    INTO v_opening_balance
    FROM bank_accounts
    WHERE company_id = p_company_id AND account_status = 'ACTIVE';
    
    -- 예상 수입 계산 (정기 수입 + 미수금 회수 예상)
    SELECT COALESCE(SUM(amount), 0)
    INTO v_predicted_income
    FROM income_records ir
    JOIN income_types it ON ir.income_type_id = it.id
    WHERE ir.company_id = p_company_id
    AND ir.income_date BETWEEN p_prediction_start AND p_prediction_end
    AND ir.status IN ('CONFIRMED', 'PENDING');
    
    -- 예상 지출 계산 (정기 지출 + 승인된 지출)
    SELECT COALESCE(SUM(amount), 0)
    INTO v_predicted_expenses
    FROM expense_records er
    WHERE er.company_id = p_company_id
    AND er.expense_date BETWEEN p_prediction_start AND p_prediction_end
    AND er.status IN ('APPROVED', 'PENDING');
    
    -- 예상 투자 금액 계산
    SELECT COALESCE(SUM(principal_amount), 0)
    INTO v_predicted_investments
    FROM investments
    WHERE company_id = p_company_id
    AND investment_date BETWEEN p_prediction_start AND p_prediction_end
    AND investment_status = 'PLANNED';
    
    -- 예상 대출 상환 금액 계산
    SELECT COALESCE(SUM(monthly_payment), 0)
    INTO v_predicted_loan_payments
    FROM loans
    WHERE company_id = p_company_id
    AND next_payment_date BETWEEN p_prediction_start AND p_prediction_end
    AND loan_status = 'ACTIVE';
    
    -- 총 유입/유출 계산
    v_predicted_inflows := v_predicted_income;
    v_predicted_outflows := v_predicted_expenses + v_predicted_investments + v_predicted_loan_payments;
    
    -- 예측 데이터 저장
    INSERT INTO cash_flow_predictions (
        company_id, prediction_date, prediction_period_start, prediction_period_end,
        prediction_type, opening_balance, predicted_inflows, predicted_outflows,
        predicted_closing_balance, predicted_income, predicted_expenses,
        predicted_investments, predicted_loan_payments, confidence_score,
        model_version, prediction_algorithm, historical_data_period
    ) VALUES (
        p_company_id, CURRENT_DATE, p_prediction_start, p_prediction_end,
        p_prediction_type, v_opening_balance, v_predicted_inflows, v_predicted_outflows,
        v_opening_balance + v_predicted_inflows - v_predicted_outflows,
        v_predicted_income, v_predicted_expenses, v_predicted_investments,
        v_predicted_loan_payments, v_confidence_score,
        '1.0', 'BASIC_PROJECTION', 90
    ) RETURNING id INTO v_prediction_id;
    
    RETURN v_prediction_id;
END;
$$ LANGUAGE plpgsql;

-- 자금 부족 경고 확인 함수
CREATE OR REPLACE FUNCTION check_cash_shortage_alerts(p_company_id UUID DEFAULT NULL)
RETURNS INTEGER AS $$
DECLARE
    v_alert_record RECORD;
    v_prediction_record RECORD;
    v_alerts_triggered INTEGER := 0;
BEGIN
    -- 활성화된 경고 설정 조회
    FOR v_alert_record IN
        SELECT * FROM cash_shortage_alerts
        WHERE (p_company_id IS NULL OR company_id = p_company_id)
        AND is_active = true
    LOOP
        -- 해당 기간의 현금 흐름 예측 조회
        FOR v_prediction_record IN
            SELECT * FROM cash_flow_predictions
            WHERE company_id = v_alert_record.company_id
            AND prediction_period_start <= CURRENT_DATE + INTERVAL '1 day' * v_alert_record.days_ahead_warning
            AND prediction_period_end >= CURRENT_DATE
            AND prediction_status = 'ACTIVE'
            AND predicted_closing_balance < v_alert_record.minimum_balance_threshold
        LOOP
            -- 이미 발생한 경고인지 확인
            IF NOT EXISTS (
                SELECT 1 FROM cash_shortage_alert_history
                WHERE alert_setting_id = v_alert_record.id
                AND alert_date = CURRENT_DATE
                AND predicted_shortage_date = v_prediction_record.prediction_period_end
            ) THEN
                -- 경고 이력 생성
                INSERT INTO cash_shortage_alert_history (
                    alert_setting_id, company_id, alert_date, predicted_shortage_date,
                    predicted_balance, shortage_amount, alert_level
                ) VALUES (
                    v_alert_record.id, v_alert_record.company_id, CURRENT_DATE,
                    v_prediction_record.prediction_period_end,
                    v_prediction_record.predicted_closing_balance,
                    v_alert_record.minimum_balance_threshold - v_prediction_record.predicted_closing_balance,
                    v_alert_record.alert_level
                );
                
                v_alerts_triggered := v_alerts_triggered + 1;
            END IF;
        END LOOP;
    END LOOP;
    
    RETURN v_alerts_triggered;
END;
$$ LANGUAGE plpgsql;

-- 투자 수익률 업데이트 함수
CREATE OR REPLACE FUNCTION update_investment_values()
RETURNS INTEGER AS $$
DECLARE
    v_investment_record RECORD;
    v_updated_count INTEGER := 0;
    v_days_invested INTEGER;
    v_new_value DECIMAL(15,2);
BEGIN
    FOR v_investment_record IN
        SELECT * FROM investments
        WHERE investment_status = 'ACTIVE'
        AND expected_return_rate IS NOT NULL
    LOOP
        -- 투자 기간 계산 (일 단위)
        v_days_invested := CURRENT_DATE - v_investment_record.investment_date;
        
        -- 복리 계산 (일할 계산)
        v_new_value := v_investment_record.principal_amount * 
                      POWER(1 + v_investment_record.expected_return_rate / 365, v_days_invested);
        
        -- 투자 가치 업데이트
        UPDATE investments
        SET current_value = v_new_value,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_investment_record.id;
        
        v_updated_count := v_updated_count + 1;
    END LOOP;
    
    RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- 대출 상환 스케줄 업데이트 함수
CREATE OR REPLACE FUNCTION update_loan_schedules()
RETURNS INTEGER AS $$
DECLARE
    v_loan_record RECORD;
    v_updated_count INTEGER := 0;
    v_next_payment_date DATE;
BEGIN
    FOR v_loan_record IN
        SELECT * FROM loans
        WHERE loan_status = 'ACTIVE'
        AND next_payment_date <= CURRENT_DATE
    LOOP
        -- 다음 상환일 계산
        CASE v_loan_record.payment_frequency
            WHEN 'WEEKLY' THEN
                v_next_payment_date := v_loan_record.next_payment_date + INTERVAL '1 week';
            WHEN 'MONTHLY' THEN
                v_next_payment_date := v_loan_record.next_payment_date + INTERVAL '1 month';
            WHEN 'QUARTERLY' THEN
                v_next_payment_date := v_loan_record.next_payment_date + INTERVAL '3 months';
            WHEN 'ANNUALLY' THEN
                v_next_payment_date := v_loan_record.next_payment_date + INTERVAL '1 year';
            ELSE
                v_next_payment_date := v_loan_record.next_payment_date + INTERVAL '1 month';
        END CASE;
        
        -- 대출 정보 업데이트
        UPDATE loans
        SET next_payment_date = v_next_payment_date,
            total_payments_made = total_payments_made + 1,
            outstanding_balance = GREATEST(0, outstanding_balance - COALESCE(monthly_payment, 0)),
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_loan_record.id;
        
        -- 대출 완료 확인
        IF (SELECT outstanding_balance FROM loans WHERE id = v_loan_record.id) <= 0 THEN
            UPDATE loans
            SET loan_status = 'PAID_OFF'
            WHERE id = v_loan_record.id;
        END IF;
        
        v_updated_count := v_updated_count + 1;
    END LOOP;
    
    RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql;

-- 코멘트 추가
COMMENT ON TABLE cash_flow_predictions IS '현금 흐름 예측 데이터 관리';
COMMENT ON TABLE cash_shortage_alerts IS '자금 부족 경고 설정 관리';
COMMENT ON TABLE cash_shortage_alert_history IS '자금 부족 경고 발생 이력';
COMMENT ON TABLE investments IS '투자 관리 및 추적';
COMMENT ON TABLE loans IS '대출 관리 및 상환 추적';
COMMENT ON TABLE cash_flow_scenarios IS '현금 흐름 시나리오 분석';

COMMENT ON FUNCTION calculate_cash_flow_prediction IS '현금 흐름 예측 계산 및 저장';
COMMENT ON FUNCTION check_cash_shortage_alerts IS '자금 부족 경고 확인 및 알림 생성';
COMMENT ON FUNCTION update_investment_values IS '투자 가치 자동 업데이트';
COMMENT ON FUNCTION update_loan_schedules IS '대출 상환 스케줄 자동 업데이트';