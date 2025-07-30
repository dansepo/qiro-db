-- =====================================================
-- QIRO 건물 관리 SaaS 통합 테스트 데이터
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 전체 시스템 기능 검증을 위한 테스트 데이터
-- =====================================================

-- 테스트 데이터 삽입 전 기존 데이터 정리 (필요시)
-- TRUNCATE TABLE ... CASCADE;

-- =====================================================
-- 1. 기본 사용자 및 역할 데이터
-- =====================================================

-- 테스트용 사용자 생성
INSERT INTO users (
    username, email, password_hash, full_name, phone_number, role_id,
    is_active, is_email_verified, created_by
) VALUES 
('admin', 'admin@qiro.co.kr', '$2a$10$example_hash', '시스템 관리자', '02-1234-5678', 
 (SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), true, true, 1),
('manager1', 'manager1@qiro.co.kr', '$2a$10$example_hash', '김건물', '010-1111-2222', 
 (SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), true, true, 1),
('staff1', 'staff1@qiro.co.kr', '$2a$10$example_hash', '이직원', '010-3333-4444', 
 (SELECT id FROM roles WHERE name = 'STAFF'), true, true, 1),
('accountant1', 'accountant1@qiro.co.kr', '$2a$10$example_hash', '박회계', '010-5555-6666', 
 (SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), true, true, 1);

-- =====================================================
-- 2. 건물 및 호실 테스트 데이터
-- =====================================================

-- 테스트 건물 생성
INSERT INTO buildings (
    name, address, building_type, total_floors, basement_floors, total_area,
    construction_year, owner_name, owner_contact, management_company,
    status, created_by, updated_by
) VALUES 
('스마트빌딩 A동', '서울시 강남구 테헤란로 123', 'COMMERCIAL', 10, 2, 5000.00,
 2020, '김소유', '010-1111-1111', 'QIRO 관리', 'ACTIVE', 1, 1),
('그린타워 B동', '서울시 서초구 서초대로 456', 'OFFICE', 15, 3, 8000.00,
 2018, '이건물', '010-2222-2222', 'QIRO 관리', 'ACTIVE', 1, 1),
('레지던스 C동', '서울시 마포구 상암동 789', 'MIXED_USE', 20, 1, 12000.00,
 2022, '박임대', '010-3333-3333', 'QIRO 관리', 'ACTIVE', 1, 1);

-- 테스트 호실 생성
INSERT INTO units (
    building_id, unit_number, floor_number, unit_type, area, common_area,
    monthly_rent, deposit, maintenance_fee, status, room_count, bathroom_count,
    has_balcony, has_parking, created_by, updated_by
) VALUES 
-- 스마트빌딩 A동 호실들
(1, '101', 1, 'COMMERCIAL', 80.50, 20.00, 1500000, 15000000, 200000, 'OCCUPIED', 3, 1, false, true, 1, 1),
(1, '102', 1, 'COMMERCIAL', 95.20, 25.00, 1800000, 20000000, 250000, 'OCCUPIED', 4, 1, false, true, 1, 1),
(1, '201', 2, 'COMMERCIAL', 120.00, 30.00, 2200000, 25000000, 300000, 'OCCUPIED', 5, 2, true, true, 1, 1),
(1, '202', 2, 'COMMERCIAL', 85.00, 20.00, 1700000, 18000000, 220000, 'AVAILABLE', 3, 1, false, true, 1, 1),
(1, '301', 3, 'OFFICE', 150.00, 35.00, 2800000, 35000000, 400000, 'OCCUPIED', 6, 2, true, true, 1, 1),
-- 그린타워 B동 호실들
(2, '501', 5, 'OFFICE', 200.00, 50.00, 3500000, 40000000, 500000, 'OCCUPIED', 8, 3, true, true, 1, 1),
(2, '502', 5, 'OFFICE', 180.00, 45.00, 3200000, 38000000, 450000, 'MAINTENANCE', 7, 2, true, true, 1, 1),
(2, '601', 6, 'OFFICE', 250.00, 60.00, 4000000, 50000000, 600000, 'AVAILABLE', 10, 3, true, true, 1, 1),
-- 레지던스 C동 호실들
(3, '1001', 10, 'RESIDENTIAL', 84.50, 15.00, 2500000, 30000000, 350000, 'OCCUPIED', 3, 2, true, true, 1, 1),
(3, '1002', 10, 'RESIDENTIAL', 84.50, 15.00, 2500000, 30000000, 350000, 'OCCUPIED', 3, 2, true, true, 1, 1);

-- =====================================================
-- 3. 임대인 및 임차인 테스트 데이터
-- =====================================================

-- 임대인 데이터
INSERT INTO lessors (
    name, entity_type, business_registration_number, representative_name,
    primary_phone, email, address, bank_name, account_holder,
    is_active, privacy_consent, created_by, updated_by
) VALUES 
('김소유', 'INDIVIDUAL', NULL, NULL, '010-1111-1111', 'owner1@example.com',
 '서울시 강남구 역삼동 123-45', '국민은행', '김소유', true, true, 1, 1),
('이건물', 'INDIVIDUAL', NULL, NULL, '010-2222-2222', 'owner2@example.com',
 '서울시 서초구 잠원동 678-90', '신한은행', '이건물', true, true, 1, 1),
('박임대', 'INDIVIDUAL', NULL, NULL, '010-3333-3333', 'owner3@example.com',
 '서울시 마포구 상암동 111-22', '우리은행', '박임대', true, true, 1, 1);

-- 임차인 데이터
INSERT INTO tenants (
    name, entity_type, business_registration_number, representative_name,
    primary_phone, email, current_address, occupation, monthly_income,
    family_members, is_active, privacy_consent, created_by, updated_by
) VALUES 
('김철수', 'INDIVIDUAL', NULL, NULL, '010-1234-5678', 'tenant1@example.com',
 '서울시 강남구 테헤란로 123 101호', '회사원', 5000000, 2, true, true, 1, 1),
('박영희', 'INDIVIDUAL', NULL, NULL, '010-2345-6789', 'tenant2@example.com',
 '서울시 강남구 테헤란로 123 102호', '프리랜서', 4000000, 1, true, true, 1, 1),
('이민수', 'INDIVIDUAL', NULL, NULL, '010-3456-7890', 'tenant3@example.com',
 '서울시 강남구 테헤란로 123 201호', '사업자', 8000000, 3, true, true, 1, 1),
('정미영', 'INDIVIDUAL', NULL, NULL, '010-4567-8901', 'tenant4@example.com',
 '서울시 서초구 서초대로 456 501호', '의사', 12000000, 4, true, true, 1, 1),
('최영수', 'CORPORATION', '123-45-67890', '최영수', '010-5678-9012', 'company1@example.com',
 '서울시 마포구 상암동 789 1001호', '법인대표', 15000000, 1, true, true, 1, 1),
('한국테크', 'CORPORATION', '234-56-78901', '한국테크', '02-1234-5678', 'tech@korea.com',
 '서울시 마포구 상암동 789 1002호', '소프트웨어개발', 20000000, 1, true, true, 1, 1);

-- =====================================================
-- 4. 관리비 항목 및 정책 테스트 데이터
-- =====================================================

-- 관리비 항목 데이터
INSERT INTO fee_items (
    building_id, name, code, fee_type, calculation_method, charge_target,
    unit_price, fixed_amount, is_taxable, is_active, display_order,
    created_by, updated_by
) VALUES 
-- 스마트빌딩 A동 관리비 항목
(1, '일반관리비', 'GENERAL_MGMT', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 1000.00, NULL, false, true, 1, 1, 1),
(1, '청소비', 'CLEANING', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 500.00, NULL, false, true, 2, 1, 1),
(1, '보안비', 'SECURITY', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 50000.00, false, true, 3, 1, 1),
(1, '승강기유지비', 'ELEVATOR', 'COMMON_MAINTENANCE', 'HOUSEHOLD_BASED', 'ALL_UNITS', NULL, 30000.00, false, true, 4, 1, 1),
(1, '전기료', 'ELECTRICITY', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 120.50, NULL, true, true, 5, 1, 1),
(1, '수도료', 'WATER', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 800.00, NULL, true, true, 6, 1, 1),
(1, '가스료', 'GAS', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 950.00, NULL, true, true, 7, 1, 1),
-- 그린타워 B동 관리비 항목
(2, '일반관리비', 'GENERAL_MGMT', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 1200.00, NULL, false, true, 1, 1, 1),
(2, '청소비', 'CLEANING', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 600.00, NULL, false, true, 2, 1, 1),
(2, '전기료', 'ELECTRICITY', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 125.00, NULL, true, true, 3, 1, 1),
-- 레지던스 C동 관리비 항목
(3, '일반관리비', 'GENERAL_MGMT', 'COMMON_MAINTENANCE', 'AREA_BASED', 'ALL_UNITS', 1500.00, NULL, false, true, 1, 1, 1),
(3, '전기료', 'ELECTRICITY', 'INDIVIDUAL_UTILITY', 'UNIT_PRICE', 'ALL_UNITS', 130.00, NULL, true, true, 2, 1, 1);

-- 납부 정책 데이터
INSERT INTO payment_policies (
    building_id, policy_name, payment_due_day, grace_period_days, late_fee_rate,
    bank_name, account_number, account_holder, effective_from,
    is_active, created_by, updated_by
) VALUES 
(1, '스마트빌딩 A동 납부정책', 5, 5, 0.0200, '국민은행', '123-456-789012', 'QIRO관리', '2024-01-01', true, 1, 1),
(2, '그린타워 B동 납부정책', 10, 3, 0.0180, '신한은행', '234-567-890123', 'QIRO관리', '2024-01-01', true, 1, 1),
(3, '레지던스 C동 납부정책', 25, 7, 0.0220, '우리은행', '345-678-901234', 'QIRO관리', '2024-01-01', true, 1, 1);

-- 외부 고지서 계정 데이터
INSERT INTO external_bill_accounts (
    building_id, provider_name, provider_type, account_number, usage_purpose,
    connected_units, is_active, created_by, updated_by
) VALUES 
(1, '한국전력공사', 'KEPCO', '1234567890', '건물 전체 전기', '[1,2,3,4,5]', true, 1, 1),
(1, '서울시 상수도사업본부', 'K_WATER', '9876543210', '건물 전체 수도', '[1,2,3,4,5]', true, 1, 1),
(2, '한국전력공사', 'KEPCO', '2345678901', '건물 전체 전기', '[6,7,8]', true, 1, 1),
(3, '한국전력공사', 'KEPCO', '3456789012', '건물 전체 전기', '[9,10]', true, 1, 1);

-- =====================================================
-- 5. 임대 계약 테스트 데이터
-- =====================================================

INSERT INTO lease_contracts (
    contract_number, unit_id, tenant_id, lessor_id, start_date, end_date,
    monthly_rent, deposit, maintenance_fee, contract_type, status,
    created_by, updated_by
) VALUES 
('LC2024001', 1, 1, 1, '2024-01-01', '2025-12-31', 1500000, 15000000, 200000, 'NEW', 'ACTIVE', 1, 1),
('LC2024002', 2, 2, 1, '2024-02-01', '2025-01-31', 1800000, 20000000, 250000, 'NEW', 'ACTIVE', 1, 1),
('LC2024003', 3, 3, 1, '2024-03-01', '2026-02-28', 2200000, 25000000, 300000, 'NEW', 'ACTIVE', 1, 1),
('LC2024004', 6, 4, 2, '2024-01-01', '2025-12-31', 3500000, 40000000, 500000, 'NEW', 'ACTIVE', 1, 1),
('LC2024005', 9, 5, 3, '2024-06-01', '2026-05-31', 2500000, 30000000, 350000, 'NEW', 'ACTIVE', 1, 1),
('LC2024006', 10, 6, 3, '2024-07-01', '2026-06-30', 2500000, 30000000, 350000, 'NEW', 'ACTIVE', 1, 1);

-- =====================================================
-- 6. 청구월 및 관리비 테스트 데이터
-- =====================================================

-- 2024년 청구월 데이터
INSERT INTO billing_months (
    building_id, billing_year, billing_month, status, due_date,
    external_bill_input_completed, meter_reading_completed,
    created_by, updated_by
) VALUES 
(1, 2024, 12, 'CLOSED', '2025-01-05', true, true, 1, 1),
(1, 2025, 1, 'INVOICED', '2025-02-05', true, true, 1, 1),
(1, 2025, 2, 'DRAFT', '2025-03-05', false, false, 1, 1),
(2, 2024, 12, 'CLOSED', '2025-01-10', true, true, 1, 1),
(2, 2025, 1, 'CALCULATED', '2025-02-10', true, true, 1, 1),
(3, 2024, 12, 'INVOICED', '2025-01-25', true, true, 1, 1),
(3, 2025, 1, 'DATA_INPUT', '2025-02-25', false, true, 1, 1);

-- 검침 데이터
INSERT INTO unit_meter_readings (
    billing_month_id, unit_id, meter_type, previous_reading, current_reading,
    unit_price, reading_date, is_verified, created_by, updated_by
) VALUES 
-- 2025년 1월 스마트빌딩 A동 검침 데이터
(2, 1, 'ELECTRICITY', 1500.0, 1650.0, 120.50, '2025-01-25', true, 1, 1),
(2, 1, 'WATER', 80.0, 95.0, 800.00, '2025-01-25', true, 1, 1),
(2, 2, 'ELECTRICITY', 1800.0, 1980.0, 120.50, '2025-01-25', true, 1, 1),
(2, 2, 'WATER', 100.0, 118.0, 800.00, '2025-01-25', true, 1, 1),
(2, 3, 'ELECTRICITY', 2200.0, 2420.0, 120.50, '2025-01-25', true, 1, 1),
(2, 3, 'WATER', 120.0, 142.0, 800.00, '2025-01-25', true, 1, 1);

-- 월별 관리비 산정 결과
INSERT INTO monthly_fees (
    billing_month_id, unit_id, fee_item_id, calculation_method,
    unit_price, quantity, calculated_amount, tax_amount,
    created_by, updated_by
) VALUES 
-- 101호 2025년 1월 관리비
(2, 1, 1, 'UNIT_BASED', 1000.00, 100.50, 100500, 0, 1, 1),  -- 일반관리비
(2, 1, 2, 'UNIT_BASED', 500.00, 100.50, 50250, 0, 1, 1),    -- 청소비
(2, 1, 3, 'FIXED_AMOUNT', NULL, NULL, 50000, 0, 1, 1),       -- 보안비
(2, 1, 4, 'FIXED_AMOUNT', NULL, NULL, 30000, 0, 1, 1),       -- 승강기유지비
(2, 1, 5, 'USAGE_BASED', 120.50, 150.0, 18075, 1808, 1, 1), -- 전기료
(2, 1, 6, 'USAGE_BASED', 800.00, 15.0, 12000, 1200, 1, 1),  -- 수도료
-- 102호 2025년 1월 관리비
(2, 2, 1, 'UNIT_BASED', 1000.00, 120.20, 120200, 0, 1, 1),
(2, 2, 2, 'UNIT_BASED', 500.00, 120.20, 60100, 0, 1, 1),
(2, 2, 3, 'FIXED_AMOUNT', NULL, NULL, 50000, 0, 1, 1),
(2, 2, 4, 'FIXED_AMOUNT', NULL, NULL, 30000, 0, 1, 1),
(2, 2, 5, 'USAGE_BASED', 120.50, 180.0, 21690, 2169, 1, 1),
(2, 2, 6, 'USAGE_BASED', 800.00, 18.0, 14400, 1440, 1, 1);--
 고지서 데이터
INSERT INTO invoices (
    billing_month_id, unit_id, invoice_number, issue_date, due_date,
    subtotal_amount, tax_amount, status, created_by, updated_by
) VALUES 
(2, 1, 'B001-2025-01-0001', '2025-01-30', '2025-02-05', 260750, 3008, 'ISSUED', 1, 1),
(2, 2, 'B001-2025-01-0002', '2025-01-30', '2025-02-05', 296300, 3609, 'ISSUED', 1, 1);

-- 고지서 상세 항목
INSERT INTO invoice_line_items (
    invoice_id, monthly_fee_id, fee_item_name, amount, tax_amount, display_order
) VALUES 
-- 101호 고지서 상세
(1, 1, '일반관리비', 100500, 0, 1),
(1, 2, '청소비', 50250, 0, 2),
(1, 3, '보안비', 50000, 0, 3),
(1, 4, '승강기유지비', 30000, 0, 4),
(1, 5, '전기료', 18075, 1808, 5),
(1, 6, '수도료', 12000, 1200, 6),
-- 102호 고지서 상세
(1, 7, '일반관리비', 120200, 0, 1),
(1, 8, '청소비', 60100, 0, 2),
(1, 9, '보안비', 50000, 0, 3),
(1, 10, '승강기유지비', 30000, 0, 4),
(1, 11, '전기료', 21690, 2169, 5),
(1, 12, '수도료', 14400, 1440, 6);

-- =====================================================
-- 7. 수납 및 미납 테스트 데이터
-- =====================================================

-- 정상 수납 케이스
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(1, '2025-02-03', 263758, 'BANK_TRANSFER', 'TXN20250203001', '정상 납부', 'COMPLETED', 1);

-- 부분 수납 케이스 (102호)
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_reference,
    notes, payment_status, processed_by
) VALUES 
(2, '2025-02-10', 200000, 'CASH', 'CASH20250210001', '부분 납부', 'COMPLETED', 1);

-- 수납 상세 내역
INSERT INTO payment_details (payment_id, fee_item_id, allocated_amount, is_late_fee) VALUES
(2, 7, 120200, false),  -- 일반관리비
(2, 8, 60100, false),   -- 청소비
(2, 9, 19700, false);   -- 보안비 일부

-- =====================================================
-- 8. 임대료 테스트 데이터
-- =====================================================

-- 월별 임대료 데이터
INSERT INTO monthly_rents (
    lease_contract_id, rent_year, rent_month, rent_amount, maintenance_fee,
    due_date, payment_status, paid_amount, paid_date, created_by, updated_by
) VALUES 
-- 101호 (계약 ID: 1) 임대료
(1, 2024, 12, 1500000, 200000, '2024-12-05', 'PAID', 1700000, '2024-12-03', 1, 1),
(1, 2025, 1, 1500000, 200000, '2025-01-05', 'PAID', 1700000, '2025-01-04', 1, 1),
(1, 2025, 2, 1500000, 200000, '2025-02-05', 'PENDING', 0, NULL, 1, 1),
-- 102호 (계약 ID: 2) 임대료
(2, 2024, 12, 1800000, 250000, '2024-12-05', 'PAID', 2050000, '2024-12-04', 1, 1),
(2, 2025, 1, 1800000, 250000, '2025-01-05', 'OVERDUE', 0, NULL, 1, 1),
-- 501호 (계약 ID: 4) 임대료
(4, 2024, 12, 3500000, 500000, '2024-12-10', 'PAID', 4000000, '2024-12-09', 1, 1),
(4, 2025, 1, 3500000, 500000, '2025-01-10', 'PAID', 4000000, '2025-01-08', 1, 1);

-- 임대료 납부 내역
INSERT INTO rent_payments (
    monthly_rent_id, payment_date, payment_amount, payment_method,
    payment_reference, rent_portion, maintenance_portion, late_fee_portion, created_by
) VALUES 
(1, '2024-12-03', 1700000, 'BANK_TRANSFER', '김철수', 1500000, 200000, 0, 1),
(2, '2025-01-04', 1700000, 'BANK_TRANSFER', '김철수', 1500000, 200000, 0, 1),
(4, '2024-12-04', 2050000, 'BANK_TRANSFER', '박영희', 1800000, 250000, 0, 1),
(7, '2024-12-09', 4000000, 'BANK_TRANSFER', '정미영', 3500000, 500000, 0, 1),
(8, '2025-01-08', 4000000, 'BANK_TRANSFER', '정미영', 3500000, 500000, 0, 1);

-- 임대료 연체 데이터
INSERT INTO rent_delinquencies (
    monthly_rent_id, overdue_amount, overdue_start_date, overdue_days,
    late_fee_rate, calculated_late_fee, applied_late_fee, is_resolved, created_by, updated_by
) VALUES 
(5, 2050000, '2025-01-06', 25, 0.0005, 25625, 25625, false, 1, 1);

-- =====================================================
-- 9. 시설물 및 유지보수 테스트 데이터
-- =====================================================

-- 시설물 데이터
INSERT INTO facilities (
    building_id, facility_code, facility_name, category, subcategory,
    location_description, floor_number, manufacturer, model_number,
    installation_date, warranty_end_date, maintenance_cycle_months,
    expected_lifespan_years, status, created_by
) VALUES 
(1, 'ELV-001', '승객용 엘리베이터 #1', 'ELEVATOR', '승객용',
 '1층 로비', 1, '현대엘리베이터', 'HE-2000',
 '2023-01-15', '2025-01-14', 1, 20, 'ACTIVE', 1),
(1, 'HVAC-B1-001', '중앙 냉난방 시스템', 'HVAC', '중앙공조',
 '지하1층 기계실', -1, '삼성공조', 'SC-5000',
 '2023-02-01', '2025-01-31', 3, 15, 'ACTIVE', 1),
(2, 'ELV-001', '승객용 엘리베이터 #1', 'ELEVATOR', '승객용',
 '1층 로비', 1, 'LG엘리베이터', 'LG-1500',
 '2022-12-01', '2024-11-30', 1, 20, 'MAINTENANCE', 1);

-- 협력업체 데이터
INSERT INTO facility_vendors (
    company_name, contact_person, contact_phone, contact_email,
    business_registration_number, specialization, address, is_active
) VALUES 
('현대엘리베이터서비스', '김기술', '02-1234-5678', 'tech@hyundai-elevator.co.kr',
 '123-45-67890', '엘리베이터', '서울시 강남구 테헤란로 123', true),
('삼성공조기술', '이냉방', '02-2345-6789', 'service@samsung-hvac.co.kr',
 '234-56-78901', '냉난방', '서울시 서초구 서초대로 456', true),
('한국소방안전', '박소방', '02-3456-7890', 'safety@korea-fire.co.kr',
 '345-67-89012', '소방설비', '서울시 영등포구 여의도동 789', true);

-- 유지보수 요청 데이터
INSERT INTO maintenance_requests (
    building_id, facility_id, request_type, title, description,
    requester_name, requester_contact, requester_type, priority,
    status, assigned_to, estimated_cost, created_by
) VALUES 
(1, 1, 'REPAIR', '엘리베이터 이상음 발생',
 '승객용 엘리베이터에서 운행 중 이상음이 발생합니다.',
 '김입주', '010-1111-2222', 'TENANT', 'HIGH',
 'COMPLETED', 2, 150000, 1),
(1, 2, 'MAINTENANCE', '냉난방 온도 조절 불량',
 '사무실 온도가 설정 온도와 다르게 나옵니다.',
 '이관리', '010-3333-4444', 'MANAGER', 'MEDIUM',
 'IN_PROGRESS', 2, 80000, 1);

-- 유지보수 작업 데이터
INSERT INTO maintenance_works (
    request_id, facility_id, vendor_id, work_title, work_description, work_type,
    scheduled_start_date, actual_start_time, actual_end_time,
    primary_worker_name, labor_cost, material_cost, status,
    work_quality_rating, completion_percentage, created_by
) VALUES 
(1, 1, 1, '엘리베이터 베어링 교체', '이상음 원인인 베어링 교체 작업', 'REPAIR',
 '2024-12-20', '2024-12-20 09:00:00', '2024-12-20 12:00:00',
 '김기술', 80000, 60000, 'COMPLETED', 5, 100, 1);

-- =====================================================
-- 10. 민원 및 공지사항 테스트 데이터
-- =====================================================

-- 민원 데이터
INSERT INTO complaints (
    complaint_number, building_id, unit_id, category_id, complainant_name,
    complainant_contact, title, description, priority, status,
    assigned_to, sla_due_at, sla_hours, submitted_at, created_by, updated_by
) VALUES 
('C202501001', 1, 1, 1, '김철수', '010-1234-5678',
 '엘리베이터 고장', '엘리베이터가 자주 멈춥니다.', 'HIGH', 'RESOLVED',
 2, '2025-01-31 18:00:00', 24, '2025-01-30 18:00:00', 1, 1),
('C202501002', 1, 2, 2, '박영희', '010-2345-6789',
 '층간소음 문제', '위층에서 소음이 심합니다.', 'MEDIUM', 'IN_PROGRESS',
 2, '2025-02-01 18:00:00', 48, '2025-01-30 18:00:00', 1, 1);

-- 공지사항 데이터
INSERT INTO announcements (
    announcement_number, building_id, category_id, title, content, summary,
    target_audience, is_urgent, status, published_at, created_by, updated_by
) VALUES 
('A202501001', 1, 1, '2월 정기점검 안내',
 '2월 중 엘리베이터 정기점검이 예정되어 있습니다. 점검 시간 동안 불편을 드려 죄송합니다.',
 '2월 엘리베이터 정기점검 안내', 'ALL', false, 'PUBLISHED', '2025-01-30 09:00:00', 1, 1),
('A202501002', NULL, 4, '긴급 공지: 수도 공급 중단',
 '수도관 공사로 인해 내일 오전 9시부터 12시까지 수도 공급이 중단됩니다.',
 '수도 공급 중단 안내', 'ALL', true, 'PUBLISHED', '2025-01-30 15:00:00', 1, 1);

-- 알림 데이터
INSERT INTO notifications (
    notification_number, recipient_type, recipient_id, recipient_name,
    notification_type, title, message, channels, priority, status,
    created_by
) VALUES 
('N202501001', 'USER', 2, '이직원', 'COMPLAINT_UPDATE',
 '새 민원이 배정되었습니다', '민원 C202501002가 귀하에게 배정되었습니다.',
 ARRAY['IN_APP', 'EMAIL'], 3, 'SENT', 1),
('N202501002', 'USER', 1, '김철수', 'BILLING_NOTICE',
 '관리비 납부 안내', '2025년 2월 관리비 납부 기한이 임박했습니다.',
 ARRAY['IN_APP', 'SMS'], 3, 'DELIVERED', 1);

-- =====================================================
-- 11. 회계 테스트 데이터
-- =====================================================

-- 회계 기간 데이터
INSERT INTO accounting_periods (
    building_id, period_year, period_month, start_date, end_date, status
) VALUES 
(1, 2024, 12, '2024-12-01', '2024-12-31', 'CLOSED'),
(1, 2025, 1, '2025-01-01', '2025-01-31', 'OPEN'),
(2, 2024, 12, '2024-12-01', '2024-12-31', 'CLOSED'),
(2, 2025, 1, '2025-01-01', '2025-01-31', 'OPEN');

-- 회계 전표 데이터
INSERT INTO journal_entries (
    building_id, entry_date, reference_number, description,
    total_debit, total_credit, status, created_by, posted_by
) VALUES 
(1, '2025-01-30', 'JE202501001', '2025년 1월 관리비 수입',
 263758, 263758, 'POSTED', 1, 1),
(1, '2025-01-30', 'JE202501002', '엘리베이터 수리비 지출',
 150000, 150000, 'POSTED', 1, 1);

-- 회계 전표 상세 데이터
INSERT INTO journal_entry_details (
    journal_entry_id, account_id, debit_amount, credit_amount, description
) VALUES 
-- 관리비 수입 전표
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '1100'), 263758, 0, '관리비 수납'),
(1, (SELECT id FROM chart_of_accounts WHERE account_code = '4200'), 0, 263758, '관리비 수익'),
-- 수리비 지출 전표
(2, (SELECT id FROM chart_of_accounts WHERE account_code = '5200'), 150000, 0, '엘리베이터 수리비'),
(2, (SELECT id FROM chart_of_accounts WHERE account_code = '1100'), 0, 150000, '현금 지출');

-- =====================================================
-- 12. 시스템 설정 테스트 데이터
-- =====================================================

-- 시스템 설정 데이터
INSERT INTO system_settings (
    setting_key, setting_value, setting_type, category, description,
    is_public, created_by, updated_by
) VALUES 
('system.timezone', 'Asia/Seoul', 'string', 'system', '시스템 기본 시간대', true, 1, 1),
('system.currency', 'KRW', 'string', 'system', '시스템 기본 통화', true, 1, 1),
('email.smtp_host', 'smtp.gmail.com', 'string', 'email', 'SMTP 서버 호스트', false, 1, 1),
('email.smtp_port', '587', 'number', 'email', 'SMTP 서버 포트', false, 1, 1),
('billing.late_fee_rate', '0.02', 'number', 'billing', '기본 연체료율 (월)', false, 1, 1);

-- 외부 서비스 설정 데이터
INSERT INTO external_service_configs (
    service_name, service_type, config_data, is_active, is_test_mode,
    api_endpoint, health_status, created_by, updated_by
) VALUES 
('Gmail SMTP', 'email', '{"host": "smtp.gmail.com", "port": 587, "secure": false}',
 true, false, 'smtp.gmail.com:587', 'healthy', 1, 1),
('KakaoTalk Alimtalk', 'sms', '{"app_key": "test_key", "sender_key": "test_sender"}',
 true, true, 'https://kapi.kakao.com', 'unknown', 1, 1);

-- =====================================================
-- 13. 감사 로그 테스트 데이터
-- =====================================================

-- 사용자 세션 데이터
INSERT INTO user_sessions (
    user_id, session_token, ip_address, user_agent, expires_at, is_active
) VALUES 
(1, 'session_token_admin_001', '192.168.1.100', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', '2025-01-31 23:59:59', true),
(2, 'session_token_manager_001', '192.168.1.101', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', '2025-01-31 23:59:59', true);

-- 로그인 이력 데이터
INSERT INTO login_history (
    user_id, username, login_type, ip_address, user_agent, session_id
) VALUES 
(1, 'admin', 'SUCCESS', '192.168.1.100', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 1),
(2, 'manager1', 'SUCCESS', '192.168.1.101', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 2),
(2, 'manager1', 'FAILED', '192.168.1.101', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', NULL);

-- 감사 로그 데이터 (주요 작업들)
INSERT INTO audit_logs (
    table_name, record_id, action, new_values, user_id, session_id,
    ip_address, building_id
) VALUES 
('buildings', 1, 'INSERT', '{"name": "스마트빌딩 A동", "status": "ACTIVE"}', 1, 1, '192.168.1.100', 1),
('invoices', 1, 'INSERT', '{"invoice_number": "B001-2025-01-0001", "status": "ISSUED"}', 2, 2, '192.168.1.101', 1),
('payments', 1, 'INSERT', '{"amount": 263758, "payment_status": "COMPLETED"}', 2, 2, '192.168.1.101', 1);

-- =====================================================
-- 14. 데이터 검증 쿼리
-- =====================================================

-- 기본 데이터 개수 확인
SELECT 
    'buildings' as table_name, COUNT(*) as count FROM buildings
UNION ALL
SELECT 'units', COUNT(*) FROM units
UNION ALL
SELECT 'lessors', COUNT(*) FROM lessors
UNION ALL
SELECT 'tenants', COUNT(*) FROM tenants
UNION ALL
SELECT 'lease_contracts', COUNT(*) FROM lease_contracts
UNION ALL
SELECT 'fee_items', COUNT(*) FROM fee_items
UNION ALL
SELECT 'billing_months', COUNT(*) FROM billing_months
UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'monthly_rents', COUNT(*) FROM monthly_rents
UNION ALL
SELECT 'facilities', COUNT(*) FROM facilities
UNION ALL
SELECT 'maintenance_requests', COUNT(*) FROM maintenance_requests
UNION ALL
SELECT 'complaints', COUNT(*) FROM complaints
UNION ALL
SELECT 'announcements', COUNT(*) FROM announcements
UNION ALL
SELECT 'users', COUNT(*) FROM users
ORDER BY table_name;

-- 데이터 무결성 검증
SELECT 
    '건물별 호실 수 일치 검증' as test_name,
    b.name as building_name,
    b.total_units as recorded_total,
    COUNT(u.id) as actual_count,
    CASE WHEN b.total_units = COUNT(u.id) THEN 'PASS' ELSE 'FAIL' END as result
FROM buildings b
LEFT JOIN units u ON b.id = u.building_id
GROUP BY b.id, b.name, b.total_units
ORDER BY b.name;

-- 관리비 계산 검증
SELECT 
    '관리비 계산 검증' as test_name,
    i.invoice_number,
    i.subtotal_amount + i.tax_amount as invoice_total,
    SUM(ili.amount + ili.tax_amount) as line_items_total,
    CASE WHEN i.subtotal_amount + i.tax_amount = SUM(ili.amount + ili.tax_amount) 
         THEN 'PASS' ELSE 'FAIL' END as result
FROM invoices i
JOIN invoice_line_items ili ON i.id = ili.invoice_id
GROUP BY i.id, i.invoice_number, i.subtotal_amount, i.tax_amount
ORDER BY i.invoice_number;

-- 수납 금액 검증
SELECT 
    '수납 금액 검증' as test_name,
    p.id as payment_id,
    p.amount as payment_amount,
    COALESCE(SUM(pd.allocated_amount), 0) as allocated_total,
    CASE WHEN p.amount = COALESCE(SUM(pd.allocated_amount), p.amount) 
         THEN 'PASS' ELSE 'FAIL' END as result
FROM payments p
LEFT JOIN payment_details pd ON p.id = pd.payment_id
WHERE p.payment_status = 'COMPLETED'
GROUP BY p.id, p.amount
ORDER BY p.id;

-- 임대 계약 중복 검증
SELECT 
    '임대 계약 중복 검증' as test_name,
    u.unit_number,
    COUNT(*) as active_contracts,
    CASE WHEN COUNT(*) <= 1 THEN 'PASS' ELSE 'FAIL' END as result
FROM lease_contracts lc
JOIN units u ON lc.unit_id = u.id
WHERE lc.status = 'ACTIVE'
  AND CURRENT_DATE BETWEEN lc.start_date AND lc.end_date
GROUP BY u.id, u.unit_number
ORDER BY u.unit_number;

-- 회계 전표 차대평형 검증
SELECT 
    '회계 전표 차대평형 검증' as test_name,
    je.reference_number,
    je.total_debit,
    je.total_credit,
    CASE WHEN je.total_debit = je.total_credit THEN 'PASS' ELSE 'FAIL' END as result
FROM journal_entries je
WHERE je.status = 'POSTED'
ORDER BY je.reference_number;

-- =====================================================
-- 15. 성능 테스트용 추가 데이터 (선택사항)
-- =====================================================

-- 대량 데이터 생성 (성능 테스트용 - 주석 처리)
/*
-- 추가 호실 데이터 생성 (100개)
INSERT INTO units (
    building_id, unit_number, floor_number, unit_type, area, monthly_rent, deposit,
    status, created_by, updated_by
)
SELECT 
    1 as building_id,
    LPAD((i % 50 + 1)::text, 3, '0') as unit_number,
    (i / 10) + 1 as floor_number,
    'COMMERCIAL' as unit_type,
    80.0 + (i % 50) as area,
    1500000 + (i % 10) * 100000 as monthly_rent,
    15000000 + (i % 10) * 1000000 as deposit,
    CASE WHEN i % 3 = 0 THEN 'AVAILABLE' ELSE 'OCCUPIED' END as status,
    1 as created_by,
    1 as updated_by
FROM generate_series(1, 100) as i;

-- 대량 수납 데이터 생성 (1000건)
INSERT INTO payments (
    invoice_id, payment_date, amount, payment_method, payment_status, processed_by
)
SELECT 
    (i % 10) + 1 as invoice_id,
    '2025-01-01'::date + (i % 30) as payment_date,
    100000 + (i % 500000) as amount,
    CASE (i % 5)
        WHEN 0 THEN 'CASH'
        WHEN 1 THEN 'BANK_TRANSFER'
        WHEN 2 THEN 'CARD'
        WHEN 3 THEN 'CMS'
        ELSE 'VIRTUAL_ACCOUNT'
    END as payment_method,
    'COMPLETED' as payment_status,
    1 as processed_by
FROM generate_series(1, 1000) as i;
*/

-- 테스트 데이터 생성 완료 메시지
SELECT 'QIRO 건물 관리 SaaS 테스트 데이터 생성이 완료되었습니다.' as message;

COMMIT;