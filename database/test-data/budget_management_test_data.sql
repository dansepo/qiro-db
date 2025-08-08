-- 예산 관리 시스템 테스트 데이터
-- 예산 계획, 예산 항목, 월별 배정, 경고 설정 등을 생성

-- 테스트 회사 ID 조회 (기존 회계 시스템에서 생성된 회사 사용)
WITH test_company AS (
    SELECT company_id 
    FROM bms.companies 
    WHERE verification_status = 'VERIFIED' 
    LIMIT 1
),
test_user AS (
    SELECT '00000000-0000-0000-0000-000000000001'::UUID as user_id
),
-- 2025년 예산 계획 생성
budget_plan_insert AS (
    INSERT INTO bms.budget_plans (
        budget_plan_id, company_id, plan_name, fiscal_year, 
        start_date, end_date, total_budget, status, 
        approved_by, approved_at, created_by
    )
    SELECT 
        gen_random_uuid(), tc.company_id, '2025년 연간 예산 계획', 2025,
        '2025-01-01', '2025-12-31', 1200000000.00, 'ACTIVE',
        tu.user_id, CURRENT_TIMESTAMP, tu.user_id
    FROM test_company tc, test_user tu
    RETURNING budget_plan_id, company_id
)
-- 예산 항목들 생성
INSERT INTO bms.budget_items (
    budget_item_id, budget_plan_id, company_id, category, subcategory,
    item_name, description, annual_budget, allocated_budget, used_budget, remaining_budget
)
SELECT 
    gen_random_uuid(), bpi.budget_plan_id, bpi.company_id, 
    budget_data.category, budget_data.subcategory,
    budget_data.item_name, budget_data.description, 
    budget_data.annual_budget, budget_data.annual_budget, 0, budget_data.annual_budget
FROM budget_plan_insert bpi,
(VALUES 
    ('INCOME', '관리비', '관리비 수입', '월별 관리비 수입 예산', 600000000.00),
    ('INCOME', '임대료', '임대료 수입', '월별 임대료 수입 예산', 300000000.00),
    ('INCOME', '주차비', '주차비 수입', '월별 주차비 수입 예산', 60000000.00),
    ('EXPENSE', '유지보수', '유지보수비', '시설 유지보수 관련 비용 예산', 200000000.00),
    ('EXPENSE', '공과금', '공과금', '전기, 가스, 수도 요금 예산', 120000000.00),
    ('EXPENSE', '관리운영', '관리운영비', '인건비, 사무용품 등 관리운영 비용', 150000000.00),
    ('EXPENSE', '청소', '청소비', '건물 청소 서비스 비용', 36000000.00),
    ('INVESTMENT', '시설개선', '시설 개선 투자', '엘리베이터 교체, 외벽 보수 등', 100000000.00),
    ('INVESTMENT', '장비구입', '장비 구입', '관리사무소 장비 및 시설 장비 구입', 50000000.00),
    ('RESERVE', '수선충당금', '수선충당금', '장기 수선을 위한 적립금', 80000000.00),
    ('RESERVE', '예비비', '예비비', '긴급 상황 대비 예비 자금', 30000000.00)
) AS budget_data(category, subcategory, item_name, description, annual_budget);

-- 월별 예산 배정 생성 (관리비 수입)
WITH management_fee_item AS (
    SELECT bi.budget_item_id, bi.company_id
    FROM bms.budget_items bi
    JOIN bms.budget_plans bp ON bi.budget_plan_id = bp.budget_plan_id
    WHERE bp.fiscal_year = 2025 AND bi.item_name = '관리비 수입'
    LIMIT 1
)
INSERT INTO bms.monthly_budget_allocations (
    allocation_id, budget_item_id, company_id, allocation_year, allocation_month,
    allocated_amount, used_amount, remaining_amount, variance_amount, variance_percentage
)
SELECT 
    gen_random_uuid(), mfi.budget_item_id, mfi.company_id, 2025, month_num,
    50000000.00, 0, 50000000.00, 0, 0
FROM management_fee_item mfi,
generate_series(1, 12) AS month_num;

-- 월별 예산 배정 생성 (유지보수비)
WITH maintenance_item AS (
    SELECT bi.budget_item_id, bi.company_id
    FROM bms.budget_items bi
    JOIN bms.budget_plans bp ON bi.budget_plan_id = bp.budget_plan_id
    WHERE bp.fiscal_year = 2025 AND bi.item_name = '유지보수비'
    LIMIT 1
)
INSERT INTO bms.monthly_budget_allocations (
    allocation_id, budget_item_id, company_id, allocation_year, allocation_month,
    allocated_amount, used_amount, remaining_amount, variance_amount, variance_percentage
)
SELECT 
    gen_random_uuid(), mi.budget_item_id, mi.company_id, 2025, month_num,
    CASE 
        WHEN month_num IN (3, 6, 9, 12) THEN 25000000.00  -- 분기별 집중 배정
        ELSE 12500000.00
    END, 0, 
    CASE 
        WHEN month_num IN (3, 6, 9, 12) THEN 25000000.00
        ELSE 12500000.00
    END, 0, 0
FROM maintenance_item mi,
generate_series(1, 12) AS month_num;

-- 예산 경고 설정 생성
WITH budget_items_for_alerts AS (
    SELECT bi.budget_item_id, bi.company_id, bi.item_name
    FROM bms.budget_items bi
    JOIN bms.budget_plans bp ON bi.budget_plan_id = bp.budget_plan_id
    WHERE bp.fiscal_year = 2025 
    AND bi.item_name IN ('관리비 수입', '유지보수비', '시설 개선 투자', '수선충당금')
)
INSERT INTO bms.budget_alert_settings (
    alert_setting_id, budget_item_id, company_id, alert_type,
    threshold_percentage, threshold_amount, is_enabled, notification_emails
)
SELECT 
    gen_random_uuid(), bifa.budget_item_id, bifa.company_id, 
    alert_data.alert_type, alert_data.threshold_percentage, 
    alert_data.threshold_amount, true, alert_data.notification_emails
FROM budget_items_for_alerts bifa,
(VALUES 
    ('관리비 수입', 'USAGE_WARNING', 80.00, NULL, ARRAY['admin@example.com', 'manager@example.com']),
    ('유지보수비', 'USAGE_CRITICAL', 90.00, NULL, ARRAY['admin@example.com', 'cfo@example.com']),
    ('시설 개선 투자', 'OVERBUDGET', 100.00, 100000000.00, ARRAY['ceo@example.com', 'cfo@example.com']),
    ('수선충당금', 'MONTHLY_LIMIT', 75.00, 6000000.00, ARRAY['admin@example.com'])
) AS alert_data(item_name, alert_type, threshold_percentage, threshold_amount, notification_emails)
WHERE bifa.item_name = alert_data.item_name;

-- 테스트용 예산 실적 추적 데이터 생성
WITH budget_items_for_tracking AS (
    SELECT bi.budget_item_id, bi.company_id, bi.item_name
    FROM bms.budget_items bi
    JOIN bms.budget_plans bp ON bi.budget_plan_id = bp.budget_plan_id
    WHERE bp.fiscal_year = 2025 
    AND bi.item_name IN ('관리비 수입', '유지보수비')
)
INSERT INTO bms.budget_performance_tracking (
    tracking_id, budget_item_id, company_id, tracking_date,
    amount, transaction_type, description
)
SELECT 
    gen_random_uuid(), bift.budget_item_id, bift.company_id, 
    tracking_data.tracking_date::DATE, tracking_data.amount, 
    tracking_data.transaction_type, tracking_data.description
FROM budget_items_for_tracking bift,
(VALUES 
    ('관리비 수입', '2025-01-15', 25000000.00, 'INCOME', '1월 상반기 관리비 수입'),
    ('관리비 수입', '2025-01-31', 20000000.00, 'INCOME', '1월 하반기 관리비 수입'),
    ('유지보수비', '2025-01-10', 8000000.00, 'EXPENSE', '엘리베이터 정기점검'),
    ('유지보수비', '2025-01-25', 3000000.00, 'EXPENSE', '소방시설 점검')
) AS tracking_data(item_name, tracking_date, amount, transaction_type, description)
WHERE bift.item_name = tracking_data.item_name;