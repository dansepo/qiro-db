-- =====================================================
-- Inventory Management System
-- Phase 4.4.2: Inventory Management Tables
-- =====================================================

-- 1. Storage locations table
CREATE TABLE IF NOT EXISTS bms.storage_locations (
    location_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Location identification
    location_code VARCHAR(20) NOT NULL,
    location_name VARCHAR(100) NOT NULL,
    location_description TEXT,
    location_type VARCHAR(20) NOT NULL,
    
    -- Location hierarchy
    parent_location_id UUID,
    location_level INTEGER DEFAULT 1,
    location_path VARCHAR(500),
    
    -- Physical properties
    building_id UUID,
    floor_level INTEGER,
    room_number VARCHAR(20),
    area_size DECIMAL(10,2),
    volume_capacity DECIMAL(10,2),
    weight_capacity DECIMAL(10,2),
    
    -- Storage conditions
    temperature_min DECIMAL(5,2),
    temperature_max DECIMAL(5,2),
    humidity_min DECIMAL(5,2),
    humidity_max DECIMAL(5,2),
    special_conditions JSONB,
    
    -- Access control
    access_level VARCHAR(20) DEFAULT 'GENERAL',
    requires_authorization BOOLEAN DEFAULT false,
    authorized_personnel JSONB,
    
    -- Location manager
    location_manager_id UUID,
    backup_manager_id UUID,
    
    -- Capacity tracking
    current_utilization_percentage DECIMAL(5,2) DEFAULT 0,
    reserved_space_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Status
    location_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_storage_locations_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_storage_locations_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE SET NULL,
    CONSTRAINT fk_storage_locations_parent FOREIGN KEY (parent_location_id) REFERENCES bms.storage_locations(location_id) ON DELETE SET NULL,
    CONSTRAINT uk_storage_locations_code UNIQUE (company_id, location_code),
    
    -- Check constraints
    CONSTRAINT chk_location_type CHECK (location_type IN (
        'WAREHOUSE', 'STOREROOM', 'CABINET', 'SHELF', 'BIN', 'YARD', 'VEHICLE', 'OTHER'
    )),
    CONSTRAINT chk_access_level CHECK (access_level IN (
        'PUBLIC', 'GENERAL', 'RESTRICTED', 'CONFIDENTIAL', 'SECRET'
    )),
    CONSTRAINT chk_location_status CHECK (location_status IN (
        'ACTIVE', 'INACTIVE', 'MAINTENANCE', 'FULL', 'RESERVED'
    )),
    CONSTRAINT chk_utilization_percentage CHECK (
        current_utilization_percentage >= 0 AND current_utilization_percentage <= 100 AND
        reserved_space_percentage >= 0 AND reserved_space_percentage <= 100
    ),
    CONSTRAINT chk_temperature_range CHECK (
        temperature_min IS NULL OR temperature_max IS NULL OR temperature_min <= temperature_max
    ),
    CONSTRAINT chk_humidity_range CHECK (
        humidity_min IS NULL OR humidity_max IS NULL OR humidity_min <= humidity_max
    )
);

-- 2. Inventory transactions table
CREATE TABLE IF NOT EXISTS bms.inventory_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Transaction identification
    transaction_number VARCHAR(50) NOT NULL,
    transaction_type VARCHAR(20) NOT NULL,
    transaction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Material and location
    material_id UUID NOT NULL,
    location_id UUID NOT NULL,
    
    -- Quantity information
    quantity DECIMAL(15,3) NOT NULL,
    unit_id UUID NOT NULL,
    unit_cost DECIMAL(12,2) DEFAULT 0,
    total_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Batch and serial tracking
    batch_number VARCHAR(50),
    serial_numbers JSONB,
    expiry_date DATE,
    manufacturing_date DATE,
    
    -- Reference information
    reference_type VARCHAR(20),
    reference_id UUID,
    reference_number VARCHAR(50),
    
    -- Transaction details
    transaction_reason VARCHAR(50),
    transaction_notes TEXT,
    
    -- Quality information
    quality_status VARCHAR(20) DEFAULT 'GOOD',
    quality_notes TEXT,
    inspection_required BOOLEAN DEFAULT false,
    inspection_completed BOOLEAN DEFAULT false,
    
    -- Approval workflow
    requires_approval BOOLEAN DEFAULT false,
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Transaction status
    transaction_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Personnel
    performed_by UUID,
    supervised_by UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_inventory_transactions_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_inventory_transactions_material FOREIGN KEY (material_id) REFERENCES bms.materials(material_id) ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_transactions_location FOREIGN KEY (location_id) REFERENCES bms.storage_locations(location_id) ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_transactions_unit FOREIGN KEY (unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    CONSTRAINT uk_inventory_transactions_number UNIQUE (company_id, transaction_number),
    
    -- Check constraints
    CONSTRAINT chk_transaction_type CHECK (transaction_type IN (
        'RECEIPT', 'ISSUE', 'TRANSFER', 'ADJUSTMENT', 'RETURN', 'DISPOSAL', 'RESERVATION', 'RELEASE'
    )),
    CONSTRAINT chk_reference_type CHECK (reference_type IN (
        'PURCHASE_ORDER', 'WORK_ORDER', 'TRANSFER_ORDER', 'ADJUSTMENT_ORDER', 'RETURN_ORDER', 'DISPOSAL_ORDER'
    )),
    CONSTRAINT chk_quality_status CHECK (quality_status IN (
        'GOOD', 'DAMAGED', 'EXPIRED', 'QUARANTINE', 'REJECTED'
    )),
    CONSTRAINT chk_transaction_status CHECK (transaction_status IN (
        'PENDING', 'APPROVED', 'COMPLETED', 'CANCELLED', 'REJECTED'
    )),
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_cost_values_inventory CHECK (unit_cost >= 0 AND total_cost >= 0)
);