-- =====================================================
-- Contractor Management System
-- Phase 4.5.1: Contractor Registration and Management Tables
-- =====================================================

-- 1. Contractor categories table
CREATE TABLE IF NOT EXISTS bms.contractor_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Category identification
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    
    -- Category hierarchy
    parent_category_id UUID,
    category_level INTEGER DEFAULT 1,
    category_path VARCHAR(500),
    
    -- Category requirements
    required_licenses JSONB,
    required_certifications JSONB,
    required_insurances JSONB,
    minimum_experience_years INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractor_categories_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_categories_parent FOREIGN KEY (parent_category_id) REFERENCES bms.contractor_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_contractor_categories_code UNIQUE (company_id, category_code),
    
    -- Check constraints
    CONSTRAINT chk_category_level CHECK (category_level >= 1 AND category_level <= 5),
    CONSTRAINT chk_minimum_experience CHECK (minimum_experience_years >= 0)
);

-- 2. Contractors table (extended from existing suppliers)
CREATE TABLE IF NOT EXISTS bms.contractors (
    contractor_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Basic information
    contractor_code VARCHAR(50) NOT NULL,
    contractor_name VARCHAR(200) NOT NULL,
    contractor_name_en VARCHAR(200),
    business_registration_number VARCHAR(20) NOT NULL,
    
    -- Business type
    business_type VARCHAR(30) NOT NULL,
    contractor_type VARCHAR(30) NOT NULL,
    category_id UUID NOT NULL,
    
    -- Contact information
    representative_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    phone_number VARCHAR(20),
    mobile_number VARCHAR(20),
    fax_number VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(200),
    
    -- Address
    address TEXT NOT NULL,
    postal_code VARCHAR(10),
    city VARCHAR(50),
    state VARCHAR(50),
    country VARCHAR(50) DEFAULT 'KR',
    
    -- Business details
    establishment_date DATE,
    capital_amount DECIMAL(15,2),
    annual_revenue DECIMAL(15,2),
    employee_count INTEGER,
    
    -- Specialization
    specialization_areas JSONB,
    service_regions JSONB,
    work_capacity JSONB,
    
    -- Financial information
    credit_rating VARCHAR(10),
    financial_status VARCHAR(20) DEFAULT 'NORMAL',
    
    -- Registration status
    registration_status VARCHAR(20) DEFAULT 'PENDING',
    registration_date TIMESTAMP WITH TIME ZONE,
    expiry_date DATE,
    
    -- Evaluation
    overall_rating DECIMAL(3,2) DEFAULT 0,
    performance_grade VARCHAR(10),
    
    -- Status
    contractor_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Notes
    remarks TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractors_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractors_category FOREIGN KEY (category_id) REFERENCES bms.contractor_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT uk_contractors_code UNIQUE (company_id, contractor_code),
    CONSTRAINT uk_contractors_business_reg UNIQUE (company_id, business_registration_number),
    
    -- Check constraints
    CONSTRAINT chk_business_type CHECK (business_type IN (
        'CORPORATION', 'PARTNERSHIP', 'SOLE_PROPRIETORSHIP', 'COOPERATIVE', 'OTHER'
    )),
    CONSTRAINT chk_contractor_type CHECK (contractor_type IN (
        'GENERAL', 'SPECIALIZED', 'SUBCONTRACTOR', 'CONSULTANT', 'SUPPLIER'
    )),
    CONSTRAINT chk_registration_status CHECK (registration_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED', 'EXPIRED'
    )),
    CONSTRAINT chk_financial_status CHECK (financial_status IN (
        'EXCELLENT', 'GOOD', 'NORMAL', 'POOR', 'CRITICAL'
    )),
    CONSTRAINT chk_contractor_status CHECK (contractor_status IN (
        'ACTIVE', 'INACTIVE', 'SUSPENDED', 'BLACKLISTED', 'TERMINATED'
    )),
    CONSTRAINT chk_overall_rating CHECK (overall_rating >= 0 AND overall_rating <= 5),
    CONSTRAINT chk_performance_grade CHECK (performance_grade IN (
        'A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F'
    )),
    CONSTRAINT chk_capital_amount CHECK (capital_amount >= 0),
    CONSTRAINT chk_annual_revenue CHECK (annual_revenue >= 0),
    CONSTRAINT chk_employee_count CHECK (employee_count >= 0)
);

-- 3. Contractor licenses table
CREATE TABLE IF NOT EXISTS bms.contractor_licenses (
    license_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contractor_id UUID NOT NULL,
    
    -- License information
    license_type VARCHAR(50) NOT NULL,
    license_name VARCHAR(200) NOT NULL,
    license_number VARCHAR(100) NOT NULL,
    
    -- Issuing authority
    issuing_authority VARCHAR(200) NOT NULL,
    issuing_country VARCHAR(50) DEFAULT 'KR',
    
    -- Validity
    issue_date DATE NOT NULL,
    expiry_date DATE,
    is_permanent BOOLEAN DEFAULT FALSE,
    
    -- Status
    license_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID,
    verification_date TIMESTAMP WITH TIME ZONE,
    verification_notes TEXT,
    
    -- Documents
    license_document_path VARCHAR(500),
    
    -- Notes
    license_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractor_licenses_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_licenses_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_licenses_verified_by FOREIGN KEY (verified_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_contractor_licenses_number UNIQUE (company_id, contractor_id, license_number),
    
    -- Check constraints
    CONSTRAINT chk_license_type CHECK (license_type IN (
        'BUSINESS_LICENSE', 'CONSTRUCTION_LICENSE', 'ELECTRICAL_LICENSE', 'PLUMBING_LICENSE',
        'HVAC_LICENSE', 'SAFETY_LICENSE', 'ENVIRONMENTAL_LICENSE', 'PROFESSIONAL_LICENSE', 'OTHER'
    )),
    CONSTRAINT chk_license_status CHECK (license_status IN (
        'ACTIVE', 'EXPIRED', 'SUSPENDED', 'REVOKED', 'PENDING_RENEWAL'
    )),
    CONSTRAINT chk_expiry_date CHECK (is_permanent = TRUE OR expiry_date IS NOT NULL)
);

-- 4. Contractor certifications table
CREATE TABLE IF NOT EXISTS bms.contractor_certifications (
    certification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contractor_id UUID NOT NULL,
    
    -- Certification information
    certification_type VARCHAR(50) NOT NULL,
    certification_name VARCHAR(200) NOT NULL,
    certification_number VARCHAR(100),
    
    -- Certifying body
    certifying_body VARCHAR(200) NOT NULL,
    certification_standard VARCHAR(100),
    
    -- Validity
    certification_date DATE NOT NULL,
    expiry_date DATE,
    is_permanent BOOLEAN DEFAULT FALSE,
    
    -- Status
    certification_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID,
    verification_date TIMESTAMP WITH TIME ZONE,
    verification_notes TEXT,
    
    -- Documents
    certification_document_path VARCHAR(500),
    
    -- Notes
    certification_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractor_certifications_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_certifications_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_certifications_verified_by FOREIGN KEY (verified_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_certification_type CHECK (certification_type IN (
        'ISO_9001', 'ISO_14001', 'ISO_45001', 'KS_CERTIFICATION', 'GREEN_BUILDING',
        'SAFETY_CERTIFICATION', 'QUALITY_CERTIFICATION', 'ENVIRONMENTAL_CERTIFICATION', 'OTHER'
    )),
    CONSTRAINT chk_certification_status CHECK (certification_status IN (
        'ACTIVE', 'EXPIRED', 'SUSPENDED', 'REVOKED', 'PENDING_RENEWAL'
    )),
    CONSTRAINT chk_cert_expiry_date CHECK (is_permanent = TRUE OR expiry_date IS NOT NULL)
);

-- 5. Contractor insurances table
CREATE TABLE IF NOT EXISTS bms.contractor_insurances (
    insurance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contractor_id UUID NOT NULL,
    
    -- Insurance information
    insurance_type VARCHAR(50) NOT NULL,
    insurance_name VARCHAR(200) NOT NULL,
    policy_number VARCHAR(100) NOT NULL,
    
    -- Insurance company
    insurance_company VARCHAR(200) NOT NULL,
    
    -- Coverage
    coverage_amount DECIMAL(15,2) NOT NULL,
    deductible_amount DECIMAL(15,2) DEFAULT 0,
    coverage_details JSONB,
    
    -- Validity
    effective_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    
    -- Status
    insurance_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by UUID,
    verification_date TIMESTAMP WITH TIME ZONE,
    verification_notes TEXT,
    
    -- Documents
    insurance_document_path VARCHAR(500),
    
    -- Notes
    insurance_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractor_insurances_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_insurances_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_insurances_verified_by FOREIGN KEY (verified_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_contractor_insurances_policy UNIQUE (company_id, contractor_id, policy_number),
    
    -- Check constraints
    CONSTRAINT chk_insurance_type CHECK (insurance_type IN (
        'GENERAL_LIABILITY', 'PROFESSIONAL_LIABILITY', 'WORKERS_COMPENSATION',
        'PROPERTY_INSURANCE', 'VEHICLE_INSURANCE', 'CYBER_LIABILITY', 'OTHER'
    )),
    CONSTRAINT chk_insurance_status CHECK (insurance_status IN (
        'ACTIVE', 'EXPIRED', 'CANCELLED', 'SUSPENDED', 'PENDING_RENEWAL'
    )),
    CONSTRAINT chk_coverage_amount CHECK (coverage_amount > 0),
    CONSTRAINT chk_deductible_amount CHECK (deductible_amount >= 0),
    CONSTRAINT chk_insurance_dates CHECK (expiry_date > effective_date)
);

-- 6. Contractor evaluations table
CREATE TABLE IF NOT EXISTS bms.contractor_evaluations (
    evaluation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contractor_id UUID NOT NULL,
    
    -- Evaluation identification
    evaluation_number VARCHAR(50) NOT NULL,
    evaluation_title VARCHAR(200) NOT NULL,
    evaluation_type VARCHAR(30) NOT NULL,
    evaluation_period_start DATE NOT NULL,
    evaluation_period_end DATE NOT NULL,
    
    -- Evaluator information
    evaluator_id UUID NOT NULL,
    evaluation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Evaluation criteria scores (0-100)
    quality_score DECIMAL(5,2) DEFAULT 0,
    schedule_score DECIMAL(5,2) DEFAULT 0,
    cost_score DECIMAL(5,2) DEFAULT 0,
    safety_score DECIMAL(5,2) DEFAULT 0,
    communication_score DECIMAL(5,2) DEFAULT 0,
    technical_score DECIMAL(5,2) DEFAULT 0,
    
    -- Overall evaluation
    total_score DECIMAL(5,2) DEFAULT 0,
    weighted_score DECIMAL(5,2) DEFAULT 0,
    evaluation_grade VARCHAR(10),
    
    -- Detailed feedback
    strengths TEXT,
    weaknesses TEXT,
    improvement_recommendations TEXT,
    
    -- Reference projects
    reference_projects JSONB,
    
    -- Status
    evaluation_status VARCHAR(20) DEFAULT 'DRAFT',
    
    -- Approval
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractor_evaluations_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_evaluations_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_evaluations_evaluator FOREIGN KEY (evaluator_id) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_contractor_evaluations_approved_by FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_contractor_evaluations_number UNIQUE (company_id, evaluation_number),
    
    -- Check constraints
    CONSTRAINT chk_evaluation_type CHECK (evaluation_type IN (
        'INITIAL', 'ANNUAL', 'PROJECT_BASED', 'INCIDENT_BASED', 'RENEWAL'
    )),
    CONSTRAINT chk_evaluation_scores CHECK (
        quality_score >= 0 AND quality_score <= 100 AND
        schedule_score >= 0 AND schedule_score <= 100 AND
        cost_score >= 0 AND cost_score <= 100 AND
        safety_score >= 0 AND safety_score <= 100 AND
        communication_score >= 0 AND communication_score <= 100 AND
        technical_score >= 0 AND technical_score <= 100 AND
        total_score >= 0 AND total_score <= 100 AND
        weighted_score >= 0 AND weighted_score <= 100
    ),
    CONSTRAINT chk_evaluation_grade CHECK (evaluation_grade IN (
        'A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F'
    )),
    CONSTRAINT chk_evaluation_status CHECK (evaluation_status IN (
        'DRAFT', 'SUBMITTED', 'APPROVED', 'REJECTED'
    )),
    CONSTRAINT chk_evaluation_period CHECK (evaluation_period_end >= evaluation_period_start)
);

-- 7. Contractor contracts table
CREATE TABLE IF NOT EXISTS bms.contractor_contracts (
    contract_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contractor_id UUID NOT NULL,
    
    -- Contract identification
    contract_number VARCHAR(50) NOT NULL,
    contract_title VARCHAR(200) NOT NULL,
    contract_type VARCHAR(30) NOT NULL,
    
    -- Contract details
    contract_description TEXT,
    scope_of_work TEXT NOT NULL,
    
    -- Financial terms
    contract_amount DECIMAL(15,2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'KRW',
    payment_terms VARCHAR(200),
    
    -- Timeline
    contract_date DATE NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    
    -- Performance terms
    performance_bond_required BOOLEAN DEFAULT FALSE,
    performance_bond_amount DECIMAL(15,2),
    warranty_period INTEGER, -- months
    penalty_terms TEXT,
    
    -- Status
    contract_status VARCHAR(20) DEFAULT 'DRAFT',
    
    -- Approval
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    
    -- Documents
    contract_document_path VARCHAR(500),
    
    -- Notes
    contract_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractor_contracts_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_contracts_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_contracts_approved_by FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_contractor_contracts_number UNIQUE (company_id, contract_number),
    
    -- Check constraints
    CONSTRAINT chk_contract_type CHECK (contract_type IN (
        'SERVICE', 'MAINTENANCE', 'CONSTRUCTION', 'SUPPLY', 'CONSULTING', 'FRAMEWORK'
    )),
    CONSTRAINT chk_contract_status CHECK (contract_status IN (
        'DRAFT', 'PENDING_APPROVAL', 'ACTIVE', 'COMPLETED', 'TERMINATED', 'EXPIRED'
    )),
    CONSTRAINT chk_contract_amount CHECK (contract_amount >= 0),
    CONSTRAINT chk_performance_bond CHECK (
        (performance_bond_required = FALSE) OR 
        (performance_bond_required = TRUE AND performance_bond_amount > 0)
    ),
    CONSTRAINT chk_warranty_period CHECK (warranty_period IS NULL OR warranty_period >= 0),
    CONSTRAINT chk_contract_dates CHECK (end_date >= start_date)
);

-- 8. Contractor performance history table
CREATE TABLE IF NOT EXISTS bms.contractor_performance_history (
    performance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contractor_id UUID NOT NULL,
    
    -- Performance period
    performance_year INTEGER NOT NULL,
    performance_quarter INTEGER,
    
    -- Project statistics
    total_projects INTEGER DEFAULT 0,
    completed_projects INTEGER DEFAULT 0,
    on_time_projects INTEGER DEFAULT 0,
    within_budget_projects INTEGER DEFAULT 0,
    
    -- Financial performance
    total_contract_value DECIMAL(15,2) DEFAULT 0,
    total_paid_amount DECIMAL(15,2) DEFAULT 0,
    average_project_value DECIMAL(15,2) DEFAULT 0,
    
    -- Quality metrics
    quality_incidents INTEGER DEFAULT 0,
    safety_incidents INTEGER DEFAULT 0,
    customer_complaints INTEGER DEFAULT 0,
    
    -- Performance ratios
    on_time_delivery_rate DECIMAL(5,2) DEFAULT 0,
    budget_adherence_rate DECIMAL(5,2) DEFAULT 0,
    quality_score_average DECIMAL(5,2) DEFAULT 0,
    
    -- Overall assessment
    performance_rating DECIMAL(3,2) DEFAULT 0,
    performance_grade VARCHAR(10),
    
    -- Notes
    performance_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_performance_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_performance_history_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE CASCADE,
    CONSTRAINT uk_performance_history UNIQUE (company_id, contractor_id, performance_year, performance_quarter),
    
    -- Check constraints
    CONSTRAINT chk_performance_quarter CHECK (performance_quarter IS NULL OR (performance_quarter >= 1 AND performance_quarter <= 4)),
    CONSTRAINT chk_project_counts CHECK (
        total_projects >= 0 AND completed_projects >= 0 AND
        on_time_projects >= 0 AND within_budget_projects >= 0 AND
        completed_projects <= total_projects AND
        on_time_projects <= completed_projects AND
        within_budget_projects <= completed_projects
    ),
    CONSTRAINT chk_financial_amounts CHECK (
        total_contract_value >= 0 AND total_paid_amount >= 0 AND
        average_project_value >= 0 AND total_paid_amount <= total_contract_value
    ),
    CONSTRAINT chk_incident_counts CHECK (
        quality_incidents >= 0 AND safety_incidents >= 0 AND customer_complaints >= 0
    ),
    CONSTRAINT chk_performance_rates CHECK (
        on_time_delivery_rate >= 0 AND on_time_delivery_rate <= 100 AND
        budget_adherence_rate >= 0 AND budget_adherence_rate <= 100 AND
        quality_score_average >= 0 AND quality_score_average <= 100
    ),
    CONSTRAINT chk_performance_rating CHECK (performance_rating >= 0 AND performance_rating <= 5),
    CONSTRAINT chk_performance_grade CHECK (performance_grade IN (
        'A+', 'A', 'B+', 'B', 'C+', 'C', 'D', 'F'
    ))
);

-- 9. Contractor blacklist table
CREATE TABLE IF NOT EXISTS bms.contractor_blacklist (
    blacklist_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contractor_id UUID NOT NULL,
    
    -- Blacklist information
    blacklist_reason VARCHAR(50) NOT NULL,
    blacklist_description TEXT NOT NULL,
    
    -- Incident details
    incident_date DATE,
    incident_reference VARCHAR(100),
    severity_level VARCHAR(20) NOT NULL,
    
    -- Blacklist period
    blacklist_start_date DATE NOT NULL,
    blacklist_end_date DATE,
    is_permanent BOOLEAN DEFAULT FALSE,
    
    -- Decision maker
    decided_by UUID NOT NULL,
    decision_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    decision_notes TEXT,
    
    -- Review information
    review_required BOOLEAN DEFAULT TRUE,
    next_review_date DATE,
    reviewed_by UUID,
    review_date TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    
    -- Status
    blacklist_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_contractor_blacklist_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_blacklist_contractor FOREIGN KEY (contractor_id) REFERENCES bms.contractors(contractor_id) ON DELETE CASCADE,
    CONSTRAINT fk_contractor_blacklist_decided_by FOREIGN KEY (decided_by) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_contractor_blacklist_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_blacklist_reason CHECK (blacklist_reason IN (
        'POOR_PERFORMANCE', 'SAFETY_VIOLATION', 'FRAUD', 'BREACH_OF_CONTRACT',
        'QUALITY_ISSUES', 'LEGAL_ISSUES', 'FINANCIAL_PROBLEMS', 'OTHER'
    )),
    CONSTRAINT chk_severity_level CHECK (severity_level IN (
        'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_blacklist_status CHECK (blacklist_status IN (
        'ACTIVE', 'EXPIRED', 'LIFTED', 'UNDER_REVIEW'
    )),
    CONSTRAINT chk_blacklist_dates CHECK (
        (is_permanent = TRUE) OR 
        (is_permanent = FALSE AND blacklist_end_date IS NOT NULL AND blacklist_end_date > blacklist_start_date)
    )
);

-- 10. RLS policies and indexes
ALTER TABLE bms.contractor_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractors ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractor_licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractor_certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractor_insurances ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractor_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractor_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractor_performance_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.contractor_blacklist ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY contractor_categories_isolation_policy ON bms.contractor_categories
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractors_isolation_policy ON bms.contractors
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractor_licenses_isolation_policy ON bms.contractor_licenses
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractor_certifications_isolation_policy ON bms.contractor_certifications
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractor_insurances_isolation_policy ON bms.contractor_insurances
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractor_evaluations_isolation_policy ON bms.contractor_evaluations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractor_contracts_isolation_policy ON bms.contractor_contracts
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractor_performance_history_isolation_policy ON bms.contractor_performance_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY contractor_blacklist_isolation_policy ON bms.contractor_blacklist
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for contractor_categories
CREATE INDEX IF NOT EXISTS idx_contractor_categories_company_id ON bms.contractor_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_contractor_categories_code ON bms.contractor_categories(category_code);
CREATE INDEX IF NOT EXISTS idx_contractor_categories_parent ON bms.contractor_categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_contractor_categories_active ON bms.contractor_categories(is_active);

-- Performance indexes for contractors
CREATE INDEX IF NOT EXISTS idx_contractors_company_id ON bms.contractors(company_id);
CREATE INDEX IF NOT EXISTS idx_contractors_code ON bms.contractors(contractor_code);
CREATE INDEX IF NOT EXISTS idx_contractors_name ON bms.contractors(contractor_name);
CREATE INDEX IF NOT EXISTS idx_contractors_business_reg ON bms.contractors(business_registration_number);
CREATE INDEX IF NOT EXISTS idx_contractors_category ON bms.contractors(category_id);
CREATE INDEX IF NOT EXISTS idx_contractors_type ON bms.contractors(contractor_type);
CREATE INDEX IF NOT EXISTS idx_contractors_status ON bms.contractors(contractor_status);
CREATE INDEX IF NOT EXISTS idx_contractors_registration_status ON bms.contractors(registration_status);
CREATE INDEX IF NOT EXISTS idx_contractors_rating ON bms.contractors(overall_rating);
CREATE INDEX IF NOT EXISTS idx_contractors_grade ON bms.contractors(performance_grade);

-- Performance indexes for contractor_licenses
CREATE INDEX IF NOT EXISTS idx_contractor_licenses_company_id ON bms.contractor_licenses(company_id);
CREATE INDEX IF NOT EXISTS idx_contractor_licenses_contractor_id ON bms.contractor_licenses(contractor_id);
CREATE INDEX IF NOT EXISTS idx_contractor_licenses_type ON bms.contractor_licenses(license_type);
CREATE INDEX IF NOT EXISTS idx_contractor_licenses_status ON bms.contractor_licenses(license_status);
CREATE INDEX IF NOT EXISTS idx_contractor_licenses_expiry ON bms.contractor_licenses(expiry_date);
CREATE INDEX IF NOT EXISTS idx_contractor_licenses_verified ON bms.contractor_licenses(is_verified);

-- Performance indexes for contractor_certifications
CREATE INDEX IF NOT EXISTS idx_contractor_certifications_company_id ON bms.contractor_certifications(company_id);
CREATE INDEX IF NOT EXISTS idx_contractor_certifications_contractor_id ON bms.contractor_certifications(contractor_id);
CREATE INDEX IF NOT EXISTS idx_contractor_certifications_type ON bms.contractor_certifications(certification_type);
CREATE INDEX IF NOT EXISTS idx_contractor_certifications_status ON bms.contractor_certifications(certification_status);
CREATE INDEX IF NOT EXISTS idx_contractor_certifications_expiry ON bms.contractor_certifications(expiry_date);

-- Performance indexes for contractor_insurances
CREATE INDEX IF NOT EXISTS idx_contractor_insurances_company_id ON bms.contractor_insurances(company_id);
CREATE INDEX IF NOT EXISTS idx_contractor_insurances_contractor_id ON bms.contractor_insurances(contractor_id);
CREATE INDEX IF NOT EXISTS idx_contractor_insurances_type ON bms.contractor_insurances(insurance_type);
CREATE INDEX IF NOT EXISTS idx_contractor_insurances_status ON bms.contractor_insurances(insurance_status);
CREATE INDEX IF NOT EXISTS idx_contractor_insurances_expiry ON bms.contractor_insurances(expiry_date);

-- Performance indexes for contractor_evaluations
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_company_id ON bms.contractor_evaluations(company_id);
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_contractor_id ON bms.contractor_evaluations(contractor_id);
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_number ON bms.contractor_evaluations(evaluation_number);
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_type ON bms.contractor_evaluations(evaluation_type);
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_date ON bms.contractor_evaluations(evaluation_date);
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_status ON bms.contractor_evaluations(evaluation_status);
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_grade ON bms.contractor_evaluations(evaluation_grade);

-- Performance indexes for contractor_contracts
CREATE INDEX IF NOT EXISTS idx_contractor_contracts_company_id ON bms.contractor_contracts(company_id);
CREATE INDEX IF NOT EXISTS idx_contractor_contracts_contractor_id ON bms.contractor_contracts(contractor_id);
CREATE INDEX IF NOT EXISTS idx_contractor_contracts_number ON bms.contractor_contracts(contract_number);
CREATE INDEX IF NOT EXISTS idx_contractor_contracts_type ON bms.contractor_contracts(contract_type);
CREATE INDEX IF NOT EXISTS idx_contractor_contracts_status ON bms.contractor_contracts(contract_status);
CREATE INDEX IF NOT EXISTS idx_contractor_contracts_dates ON bms.contractor_contracts(start_date, end_date);

-- Performance indexes for contractor_performance_history
CREATE INDEX IF NOT EXISTS idx_performance_history_company_id ON bms.contractor_performance_history(company_id);
CREATE INDEX IF NOT EXISTS idx_performance_history_contractor_id ON bms.contractor_performance_history(contractor_id);
CREATE INDEX IF NOT EXISTS idx_performance_history_year ON bms.contractor_performance_history(performance_year);
CREATE INDEX IF NOT EXISTS idx_performance_history_quarter ON bms.contractor_performance_history(performance_quarter);
CREATE INDEX IF NOT EXISTS idx_performance_history_rating ON bms.contractor_performance_history(performance_rating);

-- Performance indexes for contractor_blacklist
CREATE INDEX IF NOT EXISTS idx_contractor_blacklist_company_id ON bms.contractor_blacklist(company_id);
CREATE INDEX IF NOT EXISTS idx_contractor_blacklist_contractor_id ON bms.contractor_blacklist(contractor_id);
CREATE INDEX IF NOT EXISTS idx_contractor_blacklist_status ON bms.contractor_blacklist(blacklist_status);
CREATE INDEX IF NOT EXISTS idx_contractor_blacklist_dates ON bms.contractor_blacklist(blacklist_start_date, blacklist_end_date);
CREATE INDEX IF NOT EXISTS idx_contractor_blacklist_reason ON bms.contractor_blacklist(blacklist_reason);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_contractors_category_status ON bms.contractors(category_id, contractor_status);
CREATE INDEX IF NOT EXISTS idx_contractor_licenses_contractor_status ON bms.contractor_licenses(contractor_id, license_status);
CREATE INDEX IF NOT EXISTS idx_contractor_evaluations_contractor_date ON bms.contractor_evaluations(contractor_id, evaluation_date);

-- Updated_at triggers
CREATE TRIGGER contractor_categories_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_categories
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractors_updated_at_trigger
    BEFORE UPDATE ON bms.contractors
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractor_licenses_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_licenses
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractor_certifications_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_certifications
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractor_insurances_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_insurances
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractor_evaluations_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_evaluations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractor_contracts_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_contracts
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractor_performance_history_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_performance_history
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER contractor_blacklist_updated_at_trigger
    BEFORE UPDATE ON bms.contractor_blacklist
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.contractor_categories IS 'Contractor categories - Classification of contractor types and specializations';
COMMENT ON TABLE bms.contractors IS 'Contractors - Registered contractors and service providers';
COMMENT ON TABLE bms.contractor_licenses IS 'Contractor licenses - Business and professional licenses';
COMMENT ON TABLE bms.contractor_certifications IS 'Contractor certifications - Quality and professional certifications';
COMMENT ON TABLE bms.contractor_insurances IS 'Contractor insurances - Insurance coverage and policies';
COMMENT ON TABLE bms.contractor_evaluations IS 'Contractor evaluations - Performance evaluations and ratings';
COMMENT ON TABLE bms.contractor_contracts IS 'Contractor contracts - Service contracts and agreements';
COMMENT ON TABLE bms.contractor_performance_history IS 'Contractor performance history - Historical performance metrics';
COMMENT ON TABLE bms.contractor_blacklist IS 'Contractor blacklist - Suspended or banned contractors';

-- Script completion message
SELECT 'Contractor Management System tables created successfully!' as status;