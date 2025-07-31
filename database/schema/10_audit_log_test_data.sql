-- =====================================================
-- 감사 로그 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    user_rec RECORD;
    building_rec RECORD;
    audit_count INTEGER := 0;
    config_count INTEGER := 0;
BEGIN
    -- 각 회사에 대해 감사 로그 설정 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 감사 로그 설정 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 1. 감사 로그 설정 생성 (주요 테이블들)
        INSERT INTO bms.audit_log_config (
            company_id, table_name, is_audit_enabled, audit_level,
            tracked_fields, excluded_fields, sensitive_fields,
            retention_days, archive_after_days,
            notify_on_change, require_approval
        ) VALUES 
        -- 사용자 관리 테이블
        (company_rec.company_id, 'bms.users', true, 'COMPREHENSIVE',
         ARRAY['full_name', 'email', 'phone_number', 'status'], 
         ARRAY['password_hash', 'last_login_at'],
         ARRAY['email', 'phone_number'],
         2555, 365, true, true),
        
        -- 건물 관리 테이블
        (company_rec.company_id, 'bms.buildings', true, 'STANDARD',
         NULL, ARRAY['created_at', 'updated_at'],
         ARRAY['manager_phone', 'emergency_contact'],
         2555, 365, false, false),
        
        -- 호실 관리 테이블
        (company_rec.company_id, 'bms.units', true, 'STANDARD',
         ARRAY['unit_number', 'area', 'unit_type', 'status'],
         ARRAY['created_at', 'updated_at'],
         NULL,
         2555, 365, false, false),
        
        -- 입주자 테이블
        (company_rec.company_id, 'bms.tenants', true, 'COMPREHENSIVE',
         ARRAY['name', 'phone', 'email', 'move_in_date'],
         ARRAY['created_at', 'updated_at'],
         ARRAY['phone', 'email', 'personal_id', 'emergency_contact'],
         2555, 365, true, true),
        
        -- 계약 테이블
        (company_rec.company_id, 'bms.contracts', true, 'DETAILED',
         ARRAY['contract_type', 'start_date', 'end_date', 'monthly_rent', 'deposit'],
         ARRAY['created_at', 'updated_at'],
         ARRAY['monthly_rent', 'deposit', 'lessor_account'],
         2555, 365, true, false),
        
        -- 시스템 설정 테이블
        (company_rec.company_id, 'bms.system_settings', true, 'DETAILED',
         ARRAY['setting_key', 'setting_value', 'is_active'],
         ARRAY['created_at', 'updated_at'],
         ARRAY['setting_value'],
         2555, 365, true, true),
        
        -- 관리비 항목 테이블
        (company_rec.company_id, 'bms.fee_items', true, 'STANDARD',
         ARRAY['item_name', 'calculation_method', 'unit_price', 'is_active'],
         ARRAY['created_at', 'updated_at'],
         NULL,
         1825, 365, false, false);
        
        config_count := config_count + 7;
        
        -- 2. 샘플 감사 로그 생성 (실제 데이터 변경 시뮬레이션)
        FOR user_rec IN 
            SELECT user_id, full_name as name
            FROM bms.users 
            WHERE company_id = company_rec.company_id
            LIMIT 3
        LOOP
            -- 사용자 정보 변경 시뮬레이션
            PERFORM bms.log_data_change(
                'bms.users'::VARCHAR(100),
                user_rec.user_id,
                'UPDATE'::VARCHAR(20),
                ('{"full_name": "' || user_rec.name || '", "email": "old@example.com", "phone_number": "010-1111-1111"}')::JSONB,
                ('{"full_name": "' || user_rec.name || '", "email": "new@example.com", "phone_number": "010-2222-2222"}')::JSONB,
                user_rec.user_id,
                '연락처 정보 업데이트'::TEXT,
                'USER_PROFILE_UPDATE'::VARCHAR(100)
            );
            audit_count := audit_count + 1;
            
            -- 로그인 기록 시뮬레이션
            PERFORM bms.log_data_change(
                'bms.users'::VARCHAR(100),
                user_rec.user_id,
                'UPDATE'::VARCHAR(20),
                '{"last_login_at": null}'::JSONB,
                ('{"last_login_at": "' || NOW()::text || '"}')::JSONB,
                user_rec.user_id,
                '사용자 로그인'::TEXT,
                'USER_LOGIN'::VARCHAR(100)
            );
            audit_count := audit_count + 1;
        END LOOP;
        
        -- 3. 건물 정보 변경 시뮬레이션
        FOR building_rec IN 
            SELECT building_id, name
            FROM bms.buildings 
            WHERE company_id = company_rec.company_id
            LIMIT 2
        LOOP
            -- 건물 정보 수정
            PERFORM bms.log_data_change(
                'bms.buildings'::VARCHAR(100),
                building_rec.building_id,
                'UPDATE'::VARCHAR(20),
                ('{"name": "' || building_rec.name || '", "manager_name": "김관리"}')::JSONB,
                ('{"name": "' || building_rec.name || '", "manager_name": "박관리"}')::JSONB,
                (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                '건물 관리자 변경'::TEXT,
                'BUILDING_MANAGEMENT_UPDATE'::VARCHAR(100)
            );
            audit_count := audit_count + 1;
            
            -- 새 호실 추가 시뮬레이션
            PERFORM bms.log_data_change(
                'bms.units'::VARCHAR(100),
                gen_random_uuid(),
                'INSERT'::VARCHAR(20),
                NULL::JSONB,
                ('{"building_id": "' || building_rec.building_id || '", "unit_number": "999호", "area": 85.5, "unit_type": "APARTMENT"}')::JSONB,
                (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                '신규 호실 등록'::TEXT,
                'UNIT_REGISTRATION'::VARCHAR(100)
            );
            audit_count := audit_count + 1;
        END LOOP;
        
        -- 4. 시스템 설정 변경 시뮬레이션
        PERFORM bms.log_data_change(
            'bms.system_settings'::VARCHAR(100),
            gen_random_uuid(),
            'UPDATE'::VARCHAR(20),
            '{"setting_key": "BILLING_DAY", "setting_value": "1"}'::JSONB,
            '{"setting_key": "BILLING_DAY", "setting_value": "5"}'::JSONB,
            (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
            '청구일 변경'::TEXT,
            'SYSTEM_CONFIG_UPDATE'::VARCHAR(100)
        );
        audit_count := audit_count + 1;
        
        -- 5. 민감한 데이터 변경 시뮬레이션 (별도 테이블에 기록)
        INSERT INTO bms.sensitive_audit_logs (
            company_id, table_name, record_id, operation_type,
            encrypted_old_values, encrypted_new_values,
            user_id, user_name, access_level
        ) VALUES (
            company_rec.company_id, 'bms.tenants', gen_random_uuid(), 'UPDATE',
            '개인정보변경전데이터암호화됨'::bytea, '개인정보변경후데이터암호화됨'::bytea,
            (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
            (SELECT full_name FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
            3
        );
        
        RAISE NOTICE '회사 % 감사 로그 설정 및 샘플 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 6. 과거 날짜의 감사 로그 생성 (시간별 분석을 위해)
    RAISE NOTICE '과거 감사 로그 데이터 생성 시작';
    
    -- 지난 30일간의 감사 로그 시뮬레이션
    FOR i IN 1..30 LOOP
        -- 매일 몇 개의 변경 사항 시뮬레이션
        FOR j IN 1..(random() * 5 + 1)::integer LOOP
            INSERT INTO bms.audit_logs (
                company_id, table_name, record_id, operation_type,
                old_values, new_values, changed_fields,
                user_id, user_name, user_role,
                business_context, change_reason,
                operation_timestamp, approval_status
            ) VALUES (
                (SELECT company_id FROM bms.companies LIMIT 1),
                (ARRAY['bms.users', 'bms.buildings', 'bms.units', 'bms.tenants'])[ceil(random() * 4)],
                gen_random_uuid(),
                (ARRAY['INSERT', 'UPDATE', 'DELETE'])[ceil(random() * 3)],
                '{"field1": "old_value"}',
                '{"field1": "new_value"}',
                ARRAY['field1'],
                (SELECT user_id FROM bms.users LIMIT 1),
                (SELECT full_name FROM bms.users LIMIT 1),
                'ADMIN',
                'DAILY_OPERATION',
                '일상 업무 처리',
                NOW() - (i || ' days')::INTERVAL - (random() * 24 || ' hours')::INTERVAL,
                'AUTO_APPROVED'
            );
            audit_count := audit_count + 1;
        END LOOP;
    END LOOP;
    
    -- 통계 정보 출력
    RAISE NOTICE '=== 감사 로그 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 감사 설정 수: %', config_count;
    RAISE NOTICE '총 감사 로그 수: %', audit_count;
    
END $$;

-- 생성된 데이터 확인 쿼리
-- 1. 감사 설정 현황
SELECT 
    '감사 설정 현황' as category,
    c.company_name,
    alc.table_name,
    alc.audit_level,
    alc.is_audit_enabled,
    alc.require_approval,
    alc.retention_days
FROM bms.audit_log_config alc
JOIN bms.companies c ON alc.company_id = c.company_id
WHERE alc.is_active = true
ORDER BY c.company_name, alc.table_name;

-- 2. 감사 로그 통계
SELECT 
    '감사 로그 통계' as category,
    table_name,
    operation_type,
    COUNT(*) as log_count,
    COUNT(DISTINCT user_id) as unique_users,
    MIN(operation_timestamp) as earliest_log,
    MAX(operation_timestamp) as latest_log
FROM bms.audit_logs
GROUP BY table_name, operation_type
ORDER BY log_count DESC;

-- 3. 최근 감사 로그 샘플
SELECT 
    '최근 감사 로그' as category,
    table_name,
    operation_type,
    user_name,
    business_context,
    change_reason,
    operation_timestamp,
    approval_status
FROM bms.audit_logs
ORDER BY operation_timestamp DESC
LIMIT 10;

-- 4. 민감한 데이터 감사 로그 현황
SELECT 
    '민감 데이터 감사' as category,
    c.company_name,
    sal.table_name,
    sal.operation_type,
    sal.access_level,
    sal.user_name,
    sal.operation_timestamp
FROM bms.sensitive_audit_logs sal
JOIN bms.companies c ON sal.company_id = c.company_id
ORDER BY sal.operation_timestamp DESC;

-- 5. 감사 로그 함수 테스트
SELECT 
    '감사 통계 함수 테스트' as category,
    *
FROM bms.get_audit_statistics(
    (SELECT company_id FROM bms.companies LIMIT 1),
    (CURRENT_DATE - INTERVAL '7 days')::date,
    CURRENT_DATE::date
);

-- 완료 메시지
SELECT '✅ 감사 로그 시스템 테스트 데이터 생성이 완료되었습니다!' as result;