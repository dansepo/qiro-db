-- =====================================================
-- Contractor Management Functions
-- Phase 4.5.1: Contractor Management Functions and Procedures
-- =====================================================

-- 1. Function to register new contractor
CREATE OR REPLACE FUNCTION bms.register_contractor(
    p_company_id UUID,
    p_contractor_name VARCHAR(200),
    p_business_registration_number VARCHAR(20),
    p_business_type VARCHAR(30),
    p_contractor_type VARCHAR(30),
    p_category_id UUID,
    p_representative_name VARCHAR(100),
    p_contact_person VARCHAR(100) DEFAULT NULL,
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_email VARCHAR(100) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_specialization_areas JSONB DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_contractor_id UUID;
    v_contractor_code VARCHAR(50);
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Generate contractor code
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(contractor_code FROM 'CON-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.contractors 
    WHERE company_id = p_company_id 
      AND contractor_code LIKE 'CON-' || v_year || '-%';
    
    v_contractor_code := 'CON-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Insert contractor
    INSERT INTO bms.contractors (
        company_id, contractor_code, contractor_name,
        business_registration_number, business_type, contractor_type,
        category_id, representative_name, contact_person,
        phone_number, email, address, specialization_areas,
        registration_status, created_by
    ) VALUES (
        p_company_id, v_contractor_code, p_contractor_name,
        p_business_registration_number, p_business_type, p_contractor_type,
        p_category_id, p_representative_name, p_contact_person,
        p_phone_number, p_email, p_address, p_specialization_areas,
        'PENDING', p_created_by
    ) RETURNING contractor_id INTO v_contractor_id;
    
    RETURN v_contractor_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Function to approve contractor registration
CREATE OR REPLACE FUNCTION bms.approve_contractor_registration(
    p_contractor_id UUID,
    p_approved_by UUID,
    p_expiry_date DATE DEFAULT NULL,
    p_remarks TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE bms.contractors 
    SET 
        registration_status = 'APPROVED',
        contractor_status = 'ACTIVE',
        registration_date = NOW(),
        expiry_date = p_expiry_date,
        remarks = p_remarks,
        updated_by = p_approved_by,
        updated_at = NOW()
    WHERE contractor_id = p_contractor_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contractor not found: %', p_contractor_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 3. Function to add contractor license
CREATE OR REPLACE FUNCTION bms.add_contractor_license(
    p_contractor_id UUID,
    p_license_type VARCHAR(50),
    p_license_name VARCHAR(200),
    p_license_number VARCHAR(100),
    p_issuing_authority VARCHAR(200),
    p_issue_date DATE,
    p_expiry_date DATE DEFAULT NULL,
    p_is_permanent BOOLEAN DEFAULT FALSE,
    p_license_document_path VARCHAR(500) DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_license_id UUID;
    v_company_id UUID;
BEGIN
    -- Get company_id from contractor
    SELECT company_id INTO v_company_id
    FROM bms.contractors 
    WHERE contractor_id = p_contractor_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contractor not found: %', p_contractor_id;
    END IF;
    
    -- Insert license
    INSERT INTO bms.contractor_licenses (
        company_id, contractor_id, license_type, license_name,
        license_number, issuing_authority, issue_date, expiry_date,
        is_permanent, license_document_path, created_by
    ) VALUES (
        v_company_id, p_contractor_id, p_license_type, p_license_name,
        p_license_number, p_issuing_authority, p_issue_date, p_expiry_date,
        p_is_permanent, p_license_document_path, p_created_by
    ) RETURNING license_id INTO v_license_id;
    
    RETURN v_license_id;
END;
$$ LANGUAGE plpgsql;

-- Script completion message
SELECT 'Contractor Management Functions created successfully!' as status;