-- =====================================================
-- 계약 당사자 관리 시스템 테이블 생성 스크립트
-- Phase 3.2: 계약 당사자 관리
-- =====================================================

-- 1. 계약 당사자 연락처 이력 테이블
CREATE TABLE IF NOT EXISTS bms.contract_party_contacts (
    contact_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 연락처 정보
    contact_type VARCHAR(20) NOT NULL,                     -- 연락처 유형
    contact_value VARCHAR(255) NOT NULL,                   -- 연락처 값
    is_primary BOOLEAN DEFAULT false,                      -- 주 연락처 여부
    is_verified BOOLEAN DEFAULT false,                     -- 인증 여부
    
    -- 인증 정보
    verification_method VARCHAR(20),                       -- 인증 방법
    verification_date TIMESTAMP WITH TIME ZONE,           -- 인증 일시
    verification_code VARCHAR(10),                         -- 인증 코드
    
    -- 사용 목적
    usage_purpose TEXT[],                                  -- 사용 목적
    notification_allowed BOOLEAN DEFAULT true,            -- 알림 수신 허용
    
    -- 상태 정보
    contact_status VARCHAR(20) DEFAULT 'ACTIVE',           -- 연락처 상태
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_party_contacts_party FOREIGN KEY (party_id) REFERENCES bms.contract_parties(party_id) ON DELETE CASCADE,
    CONSTRAINT fk_party_contacts_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_contact_type CHECK (contact_type IN (
        'PHONE',               -- 전화번호
        'MOBILE',              -- 휴대폰번호
        'EMAIL',               -- 이메일
        'FAX',                 -- 팩스
        'KAKAO_TALK',          -- 카카오톡
        'LINE',                -- 라인
        'TELEGRAM',            -- 텔레그램
        'WECHAT',              -- 위챗
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_verification_method CHECK (verification_method IN (
        'SMS',                 -- SMS 인증
        'EMAIL',               -- 이메일 인증
        'PHONE_CALL',          -- 전화 인증
        'DOCUMENT',            -- 서류 인증
        'IN_PERSON',           -- 대면 인증
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_contact_status CHECK (contact_status IN (
        'ACTIVE',              -- 활성
        'INACTIVE',            -- 비활성
        'INVALID',             -- 유효하지 않음
        'BLOCKED'              -- 차단됨
    ))
);

-- 2. 계약 당사자 신용 정보 테이블
CREATE TABLE IF NOT EXISTS bms.contract_party_credit (
    credit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 신용 평가 기본 정보
    credit_evaluation_date DATE NOT NULL,                  -- 신용 평가일
    credit_score INTEGER,                                  -- 신용 점수
    credit_grade VARCHAR(10),                              -- 신용 등급
    credit_agency VARCHAR(50),                             -- 신용평가기관
    
    -- 소득 정보
    monthly_income DECIMAL(15,2),                          -- 월 소득
    annual_income DECIMAL(15,2),                           -- 연 소득
    income_source VARCHAR(100),                            -- 소득원
    employment_status VARCHAR(20),                         -- 고용 상태
    employment_period_months INTEGER,                      -- 재직 기간 (월)
    
    -- 자산 정보
    total_assets DECIMAL(15,2),                            -- 총 자산
    real_estate_assets DECIMAL(15,2),                      -- 부동산 자산
    financial_assets DECIMAL(15,2),                        -- 금융 자산
    other_assets DECIMAL(15,2),                            -- 기타 자산
    
    -- 부채 정보
    total_debts DECIMAL(15,2),                             -- 총 부채
    mortgage_debt DECIMAL(15,2),                           -- 주택담보대출
    credit_card_debt DECIMAL(15,2),                        -- 신용카드 부채
    other_debts DECIMAL(15,2),                             -- 기타 부채
    
    -- 신용 이력
    credit_history_years INTEGER,                          -- 신용 이력 기간
    default_history BOOLEAN DEFAULT false,                -- 연체 이력 여부
    bankruptcy_history BOOLEAN DEFAULT false,             -- 파산 이력 여부
    lawsuit_history BOOLEAN DEFAULT false,                -- 소송 이력 여부
    
    -- 평가 결과
    evaluation_result VARCHAR(20),                         -- 평가 결과
    risk_level VARCHAR(20),                                -- 위험 수준
    recommended_deposit_ratio DECIMAL(5,2),                -- 권장 보증금 비율
    recommended_guarantor BOOLEAN DEFAULT false,           -- 연대보증인 필요 여부
    
    -- 평가자 정보
    evaluated_by UUID,                                     -- 평가자
    evaluation_notes TEXT,                                 -- 평가 메모
    
    -- 유효 기간
    valid_until DATE,                                      -- 유효 기간
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_party_credit_party FOREIGN KEY (party_id) REFERENCES bms.contract_parties(party_id) ON DELETE CASCADE,
    CONSTRAINT fk_party_credit_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_credit_score CHECK (credit_score IS NULL OR (credit_score >= 0 AND credit_score <= 1000)),
    CONSTRAINT chk_credit_grade CHECK (credit_grade IN (
        'AAA', 'AA+', 'AA', 'AA-',
        'A+', 'A', 'A-',
        'BBB+', 'BBB', 'BBB-',
        'BB+', 'BB', 'BB-',
        'B+', 'B', 'B-',
        'CCC+', 'CCC', 'CCC-',
        'CC', 'C', 'D'
    )),
    CONSTRAINT chk_employment_status CHECK (employment_status IN (
        'EMPLOYED',            -- 정규직
        'CONTRACT',            -- 계약직
        'PART_TIME',           -- 시간제
        'SELF_EMPLOYED',       -- 자영업
        'UNEMPLOYED',          -- 무직
        'RETIRED',             -- 은퇴
        'STUDENT',             -- 학생
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_evaluation_result CHECK (evaluation_result IN (
        'EXCELLENT',           -- 우수
        'GOOD',                -- 양호
        'FAIR',                -- 보통
        'POOR',                -- 미흡
        'REJECTED'             -- 거부
    )),
    CONSTRAINT chk_risk_level CHECK (risk_level IN (
        'LOW',                 -- 낮음
        'MEDIUM',              -- 보통
        'HIGH',                -- 높음
        'VERY_HIGH'            -- 매우 높음
    )),
    CONSTRAINT chk_amounts_credit CHECK (
        (monthly_income IS NULL OR monthly_income >= 0) AND
        (annual_income IS NULL OR annual_income >= 0) AND
        (total_assets IS NULL OR total_assets >= 0) AND
        (total_debts IS NULL OR total_debts >= 0) AND
        (recommended_deposit_ratio IS NULL OR (recommended_deposit_ratio >= 0 AND recommended_deposit_ratio <= 100))
    ),
    CONSTRAINT chk_employment_period CHECK (employment_period_months IS NULL OR employment_period_months >= 0),
    CONSTRAINT chk_credit_history CHECK (credit_history_years IS NULL OR credit_history_years >= 0)
);

-- 3. 계약 당사자 관계 테이블
CREATE TABLE IF NOT EXISTS bms.contract_party_relationships (
    relationship_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 관계 당사자
    primary_party_id UUID NOT NULL,                       -- 주 당사자
    related_party_id UUID NOT NULL,                       -- 관련 당사자
    
    -- 관계 정보
    relationship_type VARCHAR(20) NOT NULL,               -- 관계 유형
    relationship_description TEXT,                        -- 관계 설명
    
    -- 법적 관계
    legal_relationship VARCHAR(20),                       -- 법적 관계
    responsibility_level VARCHAR(20),                     -- 책임 수준
    liability_amount DECIMAL(15,2),                       -- 책임 한도 금액
    
    -- 권한 정보
    authorization_scope TEXT[],                           -- 권한 범위
    can_sign_contract BOOLEAN DEFAULT false,              -- 계약 서명 권한
    can_modify_contract BOOLEAN DEFAULT false,            -- 계약 변경 권한
    can_terminate_contract BOOLEAN DEFAULT false,         -- 계약 해지 권한
    can_receive_notices BOOLEAN DEFAULT true,             -- 통지 수신 권한
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,       -- 관계 시작일
    effective_end_date DATE,                              -- 관계 종료일
    
    -- 상태 정보
    relationship_status VARCHAR(20) DEFAULT 'ACTIVE',     -- 관계 상태
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_party_relationships_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_party_relationships_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_party_relationships_primary FOREIGN KEY (primary_party_id) REFERENCES bms.contract_parties(party_id) ON DELETE CASCADE,
    CONSTRAINT fk_party_relationships_related FOREIGN KEY (related_party_id) REFERENCES bms.contract_parties(party_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_relationship_type CHECK (relationship_type IN (
        'SPOUSE',              -- 배우자
        'PARENT',              -- 부모
        'CHILD',               -- 자녀
        'SIBLING',             -- 형제자매
        'RELATIVE',            -- 친척
        'BUSINESS_PARTNER',    -- 사업 파트너
        'EMPLOYEE',            -- 직원
        'REPRESENTATIVE',      -- 대리인
        'GUARANTOR',           -- 보증인
        'CO_TENANT',           -- 공동 임차인
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_legal_relationship CHECK (legal_relationship IN (
        'JOINT_LIABILITY',     -- 연대 책임
        'INDIVIDUAL_LIABILITY', -- 개별 책임
        'LIMITED_LIABILITY',   -- 제한 책임
        'NO_LIABILITY',        -- 무책임
        'REPRESENTATIVE'       -- 대리 관계
    )),
    CONSTRAINT chk_responsibility_level CHECK (responsibility_level IN (
        'FULL',                -- 전체 책임
        'PARTIAL',             -- 부분 책임
        'LIMITED',             -- 제한 책임
        'NONE'                 -- 무책임
    )),
    CONSTRAINT chk_relationship_status CHECK (relationship_status IN (
        'ACTIVE',              -- 활성
        'INACTIVE',            -- 비활성
        'SUSPENDED',           -- 중단
        'TERMINATED'           -- 종료
    )),
    CONSTRAINT chk_liability_amount CHECK (liability_amount IS NULL OR liability_amount >= 0),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date),
    CONSTRAINT chk_different_parties CHECK (primary_party_id != related_party_id)
);

-- 4. 계약 당사자 변경 이력 테이블
CREATE TABLE IF NOT EXISTS bms.contract_party_changes (
    change_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 변경 기본 정보
    change_type VARCHAR(20) NOT NULL,                      -- 변경 유형
    change_reason VARCHAR(20) NOT NULL,                    -- 변경 사유
    change_description TEXT,                               -- 변경 설명
    
    -- 변경 대상
    affected_party_id UUID,                               -- 영향받는 당사자
    previous_party_id UUID,                               -- 이전 당사자
    new_party_id UUID,                                    -- 새로운 당사자
    
    -- 변경 내용
    changed_fields JSONB,                                 -- 변경된 필드 정보
    previous_values JSONB,                                -- 이전 값
    new_values JSONB,                                     -- 새로운 값
    
    -- 법적 절차
    legal_procedure_required BOOLEAN DEFAULT false,       -- 법적 절차 필요 여부
    legal_procedure_completed BOOLEAN DEFAULT false,      -- 법적 절차 완료 여부
    legal_document_path TEXT,                             -- 법적 문서 경로
    
    -- 승인 정보
    approval_required BOOLEAN DEFAULT true,               -- 승인 필요 여부
    approved_by UUID,                                     -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                -- 승인 일시
    approval_notes TEXT,                                  -- 승인 메모
    
    -- 적용 정보
    effective_date DATE,                                  -- 적용일
    applied_by UUID,                                      -- 적용자
    applied_at TIMESTAMP WITH TIME ZONE,                 -- 적용 일시
    
    -- 상태 정보
    change_status VARCHAR(20) DEFAULT 'PENDING',          -- 변경 상태
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_party_changes_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_party_changes_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_party_changes_affected FOREIGN KEY (affected_party_id) REFERENCES bms.contract_parties(party_id) ON DELETE SET NULL,
    CONSTRAINT fk_party_changes_previous FOREIGN KEY (previous_party_id) REFERENCES bms.contract_parties(party_id) ON DELETE SET NULL,
    CONSTRAINT fk_party_changes_new FOREIGN KEY (new_party_id) REFERENCES bms.contract_parties(party_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_change_type CHECK (change_type IN (
        'ADD_PARTY',           -- 당사자 추가
        'REMOVE_PARTY',        -- 당사자 제거
        'REPLACE_PARTY',       -- 당사자 교체
        'UPDATE_INFO',         -- 정보 업데이트
        'CHANGE_ROLE',         -- 역할 변경
        'UPDATE_CONTACT',      -- 연락처 변경
        'UPDATE_RELATIONSHIP', -- 관계 변경
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_change_reason CHECK (change_reason IN (
        'DEATH',               -- 사망
        'DIVORCE',             -- 이혼
        'MARRIAGE',            -- 결혼
        'BUSINESS_TRANSFER',   -- 사업 양도
        'LEGAL_REQUIREMENT',   -- 법적 요구사항
        'VOLUNTARY_CHANGE',    -- 자발적 변경
        'COURT_ORDER',         -- 법원 명령
        'BANKRUPTCY',          -- 파산
        'INCAPACITY',          -- 무능력
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_change_status CHECK (change_status IN (
        'PENDING',             -- 대기중
        'APPROVED',            -- 승인됨
        'REJECTED',            -- 거부됨
        'APPLIED',             -- 적용됨
        'CANCELLED'            -- 취소됨
    ))
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.contract_party_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_party_credit ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_party_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_party_changes ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY contract_party_contacts_isolation_policy ON bms.contract_party_contacts
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_party_credit_isolation_policy ON bms.contract_party_credit
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_party_relationships_isolation_policy ON bms.contract_party_relationships
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_party_changes_isolation_policy ON bms.contract_party_changes
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 계약 당사자 연락처 인덱스
CREATE INDEX IF NOT EXISTS idx_party_contacts_party_id ON bms.contract_party_contacts(party_id);
CREATE INDEX IF NOT EXISTS idx_party_contacts_company_id ON bms.contract_party_contacts(company_id);
CREATE INDEX IF NOT EXISTS idx_party_contacts_type ON bms.contract_party_contacts(contact_type);
CREATE INDEX IF NOT EXISTS idx_party_contacts_primary ON bms.contract_party_contacts(is_primary);
CREATE INDEX IF NOT EXISTS idx_party_contacts_status ON bms.contract_party_contacts(contact_status);

-- 계약 당사자 신용 정보 인덱스
CREATE INDEX IF NOT EXISTS idx_party_credit_party_id ON bms.contract_party_credit(party_id);
CREATE INDEX IF NOT EXISTS idx_party_credit_company_id ON bms.contract_party_credit(company_id);
CREATE INDEX IF NOT EXISTS idx_party_credit_evaluation_date ON bms.contract_party_credit(credit_evaluation_date DESC);
CREATE INDEX IF NOT EXISTS idx_party_credit_score ON bms.contract_party_credit(credit_score DESC);
CREATE INDEX IF NOT EXISTS idx_party_credit_grade ON bms.contract_party_credit(credit_grade);
CREATE INDEX IF NOT EXISTS idx_party_credit_valid_until ON bms.contract_party_credit(valid_until);

-- 계약 당사자 관계 인덱스
CREATE INDEX IF NOT EXISTS idx_party_relationships_contract_id ON bms.contract_party_relationships(contract_id);
CREATE INDEX IF NOT EXISTS idx_party_relationships_company_id ON bms.contract_party_relationships(company_id);
CREATE INDEX IF NOT EXISTS idx_party_relationships_primary ON bms.contract_party_relationships(primary_party_id);
CREATE INDEX IF NOT EXISTS idx_party_relationships_related ON bms.contract_party_relationships(related_party_id);
CREATE INDEX IF NOT EXISTS idx_party_relationships_type ON bms.contract_party_relationships(relationship_type);
CREATE INDEX IF NOT EXISTS idx_party_relationships_status ON bms.contract_party_relationships(relationship_status);

-- 계약 당사자 변경 이력 인덱스
CREATE INDEX IF NOT EXISTS idx_party_changes_contract_id ON bms.contract_party_changes(contract_id);
CREATE INDEX IF NOT EXISTS idx_party_changes_company_id ON bms.contract_party_changes(company_id);
CREATE INDEX IF NOT EXISTS idx_party_changes_affected ON bms.contract_party_changes(affected_party_id);
CREATE INDEX IF NOT EXISTS idx_party_changes_type ON bms.contract_party_changes(change_type);
CREATE INDEX IF NOT EXISTS idx_party_changes_status ON bms.contract_party_changes(change_status);
CREATE INDEX IF NOT EXISTS idx_party_changes_date ON bms.contract_party_changes(created_at DESC);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_party_contacts_party_type ON bms.contract_party_contacts(party_id, contact_type);
CREATE INDEX IF NOT EXISTS idx_party_relationships_contract_type ON bms.contract_party_relationships(contract_id, relationship_type);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER contract_party_contacts_updated_at_trigger
    BEFORE UPDATE ON bms.contract_party_contacts
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_party_credit_updated_at_trigger
    BEFORE UPDATE ON bms.contract_party_credit
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_party_relationships_updated_at_trigger
    BEFORE UPDATE ON bms.contract_party_relationships
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_party_changes_updated_at_trigger
    BEFORE UPDATE ON bms.contract_party_changes
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 스크립트 완료 메시지
SELECT '계약 당사자 관리 시스템 테이블 생성이 완료되었습니다.' as message;