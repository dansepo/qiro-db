-- =====================================================
-- 관리비 및 임대차 테이블 멀티테넌시 마이그레이션
-- 작성일: 2025-01-30
-- 설명: 관리비, 임대차 관련 테이블들에 조직별 데이터 격리 적용
-- =====================================================

-- 1. 관리비 관련 테이블들에 RLS 적용

-- 1.1 Fee Items 테이블 RLS
ALTER TABLE fee_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY fee_items_org_isolation_policy ON fee_items
    FOR ALL
    TO application_role
    USING (
        building_id IN (
            SELECT id FROM buildings 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 1.2 Payment Policies 테이블 RLS
ALTER TABLE payment_policies ENABLE ROW LEVEL SECURITY;

CREATE POLICY payment_policies_org_isolation_policy ON payment_policies
    FOR ALL
    TO application_role
    USING (
        building_id IN (
            SELECT id FROM buildings 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 1.3 External Bill Accounts 테이블 RLS
ALTER TABLE external_bill_accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY external_bill_accounts_org_isolation_policy ON external_bill_accounts
    FOR ALL
    TO application_role
    USING (
        building_id IN (
            SELECT id FROM buildings 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 1.4 Fee Calculation Metadata 테이블 RLS
ALTER TABLE fee_calculation_metadata ENABLE ROW LEVEL SECURITY;

CREATE POLICY fee_calculation_metadata_org_isolation_policy ON fee_calculation_metadata
    FOR ALL
    TO application_role
    USING (
        fee_item_id IN (
            SELECT fi.id FROM fee_items fi
            JOIN buildings b ON fi.building_id = b.id
            WHERE b.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2. 월별 관리비 처리 관련 테이블들에 RLS 적용

-- 2.1 Billing Months 테이블 RLS
ALTER TABLE billing_months ENABLE ROW LEVEL SECURITY;

CREATE POLICY billing_months_org_isolation_policy ON billing_months
    FOR ALL
    TO application_role
    USING (
        building_id IN (
            SELECT id FROM buildings 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.2 Unit Meter Readings 테이블 RLS
ALTER TABLE unit_meter_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY unit_meter_readings_org_isolation_policy ON unit_meter_readings
    FOR ALL
    TO application_role
    USING (
        billing_month_id IN (
            SELECT bm.id FROM billing_months bm
            JOIN buildings b ON bm.building_id = b.id
            WHERE b.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.3 Common Meter Readings 테이블 RLS
ALTER TABLE common_meter_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY common_meter_readings_org_isolation_policy ON common_meter_readings
    FOR ALL
    TO application_role
    USING (
        building_id IN (
            SELECT id FROM buildings 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.4 Monthly Fees 테이블 RLS
ALTER TABLE monthly_fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY monthly_fees_org_isolation_policy ON monthly_fees
    FOR ALL
    TO application_role
    USING (
        billing_month_id IN (
            SELECT bm.id FROM billing_months bm
            JOIN buildings b ON bm.building_id = b.id
            WHERE b.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.5 Fee Calculation Verification 테이블 RLS
ALTER TABLE fee_calculation_verification ENABLE ROW LEVEL SECURITY;

CREATE POLICY fee_calculation_verification_org_isolation_policy ON fee_calculation_verification
    FOR ALL
    TO application_role
    USING (
        billing_month_id IN (
            SELECT bm.id FROM billing_months bm
            JOIN buildings b ON bm.building_id = b.id
            WHERE b.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.6 Invoices 테이블 RLS
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY invoices_org_isolation_policy ON invoices
    FOR ALL
    TO application_role
    USING (
        billing_month_id IN (
            SELECT bm.id FROM billing_months bm
            JOIN buildings b ON bm.building_id = b.id
            WHERE b.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.7 Invoice Line Items 테이블 RLS
ALTER TABLE invoice_line_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY invoice_line_items_org_isolation_policy ON invoice_line_items
    FOR ALL
    TO application_role
    USING (
        invoice_id IN (
            SELECT i.id FROM invoices i
            JOIN billing_months bm ON i.billing_month_id = bm.id
            JOIN buildings b ON bm.building_id = b.id
            WHERE b.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.8 Payments 테이블 RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY payments_org_isolation_policy ON payments
    FOR ALL
    TO application_role
    USING (
        invoice_id IN (
            SELECT i.id FROM invoices i
            JOIN billing_months bm ON i.billing_month_id = bm.id
            JOIN buildings b ON bm.building_id = b.id
            WHERE b.company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 2.9 Delinquencies 테이블 RLS (테이블이 존재한다면)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'delinquencies') THEN
        EXECUTE 'ALTER TABLE delinquencies ENABLE ROW LEVEL SECURITY';
        
        EXECUTE 'CREATE POLICY delinquencies_org_isolation_policy ON delinquencies
            FOR ALL
            TO application_role
            USING (
                invoice_id IN (
                    SELECT i.id FROM invoices i
                    JOIN billing_months bm ON i.billing_month_id = bm.id
                    JOIN buildings b ON bm.building_id = b.id
                    WHERE b.company_id = current_setting(''app.current_company_id'', true)::UUID
                )
            )';
    END IF;
END $$;

-- 3. 임대차 관련 테이블들에 RLS 적용

-- 3.1 Lessors 테이블에 company_id 추가 및 RLS 적용
-- 임대인은 여러 조직과 관련될 수 있으므로 별도 처리 필요
ALTER TABLE lessors 
ADD COLUMN IF NOT EXISTS company_id UUID;

-- 기존 데이터 마이그레이션 (기본 조직으로 설정)
DO $$
DECLARE
    default_org_id UUID;
BEGIN
    SELECT company_id INTO default_org_id 
    FROM companies 
    WHERE business_registration_number = '000-00-00000' 
    LIMIT 1;
    
    IF default_org_id IS NOT NULL THEN
        UPDATE lessors 
        SET company_id = default_org_id 
        WHERE company_id IS NULL;
    END IF;
END $$;

-- Lessors 테이블 RLS
ALTER TABLE lessors ENABLE ROW LEVEL SECURITY;

CREATE POLICY lessors_org_isolation_policy ON lessors
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 3.2 Tenants 테이블에 company_id 추가 및 RLS 적용
ALTER TABLE tenants 
ADD COLUMN IF NOT EXISTS company_id UUID;

-- 기존 데이터 마이그레이션
DO $$
DECLARE
    default_org_id UUID;
BEGIN
    SELECT company_id INTO default_org_id 
    FROM companies 
    WHERE business_registration_number = '000-00-00000' 
    LIMIT 1;
    
    IF default_org_id IS NOT NULL THEN
        UPDATE tenants 
        SET company_id = default_org_id 
        WHERE company_id IS NULL;
    END IF;
END $$;

-- Tenants 테이블 RLS
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenants_org_isolation_policy ON tenants
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 3.3 Contacts 테이블 RLS (Lessors/Tenants를 통한 간접 격리)
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;

CREATE POLICY contacts_org_isolation_policy ON contacts
    FOR ALL
    TO application_role
    USING (
        (lessor_id IS NOT NULL AND lessor_id IN (
            SELECT id FROM lessors 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )) OR
        (tenant_id IS NOT NULL AND tenant_id IN (
            SELECT id FROM tenants 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        ))
    );

-- 3.4 Lease Contracts 테이블 RLS (테이블이 존재한다면)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'lease_contracts') THEN
        EXECUTE 'ALTER TABLE lease_contracts ENABLE ROW LEVEL SECURITY';
        
        EXECUTE 'CREATE POLICY lease_contracts_org_isolation_policy ON lease_contracts
            FOR ALL
            TO application_role
            USING (
                unit_id IN (
                    SELECT u.id FROM units u
                    JOIN buildings b ON u.building_id = b.id
                    WHERE b.company_id = current_setting(''app.current_company_id'', true)::UUID
                )
            )';
    END IF;
END $$;

-- 4. 외래키 제약조건 추가
ALTER TABLE lessors 
ADD CONSTRAINT fk_lessors_company_id 
FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE;

ALTER TABLE tenants 
ADD CONSTRAINT fk_tenants_company_id 
FOREIGN KEY (company_id) REFERENCES companies(company_id) ON DELETE CASCADE;

-- 5. 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_lessors_company_id ON lessors(company_id);
CREATE INDEX IF NOT EXISTS idx_tenants_company_id ON tenants(company_id);
CREATE INDEX IF NOT EXISTS idx_fee_items_building_company ON fee_items(building_id);
CREATE INDEX IF NOT EXISTS idx_billing_months_building_company ON billing_months(building_id);
CREATE INDEX IF NOT EXISTS idx_invoices_billing_month ON invoices(billing_month_id);
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);

-- 6. 권한 부여
GRANT SELECT, INSERT, UPDATE, DELETE ON fee_items TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON payment_policies TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON external_bill_accounts TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON billing_months TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON unit_meter_readings TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON common_meter_readings TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON monthly_fees TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON invoices TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON invoice_line_items TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON payments TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON lessors TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON tenants TO application_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON contacts TO application_role;

-- 7. 데이터 무결성 검증 함수
CREATE OR REPLACE FUNCTION verify_billing_lease_multitenancy()
RETURNS TABLE (
    table_name TEXT,
    total_records BIGINT,
    records_with_company_context BIGINT,
    unique_companies BIGINT
) AS $$
BEGIN
    -- Buildings 기반 테이블들
    RETURN QUERY
    SELECT 
        'fee_items'::TEXT,
        COUNT(*)::BIGINT,
        COUNT(CASE WHEN b.company_id IS NOT NULL THEN 1 END)::BIGINT,
        COUNT(DISTINCT b.company_id)::BIGINT
    FROM fee_items fi
    LEFT JOIN buildings b ON fi.building_id = b.id;
    
    RETURN QUERY
    SELECT 
        'billing_months'::TEXT,
        COUNT(*)::BIGINT,
        COUNT(CASE WHEN b.company_id IS NOT NULL THEN 1 END)::BIGINT,
        COUNT(DISTINCT b.company_id)::BIGINT
    FROM billing_months bm
    LEFT JOIN buildings b ON bm.building_id = b.id;
    
    RETURN QUERY
    SELECT 
        'invoices'::TEXT,
        COUNT(*)::BIGINT,
        COUNT(CASE WHEN b.company_id IS NOT NULL THEN 1 END)::BIGINT,
        COUNT(DISTINCT b.company_id)::BIGINT
    FROM invoices i
    LEFT JOIN billing_months bm ON i.billing_month_id = bm.id
    LEFT JOIN buildings b ON bm.building_id = b.id;
    
    -- 직접 company_id를 가진 테이블들
    RETURN QUERY
    SELECT 
        'lessors'::TEXT,
        COUNT(*)::BIGINT,
        COUNT(CASE WHEN company_id IS NOT NULL THEN 1 END)::BIGINT,
        COUNT(DISTINCT company_id)::BIGINT
    FROM lessors;
    
    RETURN QUERY
    SELECT 
        'tenants'::TEXT,
        COUNT(*)::BIGINT,
        COUNT(CASE WHEN company_id IS NOT NULL THEN 1 END)::BIGINT,
        COUNT(DISTINCT company_id)::BIGINT
    FROM tenants;
END;
$$ LANGUAGE plpgsql;

-- 8. 조직별 관리비 통계 함수
CREATE OR REPLACE FUNCTION get_billing_stats_by_organization()
RETURNS TABLE (
    company_id UUID,
    company_name VARCHAR(255),
    total_buildings BIGINT,
    total_fee_items BIGINT,
    active_billing_months BIGINT,
    total_invoices BIGINT,
    total_payments BIGINT,
    total_lessors BIGINT,
    total_tenants BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.company_id,
        c.company_name,
        COUNT(DISTINCT b.id) as total_buildings,
        COUNT(DISTINCT fi.id) as total_fee_items,
        COUNT(DISTINCT bm.id) as active_billing_months,
        COUNT(DISTINCT i.id) as total_invoices,
        COUNT(DISTINCT p.id) as total_payments,
        COUNT(DISTINCT l.id) as total_lessors,
        COUNT(DISTINCT t.id) as total_tenants
    FROM companies c
    LEFT JOIN buildings b ON c.company_id = b.company_id
    LEFT JOIN fee_items fi ON b.id = fi.building_id
    LEFT JOIN billing_months bm ON b.id = bm.building_id
    LEFT JOIN invoices i ON bm.id = i.billing_month_id
    LEFT JOIN payments p ON i.id = p.invoice_id
    LEFT JOIN lessors l ON c.company_id = l.company_id
    LEFT JOIN tenants t ON c.company_id = t.company_id
    GROUP BY c.company_id, c.company_name
    ORDER BY total_buildings DESC;
END;
$$ LANGUAGE plpgsql;

-- 9. 마이그레이션 검증 실행
SELECT * FROM verify_billing_lease_multitenancy();

-- 10. 마이그레이션 로그 기록
INSERT INTO migration_log (
    migration_name,
    description,
    executed_at,
    status
) VALUES (
    'billing_lease_multitenancy_migration',
    '관리비 및 임대차 테이블 조직별 데이터 격리 적용',
    now(),
    'COMPLETED'
) ON CONFLICT (migration_name) DO UPDATE SET
    executed_at = now(),
    status = 'COMPLETED';

-- 완료 메시지
DO $$
BEGIN
    RAISE NOTICE '=== 관리비 및 임대차 테이블 멀티테넌시 마이그레이션 완료 ===';
    RAISE NOTICE '1. 관리비 관련 테이블 RLS 정책 적용 완료';
    RAISE NOTICE '2. 월별 관리비 처리 테이블 RLS 정책 적용 완료';
    RAISE NOTICE '3. 임대차 관련 테이블 RLS 정책 적용 완료';
    RAISE NOTICE '4. 외래키 제약조건 및 인덱스 생성 완료';
    RAISE NOTICE '5. 데이터 무결성 검증 함수 생성 완료';
    RAISE NOTICE '6. 조직별 통계 함수 생성 완료';
    RAISE NOTICE '=== 검증을 위해 verify_billing_lease_multitenancy() 함수를 실행하세요 ===';
END $$;