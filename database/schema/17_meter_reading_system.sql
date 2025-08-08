-- =====================================================
-- 검침 데이터 시스템 테이블 생성 스크립트
-- Phase 2.2.1: 검침 데이터 테이블 생성
-- =====================================================

-- 1. 계량기 마스터 테이블
CREATE TABLE IF NOT EXISTS bms.meters (
    meter_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID NOT NULL,
    unit_id UUID,                                       -- NULL이면 공용 계량기
    
    -- 계량기 기본 정보
    meter_number VARCHAR(50) NOT NULL,                  -- 계량기 번호
    meter_type VARCHAR(20) NOT NULL,                    -- 계량기 유형
    meter_brand VARCHAR(50),                            -- 제조사
    meter_model VARCHAR(50),                            -- 모델명
    
    -- 설치 정보
    installation_date DATE,                             -- 설치일
    installation_location VARCHAR(200),                 -- 설치 위치
    installer_name VARCHAR(100),                        -- 설치자
    
    -- 계량기 사양
    measurement_unit VARCHAR(20) NOT NULL,              -- 측정 단위
    decimal_places INTEGER DEFAULT 0,                   -- 소수점 자릿수
    max_reading DECIMAL(15,4),                          -- 최대 검침값
    min_reading DECIMAL(15,4) DEFAULT 0,                -- 최소 검침값
    
    -- 검침 설정
    reading_cycle VARCHAR(20) DEFAULT 'MONTHLY',        -- 검침 주기
    reading_day INTEGER DEFAULT 1,                      -- 검침일
    auto_reading_enabled BOOLEAN DEFAULT false,         -- 자동 검침 여부
    
    -- 계량기 상태
    meter_status VARCHAR(20) DEFAULT 'ACTIVE',          -- 계량기 상태
    last_maintenance_date DATE,                         -- 마지막 점검일
    next_maintenance_date DATE,                         -- 다음 점검일
    
    -- 검증 설정
    validation_enabled BOOLEAN DEFAULT true,            -- 검증 활성화
    max_usage_threshold DECIMAL(15,4),                  -- 최대 사용량 임계값
    min_usage_threshold DECIMAL(15,4),                  -- 최소 사용량 임계값
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    is_active BOOLEAN DEFAULT true,
    
    -- 제약조건
    CONSTRAINT fk_meters_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_meters_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_meters_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT uk_meters_number UNIQUE (company_id, meter_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_meter_type CHECK (meter_type IN (
        'ELECTRIC',            -- 전기
        'WATER',               -- 수도
        'GAS',                 -- 가스
        'HEATING',             -- 난방
        'HOT_WATER',           -- 온수
        'STEAM',               -- 스팀
        'COMPRESSED_AIR',      -- 압축공기
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_measurement_unit CHECK (measurement_unit IN (
        'KWH',                 -- 킬로와트시
        'M3',                  -- 세제곱미터
        'L',                   -- 리터
        'KCAL',                -- 킬로칼로리
        'MJ',                  -- 메가줄
        'UNIT'                 -- 단위
    )),
    CONSTRAINT chk_reading_cycle CHECK (reading_cycle IN (
        'DAILY',               -- 일별
        'WEEKLY',              -- 주별
        'MONTHLY',             -- 월별
        'QUARTERLY',           -- 분기별
        'ANNUAL'               -- 연간
    )),
    CONSTRAINT chk_meter_status CHECK (meter_status IN (
        'ACTIVE',              -- 활성
        'INACTIVE',            -- 비활성
        'MAINTENANCE',         -- 점검중
        'BROKEN',              -- 고장
        'REPLACED'             -- 교체됨
    )),
    CONSTRAINT chk_reading_day CHECK (reading_day BETWEEN 1 AND 31),
    CONSTRAINT chk_decimal_places CHECK (decimal_places >= 0 AND decimal_places <= 6),
    CONSTRAINT chk_reading_range CHECK (max_reading IS NULL OR min_reading IS NULL OR max_reading > min_reading)
);

-- 2. 검침 데이터 테이블
CREATE TABLE IF NOT EXISTS bms.meter_readings (
    reading_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    meter_id UUID NOT NULL,
    
    -- 검침 기본 정보
    reading_date DATE NOT NULL,                         -- 검침일
    reading_time TIME,                                  -- 검침 시간
    reading_value DECIMAL(15,4) NOT NULL,               -- 검침값
    previous_reading_value DECIMAL(15,4),               -- 이전 검침값
    usage_amount DECIMAL(15,4),                         -- 사용량 (현재값 - 이전값)
    
    -- 검침 방법
    reading_method VARCHAR(20) NOT NULL,                -- 검침 방법
    reading_source VARCHAR(20) DEFAULT 'MANUAL',        -- 검침 소스
    
    -- 검침자 정보
    reader_id UUID,                                     -- 검침자 ID
    reader_name VARCHAR(100),                           -- 검침자명
    reader_signature TEXT,                              -- 검침자 서명 (Base64)
    
    -- 검침 상태
    reading_status VARCHAR(20) DEFAULT 'NORMAL',        -- 검침 상태
    is_estimated BOOLEAN DEFAULT false,                 -- 추정 검침 여부
    estimation_method VARCHAR(20),                      -- 추정 방법
    
    -- 검증 정보
    is_validated BOOLEAN DEFAULT false,                 -- 검증 완료 여부
    validation_status VARCHAR(20),                      -- 검증 상태
    validation_notes TEXT,                              -- 검증 메모
    validated_by UUID,                                  -- 검증자 ID
    validated_at TIMESTAMP WITH TIME ZONE,             -- 검증 일시
    
    -- 이상 감지
    anomaly_detected BOOLEAN DEFAULT false,             -- 이상 감지 여부
    anomaly_type VARCHAR(20),                           -- 이상 유형
    anomaly_description TEXT,                           -- 이상 설명
    
    -- 조정 정보
    is_adjusted BOOLEAN DEFAULT false,                  -- 조정 여부
    adjusted_value DECIMAL(15,4),                       -- 조정된 값
    adjustment_reason TEXT,                             -- 조정 사유
    adjusted_by UUID,                                   -- 조정자 ID
    adjusted_at TIMESTAMP WITH TIME ZONE,              -- 조정 일시
    
    -- 첨부 파일
    photo_urls TEXT[],                                  -- 검침 사진 URL 목록
    document_urls TEXT[],                               -- 관련 문서 URL 목록
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_readings_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_readings_meter FOREIGN KEY (meter_id) REFERENCES bms.meters(meter_id) ON DELETE CASCADE,
    CONSTRAINT fk_readings_reader FOREIGN KEY (reader_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_readings_validator FOREIGN KEY (validated_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_readings_adjuster FOREIGN KEY (adjusted_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_readings_meter_date UNIQUE (meter_id, reading_date),
    
    -- 체크 제약조건
    CONSTRAINT chk_reading_method CHECK (reading_method IN (
        'MANUAL',              -- 수동 검침
        'PHOTO',               -- 사진 검침
        'REMOTE',              -- 원격 검침
        'AUTOMATIC',           -- 자동 검침
        'ESTIMATED'            -- 추정 검침
    )),
    CONSTRAINT chk_reading_source CHECK (reading_source IN (
        'MANUAL',              -- 수동 입력
        'MOBILE_APP',          -- 모바일 앱
        'WEB_PORTAL',          -- 웹 포털
        'API',                 -- API
        'IMPORT',              -- 일괄 가져오기
        'SYSTEM'               -- 시스템 자동
    )),
    CONSTRAINT chk_reading_status CHECK (reading_status IN (
        'NORMAL',              -- 정상
        'ABNORMAL',            -- 비정상
        'SUSPICIOUS',          -- 의심스러운
        'CORRECTED',           -- 수정됨
        'PENDING'              -- 대기중
    )),
    CONSTRAINT chk_estimation_method CHECK (estimation_method IN (
        'AVERAGE',             -- 평균값
        'PREVIOUS_MONTH',      -- 전월 동일
        'SEASONAL_PATTERN',    -- 계절 패턴
        'REGRESSION',          -- 회귀 분석
        'MANUAL_ESTIMATE'      -- 수동 추정
    )),
    CONSTRAINT chk_validation_status CHECK (validation_status IN (
        'PENDING',             -- 검증 대기
        'PASSED',              -- 검증 통과
        'FAILED',              -- 검증 실패
        'MANUAL_REVIEW'        -- 수동 검토 필요
    )),
    CONSTRAINT chk_anomaly_type CHECK (anomaly_type IN (
        'HIGH_USAGE',          -- 사용량 과다
        'LOW_USAGE',           -- 사용량 과소
        'NEGATIVE_USAGE',      -- 음수 사용량
        'METER_ROLLOVER',      -- 계량기 리셋
        'READING_ERROR',       -- 검침 오류
        'METER_MALFUNCTION'    -- 계량기 오작동
    )),
    CONSTRAINT chk_reading_value_positive CHECK (reading_value >= 0),
    CONSTRAINT chk_usage_calculation CHECK (
        usage_amount IS NULL OR 
        previous_reading_value IS NULL OR 
        usage_amount = reading_value - previous_reading_value
    )
);

-- 3. 검침 일정 테이블
CREATE TABLE IF NOT EXISTS bms.meter_reading_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                   -- NULL이면 전체 건물
    
    -- 일정 기본 정보
    schedule_name VARCHAR(100) NOT NULL,                -- 일정명
    schedule_description TEXT,                          -- 일정 설명
    
    -- 검침 주기 설정
    reading_cycle VARCHAR(20) NOT NULL,                 -- 검침 주기
    reading_day INTEGER NOT NULL,                       -- 검침일
    reading_time TIME DEFAULT '09:00',                  -- 검침 시간
    
    -- 대상 계량기
    meter_types TEXT[],                                 -- 대상 계량기 유형
    specific_meters UUID[],                             -- 특정 계량기 ID 목록
    
    -- 담당자 설정
    assigned_readers UUID[],                            -- 담당 검침자 목록
    backup_readers UUID[],                              -- 백업 검침자 목록
    
    -- 알림 설정
    notification_enabled BOOLEAN DEFAULT true,          -- 알림 활성화
    notification_days_before INTEGER DEFAULT 1,         -- 사전 알림 일수
    notification_methods TEXT[],                        -- 알림 방법
    
    -- 자동화 설정
    auto_create_tasks BOOLEAN DEFAULT true,             -- 자동 작업 생성
    auto_reminder_enabled BOOLEAN DEFAULT true,         -- 자동 리마인더
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_schedules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_schedules_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_schedule_reading_cycle CHECK (reading_cycle IN (
        'DAILY', 'WEEKLY', 'MONTHLY', 'QUARTERLY', 'ANNUAL'
    )),
    CONSTRAINT chk_schedule_reading_day CHECK (reading_day BETWEEN 1 AND 31),
    CONSTRAINT chk_notification_days_before CHECK (notification_days_before >= 0),
    CONSTRAINT chk_schedule_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 4. 검침 작업 테이블
CREATE TABLE IF NOT EXISTS bms.meter_reading_tasks (
    task_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    schedule_id UUID,                                   -- 일정 ID (NULL이면 임시 작업)
    meter_id UUID NOT NULL,
    
    -- 작업 기본 정보
    task_name VARCHAR(100),                             -- 작업명
    scheduled_date DATE NOT NULL,                       -- 예정일
    scheduled_time TIME,                                -- 예정 시간
    
    -- 담당자 정보
    assigned_to UUID,                                   -- 담당자 ID
    assigned_at TIMESTAMP WITH TIME ZONE,              -- 배정 일시
    
    -- 작업 상태
    task_status VARCHAR(20) DEFAULT 'PENDING',          -- 작업 상태
    started_at TIMESTAMP WITH TIME ZONE,               -- 시작 일시
    completed_at TIMESTAMP WITH TIME ZONE,             -- 완료 일시
    
    -- 작업 결과
    reading_id UUID,                                    -- 검침 결과 ID
    completion_notes TEXT,                              -- 완료 메모
    
    -- 우선순위
    priority_level INTEGER DEFAULT 3,                   -- 우선순위 (1=높음, 5=낮음)
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_tasks_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_tasks_schedule FOREIGN KEY (schedule_id) REFERENCES bms.meter_reading_schedules(schedule_id) ON DELETE SET NULL,
    CONSTRAINT fk_tasks_meter FOREIGN KEY (meter_id) REFERENCES bms.meters(meter_id) ON DELETE CASCADE,
    CONSTRAINT fk_tasks_assigned_to FOREIGN KEY (assigned_to) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_tasks_reading FOREIGN KEY (reading_id) REFERENCES bms.meter_readings(reading_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_task_status CHECK (task_status IN (
        'PENDING',             -- 대기중
        'ASSIGNED',            -- 배정됨
        'IN_PROGRESS',         -- 진행중
        'COMPLETED',           -- 완료
        'CANCELLED',           -- 취소됨
        'OVERDUE'              -- 지연됨
    )),
    CONSTRAINT chk_priority_level CHECK (priority_level BETWEEN 1 AND 5)
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.meters ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.meter_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.meter_reading_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.meter_reading_tasks ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY meters_isolation_policy ON bms.meters
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY meter_readings_isolation_policy ON bms.meter_readings
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY meter_reading_schedules_isolation_policy ON bms.meter_reading_schedules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY meter_reading_tasks_isolation_policy ON bms.meter_reading_tasks
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 계량기 마스터 인덱스
CREATE INDEX idx_meters_company_id ON bms.meters(company_id);
CREATE INDEX idx_meters_building_id ON bms.meters(building_id);
CREATE INDEX idx_meters_unit_id ON bms.meters(unit_id);
CREATE INDEX idx_meters_type ON bms.meters(meter_type);
CREATE INDEX idx_meters_status ON bms.meters(meter_status);
CREATE INDEX idx_meters_number ON bms.meters(meter_number);

-- 검침 데이터 인덱스
CREATE INDEX idx_readings_company_id ON bms.meter_readings(company_id);
CREATE INDEX idx_readings_meter_id ON bms.meter_readings(meter_id);
CREATE INDEX idx_readings_date ON bms.meter_readings(reading_date DESC);
CREATE INDEX idx_readings_status ON bms.meter_readings(reading_status);
CREATE INDEX idx_readings_method ON bms.meter_readings(reading_method);
CREATE INDEX idx_readings_estimated ON bms.meter_readings(is_estimated);
CREATE INDEX idx_readings_validated ON bms.meter_readings(is_validated);
CREATE INDEX idx_readings_anomaly ON bms.meter_readings(anomaly_detected);

-- 검침 일정 인덱스
CREATE INDEX idx_schedules_company_id ON bms.meter_reading_schedules(company_id);
CREATE INDEX idx_schedules_building_id ON bms.meter_reading_schedules(building_id);
CREATE INDEX idx_schedules_cycle ON bms.meter_reading_schedules(reading_cycle);
CREATE INDEX idx_schedules_active ON bms.meter_reading_schedules(is_active);

-- 검침 작업 인덱스
CREATE INDEX idx_tasks_company_id ON bms.meter_reading_tasks(company_id);
CREATE INDEX idx_tasks_schedule_id ON bms.meter_reading_tasks(schedule_id);
CREATE INDEX idx_tasks_meter_id ON bms.meter_reading_tasks(meter_id);
CREATE INDEX idx_tasks_assigned_to ON bms.meter_reading_tasks(assigned_to);
CREATE INDEX idx_tasks_status ON bms.meter_reading_tasks(task_status);
CREATE INDEX idx_tasks_scheduled_date ON bms.meter_reading_tasks(scheduled_date);
CREATE INDEX idx_tasks_priority ON bms.meter_reading_tasks(priority_level);

-- 복합 인덱스
CREATE INDEX idx_meters_company_building ON bms.meters(company_id, building_id);
CREATE INDEX idx_readings_meter_date ON bms.meter_readings(meter_id, reading_date DESC);
CREATE INDEX idx_readings_company_date ON bms.meter_readings(company_id, reading_date DESC);
CREATE INDEX idx_tasks_assigned_status ON bms.meter_reading_tasks(assigned_to, task_status);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER meters_updated_at_trigger
    BEFORE UPDATE ON bms.meters
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER meter_readings_updated_at_trigger
    BEFORE UPDATE ON bms.meter_readings
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER meter_reading_schedules_updated_at_trigger
    BEFORE UPDATE ON bms.meter_reading_schedules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER meter_reading_tasks_updated_at_trigger
    BEFORE UPDATE ON bms.meter_reading_tasks
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 검침 데이터 관리 함수들
-- 사용량 계산 및 업데이트 함수
CREATE OR REPLACE FUNCTION bms.calculate_usage_amount(
    p_reading_id UUID
)
RETURNS DECIMAL(15,4) AS $$
DECLARE
    v_current_reading DECIMAL(15,4);
    v_previous_reading DECIMAL(15,4);
    v_usage_amount DECIMAL(15,4);
    v_meter_id UUID;
    v_reading_date DATE;
BEGIN
    -- 현재 검침 정보 조회
    SELECT meter_id, reading_date, reading_value
    INTO v_meter_id, v_reading_date, v_current_reading
    FROM bms.meter_readings
    WHERE reading_id = p_reading_id;
    
    -- 이전 검침값 조회
    SELECT reading_value INTO v_previous_reading
    FROM bms.meter_readings
    WHERE meter_id = v_meter_id
      AND reading_date < v_reading_date
    ORDER BY reading_date DESC
    LIMIT 1;
    
    -- 사용량 계산
    IF v_previous_reading IS NOT NULL THEN
        v_usage_amount := v_current_reading - v_previous_reading;
        
        -- 음수 사용량 처리 (계량기 교체 등)
        IF v_usage_amount < 0 THEN
            v_usage_amount := v_current_reading;  -- 현재 검침값을 사용량으로 사용
        END IF;
    ELSE
        -- 첫 검침인 경우
        v_usage_amount := v_current_reading;
    END IF;
    
    -- 검침 데이터 업데이트
    UPDATE bms.meter_readings
    SET usage_amount = v_usage_amount,
        previous_reading_value = v_previous_reading,
        updated_at = NOW()
    WHERE reading_id = p_reading_id;
    
    RETURN v_usage_amount;
END;
$$ LANGUAGE plpgsql;

-- 이상 검침 감지 함수
CREATE OR REPLACE FUNCTION bms.detect_reading_anomaly(
    p_reading_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    v_reading_rec RECORD;
    v_meter_rec RECORD;
    v_avg_usage DECIMAL(15,4);
    v_std_dev DECIMAL(15,4);
    v_threshold_multiplier DECIMAL(8,4) := 3.0;  -- 표준편차의 3배
    v_is_anomaly BOOLEAN := false;
    v_anomaly_type VARCHAR(20);
    v_anomaly_description TEXT;
BEGIN
    -- 검침 데이터 조회
    SELECT * INTO v_reading_rec
    FROM bms.meter_readings
    WHERE reading_id = p_reading_id;
    
    -- 계량기 정보 조회
    SELECT * INTO v_meter_rec
    FROM bms.meters
    WHERE meter_id = v_reading_rec.meter_id;
    
    -- 과거 6개월 평균 사용량 및 표준편차 계산
    SELECT 
        AVG(usage_amount) as avg_usage,
        STDDEV(usage_amount) as std_dev
    INTO v_avg_usage, v_std_dev
    FROM bms.meter_readings
    WHERE meter_id = v_reading_rec.meter_id
      AND reading_date >= v_reading_rec.reading_date - INTERVAL '6 months'
      AND reading_date < v_reading_rec.reading_date
      AND usage_amount IS NOT NULL
      AND anomaly_detected = false;
    
    -- 이상 검침 감지 로직
    IF v_reading_rec.usage_amount IS NOT NULL AND v_avg_usage IS NOT NULL THEN
        -- 1. 음수 사용량 체크
        IF v_reading_rec.usage_amount < 0 THEN
            v_is_anomaly := true;
            v_anomaly_type := 'NEGATIVE_USAGE';
            v_anomaly_description := '음수 사용량 감지';
            
        -- 2. 최대 임계값 초과 체크
        ELSIF v_meter_rec.max_usage_threshold IS NOT NULL AND 
              v_reading_rec.usage_amount > v_meter_rec.max_usage_threshold THEN
            v_is_anomaly := true;
            v_anomaly_type := 'HIGH_USAGE';
            v_anomaly_description := '최대 사용량 임계값 초과';
            
        -- 3. 최소 임계값 미달 체크
        ELSIF v_meter_rec.min_usage_threshold IS NOT NULL AND 
              v_reading_rec.usage_amount < v_meter_rec.min_usage_threshold THEN
            v_is_anomaly := true;
            v_anomaly_type := 'LOW_USAGE';
            v_anomaly_description := '최소 사용량 임계값 미달';
            
        -- 4. 통계적 이상값 체크 (표준편차 기반)
        ELSIF v_std_dev IS NOT NULL AND v_std_dev > 0 AND
              ABS(v_reading_rec.usage_amount - v_avg_usage) > (v_threshold_multiplier * v_std_dev) THEN
            v_is_anomaly := true;
            IF v_reading_rec.usage_amount > v_avg_usage THEN
                v_anomaly_type := 'HIGH_USAGE';
                v_anomaly_description := '평균 대비 과다 사용량 (통계적 이상값)';
            ELSE
                v_anomaly_type := 'LOW_USAGE';
                v_anomaly_description := '평균 대비 과소 사용량 (통계적 이상값)';
            END IF;
        END IF;
    END IF;
    
    -- 이상 감지 결과 업데이트
    IF v_is_anomaly THEN
        UPDATE bms.meter_readings
        SET anomaly_detected = true,
            anomaly_type = v_anomaly_type,
            anomaly_description = v_anomaly_description,
            validation_status = 'MANUAL_REVIEW',
            updated_at = NOW()
        WHERE reading_id = p_reading_id;
    END IF;
    
    RETURN v_is_anomaly;
END;
$$ LANGUAGE plpgsql;

-- 10. 검침 데이터 뷰 생성
CREATE OR REPLACE VIEW bms.v_meter_readings_summary AS
SELECT 
    mr.reading_id,
    mr.company_id,
    c.company_name,
    mr.meter_id,
    m.meter_number,
    m.meter_type,
    b.name as building_name,
    u.unit_number,
    mr.reading_date,
    mr.reading_value,
    mr.usage_amount,
    mr.reading_method,
    mr.reading_status,
    mr.is_estimated,
    mr.is_validated,
    mr.anomaly_detected,
    mr.anomaly_type,
    mr.reader_name,
    mr.created_at
FROM bms.meter_readings mr
JOIN bms.meters m ON mr.meter_id = m.meter_id
JOIN bms.companies c ON mr.company_id = c.company_id
JOIN bms.buildings b ON m.building_id = b.building_id
LEFT JOIN bms.units u ON m.unit_id = u.unit_id
ORDER BY mr.reading_date DESC, b.name, u.unit_number;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_meter_readings_summary OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 2.1 검침 데이터 테이블 생성이 완료되었습니다!' as result;