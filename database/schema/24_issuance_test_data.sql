-- =====================================================
-- 고지서 발행 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    calculation_rec RECORD;
    template_rec RECORD;
    batch_count INTEGER := 0;
    issuance_count INTEGER := 0;
    delivery_count INTEGER := 0;
    schedule_count INTEGER := 0;
    
    -- 배치 ID 저장용 변수들
    v_batch_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- 각 회사에 대해 고지서 발행 시스템 데이터 생성
    FOR company_rec IN 
        SELECT DISTINCT c.company_id, c.company_name
        FROM bms.companies c
        JOIN bms.monthly_fee_calculations mfc ON c.company_id = mfc.company_id
        WHERE mfc.calculation_status IN ('APPROVED', 'FINALIZED')
        LIMIT 3  -- 승인된 관리비 계산이 있는 3개 회사만
    LOOP
        RAISE NOTICE '회사 % (%) 고지서 발행 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 관리자 사용자 ID 조회
        SELECT user_id INTO v_admin_user_id 
        FROM bms.users 
        WHERE company_id = company_rec.company_id 
        LIMIT 1;
        
        -- 1. 고지서 발행 스케줄 생성
        FOR template_rec IN 
            SELECT template_id, template_name
            FROM bms.bill_templates
            WHERE company_id = company_rec.company_id
              AND is_active = true
            LIMIT 2  -- 각 회사당 2개 템플릿만
        LOOP
            INSERT INTO bms.bill_issuance_schedules (
                company_id, building_id, schedule_name, schedule_description,
                schedule_type, cron_expression, timezone,
                template_id, output_format, auto_approval, auto_delivery,
                target_unit_types, delivery_methods, delivery_delay_hours,
                notification_enabled, notification_recipients, notification_events,
                is_active, next_execution_at, execution_count,
                created_by
            ) VALUES (
                company_rec.company_id, NULL, 
                '월별 관리비 고지서 자동 발행 (' || template_rec.template_name || ')',
                '매월 25일 관리비 고지서 자동 발행 스케줄',
                'MONTHLY', '0 0 25 * *', 'Asia/Seoul',
                template_rec.template_id, 'PDF', true, true,
                ARRAY['OFFICE', 'RESIDENTIAL'], 
                ARRAY['EMAIL', 'PORTAL'], 2,
                true, ARRAY['admin@' || company_rec.company_name || '.com'],
                ARRAY['batch_completed', 'delivery_failed'],
                true, DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' + INTERVAL '24 days',
                (random() * 12)::integer,  -- 0~12회 실행 이력
                v_admin_user_id
            );
            
            schedule_count := schedule_count + 1;
        END LOOP;
        
        -- 2. 고지서 발행 배치 생성 (최근 3개월)
        FOR i IN 0..2 LOOP
            DECLARE
                v_target_period DATE := DATE_TRUNC('month', CURRENT_DATE) - (i || ' months')::INTERVAL;
                v_template_id UUID;
                v_unit_count INTEGER;
            BEGIN
                -- 템플릿 선택
                SELECT template_id INTO v_template_id
                FROM bms.bill_templates
                WHERE company_id = company_rec.company_id
                  AND is_active = true
                LIMIT 1;
                
                -- 대상 호실 수 계산
                SELECT COUNT(DISTINCT umf.unit_id) INTO v_unit_count
                FROM bms.unit_monthly_fees umf
                JOIN bms.monthly_fee_calculations mfc ON umf.calculation_id = mfc.calculation_id
                WHERE mfc.company_id = company_rec.company_id
                  AND mfc.calculation_period = v_target_period
                  AND mfc.calculation_status IN ('APPROVED', 'FINALIZED');
                
                IF v_unit_count > 0 THEN
                    -- 발행 배치 생성
                    v_batch_id := gen_random_uuid();
                    
                    INSERT INTO bms.bill_issuance_batches (
                        batch_id, company_id, building_id,
                        batch_name, batch_description, batch_type,
                        target_period, target_unit_count, target_unit_types,
                        template_id, output_format,
                        batch_status, processing_status,
                        total_bills, successful_bills, failed_bills,
                        scheduled_at, started_at, completed_at, processing_duration_ms,
                        output_directory, total_file_size,
                        approval_required, approved_by, approved_at,
                        created_by
                    ) VALUES (
                        v_batch_id, company_rec.company_id, NULL,
                        DATE_PART('year', v_target_period) || '년 ' || DATE_PART('month', v_target_period) || '월 관리비 고지서',
                        v_target_period || ' 관리비 고지서 일괄 발행',
                        CASE WHEN i = 0 THEN 'REGULAR' WHEN random() < 0.1 THEN 'CORRECTION' ELSE 'REGULAR' END,
                        v_target_period, v_unit_count, ARRAY['OFFICE', 'RESIDENTIAL'],
                        v_template_id, 'PDF',
                        CASE WHEN i <= 1 THEN 'APPROVED' ELSE 'READY' END,
                        CASE WHEN i <= 1 THEN 'COMPLETED' ELSE 'PENDING' END,
                        v_unit_count, 
                        CASE WHEN i <= 1 THEN v_unit_count - (random() * 2)::integer ELSE 0 END,
                        CASE WHEN i <= 1 THEN (random() * 2)::integer ELSE 0 END,
                        v_target_period + INTERVAL '25 days',
                        CASE WHEN i <= 1 THEN v_target_period + INTERVAL '25 days' + INTERVAL '1 hour' ELSE NULL END,
                        CASE WHEN i <= 1 THEN v_target_period + INTERVAL '25 days' + INTERVAL '2 hours' ELSE NULL END,
                        CASE WHEN i <= 1 THEN (3600000 + random() * 1800000)::integer ELSE NULL END,  -- 1~2.5시간
                        '/bills/' || company_rec.company_id || '/' || TO_CHAR(v_target_period, 'YYYY-MM'),
                        CASE WHEN i <= 1 THEN (v_unit_count * 500000 + random() * v_unit_count * 200000)::bigint ELSE 0 END,
                        true, v_admin_user_id, 
                        CASE WHEN i <= 1 THEN v_target_period + INTERVAL '24 days' ELSE NULL END,
                        v_admin_user_id
                    );
                    
                    batch_count := batch_count + 1;
                    
                    -- 3. 개별 고지서 발행 생성 (완료된 배치만)
                    IF i <= 1 THEN
                        FOR calculation_rec IN 
                            SELECT mfc.calculation_id, umf.unit_id, umf.total_amount, u.unit_number
                            FROM bms.monthly_fee_calculations mfc
                            JOIN bms.unit_monthly_fees umf ON mfc.calculation_id = umf.calculation_id
                            JOIN bms.units u ON umf.unit_id = u.unit_id
                            WHERE mfc.company_id = company_rec.company_id
                              AND mfc.calculation_period = v_target_period
                              AND mfc.calculation_status IN ('APPROVED', 'FINALIZED')
                            LIMIT 5  -- 각 배치당 5개 고지서만
                        LOOP
                            DECLARE
                                v_issuance_id UUID := gen_random_uuid();
                                v_bill_number VARCHAR(50);
                                v_due_date DATE := v_target_period + INTERVAL '1 month' + INTERVAL '15 days';
                                v_generation_success BOOLEAN := random() < 0.95;  -- 95% 성공률
                            BEGIN
                                -- 고지서 번호 생성
                                v_bill_number := TO_CHAR(v_target_period, 'YYYYMM') || '-' || 
                                               LPAD(calculation_rec.unit_number, 4, '0') || '-' ||
                                               LPAD((random() * 9999)::integer::text, 4, '0');
                                
                                -- 개별 고지서 발행 생성
                                INSERT INTO bms.bill_issuances (
                                    issuance_id, batch_id, company_id, calculation_id, unit_id,
                                    bill_number, bill_title, bill_period, issue_date, due_date,
                                    total_amount, previous_balance, late_fee, discount_amount, final_amount,
                                    issuance_status, generation_status,
                                    file_path, file_name, file_size, file_hash,
                                    template_id, output_format, generation_data,
                                    generation_start_time, generation_end_time, generation_duration_ms,
                                    error_code, error_message, retry_count,
                                    delivery_method, delivery_status, delivered_at,
                                    is_viewed, viewed_at, view_count
                                ) VALUES (
                                    v_issuance_id, v_batch_id, company_rec.company_id, 
                                    calculation_rec.calculation_id, calculation_rec.unit_id,
                                    v_bill_number, 
                                    DATE_PART('year', v_target_period) || '년 ' || DATE_PART('month', v_target_period) || '월 관리비 고지서',
                                    v_target_period, v_target_period + INTERVAL '25 days', v_due_date,
                                    calculation_rec.total_amount, 
                                    CASE WHEN random() < 0.1 THEN random() * 50000 ELSE 0 END,  -- 10% 확률로 전월 미납액
                                    CASE WHEN random() < 0.05 THEN random() * 10000 ELSE 0 END,  -- 5% 확률로 연체료
                                    CASE WHEN random() < 0.15 THEN random() * 20000 ELSE 0 END,  -- 15% 확률로 할인
                                    calculation_rec.total_amount,  -- 간단화를 위해 총액과 동일
                                    CASE WHEN v_generation_success THEN 'DELIVERED' ELSE 'GENERATED' END,
                                    CASE WHEN v_generation_success THEN 'COMPLETED' ELSE 'FAILED' END,
                                    CASE WHEN v_generation_success THEN 
                                        '/bills/' || company_rec.company_id || '/' || TO_CHAR(v_target_period, 'YYYY-MM') || '/' || v_bill_number || '.pdf'
                                    ELSE NULL END,
                                    CASE WHEN v_generation_success THEN v_bill_number || '.pdf' ELSE NULL END,
                                    CASE WHEN v_generation_success THEN (400000 + random() * 200000)::bigint ELSE NULL END,
                                    CASE WHEN v_generation_success THEN md5(v_bill_number || NOW()::text) ELSE NULL END,
                                    v_template_id, 'PDF',
                                    jsonb_build_object(
                                        'unit_number', calculation_rec.unit_number,
                                        'total_amount', calculation_rec.total_amount,
                                        'generation_timestamp', NOW()
                                    ),
                                    v_target_period + INTERVAL '25 days' + INTERVAL '1 hour' + (random() * 3600 || ' seconds')::INTERVAL,
                                    CASE WHEN v_generation_success THEN 
                                        v_target_period + INTERVAL '25 days' + INTERVAL '1 hour' + (random() * 3600 || ' seconds')::INTERVAL + (random() * 30 || ' seconds')::INTERVAL
                                    ELSE NULL END,
                                    CASE WHEN v_generation_success THEN (5000 + random() * 25000)::integer ELSE NULL END,
                                    CASE WHEN NOT v_generation_success THEN 'TEMPLATE_ERROR' ELSE NULL END,
                                    CASE WHEN NOT v_generation_success THEN '템플릿 렌더링 오류' ELSE NULL END,
                                    CASE WHEN NOT v_generation_success THEN 1 ELSE 0 END,
                                    CASE WHEN v_generation_success THEN 
                                        CASE WHEN random() < 0.7 THEN 'EMAIL' ELSE 'PORTAL' END
                                    ELSE NULL END,
                                    CASE WHEN v_generation_success THEN 
                                        CASE WHEN random() < 0.9 THEN 'DELIVERED' ELSE 'FAILED' END
                                    ELSE 'PENDING' END,
                                    CASE WHEN v_generation_success AND random() < 0.9 THEN 
                                        v_target_period + INTERVAL '25 days' + INTERVAL '3 hours'
                                    ELSE NULL END,
                                    CASE WHEN v_generation_success AND random() < 0.6 THEN true ELSE false END,
                                    CASE WHEN v_generation_success AND random() < 0.6 THEN 
                                        v_target_period + INTERVAL '26 days' + (random() * 10 || ' days')::INTERVAL
                                    ELSE NULL END,
                                    CASE WHEN v_generation_success AND random() < 0.6 THEN (1 + random() * 5)::integer ELSE 0 END
                                );
                                
                                issuance_count := issuance_count + 1;
                                
                                -- 4. 배포 이력 생성 (성공한 고지서만)
                                IF v_generation_success AND random() < 0.9 THEN
                                    DECLARE
                                        v_delivery_method VARCHAR(20) := CASE WHEN random() < 0.7 THEN 'EMAIL' ELSE 'PORTAL' END;
                                        v_delivery_success BOOLEAN := random() < 0.95;
                                    BEGIN
                                        INSERT INTO bms.bill_delivery_history (
                                            issuance_id, company_id,
                                            delivery_method, delivery_target, delivery_status,
                                            attempt_number, attempted_at, completed_at,
                                            delivery_result, response_code, response_message,
                                            delivery_reference, delivery_details, delivery_cost
                                        ) VALUES (
                                            v_issuance_id, company_rec.company_id,
                                            v_delivery_method,
                                            CASE WHEN v_delivery_method = 'EMAIL' THEN 
                                                'resident' || calculation_rec.unit_number || '@example.com'
                                            ELSE 'PORTAL_USER_' || calculation_rec.unit_id::text END,
                                            CASE WHEN v_delivery_success THEN 'DELIVERED' ELSE 'FAILED' END,
                                            1,
                                            v_target_period + INTERVAL '25 days' + INTERVAL '3 hours',
                                            CASE WHEN v_delivery_success THEN 
                                                v_target_period + INTERVAL '25 days' + INTERVAL '3 hours' + INTERVAL '30 seconds'
                                            ELSE NULL END,
                                            CASE WHEN v_delivery_success THEN 'SUCCESS' ELSE 'FAILED' END,
                                            CASE WHEN v_delivery_success THEN '200' ELSE '500' END,
                                            CASE WHEN v_delivery_success THEN 'Delivered successfully' ELSE 'Delivery failed' END,
                                            'REF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD((random() * 9999)::integer::text, 4, '0'),
                                            jsonb_build_object(
                                                'delivery_method', v_delivery_method,
                                                'target_type', CASE WHEN v_delivery_method = 'EMAIL' THEN 'email' ELSE 'portal' END,
                                                'file_size', CASE WHEN v_generation_success THEN (400000 + random() * 200000)::bigint ELSE NULL END
                                            ),
                                            CASE WHEN v_delivery_method = 'EMAIL' THEN 100 ELSE 0 END  -- 이메일은 100원
                                        );
                                        
                                        delivery_count := delivery_count + 1;
                                        
                                        -- 실패한 경우 재시도 이력 추가 (50% 확률)
                                        IF NOT v_delivery_success AND random() < 0.5 THEN
                                            INSERT INTO bms.bill_delivery_history (
                                                issuance_id, company_id,
                                                delivery_method, delivery_target, delivery_status,
                                                attempt_number, attempted_at, completed_at,
                                                delivery_result, response_code, response_message,
                                                delivery_reference, delivery_details, delivery_cost
                                            ) VALUES (
                                                v_issuance_id, company_rec.company_id,
                                                v_delivery_method,
                                                CASE WHEN v_delivery_method = 'EMAIL' THEN 
                                                    'resident' || calculation_rec.unit_number || '@example.com'
                                                ELSE 'PORTAL_USER_' || calculation_rec.unit_id::text END,
                                                'DELIVERED',
                                                2,
                                                v_target_period + INTERVAL '25 days' + INTERVAL '4 hours',
                                                v_target_period + INTERVAL '25 days' + INTERVAL '4 hours' + INTERVAL '30 seconds',
                                                'SUCCESS', '200', 'Delivered successfully on retry',
                                                'REF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD((random() * 9999)::integer::text, 4, '0'),
                                                jsonb_build_object(
                                                    'delivery_method', v_delivery_method,
                                                    'retry_attempt', true,
                                                    'original_failure', 'temporary_error'
                                                ),
                                                CASE WHEN v_delivery_method = 'EMAIL' THEN 100 ELSE 0 END
                                            );
                                            
                                            delivery_count := delivery_count + 1;
                                        END IF;
                                    END;
                                END IF;
                            END;
                        END LOOP;
                    END IF;
                END IF;
            END;
        END LOOP;
        
        RAISE NOTICE '회사 % 고지서 발행 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 고지서 발행 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 발행 스케줄: %개', schedule_count;
    RAISE NOTICE '생성된 발행 배치: %개', batch_count;
    RAISE NOTICE '생성된 개별 고지서: %개', issuance_count;
    RAISE NOTICE '생성된 배포 이력: %개', delivery_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 고지서 발행 시스템 테스트 데이터 생성이 완료되었습니다!' as result;