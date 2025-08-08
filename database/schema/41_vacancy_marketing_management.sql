-- =====================================================
-- Vacancy and Marketing Management System Tables
-- Phase 3.4.1: Vacancy and Marketing Management
-- =====================================================

-- 1. Vacancy tracking table
CREATE TABLE IF NOT EXISTS bms.vacancy_tracking (
    vacancy_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    
    -- Vacancy period information
    vacancy_start_date DATE NOT NULL,
    vacancy_end_date DATE,
    vacancy_duration_days INTEGER,
    
    -- Vacancy reason and type
    vacancy_reason VARCHAR(30) NOT NULL,
    vacancy_type VARCHAR(20) NOT NULL DEFAULT 'TENANT_TURNOVER',
    
    -- Previous tenant information
    previous_contract_id UUID,
    previous_tenant_name VARCHAR(100),
    move_out_date DATE,
    
    -- Vacancy costs
    lost_rental_income DECIMAL(15,2) DEFAULT 0,
    marketing_costs DECIMAL(15,2) DEFAULT 0,
    preparation_costs DECIMAL(15,2) DEFAULT 0,
    total_vacancy_cost DECIMAL(15,2) DEFAULT 0,
    
    -- Market conditions
    market_rent_at_vacancy DECIMAL(15,2),
    asking_rent DECIMAL(15,2),
    final_rent_achieved DECIMAL(15,2),
    
    -- Status and resolution
    vacancy_status VARCHAR(20) DEFAULT 'ACTIVE',
    resolution_type VARCHAR(20),
    resolution_date DATE,
    
    -- Notes and analysis
    vacancy_notes TEXT,
    market_analysis JSONB,
    lessons_learned TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_vacancy_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_vacancy_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_vacancy_previous_contract FOREIGN KEY (previous_contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_vacancy_reason CHECK (vacancy_reason IN (
        'TENANT_TURNOVER', 'LEASE_EXPIRY', 'EARLY_TERMINATION', 'EVICTION',
        'RENOVATION', 'MAINTENANCE', 'MARKET_REPOSITIONING', 'OWNER_USE', 'OTHER'
    )),
    CONSTRAINT chk_vacancy_type CHECK (vacancy_type IN (
        'TENANT_TURNOVER', 'PLANNED', 'UNPLANNED', 'STRATEGIC'
    )),
    CONSTRAINT chk_vacancy_status CHECK (vacancy_status IN (
        'ACTIVE', 'MARKETING', 'LEASED', 'WITHDRAWN', 'ON_HOLD'
    )),
    CONSTRAINT chk_resolution_type CHECK (resolution_type IN (
        'NEW_LEASE', 'RENEWAL', 'WITHDRAWN', 'CONVERTED', 'OTHER'
    ) OR resolution_type IS NULL),
    CONSTRAINT chk_vacancy_dates CHECK (
        vacancy_end_date IS NULL OR vacancy_end_date >= vacancy_start_date
    ),
    CONSTRAINT chk_vacancy_costs CHECK (
        lost_rental_income >= 0 AND marketing_costs >= 0 AND 
        preparation_costs >= 0 AND total_vacancy_cost >= 0
    )
);

-- 2. Marketing campaigns table
CREATE TABLE IF NOT EXISTS bms.marketing_campaigns (
    campaign_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- Campaign basic information
    campaign_name VARCHAR(200) NOT NULL,
    campaign_description TEXT,
    campaign_type VARCHAR(20) NOT NULL,
    
    -- Campaign period
    campaign_start_date DATE NOT NULL,
    campaign_end_date DATE,
    
    -- Target information
    target_units JSONB,
    target_demographics JSONB,
    target_rent_range JSONB,
    
    -- Marketing channels
    marketing_channels JSONB,
    
    -- Budget and costs
    planned_budget DECIMAL(15,2) DEFAULT 0,
    actual_spent DECIMAL(15,2) DEFAULT 0,
    cost_per_lead DECIMAL(10,2),
    cost_per_lease DECIMAL(10,2),
    
    -- Performance metrics
    total_leads INTEGER DEFAULT 0,
    qualified_leads INTEGER DEFAULT 0,
    applications_received INTEGER DEFAULT 0,
    leases_signed INTEGER DEFAULT 0,
    
    -- Campaign status
    campaign_status VARCHAR(20) DEFAULT 'PLANNED',
    
    -- Results and analysis
    campaign_notes TEXT,
    performance_analysis JSONB,
    roi_analysis JSONB,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- Constraints
    CONSTRAINT fk_campaigns_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_campaigns_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_campaign_type CHECK (campaign_type IN (
        'GENERAL', 'TARGETED', 'SEASONAL', 'PROMOTIONAL', 'DIGITAL', 'TRADITIONAL'
    )),
    CONSTRAINT chk_campaign_status CHECK (campaign_status IN (
        'PLANNED', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED'
    )),
    CONSTRAINT chk_campaign_dates CHECK (
        campaign_end_date IS NULL OR campaign_end_date >= campaign_start_date
    ),
    CONSTRAINT chk_campaign_budget CHECK (
        planned_budget >= 0 AND actual_spent >= 0
    ),
    CONSTRAINT chk_campaign_metrics CHECK (
        total_leads >= 0 AND qualified_leads >= 0 AND 
        applications_received >= 0 AND leases_signed >= 0 AND
        qualified_leads <= total_leads AND
        applications_received <= qualified_leads AND
        leases_signed <= applications_received
    )
);-- 3
. Prospect inquiries table
CREATE TABLE IF NOT EXISTS bms.prospect_inquiries (
    inquiry_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    campaign_id UUID,
    unit_id UUID,
    
    -- Prospect information
    prospect_name VARCHAR(100),
    prospect_email VARCHAR(200),
    prospect_phone VARCHAR(20),
    
    -- Inquiry details
    inquiry_date DATE DEFAULT CURRENT_DATE,
    inquiry_source VARCHAR(30) NOT NULL,
    inquiry_channel VARCHAR(30),
    
    -- Interest details
    interested_units JSONB,
    budget_range JSONB,
    move_in_timeline VARCHAR(20),
    specific_requirements TEXT,
    
    -- Lead qualification
    lead_status VARCHAR(20) DEFAULT 'NEW',
    lead_score INTEGER DEFAULT 0,
    qualification_notes TEXT,
    
    -- Follow-up tracking
    last_contact_date DATE,
    next_follow_up_date DATE,
    contact_attempts INTEGER DEFAULT 0,
    
    -- Conversion tracking
    application_submitted BOOLEAN DEFAULT false,
    application_date DATE,
    lease_signed BOOLEAN DEFAULT false,
    lease_signed_date DATE,
    conversion_notes TEXT,
    
    -- Assigned staff
    assigned_to UUID,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT fk_inquiries_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_inquiries_campaign FOREIGN KEY (campaign_id) REFERENCES bms.marketing_campaigns(campaign_id) ON DELETE SET NULL,
    CONSTRAINT fk_inquiries_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE SET NULL,
    
    -- Check constraints
    CONSTRAINT chk_inquiry_source CHECK (inquiry_source IN (
        'WEBSITE', 'PHONE', 'EMAIL', 'WALK_IN', 'REFERRAL', 'SOCIAL_MEDIA',
        'ONLINE_LISTING', 'PRINT_AD', 'SIGN', 'BROKER', 'OTHER'
    )),
    CONSTRAINT chk_inquiry_channel CHECK (inquiry_channel IN (
        'DIRECT', 'GOOGLE', 'FACEBOOK', 'INSTAGRAM', 'ZILLOW', 'APARTMENTS_COM',
        'CRAIGSLIST', 'NEWSPAPER', 'RADIO', 'TV', 'REFERRAL', 'OTHER'
    ) OR inquiry_channel IS NULL),
    CONSTRAINT chk_lead_status CHECK (lead_status IN (
        'NEW', 'CONTACTED', 'QUALIFIED', 'INTERESTED', 'APPLIED', 
        'APPROVED', 'LEASED', 'LOST', 'UNQUALIFIED'
    )),
    CONSTRAINT chk_move_in_timeline CHECK (move_in_timeline IN (
        'IMMEDIATE', 'WITHIN_WEEK', 'WITHIN_MONTH', 'WITHIN_3_MONTHS', 
        'FLEXIBLE', 'SPECIFIC_DATE'
    ) OR move_in_timeline IS NULL),
    CONSTRAINT chk_lead_score CHECK (lead_score >= 0 AND lead_score <= 100),
    CONSTRAINT chk_contact_attempts CHECK (contact_attempts >= 0),
    CONSTRAINT chk_inquiry_dates CHECK (
        (application_date IS NULL OR application_date >= inquiry_date) AND
        (lease_signed_date IS NULL OR lease_signed_date >= inquiry_date) AND
        (last_contact_date IS NULL OR last_contact_date >= inquiry_date)
    )
);

-- 4. Market analysis table
CREATE TABLE IF NOT EXISTS bms.market_analysis (
    analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    unit_type VARCHAR(20),
    
    -- Analysis period
    analysis_date DATE DEFAULT CURRENT_DATE,
    analysis_period VARCHAR(20) NOT NULL,
    
    -- Market data
    market_rent_range JSONB NOT NULL,
    average_market_rent DECIMAL(10,2),
    occupancy_rate DECIMAL(5,2),
    
    -- Competitive analysis
    competitor_data JSONB,
    competitive_position VARCHAR(20),
    
    -- Market trends
    rent_trend VARCHAR(20),
    demand_level VARCHAR(20),
    supply_level VARCHAR(20),
    
    -- Recommendations
    recommended_rent DECIMAL(10,2),
    pricing_strategy VARCHAR(30),
    marketing_recommendations TEXT,
    
    -- Data sources
    data_sources JSONB,
    analysis_methodology TEXT,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- Constraints
    CONSTRAINT fk_market_analysis_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_market_analysis_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_analysis_period CHECK (analysis_period IN (
        'WEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUAL', 'AD_HOC'
    )),
    CONSTRAINT chk_competitive_position CHECK (competitive_position IN (
        'PREMIUM', 'ABOVE_MARKET', 'MARKET_RATE', 'BELOW_MARKET', 'VALUE'
    ) OR competitive_position IS NULL),
    CONSTRAINT chk_rent_trend CHECK (rent_trend IN (
        'INCREASING', 'STABLE', 'DECREASING', 'VOLATILE'
    ) OR rent_trend IS NULL),
    CONSTRAINT chk_demand_level CHECK (demand_level IN (
        'HIGH', 'MODERATE', 'LOW', 'VERY_LOW'
    ) OR demand_level IS NULL),
    CONSTRAINT chk_supply_level CHECK (supply_level IN (
        'HIGH', 'MODERATE', 'LOW', 'VERY_LOW'
    ) OR supply_level IS NULL),
    CONSTRAINT chk_pricing_strategy CHECK (pricing_strategy IN (
        'PREMIUM_PRICING', 'MARKET_PRICING', 'COMPETITIVE_PRICING', 
        'PENETRATION_PRICING', 'VALUE_PRICING', 'DYNAMIC_PRICING'
    ) OR pricing_strategy IS NULL),
    CONSTRAINT chk_market_rates CHECK (
        average_market_rent >= 0 AND recommended_rent >= 0 AND
        occupancy_rate >= 0 AND occupancy_rate <= 100
    )
);--
 5. RLS policies and indexes
ALTER TABLE bms.vacancy_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.marketing_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.prospect_inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.market_analysis ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY vacancy_tracking_isolation_policy ON bms.vacancy_tracking
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY marketing_campaigns_isolation_policy ON bms.marketing_campaigns
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY prospect_inquiries_isolation_policy ON bms.prospect_inquiries
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY market_analysis_isolation_policy ON bms.market_analysis
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_vacancy_tracking_company_id ON bms.vacancy_tracking(company_id);
CREATE INDEX IF NOT EXISTS idx_vacancy_tracking_unit_id ON bms.vacancy_tracking(unit_id);
CREATE INDEX IF NOT EXISTS idx_vacancy_tracking_status ON bms.vacancy_tracking(vacancy_status);
CREATE INDEX IF NOT EXISTS idx_vacancy_tracking_start_date ON bms.vacancy_tracking(vacancy_start_date);
CREATE INDEX IF NOT EXISTS idx_vacancy_tracking_reason ON bms.vacancy_tracking(vacancy_reason);

CREATE INDEX IF NOT EXISTS idx_marketing_campaigns_company_id ON bms.marketing_campaigns(company_id);
CREATE INDEX IF NOT EXISTS idx_marketing_campaigns_building_id ON bms.marketing_campaigns(building_id);
CREATE INDEX IF NOT EXISTS idx_marketing_campaigns_status ON bms.marketing_campaigns(campaign_status);
CREATE INDEX IF NOT EXISTS idx_marketing_campaigns_type ON bms.marketing_campaigns(campaign_type);
CREATE INDEX IF NOT EXISTS idx_marketing_campaigns_dates ON bms.marketing_campaigns(campaign_start_date, campaign_end_date);

CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_company_id ON bms.prospect_inquiries(company_id);
CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_campaign_id ON bms.prospect_inquiries(campaign_id);
CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_unit_id ON bms.prospect_inquiries(unit_id);
CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_status ON bms.prospect_inquiries(lead_status);
CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_source ON bms.prospect_inquiries(inquiry_source);
CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_date ON bms.prospect_inquiries(inquiry_date);
CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_assigned ON bms.prospect_inquiries(assigned_to);

CREATE INDEX IF NOT EXISTS idx_market_analysis_company_id ON bms.market_analysis(company_id);
CREATE INDEX IF NOT EXISTS idx_market_analysis_building_id ON bms.market_analysis(building_id);
CREATE INDEX IF NOT EXISTS idx_market_analysis_date ON bms.market_analysis(analysis_date);
CREATE INDEX IF NOT EXISTS idx_market_analysis_unit_type ON bms.market_analysis(unit_type);

-- Composite indexes
CREATE INDEX IF NOT EXISTS idx_vacancy_tracking_company_status ON bms.vacancy_tracking(company_id, vacancy_status);
CREATE INDEX IF NOT EXISTS idx_prospect_inquiries_company_status ON bms.prospect_inquiries(company_id, lead_status);

-- Updated_at triggers
CREATE TRIGGER vacancy_tracking_updated_at_trigger
    BEFORE UPDATE ON bms.vacancy_tracking
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER marketing_campaigns_updated_at_trigger
    BEFORE UPDATE ON bms.marketing_campaigns
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER prospect_inquiries_updated_at_trigger
    BEFORE UPDATE ON bms.prospect_inquiries
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER market_analysis_updated_at_trigger
    BEFORE UPDATE ON bms.market_analysis
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- Comments
COMMENT ON TABLE bms.vacancy_tracking IS 'Vacancy tracking - Track vacant units, reasons, costs, and resolution';
COMMENT ON TABLE bms.marketing_campaigns IS 'Marketing campaigns - Manage marketing campaigns for rental properties';
COMMENT ON TABLE bms.prospect_inquiries IS 'Prospect inquiries - Track and manage prospective tenant inquiries';
COMMENT ON TABLE bms.market_analysis IS 'Market analysis - Store market research and competitive analysis data';

-- Script completion message
SELECT 'Vacancy and marketing management system tables created successfully.' as message;