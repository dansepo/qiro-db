-- 시설물 자산 관리 테이블 생성
-- 건물 내 모든 시설물과 장비의 정보를 관리하는 테이블

CREATE TABLE IF NOT EXISTS bms.facility_assets (
    asset_id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    asset_code VARCHAR(50) NOT NULL UNIQUE COMMENT '자산 코드 (고유 식별자)',
    asset_name VARCHAR(200) NOT NULL COMMENT '자산명',
    asset_category VARCHAR(50) NOT NULL COMMENT '자산 분류 (전기, 기계, 소방, 승강기 등)',
    asset_type VARCHAR(100) COMMENT '자산 유형 (세부 분류)',
    
    -- 제품 정보
    manufacturer VARCHAR(100) COMMENT '제조사',
    model_name VARCHAR(100) COMMENT '모델명',
    serial_number VARCHAR(100) COMMENT '시리얼 번호',
    
    -- 위치 정보
    location VARCHAR(200) NOT NULL COMMENT '설치 위치',
    building_id BIGINT NOT NULL COMMENT '건물 ID (외래키)',
    floor_number INTEGER COMMENT '층수',
    
    -- 구매 및 설치 정보
    purchase_date DATE COMMENT '구매일자',
    purchase_amount DECIMAL(15,2) COMMENT '구매 금액',
    installation_date DATE COMMENT '설치일자',
    
    -- 보증 정보
    warranty_start_date DATE COMMENT '보증 시작일',
    warranty_end_date DATE COMMENT '보증 종료일',
    
    -- 상태 정보
    asset_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL' COMMENT '자산 상태 (NORMAL, INSPECTION_REQUIRED, UNDER_REPAIR, OUT_OF_ORDER, DISPOSED, RESERVED)',
    usage_status VARCHAR(20) NOT NULL DEFAULT 'IN_USE' COMMENT '사용 상태 (IN_USE, NOT_IN_USE, STANDBY, MAINTENANCE)',
    importance_level VARCHAR(10) NOT NULL DEFAULT 'MEDIUM' COMMENT '중요도 (HIGH, MEDIUM, LOW)',
    
    -- 정비 정보
    maintenance_cycle_days INTEGER COMMENT '정기 점검 주기 (일 단위)',
    last_maintenance_date DATE COMMENT '마지막 점검일',
    next_maintenance_date DATE COMMENT '다음 점검 예정일',
    
    -- 기타 정보
    description TEXT COMMENT '설명/메모',
    manager_id BIGINT COMMENT '담당자 ID',
    
    -- 시스템 정보
    is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT '활성 상태',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일시',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일시',
    created_by BIGINT COMMENT '생성자 ID',
    updated_by BIGINT COMMENT '수정자 ID',
    
    -- 제약 조건
    CONSTRAINT chk_asset_status CHECK (asset_status IN ('NORMAL', 'INSPECTION_REQUIRED', 'UNDER_REPAIR', 'OUT_OF_ORDER', 'DISPOSED', 'RESERVED')),
    CONSTRAINT chk_usage_status CHECK (usage_status IN ('IN_USE', 'NOT_IN_USE', 'STANDBY', 'MAINTENANCE')),
    CONSTRAINT chk_importance_level CHECK (importance_level IN ('HIGH', 'MEDIUM', 'LOW')),
    CONSTRAINT chk_warranty_dates CHECK (warranty_end_date IS NULL OR warranty_start_date IS NULL OR warranty_end_date >= warranty_start_date),
    CONSTRAINT chk_purchase_install_dates CHECK (installation_date IS NULL OR purchase_date IS NULL OR installation_date >= purchase_date),
    CONSTRAINT chk_maintenance_cycle CHECK (maintenance_cycle_days IS NULL OR maintenance_cycle_days > 0)
);

-- 인덱스 생성
CREATE INDEX idx_facility_assets_asset_code ON bms.facility_assets(asset_code);
CREATE INDEX idx_facility_assets_building_id ON bms.facility_assets(building_id);
CREATE INDEX idx_facility_assets_asset_category ON bms.facility_assets(asset_category);
CREATE INDEX idx_facility_assets_asset_status ON bms.facility_assets(asset_status);
CREATE INDEX idx_facility_assets_usage_status ON bms.facility_assets(usage_status);
CREATE INDEX idx_facility_assets_importance_level ON bms.facility_assets(importance_level);
CREATE INDEX idx_facility_assets_location ON bms.facility_assets(location);
CREATE INDEX idx_facility_assets_manager_id ON bms.facility_assets(manager_id);
CREATE INDEX idx_facility_assets_warranty_end_date ON bms.facility_assets(warranty_end_date);
CREATE INDEX idx_facility_assets_next_maintenance_date ON bms.facility_assets(next_maintenance_date);
CREATE INDEX idx_facility_assets_serial_number ON bms.facility_assets(serial_number);
CREATE INDEX idx_facility_assets_is_active ON bms.facility_assets(is_active);
CREATE INDEX idx_facility_assets_created_at ON bms.facility_assets(created_at);

-- 복합 인덱스
CREATE INDEX idx_facility_assets_building_floor ON bms.facility_assets(building_id, floor_number);
CREATE INDEX idx_facility_assets_category_status ON bms.facility_assets(asset_category, asset_status);
CREATE INDEX idx_facility_assets_active_status ON bms.facility_assets(is_active, asset_status);

-- 전문 검색을 위한 인덱스 (PostgreSQL의 경우)
-- CREATE INDEX idx_facility_assets_search ON bms.facility_assets USING gin(to_tsvector('korean', asset_name || ' ' || COALESCE(location, '') || ' ' || COALESCE(manufacturer, '') || ' ' || COALESCE(model_name, '')));

-- 테이블 코멘트
COMMENT ON TABLE bms.facility_assets IS '시설물 자산 관리 테이블 - 건물 내 모든 시설물과 장비의 정보를 관리';

-- 컬럼 코멘트
COMMENT ON COLUMN bms.facility_assets.asset_id IS '자산 ID (기본키)';
COMMENT ON COLUMN bms.facility_assets.asset_code IS '자산 코드 (고유 식별자)';
COMMENT ON COLUMN bms.facility_assets.asset_name IS '자산명';
COMMENT ON COLUMN bms.facility_assets.asset_category IS '자산 분류 (전기, 기계, 소방, 승강기 등)';
COMMENT ON COLUMN bms.facility_assets.asset_type IS '자산 유형 (세부 분류)';
COMMENT ON COLUMN bms.facility_assets.manufacturer IS '제조사';
COMMENT ON COLUMN bms.facility_assets.model_name IS '모델명';
COMMENT ON COLUMN bms.facility_assets.serial_number IS '시리얼 번호';
COMMENT ON COLUMN bms.facility_assets.location IS '설치 위치';
COMMENT ON COLUMN bms.facility_assets.building_id IS '건물 ID (외래키)';
COMMENT ON COLUMN bms.facility_assets.floor_number IS '층수';
COMMENT ON COLUMN bms.facility_assets.purchase_date IS '구매일자';
COMMENT ON COLUMN bms.facility_assets.purchase_amount IS '구매 금액';
COMMENT ON COLUMN bms.facility_assets.installation_date IS '설치일자';
COMMENT ON COLUMN bms.facility_assets.warranty_start_date IS '보증 시작일';
COMMENT ON COLUMN bms.facility_assets.warranty_end_date IS '보증 종료일';
COMMENT ON COLUMN bms.facility_assets.asset_status IS '자산 상태';
COMMENT ON COLUMN bms.facility_assets.usage_status IS '사용 상태';
COMMENT ON COLUMN bms.facility_assets.importance_level IS '중요도';
COMMENT ON COLUMN bms.facility_assets.maintenance_cycle_days IS '정기 점검 주기 (일 단위)';
COMMENT ON COLUMN bms.facility_assets.last_maintenance_date IS '마지막 점검일';
COMMENT ON COLUMN bms.facility_assets.next_maintenance_date IS '다음 점검 예정일';
COMMENT ON COLUMN bms.facility_assets.description IS '설명/메모';
COMMENT ON COLUMN bms.facility_assets.manager_id IS '담당자 ID';
COMMENT ON COLUMN bms.facility_assets.is_active IS '활성 상태';
COMMENT ON COLUMN bms.facility_assets.created_at IS '생성일시';
COMMENT ON COLUMN bms.facility_assets.updated_at IS '수정일시';
COMMENT ON COLUMN bms.facility_assets.created_by IS '생성자 ID';
COMMENT ON COLUMN bms.facility_assets.updated_by IS '수정자 ID';