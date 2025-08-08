-- =====================================================
-- Material Master Management Functions
-- Phase 4.4.1: Material Master Management Functions
-- =====================================================

-- 1. Create material function
CREATE OR REPLACE FUNCTION bms.create_material(
    p_company_id UUID,
    p_material_code VARCHAR(50),
    p_material_name VARCHAR(200),
    p_material_description TEXT,
    p_category_id UUID,
    p_material_type VARCHAR(30),
    p_base_unit_id UUID,
    p_brand VARCHAR(100) DEFAULT NULL,
    p_model_number VARCHAR(100) DEFAULT NULL,
    p_part_number VARCHAR(100) DEFAULT NULL,
    p_specifications JSONB DEFAULT NULL,
    p_standard_cost DECIMAL(12,2) DEFAULT 0,
    p_minimum_stock_level DECIMAL(10,3) DEFAULT 0,
    p_reorder_point DECIMAL(10,3) DEFAULT 0,
    p_reorder_quantity DECIMAL(10,3) DEFAULT 0,
    p_primary_supplier_id UUID DEFAULT NULL,
    p_lead_time_days INTEGER DEFAULT 7,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_material_id UUID;
    v_category RECORD;
    v_unit RECORD;
BEGIN
    -- Validate category
    SELECT * INTO v_category
    FROM bms.material_categories
    WHERE category_id = p_category_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Material category not found: %', p_category_id;
    END IF;
    
    -- Validate unit
    SELECT * INTO v_unit
    FROM bms.material_units
    WHERE unit_id = p_base_unit_id AND company_id = p_company_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Material unit not found: %', p_base_unit_id;
    END IF;
    
    -- Create material
    INSERT INTO bms.materials (
        company_id,
        material_code,
        material_name,
        material_description,
        category_id,
        material_type,
        base_unit_id,
        brand,
        model_number,
        part_number,
        specifications,
        standard_cost,
        minimum_stock_level,
        reorder_point,
        reorder_quantity,
        primary_supplier_id,
        lead_time_days,
        created_by
    ) VALUES (
        p_company_id,
        p_material_code,
        p_material_name,
        p_material_description,
        p_category_id,
        p_material_type,
        p_base_unit_id,
        p_brand,
        p_model_number,
        p_part_number,
        p_specifications,
        p_standard_cost,
        p_minimum_stock_level,
        p_reorder_point,
        p_reorder_quantity,
        p_primary_supplier_id,
        p_lead_time_days,
        p_created_by
    ) RETURNING material_id INTO v_material_id;
    
    -- Create primary supplier relationship if provided
    IF p_primary_supplier_id IS NOT NULL THEN
        INSERT INTO bms.material_suppliers (
            company_id,
            material_id,
            supplier_id,
            supplier_priority,
            is_primary_supplier,
            lead_time_days,
            created_by
        ) VALUES (
            p_company_id,
            v_material_id,
            p_primary_supplier_id,
            1,
            true,
            p_lead_time_days,
            p_created_by
        );
    END IF;
    
    RETURN v_material_id;
END;
$$;

-- 2. Create supplier function
CREATE OR REPLACE FUNCTION bms.create_supplier(
    p_company_id UUID,
    p_supplier_code VARCHAR(20),
    p_supplier_name VARCHAR(200),
    p_supplier_type VARCHAR(30),
    p_contact_person VARCHAR(100) DEFAULT NULL,
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_email VARCHAR(100) DEFAULT NULL,
    p_address_line1 VARCHAR(200) DEFAULT NULL,
    p_city VARCHAR(100) DEFAULT NULL,
    p_business_category VARCHAR(50) DEFAULT NULL,
    p_payment_terms VARCHAR(100) DEFAULT NULL,
    p_lead_time_days INTEGER DEFAULT 7,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_supplier_id UUID;
BEGIN
    -- Create supplier
    INSERT INTO bms.suppliers (
        company_id,
        supplier_code,
        supplier_name,
        supplier_type,
        contact_person,
        phone_number,
        email,
        address_line1,
        city,
        business_category,
        payment_terms,
        lead_time_days,
        created_by
    ) VALUES (
        p_company_id,
        p_supplier_code,
        p_supplier_name,
        p_supplier_type,
        p_contact_person,
        p_phone_number,
        p_email,
        p_address_line1,
        p_city,
        p_business_category,
        p_payment_terms,
        p_lead_time_days,
        p_created_by
    ) RETURNING supplier_id INTO v_supplier_id;
    
    RETURN v_supplier_id;
END;
$$;

-- 3. Add material supplier relationship function
CREATE OR REPLACE FUNCTION bms.add_material_supplier(
    p_material_id UUID,
    p_supplier_id UUID,
    p_unit_price DECIMAL(12,2),
    p_supplier_priority INTEGER DEFAULT 2,
    p_minimum_order_quantity DECIMAL(10,3) DEFAULT 0,
    p_lead_time_days INTEGER DEFAULT 7,
    p_payment_terms VARCHAR(100) DEFAULT NULL,
    p_is_primary_supplier BOOLEAN DEFAULT FALSE,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_material_supplier_id UUID;
    v_material RECORD;
    v_supplier RECORD;
BEGIN
    -- Get material information
    SELECT * INTO v_material
    FROM bms.materials
    WHERE material_id = p_material_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Material not found: %', p_material_id;
    END IF;
    
    -- Get supplier information
    SELECT * INTO v_supplier
    FROM bms.suppliers
    WHERE supplier_id = p_supplier_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Supplier not found: %', p_supplier_id;
    END IF;
    
    -- If this is set as primary supplier, update existing primary
    IF p_is_primary_supplier THEN
        UPDATE bms.material_suppliers
        SET is_primary_supplier = false
        WHERE material_id = p_material_id AND is_primary_supplier = true;
        
        -- Update material's primary supplier
        UPDATE bms.materials
        SET primary_supplier_id = p_supplier_id
        WHERE material_id = p_material_id;
    END IF;
    
    -- Create or update material supplier relationship
    INSERT INTO bms.material_suppliers (
        company_id,
        material_id,
        supplier_id,
        supplier_priority,
        is_primary_supplier,
        unit_price,
        minimum_order_quantity,
        lead_time_days,
        payment_terms,
        created_by
    ) VALUES (
        v_material.company_id,
        p_material_id,
        p_supplier_id,
        p_supplier_priority,
        p_is_primary_supplier,
        p_unit_price,
        p_minimum_order_quantity,
        p_lead_time_days,
        p_payment_terms,
        p_created_by
    ) 
    ON CONFLICT (company_id, material_id, supplier_id)
    DO UPDATE SET
        supplier_priority = EXCLUDED.supplier_priority,
        is_primary_supplier = EXCLUDED.is_primary_supplier,
        unit_price = EXCLUDED.unit_price,
        minimum_order_quantity = EXCLUDED.minimum_order_quantity,
        lead_time_days = EXCLUDED.lead_time_days,
        payment_terms = EXCLUDED.payment_terms,
        updated_by = p_created_by,
        updated_at = NOW()
    RETURNING material_supplier_id INTO v_material_supplier_id;
    
    RETURN v_material_supplier_id;
END;
$$;-- 4.
 Get materials with filters function
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

-- 5. Get suppliers with filters function
CREATE OR REPLACE FUNCTION bms.get_suppliers(
    p_company_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_supplier_type VARCHAR(30) DEFAULT NULL,
    p_supplier_status VARCHAR(20) DEFAULT NULL,
    p_search_text VARCHAR(200) DEFAULT NULL
) RETURNS TABLE (
    supplier_id UUID,
    supplier_code VARCHAR(20),
    supplier_name VARCHAR(200),
    supplier_type VARCHAR(30),
    supplier_status VARCHAR(20),
    contact_person VARCHAR(100),
    phone_number VARCHAR(20),
    email VARCHAR(100),
    city VARCHAR(100),
    business_category VARCHAR(50),
    quality_rating DECIMAL(3,1),
    on_time_delivery_rate DECIMAL(5,2),
    total_orders INTEGER,
    total_order_value DECIMAL(15,2),
    total_count BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.supplier_id,
        s.supplier_code,
        s.supplier_name,
        s.supplier_type,
        s.supplier_status,
        s.contact_person,
        s.phone_number,
        s.email,
        s.city,
        s.business_category,
        s.quality_rating,
        s.on_time_delivery_rate,
        s.total_orders,
        s.total_order_value,
        COUNT(*) OVER() as total_count
    FROM bms.suppliers s
    WHERE s.company_id = p_company_id
        AND (p_supplier_type IS NULL OR s.supplier_type = p_supplier_type)
        AND (p_supplier_status IS NULL OR s.supplier_status = p_supplier_status)
        AND (p_search_text IS NULL OR 
             s.supplier_name ILIKE '%' || p_search_text || '%' OR
             s.supplier_code ILIKE '%' || p_search_text || '%' OR
             s.contact_person ILIKE '%' || p_search_text || '%')
    ORDER BY s.supplier_name
    LIMIT p_limit OFFSET p_offset;
END;
$$;

-- 6. Get material suppliers function
CREATE OR REPLACE FUNCTION bms.get_material_suppliers(
    p_material_id UUID
) RETURNS TABLE (
    material_supplier_id UUID,
    supplier_id UUID,
    supplier_code VARCHAR(20),
    supplier_name VARCHAR(200),
    supplier_priority INTEGER,
    is_primary_supplier BOOLEAN,
    unit_price DECIMAL(12,2),
    currency VARCHAR(3),
    minimum_order_quantity DECIMAL(10,3),
    lead_time_days INTEGER,
    quality_rating DECIMAL(3,1),
    delivery_performance DECIMAL(5,2),
    relationship_status VARCHAR(20)
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ms.material_supplier_id,
        ms.supplier_id,
        s.supplier_code,
        s.supplier_name,
        ms.supplier_priority,
        ms.is_primary_supplier,
        ms.unit_price,
        ms.currency,
        ms.minimum_order_quantity,
        ms.lead_time_days,
        ms.quality_rating,
        ms.delivery_performance,
        ms.relationship_status
    FROM bms.material_suppliers ms
    JOIN bms.suppliers s ON ms.supplier_id = s.supplier_id
    WHERE ms.material_id = p_material_id
        AND ms.relationship_status = 'ACTIVE'
    ORDER BY ms.supplier_priority, s.supplier_name;
END;
$$;

-- 7. Update material cost function
CREATE OR REPLACE FUNCTION bms.update_material_cost(
    p_material_id UUID,
    p_new_cost DECIMAL(12,2),
    p_cost_type VARCHAR(20) DEFAULT 'STANDARD',
    p_updated_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_material RECORD;
    v_old_cost DECIMAL(12,2);
BEGIN
    -- Get current material information
    SELECT * INTO v_material
    FROM bms.materials
    WHERE material_id = p_material_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Material not found: %', p_material_id;
    END IF;
    
    -- Update cost based on type
    CASE p_cost_type
        WHEN 'STANDARD' THEN
            v_old_cost := v_material.standard_cost;
            UPDATE bms.materials
            SET standard_cost = p_new_cost,
                updated_by = p_updated_by
            WHERE material_id = p_material_id;
            
        WHEN 'LAST_PURCHASE' THEN
            v_old_cost := v_material.last_purchase_cost;
            UPDATE bms.materials
            SET last_purchase_cost = p_new_cost,
                updated_by = p_updated_by
            WHERE material_id = p_material_id;
            
        WHEN 'AVERAGE' THEN
            v_old_cost := v_material.average_cost;
            UPDATE bms.materials
            SET average_cost = p_new_cost,
                updated_by = p_updated_by
            WHERE material_id = p_material_id;
            
        WHEN 'LIST_PRICE' THEN
            v_old_cost := v_material.list_price;
            UPDATE bms.materials
            SET list_price = p_new_cost,
                updated_by = p_updated_by
            WHERE material_id = p_material_id;
            
        ELSE
            RAISE EXCEPTION 'Invalid cost type: %', p_cost_type;
    END CASE;
    
    RETURN TRUE;
END;
$$;

-- 8. Get material statistics function
CREATE OR REPLACE FUNCTION bms.get_material_statistics(
    p_company_id UUID,
    p_category_id UUID DEFAULT NULL
) RETURNS TABLE (
    total_materials BIGINT,
    active_materials BIGINT,
    inactive_materials BIGINT,
    materials_by_type JSONB,
    materials_by_category JSONB,
    suppliers_count BIGINT,
    active_suppliers BIGINT,
    avg_material_cost DECIMAL(12,2),
    materials_needing_reorder BIGINT,
    materials_without_supplier BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    WITH material_stats AS (
        SELECT 
            COUNT(*) as total_materials,
            COUNT(*) FILTER (WHERE material_status = 'ACTIVE') as active_materials,
            COUNT(*) FILTER (WHERE material_status != 'ACTIVE') as inactive_materials,
            AVG(standard_cost) FILTER (WHERE standard_cost > 0) as avg_material_cost,
            COUNT(*) FILTER (WHERE primary_supplier_id IS NULL) as materials_without_supplier
        FROM bms.materials m
        WHERE m.company_id = p_company_id
            AND (p_category_id IS NULL OR m.category_id = p_category_id)
    ),
    type_stats AS (
        SELECT jsonb_object_agg(material_type, count) as materials_by_type
        FROM (
            SELECT material_type, COUNT(*) as count
            FROM bms.materials m
            WHERE m.company_id = p_company_id
                AND (p_category_id IS NULL OR m.category_id = p_category_id)
            GROUP BY material_type
        ) t
    ),
    category_stats AS (
        SELECT jsonb_object_agg(category_name, count) as materials_by_category
        FROM (
            SELECT mc.category_name, COUNT(*) as count
            FROM bms.materials m
            JOIN bms.material_categories mc ON m.category_id = mc.category_id
            WHERE m.company_id = p_company_id
                AND (p_category_id IS NULL OR m.category_id = p_category_id)
            GROUP BY mc.category_name
        ) t
    ),
    supplier_stats AS (
        SELECT 
            COUNT(DISTINCT s.supplier_id) as suppliers_count,
            COUNT(DISTINCT s.supplier_id) FILTER (WHERE s.supplier_status = 'ACTIVE') as active_suppliers
        FROM bms.suppliers s
        WHERE s.company_id = p_company_id
    )
    SELECT 
        ms.total_materials,
        ms.active_materials,
        ms.inactive_materials,
        ts.materials_by_type,
        cs.materials_by_category,
        ss.suppliers_count,
        ss.active_suppliers,
        ms.avg_material_cost,
        0::BIGINT as materials_needing_reorder, -- Placeholder for inventory integration
        ms.materials_without_supplier
    FROM material_stats ms
    CROSS JOIN type_stats ts
    CROSS JOIN category_stats cs
    CROSS JOIN supplier_stats ss;
END;
$$;

-- Comments
COMMENT ON FUNCTION bms.create_material IS 'Create new material with specifications and supplier relationship';
COMMENT ON FUNCTION bms.create_supplier IS 'Create new supplier with contact and business information';
COMMENT ON FUNCTION bms.add_material_supplier IS 'Add or update supplier relationship for material';
COMMENT ON FUNCTION bms.get_materials IS 'Get materials with filtering and pagination';
COMMENT ON FUNCTION bms.get_suppliers IS 'Get suppliers with filtering and pagination';
COMMENT ON FUNCTION bms.get_material_suppliers IS 'Get all suppliers for a specific material';
COMMENT ON FUNCTION bms.update_material_cost IS 'Update material cost with history tracking';
COMMENT ON FUNCTION bms.get_material_statistics IS 'Get comprehensive material and supplier statistics';

-- Script completion message
SELECT 'Material master management functions created successfully.' as message;