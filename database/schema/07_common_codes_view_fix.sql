-- =====================================================
-- 공통 코드 뷰 수정
-- =====================================================

-- 9. 공통 코드 뷰 생성 (계층 구조 포함) - 수정
CREATE OR REPLACE VIEW bms.v_common_codes_hierarchy AS
WITH RECURSIVE code_hierarchy AS (
    -- 최상위 코드들
    SELECT 
        c.code_id,
        c.company_id,
        c.group_id,
        g.group_code,
        g.group_name,
        c.code_value,
        c.code_name,
        c.code_description,
        c.parent_code_id,
        c.depth_level,
        c.sort_path,
        c.display_order,
        c.extra_attributes,
        c.is_active,
        c.effective_start_date,
        c.effective_end_date,
        ARRAY[c.code_name::VARCHAR] as hierarchy_path,
        c.code_name::VARCHAR as full_path
    FROM bms.common_codes c
    JOIN bms.code_groups g ON c.group_id = g.group_id
    WHERE c.parent_code_id IS NULL
    
    UNION ALL
    
    -- 하위 코드들
    SELECT 
        c.code_id,
        c.company_id,
        c.group_id,
        ch.group_code,
        ch.group_name,
        c.code_value,
        c.code_name,
        c.code_description,
        c.parent_code_id,
        c.depth_level,
        c.sort_path,
        c.display_order,
        c.extra_attributes,
        c.is_active,
        c.effective_start_date,
        c.effective_end_date,
        ch.hierarchy_path || ARRAY[c.code_name::VARCHAR],
        ch.full_path || ' > ' || c.code_name
    FROM bms.common_codes c
    JOIN code_hierarchy ch ON c.parent_code_id = ch.code_id
)
SELECT * FROM code_hierarchy
ORDER BY group_code, sort_path, display_order;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_common_codes_hierarchy OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 공통 코드 계층 뷰가 수정되었습니다!' as result;