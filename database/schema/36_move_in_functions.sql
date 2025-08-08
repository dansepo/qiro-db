-- =====================================================
-- Move-in Process Management Functions
-- Phase 3.3.1: Move-in Process Functions
-- =====================================================

-- 1. Create move-in process function
CREATE OR REPLACE FUNCTION bms.create_move_in_process(
    p_company_id UUID,
    p_contract_id UUID,
    p_template_id UUID DEFAULT NULL,
    p_scheduled_move_in_date DATE DEFAULT NULL,
    p_assigned_staff_id UUID DEFAULT NULL,
    p_contact_person_name VARCHAR(100) DEFAULT NULL,
    p_contact_person_phone VARCHAR(20) DEFAULT NULL,
    p_special_requirements TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_process_id UUID;
    v_process_number VARCHAR(50);
    v_contract RECORD;
    v_template RECORD;
    v_checklist_item JSONB;
BEGIN
    -- Get contract information
    SELECT lc.*, u.unit_number, b.name as building_name
    INTO v_contract
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE lc.contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found: %', p_contract_id;
    END IF;
    
    -- Check if move-in process already exists
    IF EXISTS (
        SELECT 1 FROM bms.move_in_processes 
        WHERE contract_id = p_contract_id
    ) THEN
        RAISE EXCEPTION 'Move-in process already exists for contract: %', p_contract_id;
    END IF;
    
    -- Generate process number
    v_process_number := 'MI' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                       REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                       LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Create move-in process
    INSERT INTO bms.move_in_processes (
        company_id,
        contract_id,
        template_id,
        process_number,
        scheduled_move_in_date,
        assigned_staff_id,
        contact_person_name,
        contact_person_phone,
        special_requirements,
        created_by
    ) VALUES (
        p_company_id,
        p_contract_id,
        p_template_id,
        v_process_number,
        p_scheduled_move_in_date,
        p_assigned_staff_id,
        p_contact_person_name,
        p_contact_person_phone,
        p_special_requirements,
        p_created_by
    ) RETURNING process_id INTO v_process_id;
    
    -- Create checklist items from template if provided
    IF p_template_id IS NOT NULL THEN
        SELECT * INTO v_template
        FROM bms.move_in_checklist_templates
        WHERE template_id = p_template_id;
        
        IF FOUND THEN
            -- Insert checklist items from template
            FOR v_checklist_item IN 
                SELECT * FROM jsonb_array_elements(v_template.checklist_items)
            LOOP
                INSERT INTO bms.move_in_checklist_items (
                    company_id,
                    process_id,
                    item_category,
                    item_name,
                    item_description,
                    item_order,
                    is_required
                ) VALUES (
                    p_company_id,
                    v_process_id,
                    (v_checklist_item->>'category')::VARCHAR(50),
                    (v_checklist_item->>'name')::VARCHAR(200),
                    v_checklist_item->>'description',
                    COALESCE((v_checklist_item->>'order')::INTEGER, 0),
                    COALESCE((v_checklist_item->>'required')::BOOLEAN, true)
                );
            END LOOP;
        END IF;
    END IF;
    
    RETURN v_process_id;
END;
$$;-
- 2. Complete checklist item function
CREATE OR REPLACE FUNCTION bms.complete_checklist_item(
    p_item_id UUID,
    p_completion_result VARCHAR(20) DEFAULT 'COMPLETED',
    p_completion_notes TEXT DEFAULT NULL,
    p_attached_files JSONB DEFAULT NULL,
    p_completed_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_item RECORD;
    v_process_id UUID;
BEGIN
    -- Get checklist item information
    SELECT * INTO v_item
    FROM bms.move_in_checklist_items
    WHERE item_id = p_item_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Checklist item not found: %', p_item_id;
    END IF;
    
    -- Update checklist item
    UPDATE bms.move_in_checklist_items
    SET is_completed = (p_completion_result = 'COMPLETED'),
        completion_date = CASE 
            WHEN p_completion_result = 'COMPLETED' THEN NOW()
            ELSE NULL
        END,
        completion_result = p_completion_result,
        completion_notes = p_completion_notes,
        attached_files = p_attached_files,
        completed_by = p_completed_by,
        updated_at = NOW()
    WHERE item_id = p_item_id;
    
    -- Update process status if all required items are completed
    v_process_id := v_item.process_id;
    PERFORM bms.update_move_in_process_status(v_process_id);
    
    RETURN true;
END;
$$;

-- 3. Update move-in process status function
CREATE OR REPLACE FUNCTION bms.update_move_in_process_status(
    p_process_id UUID
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_process RECORD;
    v_total_required INTEGER;
    v_completed_required INTEGER;
    v_new_status VARCHAR(20);
BEGIN
    -- Get process information
    SELECT * INTO v_process
    FROM bms.move_in_processes
    WHERE process_id = p_process_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Count required items
    SELECT COUNT(*) INTO v_total_required
    FROM bms.move_in_checklist_items
    WHERE process_id = p_process_id
    AND is_required = true;
    
    -- Count completed required items
    SELECT COUNT(*) INTO v_completed_required
    FROM bms.move_in_checklist_items
    WHERE process_id = p_process_id
    AND is_required = true
    AND is_completed = true;
    
    -- Determine new status
    IF v_total_required = 0 THEN
        v_new_status := 'PENDING';
    ELSIF v_completed_required = 0 THEN
        v_new_status := 'PENDING';
    ELSIF v_completed_required = v_total_required THEN
        v_new_status := 'COMPLETED';
    ELSE
        v_new_status := 'IN_PROGRESS';
    END IF;
    
    -- Update process status
    UPDATE bms.move_in_processes
    SET process_status = v_new_status,
        process_completion_date = CASE 
            WHEN v_new_status = 'COMPLETED' THEN CURRENT_DATE
            ELSE process_completion_date
        END,
        updated_at = NOW()
    WHERE process_id = p_process_id;
    
    RETURN true;
END;
$$;--
 4. Issue key or security card function
CREATE OR REPLACE FUNCTION bms.issue_key_security_card(
    p_company_id UUID,
    p_unit_id UUID,
    p_process_id UUID DEFAULT NULL,
    p_key_type VARCHAR(20),
    p_key_number VARCHAR(50) DEFAULT NULL,
    p_key_description VARCHAR(200) DEFAULT NULL,
    p_issued_to_name VARCHAR(100),
    p_issued_to_phone VARCHAR(20) DEFAULT NULL,
    p_is_master_key BOOLEAN DEFAULT false,
    p_issued_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_key_id UUID;
BEGIN
    -- Check if key number already exists and is issued
    IF p_key_number IS NOT NULL AND EXISTS (
        SELECT 1 FROM bms.key_security_management 
        WHERE company_id = p_company_id 
        AND key_number = p_key_number 
        AND key_status = 'ISSUED'
    ) THEN
        RAISE EXCEPTION 'Key number already issued: %', p_key_number;
    END IF;
    
    -- Create key/card record
    INSERT INTO bms.key_security_management (
        company_id,
        unit_id,
        process_id,
        key_type,
        key_number,
        key_description,
        issued_date,
        issued_to_name,
        issued_to_phone,
        issued_by,
        key_status,
        is_master_key
    ) VALUES (
        p_company_id,
        p_unit_id,
        p_process_id,
        p_key_type,
        p_key_number,
        p_key_description,
        CURRENT_DATE,
        p_issued_to_name,
        p_issued_to_phone,
        p_issued_by,
        'ISSUED',
        p_is_master_key
    ) RETURNING key_id INTO v_key_id;
    
    RETURN v_key_id;
END;
$$;

-- 5. Return key or security card function
CREATE OR REPLACE FUNCTION bms.return_key_security_card(
    p_key_id UUID,
    p_returned_by_name VARCHAR(100),
    p_returned_condition VARCHAR(20) DEFAULT 'GOOD',
    p_received_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_key RECORD;
BEGIN
    -- Get key information
    SELECT * INTO v_key
    FROM bms.key_security_management
    WHERE key_id = p_key_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Key not found: %', p_key_id;
    END IF;
    
    IF v_key.key_status != 'ISSUED' THEN
        RAISE EXCEPTION 'Key is not currently issued: %', p_key_id;
    END IF;
    
    -- Update key record
    UPDATE bms.key_security_management
    SET returned_date = CURRENT_DATE,
        returned_by_name = p_returned_by_name,
        returned_condition = p_returned_condition,
        received_by = p_received_by,
        key_status = 'RETURNED',
        updated_at = NOW()
    WHERE key_id = p_key_id;
    
    RETURN true;
END;
$$;-- 6. Sche
dule facility orientation function
CREATE OR REPLACE FUNCTION bms.schedule_facility_orientation(
    p_company_id UUID,
    p_process_id UUID,
    p_orientation_type VARCHAR(30),
    p_orientation_title VARCHAR(200),
    p_orientation_content TEXT DEFAULT NULL,
    p_scheduled_date TIMESTAMP WITH TIME ZONE,
    p_conducted_by UUID DEFAULT NULL,
    p_attendees JSONB DEFAULT NULL,
    p_materials_provided JSONB DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_orientation_id UUID;
BEGIN
    -- Create facility orientation record
    INSERT INTO bms.facility_orientations (
        company_id,
        process_id,
        orientation_type,
        orientation_title,
        orientation_content,
        scheduled_date,
        conducted_by,
        attendees,
        materials_provided,
        completion_status
    ) VALUES (
        p_company_id,
        p_process_id,
        p_orientation_type,
        p_orientation_title,
        p_orientation_content,
        p_scheduled_date,
        p_conducted_by,
        p_attendees,
        p_materials_provided,
        'SCHEDULED'
    ) RETURNING orientation_id INTO v_orientation_id;
    
    RETURN v_orientation_id;
END;
$$;

-- 7. Complete facility orientation function
CREATE OR REPLACE FUNCTION bms.complete_facility_orientation(
    p_orientation_id UUID,
    p_attendance_confirmed BOOLEAN DEFAULT true,
    p_feedback_notes TEXT DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    -- Update orientation record
    UPDATE bms.facility_orientations
    SET completed_date = NOW(),
        attendance_confirmed = p_attendance_confirmed,
        completion_status = 'COMPLETED',
        feedback_notes = p_feedback_notes,
        updated_at = NOW()
    WHERE orientation_id = p_orientation_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Orientation not found: %', p_orientation_id;
    END IF;
    
    RETURN true;
END;
$$;-- 8. Move-
in process status view
CREATE OR REPLACE VIEW bms.v_move_in_process_status AS
SELECT 
    mp.process_id,
    mp.company_id,
    mp.contract_id,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- Process information
    mp.process_number,
    mp.process_status,
    mp.scheduled_move_in_date,
    mp.actual_move_in_date,
    mp.process_start_date,
    mp.process_completion_date,
    
    -- Staff and contact information
    mp.assigned_staff_id,
    mp.contact_person_name,
    mp.contact_person_phone,
    
    -- Checklist progress
    COALESCE(checklist.total_items, 0) as total_checklist_items,
    COALESCE(checklist.completed_items, 0) as completed_checklist_items,
    COALESCE(checklist.required_items, 0) as required_checklist_items,
    COALESCE(checklist.completed_required_items, 0) as completed_required_items,
    
    -- Progress percentage
    CASE 
        WHEN COALESCE(checklist.required_items, 0) = 0 THEN 0
        ELSE ROUND((COALESCE(checklist.completed_required_items, 0)::DECIMAL / checklist.required_items * 100), 2)
    END as progress_percentage,
    
    -- Key management
    COALESCE(keys.total_keys, 0) as total_keys_issued,
    COALESCE(keys.returned_keys, 0) as returned_keys,
    
    -- Orientations
    COALESCE(orientations.total_orientations, 0) as total_orientations,
    COALESCE(orientations.completed_orientations, 0) as completed_orientations,
    
    -- Status display
    CASE 
        WHEN mp.process_status = 'COMPLETED' THEN '완료'
        WHEN mp.process_status = 'IN_PROGRESS' THEN '진행중'
        WHEN mp.process_status = 'PENDING' THEN '대기'
        WHEN mp.process_status = 'CANCELLED' THEN '취소'
        WHEN mp.process_status = 'ON_HOLD' THEN '보류'
        ELSE mp.process_status
    END as status_display,
    
    -- Tenant information
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone
    
FROM bms.move_in_processes mp
JOIN bms.lease_contracts lc ON mp.contract_id = lc.contract_id
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN (
    SELECT 
        process_id,
        COUNT(*) as total_items,
        COUNT(*) FILTER (WHERE is_completed = true) as completed_items,
        COUNT(*) FILTER (WHERE is_required = true) as required_items,
        COUNT(*) FILTER (WHERE is_required = true AND is_completed = true) as completed_required_items
    FROM bms.move_in_checklist_items
    GROUP BY process_id
) checklist ON mp.process_id = checklist.process_id
LEFT JOIN (
    SELECT 
        process_id,
        COUNT(*) as total_keys,
        COUNT(*) FILTER (WHERE key_status = 'RETURNED') as returned_keys
    FROM bms.key_security_management
    WHERE process_id IS NOT NULL
    GROUP BY process_id
) keys ON mp.process_id = keys.process_id
LEFT JOIN (
    SELECT 
        process_id,
        COUNT(*) as total_orientations,
        COUNT(*) FILTER (WHERE completion_status = 'COMPLETED') as completed_orientations
    FROM bms.facility_orientations
    GROUP BY process_id
) orientations ON mp.process_id = orientations.process_id
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true;-- 
9. Move-in statistics view
CREATE OR REPLACE VIEW bms.v_move_in_statistics AS
SELECT 
    company_id,
    
    -- Overall statistics
    COUNT(*) as total_processes,
    
    -- Status statistics
    COUNT(*) FILTER (WHERE process_status = 'PENDING') as pending_count,
    COUNT(*) FILTER (WHERE process_status = 'IN_PROGRESS') as in_progress_count,
    COUNT(*) FILTER (WHERE process_status = 'COMPLETED') as completed_count,
    COUNT(*) FILTER (WHERE process_status = 'CANCELLED') as cancelled_count,
    COUNT(*) FILTER (WHERE process_status = 'ON_HOLD') as on_hold_count,
    
    -- Completion rate
    CASE 
        WHEN COUNT(*) > 0 THEN
            ROUND((COUNT(*) FILTER (WHERE process_status = 'COMPLETED')::DECIMAL / COUNT(*) * 100), 2)
        ELSE 0
    END as completion_rate,
    
    -- Average processing time (for completed processes)
    ROUND(AVG(
        CASE 
            WHEN process_status = 'COMPLETED' AND process_completion_date IS NOT NULL THEN
                process_completion_date - process_start_date
            ELSE NULL
        END
    ), 2) as avg_processing_days,
    
    -- This month statistics
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', process_start_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_processes,
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', process_completion_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_completed,
    
    -- Latest update time
    MAX(updated_at) as last_updated_at
    
FROM bms.move_in_processes
GROUP BY company_id;

-- 10. Comments
COMMENT ON FUNCTION bms.create_move_in_process(UUID, UUID, UUID, DATE, UUID, VARCHAR, VARCHAR, TEXT, UUID) IS 'Create move-in process - Initialize move-in process with checklist items from template';
COMMENT ON FUNCTION bms.complete_checklist_item(UUID, VARCHAR, TEXT, JSONB, UUID) IS 'Complete checklist item - Mark checklist item as completed and update process status';
COMMENT ON FUNCTION bms.update_move_in_process_status(UUID) IS 'Update move-in process status - Automatically update process status based on checklist completion';
COMMENT ON FUNCTION bms.issue_key_security_card(UUID, UUID, UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, BOOLEAN, UUID) IS 'Issue key or security card - Record key/card issuance to tenant';
COMMENT ON FUNCTION bms.return_key_security_card(UUID, VARCHAR, VARCHAR, UUID) IS 'Return key or security card - Process key/card return from tenant';
COMMENT ON FUNCTION bms.schedule_facility_orientation(UUID, UUID, VARCHAR, VARCHAR, TEXT, TIMESTAMP, UUID, JSONB, JSONB) IS 'Schedule facility orientation - Schedule orientation session for new tenant';
COMMENT ON FUNCTION bms.complete_facility_orientation(UUID, BOOLEAN, TEXT) IS 'Complete facility orientation - Mark orientation session as completed';

COMMENT ON VIEW bms.v_move_in_process_status IS 'Move-in process status view - Comprehensive view of move-in process progress and statistics';
COMMENT ON VIEW bms.v_move_in_statistics IS 'Move-in statistics view - Company-wise move-in process statistics';

-- Script completion message
SELECT 'Move-in process management functions created successfully.' as message;