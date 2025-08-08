-- =====================================================
-- Fault Report Communications Table (Missing)
-- Phase 4.3.1: Create missing communications table
-- =====================================================

-- Create fault report communications table
CREATE TABLE IF NOT EXISTS bms.fault_report_communications (
    communication_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    report_id UUID NOT NULL,
    
    -- Communication details
    communication_type VARCHAR(20) NOT NULL,
    communication_direction VARCHAR(10) NOT NULL,
    communication_method VARCHAR(20) NOT NULL,
    
    -- Participants
    sender_type VARCHAR(20) NOT NULL,
    sender_name VARCHAR(100),
    sender_contact VARCHAR(100),
    sender_user_id UUID,
    
    recipient_type VARCHAR(20) NOT NULL,
    recipient_name VARCHAR(100),
    recipient_contact VARCHAR(100),
    recipient_user_id UUID,
    
    -- Message content
    subject VARCHAR(200),
    message_content TEXT NOT NULL,
    message_format VARCHAR(20) DEFAULT 'TEXT',
    
    -- Timing
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,
    
    -- Status
    delivery_status VARCHAR(20) DEFAULT 'PENDING',
    read_status BOOLEAN DEFAULT false,
    
    -- Attachments
    attachments JSONB,
    
    -- Response tracking
    requires_response BOOLEAN DEFAULT false,
    response_deadline TIMESTAMP WITH TIME ZONE,
    response_received BOOLEAN DEFAULT false,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT fk_fault_communications_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_fault_communications_report FOREIGN KEY (report_id) REFERENCES bms.fault_reports(report_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_communication_type CHECK (communication_type IN (
        'INITIAL_REPORT', 'ACKNOWLEDGMENT', 'STATUS_UPDATE', 'CLARIFICATION',
        'RESOLUTION_NOTICE', 'FOLLOW_UP', 'ESCALATION', 'FEEDBACK_REQUEST', 'OTHER'
    )),
    CONSTRAINT chk_communication_direction CHECK (communication_direction IN (
        'INBOUND', 'OUTBOUND'
    )),
    CONSTRAINT chk_communication_method CHECK (communication_method IN (
        'EMAIL', 'SMS', 'PHONE', 'IN_PERSON', 'MOBILE_APP', 'WEB_PORTAL', 'SYSTEM'
    )),
    CONSTRAINT chk_participant_type CHECK (
        sender_type IN ('TENANT', 'STAFF', 'CONTRACTOR', 'SYSTEM', 'EXTERNAL') AND
        recipient_type IN ('TENANT', 'STAFF', 'CONTRACTOR', 'SYSTEM', 'EXTERNAL')
    ),
    CONSTRAINT chk_message_format CHECK (message_format IN (
        'TEXT', 'HTML', 'JSON', 'XML'
    )),
    CONSTRAINT chk_delivery_status CHECK (delivery_status IN (
        'PENDING', 'SENT', 'DELIVERED', 'FAILED', 'BOUNCED'
    ))
);

-- Enable RLS
ALTER TABLE bms.fault_report_communications ENABLE ROW LEVEL SECURITY;

-- Create RLS policy
CREATE POLICY fault_communications_isolation_policy ON bms.fault_report_communications
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_fault_communications_company_id ON bms.fault_report_communications(company_id);
CREATE INDEX IF NOT EXISTS idx_fault_communications_report_id ON bms.fault_report_communications(report_id);
CREATE INDEX IF NOT EXISTS idx_fault_communications_type ON bms.fault_report_communications(communication_type);
CREATE INDEX IF NOT EXISTS idx_fault_communications_method ON bms.fault_report_communications(communication_method);
CREATE INDEX IF NOT EXISTS idx_fault_communications_sent_at ON bms.fault_report_communications(sent_at);
CREATE INDEX IF NOT EXISTS idx_fault_communications_sender ON bms.fault_report_communications(sender_user_id);
CREATE INDEX IF NOT EXISTS idx_fault_communications_recipient ON bms.fault_report_communications(recipient_user_id);

-- Add comment
COMMENT ON TABLE bms.fault_report_communications IS 'Fault report communications - Communication log for fault reports';

-- Script completion message
SELECT 'Fault report communications table created successfully.' as message;