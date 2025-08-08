-- =====================================================
-- Contractor Management Test Data
-- Phase 4.5.1: Sample data for contractor management system
-- =====================================================

-- Set company context for testing
SET app.current_company_id = 'c1234567-89ab-cdef-0123-456789abcdef';

-- 1. Insert contractor categories
INSERT INTO bms.contractor_categories (
    company_id, category_code, category_name, category_description,
    required_licenses, required_certifications, required_insurances,
    minimum_experience_years, created_by
) VALUES 
-- 전기 공사업
('c1234567-89ab-cdef-0123-456789abcdef', 'ELEC', '전기공사업', '전기 설비 설치 및 유지보수',
 '["ELECTRICAL_LICENSE", "BUSINESS_LICENSE"]'::jsonb,
 '["ISO_9001", "SAFETY_CERTIFICATION"]'::jsonb,
 '["GENERAL_LIABILITY", "PROFESSIONAL_LIABILITY"]'::jsonb,
 3, '11234567-89ab-cdef-0123-456789abcdef'),

-- 배관 공사업
('c1234567-89ab-cdef-0123-456789abcdef', 'PLUMB', '배관공사업', '급수, 배수, 가스 배관 공사',
 '["PLUMBING_LICENSE", "BUSINESS_LICENSE"]'::jsonb,
 '["KS_CERTIFICATION", "SAFETY_CERTIFICATION"]'::jsonb,
 '["GENERAL_LIABILITY", "WORKERS_COMPENSATION"]'::jsonb,
 2, '11234567-89ab-cdef-0123-456789abcdef'),

-- 청소 서비스업
('c1234567-89ab-cdef-0123-456789abcdef', 'CLEAN', '청소서비스업', '건물 청소 및 위생 관리',
 '["BUSINESS_LICENSE"]'::jsonb,
 '["ENVIRONMENTAL_CERTIFICATION"]'::jsonb,
 '["GENERAL_LIABILITY", "WORKERS_COMPENSATION"]'::jsonb,
 1, '11234567-89ab-cdef-0123-456789abcdef');

-- 2. Register contractors using function
DO $$
DECLARE
    v_contractor_id_1 UUID;
    v_contractor_id_2 UUID;
    v_contractor_id_3 UUID;
    v_category_id UUID;
BEGIN
    -- Contractor 1: 전기공사업체
    SELECT category_id INTO v_category_id FROM bms.contractor_categories WHERE category_code = 'ELEC';
    
    SELECT bms.register_contractor(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '대한전기공사'::VARCHAR(200),
        '123-45-67890'::VARCHAR(20),
        'CORPORATION'::VARCHAR(30),
        'SPECIALIZED'::VARCHAR(30),
        v_category_id,
        '김전기'::VARCHAR(100),
        '이담당'::VARCHAR(100),
        '02-1234-5678'::VARCHAR(20),
        'contact@dahanelec.co.kr'::VARCHAR(100),
        '서울시 강남구 테헤란로 456'::TEXT,
        '{"specialties": ["전기설비", "조명시설", "비상전원"], "capacity": "대형건물"}'::jsonb,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    ) INTO v_contractor_id_1;
    
    -- Add license for contractor 1
    PERFORM bms.add_contractor_license(
        v_contractor_id_1,
        'ELECTRICAL_LICENSE'::VARCHAR(50),
        '전기공사업 면허'::VARCHAR(200),
        'ELEC-2020-001'::VARCHAR(100),
        '한국전기안전공사'::VARCHAR(200),
        '2020-01-15'::DATE,
        '2025-01-14'::DATE,
        FALSE,
        '/documents/licenses/elec_license_001.pdf'::VARCHAR(500),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    );
    
    -- Approve contractor 1
    PERFORM bms.approve_contractor_registration(
        v_contractor_id_1,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '2025-12-31'::DATE,
        '전기공사 전문업체로 승인'::TEXT
    );
    
    -- Contractor 2: 배관공사업체
    SELECT category_id INTO v_category_id FROM bms.contractor_categories WHERE category_code = 'PLUMB';
    
    SELECT bms.register_contractor(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '한국배관기술'::VARCHAR(200),
        '234-56-78901'::VARCHAR(20),
        'CORPORATION'::VARCHAR(30),
        'SPECIALIZED'::VARCHAR(30),
        v_category_id,
        '박배관'::VARCHAR(100),
        '최기술'::VARCHAR(100),
        '02-2345-6789'::VARCHAR(20),
        'info@koreaplumb.co.kr'::VARCHAR(100),
        '서울시 서초구 서초대로 789'::TEXT,
        '{"specialties": ["급수배관", "배수배관", "가스배관"], "capacity": "중대형건물"}'::jsonb,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    ) INTO v_contractor_id_2;
    
    -- Add license for contractor 2
    PERFORM bms.add_contractor_license(
        v_contractor_id_2,
        'PLUMBING_LICENSE'::VARCHAR(50),
        '배관공사업 면허'::VARCHAR(200),
        'PLUMB-2019-002'::VARCHAR(100),
        '한국가스안전공사'::VARCHAR(200),
        '2019-03-20'::DATE,
        '2024-03-19'::DATE,
        FALSE,
        '/documents/licenses/plumb_license_002.pdf'::VARCHAR(500),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    );
    
    -- Approve contractor 2
    PERFORM bms.approve_contractor_registration(
        v_contractor_id_2,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '2025-12-31'::DATE,
        '배관공사 전문업체로 승인'::TEXT
    );
    
    -- Contractor 3: 청소서비스업체
    SELECT category_id INTO v_category_id FROM bms.contractor_categories WHERE category_code = 'CLEAN';
    
    SELECT bms.register_contractor(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '깨끗한세상'::VARCHAR(200),
        '345-67-89012'::VARCHAR(20),
        'PARTNERSHIP'::VARCHAR(30),
        'GENERAL'::VARCHAR(30),
        v_category_id,
        '정청소'::VARCHAR(100),
        '김관리'::VARCHAR(100),
        '02-3456-7890'::VARCHAR(20),
        'service@cleanworld.co.kr'::VARCHAR(100),
        '서울시 마포구 월드컵로 123'::TEXT,
        '{"specialties": ["일반청소", "특수청소", "소독방역"], "capacity": "전체규모"}'::jsonb,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    ) INTO v_contractor_id_3;
    
    -- Approve contractor 3
    PERFORM bms.approve_contractor_registration(
        v_contractor_id_3,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '2025-12-31'::DATE,
        '청소서비스 업체로 승인'::TEXT
    );
END $$;

-- Script completion message
SELECT 'Contractor Management test data inserted successfully!' as status;