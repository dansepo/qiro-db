-- =====================================================
-- Fault Reporting System Tables
-- Phase 4.3.1: Fault Reporting System
-- =====================================================

-- 1. Fault categories table
CREATE TABLE IF NOT EXISTS bms.fault_categories (
    category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Category information
    category_code VARCHAR(20) NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_description TEXT,
    parent_category_id UUID,
    
    -- Category settings
    default_priority VARCHAR(20) DEFAULT 'MEDIUM',
    default_urgency VARCHAR(20) DEFAULT 'NORMAL',
    auto_escalation_hours INTEGER DEFAULT 24,
    requires_immediate_response BOOLEAN DEFAULT false,
    
    -- Response time SLA
    response_time_minutes INTEGER DEFAULT 240, -- 4 hours default
    resolution_time_hours INTEGER DEFAULT 24,
    
    -- Assignment rules
    default_assigned_team VARCHAR(50),
    requires_specialist BOOLEAN DEFAULT false,
    contractor_required BOOLEAN DEFAULT false,
    
    -- Notification settings
    notify_management BOOLEAN DEFAULT false,
    notify_residents BOOLEAN DEFAULT false,
    
    -- Category hierarchy
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
    CONSTRAINT fk_fault_categories_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_categories_parent FOREIGN KEY (parent_category_id) REFERENCES bms.fault_categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uk_fault_categories_code UNIQUE (company_id, category_code),
    
    -- Check constraints
    CONSTRAINT chk_fault_priority CHECK (default_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_fault_urgency CHECK (default_urgency IN (
        'LOW', 'NORMAL', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_category_level_fault CHECK (category_level >= 1 AND category_level <= 5)
);

-- 2. Fault reports table
CREATE TABLE IF NOT EXISTS bms.fault_reports (
    report_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    unit_id UUID,
    asset_id UUID,
    category_id UUID NOT NULL,
    
    -- Report identification
    report_number VARCHAR(50) NOT NULL,
    report_title VARCHAR(200) NOT NULL,
    report_description TEXT NOT NULL,
    
    -- Reporter information
    reporter_type VARCHAR(20) NOT NULL,
    reporter_name VARCHAR(100),
    reporter_contact JSONB,
    reporter_unit_id UUID,
    anonymous_report BOOLEAN DEFAULT false,
    
    -- Fault details
    fault_type VARCHAR(30) NOT NULL,
    fault_severity VARCHAR(20) NOT NULL,
    fault_urgency VARCHAR(20) NOT NULL,
    fault_priority VARCHAR(20) NOT NULL,
    
    -- Location and context
    fault_location TEXT,
    affected_areas JSONB,
    environmental_conditions TEXT,
    
    -- Impact assessment
    safety_impact VARCHAR(20) DEFAULT 'NONE',
    operational_impact VARCHAR(20) DEFAULT 'MINOR',
    resident_impact VARCHAR(20) DEFAULT 'MINOR',
    estimated_affected_units INTEGER DEFAULT 0,
    
    -- Timing information
    fault_occurred_at TIMESTAMP WITH TIME ZONE,
    reported_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    first_response_due TIMESTAMP WITH TIME ZONE,
    resolution_due TIMESTAMP WITH TIME ZONE,
    
    -- Status tracking
    report_status VARCHAR(20) DEFAULT 'OPEN',
    resolution_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Assignment
    assigned_to UUID,
    assigned_team VARCHAR(50),
    contractor_id UUID,
    escalation_level INTEGER DEFAULT 1,
    
    -- Response tracking
    first_response_at TIMESTAMP WITH TIME ZONE,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    acknowledged_by UUID,
    
    -- Resolution tracking
    work_started_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID,
    resolution_method VARCHAR(50),
    resolution_description TEXT,
    
    -- Cost tracking
    estimated_repair_cost DECIMAL(12,2) DEFAULT 0,
    actual_repair_cost DECIMAL(12,2) DEFAULT 0,
    
    -- Quality and satisfaction
    resolution_quality_rating DECIMAL(3,1) DEFAULT 0,
    reporter_satisfaction_rating DECIMAL(3,1) DEFAULT 0,
    
    -- Documentation
    initial_photos JSONB,
    resolution_photos JSONB,
    supporting_documents JSONB,
    
    -- Communication log
    communication_log JSONB,
    internal_notes TEXT,
    
    -- Follow-up
    follow_up_required BOOLEAN DEFAULT false,
    follow_up_date DATE,
    follow_up_notes TEXT,
    
    -- Recurrence tracking
    is_recurring_issue BOOLEAN DEFAULT false,
    related_reports JSONB,
    root_cause_identified BOOLEAN DEFAULT false,
    root_cause_description TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_fault_reports_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_reports_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_reports_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_reports_asset FOREIGN KEY (asset_id) REFERENCES bms.facility_assets(asset_id) ON DELETE SET NULL,
    CONSTRAINT fk_fault_reports_category FOREIGN KEY (category_id) REFERENCES bms.fault_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_fault_reports_reporter_unit FOREIGN KEY (reporter_unit_id) REFERENCES bms.units(unit_id) ON DELETE SET NULL,
    CONSTRAINT uk_fault_reports_number UNIQUE (company_id, report_number),
    
    -- Check constraints
    CONSTRAINT chk_reporter_type CHECK (reporter_type IN (
        'RESIDENT', 'TENANT', 'VISITOR', 'STAFF', 'CONTRACTOR', 'SYSTEM', 'ANONYMOUS'
    )),
    CONSTRAINT chk_fault_type CHECK (fault_type IN (
        'ELECTRICAL', 'PLUMBING', 'HVAC', 'ELEVATOR', 'FIRE_SAFETY', 'SECURITY',
        'STRUCTURAL', 'APPLIANCE', 'LIGHTING', 'COMMUNICATION', 'OTHER'
    )),
    CONSTRAINT chk_fault_severity CHECK (fault_severity IN (
        'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL', 'CATASTROPHIC'
    )),
    CONSTRAINT chk_fault_urgency CHECK (fault_urgency IN (
        'LOW', 'NORMAL', 'HIGH', 'CRITICAL'
    )),
    CONSTRAINT chk_fault_priority CHECK (fault_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'EMERGENCY'
    )),
    CONSTRAINT chk_impact_levels CHECK (
        safety_impact IN ('NONE', 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL') AND
        operational_impact IN ('NONE', 'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL') AND
        resident_impact IN ('NONE', 'MINOR', 'MODERATE', 'MAJOR', 'CRITICAL')
    ),
    CONSTRAINT chk_report_status CHECK (report_status IN (
        'OPEN', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'RESOLVED', 'CLOSED', 'CANCELLED'
    )),
    CONSTRAINT chk_resolution_status CHECK (resolution_status IN (
        'PENDING', 'INVESTIGATING', 'PARTS_ORDERED', 'SCHEDULED', 'IN_PROGRESS', 
        'COMPLETED', 'DEFERRED', 'CANCELLED'
    )),
    CONSTRAINT chk_escalation_level CHECK (escalation_level >= 1 AND escalation_level <= 5),
    CONSTRAINT chk_rating_values CHECK (
        (resolution_quality_rating >= 0 AND resolution_quality_rating <= 10) AND
        (reporter_satisfaction_rating >= 0 AND reporter_satisfaction_rating <= 10)
    ),
    CONSTRAINT chk_cost_values_fault CHECK (
        estimated_repair_cost >= 0 AND actual_repair_cost >= 0
    )
);-- 3.
 Fault report status history table
CREATE TABLE IF NOT EXISTS bms.fault_report_status_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    report_id UUID NOT NULL,
    
    -- Status change information
    status_change_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    old_resolution_status VARCHAR(20),
    new_resolution_status VARCHAR(20),
    
    -- Change details
    change_reason VARCHAR(100),
    change_description TEXT,
    
    -- Assignment changes
    old_assigned_to UUID,
    new_assigned_to UUID,
    old_assigned_team VARCHAR(50),
    new_assigned_team VARCHAR(50),
    
    -- Priority changes
    old_priority VARCHAR(20),
    new_priority VARCHAR(20),
    old_urgency VARCHAR(20),
    new_urgency VARCHAR(20),
    
    -- Escalation tracking
    escalation_triggered BOOLEAN DEFAULT false,
    escalation_reason TEXT,
    escalated_to UUID,
    
    -- Response time tracking
    response_time_minutes INTEGER,
    sla_met BOOLEAN,
    sla_breach_reason TEXT,
    
    -- Communication
    notification_sent BOOLEAN DEFAULT false,
    notification_recipients JSONB,
    
    -- Change metadata
    changed_by UUID,
    change_notes TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_fault_status_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_status_history_report FOREIGN KEY (report_id) REFERENCES bms.fault_reports(report_id) ON DELETE CASCADE
);

-- 4. Fault report feedback table
CREATE TABLE IF NOT EXISTS bms.fault_report_feedback (
    feedback_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    report_id UUID NOT NULL,
    
    -- Feedback information
    feedback_type VARCHAR(20) NOT NULL,
    feedback_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ratings
    overall_satisfaction DECIMAL(3,1) DEFAULT 0,
    response_time_rating DECIMAL(3,1) DEFAULT 0,
    communication_rating DECIMAL(3,1) DEFAULT 0,
    resolution_quality_rating DECIMAL(3,1) DEFAULT 0,
    staff_professionalism_rating DECIMAL(3,1) DEFAULT 0,
    
    -- Feedback details
    positive_feedback TEXT,
    improvement_suggestions TEXT,
    additional_comments TEXT,
    
    -- Follow-up preferences
    follow_up_requested BOOLEAN DEFAULT false,
    preferred_contact_method VARCHAR(20),
    
    -- Feedback source
    feedback_source VARCHAR(20) DEFAULT 'DIRECT',
    feedback_channel VARCHAR(20),
    
    -- Anonymous feedback
    anonymous_feedback BOOLEAN DEFAULT false,
    
    -- Response to feedback
    management_response TEXT,
    response_date DATE,
    responded_by UUID,
    
    -- Action taken
    action_required BOOLEAN DEFAULT false,
    action_taken TEXT,
    action_date DATE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_fault_feedback_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_feedback_report FOREIGN KEY (report_id) REFERENCES bms.fault_reports(report_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_feedback_type CHECK (feedback_type IN (
        'SATISFACTION_SURVEY', 'COMPLAINT', 'COMPLIMENT', 'SUGGESTION', 'FOLLOW_UP'
    )),
    CONSTRAINT chk_feedback_ratings CHECK (
        overall_satisfaction >= 0 AND overall_satisfaction <= 10 AND
        response_time_rating >= 0 AND response_time_rating <= 10 AND
        communication_rating >= 0 AND communication_rating <= 10 AND
        resolution_quality_rating >= 0 AND resolution_quality_rating <= 10 AND
        staff_professionalism_rating >= 0 AND staff_professionalism_rating <= 10
    ),
    CONSTRAINT chk_feedback_source CHECK (feedback_source IN (
        'DIRECT', 'SURVEY', 'PHONE', 'EMAIL', 'MOBILE_APP', 'WEBSITE'
    )),
    CONSTRAINT chk_preferred_contact CHECK (preferred_contact_method IN (
        'PHONE', 'EMAIL', 'SMS', 'MOBILE_APP', 'IN_PERSON', 'NO_CONTACT'
    ) OR preferred_contact_method IS NULL)
);

-- 5. Fault report escalation rules table
CREATE TABLE IF NOT EXISTS bms.fault_escalation_rules (
    rule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- Rule information
    rule_name VARCHAR(100) NOT NULL,
    rule_description TEXT,
    rule_type VARCHAR(30) NOT NULL,
    
    -- Trigger conditions
    trigger_conditions JSONB NOT NULL,
    
    -- Escalation settings
    escalation_level INTEGER NOT NULL,
    escalation_delay_hours INTEGER DEFAULT 0,
    
    -- Escalation actions
    escalate_to_role VARCHAR(50),
    escalate_to_user UUID,
    escalate_to_team VARCHAR(50),
    
    -- Notification settings
    send_notifications BOOLEAN DEFAULT true,
    notification_template VARCHAR(100),
    notification_recipients JSONB,
    
    -- Priority changes
    increase_priority BOOLEAN DEFAULT false,
    new_priority VARCHAR(20),
    increase_urgency BOOLEAN DEFAULT false,
    new_urgency VARCHAR(20),
    
    -- Rule status
    is_active BOOLEAN DEFAULT true,
    effective_date DATE DEFAULT CURRENT_DATE,
    expiry_date DATE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_escalation_rules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_rule_type CHECK (rule_type IN (
        'TIME_BASED', 'STATUS_BASED', 'PRIORITY_BASED', 'CATEGORY_BASED', 'CUSTOM'
    )),
    CONSTRAINT chk_escalation_level_rule CHECK (escalation_level >= 1 AND escalation_level <= 5),
    CONSTRAINT chk_new_priority CHECK (new_priority IN (
        'LOW', 'MEDIUM', 'HIGH', 'URGENT', 'EMERGENCY'
    ) OR new_priority IS NULL),
    CONSTRAINT chk_new_urgency CHECK (new_urgency IN (
        'LOW', 'NORMAL', 'HIGH', 'CRITICAL'
    ) OR new_urgency IS NULL)
);-- 6. 
RLS policies and indexes
ALTER TABLE bms.fault_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fault_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fault_report_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fault_report_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.fault_escalation_rules ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY fault_categories_isolation_policy ON bms.fault_categories
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fault_reports_isolation_policy ON bms.fault_reports
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fault_status_history_isolation_policy ON bms.fault_report_status_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY fault_feedback_isolation_policy ON bms.fault_report_feedback
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY escalation_rules_isolation_policy ON bms.fault_escalation_rules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes for fault_categories
CREATE INDEX IF NOT EXISTS idx_fault_categories_company_id ON bms.fault_categories(company_id);
CREATE INDEX IF NOT EXISTS idx_fault_categories_parent ON bms.fault_categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_fault_categories_code ON bms.fault_categories(category_code);
CREATE INDEX IF NOT EXISTS idx_fault_categories_active ON bms.fault_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_fault_categories_priority ON bms.fault_categories(default_priority);

-- Performance indexes for fault_reports
CREATE INDEX IF NOT EXISTS idx_fault_reports_company_id ON bms.fault_reports(company_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_building_id ON bms.fault_reports(building_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_unit_id ON bms.fault_reports(unit_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_asset_id ON bms.fault_reports(asset_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_category_id ON bms.fault_reports(category_id);
CREATE INDEX IF NOT EXISTS idx_fault_reports_number ON bms.fault_reports(report_number);
CREATE INDEX IF NOT EXISTS idx_fault_reports_status ON bms.fault_reports(report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_resolution_status ON bms.fault_reports(resolution_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_priority ON bms.fault_reports(fault_priority);
CREATE INDEX IF NOT EXISTS idx_fault_reports_urgency ON bms.fault_reports(fault_urgency);
CREATE INDEX IF NOT EXISTS idx_fault_reports_severity ON bms.fault_reports(fault_severity);
CREATE INDEX IF NOT EXISTS idx_fault_reports_type ON bms.fault_reports(fault_type);
CREATE INDEX IF NOT EXISTS idx_fault_reports_reporter_type ON bms.fault_reports(reporter_type);
CREATE INDEX IF NOT EXISTS idx_fault_reports_assigned_to ON bms.fault_reports(assigned_to);
CREATE INDEX IF NOT EXISTS idx_fault_reports_reported_at ON bms.fault_reports(reported_at);
CREATE INDEX IF NOT EXISTS idx_fault_reports_occurred_at ON bms.fault_reports(fault_occurred_at);
CREATE INDEX IF NOT EXISTS idx_fault_reports_first_response_due ON bms.fault_reports(first_response_due);
CREATE INDEX IF NOT EXISTS idx_fault_reports_resolution_due ON bms.fault_reports(resolution_due);

-- Performance indexes for fault_report_status_history
CREATE INDEX IF NOT EXISTS idx_fault_status_history_company_id ON bms.fault_report_status_history(company_id);
CREATE INDEX IF NOT EXISTS idx_fault_status_history_report_id ON bms.fault_report_status_history(report_id);
CREATE INDEX IF NOT EXISTS idx_fault_status_history_change_date ON bms.fault_report_status_history(status_change_date);
CREATE INDEX IF NOT EXISTS idx_fault_status_history_changed_by ON bms.fault_report_status_history(changed_by);
CREATE INDEX IF NOT EXISTS idx_fault_status_history_escalation ON bms.fault_report_status_history(escalation_triggered);

-- Performance indexes for fault_report_feedback
CREATE INDEX IF NOT EXISTS idx_fault_feedback_company_id ON bms.fault_report_feedback(company_id);
CREATE INDEX IF NOT EXISTS idx_fault_feedback_report_id ON bms.fault_report_feedback(report_id);
CREATE INDEX IF NOT EXISTS idx_fault_feedback_type ON bms.fault_report_feedback(feedback_type);
CREATE INDEX IF NOT EXISTS idx_fault_feedback_date ON bms.fault_report_feedback(feedback_date);
CREATE INDEX IF NOT EXISTS idx_fault_feedback_satisfaction ON bms.fault_report_feedback(overall_satisfaction);

-- Performance indexes for fault_escalation_rules
CREATE INDEX IF NOT EXISTS idx_escalation_rules_company_id ON bms.fault_escalation_rules(company_id);
CREATE INDEX IF NOT EXISTS idx_escalation_rules_type ON bms.fault_escalation_rules(rule_type);
CREATE INDEX IF NOT EXISTS idx_escalation_rules_active ON bms.fault_escalation_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_escalation_rules_level ON bms.fault_escalation_rules(escalation_level);

-- Composite indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_fault_reports_company_status ON bms.fault_reports(company_id, report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_building_status ON bms.fault_reports(building_id, report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_priority_status ON bms.fault_reports(fault_priority, report_status);
CREATE INDEX IF NOT EXISTS idx_fault_reports_assigned_status ON bms.fault_reports(assigned_to, report_status);
CREATE INDEX IF NOT EXISTS idx_fault_status_history_report_date ON bms.fault_report_status_history(report_id, status_change_date);

-- Updated_at triggers
CREATE TRIGGER fault_categories_updated_at_trigger
    BEFORE UPDATE ON bms.fault_categories
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fault_reports_updated_at_trigger
    BEFORE UPDATE ON bms.fault_reports
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER fault_feedback_updated_at_trigger
    BEFORE UPDATE ON bms.fault_report_feedback
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER escalation_rules_updated_at_trigger
    BEFORE UPDATE ON bms.fault_escalation_rules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.fault_categories IS 'Fault categories - Classification system for different types of facility faults and issues';
COMMENT ON TABLE bms.fault_reports IS 'Fault reports - Comprehensive fault reporting and tracking system';
COMMENT ON TABLE bms.fault_report_status_history IS 'Fault report status history - Complete audit trail of fault report status changes';
COMMENT ON TABLE bms.fault_report_feedback IS 'Fault report feedback - Feedback and satisfaction tracking for fault resolution';
COMMENT ON TABLE bms.fault_escalation_rules IS 'Fault escalation rules - Automated escalation rules for fault management';

-- Script completion message
SELECT 'Fault reporting system tables created successfully.' as message;