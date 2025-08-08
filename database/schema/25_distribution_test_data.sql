-- =====================================================
-- 고지서 배포 관리 시스템 테스트 데이터 생성 스크립트 (알림톡 포함)
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    unit_rec RECORD;
    channel_count INTEGER := 0;
    group_count INTEGER := 0;
    contact_count INTEGER := 0;
    queue_count INTEGER := 0;
    log_count INTEGER := 0;
    
    -- 채널 ID 저장용 변수들
    v_email_channel_id UUID;
    v_sms_channel_id UUID;
    v_kakao_channel_id UUID;
    v_portal_channel_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- 각 회사에 대해 배포 관리 시스템 데이터 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 배포 관리 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 관리자 사용자 ID 조회
        SELECT user_id INTO v_admin_user_id 
        FROM bms.users 
        WHERE company_id = company_rec.company_id 
        LIMIT 1;
        
        -- 1. 배포 채널 생성
        -- 이메일 채널
        v_email_channel_id := gen_random_uuid();
        INSERT INTO bms.distribution_channels (
            channel_id, company_id, building_id,
            channel_name, channel_type, channel_description,
            provider_name, api_endpoint, api_credentials,
            max_retry_count, retry_interval_minutes, timeout_seconds,
            max_file_size_mb, supported_formats, max_recipients_per_batch,
            cost_per_message, cost_currency, billing_unit,
            is_active, daily_limit, monthly_limit,
            total_sent, total_delivered, total_failed,
            created_by
        ) VALUES (
            v_email_channel_id, company_rec.company_id, NULL,
            '이메일 배포 채널', 'EMAIL', '고지서 이메일 자동 배포',
            'AWS SES', 'https://email.ap-northeast-2.amazonaws.com',
            jsonb_build_object(
                'access_key_id', 'AKIA***',
                'secret_access_key', '***',
                'region', 'ap-northeast-2'
            ),
            3, 30, 30,
            25, ARRAY['PDF', 'HTML'], 100,
            50.0, 'KRW', 'MESSAGE',
            true, 1000, 30000,
            (random() * 5000)::integer, (random() * 4500)::integer, (random() * 500)::integer,
            v_admin_user_id
        );
        
        -- SMS 채널
        v_sms_channel_id := gen_random_uuid();
        INSERT INTO bms.distribution_channels (
            channel_id, company_id, building_id,
            channel_name, channel_type, channel_description,
            provider_name, api_endpoint, api_credentials,
            max_retry_count, retry_interval_minutes, timeout_seconds,
            max_file_size_mb, supported_formats, max_recipients_per_batch,
            cost_per_message, cost_currency, billing_unit,
            is_active, daily_limit, monthly_limit,
            total_sent, total_delivered, total_failed,
            created_by
        ) VALUES (
            v_sms_channel_id, company_rec.company_id, NULL,
            'SMS 알림 채널', 'SMS', '고지서 발행 SMS 알림',
            'NHN Toast', 'https://api-sms.cloud.toast.com',
            jsonb_build_object(
                'app_key', 'APP_KEY_***',
                'secret_key', 'SECRET_***',
                'sender_number', '02-1234-5678'
            ),
            3, 15, 30,
            1, ARRAY['TEXT'], 500,
            20.0, 'KRW', 'MESSAGE',
            true, 2000, 50000,
            (random() * 3000)::integer, (random() * 2800)::integer, (random() * 200)::integer,
            v_admin_user_id
        );
        
        -- 카카오톡 알림톡 채널
        v_kakao_channel_id := gen_random_uuid();
        INSERT INTO bms.distribution_channels (
            channel_id, company_id, building_id,
            channel_name, channel_type, channel_description,
            provider_name, api_endpoint, api_credentials,
            max_retry_count, retry_interval_minutes, timeout_seconds,
            max_file_size_mb, supported_formats, max_recipients_per_batch,
            cost_per_message, cost_currency, billing_unit,
            template_code, template_content, template_variables,
            is_active, daily_limit, monthly_limit,
            total_sent, total_delivered, total_failed,
            created_by
        ) VALUES (
            v_kakao_channel_id, company_rec.company_id, NULL,
            '카카오톡 알림톡 채널', 'KAKAO_TALK', '고지서 발행 카카오톡 알림',
            'Kakao Business', 'https://kapi.kakao.com/v2/api/talk/memo/default/send',
            jsonb_build_object(
                'app_key', 'KAKAO_APP_KEY_***',
                'admin_key', 'KAKAO_ADMIN_KEY_***',
                'sender_key', 'SENDER_KEY_***'
            ),
            3, 10, 30,
            5, ARRAY['TEXT', 'IMAGE'], 200,
            15.0, 'KRW', 'MESSAGE',
            'BILL_NOTICE_001', 
            '[#{company_name}] #{bill_period} 관리비 고지서가 발행되었습니다.\n\n총 관리비: #{total_amount}원\n납부기한: #{due_date}\n\n자세한 내용은 첨부된 고지서를 확인해주세요.',
            jsonb_build_object(
                'company_name', 'string',
                'bill_period', 'string', 
                'total_amount', 'number',
                'due_date', 'date'
            ),
            true, 1500, 40000,
            (random() * 4000)::integer, (random() * 3800)::integer, (random() * 200)::integer,
            v_admin_user_id
        );
        
        -- 웹 포털 채널
        v_portal_channel_id := gen_random_uuid();
        INSERT INTO bms.distribution_channels (
            channel_id, company_id, building_id,
            channel_name, channel_type, channel_description,
            provider_name, api_endpoint,
            max_retry_count, retry_interval_minutes, timeout_seconds,
            max_file_size_mb, supported_formats, max_recipients_per_batch,
            cost_per_message, cost_currency, billing_unit,
            is_active, daily_limit, monthly_limit,
            total_sent, total_delivered, total_failed,
            created_by
        ) VALUES (
            v_portal_channel_id, company_rec.company_id, NULL,
            '웹 포털 게시', 'PORTAL', '웹 포털 고지서 게시',
            'Internal Portal', 'https://portal.' || company_rec.company_name || '.com/api',
            1, 5, 60,
            50, ARRAY['PDF', 'HTML'], 1000,
            0.0, 'KRW', 'MESSAGE',
            true, NULL, NULL,
            (random() * 2000)::integer, (random() * 1950)::integer, (random() * 50)::integer,
            v_admin_user_id
        );
        
        channel_count := channel_count + 4;
        
        -- 2. 수신자 그룹 생성
        INSERT INTO bms.recipient_groups (
            company_id, building_id, group_name, group_description, group_type,
            selection_criteria, dynamic_group,
            default_channel_types, contact_preferences,
            member_count, active_member_count,
            created_by
        ) VALUES 
        (company_rec.company_id, NULL, '전체 입주자', '회사 전체 입주자 그룹', 'ALL_RESIDENTS',
         jsonb_build_object('unit_status', 'OCCUPIED', 'contact_active', true),
         true,
         ARRAY['EMAIL', 'KAKAO_TALK'], 
         jsonb_build_object('primary_channel', 'EMAIL', 'fallback_channel', 'SMS'),
         (SELECT COUNT(*) FROM bms.units WHERE company_id = company_rec.company_id AND unit_status = 'OCCUPIED'),
         (SELECT COUNT(*) FROM bms.units WHERE company_id = company_rec.company_id AND unit_status = 'OCCUPIED'),
         v_admin_user_id),
        
        (company_rec.company_id, NULL, '소유자 그룹', '호실 소유자만 포함하는 그룹', 'UNIT_OWNERS',
         jsonb_build_object('contact_type', 'OWNER', 'is_active', true),
         true,
         ARRAY['EMAIL', 'PORTAL'],
         jsonb_build_object('primary_channel', 'EMAIL', 'secondary_channel', 'PORTAL'),
         (SELECT COUNT(*) FROM bms.units WHERE company_id = company_rec.company_id AND unit_status = 'OCCUPIED') / 2,
         (SELECT COUNT(*) FROM bms.units WHERE company_id = company_rec.company_id AND unit_status = 'OCCUPIED') / 2,
         v_admin_user_id);
        
        group_count := group_count + 2;
        
        -- 3. 수신자 연락처 생성
        FOR unit_rec IN 
            SELECT unit_id, unit_number
            FROM bms.units
            WHERE company_id = company_rec.company_id
              AND unit_status = 'OCCUPIED'
            LIMIT 10  -- 각 회사당 10개 호실만
        LOOP
            -- 주 연락처 (소유자)
            INSERT INTO bms.recipient_contacts (
                company_id, unit_id, contact_name, contact_type, contact_role,
                email_address, phone_number, mobile_number, kakao_id,
                email_enabled, sms_enabled, kakao_talk_enabled, push_enabled,
                preferred_time_start, preferred_time_end, preferred_language,
                email_verified, phone_verified, kakao_verified,
                is_active, is_primary
            ) VALUES (
                company_rec.company_id, unit_rec.unit_id,
                '입주자' || unit_rec.unit_number, 'OWNER', 'PRIMARY',
                'resident' || unit_rec.unit_number || '@example.com',
                '02-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0') || '-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0'),
                '010-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0') || '-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0'),
                'kakao_' || unit_rec.unit_number,
                true, true, true, true,
                '09:00', '21:00', 'ko',
                random() < 0.8, random() < 0.9, random() < 0.7,  -- 검증 확률
                true, true
            );
            
            contact_count := contact_count + 1;
            
            -- 보조 연락처 (30% 확률)
            IF random() < 0.3 THEN
                INSERT INTO bms.recipient_contacts (
                    company_id, unit_id, contact_name, contact_type, contact_role,
                    email_address, mobile_number,
                    email_enabled, sms_enabled, kakao_talk_enabled,
                    preferred_language, is_active, is_primary
                ) VALUES (
                    company_rec.company_id, unit_rec.unit_id,
                    '가족' || unit_rec.unit_number, 'OTHER', 'SECONDARY',
                    'family' || unit_rec.unit_number || '@example.com',
                    '010-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0') || '-' || LPAD((1000 + random() * 8999)::integer::text, 4, '0'),
                    true, true, false,
                    'ko', true, false
                );
                
                contact_count := contact_count + 1;
            END IF;
        END LOOP;
        
        -- 4. 배포 큐 생성 (시뮬레이션)
        FOR i IN 1..20 LOOP
            DECLARE
                v_channel_id UUID;
                v_contact_id UUID;
                v_queue_status VARCHAR(20);
                v_processing_status VARCHAR(20);
            BEGIN
                -- 랜덤 채널 선택
                v_channel_id := CASE (random() * 4)::integer
                    WHEN 0 THEN v_email_channel_id
                    WHEN 1 THEN v_sms_channel_id
                    WHEN 2 THEN v_kakao_channel_id
                    ELSE v_portal_channel_id
                END;
                
                -- 랜덤 연락처 선택
                SELECT contact_id INTO v_contact_id
                FROM bms.recipient_contacts
                WHERE company_id = company_rec.company_id
                ORDER BY random()
                LIMIT 1;
                
                -- 상태 설정
                CASE (random() * 5)::integer
                    WHEN 0 THEN 
                        v_queue_status := 'PENDING';
                        v_processing_status := 'WAITING';
                    WHEN 1 THEN 
                        v_queue_status := 'PROCESSING';
                        v_processing_status := 'SENDING';
                    WHEN 2 THEN 
                        v_queue_status := 'COMPLETED';
                        v_processing_status := 'DELIVERED';
                    WHEN 3 THEN 
                        v_queue_status := 'FAILED';
                        v_processing_status := 'FAILED';
                    ELSE 
                        v_queue_status := 'COMPLETED';
                        v_processing_status := 'SENT';
                END CASE;
                
                INSERT INTO bms.distribution_queue (
                    company_id, issuance_id, channel_id, recipient_contact_id,
                    priority_level, scheduled_at,
                    message_subject, message_content, message_variables,
                    attachment_file_path, attachment_file_name, attachment_file_size,
                    queue_status, processing_status,
                    attempt_count, max_attempts, last_attempt_at, next_attempt_at,
                    delivery_result, response_code, response_message,
                    estimated_cost, actual_cost
                ) VALUES (
                    company_rec.company_id,
                    (SELECT issuance_id FROM bms.bill_issuances WHERE company_id = company_rec.company_id ORDER BY random() LIMIT 1),
                    v_channel_id, v_contact_id,
                    (1 + random() * 5)::integer,  -- 우선순위 1-5
                    NOW() - (random() * 24 || ' hours')::INTERVAL,
                    CASE 
                        WHEN v_channel_id = v_kakao_channel_id THEN NULL  -- 알림톡은 제목 없음
                        ELSE '[' || company_rec.company_name || '] 관리비 고지서 발행 안내'
                    END,
                    CASE 
                        WHEN v_channel_id = v_kakao_channel_id THEN 
                            '[' || company_rec.company_name || '] 2025년 8월 관리비 고지서가 발행되었습니다.\n\n총 관리비: ' || (100000 + random() * 200000)::integer || '원\n납부기한: 2025-09-15\n\n자세한 내용은 첨부된 고지서를 확인해주세요.'
                        WHEN v_channel_id = v_sms_channel_id THEN
                            '[' || company_rec.company_name || '] 관리비 고지서가 발행되었습니다. 포털에서 확인하세요.'
                        ELSE
                            '안녕하세요. ' || company_rec.company_name || '입니다.\n\n2025년 8월 관리비 고지서를 첨부파일로 발송드립니다.\n납부기한까지 납부해주시기 바랍니다.'
                    END,
                    jsonb_build_object(
                        'company_name', company_rec.company_name,
                        'bill_period', '2025년 8월',
                        'total_amount', (100000 + random() * 200000)::integer,
                        'due_date', '2025-09-15'
                    ),
                    CASE WHEN v_channel_id IN (v_email_channel_id, v_portal_channel_id) THEN
                        '/bills/' || company_rec.company_id || '/2025-08/bill_' || i || '.pdf'
                    ELSE NULL END,
                    CASE WHEN v_channel_id IN (v_email_channel_id, v_portal_channel_id) THEN
                        'bill_' || i || '.pdf'
                    ELSE NULL END,
                    CASE WHEN v_channel_id IN (v_email_channel_id, v_portal_channel_id) THEN
                        (400000 + random() * 200000)::bigint
                    ELSE NULL END,
                    v_queue_status, v_processing_status,
                    CASE WHEN v_queue_status = 'FAILED' THEN (1 + random() * 2)::integer ELSE 0 END,
                    3,
                    CASE WHEN v_queue_status != 'PENDING' THEN NOW() - (random() * 12 || ' hours')::INTERVAL ELSE NULL END,
                    CASE WHEN v_queue_status = 'FAILED' THEN NOW() + (random() * 2 || ' hours')::INTERVAL ELSE NULL END,
                    CASE 
                        WHEN v_queue_status = 'COMPLETED' THEN 'SUCCESS'
                        WHEN v_queue_status = 'FAILED' THEN 'FAILED'
                        ELSE NULL
                    END,
                    CASE 
                        WHEN v_queue_status = 'COMPLETED' THEN '200'
                        WHEN v_queue_status = 'FAILED' THEN '500'
                        ELSE NULL
                    END,
                    CASE 
                        WHEN v_queue_status = 'COMPLETED' THEN 'Message delivered successfully'
                        WHEN v_queue_status = 'FAILED' THEN 'Delivery failed: Invalid recipient'
                        ELSE NULL
                    END,
                    CASE 
                        WHEN v_channel_id = v_email_channel_id THEN 50.0
                        WHEN v_channel_id = v_sms_channel_id THEN 20.0
                        WHEN v_channel_id = v_kakao_channel_id THEN 15.0
                        ELSE 0.0
                    END,
                    CASE 
                        WHEN v_queue_status = 'COMPLETED' THEN
                            CASE 
                                WHEN v_channel_id = v_email_channel_id THEN 50.0
                                WHEN v_channel_id = v_sms_channel_id THEN 20.0
                                WHEN v_channel_id = v_kakao_channel_id THEN 15.0
                                ELSE 0.0
                            END
                        ELSE 0.0
                    END
                );
                
                queue_count := queue_count + 1;
            END;
        END LOOP;
        
        -- 5. 배포 로그 생성
        FOR i IN 1..30 LOOP
            INSERT INTO bms.distribution_logs (
                company_id, queue_id, log_level, log_category, log_message,
                channel_type, recipient_info, processing_context,
                processing_time_ms, memory_usage_mb,
                error_code, error_details
            ) VALUES (
                company_rec.company_id,
                (SELECT queue_id FROM bms.distribution_queue WHERE company_id = company_rec.company_id ORDER BY random() LIMIT 1),
                CASE (random() * 5)::integer
                    WHEN 0 THEN 'DEBUG'
                    WHEN 1 THEN 'INFO'
                    WHEN 2 THEN 'WARN'
                    WHEN 3 THEN 'ERROR'
                    ELSE 'INFO'
                END,
                CASE (random() * 4)::integer
                    WHEN 0 THEN 'DELIVERY'
                    WHEN 1 THEN 'CHANNEL'
                    WHEN 2 THEN 'QUEUE'
                    ELSE 'SYSTEM'
                END,
                CASE (random() * 4)::integer
                    WHEN 0 THEN '메시지 전송 완료'
                    WHEN 1 THEN '채널 연결 성공'
                    WHEN 2 THEN '큐 처리 시작'
                    ELSE '시스템 정상 작동'
                END,
                CASE (random() * 4)::integer
                    WHEN 0 THEN 'EMAIL'
                    WHEN 1 THEN 'SMS'
                    WHEN 2 THEN 'KAKAO_TALK'
                    ELSE 'PORTAL'
                END,
                jsonb_build_object(
                    'recipient_count', (1 + random() * 10)::integer,
                    'message_type', 'bill_notification'
                ),
                jsonb_build_object(
                    'batch_id', gen_random_uuid(),
                    'retry_count', (random() * 3)::integer
                ),
                (100 + random() * 5000)::integer,  -- 100ms ~ 5초
                (10 + random() * 50)::numeric(10,2),  -- 10MB ~ 60MB
                CASE WHEN random() < 0.1 THEN 'TIMEOUT_ERROR' ELSE NULL END,
                CASE WHEN random() < 0.1 THEN 
                    jsonb_build_object('error_type', 'timeout', 'duration_ms', 30000)
                ELSE NULL END
            );
            
            log_count := log_count + 1;
        END LOOP;
        
        RAISE NOTICE '회사 % 배포 관리 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 배포 관리 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 배포 채널: %개', channel_count;
    RAISE NOTICE '생성된 수신자 그룹: %개', group_count;
    RAISE NOTICE '생성된 연락처: %개', contact_count;
    RAISE NOTICE '생성된 배포 큐: %개', queue_count;
    RAISE NOTICE '생성된 로그: %개', log_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 고지서 배포 관리 시스템 (알림톡 포함) 테스트 데이터 생성이 완료되었습니다!' as result;