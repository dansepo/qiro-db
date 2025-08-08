-- =====================================================
-- Outsourcing Work Management Test Data
-- Phase 4.5.2: Sample data for outsourcing work management system
-- =====================================================

-- Set company context for testing
SET app.current_company_id = 'c1234567-89ab-cdef-0123-456789abcdef';

-- 1. Create outsourcing work requests using function
DO $$
DECLARE
    v_request_id_1 UUID;
    v_request_id_2 UUID;
    v_request_id_3 UUID;
    v_assignment_id_1 UUID;
    v_assignment_id_2 UUID;
    v_assignment_id_3 UUID;
    v_contractor_id UUID;
BEGIN
    -- Request 1: 전기 시설 점검
    SELECT bms.create_outsourcing_work_request(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '전기 시설 정기 점검'::VARCHAR(200),
        'INSPECTION'::VARCHAR(30),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '건물 전체 전기 시설의 정기 안전 점검 및 이상 유무 확인'::TEXT,
        '전체 건물'::VARCHAR(200),
        '2024-12-10'::DATE,
        '2024-12-12'::DATE,
        500000.00::DECIMAL(15,2),
        'HIGH'::VARCHAR(20),
        'NORMAL'::VARCHAR(20),
        (SELECT category_id FROM bms.contractor_categories WHERE category_code = 'ELEC')
    ) INTO v_request_id_1;
    
    -- Assign to contractor
    SELECT contractor_id INTO v_contractor_id 
    FROM bms.contractors 
    WHERE contractor_name = '대한전기공사';
    
    SELECT bms.assign_work_to_contractor(
        v_request_id_1,
        v_contractor_id,
        '2024-12-10'::DATE,
        '2024-12-12'::DATE,
        500000.00::DECIMAL(15,2),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '작업 완료 후 7일 내 지급'::VARCHAR(200),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    ) INTO v_assignment_id_1;
    
    -- Update progress
    PERFORM bms.update_work_progress(
        v_assignment_id_1,
        75.00::DECIMAL(5,2),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    );
    
    -- Request 2: 배관 수리 작업
    SELECT bms.create_outsourcing_work_request(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '화장실 배관 누수 수리'::VARCHAR(200),
        'REPAIR'::VARCHAR(30),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '3층 화장실 급수관 누수 수리 및 관련 배관 교체'::TEXT,
        '3층 화장실'::VARCHAR(200),
        '2024-12-08'::DATE,
        '2024-12-09'::DATE,
        300000.00::DECIMAL(15,2),
        'URGENT'::VARCHAR(20),
        'HIGH'::VARCHAR(20),
        (SELECT category_id FROM bms.contractor_categories WHERE category_code = 'PLUMB')
    ) INTO v_request_id_2;
    
    -- Assign to contractor
    SELECT contractor_id INTO v_contractor_id 
    FROM bms.contractors 
    WHERE contractor_name = '한국배관기술';
    
    SELECT bms.assign_work_to_contractor(
        v_request_id_2,
        v_contractor_id,
        '2024-12-08'::DATE,
        '2024-12-09'::DATE,
        300000.00::DECIMAL(15,2),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '작업 완료 후 즉시 지급'::VARCHAR(200),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    ) INTO v_assignment_id_2;
    
    -- Update progress to completed
    PERFORM bms.update_work_progress(
        v_assignment_id_2,
        100.00::DECIMAL(5,2),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    );
    
    -- Request 3: 청소 서비스
    SELECT bms.create_outsourcing_work_request(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '연말 대청소 서비스'::VARCHAR(200),
        'CLEANING'::VARCHAR(30),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '연말 대청소 및 왁스 코팅, 유리창 청소 포함'::TEXT,
        '전체 건물'::VARCHAR(200),
        '2024-12-28'::DATE,
        '2024-12-30'::DATE,
        800000.00::DECIMAL(15,2),
        'NORMAL'::VARCHAR(20),
        'NORMAL'::VARCHAR(20),
        (SELECT category_id FROM bms.contractor_categories WHERE category_code = 'CLEAN')
    ) INTO v_request_id_3;
    
    -- Assign to contractor
    SELECT contractor_id INTO v_contractor_id 
    FROM bms.contractors 
    WHERE contractor_name = '깨끗한세상';
    
    SELECT bms.assign_work_to_contractor(
        v_request_id_3,
        v_contractor_id,
        '2024-12-28'::DATE,
        '2024-12-30'::DATE,
        800000.00::DECIMAL(15,2),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '월말 결제'::VARCHAR(200),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID
    ) INTO v_assignment_id_3;
    
    -- Create inspection for completed work
    PERFORM bms.create_work_inspection(
        v_assignment_id_2,
        'FINAL'::VARCHAR(30),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '배관 수리 작업 완료 검수'::TEXT,
        'PASSED'::VARCHAR(20),
        95.00::DECIMAL(5,2),
        90.00::DECIMAL(5,2),
        NULL::TEXT,
        '작업 품질 우수, 향후 정기 점검 권장'::TEXT
    );
END $$;

-- 2. Insert work milestones
INSERT INTO bms.work_progress_milestones (
    company_id, assignment_id, milestone_number, milestone_name,
    milestone_description, planned_date, milestone_percentage,
    is_critical, milestone_status, created_by
) VALUES 
-- 전기 점검 마일스톤
('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT assignment_id FROM bms.outsourcing_work_assignments WHERE assignment_title = '전기 시설 정기 점검'),
 1, '점검 준비 완료', '점검 장비 준비 및 안전 교육 완료',
 '2024-12-10'::DATE, 25.00, FALSE, 'COMPLETED', '11234567-89ab-cdef-0123-456789abcdef'),

('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT assignment_id FROM bms.outsourcing_work_assignments WHERE assignment_title = '전기 시설 정기 점검'),
 2, '1-2층 점검 완료', '1층과 2층 전기 시설 점검 완료',
 '2024-12-11'::DATE, 50.00, FALSE, 'COMPLETED', '11234567-89ab-cdef-0123-456789abcdef'),

('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT assignment_id FROM bms.outsourcing_work_assignments WHERE assignment_title = '전기 시설 정기 점검'),
 3, '3-4층 점검 완료', '3층과 4층 전기 시설 점검 완료',
 '2024-12-12'::DATE, 75.00, FALSE, 'IN_PROGRESS', '11234567-89ab-cdef-0123-456789abcdef'),

('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT assignment_id FROM bms.outsourcing_work_assignments WHERE assignment_title = '전기 시설 정기 점검'),
 4, '점검 보고서 작성', '전체 점검 결과 보고서 작성 및 제출',
 '2024-12-12'::DATE, 100.00, TRUE, 'PLANNED', '11234567-89ab-cdef-0123-456789abcdef');

-- 3. Insert work issues
INSERT INTO bms.work_issue_tracking (
    company_id, assignment_id, issue_number, issue_title, issue_type,
    issue_description, issue_location, severity_level, impact_level,
    reported_by, discovered_date, issue_status, created_by
) VALUES 
-- 전기 점검 중 발견된 이슈
('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT assignment_id FROM bms.outsourcing_work_assignments WHERE assignment_title = '전기 시설 정기 점검'),
 'ISS-2024-001', '노후 전선 발견', 'SAFETY',
 '2층 복도 전선이 노후화되어 교체 필요', '2층 복도',
 'MEDIUM', 'MEDIUM', '11234567-89ab-cdef-0123-456789abcdef',
 '2024-12-11'::DATE, 'OPEN', '11234567-89ab-cdef-0123-456789abcdef'),

-- 배관 수리 중 발견된 이슈
('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT assignment_id FROM bms.outsourcing_work_assignments WHERE assignment_title = '화장실 배관 누수 수리'),
 'ISS-2024-002', '추가 배관 교체 필요', 'TECHNICAL',
 '수리 과정에서 인접 배관도 노후화 확인되어 추가 교체 필요', '3층 화장실',
 'LOW', 'LOW', '11234567-89ab-cdef-0123-456789abcdef',
 '2024-12-08'::DATE, 'RESOLVED', '11234567-89ab-cdef-0123-456789abcdef');

-- Update issue with resolution
UPDATE bms.work_issue_tracking 
SET 
    resolution_description = '인접 배관 2m 추가 교체 완료',
    resolution_date = '2024-12-09 14:30:00+09'::TIMESTAMP WITH TIME ZONE,
    resolved_by = '11234567-89ab-cdef-0123-456789abcdef',
    issue_status = 'RESOLVED',
    updated_at = NOW()
WHERE issue_number = 'ISS-2024-002';

-- Script completion message
SELECT 
    'Outsourcing Work Management test data inserted successfully!' as status,
    COUNT(DISTINCT owr.request_id) as work_requests,
    COUNT(DISTINCT owa.assignment_id) as work_assignments,
    COUNT(DISTINCT wpm.milestone_id) as milestones,
    COUNT(DISTINCT wir.inspection_id) as inspections,
    COUNT(DISTINCT wit.issue_id) as issues
FROM bms.outsourcing_work_requests owr
FULL OUTER JOIN bms.outsourcing_work_assignments owa ON owr.company_id = owa.company_id
FULL OUTER JOIN bms.work_progress_milestones wpm ON owa.assignment_id = wpm.assignment_id
FULL OUTER JOIN bms.work_inspection_records wir ON owa.assignment_id = wir.assignment_id
FULL OUTER JOIN bms.work_issue_tracking wit ON owa.assignment_id = wit.assignment_id
WHERE COALESCE(owr.company_id, owa.company_id) = 'c1234567-89ab-cdef-0123-456789abcdef';