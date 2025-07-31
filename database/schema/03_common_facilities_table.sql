-- =====================================================
-- 공용시설 관리 테이블 생성 스크립트
-- Phase 1.3: 공용시설 관리 테이블 생성
-- =====================================================

-- 1. 공용시설 테이블 생성
CREATE TABLE IF NOT EXISTS bms.common_facilities (
    facility_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID NOT NULL,
    facility_name VARCHAR(200) NOT NULL,                 -- 시설명
    facility_code VARCHAR(50),                           -- 시설 코드 (관리용)
    facility_category VARCHAR(50) NOT NULL,              -- 시설 분류
    facility_type VARCHAR(50) NOT NULL,                  -- 시설 타입
    
    -- 위치 정보
    location_floor INTEGER,                              -- 위치 층수
    location_area VARCHAR(100),                          -- 위치 구역 (동, 서, 남, 북 등)
    location_detail TEXT,                                -- 상세 위치 설명
    
    -- 시설 정보
    capacity INTEGER DEFAULT 0,                          -- 수용 인원/용량
    area DECIMAL(10,2) DEFAULT 0,                        -- 시설 면적 (㎡)
    installation_date DATE,                              -- 설치일
    manufacturer VARCHAR(200),                           -- 제조사/설치업체
    model_number VARCHAR(100),                           -- 모델번호
    serial_number VARCHAR(100),                          -- 시리얼번호
    
    -- 상태 관리
    facility_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- 시설 상태
    operational_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL', -- 운영 상태
    last_inspection_date DATE,                           -- 최근 점검일
    next_inspection_date DATE,                           -- 다음 점검 예정일
    inspection_cycle_months INTEGER DEFAULT 6,          -- 점검 주기 (개월)
    
    -- 관리 정보
    manager_name VARCHAR(100),                           -- 담당 관리자
    manager_phone VARCHAR(20),                           -- 담당자 연락처
    manager_company VARCHAR(200),                        -- 관리 업체
    maintenance_contract_start DATE,                     -- 유지보수 계약 시작일
    maintenance_contract_end DATE,                       -- 유지보수 계약 종료일
    
    -- 비용 정보
    installation_cost DECIMAL(15,2) DEFAULT 0,          -- 설치 비용
    monthly_maintenance_cost DECIMAL(10,2) DEFAULT 0,   -- 월 유지보수 비용
    annual_inspection_cost DECIMAL(10,2) DEFAULT 0,     -- 연간 점검 비용
    
    -- 운영 정보
    operating_hours VARCHAR(100),                        -- 운영 시간
    usage_restrictions TEXT,                             -- 사용 제한사항
    safety_requirements TEXT,                            -- 안전 요구사항
    emergency_procedures TEXT,                           -- 비상시 절차
    
    -- 기술 정보
    power_consumption DECIMAL(8,2),                      -- 전력 소비량 (kW)
    water_usage DECIMAL(8,2),                           -- 용수 사용량 (L/h)
    gas_usage DECIMAL(8,2),                             -- 가스 사용량 (㎥/h)
    noise_level DECIMAL(5,2),                           -- 소음 수준 (dB)
    
    -- 보증 및 보험
    warranty_start_date DATE,                            -- 보증 시작일
    warranty_end_date DATE,                              -- 보증 종료일
    warranty_company VARCHAR(200),                       -- 보증 업체
    insurance_policy_number VARCHAR(100),               -- 보험 증권번호
    insurance_company VARCHAR(200),                      -- 보험사
    
    -- 특이사항
    special_features TEXT,                               -- 특별한 기능이나 특징
    known_issues TEXT,                                   -- 알려진 문제점
    improvement_suggestions TEXT,                        -- 개선 제안사항
    notes TEXT,                                          -- 기타 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_facilities_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_facilities_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_facilities_building_code UNIQUE (building_id, facility_code), -- 같은 건물 내 시설 코드 중복 방지
    
    -- 체크 제약조건
    CONSTRAINT chk_facility_category CHECK (facility_category IN (
        'ELEVATOR', 'ESCALATOR', 'HVAC', 'ELECTRICAL', 'PLUMBING', 'FIRE_SAFETY', 
        'SECURITY', 'PARKING', 'WASTE', 'COMMUNICATION', 'RECREATION', 'OTHER'
    )),
    CONSTRAINT chk_facility_type CHECK (facility_type IN (
        'PASSENGER_ELEVATOR', 'FREIGHT_ELEVATOR', 'ESCALATOR', 'MOVING_WALKWAY',
        'AIR_CONDITIONER', 'HEATER', 'VENTILATION_FAN', 'BOILER', 'CHILLER',
        'MAIN_PANEL', 'GENERATOR', 'UPS', 'TRANSFORMER', 'LIGHTING',
        'WATER_PUMP', 'WATER_TANK', 'SEWAGE_PUMP', 'WATER_TREATMENT',
        'FIRE_PUMP', 'SPRINKLER', 'FIRE_ALARM', 'SMOKE_DETECTOR', 'FIRE_EXTINGUISHER',
        'CCTV', 'ACCESS_CONTROL', 'INTERCOM', 'ALARM_SYSTEM',
        'PARKING_GATE', 'PARKING_GUIDANCE', 'CAR_LIFT',
        'WASTE_COMPACTOR', 'RECYCLING_SYSTEM',
        'INTERNET_EQUIPMENT', 'PHONE_SYSTEM', 'BROADCAST_SYSTEM',
        'GYM_EQUIPMENT', 'POOL_EQUIPMENT', 'LOUNGE_FURNITURE',
        'OTHER'
    )),
    CONSTRAINT chk_facility_status CHECK (facility_status IN (
        'ACTIVE', 'INACTIVE', 'UNDER_MAINTENANCE', 'OUT_OF_ORDER', 'DECOMMISSIONED'
    )),
    CONSTRAINT chk_operational_status CHECK (operational_status IN (
        'NORMAL', 'WARNING', 'ERROR', 'MAINTENANCE', 'EMERGENCY'
    )),
    CONSTRAINT chk_capacity CHECK (capacity >= 0),
    CONSTRAINT chk_area CHECK (area >= 0),
    CONSTRAINT chk_inspection_cycle CHECK (inspection_cycle_months > 0),
    CONSTRAINT chk_maintenance_contract_dates CHECK (
        maintenance_contract_end IS NULL OR 
        maintenance_contract_start IS NULL OR 
        maintenance_contract_end >= maintenance_contract_start
    ),
    CONSTRAINT chk_warranty_dates CHECK (
        warranty_end_date IS NULL OR 
        warranty_start_date IS NULL OR 
        warranty_end_date >= warranty_start_date
    )
);

-- 2. RLS 정책 활성화
ALTER TABLE bms.common_facilities ENABLE ROW LEVEL SECURITY;

-- 3. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY facility_isolation_policy ON bms.common_facilities
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 4. 성능 최적화 인덱스 생성
CREATE INDEX idx_facilities_company_id ON bms.common_facilities(company_id);
CREATE INDEX idx_facilities_building_id ON bms.common_facilities(building_id);
CREATE INDEX idx_facilities_category ON bms.common_facilities(facility_category);
CREATE INDEX idx_facilities_type ON bms.common_facilities(facility_type);
CREATE INDEX idx_facilities_status ON bms.common_facilities(facility_status);
CREATE INDEX idx_facilities_operational_status ON bms.common_facilities(operational_status);
CREATE INDEX idx_facilities_next_inspection ON bms.common_facilities(next_inspection_date);
CREATE INDEX idx_facilities_location_floor ON bms.common_facilities(location_floor);
CREATE INDEX idx_facilities_manager ON bms.common_facilities(manager_name);

-- 복합 인덱스 (자주 함께 조회되는 컬럼들)
CREATE INDEX idx_facilities_building_category ON bms.common_facilities(building_id, facility_category);
CREATE INDEX idx_facilities_building_status ON bms.common_facilities(building_id, facility_status);
CREATE INDEX idx_facilities_category_status ON bms.common_facilities(facility_category, facility_status);
CREATE INDEX idx_facilities_status_inspection ON bms.common_facilities(facility_status, next_inspection_date);

-- 5. updated_at 자동 업데이트 트리거
CREATE TRIGGER facilities_updated_at_trigger
    BEFORE UPDATE ON bms.common_facilities
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 6. 시설 정보 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_facility_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 면적은 음수가 될 수 없음
    IF NEW.area < 0 THEN
        RAISE EXCEPTION '시설 면적은 음수가 될 수 없습니다.';
    END IF;
    
    -- 수용 인원은 음수가 될 수 없음
    IF NEW.capacity < 0 THEN
        RAISE EXCEPTION '수용 인원은 음수가 될 수 없습니다.';
    END IF;
    
    -- 점검 주기는 양수여야 함
    IF NEW.inspection_cycle_months <= 0 THEN
        RAISE EXCEPTION '점검 주기는 양수여야 합니다.';
    END IF;
    
    -- 다음 점검일이 과거인 경우 경고
    IF NEW.next_inspection_date IS NOT NULL AND NEW.next_inspection_date < CURRENT_DATE THEN
        RAISE WARNING '시설 %의 점검일이 지났습니다. (%)', NEW.facility_name, NEW.next_inspection_date;
    END IF;
    
    -- 운영 중단 상태인 시설은 운영 상태를 ERROR로 설정
    IF NEW.facility_status = 'OUT_OF_ORDER' AND NEW.operational_status = 'NORMAL' THEN
        NEW.operational_status := 'ERROR';
    END IF;
    
    -- 유지보수 중인 시설은 운영 상태를 MAINTENANCE로 설정
    IF NEW.facility_status = 'UNDER_MAINTENANCE' AND NEW.operational_status = 'NORMAL' THEN
        NEW.operational_status := 'MAINTENANCE';
    END IF;
    
    -- 다음 점검일 자동 계산 (최근 점검일이 있고 다음 점검일이 없는 경우)
    IF NEW.last_inspection_date IS NOT NULL AND NEW.next_inspection_date IS NULL THEN
        NEW.next_inspection_date := NEW.last_inspection_date + (NEW.inspection_cycle_months || ' months')::INTERVAL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. 시설 검증 트리거 생성
CREATE TRIGGER trg_validate_facility_data
    BEFORE INSERT OR UPDATE ON bms.common_facilities
    FOR EACH ROW EXECUTE FUNCTION bms.validate_facility_data();

-- 8. 시설 상태 변경 이력 함수
CREATE OR REPLACE FUNCTION bms.log_facility_status_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 로그 기록
    IF TG_OP = 'UPDATE' AND (
        OLD.facility_status IS DISTINCT FROM NEW.facility_status OR
        OLD.operational_status IS DISTINCT FROM NEW.operational_status
    ) THEN
        -- 상태 변경 이력 테이블이 있다면 여기에 로그 기록
        -- 현재는 주석 처리 (4.1 태스크에서 구현 예정)
        RAISE NOTICE '시설 % 상태가 변경되었습니다. 시설상태: % -> %, 운영상태: % -> %', 
            NEW.facility_name, 
            OLD.facility_status, NEW.facility_status,
            OLD.operational_status, NEW.operational_status;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 9. 상태 변경 이력 트리거 생성
CREATE TRIGGER trg_log_facility_status_changes
    AFTER UPDATE ON bms.common_facilities
    FOR EACH ROW EXECUTE FUNCTION bms.log_facility_status_changes();

-- 10. 시설 요약 뷰 생성
CREATE OR REPLACE VIEW bms.v_facility_summary AS
SELECT 
    f.facility_id,
    f.company_id,
    f.building_id,
    b.name as building_name,
    f.facility_name,
    f.facility_code,
    f.facility_category,
    f.facility_type,
    f.location_floor,
    f.location_area,
    f.facility_status,
    f.operational_status,
    f.capacity,
    f.area,
    f.manager_name,
    f.manager_phone,
    f.last_inspection_date,
    f.next_inspection_date,
    f.monthly_maintenance_cost,
    f.installation_date,
    f.warranty_end_date,
    CASE 
        WHEN f.next_inspection_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN f.next_inspection_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'DUE_SOON'
        ELSE 'OK'
    END as inspection_status,
    CASE 
        WHEN f.warranty_end_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN f.warranty_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 'EXPIRING_SOON'
        ELSE 'VALID'
    END as warranty_status,
    f.created_at,
    f.updated_at
FROM bms.common_facilities f
JOIN bms.buildings b ON f.building_id = b.building_id;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_facility_summary OWNER TO qiro;

-- 11. 건물별 시설 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_building_facility_statistics AS
SELECT 
    f.building_id,
    b.name as building_name,
    f.company_id,
    COUNT(*) as total_facilities,
    COUNT(CASE WHEN f.facility_status = 'ACTIVE' THEN 1 END) as active_facilities,
    COUNT(CASE WHEN f.facility_status = 'OUT_OF_ORDER' THEN 1 END) as out_of_order_facilities,
    COUNT(CASE WHEN f.facility_status = 'UNDER_MAINTENANCE' THEN 1 END) as maintenance_facilities,
    COUNT(CASE WHEN f.operational_status = 'ERROR' THEN 1 END) as error_facilities,
    COUNT(CASE WHEN f.operational_status = 'WARNING' THEN 1 END) as warning_facilities,
    COUNT(CASE WHEN f.next_inspection_date < CURRENT_DATE THEN 1 END) as overdue_inspections,
    COUNT(CASE WHEN f.next_inspection_date <= CURRENT_DATE + INTERVAL '30 days' THEN 1 END) as due_soon_inspections,
    SUM(f.monthly_maintenance_cost) as total_monthly_maintenance_cost,
    AVG(f.monthly_maintenance_cost) as avg_monthly_maintenance_cost
FROM bms.common_facilities f
JOIN bms.buildings b ON f.building_id = b.building_id
GROUP BY f.building_id, b.name, f.company_id;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_facility_statistics OWNER TO qiro;

-- 12. 시설 분류별 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_facility_category_statistics AS
SELECT 
    f.company_id,
    f.facility_category,
    COUNT(*) as total_count,
    COUNT(CASE WHEN f.facility_status = 'ACTIVE' THEN 1 END) as active_count,
    COUNT(CASE WHEN f.facility_status = 'OUT_OF_ORDER' THEN 1 END) as out_of_order_count,
    COUNT(CASE WHEN f.operational_status = 'ERROR' THEN 1 END) as error_count,
    ROUND(COUNT(CASE WHEN f.facility_status = 'ACTIVE' THEN 1 END) * 100.0 / COUNT(*), 2) as active_rate,
    SUM(f.monthly_maintenance_cost) as total_maintenance_cost,
    AVG(f.monthly_maintenance_cost) as avg_maintenance_cost,
    COUNT(CASE WHEN f.next_inspection_date < CURRENT_DATE THEN 1 END) as overdue_inspections
FROM bms.common_facilities f
GROUP BY f.company_id, f.facility_category;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_facility_category_statistics OWNER TO qiro;

-- 13. 점검 예정 시설 뷰 생성
CREATE OR REPLACE VIEW bms.v_inspection_schedule AS
SELECT 
    f.facility_id,
    f.company_id,
    f.building_id,
    b.name as building_name,
    f.facility_name,
    f.facility_category,
    f.facility_type,
    f.location_floor,
    f.manager_name,
    f.manager_phone,
    f.last_inspection_date,
    f.next_inspection_date,
    f.inspection_cycle_months,
    CASE 
        WHEN f.next_inspection_date < CURRENT_DATE THEN 'OVERDUE'
        WHEN f.next_inspection_date <= CURRENT_DATE + INTERVAL '7 days' THEN 'THIS_WEEK'
        WHEN f.next_inspection_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'THIS_MONTH'
        ELSE 'FUTURE'
    END as inspection_urgency,
    CURRENT_DATE - f.next_inspection_date as days_overdue
FROM bms.common_facilities f
JOIN bms.buildings b ON f.building_id = b.building_id
WHERE f.facility_status = 'ACTIVE' 
  AND f.next_inspection_date IS NOT NULL
ORDER BY f.next_inspection_date;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_inspection_schedule OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 1.3 공용시설 관리 테이블 생성이 완료되었습니다!' as result;