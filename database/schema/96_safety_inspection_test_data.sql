-- =====================================================
-- Safety Inspection Management Test Data
-- Phase 4.7.1: Sample data for safety inspection management system
-- =====================================================

-- Set company context for testing
SET app.current_company_id = 'c1234567-89ab-cdef-0123-456789abcdef';

-- 1. Insert safety inspection categories
INSERT INTO bms.safety_inspection_categories (
    company_id, category_code, category_name, category_description,
    category_type, regulatory_basis, inspection_frequency,
    mandatory_inspection, required_qualifications, created_by
) VALUES 
-- 소방 안전 점검
('c1234567-89ab-cdef-0123-456789abcdef', 'FIRE_001', '소방시설 정기점검', '소방시설의 정기적인 안전점검',
 'FIRE_SAFETY', '소방시설 설치유지 및 안전관리에 관한 법률', 'MONTHLY',
 TRUE, '["소방안전관리자", "소방시설관리사"]'::jsonb, '11234567-89ab-cdef-0123-456789abcdef'),

-- 전기 안전 점검
('c1234567-89ab-cdef-0123-456789abcdef', 'ELEC_001', '전기시설 안전점검', '전기시설의 안전상태 점검',
 'ELECTRICAL_SAFETY', '전기사업법', 'QUARTERLY',
 TRUE, '["전기안전관리자", "전기기술자"]'::jsonb, '11234567-89ab-cdef-0123-456789abcdef'),

-- 구조물 안전 점검
('c1234567-89ab-cdef-0123-456789abcdef', 'STRUCT_001', '건축물 구조안전점검', '건축물의 구조적 안전성 점검',
 'STRUCTURAL_SAFETY', '건축법', 'ANNUAL',
 TRUE, '["건축구조기술사", "건축안전점검자"]'::jsonb, '11234567-89ab-cdef-0123-456789abcdef'),

-- 엘리베이터 안전 점검
('c1234567-89ab-cdef-0123-456789abcdef', 'ELEV_001', '승강기 안전점검', '승강기 시설의 안전점검',
 'ELEVATOR_SAFETY', '승강기 안전관리법', 'MONTHLY',
 TRUE, '["승강기안전관리자", "승강기검사원"]'::jsonb, '11234567-89ab-cdef-0123-456789abcdef');

-- 2. Create safety inspection schedules
DO $$
DECLARE
    v_schedule_id_1 UUID;
    v_schedule_id_2 UUID;
    v_schedule_id_3 UUID;
    v_inspection_id_1 UUID;
    v_inspection_id_2 UUID;
    v_incident_id_1 UUID;
BEGIN
    -- Schedule 1: 소방시설 월간 점검
    SELECT bms.create_safety_inspection_schedule(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '소방시설 월간 정기점검'::VARCHAR(200),
        (SELECT category_id FROM bms.safety_inspection_categories WHERE category_code = 'FIRE_001'),
        '건물 전체 소방시설 점검 (소화기, 스프링클러, 화재경보기 등)'::TEXT,
        'MONTHLY'::VARCHAR(20),
        1::INTEGER,
        'MONTHS'::VARCHAR(20),
        '2024-12-15'::DATE,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        NULL::UUID
    ) INTO v_schedule_id_1;
    
    -- Schedule 2: 전기시설 분기 점검
    SELECT bms.create_safety_inspection_schedule(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '전기시설 분기별 안전점검'::VARCHAR(200),
        (SELECT category_id FROM bms.safety_inspection_categories WHERE category_code = 'ELEC_001'),
        '전기 배전반, 접지시설, 누전차단기 등 전기시설 전반 점검'::TEXT,
        'QUARTERLY'::VARCHAR(20),
        1::INTEGER,
        'MONTHS'::VARCHAR(20),
        '2024-12-20'::DATE,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        NULL::UUID
    ) INTO v_schedule_id_2;
    
    -- Schedule 3: 엘리베이터 월간 점검
    SELECT bms.create_safety_inspection_schedule(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '승강기 월간 안전점검'::VARCHAR(200),
        (SELECT category_id FROM bms.safety_inspection_categories WHERE category_code = 'ELEV_001'),
        '승강기 기계실, 승강로, 카 내부 안전장치 점검'::TEXT,
        'MONTHLY'::VARCHAR(20),
        1::INTEGER,
        'MONTHS'::VARCHAR(20),
        '2024-12-10'::DATE,
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        NULL::UUID
    ) INTO v_schedule_id_3;
    
    -- Create safety inspections
    SELECT bms.create_safety_inspection(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '12월 소방시설 정기점검'::VARCHAR(200),
        (SELECT category_id FROM bms.safety_inspection_categories WHERE category_code = 'FIRE_001'),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '건물 전체 소방시설 점검'::TEXT,
        '2024-12-05'::DATE,
        v_schedule_id_1,
        NULL::UUID
    ) INTO v_inspection_id_1;
    
    SELECT bms.create_safety_inspection(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '4분기 전기시설 안전점검'::VARCHAR(200),
        (SELECT category_id FROM bms.safety_inspection_categories WHERE category_code = 'ELEC_001'),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '전기시설 전반 안전점검'::TEXT,
        '2024-12-03'::DATE,
        v_schedule_id_2,
        NULL::UUID
    ) INTO v_inspection_id_2;
    
    -- Complete inspections
    PERFORM bms.complete_safety_inspection(
        v_inspection_id_1,
        'PASSED'::VARCHAR(20),
        25::INTEGER,
        23::INTEGER,
        2::INTEGER,
        0::INTEGER,
        1::INTEGER,
        1::INTEGER,
        92.0::DECIMAL(5,2),
        NULL::TEXT,
        '소화기 2개 교체 필요'::TEXT,
        '정기적인 소방시설 점검 지속 필요'::TEXT
    );
    
    PERFORM bms.complete_safety_inspection(
        v_inspection_id_2,
        'CONDITIONAL'::VARCHAR(20),
        15::INTEGER,
        12::INTEGER,
        3::INTEGER,
        1::INTEGER,
        2::INTEGER,
        0::INTEGER,
        80.0::DECIMAL(5,2),
        '누전차단기 즉시 교체'::TEXT,
        '전기 배선 노후 부분 교체, 접지 저항 측정'::TEXT,
        '전기안전 교육 실시 권장'::TEXT
    );
    
    -- Report safety incident
    SELECT bms.report_safety_incident(
        'c1234567-89ab-cdef-0123-456789abcdef'::UUID,
        '복도 미끄러짐 사고'::VARCHAR(200),
        'SLIP_FALL'::VARCHAR(30),
        '2층 복도'::VARCHAR(200),
        '청소 후 물기 제거가 불충분하여 직원이 미끄러져 넘어짐'::TEXT,
        'MINOR'::VARCHAR(20),
        '11234567-89ab-cdef-0123-456789abcdef'::UUID,
        '2024-12-01'::DATE,
        NULL::UUID,
        1::INTEGER,
        FALSE::BOOLEAN
    ) INTO v_incident_id_1;
END $$;

-- 3. Insert safety inspection items for completed inspections
INSERT INTO bms.safety_inspection_items (
    company_id, inspection_id, item_number, item_name,
    item_description, inspection_criteria, inspection_result,
    issue_severity, issue_description, created_by
) VALUES 
-- 소방시설 점검 항목들
('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT inspection_id FROM bms.safety_inspections WHERE inspection_title = '12월 소방시설 정기점검'),
 1, '소화기 점검', '각 층별 소화기 상태 점검',
 '소화기 압력, 안전핀, 호스 상태 확인', 'FAIL',
 'MINOR', '1층 소화기 2개 압력 부족', '11234567-89ab-cdef-0123-456789abcdef'),

('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT inspection_id FROM bms.safety_inspections WHERE inspection_title = '12월 소방시설 정기점검'),
 2, '화재경보기 점검', '화재감지기 및 경보벨 작동 점검',
 '감지기 작동 테스트, 경보음 확인', 'PASS',
 'NONE', NULL, '11234567-89ab-cdef-0123-456789abcdef'),

('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT inspection_id FROM bms.safety_inspections WHERE inspection_title = '12월 소방시설 정기점검'),
 3, '스프링클러 점검', '스프링클러 헤드 및 배관 점검',
 '헤드 막힘, 배관 누수 여부 확인', 'PASS',
 'NONE', NULL, '11234567-89ab-cdef-0123-456789abcdef'),

-- 전기시설 점검 항목들
('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT inspection_id FROM bms.safety_inspections WHERE inspection_title = '4분기 전기시설 안전점검'),
 1, '누전차단기 점검', '누전차단기 작동 상태 점검',
 '누전차단기 동작 테스트, 접점 상태 확인', 'FAIL',
 'CRITICAL', '지하 배전반 누전차단기 동작 불량', '11234567-89ab-cdef-0123-456789abcdef'),

('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT inspection_id FROM bms.safety_inspections WHERE inspection_title = '4분기 전기시설 안전점검'),
 2, '접지 저항 측정', '접지 시설의 저항값 측정',
 '접지 저항 10Ω 이하 유지', 'FAIL',
 'MAJOR', '접지 저항 15Ω으로 기준 초과', '11234567-89ab-cdef-0123-456789abcdef'),

('c1234567-89ab-cdef-0123-456789abcdef',
 (SELECT inspection_id FROM bms.safety_inspections WHERE inspection_title = '4분기 전기시설 안전점검'),
 3, '배전반 점검', '배전반 내부 상태 점검',
 '단자 접속 상태, 절연 상태 확인', 'PASS',
 'NONE', NULL, '11234567-89ab-cdef-0123-456789abcdef');

-- Update incident with investigation details
UPDATE bms.safety_incidents 
SET 
    incident_cause = '청소 후 바닥 건조 시간 부족',
    contributing_factors = '미끄럼 방지 표시 부족, 청소 절차 미준수',
    immediate_actions_taken = '부상자 응급처치, 해당 구역 통행 차단',
    corrective_actions_required = '청소 후 충분한 건조 시간 확보, 미끄럼 방지 표시 설치',
    preventive_measures = '청소 절차 개선, 직원 안전 교육 강화',
    incident_status = 'INVESTIGATION_COMPLETE',
    investigation_completion_date = '2024-12-03',
    investigation_findings = '청소 절차 미준수로 인한 안전사고',
    updated_at = NOW()
WHERE incident_title = '복도 미끄러짐 사고';

-- Script completion message
SELECT 
    'Safety Inspection Management test data inserted successfully!' as status,
    COUNT(DISTINCT sic.category_id) as categories,
    COUNT(DISTINCT sis.schedule_id) as schedules,
    COUNT(DISTINCT si.inspection_id) as inspections,
    COUNT(DISTINCT sii.item_id) as inspection_items,
    COUNT(DISTINCT sinc.incident_id) as incidents
FROM bms.safety_inspection_categories sic
FULL OUTER JOIN bms.safety_inspection_schedules sis ON sic.company_id = sis.company_id
FULL OUTER JOIN bms.safety_inspections si ON sic.company_id = si.company_id
FULL OUTER JOIN bms.safety_inspection_items sii ON si.inspection_id = sii.inspection_id
FULL OUTER JOIN bms.safety_incidents sinc ON sic.company_id = sinc.company_id
WHERE COALESCE(sic.company_id, sis.company_id, si.company_id, sinc.company_id) = 'c1234567-89ab-cdef-0123-456789abcdef';