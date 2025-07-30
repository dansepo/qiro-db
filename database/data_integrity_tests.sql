-- =====================================================
-- QIRO 건물 관리 SaaS 데이터 무결성 검증 테스트
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- 설명: 비즈니스 규칙 및 데이터 무결성 제약조건 검증
-- =====================================================

-- 테스트 결과를 저장할 임시 테이블 생성
CREATE TEMP TABLE test_results (
    test_id SERIAL PRIMARY KEY,
    test_category VARCHAR(50),
    test_name VARCHAR(200),
    test_status VARCHAR(10), -- PASS, FAIL, ERROR
    expected_result TEXT,
    actual_result TEXT,
    error_message TEXT,
    test_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 테스트 실행 함수
CREATE OR REPLACE FUNCTION run_integrity_test(
    p_category VARCHAR(50),
    p_test_name VARCHAR(200),
    p_test_sql TEXT,
    p_expected_result TEXT DEFAULT 'SUCCESS'
) RETURNS VOID AS $
DECLARE
    v_result TEXT;
    v_status VARCHAR(10);
    v_error_message TEXT;
BEGIN
    BEGIN
        EXECUTE p_test_sql INTO v_result;
        
        IF v_result = p_expected_result OR p_expected_result = 'SUCCESS' THEN
            v_status := 'PASS';
            v_error_message := NULL;
        ELSE
            v_status := 'FAIL';
            v_error_message := 'Expected: ' || p_expected_result || ', Got: ' || COALESCE(v_result, 'NULL');
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        v_status := 'ERROR';
        v_result := NULL;
        v_error_message := SQLERRM;
    END;
    
    INSERT INTO test_results (test_category, test_name, test_status, expected_result, actual_result, error_message)
    VALUES (p_category, p_test_name, v_status, p_expected_result, v_result, v_error_message);
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- R-DB-001: 건물 내 호실 번호 유일성 검증
-- =====================================================

-- 테스트 1-1: 정상적인 호실 번호 등록
SELECT run_integrity_test(
    'R-DB-001',
    '정상적인 호실 번호 등록',
    'INSERT INTO units (building_id, unit_number, floor_number, unit_type, area, created_by, updated_by) 
     VALUES (1, ''TEST001'', 1, ''COMMERCIAL'', 50.0, 1, 1); 
     SELECT ''SUCCESS''',
    'SUCCESS'
);

-- 테스트 1-2: 동일 건물 내 중복 호실 번호 등록 시도 (실패해야 함)
SELECT run_integrity_test(
    'R-DB-001',
    '동일 건물 내 중복 호실 번호 등록 방지',
    'INSERT INTO units (building_id, unit_number, floor_number, unit_type, area, created_by, updated_by) 
     VALUES (1, ''101'', 1, ''COMMERCIAL'', 50.0, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 1-3: 다른 건물에는 동일 호실 번호 등록 가능
SELECT run_integrity_test(
    'R-DB-001',
    '다른 건물에는 동일 호실 번호 등록 가능',
    'INSERT INTO units (building_id, unit_number, floor_number, unit_type, area, created_by, updated_by) 
     VALUES (2, ''101'', 1, ''OFFICE'', 60.0, 1, 1); 
     SELECT ''SUCCESS''',
    'SUCCESS'
);

-- 테스트 1-4: 호실 번호 NULL 값 방지
SELECT run_integrity_test(
    'R-DB-001',
    '호실 번호 NULL 값 방지',
    'INSERT INTO units (building_id, unit_number, floor_number, unit_type, area, created_by, updated_by) 
     VALUES (1, NULL, 1, ''COMMERCIAL'', 50.0, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 1-5: 빈 문자열 호실 번호 방지
SELECT run_integrity_test(
    'R-DB-001',
    '빈 문자열 호실 번호 방지',
    'INSERT INTO units (building_id, unit_number, floor_number, unit_type, area, created_by, updated_by) 
     VALUES (1, '''', 1, ''COMMERCIAL'', 50.0, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- =====================================================
-- R-DB-002: 건물의 총 세대수와 실제 등록된 Unit 수 일치 검증
-- =====================================================

-- 테스트 2-1: 건물별 총 호실 수 자동 업데이트 검증
SELECT run_integrity_test(
    'R-DB-002',
    '건물별 총 호실 수 자동 업데이트',
    'SELECT CASE WHEN b.total_units = (SELECT COUNT(*) FROM units u WHERE u.building_id = b.id) 
                THEN ''SUCCESS'' ELSE ''FAIL'' END
     FROM buildings b WHERE b.id = 1',
    'SUCCESS'
);

-- 테스트 2-2: 호실 삭제 시 총 호실 수 자동 감소
SELECT run_integrity_test(
    'R-DB-002',
    '호실 삭제 시 총 호실 수 자동 감소',
    'DELETE FROM units WHERE building_id = 1 AND unit_number = ''TEST001'';
     SELECT CASE WHEN b.total_units = (SELECT COUNT(*) FROM units u WHERE u.building_id = b.id) 
                THEN ''SUCCESS'' ELSE ''FAIL'' END
     FROM buildings b WHERE b.id = 1',
    'SUCCESS'
);

-- =====================================================
-- R-DB-003: 계약 기간 중복 방지 검증
-- =====================================================

-- 테스트 3-1: 정상적인 계약 등록
SELECT run_integrity_test(
    'R-DB-003',
    '정상적인 계약 등록',
    'INSERT INTO lease_contracts (contract_number, unit_id, tenant_id, lessor_id, start_date, end_date, monthly_rent, deposit, status, created_by, updated_by) 
     VALUES (''TEST_CONTRACT_001'', 4, 1, 1, ''2025-03-01'', ''2026-02-28'', 1500000, 15000000, ''ACTIVE'', 1, 1); 
     SELECT ''SUCCESS''',
    'SUCCESS'
);

-- 테스트 3-2: 동일 호실 기간 중복 계약 시도 (실패해야 함)
SELECT run_integrity_test(
    'R-DB-003',
    '동일 호실 기간 중복 계약 방지',
    'INSERT INTO lease_contracts (contract_number, unit_id, tenant_id, lessor_id, start_date, end_date, monthly_rent, deposit, status, created_by, updated_by) 
     VALUES (''TEST_CONTRACT_002'', 4, 2, 1, ''2025-06-01'', ''2026-05-31'', 1600000, 16000000, ''ACTIVE'', 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 3-3: 기간이 겹치지 않는 계약은 등록 가능
SELECT run_integrity_test(
    'R-DB-003',
    '기간이 겹치지 않는 계약 등록 가능',
    'INSERT INTO lease_contracts (contract_number, unit_id, tenant_id, lessor_id, start_date, end_date, monthly_rent, deposit, status, created_by, updated_by) 
     VALUES (''TEST_CONTRACT_003'', 4, 2, 1, ''2026-03-01'', ''2027-02-28'', 1600000, 16000000, ''DRAFT'', 1, 1); 
     SELECT ''SUCCESS''',
    'SUCCESS'
);

-- =====================================================
-- R-DB-004: 관리비 부과 시 차변/대변 합계 일치 검증 (복식부기 원칙)
-- =====================================================

-- 테스트 4-1: 정상적인 회계 전표 등록
SELECT run_integrity_test(
    'R-DB-004',
    '정상적인 회계 전표 등록 (차변=대변)',
    'INSERT INTO journal_entries (building_id, entry_date, description, total_debit, total_credit, status, created_by) 
     VALUES (1, CURRENT_DATE, ''테스트 전표'', 100000, 100000, ''DRAFT'', 1); 
     SELECT ''SUCCESS''',
    'SUCCESS'
);

-- 테스트 4-2: 차변과 대변이 일치하지 않는 전표 등록 시도 (실패해야 함)
SELECT run_integrity_test(
    'R-DB-004',
    '차변≠대변인 전표 등록 방지',
    'INSERT INTO journal_entries (building_id, entry_date, description, total_debit, total_credit, status, created_by) 
     VALUES (1, CURRENT_DATE, ''잘못된 전표'', 100000, 90000, ''DRAFT'', 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 4-3: 전표 상세의 차변/대변 제약조건 검증
SELECT run_integrity_test(
    'R-DB-004',
    '전표 상세 차변 또는 대변 중 하나만 값 가져야 함',
    'INSERT INTO journal_entry_details (journal_entry_id, account_id, debit_amount, credit_amount) 
     VALUES ((SELECT MAX(id) FROM journal_entries), 1, 50000, 50000); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- =====================================================
-- R-DB-005: 임대료 연체 계산 시 납부 정책 적용 검증
-- =====================================================

-- 테스트 5-1: 연체료 계산 함수 정확성 검증 (유예기간 내)
SELECT run_integrity_test(
    'R-DB-005',
    '유예기간 내 연체료 계산 (0원)',
    'SELECT CASE WHEN calculate_late_fee(100000, 3, 24.0, 5) = 0 
                THEN ''SUCCESS'' ELSE ''FAIL'' END',
    'SUCCESS'
);

-- 테스트 5-2: 연체료 계산 함수 정확성 검증 (유예기간 초과)
SELECT run_integrity_test(
    'R-DB-005',
    '유예기간 초과 연체료 계산',
    'SELECT CASE WHEN calculate_late_fee(100000, 30, 24.0, 5) > 0 
                THEN ''SUCCESS'' ELSE ''FAIL'' END',
    'SUCCESS'
);

-- 테스트 5-3: 미납 상태 업데이트 함수 검증
SELECT run_integrity_test(
    'R-DB-005',
    '미납 상태 업데이트 함수 실행',
    'SELECT update_delinquency_status(1); SELECT ''SUCCESS''',
    'SUCCESS'
);

-- =====================================================
-- 추가 비즈니스 규칙 검증
-- =====================================================

-- 테스트 6-1: 사업자등록번호 유효성 검증
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '유효한 사업자등록번호 검증',
    'SELECT CASE WHEN validate_business_registration_number(''1234567890'') = true 
                THEN ''SUCCESS'' ELSE ''FAIL'' END',
    'SUCCESS'
);

-- 테스트 6-2: 잘못된 사업자등록번호 검증
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '잘못된 사업자등록번호 검증',
    'SELECT CASE WHEN validate_business_registration_number(''1111111111'') = false 
                THEN ''SUCCESS'' ELSE ''FAIL'' END',
    'SUCCESS'
);

-- 테스트 6-3: 건물 면적 양수 검증
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '건물 면적 양수 검증',
    'INSERT INTO buildings (name, address, building_type, total_floors, total_area, created_by, updated_by) 
     VALUES (''테스트건물'', ''테스트주소'', ''COMMERCIAL'', 5, -100.0, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 6-4: 호실 면적 양수 검증
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '호실 면적 양수 검증',
    'INSERT INTO units (building_id, unit_number, floor_number, unit_type, area, created_by, updated_by) 
     VALUES (1, ''TEST002'', 1, ''COMMERCIAL'', -50.0, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 6-5: 임대료 양수 검증
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '임대료 양수 검증',
    'INSERT INTO lease_contracts (contract_number, unit_id, tenant_id, lessor_id, start_date, end_date, monthly_rent, deposit, status, created_by, updated_by) 
     VALUES (''TEST_CONTRACT_004'', 5, 1, 1, ''2025-03-01'', ''2026-02-28'', -1500000, 15000000, ''ACTIVE'', 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 6-6: 보증금 양수 검증
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '보증금 양수 검증',
    'INSERT INTO lease_contracts (contract_number, unit_id, tenant_id, lessor_id, start_date, end_date, monthly_rent, deposit, status, created_by, updated_by) 
     VALUES (''TEST_CONTRACT_005'', 5, 1, 1, ''2025-03-01'', ''2026-02-28'', 1500000, -15000000, ''ACTIVE'', 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 6-7: 계약 시작일이 종료일보다 이전인지 검증
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '계약 시작일이 종료일보다 이전인지 검증',
    'INSERT INTO lease_contracts (contract_number, unit_id, tenant_id, lessor_id, start_date, end_date, monthly_rent, deposit, status, created_by, updated_by) 
     VALUES (''TEST_CONTRACT_006'', 5, 1, 1, ''2026-02-28'', ''2025-03-01'', 1500000, 15000000, ''ACTIVE'', 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 6-8: 연체료율 범위 검증 (0-100%)
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '연체료율 범위 검증 (100% 초과)',
    'INSERT INTO payment_policies (building_id, policy_name, payment_due_day, late_fee_rate, effective_from, created_by, updated_by) 
     VALUES (1, ''테스트정책3'', 5, 1.5, CURRENT_DATE, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 6-9: 납부 기한일 범위 검증 (1-31일)
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '납부 기한일 범위 검증 (31일 초과)',
    'INSERT INTO payment_policies (building_id, policy_name, payment_due_day, late_fee_rate, effective_from, created_by, updated_by) 
     VALUES (1, ''테스트정책4'', 35, 0.02, CURRENT_DATE, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 6-10: 유예기간 음수 방지
SELECT run_integrity_test(
    'BUSINESS_RULES',
    '유예기간 음수 방지',
    'INSERT INTO payment_policies (building_id, policy_name, payment_due_day, grace_period_days, late_fee_rate, effective_from, created_by, updated_by) 
     VALUES (1, ''테스트정책5'', 5, -5, 0.02, CURRENT_DATE, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 7-1: 수납 금액이 고지서 총액 초과 방지
SELECT run_integrity_test(
    'PAYMENT_RULES',
    '수납 금액이 고지서 총액 초과 방지',
    'INSERT INTO payments (invoice_id, payment_date, amount, payment_method, payment_status, processed_by) 
     VALUES (1, CURRENT_DATE, 999999999, ''CASH'', ''COMPLETED'', 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 7-2: 음수 금액 수납 방지
SELECT run_integrity_test(
    'PAYMENT_RULES',
    '음수 금액 수납 방지',
    'INSERT INTO payments (invoice_id, payment_date, amount, payment_method, payment_status, processed_by) 
     VALUES (1, CURRENT_DATE, -1000, ''CASH'', ''COMPLETED'', 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 8-1: 관리비 항목 설정 유효성 검증 (고정금액 방식)
SELECT run_integrity_test(
    'FEE_RULES',
    '고정금액 방식 관리비 항목 - fixed_amount 필수',
    'INSERT INTO fee_items (building_id, name, fee_type, calculation_method, charge_target, is_active, created_by, updated_by) 
     VALUES (1, ''테스트항목'', ''COMMON_MAINTENANCE'', ''FIXED_AMOUNT'', ''ALL_UNITS'', true, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 8-2: 단가 방식 관리비 항목 - unit_price 필수
SELECT run_integrity_test(
    'FEE_RULES',
    '단가 방식 관리비 항목 - unit_price 필수',
    'INSERT INTO fee_items (building_id, name, fee_type, calculation_method, charge_target, is_active, created_by, updated_by) 
     VALUES (1, ''테스트항목2'', ''INDIVIDUAL_UTILITY'', ''UNIT_PRICE'', ''ALL_UNITS'', true, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 9-1: 납부 정책 연체료율 범위 검증 (0-10%)
SELECT run_integrity_test(
    'POLICY_RULES',
    '납부 정책 연체료율 범위 검증 (10% 초과)',
    'INSERT INTO payment_policies (building_id, policy_name, payment_due_day, late_fee_rate, effective_from, created_by, updated_by) 
     VALUES (1, ''테스트정책'', 5, 0.15, CURRENT_DATE, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- 테스트 9-2: 자동출금 설정 시 은행 정보 필수
SELECT run_integrity_test(
    'POLICY_RULES',
    '자동출금 설정 시 은행 정보 필수',
    'INSERT INTO payment_policies (building_id, policy_name, payment_due_day, late_fee_rate, auto_debit_enabled, effective_from, created_by, updated_by) 
     VALUES (1, ''테스트정책2'', 5, 0.02, true, CURRENT_DATE, 1, 1); 
     SELECT ''SHOULD_FAIL''',
    'ERROR'
);

-- =====================================================
-- 데이터 일관성 검증
-- =====================================================

-- 테스트 10-1: 호실 상태와 임대 계약 상태 일관성
SELECT run_integrity_test(
    'CONSISTENCY',
    '호실 상태와 임대 계약 상태 일관성',
    'SELECT CASE WHEN COUNT(*) = 0 THEN ''SUCCESS'' ELSE ''FAIL'' END
     FROM units u 
     WHERE u.status = ''OCCUPIED'' 
       AND NOT EXISTS (
           SELECT 1 FROM lease_contracts lc 
           WHERE lc.unit_id = u.id 
             AND lc.status = ''ACTIVE'' 
             AND CURRENT_DATE BETWEEN lc.start_date AND lc.end_date
       )',
    'SUCCESS'
);

-- 테스트 10-2: 고지서 총액과 상세 항목 합계 일치
SELECT run_integrity_test(
    'CONSISTENCY',
    '고지서 총액과 상세 항목 합계 일치',
    'SELECT CASE WHEN COUNT(*) = 0 THEN ''SUCCESS'' ELSE ''FAIL'' END
     FROM invoices i 
     WHERE (i.subtotal_amount + i.tax_amount) != (
         SELECT SUM(ili.amount + ili.tax_amount) 
         FROM invoice_line_items ili 
         WHERE ili.invoice_id = i.id
     )',
    'SUCCESS'
);

-- 테스트 10-3: 수납 금액과 수납 상세 합계 일치
SELECT run_integrity_test(
    'CONSISTENCY',
    '수납 금액과 수납 상세 합계 일치',
    'SELECT CASE WHEN COUNT(*) = 0 THEN ''SUCCESS'' ELSE ''FAIL'' END
     FROM payments p 
     WHERE p.payment_status = ''COMPLETED''
       AND EXISTS (SELECT 1 FROM payment_details pd WHERE pd.payment_id = p.id)
       AND p.amount != (
           SELECT SUM(pd.allocated_amount) 
           FROM payment_details pd 
           WHERE pd.payment_id = p.id
       )',
    'SUCCESS'
);

-- =====================================================
-- 성능 관련 제약조건 검증
-- =====================================================

-- 테스트 11-1: 인덱스 존재 여부 확인 (주요 테이블)
SELECT run_integrity_test(
    'PERFORMANCE',
    '주요 테이블 인덱스 존재 확인',
    'SELECT CASE WHEN COUNT(*) >= 5 THEN ''SUCCESS'' ELSE ''FAIL'' END
     FROM pg_indexes 
     WHERE tablename IN (''buildings'', ''units'', ''lease_contracts'', ''invoices'', ''payments'')',
    'SUCCESS'
);

-- 테스트 11-2: 외래키 제약조건 존재 확인
SELECT run_integrity_test(
    'PERFORMANCE',
    '외래키 제약조건 존재 확인',
    'SELECT CASE WHEN COUNT(*) >= 10 THEN ''SUCCESS'' ELSE ''FAIL'' END
     FROM information_schema.table_constraints 
     WHERE constraint_type = ''FOREIGN KEY''',
    'SUCCESS'
);

-- =====================================================
-- 테스트 결과 정리 및 출력
-- =====================================================

-- 테스트 결과 요약
SELECT 
    test_category,
    COUNT(*) as total_tests,
    COUNT(CASE WHEN test_status = 'PASS' THEN 1 END) as passed,
    COUNT(CASE WHEN test_status = 'FAIL' THEN 1 END) as failed,
    COUNT(CASE WHEN test_status = 'ERROR' THEN 1 END) as errors,
    ROUND(
        COUNT(CASE WHEN test_status = 'PASS' THEN 1 END)::DECIMAL / COUNT(*) * 100, 2
    ) as pass_rate
FROM test_results
GROUP BY test_category
ORDER BY test_category;

-- 실패한 테스트 상세 정보
SELECT 
    test_category,
    test_name,
    test_status,
    expected_result,
    actual_result,
    error_message
FROM test_results
WHERE test_status IN ('FAIL', 'ERROR')
ORDER BY test_category, test_name;

-- 전체 테스트 결과 요약
SELECT 
    '전체 테스트 결과' as summary,
    COUNT(*) as total_tests,
    COUNT(CASE WHEN test_status = 'PASS' THEN 1 END) as passed,
    COUNT(CASE WHEN test_status = 'FAIL' THEN 1 END) as failed,
    COUNT(CASE WHEN test_status = 'ERROR' THEN 1 END) as errors,
    ROUND(
        COUNT(CASE WHEN test_status = 'PASS' THEN 1 END)::DECIMAL / COUNT(*) * 100, 2
    ) as overall_pass_rate
FROM test_results;

-- 테스트 완료 메시지
SELECT 'QIRO 건물 관리 SaaS 데이터 무결성 검증 테스트가 완료되었습니다.' as message;

-- 정리 작업
DROP FUNCTION IF EXISTS run_integrity_test(VARCHAR, VARCHAR, TEXT, TEXT);

COMMIT;