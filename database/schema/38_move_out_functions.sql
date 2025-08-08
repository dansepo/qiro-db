-- =====================================================
-- Move-out Process Management Functions
-- Phase 3.3.2: Move-out Process Functions
-- =====================================================

-- 1. Create move-out process function
CREATE OR REPLACE FUNCTION bms.create_move_out_process(
    p_company_id UUID,
    p_contract_id UUID,
    p_template_id UUID DEFAULT NULL,
    p_notice_date DATE DEFAULT CURRENT_DATE,
    p_scheduled_move_out_date DATE DEFAULT NULL,
    p_termination_reason VARCHAR(50) DEFAULT 'NORMAL_EXPIRY',
    p_early_termination BOOLEAN DEFAULT false,
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
    v_notice_period_days INTEGER;
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
    
    -- Check if move-out process already exists
    IF EXISTS (
        SELECT 1 FROM bms.move_out_processes 
        WHERE contract_id = p_contract_id
    ) THEN
        RAISE EXCEPTION 'Move-out process already exists for contract: %', p_contract_id;
    END IF;
    
    -- Generate process number
    v_process_number := 'MO' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                       REPLACE(v_contract.unit_number, ' ', '') || '-' ||
                       LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- Calculate notice period
    IF p_scheduled_move_out_date IS NOT NULL THEN
        v_notice_period_days := p_scheduled_move_out_date - p_notice_date;
    END IF;
    
    -- Create move-out process
    INSERT INTO bms.move_out_processes (
        company_id,
        contract_id,
        template_id,
        process_number,
        notice_date,
        scheduled_move_out_date,
        notice_period_days,
        early_termination,
        termination_reason,
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
        p_notice_date,
        p_scheduled_move_out_date,
        v_notice_period_days,
        p_early_termination,
        p_termination_reason,
        p_assigned_staff_id,
        p_contact_person_name,
        p_contact_person_phone,
        p_special_requirements,
        p_created_by
    ) RETURNING process_id INTO v_process_id;
    
    -- Create checklist items from template if provided
    IF p_template_id IS NOT NULL THEN
        SELECT * INTO v_template
        FROM bms.move_out_checklist_templates
        WHERE template_id = p_template_id;
        
        IF FOUND THEN
            -- Insert checklist items from template
            FOR v_checklist_item IN 
                SELECT * FROM jsonb_array_elements(v_template.checklist_items)
            LOOP
                INSERT INTO bms.move_out_checklist_items (
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
$$;-- 2. Creat
e unit condition assessment function
CREATE OR REPLACE FUNCTION bms.create_unit_condition_assessment(
    p_company_id UUID,
    p_process_id UUID,
    p_unit_id UUID,
    p_assessment_date DATE DEFAULT CURRENT_DATE,
    p_assessed_by UUID DEFAULT NULL,
    p_overall_condition VARCHAR(20) DEFAULT 'GOOD',
    p_overall_notes TEXT DEFAULT NULL,
    p_room_assessments JSONB DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_assessment_id UUID;
BEGIN
    -- Create unit condition assessment
    INSERT INTO bms.unit_condition_assessments (
        company_id,
        process_id,
        unit_id,
        assessment_date,
        assessed_by,
        overall_condition,
        overall_notes,
        room_assessments
    ) VALUES (
        p_company_id,
        p_process_id,
        p_unit_id,
        p_assessment_date,
        p_assessed_by,
        p_overall_condition,
        p_overall_notes,
        p_room_assessments
    ) RETURNING assessment_id INTO v_assessment_id;
    
    RETURN v_assessment_id;
END;
$$;

-- 3. Update assessment with damage costs function
CREATE OR REPLACE FUNCTION bms.update_assessment_damage_costs(
    p_assessment_id UUID,
    p_total_damages INTEGER DEFAULT 0,
    p_total_repair_cost DECIMAL(15,2) DEFAULT 0,
    p_tenant_responsible_cost DECIMAL(15,2) DEFAULT 0
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
BEGIN
    -- Update assessment with damage information
    UPDATE bms.unit_condition_assessments
    SET total_damages = p_total_damages,
        total_repair_cost = p_total_repair_cost,
        tenant_responsible_cost = p_tenant_responsible_cost,
        updated_at = NOW()
    WHERE assessment_id = p_assessment_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assessment not found: %', p_assessment_id;
    END IF;
    
    RETURN true;
END;
$$;

-- 4. Create restoration work function
CREATE OR REPLACE FUNCTION bms.create_restoration_work(
    p_company_id UUID,
    p_process_id UUID,
    p_assessment_id UUID DEFAULT NULL,
    p_work_category VARCHAR(30),
    p_work_description TEXT,
    p_work_location VARCHAR(100) DEFAULT NULL,
    p_estimated_cost DECIMAL(15,2),
    p_tenant_responsibility_percentage DECIMAL(5,2) DEFAULT 100,
    p_contractor_name VARCHAR(200) DEFAULT NULL,
    p_contractor_contact VARCHAR(100) DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_work_id UUID;
    v_tenant_responsible_amount DECIMAL(15,2);
BEGIN
    -- Calculate tenant responsible amount
    v_tenant_responsible_amount := p_estimated_cost * p_tenant_responsibility_percentage / 100;
    
    -- Create restoration work
    INSERT INTO bms.unit_restoration_works (
        company_id,
        process_id,
        assessment_id,
        work_category,
        work_description,
        work_location,
        estimated_cost,
        tenant_responsibility_percentage,
        tenant_responsible_amount,
        contractor_name,
        contractor_contact,
        created_by
    ) VALUES (
        p_company_id,
        p_process_id,
        p_assessment_id,
        p_work_category,
        p_work_description,
        p_work_location,
        p_estimated_cost,
        p_tenant_responsibility_percentage,
        v_tenant_responsible_amount,
        p_contractor_name,
        p_contractor_contact,
        p_created_by
    ) RETURNING work_id INTO v_work_id;
    
    RETURN v_work_id;
END;
$$;-- 5
. Complete restoration work function
CREATE OR REPLACE FUNCTION bms.complete_restoration_work(
    p_work_id UUID,
    p_actual_cost DECIMAL(15,2) DEFAULT NULL,
    p_work_quality VARCHAR(20) DEFAULT 'GOOD',
    p_completion_notes TEXT DEFAULT NULL,
    p_after_photos JSONB DEFAULT NULL,
    p_receipts JSONB DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_work RECORD;
    v_tenant_responsible_amount DECIMAL(15,2);
BEGIN
    -- Get work information
    SELECT * INTO v_work
    FROM bms.unit_restoration_works
    WHERE work_id = p_work_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Restoration work not found: %', p_work_id;
    END IF;
    
    -- Calculate actual tenant responsible amount
    IF p_actual_cost IS NOT NULL THEN
        v_tenant_responsible_amount := p_actual_cost * v_work.tenant_responsibility_percentage / 100;
    ELSE
        v_tenant_responsible_amount := v_work.tenant_responsible_amount;
    END IF;
    
    -- Update restoration work
    UPDATE bms.unit_restoration_works
    SET actual_cost = p_actual_cost,
        tenant_responsible_amount = v_tenant_responsible_amount,
        actual_completion_date = CURRENT_DATE,
        work_status = 'COMPLETED',
        work_quality = p_work_quality,
        completion_notes = p_completion_notes,
        after_photos = p_after_photos,
        receipts = p_receipts,
        updated_at = NOW()
    WHERE work_id = p_work_id;
    
    RETURN true;
END;
$$;

-- 6. Complete move-out checklist item function
CREATE OR REPLACE FUNCTION bms.complete_move_out_checklist_item(
    p_item_id UUID,
    p_completion_result VARCHAR(20) DEFAULT 'COMPLETED',
    p_completion_notes TEXT DEFAULT NULL,
    p_attached_files JSONB DEFAULT NULL,
    p_inspection_result VARCHAR(20) DEFAULT NULL,
    p_damage_assessment JSONB DEFAULT NULL,
    p_repair_required BOOLEAN DEFAULT false,
    p_estimated_repair_cost DECIMAL(15,2) DEFAULT 0,
    p_completed_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_item RECORD;
    v_process_id UUID;
BEGIN
    -- Get checklist item information
    SELECT * INTO v_item
    FROM bms.move_out_checklist_items
    WHERE item_id = p_item_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Checklist item not found: %', p_item_id;
    END IF;
    
    -- Update checklist item
    UPDATE bms.move_out_checklist_items
    SET is_completed = (p_completion_result = 'COMPLETED'),
        completion_date = CASE 
            WHEN p_completion_result = 'COMPLETED' THEN NOW()
            ELSE NULL
        END,
        completion_result = p_completion_result,
        completion_notes = p_completion_notes,
        attached_files = p_attached_files,
        inspection_result = p_inspection_result,
        damage_assessment = p_damage_assessment,
        repair_required = p_repair_required,
        estimated_repair_cost = p_estimated_repair_cost,
        completed_by = p_completed_by,
        updated_at = NOW()
    WHERE item_id = p_item_id;
    
    -- Update process status if all required items are completed
    v_process_id := v_item.process_id;
    PERFORM bms.update_move_out_process_status(v_process_id);
    
    RETURN true;
END;
$$;-- 7.
 Update move-out process status function
CREATE OR REPLACE FUNCTION bms.update_move_out_process_status(
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
    FROM bms.move_out_processes
    WHERE process_id = p_process_id;
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- Count required items
    SELECT COUNT(*) INTO v_total_required
    FROM bms.move_out_checklist_items
    WHERE process_id = p_process_id
    AND is_required = true;
    
    -- Count completed required items
    SELECT COUNT(*) INTO v_completed_required
    FROM bms.move_out_checklist_items
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
    UPDATE bms.move_out_processes
    SET process_status = v_new_status,
        process_completion_date = CASE 
            WHEN v_new_status = 'COMPLETED' THEN CURRENT_DATE
            ELSE process_completion_date
        END,
        updated_at = NOW()
    WHERE process_id = p_process_id;
    
    RETURN true;
END;
$$;

-- 8. Move-out process status view
CREATE OR REPLACE VIEW bms.v_move_out_process_status AS
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
    mp.notice_date,
    mp.scheduled_move_out_date,
    mp.actual_move_out_date,
    mp.process_start_date,
    mp.process_completion_date,
    mp.notice_period_days,
    mp.early_termination,
    mp.termination_reason,
    
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
    
    -- Assessment information
    COALESCE(assessments.total_assessments, 0) as total_assessments,
    COALESCE(assessments.total_repair_cost, 0) as total_repair_cost,
    COALESCE(assessments.tenant_responsible_cost, 0) as tenant_responsible_cost,
    
    -- Restoration works
    COALESCE(works.total_works, 0) as total_restoration_works,
    COALESCE(works.completed_works, 0) as completed_restoration_works,
    COALESCE(works.total_work_cost, 0) as total_work_cost,
    
    -- Status display
    CASE 
        WHEN mp.process_status = 'COMPLETED' THEN 'COMPLETED'
        WHEN mp.process_status = 'IN_PROGRESS' THEN 'IN_PROGRESS'
        WHEN mp.process_status = 'PENDING' THEN 'PENDING'
        WHEN mp.process_status = 'CANCELLED' THEN 'CANCELLED'
        WHEN mp.process_status = 'ON_HOLD' THEN 'ON_HOLD'
        ELSE mp.process_status
    END as status_display,
    
    -- Tenant information
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone
    
FROM bms.move_out_processes mp
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
    FROM bms.move_out_checklist_items
    GROUP BY process_id
) checklist ON mp.process_id = checklist.process_id
LEFT JOIN (
    SELECT 
        process_id,
        COUNT(*) as total_assessments,
        SUM(total_repair_cost) as total_repair_cost,
        SUM(tenant_responsible_cost) as tenant_responsible_cost
    FROM bms.unit_condition_assessments
    GROUP BY process_id
) assessments ON mp.process_id = assessments.process_id
LEFT JOIN (
    SELECT 
        process_id,
        COUNT(*) as total_works,
        COUNT(*) FILTER (WHERE work_status = 'COMPLETED') as completed_works,
        SUM(COALESCE(actual_cost, estimated_cost)) as total_work_cost
    FROM bms.unit_restoration_works
    GROUP BY process_id
) works ON mp.process_id = works.process_id
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true;-
- 9. Move-out statistics view
CREATE OR REPLACE VIEW bms.v_move_out_statistics AS
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
    
    -- Termination reasons
    COUNT(*) FILTER (WHERE termination_reason = 'NORMAL_EXPIRY') as normal_expiry_count,
    COUNT(*) FILTER (WHERE termination_reason = 'EARLY_TERMINATION') as early_termination_count,
    COUNT(*) FILTER (WHERE early_termination = true) as early_termination_total,
    
    -- Average processing time (for completed processes)
    ROUND(AVG(
        CASE 
            WHEN process_status = 'COMPLETED' AND process_completion_date IS NOT NULL THEN
                process_completion_date - process_start_date
            ELSE NULL
        END
    ), 2) as avg_processing_days,
    
    -- Average notice period
    ROUND(AVG(notice_period_days), 2) as avg_notice_period_days,
    
    -- This month statistics
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', process_start_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_processes,
    COUNT(*) FILTER (WHERE DATE_TRUNC('month', process_completion_date) = DATE_TRUNC('month', CURRENT_DATE)) as this_month_completed,
    
    -- Latest update time
    MAX(updated_at) as last_updated_at
    
FROM bms.move_out_processes
GROUP BY company_id;

-- 10. Comments
COMMENT ON FUNCTION bms.create_move_out_process(UUID, UUID, UUID, DATE, DATE, VARCHAR, BOOLEAN, UUID, VARCHAR, VARCHAR, TEXT, UUID) IS 'Create move-out process - Initialize move-out process with checklist items from template';
COMMENT ON FUNCTION bms.create_unit_condition_assessment(UUID, UUID, UUID, DATE, UUID, VARCHAR, TEXT, JSONB) IS 'Create unit condition assessment - Record unit condition during move-out inspection';
COMMENT ON FUNCTION bms.update_assessment_damage_costs(UUID, INTEGER, DECIMAL, DECIMAL) IS 'Update assessment damage costs - Update assessment with calculated damage costs';
COMMENT ON FUNCTION bms.create_restoration_work(UUID, UUID, UUID, VARCHAR, TEXT, VARCHAR, DECIMAL, DECIMAL, VARCHAR, VARCHAR, UUID) IS 'Create restoration work - Create restoration work item with cost allocation';
COMMENT ON FUNCTION bms.complete_restoration_work(UUID, DECIMAL, VARCHAR, TEXT, JSONB, JSONB) IS 'Complete restoration work - Mark restoration work as completed with actual costs';
COMMENT ON FUNCTION bms.complete_move_out_checklist_item(UUID, VARCHAR, TEXT, JSONB, VARCHAR, JSONB, BOOLEAN, DECIMAL, UUID) IS 'Complete move-out checklist item - Mark checklist item as completed with inspection results';
COMMENT ON FUNCTION bms.update_move_out_process_status(UUID) IS 'Update move-out process status - Automatically update process status based on checklist completion';

COMMENT ON VIEW bms.v_move_out_process_status IS 'Move-out process status view - Comprehensive view of move-out process progress and costs';
COMMENT ON VIEW bms.v_move_out_statistics IS 'Move-out statistics view - Company-wise move-out process statistics';

-- Script completion message
SELECT 'Move-out process management functions created successfully.' as message;