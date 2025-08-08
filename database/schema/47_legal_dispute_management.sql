-- =====================================================
-- Legal Management and Dispute Resolution System
-- Phase 3.7: Legal Management and Dispute Processing
-- =====================================================

-- 1. Legal requirements compliance table
CREATE TABLE IF NOT EXISTS bms.legal_compliance_requirements (
    requirement_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- Requirement information
    requirement_type VARCHAR(30) NOT NULL,
    requirement_category VARCHAR(20) NOT NULL,
    requirement_title VARCHAR(200) NOT NULL,
    requirement_description TEXT,
    
    -- Legal basis
    legal_basis VARCHAR(100),
    regulation_reference VARCHAR(100),
    effective_date DATE,
    
    -- Compliance details
    compliance_status VARCHAR(20) DEFAULT 'PENDING',
    compliance_deadline DATE,
    last_review_date DATE,
    next_review_date DATE,
    
    -- Implementation details
    implementation_notes TEXT,
    responsible_staff_id UUID,
    
    -- Documentation
    supporting_documents JSONB,
    compliance_evidence JSONB,
    
    -- Risk assessment
    risk_level VARCHAR(20) DEFAULT 'MEDIUM',
    non_compliance_penalty TEXT,
    
    -- Status tracking
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_legal_requirements_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_legal_requirements_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_requirement_type CHECK (requirement_type IN (
        'TENANT_PROTECTION_LAW', 'DEPOSIT_PROTECTION', 'SAFETY_REGULATION',
        'BUILDING_CODE', 'FIRE_SAFETY', 'ACCESSIBILITY', 'ENVIRONMENTAL',
        'TAX_COMPLIANCE', 'INSURANCE_REQUIREMENT', 'OTHER'
    )),
    CONSTRAINT chk_requirement_category CHECK (requirement_category IN (
        'MANDATORY', 'RECOMMENDED', 'BEST_PRACTICE'
    )),
    CONSTRAINT chk_compliance_status CHECK (compliance_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLIANT', 'NON_COMPLIANT', 'UNDER_REVIEW'
    )),
    CONSTRAINT chk_risk_level CHECK (risk_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    ))
);

-- 2. Dispute cases table
CREATE TABLE IF NOT EXISTS bms.dispute_cases (
    dispute_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID,
    unit_id UUID,
    
    -- Case information
    case_number VARCHAR(50) NOT NULL,
    dispute_type VARCHAR(30) NOT NULL,
    dispute_category VARCHAR(20) NOT NULL,
    dispute_title VARCHAR(200) NOT NULL,
    dispute_description TEXT NOT NULL,
    
    -- Parties involved
    complainant_type VARCHAR(20) NOT NULL,
    complainant_name VARCHAR(100),
    complainant_contact JSONB,
    
    respondent_type VARCHAR(20) NOT NULL,
    respondent_name VARCHAR(100),
    respondent_contact JSONB,
    
    -- Financial impact
    disputed_amount DECIMAL(15,2) DEFAULT 0,
    claimed_damages DECIMAL(15,2) DEFAULT 0,
    
    -- Case timeline
    dispute_date DATE DEFAULT CURRENT_DATE,
    filing_date DATE,
    response_deadline DATE,
    hearing_date DATE,
    resolution_date DATE,
    
    -- Case status
    dispute_status VARCHAR(20) DEFAULT 'OPEN',
    resolution_method VARCHAR(20),
    
    -- Legal representation
    legal_counsel_required BOOLEAN DEFAULT false,
    legal_counsel_assigned VARCHAR(200),
    legal_counsel_contact JSONB,
    
    -- Resolution details
    resolution_summary TEXT,
    settlement_amount DECIMAL(15,2) DEFAULT 0,
    resolution_terms JSONB,
    
    -- Documentation
    case_documents JSONB,
    evidence_files JSONB,
    correspondence_log JSONB,
    
    -- Staff assignment
    assigned_staff_id UUID,
    case_manager_id UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_disputes_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_disputes_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE SET NULL,
    CONSTRAINT fk_disputes_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE SET NULL,
    CONSTRAINT uk_disputes_case_number UNIQUE (company_id, case_number),
    
    -- Check constraints
    CONSTRAINT chk_dispute_type CHECK (dispute_type IN (
        'RENT_DISPUTE', 'DEPOSIT_DISPUTE', 'MAINTENANCE_DISPUTE', 'EVICTION',
        'LEASE_VIOLATION', 'PROPERTY_DAMAGE', 'NOISE_COMPLAINT', 'DISCRIMINATION',
        'HARASSMENT', 'BREACH_OF_CONTRACT', 'OTHER'
    )),
    CONSTRAINT chk_dispute_category CHECK (dispute_category IN (
        'FINANCIAL', 'CONTRACTUAL', 'BEHAVIORAL', 'PROPERTY', 'LEGAL'
    )),
    CONSTRAINT chk_complainant_type CHECK (complainant_type IN (
        'TENANT', 'LANDLORD', 'NEIGHBOR', 'THIRD_PARTY'
    )),
    CONSTRAINT chk_respondent_type CHECK (respondent_type IN (
        'TENANT', 'LANDLORD', 'PROPERTY_MANAGER', 'THIRD_PARTY'
    )),
    CONSTRAINT chk_dispute_status CHECK (dispute_status IN (
        'OPEN', 'UNDER_INVESTIGATION', 'MEDIATION', 'ARBITRATION', 
        'LITIGATION', 'RESOLVED', 'DISMISSED', 'WITHDRAWN'
    )),
    CONSTRAINT chk_resolution_method CHECK (resolution_method IN (
        'NEGOTIATION', 'MEDIATION', 'ARBITRATION', 'COURT_RULING', 'SETTLEMENT'
    ) OR resolution_method IS NULL),
    CONSTRAINT chk_financial_amounts CHECK (
        disputed_amount >= 0 AND claimed_damages >= 0 AND settlement_amount >= 0
    )
);

-- 3. Risk assessments table
CREATE TABLE IF NOT EXISTS bms.risk_assessments (
    assessment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    unit_id UUID,
    contract_id UUID,
    
    -- Assessment information
    assessment_type VARCHAR(30) NOT NULL,
    assessment_category VARCHAR(20) NOT NULL,
    assessment_title VARCHAR(200) NOT NULL,
    assessment_description TEXT,
    
    -- Risk details
    risk_factor VARCHAR(50) NOT NULL,
    risk_level VARCHAR(20) NOT NULL,
    probability_score INTEGER DEFAULT 0, -- 1-10 scale
    impact_score INTEGER DEFAULT 0, -- 1-10 scale
    overall_risk_score INTEGER DEFAULT 0, -- calculated field
    
    -- Financial impact
    potential_financial_impact DECIMAL(15,2) DEFAULT 0,
    mitigation_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Timeline
    assessment_date DATE DEFAULT CURRENT_DATE,
    review_frequency_months INTEGER DEFAULT 12,
    next_review_date DATE,
    
    -- Mitigation measures
    current_mitigation_measures TEXT,
    recommended_actions TEXT,
    action_priority VARCHAR(20) DEFAULT 'MEDIUM',
    action_deadline DATE,
    
    -- Status tracking
    assessment_status VARCHAR(20) DEFAULT 'ACTIVE',
    mitigation_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Responsible parties
    assessed_by UUID,
    responsible_staff_id UUID,
    
    -- Documentation
    supporting_evidence JSONB,
    mitigation_documents JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_risk_assessments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_risk_assessments_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_risk_assessments_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_risk_assessments_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_assessment_type CHECK (assessment_type IN (
        'TENANT_CREDIT_RISK', 'PAYMENT_DEFAULT_RISK', 'PROPERTY_DAMAGE_RISK',
        'LEGAL_COMPLIANCE_RISK', 'MARKET_RISK', 'OPERATIONAL_RISK',
        'INSURANCE_RISK', 'ENVIRONMENTAL_RISK', 'SAFETY_RISK', 'OTHER'
    )),
    CONSTRAINT chk_assessment_category CHECK (assessment_category IN (
        'FINANCIAL', 'OPERATIONAL', 'LEGAL', 'SAFETY', 'ENVIRONMENTAL'
    )),
    CONSTRAINT chk_risk_level CHECK (risk_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_action_priority CHECK (action_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT'
    )),
    CONSTRAINT chk_assessment_status CHECK (assessment_status IN (
        'ACTIVE', 'UNDER_REVIEW', 'RESOLVED', 'ARCHIVED'
    )),
    CONSTRAINT chk_mitigation_status CHECK (mitigation_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'DEFERRED'
    )),
    CONSTRAINT chk_scores CHECK (
        probability_score >= 0 AND probability_score <= 10 AND
        impact_score >= 0 AND impact_score <= 10 AND
        overall_risk_score >= 0 AND overall_risk_score <= 100
    ),
    CONSTRAINT chk_financial_impact CHECK (
        potential_financial_impact >= 0 AND mitigation_cost >= 0
    )
);

-- 4. Insurance policies table
CREATE TABLE IF NOT EXISTS bms.insurance_policies (
    policy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- Policy information
    policy_number VARCHAR(100) NOT NULL,
    policy_type VARCHAR(30) NOT NULL,
    policy_name VARCHAR(200) NOT NULL,
    
    -- Insurance provider
    insurance_company VARCHAR(200) NOT NULL,
    agent_name VARCHAR(100),
    agent_contact JSONB,
    
    -- Coverage details
    coverage_amount DECIMAL(15,2) NOT NULL,
    deductible_amount DECIMAL(15,2) DEFAULT 0,
    coverage_description TEXT,
    covered_risks JSONB,
    exclusions JSONB,
    
    -- Policy period
    policy_start_date DATE NOT NULL,
    policy_end_date DATE NOT NULL,
    renewal_date DATE,
    
    -- Premium information
    annual_premium DECIMAL(15,2) NOT NULL,
    payment_frequency VARCHAR(20) DEFAULT 'ANNUAL',
    last_payment_date DATE,
    next_payment_date DATE,
    
    -- Policy status
    policy_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Claims information
    claims_count INTEGER DEFAULT 0,
    total_claims_amount DECIMAL(15,2) DEFAULT 0,
    last_claim_date DATE,
    
    -- Documentation
    policy_documents JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_insurance_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_insurance_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_insurance_policy_number UNIQUE (company_id, policy_number),
    
    -- Check constraints
    CONSTRAINT chk_policy_type CHECK (policy_type IN (
        'PROPERTY_INSURANCE', 'LIABILITY_INSURANCE', 'LANDLORD_INSURANCE',
        'UMBRELLA_INSURANCE', 'WORKERS_COMPENSATION', 'CYBER_LIABILITY',
        'DIRECTORS_OFFICERS', 'BUSINESS_INTERRUPTION', 'OTHER'
    )),
    CONSTRAINT chk_payment_frequency CHECK (payment_frequency IN (
        'MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL'
    )),
    CONSTRAINT chk_policy_status CHECK (policy_status IN (
        'ACTIVE', 'EXPIRED', 'CANCELLED', 'SUSPENDED', 'PENDING_RENEWAL'
    )),
    CONSTRAINT chk_policy_dates CHECK (
        policy_end_date > policy_start_date
    ),
    CONSTRAINT chk_insurance_amounts CHECK (
        coverage_amount > 0 AND annual_premium > 0 AND
        deductible_amount >= 0 AND total_claims_amount >= 0 AND
        claims_count >= 0
    )
);