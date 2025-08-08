-- =====================================================
-- Legal Management and Dispute Resolution Indexes and RLS
-- Phase 3.7: Legal Management Indexes and Security
-- =====================================================

-- RLS policies
ALTER TABLE bms.legal_compliance_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.dispute_cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.risk_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.insurance_policies ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY legal_compliance_isolation_policy ON bms.legal_compliance_requirements
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY dispute_cases_isolation_policy ON bms.dispute_cases
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY risk_assessments_isolation_policy ON bms.risk_assessments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY insurance_policies_isolation_policy ON bms.insurance_policies
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for legal_compliance_requirements
CREATE INDEX IF NOT EXISTS idx_legal_compliance_company_id ON bms.legal_compliance_requirements(company_id);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_building_id ON bms.legal_compliance_requirements(building_id);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_type ON bms.legal_compliance_requirements(requirement_type);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_status ON bms.legal_compliance_requirements(compliance_status);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_deadline ON bms.legal_compliance_requirements(compliance_deadline);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_risk_level ON bms.legal_compliance_requirements(risk_level);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_active ON bms.legal_compliance_requirements(is_active);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_responsible ON bms.legal_compliance_requirements(responsible_staff_id);

-- Performance indexes for dispute_cases
CREATE INDEX IF NOT EXISTS idx_dispute_cases_company_id ON bms.dispute_cases(company_id);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_contract_id ON bms.dispute_cases(contract_id);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_unit_id ON bms.dispute_cases(unit_id);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_type ON bms.dispute_cases(dispute_type);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_category ON bms.dispute_cases(dispute_category);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_status ON bms.dispute_cases(dispute_status);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_date ON bms.dispute_cases(dispute_date);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_filing_date ON bms.dispute_cases(filing_date);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_resolution_date ON bms.dispute_cases(resolution_date);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_assigned ON bms.dispute_cases(assigned_staff_id);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_case_manager ON bms.dispute_cases(case_manager_id);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_case_number ON bms.dispute_cases(case_number);

-- Performance indexes for risk_assessments
CREATE INDEX IF NOT EXISTS idx_risk_assessments_company_id ON bms.risk_assessments(company_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_building_id ON bms.risk_assessments(building_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_unit_id ON bms.risk_assessments(unit_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_contract_id ON bms.risk_assessments(contract_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_type ON bms.risk_assessments(assessment_type);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_category ON bms.risk_assessments(assessment_category);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_risk_level ON bms.risk_assessments(risk_level);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_status ON bms.risk_assessments(assessment_status);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_mitigation_status ON bms.risk_assessments(mitigation_status);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_assessment_date ON bms.risk_assessments(assessment_date);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_review_date ON bms.risk_assessments(next_review_date);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_action_deadline ON bms.risk_assessments(action_deadline);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_assessed_by ON bms.risk_assessments(assessed_by);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_responsible ON bms.risk_assessments(responsible_staff_id);

-- Performance indexes for insurance_policies
CREATE INDEX IF NOT EXISTS idx_insurance_policies_company_id ON bms.insurance_policies(company_id);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_building_id ON bms.insurance_policies(building_id);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_type ON bms.insurance_policies(policy_type);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_status ON bms.insurance_policies(policy_status);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_start_date ON bms.insurance_policies(policy_start_date);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_end_date ON bms.insurance_policies(policy_end_date);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_renewal_date ON bms.insurance_policies(renewal_date);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_payment_date ON bms.insurance_policies(next_payment_date);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_policy_number ON bms.insurance_policies(policy_number);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_insurance_company ON bms.insurance_policies(insurance_company);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_legal_compliance_company_status ON bms.legal_compliance_requirements(company_id, compliance_status);
CREATE INDEX IF NOT EXISTS idx_legal_compliance_company_deadline ON bms.legal_compliance_requirements(company_id, compliance_deadline);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_company_status ON bms.dispute_cases(company_id, dispute_status);
CREATE INDEX IF NOT EXISTS idx_dispute_cases_company_type ON bms.dispute_cases(company_id, dispute_type);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_company_level ON bms.risk_assessments(company_id, risk_level);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_company_status ON bms.risk_assessments(company_id, assessment_status);
CREATE INDEX IF NOT EXISTS idx_insurance_policies_company_status ON bms.insurance_policies(company_id, policy_status);

-- Updated_at triggers
CREATE TRIGGER legal_compliance_updated_at_trigger
    BEFORE UPDATE ON bms.legal_compliance_requirements
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER dispute_cases_updated_at_trigger
    BEFORE UPDATE ON bms.dispute_cases
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER risk_assessments_updated_at_trigger
    BEFORE UPDATE ON bms.risk_assessments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER insurance_policies_updated_at_trigger
    BEFORE UPDATE ON bms.insurance_policies
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.legal_compliance_requirements IS 'Legal compliance requirements - Tracking legal and regulatory compliance requirements';
COMMENT ON TABLE bms.dispute_cases IS 'Dispute cases - Management of legal disputes and resolution processes';
COMMENT ON TABLE bms.risk_assessments IS 'Risk assessments - Comprehensive risk assessment and mitigation tracking';
COMMENT ON TABLE bms.insurance_policies IS 'Insurance policies - Insurance policy management and monitoring';

-- Script completion message
SELECT 'Legal management indexes and RLS policies created successfully.' as message;