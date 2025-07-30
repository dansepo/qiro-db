-- =====================================================
-- 건물 및 호실 정보 테이블 설계
-- 요구사항: 1.1, 1.2
-- =====================================================

-- 건물 상태 ENUM 타입 정의
CREATE TYPE building_status AS ENUM (
    'ACTIVE',           -- 운영중
    'UNDER_CONSTRUCTION', -- 건설중
    'MAINTENANCE',      -- 정비중
    'INACTIVE'          -- 비활성
);

-- 호실 상태 ENUM 타입 정의
CREATE TYPE unit_status AS ENUM (
    'AVAILABLE',        -- 임대 가능
    'OCCUPIED',         -- 임대중
    'MAINTENANCE',      -- 정비중
    'UNAVAILABLE'       -- 임대 불가
);

-- 건물 유형 ENUM 타입 정의
CREATE TYPE building_type AS ENUM (
    'APARTMENT',        -- 공동주택
    'COMMERCIAL',       -- 상업용 건물
    'MIXED_USE',        -- 복합용도
    'OFFICE',           -- 사무용 건물
    'RETAIL',           -- 소매용 건물
    'WAREHOUSE'         -- 창고
);

-- 호실 유형 ENUM 타입 정의
CREATE TYPE unit_type AS ENUM (
    'RESIDENTIAL',      -- 주거용
    'COMMERCIAL',       -- 상업용
    'OFFICE',           -- 사무용
    'STORAGE',          -- 창고
    'PARKING',          -- 주차장
    'COMMON_AREA'       -- 공용구역
);

-- =====================================================
-- 건물 정보 테이블 (buildings)
-- =====================================================
CREATE TABLE buildings (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 건물 기본 정보
    name VARCHAR(255) NOT NULL COMMENT '건물명',
    address TEXT NOT NULL COMMENT '건물 주소',
    building_type building_type NOT NULL COMMENT '건물 유형',
    
    -- 건물 규모 정보
    total_floors INTEGER NOT NULL CHECK (total_floors > 0) COMMENT '총 층수',
    basement_floors INTEGER DEFAULT 0 CHECK (basement_floors >= 0) COMMENT '지하 층수',
    total_area DECIMAL(12,2) NOT NULL CHECK (total_area > 0) COMMENT '총 면적(㎡)',
    total_units INTEGER DEFAULT 0 CHECK (total_units >= 0) COMMENT '총 호실 수',
    
    -- 건물 상세 정보
    construction_year INTEGER CHECK (construction_year > 1900 AND construction_year <= EXTRACT(YEAR FROM CURRENT_DATE)) COMMENT '건축년도',
    completion_date DATE COMMENT '준공일',
    building_permit_number VARCHAR(100) COMMENT '건축허가번호',
    
    -- 소유자 정보
    owner_name VARCHAR(255) COMMENT '소유자명',
    owner_contact VARCHAR(100) COMMENT '소유자 연락처',
    owner_business_number VARCHAR(20) COMMENT '소유자 사업자등록번호',
    
    -- 관리 정보
    management_company VARCHAR(255) COMMENT '관리업체명',
    management_contact VARCHAR(100) COMMENT '관리업체 연락처',
    
    -- 상태 및 메타데이터
    status building_status DEFAULT 'ACTIVE' COMMENT '건물 상태',
    description TEXT COMMENT '건물 설명',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID'
);

-- 건물 테이블 인덱스
CREATE INDEX idx_buildings_name ON buildings(name);
CREATE INDEX idx_buildings_type ON buildings(building_type);
CREATE INDEX idx_buildings_status ON buildings(status);
CREATE INDEX idx_buildings_created_at ON buildings(created_at);

-- =====================================================
-- 호실 정보 테이블 (units)
-- =====================================================
CREATE TABLE units (
    -- 기본 식별자
    id BIGSERIAL PRIMARY KEY,
    
    -- 건물 연관 관계
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE COMMENT '건물 ID',
    
    -- 호실 식별 정보
    unit_number VARCHAR(50) NOT NULL COMMENT '호실 번호',
    floor_number INTEGER NOT NULL COMMENT '층수',
    
    -- 호실 상세 정보
    unit_type unit_type NOT NULL COMMENT '호실 유형',
    area DECIMAL(10,2) NOT NULL CHECK (area > 0) COMMENT '전용면적(㎡)',
    common_area DECIMAL(10,2) DEFAULT 0 CHECK (common_area >= 0) COMMENT '공용면적(㎡)',
    total_area DECIMAL(10,2) GENERATED ALWAYS AS (area + common_area) STORED COMMENT '총면적(㎡)',
    
    -- 임대 관련 정보
    monthly_rent DECIMAL(12,2) DEFAULT 0 CHECK (monthly_rent >= 0) COMMENT '월 임대료',
    deposit DECIMAL(12,2) DEFAULT 0 CHECK (deposit >= 0) COMMENT '보증금',
    maintenance_fee DECIMAL(12,2) DEFAULT 0 CHECK (maintenance_fee >= 0) COMMENT '관리비',
    
    -- 호실 상태 및 특성
    status unit_status DEFAULT 'AVAILABLE' COMMENT '호실 상태',
    room_count INTEGER CHECK (room_count >= 0) COMMENT '방 개수',
    bathroom_count INTEGER CHECK (bathroom_count >= 0) COMMENT '화장실 개수',
    has_balcony BOOLEAN DEFAULT false COMMENT '발코니 유무',
    has_parking BOOLEAN DEFAULT false COMMENT '주차장 유무',
    
    -- 시설 정보
    heating_type VARCHAR(50) COMMENT '난방 방식',
    air_conditioning BOOLEAN DEFAULT false COMMENT '에어컨 유무',
    elevator_access BOOLEAN DEFAULT false COMMENT '엘리베이터 접근 가능',
    
    -- 메타데이터
    description TEXT COMMENT '호실 설명',
    special_notes TEXT COMMENT '특이사항',
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID',
    
    -- 제약조건
    CONSTRAINT uk_building_unit_number UNIQUE (building_id, unit_number)
);

-- 호실 테이블 인덱스
CREATE INDEX idx_units_building_id ON units(building_id);
CREATE INDEX idx_units_floor_number ON units(floor_number);
CREATE INDEX idx_units_unit_type ON units(unit_type);
CREATE INDEX idx_units_status ON units(status);
CREATE INDEX idx_units_area ON units(area);
CREATE INDEX idx_units_monthly_rent ON units(monthly_rent);

-- =====================================================
-- 건물-호실 관계 제약조건 및 트리거
-- =====================================================

-- 건물의 총 호실 수 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_building_total_units()
RETURNS TRIGGER AS $$
BEGIN
    -- INSERT 또는 DELETE 시 건물의 총 호실 수 업데이트
    IF TG_OP = 'INSERT' THEN
        UPDATE buildings 
        SET total_units = (
            SELECT COUNT(*) 
            FROM units 
            WHERE building_id = NEW.building_id
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.building_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE buildings 
        SET total_units = (
            SELECT COUNT(*) 
            FROM units 
            WHERE building_id = OLD.building_id
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE id = OLD.building_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 호실 수 업데이트 트리거
CREATE TRIGGER trigger_update_building_total_units
    AFTER INSERT OR DELETE ON units
    FOR EACH ROW
    EXECUTE FUNCTION update_building_total_units();

-- updated_at 자동 업데이트 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- buildings 테이블 updated_at 트리거
CREATE TRIGGER trigger_buildings_updated_at
    BEFORE UPDATE ON buildings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- units 테이블 updated_at 트리거
CREATE TRIGGER trigger_units_updated_at
    BEFORE UPDATE ON units
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 데이터 무결성 검증 함수
-- =====================================================

-- 건물 내 호실 번호 중복 검증 함수
CREATE OR REPLACE FUNCTION validate_unit_number_uniqueness()
RETURNS TRIGGER AS $$
BEGIN
    -- 동일 건물 내에서 호실 번호 중복 검사
    IF EXISTS (
        SELECT 1 FROM units 
        WHERE building_id = NEW.building_id 
        AND unit_number = NEW.unit_number 
        AND id != COALESCE(NEW.id, 0)
    ) THEN
        RAISE EXCEPTION '동일 건물 내에 중복된 호실 번호가 존재합니다: %', NEW.unit_number;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 호실 번호 중복 검증 트리거
CREATE TRIGGER trigger_validate_unit_number_uniqueness
    BEFORE INSERT OR UPDATE ON units
    FOR EACH ROW
    EXECUTE FUNCTION validate_unit_number_uniqueness();

-- =====================================================
-- 초기 데이터 및 설정
-- =====================================================

-- 건물 테이블 코멘트
COMMENT ON TABLE buildings IS '건물 기본 정보를 관리하는 테이블';
COMMENT ON TABLE units IS '호실 정보를 관리하는 테이블';

-- 제약조건 코멘트
COMMENT ON CONSTRAINT uk_building_unit_number ON units IS '건물 내 호실 번호 유일성 보장';