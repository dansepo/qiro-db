-- =====================================================
-- Missing Material Master Tables
-- Phase 4.4.1: Create missing tables
-- =====================================================

-- Materials master table
CREATE TABLE IF NOT EXISTS bms.materials (
    material_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Material identification
    material_code VARCHAR(50) NOT NULL,
    material_name VARCHAR(200) NOT NULL,
    material_description TEXT,
    category_id UUID NOT NULL,
    
    -- Material classification
    material_type VARCHAR(30) NOT NULL,
    material_group VARCHAR(50),
    brand VARCHAR(100),
    model_number VARCHAR(100),
    part_number VARCHAR(100),
    
    -- Physical specifications
    specifications JSONB,
    dimensions JSONB,
    weight DECIMAL(10,3),
    color VARCHAR(50),
    material_composition TEXT,
    
    -- Unit information
    base_unit_id UUID NOT NULL,
    purchase_unit_id UUID,
    stock_unit_id UUID,
    
    -- Pricing information
    standard_cost DECIMAL(12,2) DEFAULT 0,
    last_purchase_cost DECIMAL(12,2) DEFAULT 0,
    average_cost DECIMAL(12,2) DEFAULT 0,
    list_price DECIMAL(12,2) DEFAULT 0,
    
    -- Inventory settings
    track_inventory BOOLEAN DEFAULT true,
    minimum_stock_level DECIMAL(10,3) DEFAULT 0,
    maximum_stock_level DECIMAL(10,3) DEFAULT 0,
    reorder_point DECIMAL(10,3) DEFAULT 0,
    reorder_quantity DECIMAL(10,3) DEFAULT 0,
    
    -- Quality and compliance
    quality_grade VARCHAR(20),
    quality_standards JSONB,
    certifications_required JSONB,
    hazardous_material BOOLEAN DEFAULT false,
    safety_data_sheet JSONB,
    
    -- Lifecycle information
    shelf_life_days INTEGER,
    expiry_tracking_required BOOLEAN DEFAULT false,
    batch_tracking_required BOOLEAN DEFAULT false,
    serial_tracking_required BOOLEAN DEFAULT false,
    
    -- Supplier information
    primary_supplier_id UUID,
    alternative_suppliers JSONB,
    lead_time_days INTEGER DEFAULT 7,
    
    -- Storage requirements
    storage_location VARCHAR(100),
    storage_conditions JSONB,
    handling_instructions TEXT,
    
    -- Usage information
    usage_category VARCHAR(30),
    consumption_pattern VARCHAR(20),
    seasonal_demand BOOLEAN DEFAULT false,
    
    -- Accounting information
    asset_account VARCHAR(20),
    expense_account VARCHAR(20),
    cost_center VARCHAR(20),
    
    -- Status and lifecycle
    material_status VARCHAR(20) DEFAULT 'ACTIVE',
    lifecycle_stage VARCHAR(20) DEFAULT 'ACTIVE',
    discontinuation_date DATE,
    replacement_material_id UUID,
    
    -- Documentation
    technical_drawings JSONB,
    installation_guides JSONB,
    maintenance_instructions JSONB,
    warranty_information JSONB,
    
    -- Performance metrics
    total_consumed DECIMAL(15,3) DEFAULT 0,
    total_purchased DECIMAL(15,3) DEFAULT 0,
    average_monthly_consumption DECIMAL(10,3) DEFAULT 0,
    last_used_date DATE,
    last_purchased_date DATE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_materials_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_materials_category FOREIGN KEY (category_id) REFERENCES bms.material_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_materials_base_unit FOREIGN KEY (base_unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    CONSTRAINT fk_materials_purchase_unit FOREIGN KEY (purchase_unit_id) REFERENCES bms.material_units(unit_id) ON DELETE SET NULL,
    CONSTRAINT fk_materials_stock_unit FOREIGN KEY (stock_unit_id) REFERENCES bms.material_units(unit_id) ON DELETE SET NULL,
    CONSTRAINT fk_materials_primary_supplier FOREIGN KEY (primary_supplier_id) REFERENCES bms.suppliers(supplier_id) ON DELETE SET NULL,
    CONSTRAINT fk_materials_replacement FOREIGN KEY (replacement_material_id) REFERENCES bms.materials(material_id) ON DELETE SET NULL,
    CONSTRAINT uk_materials_code UNIQUE (company_id, material_code),
    
    -- Check constraints
    CONSTRAINT chk_material_type CHECK (material_type IN (
        'RAW_MATERIAL', 'COMPONENT', 'SPARE_PART', 'CONSUMABLE', 'TOOL', 'EQUIPMENT', 'CHEMICAL', 'OTHER'
    )),
    CONSTRAINT chk_material_status CHECK (material_status IN (
        'ACTIVE', 'INACTIVE', 'DISCONTINUED', 'OBSOLETE', 'PENDING_APPROVAL'
    )),
    CONSTRAINT chk_lifecycle_stage CHECK (lifecycle_stage IN (
        'INTRODUCTION', 'ACTIVE', 'MATURE', 'DECLINING', 'DISCONTINUED'
    )),
    CONSTRAINT chk_usage_category CHECK (usage_category IN (
        'MAINTENANCE', 'REPAIR', 'CONSTRUCTION', 'CLEANING', 'SAFETY', 'OFFICE', 'OTHER'
    )),
    CONSTRAINT chk_consumption_pattern CHECK (consumption_pattern IN (
        'REGULAR', 'IRREGULAR', 'SEASONAL', 'PROJECT_BASED', 'EMERGENCY'
    )),
    CONSTRAINT chk_cost_values_material CHECK (
        standard_cost >= 0 AND last_purchase_cost >= 0 AND 
        average_cost >= 0 AND list_price >= 0
    ),
    CONSTRAINT chk_stock_levels CHECK (
        minimum_stock_level >= 0 AND maximum_stock_level >= 0 AND
        reorder_point >= 0 AND reorder_quantity >= 0 AND
        (maximum_stock_level = 0 OR maximum_stock_level >= minimum_stock_level)
    )
);

-- Material suppliers relationship table
CREATE TABLE IF NOT EXISTS bms.material_suppliers (
    material_supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    material_id UUID NOT NULL,
    supplier_id UUID NOT NULL,
    
    -- Supplier relationship
    supplier_priority INTEGER DEFAULT 1,
    is_primary_supplier BOOLEAN DEFAULT false,
    is_approved_supplier BOOLEAN DEFAULT true,
    
    -- Pricing information
    unit_price DECIMAL(12,2) DEFAULT 0,
    currency VARCHAR(3) DEFAULT 'KRW',
    price_valid_from DATE,
    price_valid_to DATE,
    minimum_order_quantity DECIMAL(10,3) DEFAULT 0,
    
    -- Terms and conditions
    lead_time_days INTEGER DEFAULT 7,
    payment_terms VARCHAR(100),
    delivery_terms VARCHAR(100),
    quality_terms TEXT,
    
    -- Performance metrics
    quality_rating DECIMAL(3,1) DEFAULT 0,
    delivery_performance DECIMAL(5,2) DEFAULT 0,
    price_competitiveness DECIMAL(3,1) DEFAULT 0,
    service_rating DECIMAL(3,1) DEFAULT 0,
    
    -- Order history
    total_orders INTEGER DEFAULT 0,
    total_order_value DECIMAL(15,2) DEFAULT 0,
    last_order_date DATE,
    average_order_value DECIMAL(12,2) DEFAULT 0,
    
    -- Status
    relationship_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_material_suppliers_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_material_suppliers_material FOREIGN KEY (material_id) REFERENCES bms.materials(material_id) ON DELETE CASCADE,
    CONSTRAINT fk_material_suppliers_supplier FOREIGN KEY (supplier_id) REFERENCES bms.suppliers(supplier_id) ON DELETE CASCADE,
    CONSTRAINT uk_material_suppliers UNIQUE (company_id, material_id, supplier_id),
    
    -- Check constraints
    CONSTRAINT chk_supplier_priority CHECK (supplier_priority >= 1 AND supplier_priority <= 10),
    CONSTRAINT chk_relationship_status CHECK (relationship_status IN (
        'ACTIVE', 'INACTIVE', 'SUSPENDED', 'TERMINATED'
    )),
    CONSTRAINT chk_supplier_ratings CHECK (
        quality_rating >= 0 AND quality_rating <= 10 AND
        price_competitiveness >= 0 AND price_competitiveness <= 10 AND
        service_rating >= 0 AND service_rating <= 10
    ),
    CONSTRAINT chk_delivery_performance CHECK (delivery_performance >= 0 AND delivery_performance <= 100),
    CONSTRAINT chk_pricing_values CHECK (unit_price >= 0 AND minimum_order_quantity >= 0)
);

-- Enable RLS
ALTER TABLE bms.materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.material_suppliers ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY materials_isolation_policy ON bms.materials
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY material_suppliers_isolation_policy ON bms.material_suppliers
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_materials_company_id ON bms.materials(company_id);
CREATE INDEX IF NOT EXISTS idx_materials_code ON bms.materials(material_code);
CREATE INDEX IF NOT EXISTS idx_materials_name ON bms.materials(material_name);
CREATE INDEX IF NOT EXISTS idx_materials_category ON bms.materials(category_id);
CREATE INDEX IF NOT EXISTS idx_materials_type ON bms.materials(material_type);
CREATE INDEX IF NOT EXISTS idx_materials_status ON bms.materials(material_status);
CREATE INDEX IF NOT EXISTS idx_materials_lifecycle ON bms.materials(lifecycle_stage);
CREATE INDEX IF NOT EXISTS idx_materials_primary_supplier ON bms.materials(primary_supplier_id);
CREATE INDEX IF NOT EXISTS idx_materials_brand ON bms.materials(brand);
CREATE INDEX IF NOT EXISTS idx_materials_model ON bms.materials(model_number);
CREATE INDEX IF NOT EXISTS idx_materials_part ON bms.materials(part_number);

CREATE INDEX IF NOT EXISTS idx_material_suppliers_company_id ON bms.material_suppliers(company_id);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_material ON bms.material_suppliers(material_id);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_supplier ON bms.material_suppliers(supplier_id);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_priority ON bms.material_suppliers(supplier_priority);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_primary ON bms.material_suppliers(is_primary_supplier);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_status ON bms.material_suppliers(relationship_status);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_materials_category_status ON bms.materials(category_id, material_status);
CREATE INDEX IF NOT EXISTS idx_materials_type_status ON bms.materials(material_type, material_status);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_material_priority ON bms.material_suppliers(material_id, supplier_priority);

-- Updated_at triggers
CREATE TRIGGER materials_updated_at_trigger
    BEFORE UPDATE ON bms.materials
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER material_suppliers_updated_at_trigger
    BEFORE UPDATE ON bms.material_suppliers
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Add comments
COMMENT ON TABLE bms.materials IS 'Materials - Master data for all materials with specifications and inventory settings';
COMMENT ON TABLE bms.material_suppliers IS 'Material suppliers - Relationship between materials and their suppliers';

-- Script completion message
SELECT 'Missing material master tables created successfully.' as message;