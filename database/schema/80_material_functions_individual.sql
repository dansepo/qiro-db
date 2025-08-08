-- =====================================================
-- Individual Material Master Functions
-- Phase 4.4.1: Individual Function Creation
-- =====================================================

-- Get materials with filters function
CREATE OR REPLACE FUNCTION bms.get_materials(
    p_company_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_category_id UUID DEFAULT NULL,
    p_material_type VARCHAR(30) DEFAULT NULL,
    p_material_status VARCHAR(20) DEFAULT NULL,
    p_supplier_id UUID DEFAULT NULL,
    p_search_text VARCHAR(200) DEFAULT NULL
) RETURNS TABLE (
    material_id UUID,
    material_code VARCHAR(50),
    material_name VARCHAR(200),
    material_description TEXT,
    category_name VARCHAR(100),
    material_type VARCHAR(30),
    material_status VARCHAR(20),
    brand VARCHAR(100),
    model_number VARCHAR(100),
    part_number VARCHAR(100),
    base_unit_name VARCHAR(50),
    standard_cost DECIMAL(12,2),
    minimum_stock_level DECIMAL(10,3),
    reorder_point DECIMAL(10,3),
    primary_supplier_name VARCHAR(200),
    lead_time_days INTEGER,
    total_count BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.material_id,
        m.material_code,
        m.material_name,
        m.material_description,
        mc.category_name,
        m.material_type,
        m.material_status,
        m.brand,
        m.model_number,
        m.part_number,
        mu.unit_name as base_unit_name,
        m.standard_cost,
        m.minimum_stock_level,
        m.reorder_point,
        s.supplier_name as primary_supplier_name,
        m.lead_time_days,
        COUNT(*) OVER() as total_count
    FROM bms.materials m
    LEFT JOIN bms.material_categories mc ON m.category_id = mc.category_id
    LEFT JOIN bms.material_units mu ON m.base_unit_id = mu.unit_id
    LEFT JOIN bms.suppliers s ON m.primary_supplier_id = s.supplier_id
    WHERE m.company_id = p_company_id
        AND (p_category_id IS NULL OR m.category_id = p_category_id)
        AND (p_material_type IS NULL OR m.material_type = p_material_type)
        AND (p_material_status IS NULL OR m.material_status = p_material_status)
        AND (p_supplier_id IS NULL OR m.primary_supplier_id = p_supplier_id)
        AND (p_search_text IS NULL OR 
             m.material_name ILIKE '%' || p_search_text || '%' OR
             m.material_code ILIKE '%' || p_search_text || '%' OR
             m.brand ILIKE '%' || p_search_text || '%' OR
             m.model_number ILIKE '%' || p_search_text || '%')
    ORDER BY m.material_code
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- Comments
COMMENT ON FUNCTION bms.get_materials IS 'Get materials with filtering and pagination';

-- Script completion message
SELECT 'Individual material functions created successfully.' as message;