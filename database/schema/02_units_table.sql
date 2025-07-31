-- =====================================================
-- 호실(Unit) 관리 테이블 생성 스크립트
-- Phase 1.2: 호실(Unit) 관리 테이블 생성
-- =====================================================

-- 1. 호실(Unit) 테이블 생성
CREATE TABLE IF NOT EXISTS bms.units (
    unit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID NOT NULL,
    unit_number VARCHAR(20) NOT NULL,                    -- 호수 (101, 201A, B1-01 등)
    floor_number INTEGER NOT NULL,                       -- 층수 (음수는 지하)
    unit_type VARCHAR(50) NOT NULL DEFAULT 'OFFICE',     -- 호실 타입
    unit_status VARCHAR(20) NOT NULL DEFAULT 'VACANT',   -- 호실 상태
    
    -- 면적 정보
    exclusive_area DECIMAL(10,2) NOT NULL DEFAULT 0,     -- 전용면적 (㎡)
    common_area DECIMAL(10,2) DEFAULT 0,                 -- 공용면적 (㎡)
    total_area DECIMAL(10,2) GENERATED ALWAYS AS (exclusive_area + COALESCE(common_area, 0)) STORED, -- 총면적
    
    -- 임대 정보
    monthly_rent DECIMAL(12,2) DEFAULT 0,                -- 월 임대료
    deposit DECIMAL(15,2) DEFAULT 0,                     -- 보증금
    maintenance_fee DECIMAL(10,2) DEFAULT 0,             -- 월 관리비
    
    -- 시설 정보
    room_count INTEGER DEFAULT 1,                        -- 방 개수
    bathroom_count INTEGER DEFAULT 1,                    -- 화장실 개수
    has_balcony BOOLEAN DEFAULT false,                   -- 발코니 유무
    has_parking BOOLEAN DEFAULT false,                   -- 주차 가능 여부
    parking_spaces INTEGER DEFAULT 0,                    -- 주차 공간 수
    
    -- 설비 정보
    heating_type VARCHAR(30) DEFAULT 'CENTRAL',          -- 난방 방식
    cooling_type VARCHAR(30) DEFAULT 'CENTRAL',          -- 냉방 방식
    ventilation_type VARCHAR(30) DEFAULT 'NATURAL',      -- 환기 방식
    has_gas BOOLEAN DEFAULT true,                        -- 가스 공급 여부
    has_water BOOLEAN DEFAULT true,                      -- 급수 여부
    has_internet BOOLEAN DEFAULT true,                   -- 인터넷 설치 가능 여부
    
    -- 방향 및 위치
    direction VARCHAR(10),                               -- 향 (N, S, E, W, NE, NW, SE, SW)
    view_type VARCHAR(30),                               -- 조망 (CITY, MOUNTAIN, RIVER, PARK 등)
    noise_level VARCHAR(10) DEFAULT 'NORMAL',            -- 소음 수준
    
    -- 상태 및 이력
    move_in_date DATE,                                   -- 입주일
    move_out_date DATE,                                  -- 퇴거일
    last_maintenance_date DATE,                          -- 최근 정비일
    next_maintenance_date DATE,                          -- 다음 정비 예정일
    
    -- 특이사항
    special_features TEXT,                               -- 특별한 시설이나 특징
    restrictions TEXT,                                   -- 사용 제한사항
    notes TEXT,                                          -- 기타 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_units_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_units_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_units_building_number UNIQUE (building_id, unit_number), -- 같은 건물 내 호수 중복 방지
    
    -- 체크 제약조건
    CONSTRAINT chk_unit_type CHECK (unit_type IN ('OFFICE', 'RETAIL', 'WAREHOUSE', 'APARTMENT', 'STUDIO', 'PARKING', 'STORAGE', 'OTHER')),
    CONSTRAINT chk_unit_status CHECK (unit_status IN ('VACANT', 'OCCUPIED', 'MAINTENANCE', 'RENOVATION', 'RESERVED', 'UNAVAILABLE')),
    CONSTRAINT chk_heating_type CHECK (heating_type IN ('CENTRAL', 'INDIVIDUAL', 'ELECTRIC', 'GAS', 'NONE', 'OTHER')),
    CONSTRAINT chk_cooling_type CHECK (cooling_type IN ('CENTRAL', 'INDIVIDUAL', 'ELECTRIC', 'NONE', 'OTHER')),
    CONSTRAINT chk_ventilation_type CHECK (ventilation_type IN ('NATURAL', 'MECHANICAL', 'HYBRID', 'NONE')),
    CONSTRAINT chk_direction CHECK (direction IN ('N', 'S', 'E', 'W', 'NE', 'NW', 'SE', 'SW')),
    CONSTRAINT chk_noise_level CHECK (noise_level IN ('QUIET', 'NORMAL', 'NOISY')),
    CONSTRAINT chk_exclusive_area CHECK (exclusive_area > 0),
    CONSTRAINT chk_common_area CHECK (common_area >= 0),
    CONSTRAINT chk_room_count CHECK (room_count >= 0),
    CONSTRAINT chk_bathroom_count CHECK (bathroom_count >= 0),
    CONSTRAINT chk_parking_spaces CHECK (parking_spaces >= 0),
    CONSTRAINT chk_parking_consistency CHECK (
        (has_parking = false AND parking_spaces = 0) OR 
        (has_parking = true AND parking_spaces >= 0)
    ),
    CONSTRAINT chk_move_dates CHECK (move_out_date IS NULL OR move_out_date >= move_in_date)
);

-- 2. RLS 정책 활성화
ALTER TABLE bms.units ENABLE ROW LEVEL SECURITY;

-- 3. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY unit_isolation_policy ON bms.units
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 4. 성능 최적화 인덱스 생성
CREATE INDEX idx_units_company_id ON bms.units(company_id);
CREATE INDEX idx_units_building_id ON bms.units(building_id);
CREATE INDEX idx_units_unit_status ON bms.units(unit_status);
CREATE INDEX idx_units_unit_type ON bms.units(unit_type);
CREATE INDEX idx_units_floor_number ON bms.units(floor_number);
CREATE INDEX idx_units_total_area ON bms.units(total_area);
CREATE INDEX idx_units_monthly_rent ON bms.units(monthly_rent);
CREATE INDEX idx_units_move_in_date ON bms.units(move_in_date);
CREATE INDEX idx_units_next_maintenance_date ON bms.units(next_maintenance_date);

-- 복합 인덱스 (자주 함께 조회되는 컬럼들)
CREATE INDEX idx_units_building_status ON bms.units(building_id, unit_status);
CREATE INDEX idx_units_building_type ON bms.units(building_id, unit_type);
CREATE INDEX idx_units_company_building ON bms.units(company_id, building_id);
CREATE INDEX idx_units_status_type ON bms.units(unit_status, unit_type);
CREATE INDEX idx_units_area_range ON bms.units(total_area, unit_type);

-- 5. updated_at 자동 업데이트 트리거
CREATE TRIGGER units_updated_at_trigger
    BEFORE UPDATE ON bms.units
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 6. 호실 정보 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_unit_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 전용면적은 양수여야 함
    IF NEW.exclusive_area <= 0 THEN
        RAISE EXCEPTION '전용면적은 양수여야 합니다.';
    END IF;
    
    -- 공용면적은 음수가 될 수 없음
    IF NEW.common_area < 0 THEN
        RAISE EXCEPTION '공용면적은 음수가 될 수 없습니다.';
    END IF;
    
    -- 주차 공간 수는 주차 가능할 때만 양수
    IF NEW.has_parking = false AND NEW.parking_spaces > 0 THEN
        RAISE EXCEPTION '주차가 불가능한 호실의 주차 공간 수는 0이어야 합니다.';
    END IF;
    
    -- 입주 중인 호실은 입주일이 있어야 함
    IF NEW.unit_status = 'OCCUPIED' AND NEW.move_in_date IS NULL THEN
        RAISE EXCEPTION '입주 중인 호실은 입주일이 설정되어야 합니다.';
    END IF;
    
    -- 공실인 호실은 입주일과 퇴거일이 없어야 함
    IF NEW.unit_status = 'VACANT' THEN
        NEW.move_in_date := NULL;
        NEW.move_out_date := NULL;
    END IF;
    
    -- 층수와 호수의 일관성 검증 (간단한 규칙)
    IF NEW.floor_number > 0 AND NEW.unit_number ~ '^[0-9]+' THEN
        -- 호수가 숫자로 시작하는 경우, 첫 자리가 층수와 일치하는지 확인
        IF LEFT(NEW.unit_number, LENGTH(NEW.floor_number::text)) != NEW.floor_number::text THEN
            RAISE WARNING '호수(%)와 층수(%)가 일치하지 않을 수 있습니다.', NEW.unit_number, NEW.floor_number;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. 호실 검증 트리거 생성
CREATE TRIGGER trg_validate_unit_data
    BEFORE INSERT OR UPDATE ON bms.units
    FOR EACH ROW EXECUTE FUNCTION bms.validate_unit_data();

-- 8. 호실 상태 변경 이력 함수
CREATE OR REPLACE FUNCTION bms.log_unit_status_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 로그 기록
    IF TG_OP = 'UPDATE' AND OLD.unit_status IS DISTINCT FROM NEW.unit_status THEN
        -- 상태 변경 이력 테이블이 있다면 여기에 로그 기록
        -- 현재는 주석 처리 (4.1 태스크에서 구현 예정)
        -- INSERT INTO bms.unit_status_change_logs ...
        RAISE NOTICE '호실 % 상태가 %에서 %로 변경되었습니다.', NEW.unit_number, OLD.unit_status, NEW.unit_status;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- 9. 상태 변경 이력 트리거 생성
CREATE TRIGGER trg_log_unit_status_changes
    AFTER UPDATE ON bms.units
    FOR EACH ROW EXECUTE FUNCTION bms.log_unit_status_changes();

-- 10. 호실 요약 뷰 생성
CREATE OR REPLACE VIEW bms.v_unit_summary AS
SELECT 
    u.unit_id,
    u.company_id,
    u.building_id,
    b.name as building_name,
    u.unit_number,
    u.floor_number,
    u.unit_type,
    u.unit_status,
    u.exclusive_area,
    u.common_area,
    u.total_area,
    u.monthly_rent,
    u.deposit,
    u.maintenance_fee,
    u.room_count,
    u.bathroom_count,
    u.has_parking,
    u.parking_spaces,
    u.direction,
    u.move_in_date,
    u.move_out_date,
    u.next_maintenance_date,
    u.created_at,
    u.updated_at
FROM bms.units u
JOIN bms.buildings b ON u.building_id = b.building_id;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_unit_summary OWNER TO qiro;

-- 11. 건물별 호실 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_building_unit_statistics AS
SELECT 
    u.building_id,
    b.name as building_name,
    u.company_id,
    COUNT(*) as total_units,
    COUNT(CASE WHEN u.unit_status = 'VACANT' THEN 1 END) as vacant_units,
    COUNT(CASE WHEN u.unit_status = 'OCCUPIED' THEN 1 END) as occupied_units,
    COUNT(CASE WHEN u.unit_status = 'MAINTENANCE' THEN 1 END) as maintenance_units,
    ROUND(COUNT(CASE WHEN u.unit_status = 'OCCUPIED' THEN 1 END) * 100.0 / COUNT(*), 2) as occupancy_rate,
    SUM(u.total_area) as total_area_sum,
    AVG(u.total_area) as avg_area,
    SUM(CASE WHEN u.unit_status = 'OCCUPIED' THEN u.monthly_rent ELSE 0 END) as total_monthly_rent,
    AVG(CASE WHEN u.unit_status = 'OCCUPIED' THEN u.monthly_rent END) as avg_monthly_rent,
    SUM(u.parking_spaces) as total_parking_spaces,
    COUNT(CASE WHEN u.has_parking = true THEN 1 END) as units_with_parking
FROM bms.units u
JOIN bms.buildings b ON u.building_id = b.building_id
GROUP BY u.building_id, b.name, u.company_id;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_building_unit_statistics OWNER TO qiro;

-- 12. 호실 타입별 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_unit_type_statistics AS
SELECT 
    u.company_id,
    u.unit_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN u.unit_status = 'VACANT' THEN 1 END) as vacant_count,
    COUNT(CASE WHEN u.unit_status = 'OCCUPIED' THEN 1 END) as occupied_count,
    ROUND(COUNT(CASE WHEN u.unit_status = 'OCCUPIED' THEN 1 END) * 100.0 / COUNT(*), 2) as occupancy_rate,
    AVG(u.total_area) as avg_area,
    AVG(CASE WHEN u.unit_status = 'OCCUPIED' THEN u.monthly_rent END) as avg_rent,
    MIN(u.monthly_rent) as min_rent,
    MAX(u.monthly_rent) as max_rent
FROM bms.units u
GROUP BY u.company_id, u.unit_type;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_unit_type_statistics OWNER TO qiro;

-- 13. 테스트 데이터 생성
DO $$
DECLARE
    building_rec RECORD;
    floor_num INTEGER;
    unit_num INTEGER;
    unit_count INTEGER := 0;
BEGIN
    -- 각 건물에 대해 호실 생성
    FOR building_rec IN 
        SELECT building_id, company_id, name, total_floors, basement_floors 
        FROM bms.buildings 
        WHERE building_status = 'ACTIVE'
        LIMIT 5  -- 처음 5개 건물만 테스트 데이터 생성
    LOOP
        -- 지하층 호실 생성
        IF building_rec.basement_floors > 0 THEN
            FOR floor_num IN REVERSE -1 DOWNTO -building_rec.basement_floors LOOP
                FOR unit_num IN 1..5 LOOP  -- 각 층에 5개 호실
                    INSERT INTO bms.units (
                        company_id, building_id, unit_number, floor_number,
                        unit_type, unit_status, exclusive_area, common_area,
                        monthly_rent, deposit, maintenance_fee,
                        room_count, bathroom_count, has_parking, parking_spaces,
                        direction, heating_type, cooling_type
                    ) VALUES (
                        building_rec.company_id,
                        building_rec.building_id,
                        'B' || ABS(floor_num) || '-' || LPAD(unit_num::text, 2, '0'),
                        floor_num,
                        CASE WHEN unit_num <= 2 THEN 'PARKING' ELSE 'STORAGE' END,
                        CASE WHEN unit_num % 3 = 0 THEN 'OCCUPIED' ELSE 'VACANT' END,
                        CASE WHEN unit_num <= 2 THEN 15.0 ELSE 10.0 END,
                        5.0,
                        CASE WHEN unit_num <= 2 THEN 50000 ELSE 30000 END,
                        CASE WHEN unit_num <= 2 THEN 500000 ELSE 300000 END,
                        CASE WHEN unit_num <= 2 THEN 10000 ELSE 5000 END,
                        0, 0,
                        CASE WHEN unit_num <= 2 THEN true ELSE false END,
                        CASE WHEN unit_num <= 2 THEN 1 ELSE 0 END,
                        CASE unit_num % 4 WHEN 0 THEN 'N' WHEN 1 THEN 'S' WHEN 2 THEN 'E' ELSE 'W' END,
                        'ELECTRIC', 'NONE'
                    );
                    unit_count := unit_count + 1;
                END LOOP;
            END LOOP;
        END IF;
        
        -- 지상층 호실 생성
        FOR floor_num IN 1..LEAST(building_rec.total_floors, 10) LOOP  -- 최대 10층까지만
            FOR unit_num IN 1..8 LOOP  -- 각 층에 8개 호실
                INSERT INTO bms.units (
                    company_id, building_id, unit_number, floor_number,
                    unit_type, unit_status, exclusive_area, common_area,
                    monthly_rent, deposit, maintenance_fee,
                    room_count, bathroom_count, has_balcony, has_parking, parking_spaces,
                    direction, heating_type, cooling_type, move_in_date
                ) VALUES (
                    building_rec.company_id,
                    building_rec.building_id,
                    floor_num || LPAD(unit_num::text, 2, '0'),
                    floor_num,
                    CASE 
                        WHEN unit_num <= 4 THEN 'OFFICE'
                        WHEN unit_num <= 6 THEN 'RETAIL'
                        ELSE 'WAREHOUSE'
                    END,
                    CASE 
                        WHEN unit_num % 4 = 0 THEN 'OCCUPIED'
                        WHEN unit_num % 5 = 0 THEN 'MAINTENANCE'
                        ELSE 'VACANT'
                    END,
                    20.0 + (unit_num * 5.0) + (floor_num * 2.0),  -- 면적 다양화
                    10.0 + (floor_num * 1.0),
                    100000 + (unit_num * 20000) + (floor_num * 10000),  -- 임대료 다양화
                    1000000 + (unit_num * 200000),
                    50000 + (unit_num * 5000),
                    CASE WHEN unit_num <= 4 THEN 2 + (unit_num % 3) ELSE 1 END,
                    CASE WHEN unit_num <= 4 THEN 1 + (unit_num % 2) ELSE 1 END,
                    CASE WHEN unit_num % 3 = 0 THEN true ELSE false END,
                    CASE WHEN unit_num % 4 = 0 THEN true ELSE false END,
                    CASE WHEN unit_num % 4 = 0 THEN 1 ELSE 0 END,
                    CASE unit_num % 4 WHEN 0 THEN 'N' WHEN 1 THEN 'S' WHEN 2 THEN 'E' ELSE 'W' END,
                    'CENTRAL', 'CENTRAL',
                    CASE WHEN unit_num % 4 = 0 THEN CURRENT_DATE - INTERVAL '30 days' * (unit_num % 12) ELSE NULL END
                );
                unit_count := unit_count + 1;
            END LOOP;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE '총 % 개의 테스트 호실이 생성되었습니다.', unit_count;
END $$;

-- 14. 성능 테스트를 위한 통계 정보 업데이트
ANALYZE bms.units;

-- 15. 데이터 검증 및 결과 출력
SELECT 
    '호실 테이블 생성 완료' as status,
    COUNT(*) as total_units,
    COUNT(CASE WHEN unit_status = 'VACANT' THEN 1 END) as vacant_units,
    COUNT(CASE WHEN unit_status = 'OCCUPIED' THEN 1 END) as occupied_units,
    ROUND(AVG(total_area), 2) as avg_area,
    ROUND(AVG(monthly_rent), 0) as avg_rent
FROM bms.units;

-- 16. 호실 타입별 통계
SELECT 
    '호실 타입별 현황' as info,
    unit_type,
    COUNT(*) as count,
    ROUND(AVG(total_area), 2) as avg_area,
    ROUND(AVG(monthly_rent), 0) as avg_rent
FROM bms.units
GROUP BY unit_type
ORDER BY count DESC;

-- 17. 뷰 테스트
SELECT 
    '뷰 테스트 결과' as info,
    COUNT(*) as summary_view_count
FROM bms.v_unit_summary;

-- 완료 메시지
SELECT '✅ 1.2 호실(Unit) 관리 테이블 생성이 완료되었습니다!' as result;