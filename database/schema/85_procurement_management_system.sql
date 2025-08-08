-- =====================================================
-- Procurement Management System
-- Phase 4.4.3: Purchase and Procurement Management Tables
-- =====================================================

-- 1. Purchase request table
CREATE TABLE IF NOT EXISTS bms.purchase_requests (
    request_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Request identification
    request_number VARCHAR(50) NOT NULL,
    request_title VARCHAR(200) NOT NULL,
    request_type VARCHAR(30) NOT NULL,
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Requester information
    requester_id UUID NOT NULL,
    department VARCHAR(50),
    cost_center VARCHAR(20),
    project_id UUID,
    
    -- Request details
    request_reason TEXT NOT NULL,
    urgency_level VARCHAR(20) DEFAULT 'NORMAL',
    required_date DATE,
    delivery_location VARCHAR(200),
    
    -- Budget information
    estimated_total_amount DECIMAL(15,2) DEFAULT 0,
    budget_code VARCHAR(30),
    budget_year INTEGER,
    
    -- Approval workflow
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    current_approver_id UUID,
    approval_level INTEGER DEFAULT 1,
    final_approval_date TIMESTAMP WITH TIME ZONE,
    
    -- Reference information
    reference_type VARCHAR(30),
    reference_id UUID,
    reference_number VARCHAR(50),
    
    -- Special requirements
    quality_requirements TEXT,
    delivery_requirements TEXT,
    technical_specifications JSONB,
    
    -- Status
    request_status VARCHAR(20) DEFAULT 'DRAFT',
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_purchase_requests_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_requests_requester FOREIGN KEY (requester_id) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_requests_approver FOREIGN KEY (current_approver_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_purchase_requests_number UNIQUE (company_id, request_number),
    
    -- Check constraints
    CONSTRAINT chk_request_type CHECK (request_type IN (
        'MATERIAL', 'SERVICE', 'EQUIPMENT', 'MAINTENANCE', 'EMERGENCY', 'CAPITAL'
    )),
    CONSTRAINT chk_urgency_level_request CHECK (urgency_level IN (
        'LOW', 'NORMAL', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_approval_status_request CHECK (approval_status IN (
        'PENDING', 'IN_REVIEW', 'APPROVED', 'REJECTED', 'CANCELLED'
    )),
    CONSTRAINT chk_request_status CHECK (request_status IN (
        'DRAFT', 'SUBMITTED', 'IN_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELLED', 'CONVERTED'
    )),
    CONSTRAINT chk_approval_level CHECK (approval_level >= 1 AND approval_level <= 5),
    CONSTRAINT chk_estimated_amount CHECK (estimated_total_amount >= 0)
);

-- 2. Purchase request items table
CREATE TABLE IF NOT EXISTS bms.purchase_request_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    request_id UUID NOT NULL,
    
    -- Item identification
    line_number INTEGER NOT NULL,
    material_id UUID,
    item_description TEXT NOT NULL,
    
    -- Quantity and unit
    requested_quantity DECIMAL(15,6) NOT NULL,
    unit_id UUID NOT NULL,
    
    -- Pricing
    estimated_unit_price DECIMAL(12,2) DEFAULT 0,
    estimated_total_price DECIMAL(15,2) DEFAULT 0,
    
    -- Specifications
    technical_specs JSONB,
    quality_requirements TEXT,
    brand_preference VARCHAR(100),
    model_preference VARCHAR(100),
    
    -- Delivery
    required_date DATE,
    delivery_location VARCHAR(200),
    
    -- Status
    item_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Notes
    item_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_purchase_request_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_request_items_request FOREIGN KEY (request_id) REFERENCES bms.purchase_requests(request_id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_request_items_material FOREIGN KEY (material_id) REFERENCES bms.materials(material_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchase_request_items_unit FOREIGN KEY (unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    CONSTRAINT uk_purchase_request_items_line UNIQUE (request_id, line_number),
    
    -- Check constraints
    CONSTRAINT chk_item_status CHECK (item_status IN (
        'ACTIVE', 'CANCELLED', 'MODIFIED', 'CONVERTED'
    )),
    CONSTRAINT chk_requested_quantity CHECK (requested_quantity > 0),
    CONSTRAINT chk_estimated_prices CHECK (estimated_unit_price >= 0 AND estimated_total_price >= 0)
);

-- 3. Purchase quotations table
CREATE TABLE IF NOT EXISTS bms.purchase_quotations (
    quotation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Quotation identification
    quotation_number VARCHAR(50) NOT NULL,
    quotation_title VARCHAR(200) NOT NULL,
    quotation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Request reference
    request_id UUID,
    
    -- Supplier information
    supplier_id UUID NOT NULL,
    supplier_contact_person VARCHAR(100),
    supplier_contact_phone VARCHAR(20),
    supplier_contact_email VARCHAR(100),
    
    -- Quotation details
    quotation_valid_until DATE,
    payment_terms VARCHAR(100),
    delivery_terms VARCHAR(100),
    warranty_terms VARCHAR(200),
    
    -- Pricing
    subtotal_amount DECIMAL(15,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) DEFAULT 0,
    currency_code VARCHAR(3) DEFAULT 'KRW',
    
    -- Evaluation
    technical_score DECIMAL(5,2) DEFAULT 0,
    commercial_score DECIMAL(5,2) DEFAULT 0,
    delivery_score DECIMAL(5,2) DEFAULT 0,
    total_score DECIMAL(5,2) DEFAULT 0,
    
    -- Status
    quotation_status VARCHAR(20) DEFAULT 'RECEIVED',
    evaluation_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Selection
    is_selected BOOLEAN DEFAULT FALSE,
    selection_reason TEXT,
    selected_by UUID,
    selection_date TIMESTAMP WITH TIME ZONE,
    
    -- Documents
    quotation_document_path VARCHAR(500),
    technical_document_path VARCHAR(500),
    
    -- Notes
    evaluation_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_purchase_quotations_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_quotations_request FOREIGN KEY (request_id) REFERENCES bms.purchase_requests(request_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchase_quotations_supplier FOREIGN KEY (supplier_id) REFERENCES bms.suppliers(supplier_id) ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_quotations_selected_by FOREIGN KEY (selected_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_purchase_quotations_number UNIQUE (company_id, quotation_number),
    
    -- Check constraints
    CONSTRAINT chk_quotation_status CHECK (quotation_status IN (
        'RECEIVED', 'UNDER_REVIEW', 'EVALUATED', 'SELECTED', 'REJECTED', 'EXPIRED'
    )),
    CONSTRAINT chk_evaluation_status CHECK (evaluation_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'APPROVED'
    )),
    CONSTRAINT chk_currency_code CHECK (currency_code IN ('KRW', 'USD', 'EUR', 'JPY', 'CNY')),
    CONSTRAINT chk_amounts CHECK (
        subtotal_amount >= 0 AND tax_amount >= 0 AND 
        discount_amount >= 0 AND total_amount >= 0
    ),
    CONSTRAINT chk_scores CHECK (
        technical_score >= 0 AND technical_score <= 100 AND
        commercial_score >= 0 AND commercial_score <= 100 AND
        delivery_score >= 0 AND delivery_score <= 100 AND
        total_score >= 0 AND total_score <= 100
    )
);

-- 4. Purchase quotation items table
CREATE TABLE IF NOT EXISTS bms.purchase_quotation_items (
    quotation_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    quotation_id UUID NOT NULL,
    
    -- Item identification
    line_number INTEGER NOT NULL,
    request_item_id UUID,
    material_id UUID,
    item_description TEXT NOT NULL,
    
    -- Quantity and unit
    quoted_quantity DECIMAL(15,6) NOT NULL,
    unit_id UUID NOT NULL,
    
    -- Pricing
    unit_price DECIMAL(12,2) NOT NULL,
    total_price DECIMAL(15,2) NOT NULL,
    
    -- Product details
    brand VARCHAR(100),
    model VARCHAR(100),
    specifications JSONB,
    country_of_origin VARCHAR(50),
    
    -- Delivery
    delivery_lead_time INTEGER, -- days
    delivery_location VARCHAR(200),
    
    -- Quality and warranty
    quality_certification VARCHAR(200),
    warranty_period INTEGER, -- months
    warranty_terms TEXT,
    
    -- Status
    item_status VARCHAR(20) DEFAULT 'ACTIVE',
    
    -- Notes
    item_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_quotation_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_quotation_items_quotation FOREIGN KEY (quotation_id) REFERENCES bms.purchase_quotations(quotation_id) ON DELETE CASCADE,
    CONSTRAINT fk_quotation_items_request_item FOREIGN KEY (request_item_id) REFERENCES bms.purchase_request_items(item_id) ON DELETE SET NULL,
    CONSTRAINT fk_quotation_items_material FOREIGN KEY (material_id) REFERENCES bms.materials(material_id) ON DELETE SET NULL,
    CONSTRAINT fk_quotation_items_unit FOREIGN KEY (unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    CONSTRAINT uk_quotation_items_line UNIQUE (quotation_id, line_number),
    
    -- Check constraints
    CONSTRAINT chk_quotation_item_status CHECK (item_status IN (
        'ACTIVE', 'CANCELLED', 'MODIFIED', 'SELECTED'
    )),
    CONSTRAINT chk_quoted_quantity CHECK (quoted_quantity > 0),
    CONSTRAINT chk_quotation_prices CHECK (unit_price >= 0 AND total_price >= 0),
    CONSTRAINT chk_delivery_lead_time CHECK (delivery_lead_time IS NULL OR delivery_lead_time >= 0),
    CONSTRAINT chk_warranty_period CHECK (warranty_period IS NULL OR warranty_period >= 0)
);

-- 5. Purchase orders table
CREATE TABLE IF NOT EXISTS bms.purchase_orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Order identification
    order_number VARCHAR(50) NOT NULL,
    order_title VARCHAR(200) NOT NULL,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Reference information
    request_id UUID,
    quotation_id UUID,
    
    -- Supplier information
    supplier_id UUID NOT NULL,
    supplier_contact_person VARCHAR(100),
    supplier_contact_phone VARCHAR(20),
    supplier_contact_email VARCHAR(100),
    
    -- Delivery information
    delivery_address TEXT NOT NULL,
    delivery_contact_person VARCHAR(100),
    delivery_contact_phone VARCHAR(20),
    requested_delivery_date DATE,
    confirmed_delivery_date DATE,
    
    -- Terms and conditions
    payment_terms VARCHAR(100),
    delivery_terms VARCHAR(100),
    warranty_terms VARCHAR(200),
    special_conditions TEXT,
    
    -- Pricing
    subtotal_amount DECIMAL(15,2) DEFAULT 0,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) DEFAULT 0,
    currency_code VARCHAR(3) DEFAULT 'KRW',
    
    -- Status tracking
    order_status VARCHAR(20) DEFAULT 'DRAFT',
    delivery_status VARCHAR(20) DEFAULT 'PENDING',
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Approval
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    
    -- Completion
    completed_date TIMESTAMP WITH TIME ZONE,
    completion_notes TEXT,
    
    -- Documents
    order_document_path VARCHAR(500),
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_purchase_orders_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_orders_request FOREIGN KEY (request_id) REFERENCES bms.purchase_requests(request_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchase_orders_quotation FOREIGN KEY (quotation_id) REFERENCES bms.purchase_quotations(quotation_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_id) REFERENCES bms.suppliers(supplier_id) ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_orders_approved_by FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_purchase_orders_number UNIQUE (company_id, order_number),
    
    -- Check constraints
    CONSTRAINT chk_order_status CHECK (order_status IN (
        'DRAFT', 'SUBMITTED', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'
    )),
    CONSTRAINT chk_delivery_status CHECK (delivery_status IN (
        'PENDING', 'SCHEDULED', 'IN_TRANSIT', 'DELIVERED', 'PARTIALLY_DELIVERED', 'DELAYED'
    )),
    CONSTRAINT chk_payment_status_order CHECK (payment_status IN (
        'PENDING', 'PARTIAL', 'COMPLETED', 'OVERDUE'
    )),
    CONSTRAINT chk_order_currency_code CHECK (currency_code IN ('KRW', 'USD', 'EUR', 'JPY', 'CNY')),
    CONSTRAINT chk_order_amounts CHECK (
        subtotal_amount >= 0 AND tax_amount >= 0 AND 
        discount_amount >= 0 AND total_amount >= 0
    )
);-- 6.
 Purchase order items table
CREATE TABLE IF NOT EXISTS bms.purchase_order_items (
    order_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    order_id UUID NOT NULL,
    
    -- Item identification
    line_number INTEGER NOT NULL,
    quotation_item_id UUID,
    material_id UUID,
    item_description TEXT NOT NULL,
    
    -- Quantity and unit
    ordered_quantity DECIMAL(15,6) NOT NULL,
    delivered_quantity DECIMAL(15,6) DEFAULT 0,
    received_quantity DECIMAL(15,6) DEFAULT 0,
    unit_id UUID NOT NULL,
    
    -- Pricing
    unit_price DECIMAL(12,2) NOT NULL,
    total_price DECIMAL(15,2) NOT NULL,
    
    -- Product details
    brand VARCHAR(100),
    model VARCHAR(100),
    specifications JSONB,
    
    -- Delivery
    delivery_lead_time INTEGER,
    scheduled_delivery_date DATE,
    actual_delivery_date DATE,
    
    -- Quality and warranty
    quality_certification VARCHAR(200),
    warranty_period INTEGER,
    warranty_terms TEXT,
    
    -- Status
    item_status VARCHAR(20) DEFAULT 'ORDERED',
    
    -- Notes
    item_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_order_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES bms.purchase_orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_quotation_item FOREIGN KEY (quotation_item_id) REFERENCES bms.purchase_quotation_items(quotation_item_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_items_material FOREIGN KEY (material_id) REFERENCES bms.materials(material_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_items_unit FOREIGN KEY (unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    CONSTRAINT uk_order_items_line UNIQUE (order_id, line_number),
    
    -- Check constraints
    CONSTRAINT chk_order_item_status CHECK (item_status IN (
        'ORDERED', 'CONFIRMED', 'IN_TRANSIT', 'DELIVERED', 'RECEIVED', 'CANCELLED'
    )),
    CONSTRAINT chk_order_quantities CHECK (
        ordered_quantity > 0 AND delivered_quantity >= 0 AND 
        received_quantity >= 0 AND delivered_quantity <= ordered_quantity AND
        received_quantity <= delivered_quantity
    ),
    CONSTRAINT chk_order_item_prices CHECK (unit_price >= 0 AND total_price >= 0)
);

-- 7. Goods receipt table
CREATE TABLE IF NOT EXISTS bms.goods_receipts (
    receipt_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Receipt identification
    receipt_number VARCHAR(50) NOT NULL,
    receipt_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Order reference
    order_id UUID NOT NULL,
    
    -- Delivery information
    delivery_note_number VARCHAR(50),
    delivery_date DATE,
    delivery_person VARCHAR(100),
    delivery_vehicle VARCHAR(50),
    
    -- Receipt details
    received_by UUID NOT NULL,
    receipt_location VARCHAR(200),
    
    -- Quality inspection
    inspection_required BOOLEAN DEFAULT TRUE,
    inspection_completed BOOLEAN DEFAULT FALSE,
    inspector_id UUID,
    inspection_date TIMESTAMP WITH TIME ZONE,
    inspection_result VARCHAR(20) DEFAULT 'PENDING',
    inspection_notes TEXT,
    
    -- Status
    receipt_status VARCHAR(20) DEFAULT 'RECEIVED',
    
    -- Documents
    delivery_note_path VARCHAR(500),
    inspection_report_path VARCHAR(500),
    
    -- Notes
    receipt_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_goods_receipts_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_goods_receipts_order FOREIGN KEY (order_id) REFERENCES bms.purchase_orders(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_goods_receipts_received_by FOREIGN KEY (received_by) REFERENCES bms.users(user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_goods_receipts_inspector FOREIGN KEY (inspector_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_goods_receipts_number UNIQUE (company_id, receipt_number),
    
    -- Check constraints
    CONSTRAINT chk_receipt_status CHECK (receipt_status IN (
        'RECEIVED', 'INSPECTED', 'ACCEPTED', 'REJECTED', 'PARTIALLY_ACCEPTED'
    )),
    CONSTRAINT chk_inspection_result CHECK (inspection_result IN (
        'PENDING', 'PASSED', 'FAILED', 'CONDITIONAL', 'WAIVED'
    ))
);

-- 8. Goods receipt items table
CREATE TABLE IF NOT EXISTS bms.goods_receipt_items (
    receipt_item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    receipt_id UUID NOT NULL,
    
    -- Item identification
    line_number INTEGER NOT NULL,
    order_item_id UUID NOT NULL,
    material_id UUID,
    item_description TEXT NOT NULL,
    
    -- Quantity information
    ordered_quantity DECIMAL(15,6) NOT NULL,
    delivered_quantity DECIMAL(15,6) NOT NULL,
    accepted_quantity DECIMAL(15,6) DEFAULT 0,
    rejected_quantity DECIMAL(15,6) DEFAULT 0,
    unit_id UUID NOT NULL,
    
    -- Quality inspection
    inspection_result VARCHAR(20) DEFAULT 'PENDING',
    quality_grade VARCHAR(20),
    defect_description TEXT,
    
    -- Batch and serial tracking
    batch_number VARCHAR(50),
    serial_numbers JSONB,
    expiry_date DATE,
    manufacturing_date DATE,
    
    -- Storage location
    storage_location_id UUID,
    
    -- Status
    item_status VARCHAR(20) DEFAULT 'RECEIVED',
    
    -- Notes
    item_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_receipt_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_receipt_items_receipt FOREIGN KEY (receipt_id) REFERENCES bms.goods_receipts(receipt_id) ON DELETE CASCADE,
    CONSTRAINT fk_receipt_items_order_item FOREIGN KEY (order_item_id) REFERENCES bms.purchase_order_items(order_item_id) ON DELETE RESTRICT,
    CONSTRAINT fk_receipt_items_material FOREIGN KEY (material_id) REFERENCES bms.materials(material_id) ON DELETE SET NULL,
    CONSTRAINT fk_receipt_items_unit FOREIGN KEY (unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    CONSTRAINT fk_receipt_items_location FOREIGN KEY (storage_location_id) REFERENCES bms.inventory_locations(location_id) ON DELETE SET NULL,
    CONSTRAINT uk_receipt_items_line UNIQUE (receipt_id, line_number),
    
    -- Check constraints
    CONSTRAINT chk_receipt_item_status CHECK (item_status IN (
        'RECEIVED', 'INSPECTED', 'ACCEPTED', 'REJECTED', 'STORED'
    )),
    CONSTRAINT chk_receipt_inspection_result CHECK (inspection_result IN (
        'PENDING', 'PASSED', 'FAILED', 'CONDITIONAL', 'WAIVED'
    )),
    CONSTRAINT chk_quality_grade CHECK (quality_grade IN (
        'A', 'B', 'C', 'REJECT', 'REWORK'
    )),
    CONSTRAINT chk_receipt_quantities CHECK (
        ordered_quantity > 0 AND delivered_quantity >= 0 AND
        accepted_quantity >= 0 AND rejected_quantity >= 0 AND
        accepted_quantity + rejected_quantity <= delivered_quantity
    )
);

-- 9. Purchase invoices table
CREATE TABLE IF NOT EXISTS bms.purchase_invoices (
    invoice_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Invoice identification
    invoice_number VARCHAR(50) NOT NULL,
    supplier_invoice_number VARCHAR(50),
    invoice_date DATE NOT NULL,
    due_date DATE,
    
    -- Order and receipt references
    order_id UUID,
    receipt_id UUID,
    
    -- Supplier information
    supplier_id UUID NOT NULL,
    
    -- Invoice amounts
    subtotal_amount DECIMAL(15,2) NOT NULL,
    tax_amount DECIMAL(15,2) DEFAULT 0,
    discount_amount DECIMAL(15,2) DEFAULT 0,
    total_amount DECIMAL(15,2) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'KRW',
    
    -- Payment information
    payment_terms VARCHAR(100),
    payment_method VARCHAR(30),
    bank_account VARCHAR(50),
    
    -- Status
    invoice_status VARCHAR(20) DEFAULT 'RECEIVED',
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    payment_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Approval workflow
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- Payment tracking
    paid_amount DECIMAL(15,2) DEFAULT 0,
    payment_date TIMESTAMP WITH TIME ZONE,
    payment_reference VARCHAR(100),
    
    -- Documents
    invoice_document_path VARCHAR(500),
    
    -- Notes
    invoice_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_purchase_invoices_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_purchase_invoices_order FOREIGN KEY (order_id) REFERENCES bms.purchase_orders(order_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchase_invoices_receipt FOREIGN KEY (receipt_id) REFERENCES bms.goods_receipts(receipt_id) ON DELETE SET NULL,
    CONSTRAINT fk_purchase_invoices_supplier FOREIGN KEY (supplier_id) REFERENCES bms.suppliers(supplier_id) ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_invoices_approved_by FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_purchase_invoices_number UNIQUE (company_id, invoice_number),
    CONSTRAINT uk_supplier_invoice_number UNIQUE (company_id, supplier_id, supplier_invoice_number),
    
    -- Check constraints
    CONSTRAINT chk_invoice_status CHECK (invoice_status IN (
        'RECEIVED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PAID', 'CANCELLED'
    )),
    CONSTRAINT chk_invoice_approval_status CHECK (approval_status IN (
        'PENDING', 'IN_REVIEW', 'APPROVED', 'REJECTED'
    )),
    CONSTRAINT chk_invoice_payment_status CHECK (payment_status IN (
        'PENDING', 'PARTIAL', 'COMPLETED', 'OVERDUE', 'CANCELLED'
    )),
    CONSTRAINT chk_payment_method CHECK (payment_method IN (
        'BANK_TRANSFER', 'CHECK', 'CASH', 'CREDIT_CARD', 'ELECTRONIC'
    )),
    CONSTRAINT chk_invoice_currency_code CHECK (currency_code IN ('KRW', 'USD', 'EUR', 'JPY', 'CNY')),
    CONSTRAINT chk_invoice_amounts CHECK (
        subtotal_amount >= 0 AND tax_amount >= 0 AND 
        discount_amount >= 0 AND total_amount >= 0 AND
        paid_amount >= 0 AND paid_amount <= total_amount
    )
);

-- 10. Purchase approval workflow table
CREATE TABLE IF NOT EXISTS bms.purchase_approval_workflow (
    workflow_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Workflow identification
    workflow_name VARCHAR(100) NOT NULL,
    workflow_type VARCHAR(30) NOT NULL,
    
    -- Approval criteria
    min_amount DECIMAL(15,2) DEFAULT 0,
    max_amount DECIMAL(15,2),
    request_type VARCHAR(30),
    department VARCHAR(50),
    
    -- Approval levels
    approval_levels JSONB NOT NULL,
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_approval_workflow_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_approval_workflow_name UNIQUE (company_id, workflow_name),
    
    -- Check constraints
    CONSTRAINT chk_workflow_type CHECK (workflow_type IN (
        'PURCHASE_REQUEST', 'PURCHASE_ORDER', 'INVOICE_APPROVAL'
    )),
    CONSTRAINT chk_amount_range CHECK (max_amount IS NULL OR max_amount >= min_amount)
);

-- 11. RLS policies and indexes
ALTER TABLE bms.purchase_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.purchase_request_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.purchase_quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.purchase_quotation_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.purchase_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.purchase_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.goods_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.goods_receipt_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.purchase_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.purchase_approval_workflow ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY purchase_requests_isolation_policy ON bms.purchase_requests
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY purchase_request_items_isolation_policy ON bms.purchase_request_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY purchase_quotations_isolation_policy ON bms.purchase_quotations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY purchase_quotation_items_isolation_policy ON bms.purchase_quotation_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY purchase_orders_isolation_policy ON bms.purchase_orders
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY purchase_order_items_isolation_policy ON bms.purchase_order_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY goods_receipts_isolation_policy ON bms.goods_receipts
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY goods_receipt_items_isolation_policy ON bms.goods_receipt_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY purchase_invoices_isolation_policy ON bms.purchase_invoices
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY purchase_approval_workflow_isolation_policy ON bms.purchase_approval_workflow
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);--
 Performance indexes for purchase_requests
CREATE INDEX IF NOT EXISTS idx_purchase_requests_company_id ON bms.purchase_requests(company_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_number ON bms.purchase_requests(request_number);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_requester ON bms.purchase_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_date ON bms.purchase_requests(request_date);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_status ON bms.purchase_requests(request_status);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_approval_status ON bms.purchase_requests(approval_status);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_type ON bms.purchase_requests(request_type);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_urgency ON bms.purchase_requests(urgency_level);
CREATE INDEX IF NOT EXISTS idx_purchase_requests_approver ON bms.purchase_requests(current_approver_id);

-- Performance indexes for purchase_request_items
CREATE INDEX IF NOT EXISTS idx_purchase_request_items_company_id ON bms.purchase_request_items(company_id);
CREATE INDEX IF NOT EXISTS idx_purchase_request_items_request_id ON bms.purchase_request_items(request_id);
CREATE INDEX IF NOT EXISTS idx_purchase_request_items_material_id ON bms.purchase_request_items(material_id);
CREATE INDEX IF NOT EXISTS idx_purchase_request_items_status ON bms.purchase_request_items(item_status);

-- Performance indexes for purchase_quotations
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_company_id ON bms.purchase_quotations(company_id);
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_number ON bms.purchase_quotations(quotation_number);
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_request_id ON bms.purchase_quotations(request_id);
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_supplier_id ON bms.purchase_quotations(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_date ON bms.purchase_quotations(quotation_date);
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_status ON bms.purchase_quotations(quotation_status);
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_selected ON bms.purchase_quotations(is_selected);
CREATE INDEX IF NOT EXISTS idx_purchase_quotations_valid_until ON bms.purchase_quotations(quotation_valid_until);

-- Performance indexes for purchase_quotation_items
CREATE INDEX IF NOT EXISTS idx_quotation_items_company_id ON bms.purchase_quotation_items(company_id);
CREATE INDEX IF NOT EXISTS idx_quotation_items_quotation_id ON bms.purchase_quotation_items(quotation_id);
CREATE INDEX IF NOT EXISTS idx_quotation_items_request_item_id ON bms.purchase_quotation_items(request_item_id);
CREATE INDEX IF NOT EXISTS idx_quotation_items_material_id ON bms.purchase_quotation_items(material_id);

-- Performance indexes for purchase_orders
CREATE INDEX IF NOT EXISTS idx_purchase_orders_company_id ON bms.purchase_orders(company_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_number ON bms.purchase_orders(order_number);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_request_id ON bms.purchase_orders(request_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_quotation_id ON bms.purchase_orders(quotation_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_id ON bms.purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_date ON bms.purchase_orders(order_date);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON bms.purchase_orders(order_status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_delivery_status ON bms.purchase_orders(delivery_status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_payment_status ON bms.purchase_orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_delivery_date ON bms.purchase_orders(requested_delivery_date);

-- Performance indexes for purchase_order_items
CREATE INDEX IF NOT EXISTS idx_order_items_company_id ON bms.purchase_order_items(company_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON bms.purchase_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_material_id ON bms.purchase_order_items(material_id);
CREATE INDEX IF NOT EXISTS idx_order_items_status ON bms.purchase_order_items(item_status);
CREATE INDEX IF NOT EXISTS idx_order_items_delivery_date ON bms.purchase_order_items(scheduled_delivery_date);

-- Performance indexes for goods_receipts
CREATE INDEX IF NOT EXISTS idx_goods_receipts_company_id ON bms.goods_receipts(company_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_number ON bms.goods_receipts(receipt_number);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_order_id ON bms.goods_receipts(order_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_date ON bms.goods_receipts(receipt_date);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_status ON bms.goods_receipts(receipt_status);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_received_by ON bms.goods_receipts(received_by);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_inspector ON bms.goods_receipts(inspector_id);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_inspection_result ON bms.goods_receipts(inspection_result);

-- Performance indexes for goods_receipt_items
CREATE INDEX IF NOT EXISTS idx_receipt_items_company_id ON bms.goods_receipt_items(company_id);
CREATE INDEX IF NOT EXISTS idx_receipt_items_receipt_id ON bms.goods_receipt_items(receipt_id);
CREATE INDEX IF NOT EXISTS idx_receipt_items_order_item_id ON bms.goods_receipt_items(order_item_id);
CREATE INDEX IF NOT EXISTS idx_receipt_items_material_id ON bms.goods_receipt_items(material_id);
CREATE INDEX IF NOT EXISTS idx_receipt_items_status ON bms.goods_receipt_items(item_status);
CREATE INDEX IF NOT EXISTS idx_receipt_items_batch ON bms.goods_receipt_items(batch_number);
CREATE INDEX IF NOT EXISTS idx_receipt_items_expiry ON bms.goods_receipt_items(expiry_date);

-- Performance indexes for purchase_invoices
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_company_id ON bms.purchase_invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_number ON bms.purchase_invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_supplier_number ON bms.purchase_invoices(supplier_invoice_number);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_order_id ON bms.purchase_invoices(order_id);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_receipt_id ON bms.purchase_invoices(receipt_id);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_supplier_id ON bms.purchase_invoices(supplier_id);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_date ON bms.purchase_invoices(invoice_date);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_due_date ON bms.purchase_invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_status ON bms.purchase_invoices(invoice_status);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_approval_status ON bms.purchase_invoices(approval_status);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_payment_status ON bms.purchase_invoices(payment_status);

-- Performance indexes for purchase_approval_workflow
CREATE INDEX IF NOT EXISTS idx_approval_workflow_company_id ON bms.purchase_approval_workflow(company_id);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_type ON bms.purchase_approval_workflow(workflow_type);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_active ON bms.purchase_approval_workflow(is_active);
CREATE INDEX IF NOT EXISTS idx_approval_workflow_amount_range ON bms.purchase_approval_workflow(min_amount, max_amount);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_purchase_requests_status_date ON bms.purchase_requests(request_status, request_date);
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier_status ON bms.purchase_orders(supplier_id, order_status);
CREATE INDEX IF NOT EXISTS idx_goods_receipts_order_status ON bms.goods_receipts(order_id, receipt_status);
CREATE INDEX IF NOT EXISTS idx_purchase_invoices_supplier_status ON bms.purchase_invoices(supplier_id, invoice_status);

-- Updated_at triggers
CREATE TRIGGER purchase_requests_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_requests
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER purchase_request_items_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_request_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER purchase_quotations_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_quotations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER purchase_quotation_items_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_quotation_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER purchase_orders_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_orders
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER purchase_order_items_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_order_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER goods_receipts_updated_at_trigger
    BEFORE UPDATE ON bms.goods_receipts
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER goods_receipt_items_updated_at_trigger
    BEFORE UPDATE ON bms.goods_receipt_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER purchase_invoices_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_invoices
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER purchase_approval_workflow_updated_at_trigger
    BEFORE UPDATE ON bms.purchase_approval_workflow
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.purchase_requests IS 'Purchase requests - Initial requests for materials or services';
COMMENT ON TABLE bms.purchase_request_items IS 'Purchase request items - Individual items in purchase requests';
COMMENT ON TABLE bms.purchase_quotations IS 'Purchase quotations - Supplier quotations for purchase requests';
COMMENT ON TABLE bms.purchase_quotation_items IS 'Purchase quotation items - Individual items in quotations';
COMMENT ON TABLE bms.purchase_orders IS 'Purchase orders - Confirmed orders to suppliers';
COMMENT ON TABLE bms.purchase_order_items IS 'Purchase order items - Individual items in purchase orders';
COMMENT ON TABLE bms.goods_receipts IS 'Goods receipts - Receipt and inspection of delivered goods';
COMMENT ON TABLE bms.goods_receipt_items IS 'Goods receipt items - Individual items received and inspected';
COMMENT ON TABLE bms.purchase_invoices IS 'Purchase invoices - Supplier invoices for payment processing';
COMMENT ON TABLE bms.purchase_approval_workflow IS 'Purchase approval workflow - Approval rules and processes';

-- Script completion message
SELECT 'Procurement Management System tables created successfully!' as status;