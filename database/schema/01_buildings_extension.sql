-- =====================================================
-- 건물 상세 정보 테이블 확장 스크립트
-- Phase 1.1: 건물 상세 정보 테이블 확장
-- =====================================================

-- 기존 buildings 테이블에 상세 정보 컬럼 추가
ALTER TABLE bms.buildings 
ADD COLUMN IF NOT EXISTS address_detail VARCHAR(500),           -- 상세 주소
ADD COLUMN IF NOT EXISTS postal_code VARCHAR(10),               -- 우편번호
ADD COLUMN IF NOT EXISTS building_type VARCHAR(50),             -- 건물 타입 (오피스, 상가, 주거 등)
ADD COLUMN IF NOT EXISTS total_floors INTEGER,                  -- 총 층수
ADD COLUMN IF NOT EXISTS basement_floors INTEGER DEFAULT 0,     -- 지하 층수
ADD COLUMN IF NOT EXISTS total_area DECIMAL(12,2),             -- 총 면적 (㎡)
ADD COLUMN IF NOT EXISTS construction_date DATE,                -- 준공일
ADD COLUMN IF NOT EXISTS building_status VARCHAR(20) DEFAULT 'ACTIVE', -- 건물 상태
ADD COLUMN IF NOT EXISTS management_office_name VARCHAR(200),   -- 관리사무소명
ADD COLUMN IF NOT EXISTS management_office_phone VARCHAR(20),   -- 관리사무소 전화번호
ADD COLUMN IF NOT EXISTS manager_name VARCHAR(100),            -- 관리인 이름
ADD COLUMN IF NOT EXISTS manager_phone VARCHAR(20),            -- 관리인 전화번호
ADD COLUMN IF NOT EXISTS manager_email VARCHAR(100),           -- 관리인 이메일
ADD COLUMN IF NOT EXISTS has_elevator BOOLEAN DEFAULT false,    -- 엘리베이터 유무
ADD COLUMN IF NOT EXISTS elevator_count INTEGER DEFAULT 0,      -- 엘리베이터 개수
ADD COLUMN IF NOT EXISTS has_parking BOOLEAN DEFAULT false,     -- 주차장 유무
ADD COLUMN IF NOT EXISTS parking_spaces INTEGER DEFAULT 0,      -- 주차 공간 수
ADD COLUMN IF NOT EXISTS has_security BOOLEAN DEFAULT false,    -- 보안 시설 유무
ADD COLUMN IF NOT EXISTS security_system VARCHAR(100),         -- 보안 시스템 종류
ADD COLUMN IF NOT EXISTS heating_system VARCHAR(50),           -- 난방 시스템
ADD COLUMN IF NOT EXISTS water_supply_system VARCHAR(50),      -- 급수 시스템
ADD COLUMN IF NOT EXISTS fire_safety_grade VARCHAR(10),        -- 소방 안전 등급
ADD COLUMN IF NOT EXISTS energy_efficiency_grade VARCHAR(10),  -- 에너지 효율 등급
ADD COLUMN IF NOT EXISTS maintenance_fee_base DECIMAL(15,2) DEFAULT 0, -- 기본 관리비
ADD COLUMN IF NOT EXISTS common_area_ratio DECIMAL(5,2),       -- 공용면적 비율
ADD COLUMN IF NOT EXISTS land_area DECIMAL(12,2),              -- 대지 면적
ADD COLUMN IF NOT EXISTS building_coverage_ratio DECIMAL(5,2), -- 건폐율
ADD COLUMN IF NOT EXISTS floor_area_ratio DECIMAL(5,2),        -- 용적률
ADD COLUMN IF NOT EXISTS building_permit_number VARCHAR(50),   -- 건축 허가번호
ADD COLUMN IF NOT EXISTS completion_approval_number VARCHAR(50), -- 사용승인번호
ADD COLUMN IF NOT EXISTS property_tax_standard DECIMAL(15,2),  -- 재산세 과세표준
ADD COLUMN IF NOT EXISTS building_insurance_info TEXT,         -- 건물 보험 정보
ADD COLUMN IF NOT EXISTS special_notes TEXT,                   -- 특이사항
ADD COLUMN IF NOT EXISTS last_renovation_date DATE,            -- 최근 리모델링 일자
ADD COLUMN IF NOT EXISTS next_inspection_date DATE;            -- 다음 점검 예정일

-- 건물 상태 체크 제약조건 추가
ALTER TABLE bms.buildings 
ADD CONSTRAINT chk_building_status 
CHECK (building_status IN ('ACTIVE', 'INACTIVE', 'UNDER_CONSTRUCTION', 'UNDER_RENOVATION', 'DEMOLISHED'));

-- 건물 타입 체크 제약조건 추가
ALTER TABLE bms.buildings 
ADD CONSTRAINT chk_building_type 
CHECK (building_type IN ('OFFICE', 'COMMERCIAL', 'RESIDENTIAL', 'MIXED_USE', 'INDUSTRIAL', 'WAREHOUSE', 'OTHER'));

-- 난방 시스템 체크 제약조건 추가
ALTER TABLE bms.buildings 
ADD CONSTRAINT chk_heating_system 
CHECK (heating_system IN ('CENTRAL', 'INDIVIDUAL', 'DISTRICT', 'ELECTRIC', 'GAS', 'OTHER'));

-- 급수 시스템 체크 제약조건 추가
ALTER TABLE bms.buildings 
ADD CONSTRAINT chk_water_supply_system 
CHECK (water_supply_system IN ('DIRECT', 'TANK', 'BOOSTER_PUMP', 'PRESSURE_TANK', 'OTHER'));

-- 성능 최적화를 위한 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_buildings_building_type ON bms.buildings(building_type);
CREATE INDEX IF NOT EXISTS idx_buildings_building_status ON bms.buildings(building_status);
CREATE INDEX IF NOT EXISTS idx_buildings_construction_date ON bms.buildings(construction_date);
CREATE INDEX IF NOT EXISTS idx_buildings_total_area ON bms.buildings(total_area);
CREATE INDEX IF NOT EXISTS idx_buildings_postal_code ON bms.buildings(postal_code);
CREATE INDEX IF NOT EXISTS idx_buildings_next_inspection_date ON bms.buildings(next_inspection_date);

-- 복합 인덱스 (자주 함께 조회되는 컬럼들)
CREATE INDEX IF NOT EXISTS idx_buildings_type_status ON bms.buildings(building_type, building_status);
CREATE INDEX IF NOT EXISTS idx_buildings_company_type ON bms.buildings(company_id, building_type);

-- 건물 상세 정보 뷰 생성 (자주 사용되는 정보들을 조합)
CREATE OR REPLACE VIEW bms.v_building_summary AS
SELECT 
    b.id,
    b.company_id,
    b.name,
    b.address_detail,
    b.postal_code,
    b.building_type,
    b.building_status,
    b.total_floors,
    b.basement_floors,
    b.total_area,
    b.construction_date,
    b.management_office_name,
    b.manager_name,
    b.manager_phone,
    b.has_elevator,
    b.elevator_count,
    b.has_parking,
    b.parking_spaces,
    b.maintenance_fee_base,
    b.next_inspection_date,
    b.created_at,
    b.updated_at,
    c.name as company_name
FROM bms.buildings b
JOIN bms.companies c ON b.company_id = c.id
WHERE b.building_status = 'ACTIVE';

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_summary OWNER TO qiro;

-- 건물 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_building_statistics AS
SELECT 
    company_id,
    COUNT(*) as total_buildings,
    COUNT(CASE WHEN building_status = 'ACTIVE' THEN 1 END) as active_buildings,
    COUNT(CASE WHEN building_type = 'OFFICE' THEN 1 END) as office_buildings,
    COUNT(CASE WHEN building_type = 'COMMERCIAL' THEN 1 END) as commercial_buildings,
    COUNT(CASE WHEN building_type = 'RESIDENTIAL' THEN 1 END) as residential_buildings,
    COUNT(CASE WHEN building_type = 'MIXED_USE' THEN 1 END) as mixed_use_buildings,
    SUM(total_area) as total_area_sum,
    AVG(total_area) as avg_area,
    SUM(parking_spaces) as total_parking_spaces,
    COUNT(CASE WHEN has_elevator = true THEN 1 END) as buildings_with_elevator,
    COUNT(CASE WHEN has_parking = true THEN 1 END) as buildings_with_parking,
    COUNT(CASE WHEN has_security = true THEN 1 END) as buildings_with_security
FROM bms.buildings
GROUP BY company_id;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_statistics OWNER TO qiro;

-- 건물 정보 검증 함수 생성
CREATE OR REPLACE FUNCTION bms.validate_building_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 총 층수는 양수여야 함
    IF NEW.total_floors IS NOT NULL AND NEW.total_floors <= 0 THEN
        RAISE EXCEPTION '총 층수는 양수여야 합니다.';
    END IF;
    
    -- 지하 층수는 음수가 될 수 없음
    IF NEW.basement_floors IS NOT NULL AND NEW.basement_floors < 0 THEN
        RAISE EXCEPTION '지하 층수는 음수가 될 수 없습니다.';
    END IF;
    
    -- 총 면적은 양수여야 함
    IF NEW.total_area IS NOT NULL AND NEW.total_area <= 0 THEN
        RAISE EXCEPTION '총 면적은 양수여야 합니다.';
    END IF;
    
    -- 엘리베이터 개수는 엘리베이터가 있을 때만 양수
    IF NEW.has_elevator = false AND NEW.elevator_count > 0 THEN
        RAISE EXCEPTION '엘리베이터가 없는 건물의 엘리베이터 개수는 0이어야 합니다.';
    END IF;
    
    -- 주차 공간 수는 주차장이 있을 때만 양수
    IF NEW.has_parking = false AND NEW.parking_spaces > 0 THEN
        RAISE EXCEPTION '주차장이 없는 건물의 주차 공간 수는 0이어야 합니다.';
    END IF;
    
    -- 준공일은 미래 날짜가 될 수 없음
    IF NEW.construction_date IS NOT NULL AND NEW.construction_date > CURRENT_DATE THEN
        RAISE EXCEPTION '준공일은 미래 날짜가 될 수 없습니다.';
    END IF;
    
    -- 이메일 형식 검증
    IF NEW.manager_email IS NOT NULL AND NEW.manager_email !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        RAISE EXCEPTION '올바른 이메일 형식이 아닙니다.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
DROP TRIGGER IF EXISTS trg_validate_building_data ON bms.buildings;
CREATE TRIGGER trg_validate_building_data
    BEFORE INSERT OR UPDATE ON bms.buildings
    FOR EACH ROW EXECUTE FUNCTION bms.validate_building_data();

-- 건물 정보 변경 이력을 위한 트리거 함수
CREATE OR REPLACE FUNCTION bms.log_building_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- 중요한 정보가 변경된 경우에만 로그 기록
    IF TG_OP = 'UPDATE' AND (
        OLD.name IS DISTINCT FROM NEW.name OR
        OLD.address_detail IS DISTINCT FROM NEW.address_detail OR
        OLD.building_type IS DISTINCT FROM NEW.building_type OR
        OLD.building_status IS DISTINCT FROM NEW.building_status OR
        OLD.total_area IS DISTINCT FROM NEW.total_area OR
        OLD.manager_name IS DISTINCT FROM NEW.manager_name OR
        OLD.manager_phone IS DISTINCT FROM NEW.manager_phone
    ) THEN
        -- 변경 이력 테이블이 있다면 여기에 로그 기록
        -- 현재는 주석 처리 (4.1 태스크에서 구현 예정)
        -- INSERT INTO bms.building_change_logs ...
        NULL;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 변경 이력 트리거 생성
DROP TRIGGER IF EXISTS trg_log_building_changes ON bms.buildings;
CREATE TRIGGER trg_log_building_changes
    AFTER INSERT OR UPDATE OR DELETE ON bms.buildings
    FOR EACH ROW EXECUTE FUNCTION bms.log_building_changes();

-- 테스트 데이터 업데이트 (기존 건물 데이터에 상세 정보 추가)
UPDATE bms.buildings 
SET 
    address_detail = name || ' 상세주소',
    postal_code = '12345',
    building_type = 'OFFICE',
    total_floors = 10,
    basement_floors = 2,
    total_area = 5000.00,
    construction_date = '2020-01-01',
    building_status = 'ACTIVE',
    management_office_name = name || ' 관리사무소',
    management_office_phone = '02-1234-5678',
    manager_name = '김관리',
    manager_phone = '010-1234-5678',
    manager_email = 'manager@example.com',
    has_elevator = true,
    elevator_count = 2,
    has_parking = true,
    parking_spaces = 50,
    has_security = true,
    security_system = 'CCTV, 출입통제시스템',
    heating_system = 'CENTRAL',
    water_supply_system = 'DIRECT',
    fire_safety_grade = 'A',
    energy_efficiency_grade = '1',
    maintenance_fee_base = 100000.00,
    common_area_ratio = 25.5,
    next_inspection_date = CURRENT_DATE + INTERVAL '6 months'
WHERE company_id IN (1, 2); -- 테스트 회사들만 업데이트

-- 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.buildings;

-- 완료 메시지
SELECT '건물 상세 정보 테이블 확장이 완료되었습니다.' as result;