-- =====================================================
-- Facility Asset Management System Tables
-- Phase 4.1: Facility Asset Registration and Management
-- =====================================================

-- 1. Facility categories table
CREATE TABLE IF NOT EXISTS bms.facility_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Category information
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    parent_category_id UUID,
    
    -- Category settings
    default_maintenance_cycle_months INTEGER DEFAULT 12,
    default_inspection_cycle_months INTEGER DEFAULT 6,
    requires_certification BOOLEAN DEFAULT false,
    safety_critical BOOLEAN DEFAULT false,
    
    -- Hierarchy and ordering
    category_level INTEGER DEFAULT 1,
    display_order INTEGER DEFAULT 0,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_facility_categories_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_categories_parent FOREIGN KEY (parent_category_id) REFERENCES bms.facility_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_facility_categories_code UNIQUE (company_id, category_code),
    
    -- Check constraints
    CONSTRAINT chk_category_level CHECK (category_level >= 1 AND category_level <= 5)
);

-- 2. Facility assets table
CREATE TABLE IF NOT EXISTS bms.facility_assets (
    asset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    unit_id UUID,
    category_id UUID NOT NULL,
    
    -- Asset identification
    asset_code VARCHAR(50) NOT NULL,
    asset_name VARCHAR(200) NOT NULL,
    asset_description TEXT,
    asset_type VARCHAR(30) NOT NULL,
    
    -- Location information
    location_description TEXT,
    floor_level VARCHAR(10),
    room_number VARCHAR(20),
    coordinates JSONB,
    
    -- Technical specifications
    manufacturer VARCHAR(100),
    model_number VARCHAR(100),
    serial_number VARCHAR(100),
    specifications JSONB,
    capacity_rating VARCHAR(50),
    power_consumption DECIMAL(10,2),
    
    -- Installation information
    installation_date DATE,
    installation_cost DECIMAL(15,2) DEFAULT 0,
    installer_company VARCHAR(100),
    warranty_start_date DATE,
    warranty_end_date DATE,
    warranty_terms TEXT,
    
    -- Lifecycle information
    expected_lifespan_years INTEGER DEFAULT 10,
    depreciation_method VARCHAR(20) DEFAULT 'STRAIGHT_LINE',
    salvage_value DECIMAL(15,2) DEFAULT 0,
    replacement_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Current status
    asset_status VARCHAR(20) DEFAULT 'ACTIVE',
    condition_rating VARCHAR(20) DEFAULT 'GOOD',
    last_inspection_date DATE,
    next_inspection_date DATE,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    
    -- Performance metrics
    uptime_percentage DECIMAL(5,2) DEFAULT 100.00,
    efficiency_rating DECIMAL(5,2) DEFAULT 100.00,
    failure_count INTEGER DEFAULT 0,
    total_maintenance_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Documentation
    manuals JSONB,
    drawings JSONB,
    certificates JSONB,
    photos JSONB,
    
    -- Responsible parties
    assigned_technician_id UUID,
    maintenance_contractor_id UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_facility_assets_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_assets_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_assets_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_assets_category FOREIGN KEY (category_id) REFERENCES bms.facility_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT uk_facility_assets_code UNIQUE (company_id, asset_code),
    
    -- Check constraints
    CONSTRAINT chk_asset_type CHECK (asset_type IN (
        'HVAC', 'ELECTRICAL', 'PLUMBING', 'ELEVATOR', 'FIRE_SAFETY', 
        'SECURITY', 'LIGHTING', 'COMMUNICATION', 'STRUCTURAL', 'OTHER'
    )),
    CONSTRAINT chk_asset_status CHECK (asset_status IN (
        'ACTIVE', 'INACTIVE', 'MAINTENANCE', 'REPAIR', 'RETIRED', 'DISPOSED'
    )),
    CONSTRAINT chk_condition_rating CHECK (condition_rating IN (
        'EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'CRITICAL'
    )),
    CONSTRAINT chk_depreciation_method CHECK (depreciation_method IN (
        'STRAIGHT_LINE', 'DECLINING_BALANCE', 'UNITS_OF_PRODUCTION'
    )),
    CONSTRAINT chk_percentages CHECK (
        uptime_percentage >= 0 AND uptime_percentage <= 100 AND
        efficiency_rating >= 0 AND efficiency_rating <= 100
    ),
    CONSTRAINT chk_costs CHECK (
        installation_cost >= 0 AND salvage_value >= 0 AND 
        replacement_cost >= 0 AND total_maintenance_cost >= 0
    )
);-- 3. As
set status history table
CREATE TABLE IF NOT EXISTS bms.asset_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Status change information
    change_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    old_condition VARCHAR(20),
    new_condition VARCHAR(20),
    
    -- Change details
    change_reason VARCHAR(50) NOT NULL,
    change_description TEXT,
    change_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Performance impact
    downtime_hours DECIMAL(8,2) DEFAULT 0,
    impact_description TEXT,
    
    -- Responsible parties
    changed_by UUID,
    approved_by UUID,
    
    -- Documentation
    supporting_documents JSONB,
    photos JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT fk_asset_status_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_asset_status_history_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_change_reason CHECK (change_reason IN (
        'INSTALLATION', 'MAINTENANCE', 'REPAIR', 'UPGRADE', 'REPLACEMENT', 
        'INSPECTION', 'FAILURE', 'RETIREMENT', 'DISPOSAL', 'OTHER'
    ))
);

-- 4. Asset depreciation table
CREATE TABLE IF NOT EXISTS bms.asset_depreciation (
    depreciation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Depreciation period
    depreciation_year INTEGER NOT NULL,
    depreciation_month INTEGER NOT NULL,
    
    -- Depreciation calculation
    book_value_start DECIMAL(15,2) NOT NULL,
    depreciation_amount DECIMAL(15,2) NOT NULL,
    accumulated_depreciation DECIMAL(15,2) NOT NULL,
    book_value_end DECIMAL(15,2) NOT NULL,
    
    -- Calculation details
    depreciation_rate DECIMAL(8,4),
    calculation_method VARCHAR(20) NOT NULL,
    calculation_notes TEXT,
    
    -- Status
    is_final_year BOOLEAN DEFAULT false,
    
    -- Metadata
    calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    calculated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_asset_depreciation_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_asset_depreciation_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    CONSTRAINT uk_asset_depreciation_period UNIQUE (asset_id, depreciation_year, depreciation_month),
    
    -- Check constraints
    CONSTRAINT chk_depreciation_month CHECK (depreciation_month >= 1 AND depreciation_month <= 12),
    CONSTRAINT chk_depreciation_amounts CHECK (
        book_value_start >= 0 AND depreciation_amount >= 0 AND 
        accumulated_depreciation >= 0 AND book_value_end >= 0
    )
);

-- 5. Asset documents table
CREATE TABLE IF NOT EXISTS bms.asset_documents (
    document_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    asset_id UUID NOT NULL,
    
    -- Document information
    document_type VARCHAR(30) NOT NULL,
    document_name VARCHAR(200) NOT NULL,
    document_description TEXT,
    
    -- File information
    file_name VARCHAR(255),
    file_path VARCHAR(500),
    file_size BIGINT,
    file_type VARCHAR(50),
    
    -- Document metadata
    document_date DATE,
    expiry_date DATE,
    version VARCHAR(20),
    language VARCHAR(10) DEFAULT 'ko',
    
    -- Access control
    is_confidential BOOLEAN DEFAULT false,
    access_level VARCHAR(20) DEFAULT 'INTERNAL',
    
    -- Status
    document_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Metadata
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    uploaded_by UUID,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_asset_documents_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_asset_documents_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_document_type CHECK (document_type IN (
        'MANUAL', 'DRAWING', 'SPECIFICATION', 'WARRANTY', 'CERTIFICATE', 
        'INSPECTION_REPORT', 'MAINTENANCE_RECORD', 'PHOTO', 'OTHER'
    )),
    CONSTRAINT chk_access_level CHECK (access_level IN (
        'PUBLIC', 'INTERNAL', 'RESTRICTED', 'CONFIDENTIAL'
    )),
    CONSTRAINT chk_document_status CHECK (document_status IN (
        'ACTIVE', 'ARCHIVED', 'EXPIRED', 'DELETED'
    ))
);--
 RLS policies and indexes
ALTER TABLE bms.facility_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.facility_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.asset_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.asset_depreciation ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.asset_documents ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY facility_categories_isolation_policy ON bms.facility_categories
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY facility_assets_isolation_policy ON bms.facility_assets
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY asset_status_history_isolation_policy ON bms.asset_status_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY asset_depreciation_isolation_policy ON bms.asset_depreciation
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY asset_documents_isolation_policy ON bms.asset_documents
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for facility_categories
CREATE INDEX IF NOT EXISTS idx_facility_categories_company_id ON bms.facility_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_facility_categories_parent ON bms.facility_categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_facility_categories_code ON bms.facility_categories(category_code);
CREATE INDEX IF NOT EXISTS idx_facility_categories_active ON bms.facility_categories(is_active);

-- Performance indexes for facility_assets
CREATE INDEX IF NOT EXISTS idx_facility_assets_company_id ON bms.facility_assets(company_id);
CREATE INDEX IF NOT EXISTS idx_facility_assets_building_id ON bms.facility_assets(building_id);
CREATE INDEX IF NOT EXISTS idx_facility_assets_unit_id ON bms.facility_assets(unit_id);
CREATE INDEX IF NOT EXISTS idx_facility_assets_category_id ON bms.facility_assets(category_id);
CREATE INDEX IF NOT EXISTS idx_facility_assets_code ON bms.facility_assets(asset_code);
CREATE INDEX IF NOT EXISTS idx_facility_assets_type ON bms.facility_assets(asset_type);
CREATE INDEX IF NOT EXISTS idx_facility_assets_status ON bms.facility_assets(asset_status);
CREATE INDEX IF NOT EXISTS idx_facility_assets_condition ON bms.facility_assets(condition_rating);
CREATE INDEX IF NOT EXISTS idx_facility_assets_next_inspection ON bms.facility_assets(next_inspection_date);
CREATE INDEX IF NOT EXISTS idx_facility_assets_next_maintenance ON bms.facility_assets(next_maintenance_date);

-- Performance indexes for asset_status_history
CREATE INDEX IF NOT EXISTS idx_asset_status_history_company_id ON bms.asset_status_history(company_id);
CREATE INDEX IF NOT EXISTS idx_asset_status_history_asset_id ON bms.asset_status_history(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_status_history_change_date ON bms.asset_status_history(change_date);

-- Performance indexes for asset_depreciation
CREATE INDEX IF NOT EXISTS idx_asset_depreciation_company_id ON bms.asset_depreciation(company_id);
CREATE INDEX IF NOT EXISTS idx_asset_depreciation_asset_id ON bms.asset_depreciation(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_depreciation_year ON bms.asset_depreciation(depreciation_year);

-- Performance indexes for asset_documents
CREATE INDEX IF NOT EXISTS idx_asset_documents_company_id ON bms.asset_documents(company_id);
CREATE INDEX IF NOT EXISTS idx_asset_documents_asset_id ON bms.asset_documents(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_documents_type ON bms.asset_documents(document_type);

-- Updated_at triggers
CREATE TRIGGER facility_categories_updated_at_trigger
    BEFORE UPDATE ON bms.facility_categories
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER facility_assets_updated_at_trigger
    BEFORE UPDATE ON bms.facility_assets
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER asset_documents_updated_at_trigger
    BEFORE UPDATE ON bms.asset_documents
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.facility_categories IS 'Facility categories - Classification system for facility assets';
COMMENT ON TABLE bms.facility_assets IS 'Facility assets - Complete asset registry with lifecycle management';
COMMENT ON TABLE bms.asset_status_history IS 'Asset status history - Complete audit trail of asset status changes';
COMMENT ON TABLE bms.asset_depreciation IS 'Asset depreciation - Depreciation calculations and book value tracking';
COMMENT ON TABLE bms.asset_documents IS 'Asset documents - Document management for facility assets';

-- Script completion message
SELECT 'Facility asset management system tables created successfully.' as message;