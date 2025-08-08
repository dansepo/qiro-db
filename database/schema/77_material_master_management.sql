-- =====================================================
-- Material Master Management System
-- Phase 4.4.1: Material Master Management Tables
-- =====================================================

-- 1. Material categories table
CREATE TABLE IF NOT EXISTS bms.material_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Category information
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    parent_category_id UUID,
    
    -- Category hierarchy
    category_level INTEGER DEFAULT 1,
    category_path VARCHAR(500),
    display_order INTEGER DEFAULT 0,
    
    -- Category properties
    requires_serial_number BOOLEAN DEFAULT false,
    requires_batch_tracking BOOLEAN DEFAULT false,
    requires_expiry_date BOOLEAN DEFAULT false,
    requires_quality_check BOOLEAN DEFAULT false,
    
    -- Storage requirements
    storage_requirements JSONB,
    handling_instructions TEXT,
    safety_requirements JSONB,
    
    -- Accounting settings
    default_account_code VARCHAR(20),
    cost_center VARCHAR(20),
    expense_category VARCHAR(30),
    
    -- Category status
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_material_categories_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_material_categories_parent FOREIGN KEY (parent_category_id) REFERENCES bms.material_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_material_categories_code UNIQUE (company_id, category_code),
    
    -- Check constraints
    CONSTRAINT chk_category_level_material CHECK (category_level >= 1 AND category_level <= 5),
    CONSTRAINT chk_expense_category CHECK (expense_category IN (
        'MAINTENANCE', 'REPAIR', 'IMPROVEMENT', 'SAFETY', 'CLEANING', 'OFFICE', 'OTHER'
    ))
);

-- 2. Material units table
CREATE TABLE IF NOT EXISTS bms.material_units (
    unit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Unit information
    unit_code VARCHAR(10) NOT NULL,
    unit_name VARCHAR(50) NOT NULL,
    unit_description TEXT,
    unit_type VARCHAR(20) NOT NULL,
    
    -- Unit properties
    base_unit_id UUID,
    conversion_factor DECIMAL(15,6) DEFAULT 1.0,
    precision_digits INTEGER DEFAULT 2,
    
    -- Display settings
    display_format VARCHAR(50),
    symbol VARCHAR(10),
    
    -- Unit status
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_material_units_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_material_units_base FOREIGN KEY (base_unit_id) REFERENCES bms.material_units(unit_id) ON DELETE SET NULL,
    CONSTRAINT uk_material_units_code UNIQUE (company_id, unit_code),
    
    -- Check constraints
    CONSTRAINT chk_unit_type CHECK (unit_type IN (
        'LENGTH', 'AREA', 'VOLUME', 'WEIGHT', 'COUNT', 'TIME', 'TEMPERATURE', 'PRESSURE', 'OTHER'
    )),
    CONSTRAINT chk_conversion_factor CHECK (conversion_factor > 0),
    CONSTRAINT chk_precision_digits CHECK (precision_digits >= 0 AND precision_digits <= 6)
);

-- 3. Suppliers table
CREATE TABLE IF NOT EXISTS bms.suppliers (
    supplier_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Supplier identification
    supplier_code VARCHAR(20) NOT NULL,
    supplier_name VARCHAR(200) NOT NULL,
    supplier_type VARCHAR(30) NOT NULL,
    business_registration_number VARCHAR(50),
    tax_id VARCHAR(50),
    
    -- Contact information
    contact_person VARCHAR(100),
    contact_title VARCHAR(50),
    phone_number VARCHAR(20),
    mobile_number VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(200),
    
    -- Address information
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'South Korea',
    
    -- Business information
    business_category VARCHAR(50),
    establishment_date DATE,
    employee_count INTEGER,
    annual_revenue DECIMAL(15,2),
    
    -- Certification and quality
    certifications JSONB,
    quality_rating DECIMAL(3,1) DEFAULT 0,
    iso_certified BOOLEAN DEFAULT false,
    
    -- Payment terms
    payment_terms VARCHAR(100),
    payment_method VARCHAR(30),
    credit_limit DECIMAL(12,2) DEFAULT 0,
    payment_days INTEGER DEFAULT 30,
    
    -- Delivery information
    delivery_terms VARCHAR(100),
    lead_time_days INTEGER DEFAULT 7,
    minimum_order_amount DECIMAL(12,2) DEFAULT 0,
    delivery_area JSONB,
    
    -- Performance metrics
    on_time_delivery_rate DECIMAL(5,2) DEFAULT 0,
    quality_score DECIMAL(3,1) DEFAULT 0,
    service_rating DECIMAL(3,1) DEFAULT 0,
    total_orders INTEGER DEFAULT 0,
    total_order_value DECIMAL(15,2) DEFAULT 0,
    
    -- Contract information
    contract_start_date DATE,
    contract_end_date DATE,
    contract_terms TEXT,
    
    -- Banking information
    bank_name VARCHAR(100),
    bank_account_number VARCHAR(50),
    bank_routing_number VARCHAR(50),
    
    -- Status and notes
    supplier_status VARCHAR(20) DEFAULT 'ACTIVE',
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    internal_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_suppliers_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_suppliers_code UNIQUE (company_id, supplier_code),
    
    -- Check constraints
    CONSTRAINT chk_supplier_type CHECK (supplier_type IN (
        'MANUFACTURER', 'DISTRIBUTOR', 'WHOLESALER', 'RETAILER', 'SERVICE_PROVIDER', 'CONTRACTOR'
    )),
    CONSTRAINT chk_supplier_status CHECK (supplier_status IN (
        'ACTIVE', 'INACTIVE', 'SUSPENDED', 'BLACKLISTED', 'PENDING_APPROVAL'
    )),
    CONSTRAINT chk_approval_status_supplier CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'UNDER_REVIEW'
    )),
    CONSTRAINT chk_quality_ratings CHECK (
        quality_rating >= 0 AND quality_rating <= 10 AND
        quality_score >= 0 AND quality_score <= 10 AND
        service_rating >= 0 AND service_rating <= 10
    ),
    CONSTRAINT chk_delivery_rate CHECK (on_time_delivery_rate >= 0 AND on_time_delivery_rate <= 100)
);-- 4. 
Materials master table
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

-- 5. Material suppliers relationship table
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
);-- 6
. RLS policies and indexes
ALTER TABLE bms.material_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.material_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.material_suppliers ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY material_categories_isolation_policy ON bms.material_categories
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY material_units_isolation_policy ON bms.material_units
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY suppliers_isolation_policy ON bms.suppliers
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY materials_isolation_policy ON bms.materials
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY material_suppliers_isolation_policy ON bms.material_suppliers
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for material_categories
CREATE INDEX IF NOT EXISTS idx_material_categories_company_id ON bms.material_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_material_categories_code ON bms.material_categories(category_code);
CREATE INDEX IF NOT EXISTS idx_material_categories_parent ON bms.material_categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_material_categories_level ON bms.material_categories(category_level);
CREATE INDEX IF NOT EXISTS idx_material_categories_active ON bms.material_categories(is_active);

-- Performance indexes for material_units
CREATE INDEX IF NOT EXISTS idx_material_units_company_id ON bms.material_units(company_id);
CREATE INDEX IF NOT EXISTS idx_material_units_code ON bms.material_units(unit_code);
CREATE INDEX IF NOT EXISTS idx_material_units_type ON bms.material_units(unit_type);
CREATE INDEX IF NOT EXISTS idx_material_units_base ON bms.material_units(base_unit_id);
CREATE INDEX IF NOT EXISTS idx_material_units_active ON bms.material_units(is_active);

-- Performance indexes for suppliers
CREATE INDEX IF NOT EXISTS idx_suppliers_company_id ON bms.suppliers(company_id);
CREATE INDEX IF NOT EXISTS idx_suppliers_code ON bms.suppliers(supplier_code);
CREATE INDEX IF NOT EXISTS idx_suppliers_name ON bms.suppliers(supplier_name);
CREATE INDEX IF NOT EXISTS idx_suppliers_type ON bms.suppliers(supplier_type);
CREATE INDEX IF NOT EXISTS idx_suppliers_status ON bms.suppliers(supplier_status);
CREATE INDEX IF NOT EXISTS idx_suppliers_approval ON bms.suppliers(approval_status);
CREATE INDEX IF NOT EXISTS idx_suppliers_rating ON bms.suppliers(quality_rating);

-- Performance indexes for materials
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

-- Performance indexes for material_suppliers
CREATE INDEX IF NOT EXISTS idx_material_suppliers_company_id ON bms.material_suppliers(company_id);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_material ON bms.material_suppliers(material_id);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_supplier ON bms.material_suppliers(supplier_id);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_priority ON bms.material_suppliers(supplier_priority);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_primary ON bms.material_suppliers(is_primary_supplier);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_status ON bms.material_suppliers(relationship_status);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_materials_category_status ON bms.materials(category_id, material_status);
CREATE INDEX IF NOT EXISTS idx_materials_type_status ON bms.materials(material_type, material_status);
CREATE INDEX IF NOT EXISTS idx_suppliers_type_status ON bms.suppliers(supplier_type, supplier_status);
CREATE INDEX IF NOT EXISTS idx_material_suppliers_material_priority ON bms.material_suppliers(material_id, supplier_priority);

-- Updated_at triggers
CREATE TRIGGER material_categories_updated_at_trigger
    BEFORE UPDATE ON bms.material_categories
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER material_units_updated_at_trigger
    BEFORE UPDATE ON bms.material_units
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER suppliers_updated_at_trigger
    BEFORE UPDATE ON bms.suppliers
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER materials_updated_at_trigger
    BEFORE UPDATE ON bms.materials
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER material_suppliers_updated_at_trigger
    BEFORE UPDATE ON bms.material_suppliers
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.material_categories IS 'Material categories - Hierarchical classification system for materials';
COMMENT ON TABLE bms.material_units IS 'Material units - Units of measure for materials with conversion factors';
COMMENT ON TABLE bms.suppliers IS 'Suppliers - Comprehensive supplier information and performance tracking';
COMMENT ON TABLE bms.materials IS 'Materials - Master data for all materials with specifications and inventory settings';
COMMENT ON TABLE bms.material_suppliers IS 'Material suppliers - Relationship between materials and their suppliers';

-- Script completion message
SELECT 'Material master management system tables created successfully.' as message;