-- =====================================================
-- Inventory Management Functions
-- Phase 4.4.2: Inventory Management Functions and Procedures
-- =====================================================

-- 1. Function to update inventory balance after transaction
CREATE OR REPLACE FUNCTION bms.update_inventory_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_current_balance DECIMAL(15,6) := 0;
    v_balance_exists BOOLEAN := FALSE;
BEGIN
    -- Check if balance record exists
    SELECT 
        current_quantity,
        TRUE
    INTO 
        v_current_balance,
        v_balance_exists
    FROM bms.inventory_balances 
    WHERE company_id = NEW.company_id 
      AND material_id = NEW.material_id 
      AND location_id = NEW.location_id;
    
    -- Create balance record if it doesn't exist
    IF NOT v_balance_exists THEN
        INSERT INTO bms.inventory_balances (
            company_id, material_id, location_id, unit_id,
            current_quantity, available_quantity, good_quantity
        ) VALUES (
            NEW.company_id, NEW.material_id, NEW.location_id, NEW.unit_id,
            0, 0, 0
        );
        v_current_balance := 0;
    END IF;
    
    -- Update balance based on transaction type
    IF NEW.transaction_type IN ('RECEIPT', 'ADJUSTMENT') THEN
        -- Increase inventory
        UPDATE bms.inventory_balances 
        SET 
            current_quantity = current_quantity + NEW.quantity,
            available_quantity = available_quantity + NEW.quantity,
            good_quantity = CASE 
                WHEN NEW.quality_status = 'GOOD' THEN good_quantity + NEW.quantity
                WHEN NEW.quality_status = 'DAMAGED' THEN good_quantity,
                damaged_quantity = damaged_quantity + NEW.quantity
                ELSE good_quantity
            END,
            damaged_quantity = CASE 
                WHEN NEW.quality_status = 'DAMAGED' THEN damaged_quantity + NEW.quantity
                ELSE damaged_quantity
            END,
            quarantine_quantity = CASE 
                WHEN NEW.quality_status = 'QUARANTINE' THEN quarantine_quantity + NEW.quantity
                ELSE quarantine_quantity
            END,
            total_value = total_value + NEW.total_cost,
            average_unit_cost = CASE 
                WHEN (current_quantity + NEW.quantity) > 0 
                THEN (total_value + NEW.total_cost) / (current_quantity + NEW.quantity)
                ELSE 0
            END,
            last_cost = NEW.unit_cost,
            last_transaction_id = NEW.transaction_id,
            last_transaction_date = NEW.transaction_date,
            last_receipt_date = NEW.transaction_date,
            updated_at = NOW()
        WHERE company_id = NEW.company_id 
          AND material_id = NEW.material_id 
          AND location_id = NEW.location_id;
          
    ELSIF NEW.transaction_type IN ('ISSUE', 'TRANSFER', 'DISPOSAL') THEN
        -- Decrease inventory
        UPDATE bms.inventory_balances 
        SET 
            current_quantity = current_quantity - NEW.quantity,
            available_quantity = available_quantity - NEW.quantity,
            good_quantity = CASE 
                WHEN NEW.quality_status = 'GOOD' THEN good_quantity - NEW.quantity
                ELSE good_quantity
            END,
            damaged_quantity = CASE 
                WHEN NEW.quality_status = 'DAMAGED' THEN damaged_quantity - NEW.quantity
                ELSE damaged_quantity
            END,
            quarantine_quantity = CASE 
                WHEN NEW.quality_status = 'QUARANTINE' THEN quarantine_quantity - NEW.quantity
                ELSE quarantine_quantity
            END,
            total_value = GREATEST(0, total_value - (average_unit_cost * NEW.quantity)),
            last_transaction_id = NEW.transaction_id,
            last_transaction_date = NEW.transaction_date,
            last_issue_date = NEW.transaction_date,
            updated_at = NOW()
        WHERE company_id = NEW.company_id 
          AND material_id = NEW.material_id 
          AND location_id = NEW.location_id;
    END IF;
    
    -- Update reorder flags
    PERFORM bms.update_reorder_flags(NEW.company_id, NEW.material_id, NEW.location_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Function to update reorder flags
CREATE OR REPLACE FUNCTION bms.update_reorder_flags(
    p_company_id UUID,
    p_material_id UUID,
    p_location_id UUID
)
RETURNS VOID AS $$
BEGIN
    UPDATE bms.inventory_balances 
    SET 
        below_minimum = (current_quantity < minimum_quantity AND minimum_quantity > 0),
        needs_reorder = (current_quantity <= reorder_point AND reorder_point > 0),
        above_maximum = (current_quantity > maximum_quantity AND maximum_quantity > 0),
        updated_at = NOW()
    WHERE company_id = p_company_id 
      AND material_id = p_material_id 
      AND location_id = p_location_id;
END;
$$ LANGUAGE plpgsql;

-- 3. Function to reserve inventory
CREATE OR REPLACE FUNCTION bms.reserve_inventory(
    p_company_id UUID,
    p_material_id UUID,
    p_location_id UUID,
    p_quantity DECIMAL(15,6),
    p_unit_id UUID,
    p_reservation_type VARCHAR(30),
    p_reserved_for_type VARCHAR(30),
    p_reserved_for_id UUID,
    p_required_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_notes TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_reservation_id UUID;
    v_reservation_number VARCHAR(50);
    v_available_quantity DECIMAL(15,6);
BEGIN
    -- Check available quantity
    SELECT available_quantity 
    INTO v_available_quantity
    FROM bms.inventory_balances 
    WHERE company_id = p_company_id 
      AND material_id = p_material_id 
      AND location_id = p_location_id;
    
    IF v_available_quantity IS NULL OR v_available_quantity < p_quantity THEN
        RAISE EXCEPTION 'Insufficient inventory available. Available: %, Requested: %', 
            COALESCE(v_available_quantity, 0), p_quantity;
    END IF;
    
    -- Generate reservation number
    v_reservation_number := 'RSV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                           LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 10, '0');
    
    -- Create reservation
    INSERT INTO bms.inventory_reservations (
        company_id, reservation_number, reservation_type,
        material_id, location_id, reserved_quantity, unit_id,
        reserved_for_type, reserved_for_id,
        required_date, reservation_notes, created_by,
        remaining_quantity
    ) VALUES (
        p_company_id, v_reservation_number, p_reservation_type,
        p_material_id, p_location_id, p_quantity, p_unit_id,
        p_reserved_for_type, p_reserved_for_id,
        p_required_date, p_notes, p_created_by,
        p_quantity
    ) RETURNING reservation_id INTO v_reservation_id;
    
    -- Update inventory balance
    UPDATE bms.inventory_balances 
    SET 
        available_quantity = available_quantity - p_quantity,
        reserved_quantity = reserved_quantity + p_quantity,
        updated_at = NOW()
    WHERE company_id = p_company_id 
      AND material_id = p_material_id 
      AND location_id = p_location_id;
    
    RETURN v_reservation_id;
END;
$$ LANGUAGE plpgsql;

-- 4. Function to fulfill reservation
CREATE OR REPLACE FUNCTION bms.fulfill_reservation(
    p_reservation_id UUID,
    p_fulfill_quantity DECIMAL(15,6),
    p_transaction_notes TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_reservation RECORD;
    v_transaction_id UUID;
    v_transaction_number VARCHAR(50);
BEGIN
    -- Get reservation details
    SELECT * INTO v_reservation
    FROM bms.inventory_reservations 
    WHERE reservation_id = p_reservation_id 
      AND reservation_status = 'ACTIVE';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active reservation not found: %', p_reservation_id;
    END IF;
    
    IF p_fulfill_quantity > v_reservation.remaining_quantity THEN
        RAISE EXCEPTION 'Fulfill quantity exceeds remaining quantity. Remaining: %, Requested: %', 
            v_reservation.remaining_quantity, p_fulfill_quantity;
    END IF;
    
    -- Generate transaction number
    v_transaction_number := 'ISS-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                           LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 10, '0');
    
    -- Create issue transaction
    INSERT INTO bms.inventory_transactions (
        company_id, transaction_number, transaction_type,
        material_id, location_id, quantity, unit_id,
        reference_type, reference_id,
        transaction_notes, created_by
    ) VALUES (
        v_reservation.company_id, v_transaction_number, 'ISSUE',
        v_reservation.material_id, v_reservation.location_id, 
        p_fulfill_quantity, v_reservation.unit_id,
        'RESERVATION', p_reservation_id,
        p_transaction_notes, p_created_by
    ) RETURNING transaction_id INTO v_transaction_id;
    
    -- Update reservation
    UPDATE bms.inventory_reservations 
    SET 
        fulfilled_quantity = fulfilled_quantity + p_fulfill_quantity,
        remaining_quantity = remaining_quantity - p_fulfill_quantity,
        reservation_status = CASE 
            WHEN remaining_quantity - p_fulfill_quantity = 0 THEN 'FULFILLED'
            ELSE 'PARTIALLY_FULFILLED'
        END,
        updated_at = NOW()
    WHERE reservation_id = p_reservation_id;
    
    -- Update inventory balance (reserved quantity)
    UPDATE bms.inventory_balances 
    SET 
        reserved_quantity = reserved_quantity - p_fulfill_quantity,
        updated_at = NOW()
    WHERE company_id = v_reservation.company_id 
      AND material_id = v_reservation.material_id 
      AND location_id = v_reservation.location_id;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- 5. Function to cancel reservation
CREATE OR REPLACE FUNCTION bms.cancel_reservation(
    p_reservation_id UUID,
    p_cancel_reason TEXT DEFAULT NULL,
    p_cancelled_by UUID DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
    v_reservation RECORD;
BEGIN
    -- Get reservation details
    SELECT * INTO v_reservation
    FROM bms.inventory_reservations 
    WHERE reservation_id = p_reservation_id 
      AND reservation_status IN ('ACTIVE', 'PARTIALLY_FULFILLED');
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Active reservation not found: %', p_reservation_id;
    END IF;
    
    -- Update reservation status
    UPDATE bms.inventory_reservations 
    SET 
        reservation_status = 'CANCELLED',
        reservation_notes = COALESCE(reservation_notes || E'\n', '') || 
                           'Cancelled: ' || COALESCE(p_cancel_reason, 'No reason provided'),
        updated_by = p_cancelled_by,
        updated_at = NOW()
    WHERE reservation_id = p_reservation_id;
    
    -- Release reserved quantity back to available
    UPDATE bms.inventory_balances 
    SET 
        available_quantity = available_quantity + v_reservation.remaining_quantity,
        reserved_quantity = reserved_quantity - v_reservation.remaining_quantity,
        updated_at = NOW()
    WHERE company_id = v_reservation.company_id 
      AND material_id = v_reservation.material_id 
      AND location_id = v_reservation.location_id;
END;
$$ LANGUAGE plpgsql;-- 6. 
Function to create cycle count
CREATE OR REPLACE FUNCTION bms.create_cycle_count(
    p_company_id UUID,
    p_count_name VARCHAR(100),
    p_count_type VARCHAR(30),
    p_location_id UUID DEFAULT NULL,
    p_material_category_id UUID DEFAULT NULL,
    p_scheduled_date DATE DEFAULT CURRENT_DATE,
    p_count_method VARCHAR(30) DEFAULT 'MANUAL',
    p_primary_counter_id UUID DEFAULT NULL,
    p_instructions TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_cycle_count_id UUID;
    v_count_number VARCHAR(50);
BEGIN
    -- Generate count number
    v_count_number := 'CC-' || TO_CHAR(p_scheduled_date, 'YYYYMMDD') || '-' || 
                     LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Create cycle count
    INSERT INTO bms.inventory_cycle_counts (
        company_id, count_number, count_name, count_type,
        location_id, material_category_id, scheduled_date,
        count_method, primary_counter_id, count_instructions,
        created_by
    ) VALUES (
        p_company_id, v_count_number, p_count_name, p_count_type,
        p_location_id, p_material_category_id, p_scheduled_date,
        p_count_method, p_primary_counter_id, p_instructions,
        p_created_by
    ) RETURNING cycle_count_id INTO v_cycle_count_id;
    
    RETURN v_cycle_count_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Function to process cycle count results
CREATE OR REPLACE FUNCTION bms.process_cycle_count_variance(
    p_cycle_count_id UUID,
    p_material_id UUID,
    p_location_id UUID,
    p_counted_quantity DECIMAL(15,6),
    p_system_quantity DECIMAL(15,6),
    p_unit_cost DECIMAL(12,2) DEFAULT 0,
    p_counter_notes TEXT DEFAULT NULL,
    p_processed_by UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_variance_quantity DECIMAL(15,6);
    v_transaction_id UUID;
    v_transaction_number VARCHAR(50);
    v_company_id UUID;
BEGIN
    -- Get company_id from cycle count
    SELECT company_id INTO v_company_id
    FROM bms.inventory_cycle_counts 
    WHERE cycle_count_id = p_cycle_count_id;
    
    -- Calculate variance
    v_variance_quantity := p_counted_quantity - p_system_quantity;
    
    -- Only create adjustment if there's a variance
    IF v_variance_quantity != 0 THEN
        -- Generate transaction number
        v_transaction_number := 'ADJ-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                               LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 10, '0');
        
        -- Create adjustment transaction
        INSERT INTO bms.inventory_transactions (
            company_id, transaction_number, transaction_type,
            material_id, location_id, quantity, unit_id,
            unit_cost, total_cost,
            reference_type, reference_id,
            transaction_reason, transaction_notes,
            physical_count_verified, verified_by, verification_date,
            variance_quantity, created_by
        ) VALUES (
            v_company_id, v_transaction_number, 'ADJUSTMENT',
            p_material_id, p_location_id, v_variance_quantity,
            (SELECT unit_id FROM bms.inventory_balances 
             WHERE company_id = v_company_id AND material_id = p_material_id AND location_id = p_location_id),
            p_unit_cost, p_unit_cost * ABS(v_variance_quantity),
            'CYCLE_COUNT', p_cycle_count_id,
            'Cycle count adjustment',
            COALESCE(p_counter_notes, 'Cycle count variance adjustment'),
            TRUE, p_processed_by, NOW(),
            v_variance_quantity, p_processed_by
        ) RETURNING transaction_id INTO v_transaction_id;
    END IF;
    
    RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Function to get inventory summary by location
CREATE OR REPLACE FUNCTION bms.get_inventory_summary_by_location(
    p_company_id UUID,
    p_location_id UUID DEFAULT NULL
)
RETURNS TABLE (
    location_id UUID,
    location_name VARCHAR(100),
    total_items BIGINT,
    total_value DECIMAL(15,2),
    items_below_minimum BIGINT,
    items_need_reorder BIGINT,
    items_above_maximum BIGINT,
    items_with_expired BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        il.location_id,
        il.location_name,
        COUNT(ib.balance_id) as total_items,
        COALESCE(SUM(ib.total_value), 0) as total_value,
        COUNT(CASE WHEN ib.below_minimum THEN 1 END) as items_below_minimum,
        COUNT(CASE WHEN ib.needs_reorder THEN 1 END) as items_need_reorder,
        COUNT(CASE WHEN ib.above_maximum THEN 1 END) as items_above_maximum,
        COUNT(CASE WHEN ib.has_expired_items THEN 1 END) as items_with_expired
    FROM bms.inventory_locations il
    LEFT JOIN bms.inventory_balances ib ON il.location_id = ib.location_id
    WHERE il.company_id = p_company_id
      AND (p_location_id IS NULL OR il.location_id = p_location_id)
      AND il.location_status = 'ACTIVE'
    GROUP BY il.location_id, il.location_name
    ORDER BY il.location_name;
END;
$$ LANGUAGE plpgsql;

-- 9. Function to get low stock report
CREATE OR REPLACE FUNCTION bms.get_low_stock_report(
    p_company_id UUID,
    p_location_id UUID DEFAULT NULL
)
RETURNS TABLE (
    material_id UUID,
    material_code VARCHAR(50),
    material_name VARCHAR(200),
    location_id UUID,
    location_name VARCHAR(100),
    current_quantity DECIMAL(15,6),
    minimum_quantity DECIMAL(15,6),
    reorder_point DECIMAL(15,6),
    reorder_quantity DECIMAL(15,6),
    unit_name VARCHAR(50),
    days_since_last_receipt INTEGER,
    average_monthly_usage DECIMAL(15,6)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.material_id,
        m.material_code,
        m.material_name,
        il.location_id,
        il.location_name,
        ib.current_quantity,
        ib.minimum_quantity,
        ib.reorder_point,
        ib.reorder_quantity,
        mu.unit_name,
        CASE 
            WHEN ib.last_receipt_date IS NOT NULL 
            THEN EXTRACT(DAYS FROM NOW() - ib.last_receipt_date)::INTEGER
            ELSE NULL
        END as days_since_last_receipt,
        -- Calculate average monthly usage from last 3 months of transactions
        COALESCE((
            SELECT ABS(AVG(it.quantity)) * 30
            FROM bms.inventory_transactions it
            WHERE it.company_id = p_company_id
              AND it.material_id = m.material_id
              AND it.location_id = il.location_id
              AND it.transaction_type = 'ISSUE'
              AND it.transaction_date >= NOW() - INTERVAL '90 days'
        ), 0) as average_monthly_usage
    FROM bms.inventory_balances ib
    JOIN bms.materials m ON ib.material_id = m.material_id
    JOIN bms.inventory_locations il ON ib.location_id = il.location_id
    JOIN bms.material_units mu ON ib.unit_id = mu.unit_id
    WHERE ib.company_id = p_company_id
      AND (p_location_id IS NULL OR ib.location_id = p_location_id)
      AND (ib.below_minimum OR ib.needs_reorder)
      AND ib.current_quantity >= 0
    ORDER BY 
        CASE WHEN ib.needs_reorder THEN 1 ELSE 2 END,
        ib.current_quantity / NULLIF(ib.minimum_quantity, 0) ASC;
END;
$$ LANGUAGE plpgsql;

-- 10. Function to get inventory movement history
CREATE OR REPLACE FUNCTION bms.get_inventory_movement_history(
    p_company_id UUID,
    p_material_id UUID,
    p_location_id UUID DEFAULT NULL,
    p_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_end_date TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    transaction_id UUID,
    transaction_number VARCHAR(50),
    transaction_type VARCHAR(20),
    transaction_date TIMESTAMP WITH TIME ZONE,
    quantity DECIMAL(15,6),
    unit_name VARCHAR(50),
    unit_cost DECIMAL(12,2),
    total_cost DECIMAL(15,2),
    location_name VARCHAR(100),
    reference_type VARCHAR(30),
    reference_number VARCHAR(50),
    transaction_notes TEXT,
    created_by_name VARCHAR(100)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        it.transaction_id,
        it.transaction_number,
        it.transaction_type,
        it.transaction_date,
        it.quantity,
        mu.unit_name,
        it.unit_cost,
        it.total_cost,
        il.location_name,
        it.reference_type,
        it.reference_number,
        it.transaction_notes,
        u.user_name as created_by_name
    FROM bms.inventory_transactions it
    JOIN bms.inventory_locations il ON it.location_id = il.location_id
    JOIN bms.material_units mu ON it.unit_id = mu.unit_id
    LEFT JOIN bms.users u ON it.created_by = u.user_id
    WHERE it.company_id = p_company_id
      AND it.material_id = p_material_id
      AND (p_location_id IS NULL OR it.location_id = p_location_id)
      AND (p_start_date IS NULL OR it.transaction_date >= p_start_date)
      AND (p_end_date IS NULL OR it.transaction_date <= p_end_date)
    ORDER BY it.transaction_date DESC, it.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for inventory balance updates
CREATE TRIGGER inventory_transactions_balance_trigger
    AFTER INSERT ON bms.inventory_transactions
    FOR EACH ROW EXECUTE FUNCTION bms.update_inventory_balance();

-- Create trigger for reservation remaining quantity calculation
CREATE OR REPLACE FUNCTION bms.update_reservation_remaining_quantity()
RETURNS TRIGGER AS $$
BEGIN
    NEW.remaining_quantity := NEW.reserved_quantity - NEW.fulfilled_quantity;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER inventory_reservations_remaining_quantity_trigger
    BEFORE INSERT OR UPDATE ON bms.inventory_reservations
    FOR EACH ROW EXECUTE FUNCTION bms.update_reservation_remaining_quantity();

-- Views for common inventory queries
CREATE OR REPLACE VIEW bms.v_inventory_current_stock AS
SELECT 
    ib.company_id,
    m.material_id,
    m.material_code,
    m.material_name,
    mc.category_name,
    il.location_id,
    il.location_code,
    il.location_name,
    ib.current_quantity,
    ib.available_quantity,
    ib.reserved_quantity,
    ib.good_quantity,
    ib.damaged_quantity,
    ib.quarantine_quantity,
    mu.unit_name,
    ib.average_unit_cost,
    ib.total_value,
    ib.minimum_quantity,
    ib.maximum_quantity,
    ib.reorder_point,
    ib.reorder_quantity,
    ib.below_minimum,
    ib.needs_reorder,
    ib.above_maximum,
    ib.has_expired_items,
    ib.last_transaction_date,
    ib.last_receipt_date,
    ib.last_issue_date
FROM bms.inventory_balances ib
JOIN bms.materials m ON ib.material_id = m.material_id
JOIN bms.material_categories mc ON m.category_id = mc.category_id
JOIN bms.inventory_locations il ON ib.location_id = il.location_id
JOIN bms.material_units mu ON ib.unit_id = mu.unit_id
WHERE ib.current_quantity > 0;

-- Comments for functions
COMMENT ON FUNCTION bms.update_inventory_balance() IS 'Trigger function to update inventory balances after transactions';
COMMENT ON FUNCTION bms.update_reorder_flags(UUID, UUID, UUID) IS 'Update reorder flags based on current quantities and thresholds';
COMMENT ON FUNCTION bms.reserve_inventory(UUID, UUID, UUID, DECIMAL, UUID, VARCHAR, VARCHAR, UUID, TIMESTAMP WITH TIME ZONE, TEXT, UUID) IS 'Reserve inventory for specific purposes';
COMMENT ON FUNCTION bms.fulfill_reservation(UUID, DECIMAL, TEXT, UUID) IS 'Fulfill inventory reservation and create issue transaction';
COMMENT ON FUNCTION bms.cancel_reservation(UUID, TEXT, UUID) IS 'Cancel inventory reservation and release reserved quantity';
COMMENT ON FUNCTION bms.create_cycle_count(UUID, VARCHAR, VARCHAR, UUID, UUID, DATE, VARCHAR, UUID, TEXT, UUID) IS 'Create new cycle count for inventory verification';
COMMENT ON FUNCTION bms.process_cycle_count_variance(UUID, UUID, UUID, DECIMAL, DECIMAL, DECIMAL, TEXT, UUID) IS 'Process cycle count variance and create adjustment transactions';
COMMENT ON FUNCTION bms.get_inventory_summary_by_location(UUID, UUID) IS 'Get inventory summary statistics by location';
COMMENT ON FUNCTION bms.get_low_stock_report(UUID, UUID) IS 'Get report of items below minimum or reorder point';
COMMENT ON FUNCTION bms.get_inventory_movement_history(UUID, UUID, UUID, TIMESTAMP WITH TIME ZONE, TIMESTAMP WITH TIME ZONE, INTEGER) IS 'Get inventory movement history for a material';

COMMENT ON VIEW bms.v_inventory_current_stock IS 'Current inventory stock levels with material and location details';

-- Script completion message
SELECT 'Inventory Management Functions created successfully!' as status;