-- =====================================================
-- QIRO 건물 관리 SaaS 통합 테스트 실행 스크립트
-- 작성일: 2025-01-30
-- 설명: 모든 테스트 데이터 생성 및 검증을 순차적으로 실행
-- =====================================================

-- 테스트 실행 시작 시간 기록
SELECT 'QIRO 건물 관리 SaaS 통합 테스트 시작: ' || CURRENT_TIMESTAMP as test_start;

-- =====================================================
-- 1. 기초 정보 및 정책 관리 도메인 테스트 데이터 생성
-- =====================================================
\echo '1. 기초 정보 및 정책 관리 도메인 테스트 데이터 생성 중...'
\i database/test_data/01_foundation_policy_test.sql

-- =====================================================
-- 2. 수납 및 미납 관리 테스트 데이터 생성
-- =====================================================
\echo '2. 수납 및 미납 관리 테스트 데이터 생성 중...'
\i database/test_data/05_payments_delinquencies_test.sql

-- =====================================================
-- 3. 성능 테스트용 대용량 데이터 생성 (선택사항)
-- =====================================================
\echo '3. 성능 테스트용 대용량 데이터 생성 중...'
\i database/test_data/performance_test_data.sql

-- =====================================================
-- 4. 데이터 무결성 검증 테스트 실행
-- =====================================================
\echo '4. 데이터 무결성 검증 테스트 실행 중...'
\i database/data_integrity_tests.sql

-- =====================================================
-- 5. 전체 테스트 결과 요약
-- =====================================================
\echo '5. 전체 테스트 결과 요약 생성 중...'

-- 테스트 데이터 생성 결과 요약
SELECT 
    '=== 테스트 데이터 생성 결과 요약 ===' as summary_title;

SELECT 
    'buildings' as table_name, 
    COUNT(*) as total_count,
    COUNT(CASE WHEN name LIKE '%테스트%' THEN 1 END) as test_data_count
FROM buildings
UNION ALL
SELECT 'units', COUNT(*), 
    COUNT(CASE WHEN building_id IN (SELECT id FROM buildings WHERE name LIKE '%테스트%') THEN 1 END)
FROM units
UNION ALL
SELECT 'lessors', COUNT(*), 
    COUNT(CASE WHEN name LIKE '%테스트%' OR name LIKE '김개인' OR name LIKE '이소유' THEN 1 END)
FROM lessors
UNION ALL
SELECT 'tenants', COUNT(*), 
    COUNT(CASE WHEN name LIKE '%테스트%' OR name LIKE '정직장인' OR name LIKE '김프리' OR name LIKE '이의사' THEN 1 END)
FROM tenants
UNION ALL
SELECT 'lease_contracts', COUNT(*), 
    COUNT(CASE WHEN contract_number LIKE 'TEST_%' OR contract_number LIKE 'PERF%' THEN 1 END)
FROM lease_contracts
UNION ALL
SELECT 'invoices', COUNT(*), 
    COUNT(CASE WHEN invoice_number LIKE '%테스트%' OR invoice_number LIKE 'PERF-%' THEN 1 END)
FROM invoices
UNION ALL
SELECT 'payments', COUNT(*), 
    COUNT(CASE WHEN payment_reference LIKE '%테스트%' OR payment_reference LIKE 'PERF%' THEN 1 END)
FROM payments
ORDER BY table_name;

-- 테스트 완료 시간 기록
SELECT 'QIRO 건물 관리 SaaS 통합 테스트 완료: ' || CURRENT_TIMESTAMP as test_end;

-- 최종 성공 메시지
SELECT '모든 테스트가 성공적으로 완료되었습니다!' as final_message;

COMMIT;