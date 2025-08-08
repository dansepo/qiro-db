-- =====================================================
-- Work Order Assignments Table (Missing)
-- Phase 4.3.2: Create missing assignments table
-- =====================================================

-- Work order assignments table
CREATE TABLE IF NOT EXISTS bms.work_order_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- Assignment details
    assigned_to UUID NOT NULL,
    assignment_role VARCHAR(30) NOT NULL,
    assignment_type VARCHAR(20) NOT NULL,
    
    -- Assignment period
    assigned_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expected_start_date TIMESTAMP WITH TIME ZONE,
    expected_end_date TIMESTAMP WITH TIME ZONE,
    
    -- Assignment status
    assignment_status VARCHAR(20) DEFAULT 'ASSIGNED',
    acceptance_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- Work allocation
    allocated_hours DECIMAL(8,2) DEFAULT 0,
    actual_hours DECIMAL(8,2) DEFAULT 0,
    work_percentage INTEGER DEFAULT 0,
    
    -- Assignment notes
    assignment_notes TEXT,
    acceptance_notes TEXT,
    completion_notes TEXT,
    
    -- Performance tracking
    performance_rating DECIMAL(3,1) DEFAULT 0,
    quality_score DECIMAL(3,1) DEFAULT 0,
    timeliness_score DECIMAL(3,1) DEFAULT 0,
    
    -- Assignment completion
    completed_date TIMESTAMP WITH TIME ZONE,
    completed_by UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_work_assignments_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_work_assignments_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_assignment_role CHECK (assignment_role IN (
        'PRIMARY_TECHNICIAN', 'ASSISTANT_TECHNICIAN', 'SUPERVISOR', 
        'SPECIALIST', 'CONTRACTOR', 'INSPECTOR', 'COORDINATOR'
    )),
    CONSTRAINT chk_assignment_type CHECK (assignment_type IN (
        'INTERNAL', 'EXTERNAL', 'CONTRACTOR', 'CONSULTANT'
    )),
    CONSTRAINT chk_assignment_status CHECK (assignment_status IN (
        'ASSIGNED', 'ACCEPTED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'REASSIGNED'
    )),
    CONSTRAINT chk_acceptance_status CHECK (acceptance_status IN (
        'PENDING', 'ACCEPTED', 'DECLINED', 'REQUIRES_CLARIFICATION'
    )),
    CONSTRAINT chk_work_percentage_assign CHECK (work_percentage >= 0 AND work_percentage <= 100),
    CONSTRAINT chk_performance_scores CHECK (
        performance_rating >= 0 AND performance_rating <= 10 AND
        quality_score >= 0 AND quality_score <= 10 AND
        timeliness_score >= 0 AND timeliness_score <= 10
    )
);

-- Enable RLS
ALTER TABLE bms.work_order_assignments ENABLE ROW LEVEL SECURITY;

-- Create RLS policy
CREATE POLICY work_assignments_isolation_policy ON bms.work_order_assignments
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_work_assignments_company_id ON bms.work_order_assignments(company_id);
CREATE INDEX IF NOT EXISTS idx_work_assignments_work_order ON bms.work_order_assignments(work_order_id);
CREATE INDEX IF NOT EXISTS idx_work_assignments_assigned_to ON bms.work_order_assignments(assigned_to);
CREATE INDEX IF NOT EXISTS idx_work_assignments_role ON bms.work_order_assignments(assignment_role);
CREATE INDEX IF NOT EXISTS idx_work_assignments_status ON bms.work_order_assignments(assignment_status);
CREATE INDEX IF NOT EXISTS idx_work_assignments_date ON bms.work_order_assignments(assigned_date);
CREATE INDEX IF NOT EXISTS idx_work_assignments_assigned_status ON bms.work_order_assignments(assigned_to, assignment_status);

-- Updated_at trigger
CREATE TRIGGER work_assignments_updated_at_trigger
    BEFORE UPDATE ON bms.work_order_assignments
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Add comment
COMMENT ON TABLE bms.work_order_assignments IS 'Work order assignments - Assignment of work orders to technicians and contractors';

-- Script completion message
SELECT 'Work order assignments table created successfully.' as message;