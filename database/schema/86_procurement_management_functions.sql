-- =====================================================
-- Procurement Management Functions
-- Phase 4.4.3: Purchase and Procurement Management Functions
-- =====================================================

-- 1. Function to create purchase request
CREATE OR REPLACE FUNCTION bms.create_purchase_request(
    p_company_id UUID,
    p_request_title VARCHAR(200),
    p_request_type VARCHAR(30),
    p_requester_id UUID,
    p_department VARCHAR(50) DEFAULT NULL,
    p_request_reason TEXT,
    p_urgency_level VARCHAR(20) DEFAULT 'NORMAL',
    p_required_date DATE DEFAULT NULL,
    p_delivery_location VARCHAR(200) DEFAULT NULL,
    p_estimated_amount DECIMAL(15,2) DEFAULT 0,
    p_budget_code VARCHAR(30) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_request_id UUID;
    v_request_number VARCHAR(50);
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Generate request number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(request_number FROM 'PR-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.purchase_requests 
    WHERE company_id = p_company_id 
      AND request_number LIKE 'PR-' || v_year || '-%';
    
    v_request_number := 'PR-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Create purchase request
    INSERT INTO bms.purchase_requests (
        company_id, request_number, request_title, request_type,
        requester_id, department, request_reason, urgency_level,
        required_date, delivery_location, estimated_total_amount,
        budget_code, created_by
    ) VALUES (
        p_company_id, v_request_number, p_request_title, p_request_type,
        p_requester_id, p_department, p_request_reason, p_urgency_level,
        p_required_date, p_delivery_location, p_estimated_amount,
        p_budget_code, p_requester_id
    ) RETURNING request_id INTO v_request_id;
    
    RETURN v_request_id;
END;
$$ LANGUAGE plpgsql;

-- 2. Function to add item to purchase request
CREATE OR REPLACE FUNCTION bms.add_purchase_request_item(
    p_request_id UUID,
    p_material_id UUID DEFAULT NULL,
    p_item_description TEXT,
    p_requested_quantity DECIMAL(15,6),
    p_unit_id UUID,
    p_estimated_unit_price DECIMAL(12,2) DEFAULT 0,
    p_technical_specs JSONB DEFAULT NULL,
    p_required_date DATE DEFAULT NULL,
    p_item_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_item_id UUID;
    v_line_number INTEGER;
    v_company_id UUID;
    v_estimated_total DECIMAL(15,2);
BEGIN
    -- Get company_id and next line number
    SELECT 
        pr.company_id,
        COALESCE(MAX(pri.line_number), 0) + 1
    INTO v_company_id, v_line_number
    FROM bms.purchase_requests pr
    LEFT JOIN bms.purchase_request_items pri ON pr.request_id = pri.request_id
    WHERE pr.request_id = p_request_id
    GROUP BY pr.company_id;
    
    -- Calculate estimated total price
    v_estimated_total := p_requested_quantity * p_estimated_unit_price;
    
    -- Insert request item
    INSERT INTO bms.purchase_request_items (
        company_id, request_id, line_number, material_id,
        item_description, requested_quantity, unit_id,
        estimated_unit_price, estimated_total_price,
        technical_specs, required_date, item_notes
    ) VALUES (
        v_company_id, p_request_id, v_line_number, p_material_id,
        p_item_description, p_requested_quantity, p_unit_id,
        p_estimated_unit_price, v_estimated_total,
        p_technical_specs, p_required_date, p_item_notes
    ) RETURNING item_id INTO v_item_id;
    
    -- Update request total amount
    UPDATE bms.purchase_requests 
    SET 
        estimated_total_amount = (
            SELECT COALESCE(SUM(estimated_total_price), 0)
            FROM bms.purchase_request_items 
            WHERE request_id = p_request_id
        ),
        updated_at = NOW()
    WHERE request_id = p_request_id;
    
    RETURN v_item_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Function to submit purchase request for approval
CREATE OR REPLACE FUNCTION bms.submit_purchase_request(
    p_request_id UUID,
    p_submitted_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_request RECORD;
    v_workflow RECORD;
    v_first_approver UUID;
BEGIN
    -- Get request details
    SELECT * INTO v_request
    FROM bms.purchase_requests 
    WHERE request_id = p_request_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Purchase request not found: %', p_request_id;
    END IF;
    
    IF v_request.request_status != 'DRAFT' THEN
        RAISE EXCEPTION 'Request is not in draft status: %', v_request.request_status;
    END IF;
    
    -- Find appropriate approval workflow
    SELECT * INTO v_workflow
    FROM bms.purchase_approval_workflow 
    WHERE company_id = v_request.company_id
      AND workflow_type = 'PURCHASE_REQUEST'
      AND is_active = TRUE
      AND (min_amount IS NULL OR v_request.estimated_total_amount >= min_amount)
      AND (max_amount IS NULL OR v_request.estimated_total_amount <= max_amount)
      AND (request_type IS NULL OR request_type = v_request.request_type)
      AND (department IS NULL OR department = v_request.department)
    ORDER BY min_amount DESC
    LIMIT 1;
    
    -- Get first approver from workflow
    IF FOUND THEN
        v_first_approver := (v_workflow.approval_levels->0->>'approver_id')::UUID;
    END IF;
    
    -- Update request status
    UPDATE bms.purchase_requests 
    SET 
        request_status = CASE 
            WHEN v_first_approver IS NOT NULL THEN 'IN_APPROVAL'
            ELSE 'APPROVED'
        END,
        approval_status = CASE 
            WHEN v_first_approver IS NOT NULL THEN 'PENDING'
            ELSE 'APPROVED'
        END,
        current_approver_id = v_first_approver,
        updated_by = p_submitted_by,
        updated_at = NOW()
    WHERE request_id = p_request_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Function to create purchase quotation
CREATE OR REPLACE FUNCTION bms.create_purchase_quotation(
    p_company_id UUID,
    p_quotation_title VARCHAR(200),
    p_request_id UUID DEFAULT NULL,
    p_supplier_id UUID,
    p_quotation_valid_until DATE DEFAULT NULL,
    p_payment_terms VARCHAR(100) DEFAULT NULL,
    p_delivery_terms VARCHAR(100) DEFAULT NULL,
    p_warranty_terms VARCHAR(200) DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_quotation_id UUID;
    v_quotation_number VARCHAR(50);
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Generate quotation number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(quotation_number FROM 'QT-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.purchase_quotations 
    WHERE company_id = p_company_id 
      AND quotation_number LIKE 'QT-' || v_year || '-%';
    
    v_quotation_number := 'QT-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Create quotation
    INSERT INTO bms.purchase_quotations (
        company_id, quotation_number, quotation_title,
        request_id, supplier_id, quotation_valid_until,
        payment_terms, delivery_terms, warranty_terms,
        created_by
    ) VALUES (
        p_company_id, v_quotation_number, p_quotation_title,
        p_request_id, p_supplier_id, p_quotation_valid_until,
        p_payment_terms, p_delivery_terms, p_warranty_terms,
        p_created_by
    ) RETURNING quotation_id INTO v_quotation_id;
    
    RETURN v_quotation_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Function to add item to quotation
CREATE OR REPLACE FUNCTION bms.add_quotation_item(
    p_quotation_id UUID,
    p_request_item_id UUID DEFAULT NULL,
    p_material_id UUID DEFAULT NULL,
    p_item_description TEXT,
    p_quoted_quantity DECIMAL(15,6),
    p_unit_id UUID,
    p_unit_price DECIMAL(12,2),
    p_brand VARCHAR(100) DEFAULT NULL,
    p_model VARCHAR(100) DEFAULT NULL,
    p_specifications JSONB DEFAULT NULL,
    p_delivery_lead_time INTEGER DEFAULT NULL,
    p_warranty_period INTEGER DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_quotation_item_id UUID;
    v_line_number INTEGER;
    v_company_id UUID;
    v_total_price DECIMAL(15,2);
BEGIN
    -- Get company_id and next line number
    SELECT 
        pq.company_id,
        COALESCE(MAX(pqi.line_number), 0) + 1
    INTO v_company_id, v_line_number
    FROM bms.purchase_quotations pq
    LEFT JOIN bms.purchase_quotation_items pqi ON pq.quotation_id = pqi.quotation_id
    WHERE pq.quotation_id = p_quotation_id
    GROUP BY pq.company_id;
    
    -- Calculate total price
    v_total_price := p_quoted_quantity * p_unit_price;
    
    -- Insert quotation item
    INSERT INTO bms.purchase_quotation_items (
        company_id, quotation_id, line_number, request_item_id,
        material_id, item_description, quoted_quantity, unit_id,
        unit_price, total_price, brand, model, specifications,
        delivery_lead_time, warranty_period
    ) VALUES (
        v_company_id, p_quotation_id, v_line_number, p_request_item_id,
        p_material_id, p_item_description, p_quoted_quantity, p_unit_id,
        p_unit_price, v_total_price, p_brand, p_model, p_specifications,
        p_delivery_lead_time, p_warranty_period
    ) RETURNING quotation_item_id INTO v_quotation_item_id;
    
    -- Update quotation totals
    PERFORM bms.update_quotation_totals(p_quotation_id);
    
    RETURN v_quotation_item_id;
END;
$$ LANGUAGE plpgsql;

-- 6. Function to update quotation totals
CREATE OR REPLACE FUNCTION bms.update_quotation_totals(
    p_quotation_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_subtotal DECIMAL(15,2);
    v_tax_rate DECIMAL(5,4) := 0.10; -- 10% VAT
BEGIN
    -- Calculate subtotal
    SELECT COALESCE(SUM(total_price), 0)
    INTO v_subtotal
    FROM bms.purchase_quotation_items 
    WHERE quotation_id = p_quotation_id;
    
    -- Update quotation totals
    UPDATE bms.purchase_quotations 
    SET 
        subtotal_amount = v_subtotal,
        tax_amount = v_subtotal * v_tax_rate,
        total_amount = v_subtotal * (1 + v_tax_rate),
        updated_at = NOW()
    WHERE quotation_id = p_quotation_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Function to select winning quotation
CREATE OR REPLACE FUNCTION bms.select_quotation(
    p_quotation_id UUID,
    p_selection_reason TEXT DEFAULT NULL,
    p_selected_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_quotation RECORD;
BEGIN
    -- Get quotation details
    SELECT * INTO v_quotation
    FROM bms.purchase_quotations 
    WHERE quotation_id = p_quotation_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Quotation not found: %', p_quotation_id;
    END IF;
    
    -- Mark other quotations for same request as not selected
    IF v_quotation.request_id IS NOT NULL THEN
        UPDATE bms.purchase_quotations 
        SET 
            is_selected = FALSE,
            quotation_status = 'REJECTED',
            updated_at = NOW()
        WHERE request_id = v_quotation.request_id 
          AND quotation_id != p_quotation_id;
    END IF;
    
    -- Mark this quotation as selected
    UPDATE bms.purchase_quotations 
    SET 
        is_selected = TRUE,
        quotation_status = 'SELECTED',
        selection_reason = p_selection_reason,
        selected_by = p_selected_by,
        selection_date = NOW(),
        updated_at = NOW()
    WHERE quotation_id = p_quotation_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Function to create purchase order from quotation
CREATE OR REPLACE FUNCTION bms.create_purchase_order_from_quotation(
    p_quotation_id UUID,
    p_delivery_address TEXT,
    p_delivery_contact_person VARCHAR(100) DEFAULT NULL,
    p_delivery_contact_phone VARCHAR(20) DEFAULT NULL,
    p_requested_delivery_date DATE DEFAULT NULL,
    p_special_conditions TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_order_id UUID;
    v_order_number VARCHAR(50);
    v_quotation RECORD;
    v_year INTEGER;
    v_sequence INTEGER;
    v_item RECORD;
BEGIN
    -- Get quotation details
    SELECT * INTO v_quotation
    FROM bms.purchase_quotations 
    WHERE quotation_id = p_quotation_id AND is_selected = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Selected quotation not found: %', p_quotation_id;
    END IF;
    
    -- Generate order number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 'PO-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.purchase_orders 
    WHERE company_id = v_quotation.company_id 
      AND order_number LIKE 'PO-' || v_year || '-%';
    
    v_order_number := 'PO-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Create purchase order
    INSERT INTO bms.purchase_orders (
        company_id, order_number, order_title,
        request_id, quotation_id, supplier_id,
        delivery_address, delivery_contact_person, delivery_contact_phone,
        requested_delivery_date, payment_terms, delivery_terms,
        warranty_terms, special_conditions,
        subtotal_amount, tax_amount, discount_amount, total_amount,
        currency_code, created_by
    ) VALUES (
        v_quotation.company_id, v_order_number, v_quotation.quotation_title,
        v_quotation.request_id, p_quotation_id, v_quotation.supplier_id,
        p_delivery_address, p_delivery_contact_person, p_delivery_contact_phone,
        p_requested_delivery_date, v_quotation.payment_terms, v_quotation.delivery_terms,
        v_quotation.warranty_terms, p_special_conditions,
        v_quotation.subtotal_amount, v_quotation.tax_amount, v_quotation.discount_amount, v_quotation.total_amount,
        v_quotation.currency_code, p_created_by
    ) RETURNING order_id INTO v_order_id;
    
    -- Copy quotation items to order items
    FOR v_item IN 
        SELECT * FROM bms.purchase_quotation_items 
        WHERE quotation_id = p_quotation_id
        ORDER BY line_number
    LOOP
        INSERT INTO bms.purchase_order_items (
            company_id, order_id, line_number, quotation_item_id,
            material_id, item_description, ordered_quantity, unit_id,
            unit_price, total_price, brand, model, specifications,
            delivery_lead_time, warranty_period, warranty_terms
        ) VALUES (
            v_item.company_id, v_order_id, v_item.line_number, v_item.quotation_item_id,
            v_item.material_id, v_item.item_description, v_item.quoted_quantity, v_item.unit_id,
            v_item.unit_price, v_item.total_price, v_item.brand, v_item.model, v_item.specifications,
            v_item.delivery_lead_time, v_item.warranty_period, v_item.warranty_terms
        );
    END LOOP;
    
    RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;--
 9. Function to create goods receipt
CREATE OR REPLACE FUNCTION bms.create_goods_receipt(
    p_order_id UUID,
    p_delivery_note_number VARCHAR(50) DEFAULT NULL,
    p_delivery_date DATE DEFAULT CURRENT_DATE,
    p_delivery_person VARCHAR(100) DEFAULT NULL,
    p_received_by UUID,
    p_receipt_location VARCHAR(200) DEFAULT NULL,
    p_inspection_required BOOLEAN DEFAULT TRUE,
    p_receipt_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_receipt_id UUID;
    v_receipt_number VARCHAR(50);
    v_company_id UUID;
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Get company_id from order
    SELECT company_id INTO v_company_id
    FROM bms.purchase_orders 
    WHERE order_id = p_order_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Purchase order not found: %', p_order_id;
    END IF;
    
    -- Generate receipt number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(receipt_number FROM 'GR-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.goods_receipts 
    WHERE company_id = v_company_id 
      AND receipt_number LIKE 'GR-' || v_year || '-%';
    
    v_receipt_number := 'GR-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Create goods receipt
    INSERT INTO bms.goods_receipts (
        company_id, receipt_number, order_id,
        delivery_note_number, delivery_date, delivery_person,
        received_by, receipt_location, inspection_required,
        receipt_notes, created_by
    ) VALUES (
        v_company_id, v_receipt_number, p_order_id,
        p_delivery_note_number, p_delivery_date, p_delivery_person,
        p_received_by, p_receipt_location, p_inspection_required,
        p_receipt_notes, p_received_by
    ) RETURNING receipt_id INTO v_receipt_id;
    
    RETURN v_receipt_id;
END;
$$ LANGUAGE plpgsql;

-- 10. Function to add item to goods receipt
CREATE OR REPLACE FUNCTION bms.add_goods_receipt_item(
    p_receipt_id UUID,
    p_order_item_id UUID,
    p_delivered_quantity DECIMAL(15,6),
    p_accepted_quantity DECIMAL(15,6) DEFAULT NULL,
    p_rejected_quantity DECIMAL(15,6) DEFAULT 0,
    p_inspection_result VARCHAR(20) DEFAULT 'PENDING',
    p_quality_grade VARCHAR(20) DEFAULT NULL,
    p_batch_number VARCHAR(50) DEFAULT NULL,
    p_expiry_date DATE DEFAULT NULL,
    p_storage_location_id UUID DEFAULT NULL,
    p_item_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_receipt_item_id UUID;
    v_line_number INTEGER;
    v_company_id UUID;
    v_order_item RECORD;
BEGIN
    -- Get company_id and order item details
    SELECT 
        gr.company_id,
        COALESCE(MAX(gri.line_number), 0) + 1,
        poi.*
    INTO v_company_id, v_line_number, v_order_item
    FROM bms.goods_receipts gr
    LEFT JOIN bms.goods_receipt_items gri ON gr.receipt_id = gri.receipt_id
    JOIN bms.purchase_order_items poi ON poi.order_item_id = p_order_item_id
    WHERE gr.receipt_id = p_receipt_id
    GROUP BY gr.company_id, poi.order_item_id, poi.material_id, poi.item_description, 
             poi.ordered_quantity, poi.unit_id;
    
    -- Set accepted quantity if not provided
    IF p_accepted_quantity IS NULL THEN
        p_accepted_quantity := p_delivered_quantity - p_rejected_quantity;
    END IF;
    
    -- Insert receipt item
    INSERT INTO bms.goods_receipt_items (
        company_id, receipt_id, line_number, order_item_id,
        material_id, item_description, ordered_quantity,
        delivered_quantity, accepted_quantity, rejected_quantity,
        unit_id, inspection_result, quality_grade,
        batch_number, expiry_date, storage_location_id, item_notes
    ) VALUES (
        v_company_id, p_receipt_id, v_line_number, p_order_item_id,
        v_order_item.material_id, v_order_item.item_description, v_order_item.ordered_quantity,
        p_delivered_quantity, p_accepted_quantity, p_rejected_quantity,
        v_order_item.unit_id, p_inspection_result, p_quality_grade,
        p_batch_number, p_expiry_date, p_storage_location_id, p_item_notes
    ) RETURNING receipt_item_id INTO v_receipt_item_id;
    
    -- Update order item delivered quantity
    UPDATE bms.purchase_order_items 
    SET 
        delivered_quantity = delivered_quantity + p_delivered_quantity,
        received_quantity = received_quantity + p_accepted_quantity,
        item_status = CASE 
            WHEN delivered_quantity + p_delivered_quantity >= ordered_quantity THEN 'DELIVERED'
            ELSE 'IN_TRANSIT'
        END,
        actual_delivery_date = CURRENT_DATE,
        updated_at = NOW()
    WHERE order_item_id = p_order_item_id;
    
    -- Create inventory transaction for accepted quantity
    IF p_accepted_quantity > 0 AND v_order_item.material_id IS NOT NULL AND p_storage_location_id IS NOT NULL THEN
        PERFORM bms.create_inventory_receipt_transaction(
            v_company_id,
            v_order_item.material_id,
            p_storage_location_id,
            p_accepted_quantity,
            v_order_item.unit_id,
            v_order_item.unit_price,
            p_batch_number,
            p_expiry_date,
            'PURCHASE_ORDER',
            v_order_item.order_id::TEXT,
            'Goods receipt from purchase order'
        );
    END IF;
    
    RETURN v_receipt_item_id;
END;
$$ LANGUAGE plpgsql;

-- 11. Function to create inventory receipt transaction
CREATE OR REPLACE FUNCTION bms.create_inventory_receipt_transaction(
    p_company_id UUID,
    p_material_id UUID,
    p_location_id UUID,
    p_quantity DECIMAL(15,6),
    p_unit_id UUID,
    p_unit_cost DECIMAL(12,2),
    p_batch_number VARCHAR(50) DEFAULT NULL,
    p_expiry_date DATE DEFAULT NULL,
    p_reference_type VARCHAR(30) DEFAULT 'PURCHASE_ORDER',
    p_reference_number VARCHAR(50) DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_transaction_id UUID;
    v_transaction_number VARCHAR(50);
BEGIN
    -- Generate transaction number
    v_transaction_number := 'REC-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                           LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 10, '0');
    
    -- Create inventory transaction
    INSERT INTO bms.inventory_transactions (
        company_id, transaction_number, transaction_type,
        material_id, location_id, quantity, unit_id,
        unit_cost, total_cost, batch_number, expiry_date,
        reference_type, reference_number, transaction_notes
    ) VALUES (
        p_company_id, v_transaction_number, 'RECEIPT',
        p_material_id, p_location_id, p_quantity, p_unit_id,
        p_unit_cost, p_unit_cost * p_quantity, p_batch_number, p_expiry_date,
        p_reference_type, p_reference_number, p_notes
    ) RETURNING transaction_id INTO v_transaction_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- 12. Function to create purchase invoice
CREATE OR REPLACE FUNCTION bms.create_purchase_invoice(
    p_company_id UUID,
    p_supplier_invoice_number VARCHAR(50),
    p_invoice_date DATE,
    p_due_date DATE DEFAULT NULL,
    p_order_id UUID DEFAULT NULL,
    p_receipt_id UUID DEFAULT NULL,
    p_supplier_id UUID,
    p_subtotal_amount DECIMAL(15,2),
    p_tax_amount DECIMAL(15,2) DEFAULT 0,
    p_discount_amount DECIMAL(15,2) DEFAULT 0,
    p_payment_terms VARCHAR(100) DEFAULT NULL,
    p_payment_method VARCHAR(30) DEFAULT 'BANK_TRANSFER',
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_invoice_id UUID;
    v_invoice_number VARCHAR(50);
    v_total_amount DECIMAL(15,2);
    v_year INTEGER;
    v_sequence INTEGER;
BEGIN
    -- Calculate total amount
    v_total_amount := p_subtotal_amount + p_tax_amount - p_discount_amount;
    
    -- Generate invoice number
    v_year := EXTRACT(YEAR FROM NOW());
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number FROM 'INV-' || v_year || '-(.*)') AS INTEGER)), 0) + 1
    INTO v_sequence
    FROM bms.purchase_invoices 
    WHERE company_id = p_company_id 
      AND invoice_number LIKE 'INV-' || v_year || '-%';
    
    v_invoice_number := 'INV-' || v_year || '-' || LPAD(v_sequence::TEXT, 4, '0');
    
    -- Create invoice
    INSERT INTO bms.purchase_invoices (
        company_id, invoice_number, supplier_invoice_number,
        invoice_date, due_date, order_id, receipt_id, supplier_id,
        subtotal_amount, tax_amount, discount_amount, total_amount,
        payment_terms, payment_method, created_by
    ) VALUES (
        p_company_id, v_invoice_number, p_supplier_invoice_number,
        p_invoice_date, p_due_date, p_order_id, p_receipt_id, p_supplier_id,
        p_subtotal_amount, p_tax_amount, p_discount_amount, v_total_amount,
        p_payment_terms, p_payment_method, p_created_by
    ) RETURNING invoice_id INTO v_invoice_id;
    
    RETURN v_invoice_id;
END;
$$ LANGUAGE plpgsql;

-- 13. Function to approve purchase invoice
CREATE OR REPLACE FUNCTION bms.approve_purchase_invoice(
    p_invoice_id UUID,
    p_approved_by UUID,
    p_approval_notes TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    UPDATE bms.purchase_invoices 
    SET 
        approval_status = 'APPROVED',
        invoice_status = 'APPROVED',
        approved_by = p_approved_by,
        approval_date = NOW(),
        approval_notes = p_approval_notes,
        updated_at = NOW()
    WHERE invoice_id = p_invoice_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invoice not found: %', p_invoice_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 14. Function to process invoice payment
CREATE OR REPLACE FUNCTION bms.process_invoice_payment(
    p_invoice_id UUID,
    p_paid_amount DECIMAL(15,2),
    p_payment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    p_payment_reference VARCHAR(100) DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_invoice RECORD;
    v_new_paid_amount DECIMAL(15,2);
BEGIN
    -- Get invoice details
    SELECT * INTO v_invoice
    FROM bms.purchase_invoices 
    WHERE invoice_id = p_invoice_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invoice not found: %', p_invoice_id;
    END IF;
    
    -- Calculate new paid amount
    v_new_paid_amount := v_invoice.paid_amount + p_paid_amount;
    
    IF v_new_paid_amount > v_invoice.total_amount THEN
        RAISE EXCEPTION 'Payment amount exceeds invoice total. Invoice: %, Paid: %, New Payment: %', 
            v_invoice.total_amount, v_invoice.paid_amount, p_paid_amount;
    END IF;
    
    -- Update invoice payment status
    UPDATE bms.purchase_invoices 
    SET 
        paid_amount = v_new_paid_amount,
        payment_date = CASE 
            WHEN v_new_paid_amount = total_amount THEN p_payment_date
            ELSE payment_date
        END,
        payment_reference = COALESCE(payment_reference, p_payment_reference),
        payment_status = CASE 
            WHEN v_new_paid_amount = total_amount THEN 'COMPLETED'
            WHEN v_new_paid_amount > 0 THEN 'PARTIAL'
            ELSE 'PENDING'
        END,
        invoice_status = CASE 
            WHEN v_new_paid_amount = total_amount THEN 'PAID'
            ELSE invoice_status
        END,
        updated_by = p_processed_by,
        updated_at = NOW()
    WHERE invoice_id = p_invoice_id;
    
    -- Update related purchase order payment status
    IF v_invoice.order_id IS NOT NULL THEN
        UPDATE bms.purchase_orders 
        SET 
            payment_status = CASE 
                WHEN v_new_paid_amount = v_invoice.total_amount THEN 'COMPLETED'
                WHEN v_new_paid_amount > 0 THEN 'PARTIAL'
                ELSE 'PENDING'
            END,
            updated_at = NOW()
        WHERE order_id = v_invoice.order_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 15. Function to get purchase request status summary
CREATE OR REPLACE FUNCTION bms.get_purchase_request_summary(
    p_company_id UUID,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    status VARCHAR(20),
    request_count BIGINT,
    total_amount DECIMAL(15,2),
    avg_amount DECIMAL(15,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.request_status,
        COUNT(*) as request_count,
        COALESCE(SUM(pr.estimated_total_amount), 0) as total_amount,
        COALESCE(AVG(pr.estimated_total_amount), 0) as avg_amount
    FROM bms.purchase_requests pr
    WHERE pr.company_id = p_company_id
      AND (p_start_date IS NULL OR pr.request_date >= p_start_date)
      AND (p_end_date IS NULL OR pr.request_date <= p_end_date)
    GROUP BY pr.request_status
    ORDER BY pr.request_status;
END;
$$ LANGUAGE plpgsql;

-- 16. Function to get supplier performance report
CREATE OR REPLACE FUNCTION bms.get_supplier_performance_report(
    p_company_id UUID,
    p_supplier_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS TABLE (
    supplier_id UUID,
    supplier_name VARCHAR(200),
    total_orders BIGINT,
    total_amount DECIMAL(15,2),
    on_time_deliveries BIGINT,
    late_deliveries BIGINT,
    on_time_percentage DECIMAL(5,2),
    avg_delivery_days DECIMAL(8,2),
    quality_issues BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.supplier_id,
        s.supplier_name,
        COUNT(DISTINCT po.order_id) as total_orders,
        COALESCE(SUM(po.total_amount), 0) as total_amount,
        COUNT(CASE WHEN poi.actual_delivery_date <= poi.scheduled_delivery_date THEN 1 END) as on_time_deliveries,
        COUNT(CASE WHEN poi.actual_delivery_date > poi.scheduled_delivery_date THEN 1 END) as late_deliveries,
        CASE 
            WHEN COUNT(poi.order_item_id) > 0 
            THEN (COUNT(CASE WHEN poi.actual_delivery_date <= poi.scheduled_delivery_date THEN 1 END) * 100.0 / COUNT(poi.order_item_id))
            ELSE 0
        END as on_time_percentage,
        COALESCE(AVG(EXTRACT(DAYS FROM poi.actual_delivery_date - po.order_date)), 0) as avg_delivery_days,
        COUNT(CASE WHEN gri.inspection_result = 'FAILED' THEN 1 END) as quality_issues
    FROM bms.suppliers s
    LEFT JOIN bms.purchase_orders po ON s.supplier_id = po.supplier_id
    LEFT JOIN bms.purchase_order_items poi ON po.order_id = poi.order_id
    LEFT JOIN bms.goods_receipt_items gri ON poi.order_item_id = gri.order_item_id
    WHERE s.company_id = p_company_id
      AND (p_supplier_id IS NULL OR s.supplier_id = p_supplier_id)
      AND (p_start_date IS NULL OR po.order_date >= p_start_date)
      AND (p_end_date IS NULL OR po.order_date <= p_end_date)
    GROUP BY s.supplier_id, s.supplier_name
    ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql;

-- Comments for functions
COMMENT ON FUNCTION bms.create_purchase_request(UUID, VARCHAR, VARCHAR, UUID, VARCHAR, TEXT, VARCHAR, DATE, VARCHAR, DECIMAL, VARCHAR) IS 'Create new purchase request';
COMMENT ON FUNCTION bms.add_purchase_request_item(UUID, UUID, TEXT, DECIMAL, UUID, DECIMAL, JSONB, DATE, TEXT) IS 'Add item to purchase request';
COMMENT ON FUNCTION bms.submit_purchase_request(UUID, UUID) IS 'Submit purchase request for approval';
COMMENT ON FUNCTION bms.create_purchase_quotation(UUID, VARCHAR, UUID, UUID, DATE, VARCHAR, VARCHAR, VARCHAR, UUID) IS 'Create purchase quotation from supplier';
COMMENT ON FUNCTION bms.add_quotation_item(UUID, UUID, UUID, TEXT, DECIMAL, UUID, DECIMAL, VARCHAR, VARCHAR, JSONB, INTEGER, INTEGER) IS 'Add item to purchase quotation';
COMMENT ON FUNCTION bms.update_quotation_totals(UUID) IS 'Update quotation total amounts';
COMMENT ON FUNCTION bms.select_quotation(UUID, TEXT, UUID) IS 'Select winning quotation';
COMMENT ON FUNCTION bms.create_purchase_order_from_quotation(UUID, TEXT, VARCHAR, VARCHAR, DATE, TEXT, UUID) IS 'Create purchase order from selected quotation';
COMMENT ON FUNCTION bms.create_goods_receipt(UUID, VARCHAR, DATE, VARCHAR, UUID, VARCHAR, BOOLEAN, TEXT) IS 'Create goods receipt for delivered items';
COMMENT ON FUNCTION bms.add_goods_receipt_item(UUID, UUID, DECIMAL, DECIMAL, DECIMAL, VARCHAR, VARCHAR, VARCHAR, DATE, UUID, TEXT) IS 'Add item to goods receipt';
COMMENT ON FUNCTION bms.create_inventory_receipt_transaction(UUID, UUID, UUID, DECIMAL, UUID, DECIMAL, VARCHAR, DATE, VARCHAR, VARCHAR, TEXT) IS 'Create inventory transaction for goods receipt';
COMMENT ON FUNCTION bms.create_purchase_invoice(UUID, VARCHAR, DATE, DATE, UUID, UUID, UUID, DECIMAL, DECIMAL, DECIMAL, VARCHAR, VARCHAR, UUID) IS 'Create purchase invoice';
COMMENT ON FUNCTION bms.approve_purchase_invoice(UUID, UUID, TEXT) IS 'Approve purchase invoice for payment';
COMMENT ON FUNCTION bms.process_invoice_payment(UUID, DECIMAL, TIMESTAMP WITH TIME ZONE, VARCHAR, UUID) IS 'Process invoice payment';
COMMENT ON FUNCTION bms.get_purchase_request_summary(UUID, DATE, DATE) IS 'Get purchase request status summary';
COMMENT ON FUNCTION bms.get_supplier_performance_report(UUID, UUID, DATE, DATE) IS 'Get supplier performance report';

-- Script completion message
SELECT 'Procurement Management Functions created successfully!' as status;