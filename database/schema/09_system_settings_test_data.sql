-- =====================================================
-- 시스템 설정 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    setting_count INTEGER := 0;
    history_count INTEGER := 0;
BEGIN
    -- 각 회사에 대해 시스템 설정 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 시스템 설정 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 1. 일반 설정 (GENERAL)
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required, is_system_setting,
            display_order, setting_group
        ) VALUES 
        (company_rec.company_id, NULL, 'GENERAL', 'COMPANY_NAME', '회사명', '회사의 공식 명칭',
         company_rec.company_name, 'STRING', '', true, true, 1, 'BASIC_INFO'),
        (company_rec.company_id, NULL, 'GENERAL', 'BUSINESS_HOURS', '영업시간', '회사의 기본 영업시간',
         '09:00-18:00', 'STRING', '09:00-18:00', true, false, 2, 'BASIC_INFO'),
        (company_rec.company_id, NULL, 'GENERAL', 'TIMEZONE', '시간대', '시스템에서 사용할 시간대',
         'Asia/Seoul', 'STRING', 'Asia/Seoul', true, true, 3, 'BASIC_INFO'),
        (company_rec.company_id, NULL, 'GENERAL', 'CURRENCY', '통화', '시스템에서 사용할 기본 통화',
         'KRW', 'STRING', 'KRW', true, true, 4, 'BASIC_INFO'),
        (company_rec.company_id, NULL, 'GENERAL', 'LANGUAGE', '언어', '시스템 기본 언어',
         'ko-KR', 'STRING', 'ko-KR', true, true, 5, 'BASIC_INFO');
        
        setting_count := setting_count + 5;
        
        -- 2. 청구 설정 (BILLING) - 첫 번째 설정 (allowed_values 포함)
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required, is_system_setting,
            display_order, setting_group, allowed_values
        ) VALUES 
        (company_rec.company_id, NULL, 'BILLING', 'BILLING_CYCLE', '청구 주기', '관리비 청구 주기',
         'MONTHLY', 'STRING', 'MONTHLY', true, false, 1, 'BILLING_BASIC', 
         ARRAY['MONTHLY', 'QUARTERLY', 'SEMI_ANNUAL', 'ANNUAL']);
        
        -- 나머지 청구 설정 (allowed_values 없음)
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required, is_system_setting,
            display_order, setting_group
        ) VALUES 
        (company_rec.company_id, NULL, 'BILLING', 'BILLING_DAY', '청구일', '매월 관리비 청구일',
         '1', 'INTEGER', '1', true, false, 2, 'BILLING_BASIC'),
        (company_rec.company_id, NULL, 'BILLING', 'DUE_DAYS', '납부 기한', '청구 후 납부 기한 (일)',
         '30', 'INTEGER', '30', true, false, 3, 'BILLING_BASIC'),
        (company_rec.company_id, NULL, 'BILLING', 'LATE_FEE_RATE', '연체료율', '연체 시 적용할 연체료율 (%)',
         '2.5', 'DECIMAL', '2.5', false, false, 4, 'BILLING_PENALTY'),
        (company_rec.company_id, NULL, 'BILLING', 'GRACE_PERIOD', '유예 기간', '연체료 적용 유예 기간 (일)',
         '5', 'INTEGER', '5', false, false, 5, 'BILLING_PENALTY');
        
        setting_count := setting_count + 1;
        setting_count := setting_count + 4;
        
        -- 3. 알림 설정 (NOTIFICATION)
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required,
            display_order, setting_group
        ) VALUES 
        (company_rec.company_id, NULL, 'NOTIFICATION', 'EMAIL_ENABLED', '이메일 알림 사용', '이메일 알림 기능 사용 여부',
         'true', 'BOOLEAN', 'true', false, 1, 'EMAIL_SETTINGS'),
        (company_rec.company_id, NULL, 'NOTIFICATION', 'SMS_ENABLED', 'SMS 알림 사용', 'SMS 알림 기능 사용 여부',
         'false', 'BOOLEAN', 'false', false, 2, 'SMS_SETTINGS'),
        (company_rec.company_id, NULL, 'NOTIFICATION', 'BILLING_REMINDER_DAYS', '청구 알림 일수', '청구 전 미리 알림 일수',
         '7', 'INTEGER', '7', false, 3, 'BILLING_NOTIFICATIONS'),
        (company_rec.company_id, NULL, 'NOTIFICATION', 'OVERDUE_REMINDER_DAYS', '연체 알림 일수', '연체 후 알림 주기 (일)',
         '3', 'INTEGER', '3', false, 4, 'BILLING_NOTIFICATIONS');
        
        setting_count := setting_count + 4;
        
        -- 4. 보안 설정 (SECURITY) - is_encrypted 포함
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required, is_system_setting,
            display_order, setting_group, is_encrypted
        ) VALUES 
        (company_rec.company_id, NULL, 'SECURITY', 'PASSWORD_MIN_LENGTH', '최소 비밀번호 길이', '사용자 비밀번호 최소 길이',
         '8', 'INTEGER', '8', true, true, 1, 'PASSWORD_POLICY', false),
        (company_rec.company_id, NULL, 'SECURITY', 'PASSWORD_REQUIRE_SPECIAL', '특수문자 필수', '비밀번호에 특수문자 포함 필수 여부',
         'true', 'BOOLEAN', 'true', true, true, 2, 'PASSWORD_POLICY', false),
        (company_rec.company_id, NULL, 'SECURITY', 'SESSION_TIMEOUT', '세션 타임아웃', '사용자 세션 타임아웃 (분)',
         '30', 'INTEGER', '30', true, true, 3, 'SESSION_MANAGEMENT', false),
        (company_rec.company_id, NULL, 'SECURITY', 'API_KEY', 'API 키', '외부 연동용 API 키',
         'sk_test_' || substr(md5(random()::text), 1, 24), 'PASSWORD', '', false, false, 4, 'API_SETTINGS', true);
        
        setting_count := setting_count + 4;
        
        -- 5. 연동 설정 (INTEGRATION)
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            json_value, setting_value_type, is_required, display_order, setting_group
        ) VALUES 
        (company_rec.company_id, NULL, 'INTEGRATION', 'EMAIL_CONFIG', '이메일 서버 설정', '이메일 발송을 위한 SMTP 설정',
         '{"host": "smtp.gmail.com", "port": 587, "secure": false, "auth": {"user": "noreply@company.com", "pass": ""}}',
         'JSON', false, 1, 'EMAIL_INTEGRATION'),
        (company_rec.company_id, NULL, 'INTEGRATION', 'SMS_CONFIG', 'SMS 서비스 설정', 'SMS 발송을 위한 서비스 설정',
         '{"provider": "KT", "api_key": "", "sender": "02-1234-5678"}',
         'JSON', false, 2, 'SMS_INTEGRATION'),
        (company_rec.company_id, NULL, 'INTEGRATION', 'PAYMENT_GATEWAY', '결제 게이트웨이 설정', '온라인 결제를 위한 PG사 설정',
         '{"provider": "KG이니시스", "merchant_id": "", "api_key": "", "test_mode": true}',
         'JSON', false, 3, 'PAYMENT_INTEGRATION');
        
        setting_count := setting_count + 3;
        
        -- 6. 보고서 설정 (REPORT) - allowed_values 포함
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required,
            display_order, setting_group, allowed_values
        ) VALUES 
        (company_rec.company_id, NULL, 'REPORT', 'REPORT_FORMAT', '기본 보고서 형식', '보고서 기본 출력 형식',
         'PDF', 'STRING', 'PDF', false, 3, 'REPORT_FORMAT', ARRAY['PDF', 'EXCEL', 'CSV']);
        
        -- 보고서 설정 (allowed_values 없음)
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required,
            display_order, setting_group
        ) VALUES 
        (company_rec.company_id, NULL, 'REPORT', 'REPORT_RETENTION_DAYS', '보고서 보관 기간', '생성된 보고서 파일 보관 기간 (일)',
         '90', 'INTEGER', '90', false, 1, 'REPORT_MANAGEMENT'),
        (company_rec.company_id, NULL, 'REPORT', 'AUTO_REPORT_ENABLED', '자동 보고서 생성', '정기 보고서 자동 생성 여부',
         'true', 'BOOLEAN', 'true', false, 2, 'REPORT_AUTOMATION');
        
        setting_count := setting_count + 1;
        setting_count := setting_count + 2;
        
        -- 7. UI 설정 (UI) - allowed_values 포함
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required,
            display_order, setting_group, allowed_values
        ) VALUES 
        (company_rec.company_id, NULL, 'UI', 'THEME', '테마', '시스템 기본 테마',
         'light', 'STRING', 'light', false, 1, 'APPEARANCE', ARRAY['light', 'dark', 'auto']),
        (company_rec.company_id, NULL, 'UI', 'DATE_FORMAT', '날짜 형식', '시스템에서 사용할 날짜 표시 형식',
         'YYYY-MM-DD', 'STRING', 'YYYY-MM-DD', false, 3, 'FORMAT', 
         ARRAY['YYYY-MM-DD', 'DD/MM/YYYY', 'MM/DD/YYYY', 'YYYY년 MM월 DD일']);
        
        -- UI 설정 (allowed_values 없음)
        INSERT INTO bms.system_settings (
            company_id, building_id, setting_category, setting_key, setting_name, setting_description,
            setting_value, setting_value_type, default_value, is_required,
            display_order, setting_group
        ) VALUES 
        (company_rec.company_id, NULL, 'UI', 'ITEMS_PER_PAGE', '페이지당 항목 수', '목록 화면에서 페이지당 표시할 항목 수',
         '20', 'INTEGER', '20', false, 2, 'PAGINATION');
        
        setting_count := setting_count + 2;
        setting_count := setting_count + 1;
        
        -- 각 건물별 개별 설정 생성
        FOR building_rec IN 
            SELECT building_id, name as building_name
            FROM bms.buildings 
            WHERE company_id = company_rec.company_id
            LIMIT 2  -- 각 회사당 2개 건물만
        LOOP
            RAISE NOTICE '  건물 % (%) 개별 설정 생성', building_rec.building_name, building_rec.building_id;
            
            -- 건물별 개별 설정
            INSERT INTO bms.system_settings (
                company_id, building_id, setting_category, setting_key, setting_name, setting_description,
                setting_value, setting_value_type, default_value, is_required,
                display_order, setting_group
            ) VALUES 
            (company_rec.company_id, building_rec.building_id, 'GENERAL', 'BUILDING_MANAGER_NAME', '건물 관리자명', '해당 건물의 관리자 이름',
             '김관리', 'STRING', '', false, 1, 'BUILDING_INFO'),
            (company_rec.company_id, building_rec.building_id, 'GENERAL', 'BUILDING_MANAGER_PHONE', '관리자 연락처', '건물 관리자 연락처',
             '010-1234-5678', 'STRING', '', false, 2, 'BUILDING_INFO'),
            (company_rec.company_id, building_rec.building_id, 'BILLING', 'COMMON_AREA_RATIO', '공용면적 비율', '공용면적 관리비 배분 비율 (%)',
             '15.0', 'DECIMAL', '15.0', false, 1, 'BUILDING_BILLING'),
            (company_rec.company_id, building_rec.building_id, 'NOTIFICATION', 'EMERGENCY_CONTACT', '비상 연락처', '건물 비상시 연락처',
             '119', 'STRING', '119', false, 1, 'EMERGENCY_SETTINGS');
            
            setting_count := setting_count + 4;
        END LOOP;
        
        RAISE NOTICE '회사 % 시스템 설정 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 시스템 설정 변경 이력 시뮬레이션 (일부 설정에 대해)
    RAISE NOTICE '시스템 설정 변경 이력 시뮬레이션 시작';
    
    -- 일부 설정값 변경하여 이력 생성
    UPDATE bms.system_settings 
    SET setting_value = '10', 
        updated_by = (SELECT user_id FROM bms.users LIMIT 1),
        updated_at = NOW() - INTERVAL '7 days'
    WHERE setting_key = 'DUE_DAYS' 
      AND setting_value = '30'
      AND company_id IN (SELECT company_id FROM bms.companies LIMIT 1);
    
    UPDATE bms.system_settings 
    SET setting_value = '25', 
        updated_by = (SELECT user_id FROM bms.users LIMIT 1),
        updated_at = NOW() - INTERVAL '5 days'
    WHERE setting_key = 'DUE_DAYS' 
      AND setting_value = '10'
      AND company_id IN (SELECT company_id FROM bms.companies LIMIT 1);
    
    UPDATE bms.system_settings 
    SET setting_value = '30', 
        updated_by = (SELECT user_id FROM bms.users LIMIT 1),
        updated_at = NOW() - INTERVAL '2 days'
    WHERE setting_key = 'DUE_DAYS' 
      AND setting_value = '25'
      AND company_id IN (SELECT company_id FROM bms.companies LIMIT 1);
    
    -- 일부 설정 비활성화 후 재활성화
    UPDATE bms.system_settings 
    SET is_active = false,
        updated_by = (SELECT user_id FROM bms.users LIMIT 1),
        updated_at = NOW() - INTERVAL '3 days'
    WHERE setting_key = 'SMS_ENABLED'
      AND company_id IN (SELECT company_id FROM bms.companies LIMIT 1);
    
    UPDATE bms.system_settings 
    SET is_active = true,
        updated_by = (SELECT user_id FROM bms.users LIMIT 1),
        updated_at = NOW() - INTERVAL '1 day'
    WHERE setting_key = 'SMS_ENABLED'
      AND company_id IN (SELECT company_id FROM bms.companies LIMIT 1);
    
    -- 통계 정보 출력
    SELECT COUNT(*) INTO setting_count FROM bms.system_settings;
    SELECT COUNT(*) INTO history_count FROM bms.system_setting_history;
    
    RAISE NOTICE '=== 시스템 설정 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 시스템 설정 수: %', setting_count;
    RAISE NOTICE '총 변경 이력 수: %', history_count;
    
END $$;

-- 생성된 데이터 확인 쿼리
WITH setting_stats AS (
    SELECT 
        '시스템 설정 통계' as category,
        setting_category,
        COUNT(*) as count
    FROM bms.system_settings 
    WHERE is_active = true
    GROUP BY setting_category
    
    UNION ALL
    
    SELECT 
        '건물별 설정 통계' as category,
        CASE WHEN building_id IS NULL THEN '회사 공통' ELSE '건물별' END as setting_category,
        COUNT(*) as count
    FROM bms.system_settings 
    WHERE is_active = true
    GROUP BY CASE WHEN building_id IS NULL THEN '회사 공통' ELSE '건물별' END
    
    UNION ALL
    
    SELECT 
        '변경 이력 통계' as category,
        change_type as setting_category,
        COUNT(*) as count
    FROM bms.system_setting_history
    GROUP BY change_type
)
SELECT * FROM setting_stats ORDER BY category, setting_category;

-- 시스템 설정 샘플 조회
SELECT 
    c.company_name,
    COALESCE(b.name, '전체') as building_name,
    s.setting_category,
    s.setting_key,
    s.setting_name,
    s.setting_value,
    s.setting_value_type,
    s.is_required,
    s.is_system_setting
FROM bms.system_settings s
JOIN bms.companies c ON s.company_id = c.company_id
LEFT JOIN bms.buildings b ON s.building_id = b.building_id
WHERE s.is_active = true
ORDER BY c.company_name, b.name NULLS FIRST, s.setting_category, s.display_order
LIMIT 20;

-- 완료 메시지
SELECT '✅ 시스템 설정 테스트 데이터 생성이 완료되었습니다!' as result;