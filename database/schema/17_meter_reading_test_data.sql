-- =====================================================
-- 검침 데이터 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    unit_rec RECORD;
    meter_count INTEGER := 0;
    reading_count INTEGER := 0;
    schedule_count INTEGER := 0;
    task_count INTEGER := 0;
    
    -- 계량기 ID 저장용 변수들
    electric_meter_id UUID;
    water_meter_id UUID;
    gas_meter_id UUID;
    heating_meter_id UUID;
BEGIN
    -- 각 회사에 대해 검침 시스템 데이터 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 검침 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 각 건물에 대해 계량기 생성
        FOR building_rec IN 
            SELECT building_id, name as building_name
            FROM bms.buildings 
            WHERE company_id = company_rec.company_id
            LIMIT 2  -- 각 회사당 2개 건물만
        LOOP
            RAISE NOTICE '  건물 % 계량기 생성', building_rec.building_name;
            
            -- 1. 공용 계량기 생성 (건물 전체용)
            INSERT INTO bms.meters (
                company_id, building_id, unit_id, meter_number, meter_type, meter_brand, meter_model,
                installation_date, installation_location, measurement_unit, decimal_places,
                reading_cycle, reading_day, max_usage_threshold, min_usage_threshold
            ) VALUES 
            -- 공용 전기 계량기
            (company_rec.company_id, building_rec.building_id, NULL, 
             'E-' || building_rec.building_name || '-MAIN', 'ELECTRIC', 'LS산전', 'EM-3000',
             CURRENT_DATE - INTERVAL '2 years', '전기실 메인 패널', 'KWH', 1,
             'MONTHLY', 1, 50000.0, 0.0),
            
            -- 공용 수도 계량기
            (company_rec.company_id, building_rec.building_id, NULL,
             'W-' || building_rec.building_name || '-MAIN', 'WATER', '동양계기', 'WM-2000',
             CURRENT_DATE - INTERVAL '2 years', '급수실 메인 밸브', 'M3', 2,
             'MONTHLY', 1, 1000.0, 0.0),
            
            -- 공용 가스 계량기
            (company_rec.company_id, building_rec.building_id, NULL,
             'G-' || building_rec.building_name || '-MAIN', 'GAS', '가스공사', 'GM-1500',
             CURRENT_DATE - INTERVAL '2 years', '가스실 메인 밸브', 'M3', 2,
             'MONTHLY', 1, 500.0, 0.0);
            
            meter_count := meter_count + 3;
            
            -- 2. 각 호실별 개별 계량기 생성
            FOR unit_rec IN 
                SELECT unit_id, unit_number
                FROM bms.units 
                WHERE building_id = building_rec.building_id
                LIMIT 3  -- 각 건물당 3개 호실만
            LOOP
                RAISE NOTICE '    호실 % 개별 계량기 생성', unit_rec.unit_number;
                
                -- 호실별 전기 계량기
                INSERT INTO bms.meters (
                    company_id, building_id, unit_id, meter_number, meter_type, meter_brand, meter_model,
                    installation_date, installation_location, measurement_unit, decimal_places,
                    reading_cycle, reading_day, max_usage_threshold, min_usage_threshold
                ) VALUES 
                (company_rec.company_id, building_rec.building_id, unit_rec.unit_id,
                 'E-' || building_rec.building_name || '-' || unit_rec.unit_number, 'ELECTRIC', 'LS산전', 'EM-1000',
                 CURRENT_DATE - INTERVAL '1 year', unit_rec.unit_number || '호 전기실', 'KWH', 1,
                 'MONTHLY', 1, 2000.0, 0.0),
                
                -- 호실별 수도 계량기
                (company_rec.company_id, building_rec.building_id, unit_rec.unit_id,
                 'W-' || building_rec.building_name || '-' || unit_rec.unit_number, 'WATER', '동양계기', 'WM-500',
                 CURRENT_DATE - INTERVAL '1 year', unit_rec.unit_number || '호 급수실', 'M3', 2,
                 'MONTHLY', 1, 100.0, 0.0),
                
                -- 호실별 가스 계량기 (50% 확률로 생성)
                (company_rec.company_id, building_rec.building_id, unit_rec.unit_id,
                 'G-' || building_rec.building_name || '-' || unit_rec.unit_number, 'GAS', '가스공사', 'GM-300',
                 CURRENT_DATE - INTERVAL '1 year', unit_rec.unit_number || '호 가스실', 'M3', 2,
                 'MONTHLY', 1, 50.0, 0.0);
                
                meter_count := meter_count + 3;
            END LOOP;
        END LOOP;
        
        -- 3. 검침 일정 생성
        INSERT INTO bms.meter_reading_schedules (
            company_id, building_id, schedule_name, schedule_description,
            reading_cycle, reading_day, reading_time,
            meter_types, assigned_readers, notification_enabled, auto_create_tasks
        ) VALUES 
        -- 전체 건물 월별 검침 일정
        (company_rec.company_id, NULL, '월별 전체 검침', '모든 건물의 월별 정기 검침',
         'MONTHLY', 1, '09:00',
         ARRAY['ELECTRIC', 'WATER', 'GAS'],
         ARRAY[(SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1)],
         true, true),
        
        -- 공용 시설 검침 일정
        (company_rec.company_id, NULL, '공용시설 검침', '공용 계량기 검침 일정',
         'MONTHLY', 1, '08:00',
         ARRAY['ELECTRIC', 'WATER', 'GAS'],
         ARRAY[(SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1)],
         true, true);
        
        schedule_count := schedule_count + 2;
        
        -- 4. 과거 검침 데이터 생성 (최근 12개월)
        FOR i IN 0..11 LOOP
            DECLARE
                v_reading_date DATE := DATE_TRUNC('month', CURRENT_DATE) - (i || ' months')::INTERVAL + INTERVAL '1 day';
                v_meter_rec RECORD;
                v_base_reading DECIMAL(15,4);
                v_monthly_usage DECIMAL(15,4);
            BEGIN
                -- 각 계량기별 검침 데이터 생성
                FOR v_meter_rec IN 
                    SELECT meter_id, meter_type, meter_number, unit_id
                    FROM bms.meters 
                    WHERE company_id = company_rec.company_id
                LOOP
                    -- 계량기 유형별 기본 사용량 설정
                    CASE v_meter_rec.meter_type
                        WHEN 'ELECTRIC' THEN
                            IF v_meter_rec.unit_id IS NULL THEN
                                -- 공용 전기: 월 3000-5000 KWH
                                v_monthly_usage := 3000 + random() * 2000;
                            ELSE
                                -- 호실 전기: 월 200-800 KWH
                                v_monthly_usage := 200 + random() * 600;
                            END IF;
                        WHEN 'WATER' THEN
                            IF v_meter_rec.unit_id IS NULL THEN
                                -- 공용 수도: 월 100-300 M3
                                v_monthly_usage := 100 + random() * 200;
                            ELSE
                                -- 호실 수도: 월 10-50 M3
                                v_monthly_usage := 10 + random() * 40;
                            END IF;
                        WHEN 'GAS' THEN
                            IF v_meter_rec.unit_id IS NULL THEN
                                -- 공용 가스: 월 50-150 M3
                                v_monthly_usage := 50 + random() * 100;
                            ELSE
                                -- 호실 가스: 월 5-30 M3
                                v_monthly_usage := 5 + random() * 25;
                            END IF;
                        ELSE
                            v_monthly_usage := 100 + random() * 200;
                    END CASE;
                    
                    -- 계절별 변동 적용 (겨울철 증가, 여름철 감소)
                    DECLARE
                        v_month INTEGER := EXTRACT(MONTH FROM v_reading_date);
                        v_seasonal_factor DECIMAL(4,2);
                    BEGIN
                        CASE 
                            WHEN v_month IN (12, 1, 2) THEN v_seasonal_factor := 1.3;  -- 겨울
                            WHEN v_month IN (6, 7, 8) THEN v_seasonal_factor := 0.8;   -- 여름
                            ELSE v_seasonal_factor := 1.0;  -- 봄, 가을
                        END CASE;
                        
                        v_monthly_usage := v_monthly_usage * v_seasonal_factor;
                    END;
                    
                    -- 누적 검침값 계산
                    SELECT COALESCE(reading_value, 0) + v_monthly_usage INTO v_base_reading
                    FROM bms.meter_readings
                    WHERE meter_id = v_meter_rec.meter_id
                      AND reading_date = v_reading_date - INTERVAL '1 month'
                    UNION ALL
                    SELECT v_monthly_usage * (12 - i)  -- 첫 검침인 경우 기본값
                    LIMIT 1;
                    
                    -- 검침 데이터 삽입
                    INSERT INTO bms.meter_readings (
                        company_id, meter_id, reading_date, reading_time, reading_value,
                        reading_method, reading_source, reader_id, reader_name,
                        reading_status, is_estimated, is_validated
                    ) VALUES (
                        company_rec.company_id, v_meter_rec.meter_id, v_reading_date, '09:00',
                        ROUND(v_base_reading, CASE WHEN v_meter_rec.meter_type = 'ELECTRIC' THEN 1 ELSE 2 END),
                        (ARRAY['MANUAL', 'PHOTO', 'REMOTE'])[ceil(random() * 3)],
                        'MOBILE_APP',
                        (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                        '검침원' || ceil(random() * 3),
                        CASE WHEN random() < 0.95 THEN 'NORMAL' ELSE 'SUSPICIOUS' END,
                        random() < 0.1,  -- 10% 확률로 추정 검침
                        random() < 0.9   -- 90% 확률로 검증 완료
                    );
                    
                    reading_count := reading_count + 1;
                END LOOP;
            END;
        END LOOP;
        
        -- 5. 검침 작업 생성 (이번 달)
        FOR v_meter_rec IN 
            SELECT meter_id, meter_number
            FROM bms.meters 
            WHERE company_id = company_rec.company_id
            LIMIT 10  -- 10개 계량기만
        LOOP
            INSERT INTO bms.meter_reading_tasks (
                company_id, schedule_id, meter_id, task_name,
                scheduled_date, scheduled_time, assigned_to, task_status, priority_level
            ) VALUES (
                company_rec.company_id,
                (SELECT schedule_id FROM bms.meter_reading_schedules WHERE company_id = company_rec.company_id LIMIT 1),
                v_meter_rec.meter_id,
                v_meter_rec.meter_number || ' 검침 작업',
                CURRENT_DATE + INTERVAL '1 day',
                '09:00',
                (SELECT user_id FROM bms.users WHERE company_id = company_rec.company_id LIMIT 1),
                (ARRAY['PENDING', 'ASSIGNED', 'IN_PROGRESS'])[ceil(random() * 3)],
                ceil(random() * 3)  -- 1-3 우선순위
            );
            
            task_count := task_count + 1;
        END LOOP;
        
        RAISE NOTICE '회사 % 검침 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 6. 사용량 계산 및 이상 감지 실행
    RAISE NOTICE '사용량 계산 및 이상 감지 실행 시작';
    
    DECLARE
        v_reading_rec RECORD;
        v_processed_count INTEGER := 0;
        v_anomaly_count INTEGER := 0;
    BEGIN
        FOR v_reading_rec IN 
            SELECT reading_id 
            FROM bms.meter_readings 
            WHERE usage_amount IS NULL
            LIMIT 100  -- 처리량 제한
        LOOP
            -- 사용량 계산
            PERFORM bms.calculate_usage_amount(v_reading_rec.reading_id);
            
            -- 이상 감지
            IF bms.detect_reading_anomaly(v_reading_rec.reading_id) THEN
                v_anomaly_count := v_anomaly_count + 1;
            END IF;
            
            v_processed_count := v_processed_count + 1;
        END LOOP;
        
        RAISE NOTICE '사용량 계산 완료: %건, 이상 감지: %건', v_processed_count, v_anomaly_count;
    END;
    
    -- 통계 정보 출력
    RAISE NOTICE '=== 검침 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '총 계량기 수: %', meter_count;
    RAISE NOTICE '총 검침 데이터 수: %', reading_count;
    RAISE NOTICE '총 검침 일정 수: %', schedule_count;
    RAISE NOTICE '총 검침 작업 수: %', task_count;
    
END $$;

-- 생성된 데이터 확인 쿼리
-- 1. 계량기 현황
SELECT 
    '계량기 현황' as category,
    c.company_name,
    b.name as building_name,
    COALESCE(u.unit_number, '공용') as unit_info,
    m.meter_type,
    m.meter_number,
    m.measurement_unit,
    m.meter_status
FROM bms.meters m
JOIN bms.companies c ON m.company_id = c.company_id
JOIN bms.buildings b ON m.building_id = b.building_id
LEFT JOIN bms.units u ON m.unit_id = u.unit_id
WHERE m.is_active = true
ORDER BY c.company_name, b.name, u.unit_number NULLS FIRST, m.meter_type
LIMIT 15;

-- 2. 최근 검침 데이터
SELECT 
    '최근 검침 데이터' as category,
    company_name,
    building_name,
    unit_number,
    meter_type,
    reading_date,
    reading_value,
    usage_amount,
    reading_method,
    anomaly_detected
FROM bms.v_meter_readings_summary
ORDER BY reading_date DESC, company_name, building_name
LIMIT 15;

-- 3. 검침 일정 현황
SELECT 
    '검침 일정' as category,
    c.company_name,
    COALESCE(b.name, '전체') as building_name,
    mrs.schedule_name,
    mrs.reading_cycle,
    mrs.reading_day,
    mrs.meter_types,
    mrs.is_active
FROM bms.meter_reading_schedules mrs
JOIN bms.companies c ON mrs.company_id = c.company_id
LEFT JOIN bms.buildings b ON mrs.building_id = b.building_id
WHERE mrs.is_active = true
ORDER BY c.company_name, b.name NULLS FIRST;

-- 4. 검침 작업 현황
SELECT 
    '검침 작업' as category,
    c.company_name,
    m.meter_number,
    mrt.task_name,
    mrt.scheduled_date,
    mrt.task_status,
    mrt.priority_level
FROM bms.meter_reading_tasks mrt
JOIN bms.companies c ON mrt.company_id = c.company_id
JOIN bms.meters m ON mrt.meter_id = m.meter_id
ORDER BY mrt.scheduled_date, mrt.priority_level
LIMIT 10;

-- 5. 이상 검침 현황
SELECT 
    '이상 검침' as category,
    company_name,
    building_name,
    unit_number,
    meter_type,
    reading_date,
    usage_amount,
    anomaly_type,
    reading_status
FROM bms.v_meter_readings_summary
WHERE anomaly_detected = true
ORDER BY reading_date DESC
LIMIT 10;

-- 6. 월별 사용량 통계
SELECT 
    '월별 사용량 통계' as category,
    DATE_TRUNC('month', mr.reading_date) as month,
    m.meter_type,
    COUNT(*) as reading_count,
    ROUND(AVG(mr.usage_amount), 2) as avg_usage,
    ROUND(SUM(mr.usage_amount), 2) as total_usage,
    m.measurement_unit
FROM bms.meter_readings mr
JOIN bms.meters m ON mr.meter_id = m.meter_id
WHERE mr.usage_amount IS NOT NULL
  AND mr.reading_date >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', mr.reading_date), m.meter_type, m.measurement_unit
ORDER BY month DESC, m.meter_type
LIMIT 15;

-- 완료 메시지
SELECT '✅ 검침 데이터 테스트 데이터 생성이 완료되었습니다!' as result;