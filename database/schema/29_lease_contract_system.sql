-- =====================================================
-- 임대차 계약 관리 시스템 테이블 생성 스크립트
-- Phase 3.1: 임대차 계약 정보 테이블 확장
-- =====================================================

-- 1. 임대차 계약 기본 정보 테이블
CREATE TABLE IF NOT EXISTS bms.lease_contracts (
    contract_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    
    -- 계약 기본 정보
    contract_number VARCHAR(50) NOT NULL,                  -- 계약 번호
    contract_type VARCHAR(20) NOT NULL,                    -- 계약 유형
    contract_status VARCHAR(20) DEFAULT 'DRAFT',           -- 계약 상태
    
    -- 계약 기간
    contract_date DATE NOT NULL,                           -- 계약 체결일
    move_in_date DATE NOT NULL,                            -- 입주 예정일
    actual_move_in_date DATE,                              -- 실제 입주일
    contract_start_date DATE NOT NULL,                     -- 계약 시작일
    contract_end_date DATE NOT NULL,                       -- 계약 종료일
    
    -- 임대 조건
    deposit_amount DECIMAL(15,2) NOT NULL,                 -- 보증금
    monthly_rent DECIMAL(15,2) NOT NULL,                   -- 월세
    maintenance_fee_included BOOLEAN DEFAULT false,        -- 관리비 포함 여부
    maintenance_fee_amount DECIMAL(15,2) DEFAULT 0,        -- 관리비 금액
    
    -- 임대료 조건
    rent_payment_day INTEGER DEFAULT 1,                    -- 임대료 납부일 (매월)
    rent_payment_method VARCHAR(20) DEFAULT 'BANK_TRANSFER', -- 납부 방법
    late_fee_rate DECIMAL(8,4) DEFAULT 0.025,              -- 연체료율 (일일)
    late_fee_grace_days INTEGER DEFAULT 5,                 -- 연체료 유예 기간
    
    -- 보증금 조건
    deposit_payment_date DATE,                             -- 보증금 납부일
    deposit_return_date DATE,                              -- 보증금 반환 예정일
    deposit_interest_rate DECIMAL(8,4) DEFAULT 0,          -- 보증금 이자율
    deposit_bank_account VARCHAR(100),                     -- 보증금 보관 계좌
    
    -- 계약 특약 사항
    special_terms TEXT,                                    -- 특약 사항
    contract_conditions JSONB,                             -- 계약 조건 (JSON)
    renewal_option VARCHAR(20) DEFAULT 'NEGOTIABLE',       -- 갱신 옵션
    auto_renewal BOOLEAN DEFAULT false,                    -- 자동 갱신 여부
    
    -- 계약서 파일 관리
    contract_document_path TEXT,                           -- 계약서 파일 경로
    contract_document_name VARCHAR(255),                   -- 계약서 파일명
    contract_document_size BIGINT,                         -- 파일 크기
    contract_document_hash VARCHAR(64),                    -- 파일 해시
    
    -- 추가 문서
    additional_documents JSONB,                            -- 추가 문서 정보 (JSON)
    
    -- 계약 변경 이력
    original_contract_id UUID,                             -- 원본 계약 ID (갱신/변경시)
    change_reason VARCHAR(20),                             -- 변경 사유
    change_description TEXT,                               -- 변경 내용
    
    -- 해지 정보
    termination_date DATE,                                 -- 해지일
    termination_reason VARCHAR(20),                        -- 해지 사유
    termination_notice_date DATE,                          -- 해지 통지일
    early_termination BOOLEAN DEFAULT false,               -- 조기 해지 여부
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_lease_contracts_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_lease_contracts_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_lease_contracts_original FOREIGN KEY (original_contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE SET NULL,
    CONSTRAINT uk_lease_contracts_number UNIQUE (company_id, contract_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_contract_type CHECK (contract_type IN (
        'NEW',                 -- 신규 계약
        'RENEWAL',             -- 갱신 계약
        'TRANSFER',            -- 명의 변경
        'MODIFICATION',        -- 계약 변경
        'SUBLEASE'             -- 전대 계약
    )),
    CONSTRAINT chk_contract_status CHECK (contract_status IN (
        'DRAFT',               -- 초안
        'PENDING',             -- 검토중
        'APPROVED',            -- 승인됨
        'ACTIVE',              -- 활성 (진행중)
        'EXPIRED',             -- 만료됨
        'TERMINATED',          -- 해지됨
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_renewal_option CHECK (renewal_option IN (
        'AUTOMATIC',           -- 자동 갱신
        'NEGOTIABLE',          -- 협의 갱신
        'FIXED_TERM',          -- 정기 계약
        'NO_RENEWAL'           -- 갱신 불가
    )),
    CONSTRAINT chk_termination_reason CHECK (termination_reason IN (
        'EXPIRATION',          -- 만료
        'TENANT_REQUEST',      -- 임차인 요청
        'LANDLORD_REQUEST',    -- 임대인 요청
        'BREACH_OF_CONTRACT',  -- 계약 위반
        'SALE_OF_PROPERTY',    -- 매매
        'REDEVELOPMENT',       -- 재개발
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_change_reason CHECK (change_reason IN (
        'RENT_ADJUSTMENT',     -- 임대료 조정
        'TENANT_CHANGE',       -- 임차인 변경
        'DEPOSIT_ADJUSTMENT',  -- 보증금 조정
        'TERM_EXTENSION',      -- 기간 연장
        'CONDITION_CHANGE',    -- 조건 변경
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_amounts CHECK (
        deposit_amount >= 0 AND monthly_rent >= 0 AND
        maintenance_fee_amount >= 0 AND
        late_fee_rate >= 0 AND late_fee_rate <= 100 AND
        deposit_interest_rate >= 0 AND deposit_interest_rate <= 100
    ),
    CONSTRAINT chk_dates CHECK (
        contract_end_date > contract_start_date AND
        move_in_date >= contract_date AND
        (actual_move_in_date IS NULL OR actual_move_in_date >= contract_date) AND
        (termination_date IS NULL OR termination_date <= contract_end_date)
    ),
    CONSTRAINT chk_payment_day CHECK (rent_payment_day BETWEEN 1 AND 31),
    CONSTRAINT chk_grace_days CHECK (late_fee_grace_days >= 0)
);

-- 2. 계약 당사자 정보 테이블
CREATE TABLE IF NOT EXISTS bms.contract_parties (
    party_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 당사자 기본 정보
    party_type VARCHAR(20) NOT NULL,                       -- 당사자 유형
    party_role VARCHAR(20) NOT NULL,                       -- 역할
    
    -- 개인 정보
    name VARCHAR(100) NOT NULL,                            -- 성명
    id_number VARCHAR(20),                                 -- 주민등록번호/사업자등록번호
    phone_number VARCHAR(20),                              -- 전화번호
    mobile_number VARCHAR(20),                             -- 휴대폰번호
    email VARCHAR(255),                                    -- 이메일
    
    -- 주소 정보
    address TEXT,                                          -- 주소
    postal_code VARCHAR(10),                               -- 우편번호
    
    -- 법인 정보 (법인인 경우)
    business_name VARCHAR(200),                            -- 상호/법인명
    business_registration_number VARCHAR(20),              -- 사업자등록번호
    representative_name VARCHAR(100),                      -- 대표자명
    business_address TEXT,                                 -- 사업장 주소
    
    -- 연대보증인 정보 (연대보증인인 경우)
    guarantor_relationship VARCHAR(50),                    -- 보증인과의 관계
    guarantor_occupation VARCHAR(100),                     -- 직업
    guarantor_income DECIMAL(15,2),                        -- 소득
    
    -- 중개업소 정보 (중개업소인 경우)
    agency_license_number VARCHAR(50),                     -- 중개업 등록번호
    agent_name VARCHAR(100),                               -- 중개사 성명
    commission_rate DECIMAL(8,4),                          -- 중개 수수료율
    commission_amount DECIMAL(15,2),                       -- 중개 수수료
    
    -- 상태 정보
    is_primary BOOLEAN DEFAULT false,                      -- 주 당사자 여부
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_contract_parties_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_contract_parties_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_party_type CHECK (party_type IN (
        'INDIVIDUAL',          -- 개인
        'CORPORATION',         -- 법인
        'PARTNERSHIP',         -- 조합/파트너십
        'GOVERNMENT',          -- 정부기관
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_party_role CHECK (party_role IN (
        'LANDLORD',            -- 임대인
        'TENANT',              -- 임차인
        'GUARANTOR',           -- 연대보증인
        'AGENT',               -- 중개업소
        'WITNESS',             -- 증인
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_amounts_party CHECK (
        (guarantor_income IS NULL OR guarantor_income >= 0) AND
        (commission_rate IS NULL OR (commission_rate >= 0 AND commission_rate <= 100)) AND
        (commission_amount IS NULL OR commission_amount >= 0)
    )
);

-- 3. 계약 상태 변경 이력 테이블
CREATE TABLE IF NOT EXISTS bms.contract_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 상태 변경 정보
    previous_status VARCHAR(20),                           -- 이전 상태
    new_status VARCHAR(20) NOT NULL,                       -- 새로운 상태
    status_change_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 상태 변경일시
    
    -- 변경 사유
    change_reason VARCHAR(20) NOT NULL,                    -- 변경 사유
    change_description TEXT,                               -- 변경 상세 설명
    
    -- 관련 문서
    supporting_documents JSONB,                            -- 관련 문서 정보
    
    -- 승인 정보
    approved_by UUID,                                      -- 승인자
    approval_date TIMESTAMP WITH TIME ZONE,               -- 승인일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 담당자 정보
    changed_by UUID,                                       -- 변경자
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_contract_status_history_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_contract_status_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_status_values CHECK (
        previous_status IN ('DRAFT', 'PENDING', 'APPROVED', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'CANCELLED') AND
        new_status IN ('DRAFT', 'PENDING', 'APPROVED', 'ACTIVE', 'EXPIRED', 'TERMINATED', 'CANCELLED')
    ),
    CONSTRAINT chk_change_reason_history CHECK (change_reason IN (
        'INITIAL_CREATION',    -- 최초 생성
        'APPROVAL_PROCESS',    -- 승인 과정
        'CONTRACT_EXECUTION',  -- 계약 체결
        'NATURAL_EXPIRATION',  -- 자연 만료
        'EARLY_TERMINATION',   -- 조기 해지
        'RENEWAL_PROCESS',     -- 갱신 과정
        'MODIFICATION',        -- 계약 변경
        'CANCELLATION',        -- 계약 취소
        'SYSTEM_UPDATE',       -- 시스템 업데이트
        'OTHER'                -- 기타
    ))
);

-- 4. 계약 첨부 문서 테이블
CREATE TABLE IF NOT EXISTS bms.contract_attachments (
    attachment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 문서 기본 정보
    document_type VARCHAR(20) NOT NULL,                    -- 문서 유형
    document_name VARCHAR(255) NOT NULL,                   -- 문서명
    document_description TEXT,                             -- 문서 설명
    
    -- 파일 정보
    file_path TEXT NOT NULL,                               -- 파일 경로
    file_name VARCHAR(255) NOT NULL,                       -- 파일명
    file_size BIGINT NOT NULL,                             -- 파일 크기
    file_type VARCHAR(50),                                 -- 파일 유형 (MIME)
    file_hash VARCHAR(64),                                 -- 파일 해시
    
    -- 문서 상태
    document_status VARCHAR(20) DEFAULT 'ACTIVE',          -- 문서 상태
    is_required BOOLEAN DEFAULT false,                     -- 필수 문서 여부
    is_signed BOOLEAN DEFAULT false,                       -- 서명 완료 여부
    
    -- 버전 관리
    version_number INTEGER DEFAULT 1,                      -- 버전 번호
    previous_version_id UUID,                              -- 이전 버전 ID
    
    -- 업로드 정보
    uploaded_by UUID,                                      -- 업로드자
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),   -- 업로드 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_contract_attachments_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_contract_attachments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contract_attachments_previous FOREIGN KEY (previous_version_id) REFERENCES bms.contract_attachments(attachment_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_document_type CHECK (document_type IN (
        'CONTRACT',            -- 계약서
        'ID_COPY',             -- 신분증 사본
        'INCOME_PROOF',        -- 소득 증명서
        'BUSINESS_LICENSE',    -- 사업자등록증
        'BANK_STATEMENT',      -- 통장 사본
        'GUARANTOR_DOCS',      -- 보증인 서류
        'INSURANCE_POLICY',    -- 보험증권
        'FLOOR_PLAN',          -- 평면도
        'INSPECTION_REPORT',   -- 점검 보고서
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_document_status CHECK (document_status IN (
        'ACTIVE',              -- 활성
        'ARCHIVED',            -- 보관됨
        'DELETED',             -- 삭제됨
        'EXPIRED'              -- 만료됨
    )),
    CONSTRAINT chk_file_size CHECK (file_size > 0),
    CONSTRAINT chk_version_number CHECK (version_number > 0)
);

-- 5. 계약 갱신 이력 테이블
CREATE TABLE IF NOT EXISTS bms.contract_renewals (
    renewal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_contract_id UUID NOT NULL,
    renewed_contract_id UUID,
    company_id UUID NOT NULL,
    
    -- 갱신 기본 정보
    renewal_type VARCHAR(20) NOT NULL,                     -- 갱신 유형
    renewal_status VARCHAR(20) DEFAULT 'PENDING',          -- 갱신 상태
    
    -- 갱신 일정
    renewal_notice_date DATE,                              -- 갱신 통지일
    renewal_deadline_date DATE,                            -- 갱신 마감일
    renewal_decision_date DATE,                            -- 갱신 결정일
    new_contract_start_date DATE,                          -- 새 계약 시작일
    new_contract_end_date DATE,                            -- 새 계약 종료일
    
    -- 갱신 조건
    previous_deposit DECIMAL(15,2),                        -- 기존 보증금
    new_deposit DECIMAL(15,2),                             -- 신규 보증금
    previous_rent DECIMAL(15,2),                           -- 기존 월세
    new_rent DECIMAL(15,2),                                -- 신규 월세
    
    -- 조건 변경 사항
    rent_increase_rate DECIMAL(8,4),                       -- 임대료 인상률
    deposit_adjustment DECIMAL(15,2),                      -- 보증금 조정액
    condition_changes JSONB,                               -- 조건 변경 사항 (JSON)
    
    -- 협상 과정
    negotiation_notes TEXT,                                -- 협상 메모
    tenant_response VARCHAR(20),                           -- 임차인 응답
    landlord_decision VARCHAR(20),                         -- 임대인 결정
    
    -- 처리 정보
    processed_by UUID,                                     -- 처리자
    processed_at TIMESTAMP WITH TIME ZONE,                -- 처리일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_contract_renewals_original FOREIGN KEY (original_contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_contract_renewals_renewed FOREIGN KEY (renewed_contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE SET NULL,
    CONSTRAINT fk_contract_renewals_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_renewal_type CHECK (renewal_type IN (
        'AUTOMATIC',           -- 자동 갱신
        'NEGOTIATED',          -- 협의 갱신
        'CONDITIONAL',         -- 조건부 갱신
        'FORCED'               -- 강제 갱신
    )),
    CONSTRAINT chk_renewal_status CHECK (renewal_status IN (
        'PENDING',             -- 대기중
        'NOTIFIED',            -- 통지됨
        'NEGOTIATING',         -- 협상중
        'AGREED',              -- 합의됨
        'REJECTED',            -- 거부됨
        'COMPLETED',           -- 완료됨
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_tenant_response CHECK (tenant_response IN (
        'ACCEPT',              -- 수락
        'REJECT',              -- 거부
        'NEGOTIATE',           -- 협상 요청
        'NO_RESPONSE'          -- 무응답
    )),
    CONSTRAINT chk_landlord_decision CHECK (landlord_decision IN (
        'APPROVE',             -- 승인
        'REJECT',              -- 거부
        'MODIFY',              -- 수정 요구
        'PENDING'              -- 보류
    )),
    CONSTRAINT chk_amounts_renewal CHECK (
        previous_deposit >= 0 AND new_deposit >= 0 AND
        previous_rent >= 0 AND new_rent >= 0 AND
        rent_increase_rate >= -100 AND rent_increase_rate <= 100
    ),
    CONSTRAINT chk_dates_renewal CHECK (
        (new_contract_end_date IS NULL OR new_contract_start_date IS NULL OR new_contract_end_date > new_contract_start_date) AND
        (renewal_deadline_date IS NULL OR renewal_notice_date IS NULL OR renewal_deadline_date >= renewal_notice_date)
    )
);

-- 6. RLS 정책 활성화
ALTER TABLE bms.lease_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_parties ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contract_renewals ENABLE ROW LEVEL SECURITY;

-- 7. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY lease_contracts_isolation_policy ON bms.lease_contracts
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_parties_isolation_policy ON bms.contract_parties
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_status_history_isolation_policy ON bms.contract_status_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_attachments_isolation_policy ON bms.contract_attachments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contract_renewals_isolation_policy ON bms.contract_renewals
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 8. 성능 최적화 인덱스 생성
-- 임대차 계약 인덱스
CREATE INDEX IF NOT EXISTS idx_lease_contracts_company_id ON bms.lease_contracts(company_id);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_unit_id ON bms.lease_contracts(unit_id);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_status ON bms.lease_contracts(contract_status);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_type ON bms.lease_contracts(contract_type);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_dates ON bms.lease_contracts(contract_start_date, contract_end_date);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_end_date ON bms.lease_contracts(contract_end_date);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_number ON bms.lease_contracts(contract_number);

-- 계약 당사자 인덱스
CREATE INDEX IF NOT EXISTS idx_contract_parties_contract_id ON bms.contract_parties(contract_id);
CREATE INDEX IF NOT EXISTS idx_contract_parties_company_id ON bms.contract_parties(company_id);
CREATE INDEX IF NOT EXISTS idx_contract_parties_role ON bms.contract_parties(party_role);
CREATE INDEX IF NOT EXISTS idx_contract_parties_type ON bms.contract_parties(party_type);
CREATE INDEX IF NOT EXISTS idx_contract_parties_name ON bms.contract_parties(name);

-- 계약 상태 이력 인덱스
CREATE INDEX IF NOT EXISTS idx_contract_status_history_contract_id ON bms.contract_status_history(contract_id);
CREATE INDEX IF NOT EXISTS idx_contract_status_history_company_id ON bms.contract_status_history(company_id);
CREATE INDEX IF NOT EXISTS idx_contract_status_history_date ON bms.contract_status_history(status_change_date DESC);
CREATE INDEX IF NOT EXISTS idx_contract_status_history_status ON bms.contract_status_history(new_status);

-- 계약 첨부 문서 인덱스
CREATE INDEX IF NOT EXISTS idx_contract_attachments_contract_id ON bms.contract_attachments(contract_id);
CREATE INDEX IF NOT EXISTS idx_contract_attachments_company_id ON bms.contract_attachments(company_id);
CREATE INDEX IF NOT EXISTS idx_contract_attachments_type ON bms.contract_attachments(document_type);
CREATE INDEX IF NOT EXISTS idx_contract_attachments_status ON bms.contract_attachments(document_status);

-- 계약 갱신 인덱스
CREATE INDEX IF NOT EXISTS idx_contract_renewals_original_id ON bms.contract_renewals(original_contract_id);
CREATE INDEX IF NOT EXISTS idx_contract_renewals_renewed_id ON bms.contract_renewals(renewed_contract_id);
CREATE INDEX IF NOT EXISTS idx_contract_renewals_company_id ON bms.contract_renewals(company_id);
CREATE INDEX IF NOT EXISTS idx_contract_renewals_status ON bms.contract_renewals(renewal_status);
CREATE INDEX IF NOT EXISTS idx_contract_renewals_deadline ON bms.contract_renewals(renewal_deadline_date);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_lease_contracts_company_status ON bms.lease_contracts(company_id, contract_status);
CREATE INDEX IF NOT EXISTS idx_lease_contracts_unit_status ON bms.lease_contracts(unit_id, contract_status);
CREATE INDEX IF NOT EXISTS idx_contract_parties_contract_role ON bms.contract_parties(contract_id, party_role);

-- 9. updated_at 자동 업데이트 트리거
CREATE TRIGGER lease_contracts_updated_at_trigger
    BEFORE UPDATE ON bms.lease_contracts
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_parties_updated_at_trigger
    BEFORE UPDATE ON bms.contract_parties
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_attachments_updated_at_trigger
    BEFORE UPDATE ON bms.contract_attachments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contract_renewals_updated_at_trigger
    BEFORE UPDATE ON bms.contract_renewals
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 스크립트 완료 메시지
SELECT '임대차 계약 관리 시스템 테이블 생성이 완료되었습니다.' as message;