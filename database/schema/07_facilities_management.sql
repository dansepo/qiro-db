-- =====================================================
-- 시설 유지보수 관리 테이블 설계
-- =====================================================

-- 시설물 카테고리 ENUM 타입
CREATE TYPE facility_category AS ENUM (
    'ELEVATOR',           -- 엘리베이터
    'HVAC',              -- 냉난방시설
    'ELECTRICAL',        -- 전기시설
    'PLUMBING',          -- 배관시설
    'FIRE_SAFETY',       -- 소방시설
    'SECURITY',          -- 보안시설
    'PARKING',           -- 주차시설
    'COMMON_AREA',       -- 공용시설
    'EXTERIOR',          -- 외부시설
    'OTHER'              -- 기타
);

-- 시설물 상태 ENUM 타입
CREATE TYPE facility_status AS ENUM (
    'ACTIVE',            -- 정상 운영
    'MAINTENANCE',       -- 유지보수 중
    'OUT_OF_ORDER',      -- 고장/사용불가
    'SCHEDULED_MAINTENANCE', -- 정기점검 예정
    'RETIRED'            -- 폐기/교체
);

-- 점검 유형 ENUM 타입
CREATE TYPE inspection_type AS ENUM (
    'ROUTINE',           -- 정기점검
    'PREVENTIVE',        -- 예방점검
    'EMERGENCY',         -- 긴급점검
    'LEGAL_REQUIRED',    -- 법정점검
    'WARRANTY'           -- 보증점검
);

-- 점검 상태 ENUM 타입
CREATE TYPE inspection_status AS ENUM (
    'SCHEDULED',         -- 예정
    'IN_PROGRESS',       -- 진행중
    'COMPLETED',         -- 완료
    'OVERDUE',           -- 연체
    'CANCELLED'          -- 취소
);

-- =====================================================
-- 1. 시설물 정보 테이블 (facilities)
-- =====================================================
CREATE TABLE facilities (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    
    -- 기본 정보
    facility_code VARCHAR(50) NOT NULL,           -- 시설물 코드 (예: ELV-001, HVAC-B1-001)
    facility_name VARCHAR(255) NOT NULL,          -- 시설물 명칭
    category facility_category NOT NULL,          -- 시설물 카테고리
    subcategory VARCHAR(100),                     -- 세부 카테고리
    
    -- 위치 정보
    location_description TEXT,                    -- 위치 설명 (예: 지하1층 기계실)
    floor_number INTEGER,                         -- 층수
    room_number VARCHAR(50),                      -- 호실번호 (해당시)
    
    -- 시설물 상세 정보
    manufacturer VARCHAR(255),                    -- 제조사
    model_number VARCHAR(255),                    -- 모델번호
    serial_number VARCHAR(255),                   -- 시리얼번호
    specifications JSONB,                         -- 사양 정보 (JSON 형태)
    
    -- 설치 및 보증 정보
    installation_date DATE,                       -- 설치일
    installation_cost DECIMAL(15,2),              -- 설치비용
    warranty_start_date DATE,                     -- 보증 시작일
    warranty_end_date DATE,                       -- 보증 종료일
    warranty_provider VARCHAR(255),               -- 보증 제공업체
    
    -- 유지보수 정보
    maintenance_cycle_months INTEGER DEFAULT 12,  -- 정기점검 주기 (개월)
    last_maintenance_date DATE,                   -- 최근 점검일
    next_maintenance_date DATE,                   -- 다음 점검 예정일
    maintenance_cost_budget DECIMAL(15,2),        -- 연간 유지보수 예산
    
    -- 상태 및 생애주기 정보
    status facility_status DEFAULT 'ACTIVE',      -- 현재 상태
    expected_lifespan_years INTEGER,              -- 예상 수명 (년)
    replacement_due_date DATE,                    -- 교체 예정일
    disposal_date DATE,                           -- 폐기일
    
    -- 추가 정보
    notes TEXT,                                   -- 비고
    attachments JSONB,                            -- 첨부파일 정보 (매뉴얼, 도면 등)
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT facilities_building_code_unique UNIQUE (building_id, facility_code),
    CONSTRAINT facilities_installation_warranty_check 
        CHECK (warranty_start_date IS NULL OR installation_date IS NULL OR warranty_start_date >= installation_date),
    CONSTRAINT facilities_warranty_period_check 
        CHECK (warranty_end_date IS NULL OR warranty_start_date IS NULL OR warranty_end_date >= warranty_start_date),
    CONSTRAINT facilities_maintenance_cycle_check 
        CHECK (maintenance_cycle_months > 0 AND maintenance_cycle_months <= 120),
    CONSTRAINT facilities_lifespan_check 
        CHECK (expected_lifespan_years IS NULL OR expected_lifespan_years > 0)
);

-- =====================================================
-- 2. 시설물 점검 계획 테이블 (facility_inspection_schedules)
-- =====================================================
CREATE TABLE facility_inspection_schedules (
    id BIGSERIAL PRIMARY KEY,
    facility_id BIGINT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    
    -- 점검 계획 정보
    inspection_type inspection_type NOT NULL,     -- 점검 유형
    inspection_name VARCHAR(255) NOT NULL,        -- 점검명
    description TEXT,                             -- 점검 설명
    
    -- 일정 정보
    scheduled_date DATE NOT NULL,                 -- 예정일
    estimated_duration_hours DECIMAL(4,2),       -- 예상 소요시간
    
    -- 담당자 정보
    assigned_to BIGINT,                           -- 담당자 (users 테이블 참조)
    vendor_id BIGINT,                             -- 협력업체 (facility_vendors 테이블 참조)
    
    -- 점검 항목
    inspection_checklist JSONB,                   -- 점검 체크리스트
    required_tools JSONB,                         -- 필요 도구/장비
    safety_requirements TEXT,                     -- 안전 요구사항
    
    -- 상태 및 결과
    status inspection_status DEFAULT 'SCHEDULED', -- 점검 상태
    actual_start_time TIMESTAMP,                  -- 실제 시작시간
    actual_end_time TIMESTAMP,                    -- 실제 종료시간
    
    -- 비용 정보
    estimated_cost DECIMAL(12,2),                 -- 예상 비용
    actual_cost DECIMAL(12,2),                    -- 실제 비용
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT inspection_schedules_duration_check 
        CHECK (estimated_duration_hours IS NULL OR estimated_duration_hours > 0),
    CONSTRAINT inspection_schedules_cost_check 
        CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
    CONSTRAINT inspection_schedules_actual_cost_check 
        CHECK (actual_cost IS NULL OR actual_cost >= 0),
    CONSTRAINT inspection_schedules_time_check 
        CHECK (actual_end_time IS NULL OR actual_start_time IS NULL OR actual_end_time >= actual_start_time)
);

-- =====================================================
-- 3. 시설물 점검 결과 테이블 (facility_inspection_results)
-- =====================================================
CREATE TABLE facility_inspection_results (
    id BIGSERIAL PRIMARY KEY,
    schedule_id BIGINT NOT NULL REFERENCES facility_inspection_schedules(id) ON DELETE CASCADE,
    facility_id BIGINT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    
    -- 점검 결과 정보
    inspection_date DATE NOT NULL,                -- 점검일
    inspector_name VARCHAR(255) NOT NULL,        -- 점검자명
    inspector_certification VARCHAR(255),        -- 점검자 자격증
    
    -- 점검 결과
    overall_condition VARCHAR(50) NOT NULL,      -- 전체 상태 (EXCELLENT, GOOD, FAIR, POOR, CRITICAL)
    detailed_findings JSONB,                     -- 상세 점검 결과
    issues_found JSONB,                          -- 발견된 문제점
    recommendations TEXT,                        -- 권고사항
    
    -- 다음 점검 정보
    next_inspection_due_date DATE,               -- 다음 점검 예정일
    next_inspection_type inspection_type,        -- 다음 점검 유형
    
    -- 첨부 자료
    photos JSONB,                                -- 점검 사진
    documents JSONB,                             -- 점검 문서
    
    -- 승인 정보
    approved_by BIGINT,                          -- 승인자
    approved_at TIMESTAMP,                       -- 승인일시
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT inspection_results_condition_check 
        CHECK (overall_condition IN ('EXCELLENT', 'GOOD', 'FAIR', 'POOR', 'CRITICAL'))
);

-- =====================================================
-- 4. 시설물 생애주기 이력 테이블 (facility_lifecycle_history)
-- =====================================================
CREATE TABLE facility_lifecycle_history (
    id BIGSERIAL PRIMARY KEY,
    facility_id BIGINT NOT NULL REFERENCES facilities(id) ON DELETE CASCADE,
    
    -- 이벤트 정보
    event_type VARCHAR(50) NOT NULL,             -- 이벤트 유형 (INSTALLED, MAINTAINED, REPAIRED, UPGRADED, RETIRED)
    event_date DATE NOT NULL,                    -- 이벤트 발생일
    event_description TEXT NOT NULL,             -- 이벤트 설명
    
    -- 비용 정보
    cost DECIMAL(15,2),                          -- 소요 비용
    vendor_id BIGINT,                            -- 작업 업체
    
    -- 상태 변경
    previous_status facility_status,             -- 이전 상태
    new_status facility_status,                  -- 변경된 상태
    
    -- 성능 지표
    performance_metrics JSONB,                   -- 성능 지표 (효율성, 가동률 등)
    
    -- 첨부 자료
    documents JSONB,                             -- 관련 문서
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    
    -- 제약조건
    CONSTRAINT lifecycle_history_event_type_check 
        CHECK (event_type IN ('INSTALLED', 'MAINTAINED', 'REPAIRED', 'UPGRADED', 'RETIRED', 'INSPECTED')),
    CONSTRAINT lifecycle_history_cost_check 
        CHECK (cost IS NULL OR cost >= 0)
);
--
 =====================================================
-- 인덱스 생성
-- =====================================================

-- facilities 테이블 인덱스
CREATE INDEX idx_facilities_building_id ON facilities(building_id);
CREATE INDEX idx_facilities_category ON facilities(category);
CREATE INDEX idx_facilities_status ON facilities(status);
CREATE INDEX idx_facilities_next_maintenance ON facilities(next_maintenance_date) WHERE next_maintenance_date IS NOT NULL;
CREATE INDEX idx_facilities_warranty_expiry ON facilities(warranty_end_date) WHERE warranty_end_date IS NOT NULL;
CREATE INDEX idx_facilities_replacement_due ON facilities(replacement_due_date) WHERE replacement_due_date IS NOT NULL;
CREATE INDEX idx_facilities_location ON facilities(building_id, floor_number, room_number);

-- facility_inspection_schedules 테이블 인덱스
CREATE INDEX idx_inspection_schedules_facility_id ON facility_inspection_schedules(facility_id);
CREATE INDEX idx_inspection_schedules_scheduled_date ON facility_inspection_schedules(scheduled_date);
CREATE INDEX idx_inspection_schedules_status ON facility_inspection_schedules(status);
CREATE INDEX idx_inspection_schedules_assigned_to ON facility_inspection_schedules(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_inspection_schedules_vendor_id ON facility_inspection_schedules(vendor_id) WHERE vendor_id IS NOT NULL;
CREATE INDEX idx_inspection_schedules_overdue ON facility_inspection_schedules(scheduled_date, status) 
    WHERE status IN ('SCHEDULED', 'IN_PROGRESS');

-- facility_inspection_results 테이블 인덱스
CREATE INDEX idx_inspection_results_schedule_id ON facility_inspection_results(schedule_id);
CREATE INDEX idx_inspection_results_facility_id ON facility_inspection_results(facility_id);
CREATE INDEX idx_inspection_results_inspection_date ON facility_inspection_results(inspection_date);
CREATE INDEX idx_inspection_results_condition ON facility_inspection_results(overall_condition);
CREATE INDEX idx_inspection_results_next_due ON facility_inspection_results(next_inspection_due_date) 
    WHERE next_inspection_due_date IS NOT NULL;

-- facility_lifecycle_history 테이블 인덱스
CREATE INDEX idx_lifecycle_history_facility_id ON facility_lifecycle_history(facility_id);
CREATE INDEX idx_lifecycle_history_event_date ON facility_lifecycle_history(event_date);
CREATE INDEX idx_lifecycle_history_event_type ON facility_lifecycle_history(event_type);
CREATE INDEX idx_lifecycle_history_vendor_id ON facility_lifecycle_history(vendor_id) WHERE vendor_id IS NOT NULL;

-- =====================================================
-- 뷰 생성 - 시설물 현황 요약
-- =====================================================
CREATE VIEW facility_status_summary AS
SELECT 
    f.building_id,
    f.category,
    f.status,
    COUNT(*) as facility_count,
    COUNT(CASE WHEN f.next_maintenance_date <= CURRENT_DATE + INTERVAL '30 days' THEN 1 END) as maintenance_due_soon,
    COUNT(CASE WHEN f.warranty_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 1 END) as warranty_expiring_soon,
    COUNT(CASE WHEN f.replacement_due_date <= CURRENT_DATE + INTERVAL '365 days' THEN 1 END) as replacement_due_soon
FROM facilities f
WHERE f.status != 'RETIRED'
GROUP BY f.building_id, f.category, f.status;

-- =====================================================
-- 뷰 생성 - 점검 일정 현황
-- =====================================================
CREATE VIEW inspection_schedule_overview AS
SELECT 
    fis.facility_id,
    f.facility_name,
    f.category,
    fis.inspection_type,
    fis.scheduled_date,
    fis.status,
    fis.assigned_to,
    fis.vendor_id,
    CASE 
        WHEN fis.scheduled_date < CURRENT_DATE AND fis.status IN ('SCHEDULED', 'IN_PROGRESS') THEN 'OVERDUE'
        WHEN fis.scheduled_date <= CURRENT_DATE + INTERVAL '7 days' AND fis.status = 'SCHEDULED' THEN 'DUE_SOON'
        ELSE 'NORMAL'
    END as urgency_status
FROM facility_inspection_schedules fis
JOIN facilities f ON fis.facility_id = f.id
WHERE fis.status IN ('SCHEDULED', 'IN_PROGRESS');

-- =====================================================
-- 함수 생성 - 다음 정기점검 일정 자동 계산
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_next_maintenance_date(
    p_facility_id BIGINT,
    p_last_maintenance_date DATE DEFAULT NULL
) RETURNS DATE AS $$
DECLARE
    v_maintenance_cycle INTEGER;
    v_base_date DATE;
BEGIN
    -- 시설물의 점검 주기 조회
    SELECT maintenance_cycle_months INTO v_maintenance_cycle
    FROM facilities 
    WHERE id = p_facility_id;
    
    -- 기준일 설정 (마지막 점검일 또는 현재일)
    v_base_date := COALESCE(p_last_maintenance_date, CURRENT_DATE);
    
    -- 다음 점검일 계산
    RETURN v_base_date + (v_maintenance_cycle || ' months')::INTERVAL;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 트리거 함수 - 시설물 상태 변경 시 생애주기 이력 자동 기록
-- =====================================================
CREATE OR REPLACE FUNCTION log_facility_status_change() RETURNS TRIGGER AS $$
BEGIN
    -- 상태가 변경된 경우에만 이력 기록
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        INSERT INTO facility_lifecycle_history (
            facility_id,
            event_type,
            event_date,
            event_description,
            previous_status,
            new_status,
            created_by
        ) VALUES (
            NEW.id,
            'STATUS_CHANGED',
            CURRENT_DATE,
            'Status changed from ' || COALESCE(OLD.status::text, 'NULL') || ' to ' || NEW.status::text,
            OLD.status,
            NEW.status,
            NEW.updated_by
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_facility_status_change
    AFTER UPDATE ON facilities
    FOR EACH ROW
    EXECUTE FUNCTION log_facility_status_change();

-- =====================================================
-- 트리거 함수 - 점검 완료 시 다음 점검 일정 자동 생성
-- =====================================================
CREATE OR REPLACE FUNCTION auto_schedule_next_inspection() RETURNS TRIGGER AS $$
DECLARE
    v_facility_id BIGINT;
    v_next_date DATE;
BEGIN
    -- 점검이 완료된 경우
    IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
        v_facility_id := NEW.facility_id;
        
        -- 정기점검인 경우 다음 정기점검 일정 자동 생성
        IF NEW.inspection_type = 'ROUTINE' THEN
            v_next_date := calculate_next_maintenance_date(v_facility_id, NEW.actual_end_time::DATE);
            
            -- 시설물의 다음 점검일 업데이트
            UPDATE facilities 
            SET 
                last_maintenance_date = NEW.actual_end_time::DATE,
                next_maintenance_date = v_next_date,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = v_facility_id;
            
            -- 다음 정기점검 일정 자동 생성
            INSERT INTO facility_inspection_schedules (
                facility_id,
                inspection_type,
                inspection_name,
                description,
                scheduled_date,
                estimated_duration_hours,
                created_by
            ) VALUES (
                v_facility_id,
                'ROUTINE',
                'Scheduled Routine Inspection',
                'Auto-generated routine inspection schedule',
                v_next_date,
                NEW.actual_end_time - NEW.actual_start_time,
                NEW.updated_by
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_auto_schedule_next_inspection
    AFTER UPDATE ON facility_inspection_schedules
    FOR EACH ROW
    EXECUTE FUNCTION auto_schedule_next_inspection();

-- =====================================================
-- 코멘트 추가
-- =====================================================
COMMENT ON TABLE facilities IS '시설물 기본 정보 및 생애주기 관리';
COMMENT ON TABLE facility_inspection_schedules IS '시설물 점검 일정 관리';
COMMENT ON TABLE facility_inspection_results IS '시설물 점검 결과 기록';
COMMENT ON TABLE facility_lifecycle_history IS '시설물 생애주기 이력 추적';

COMMENT ON COLUMN facilities.facility_code IS '건물 내 고유한 시설물 식별 코드';
COMMENT ON COLUMN facilities.maintenance_cycle_months IS '정기점검 주기 (개월 단위)';
COMMENT ON COLUMN facilities.expected_lifespan_years IS '예상 사용 수명 (년 단위)';
COMMENT ON COLUMN facility_inspection_schedules.inspection_checklist IS '점검 체크리스트 (JSON 형태)';
COMMENT ON COLUMN facility_inspection_results.detailed_findings IS '상세 점검 결과 (JSON 형태)';
COMMENT ON COLUMN facility_lifecycle_history.performance_metrics IS '성능 지표 데이터 (JSON 형태)';
--
 =====================================================
-- 유지보수 요청 및 작업 관리 테이블
-- =====================================================

-- 요청 우선순위 ENUM 타입
CREATE TYPE maintenance_priority AS ENUM (
    'LOW',               -- 낮음
    'MEDIUM',            -- 보통
    'HIGH',              -- 높음
    'URGENT',            -- 긴급
    'CRITICAL'           -- 매우 긴급
);

-- 요청 상태 ENUM 타입
CREATE TYPE maintenance_request_status AS ENUM (
    'SUBMITTED',         -- 접수
    'UNDER_REVIEW',      -- 검토중
    'APPROVED',          -- 승인
    'ASSIGNED',          -- 배정
    'IN_PROGRESS',       -- 진행중
    'COMPLETED',         -- 완료
    'REJECTED',          -- 반려
    'CANCELLED',         -- 취소
    'ON_HOLD'            -- 보류
);

-- 작업 상태 ENUM 타입
CREATE TYPE maintenance_work_status AS ENUM (
    'SCHEDULED',         -- 예정
    'IN_PROGRESS',       -- 진행중
    'COMPLETED',         -- 완료
    'CANCELLED',         -- 취소
    'FAILED',            -- 실패
    'RESCHEDULED'        -- 재예정
);

-- 요청 유형 ENUM 타입
CREATE TYPE maintenance_request_type AS ENUM (
    'REPAIR',            -- 수리
    'REPLACEMENT',       -- 교체
    'UPGRADE',           -- 업그레이드
    'PREVENTIVE',        -- 예방정비
    'EMERGENCY',         -- 응급처치
    'INSPECTION',        -- 점검
    'CLEANING',          -- 청소
    'OTHER'              -- 기타
);

-- =====================================================
-- 5. 유지보수 요청 테이블 (maintenance_requests)
-- =====================================================
CREATE TABLE maintenance_requests (
    id BIGSERIAL PRIMARY KEY,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    facility_id BIGINT REFERENCES facilities(id) ON DELETE SET NULL,
    unit_id BIGINT REFERENCES units(id) ON DELETE SET NULL,
    
    -- 요청 기본 정보
    request_number VARCHAR(50) UNIQUE NOT NULL,   -- 요청번호 (자동생성)
    request_type maintenance_request_type NOT NULL, -- 요청 유형
    title VARCHAR(255) NOT NULL,                  -- 요청 제목
    description TEXT NOT NULL,                    -- 상세 설명
    
    -- 요청자 정보
    requester_name VARCHAR(255) NOT NULL,         -- 요청자명
    requester_contact VARCHAR(100),               -- 요청자 연락처
    requester_email VARCHAR(255),                 -- 요청자 이메일
    requester_type VARCHAR(50) NOT NULL,          -- 요청자 구분 (TENANT, LESSOR, MANAGER, STAFF)
    requester_unit_id BIGINT REFERENCES units(id), -- 요청자 호실 (해당시)
    
    -- 우선순위 및 상태
    priority maintenance_priority DEFAULT 'MEDIUM', -- 우선순위
    status maintenance_request_status DEFAULT 'SUBMITTED', -- 처리 상태
    urgency_reason TEXT,                          -- 긴급 사유 (긴급시)
    
    -- 일정 정보
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 요청일시
    preferred_date DATE,                          -- 희망 작업일
    preferred_time_start TIME,                    -- 희망 시작시간
    preferred_time_end TIME,                      -- 희망 종료시간
    
    -- 배정 정보
    assigned_to BIGINT,                           -- 담당자 (users 테이블 참조)
    assigned_at TIMESTAMP,                        -- 배정일시
    estimated_cost DECIMAL(12,2),                 -- 예상 비용
    approved_budget DECIMAL(12,2),                -- 승인 예산
    
    -- 완료 정보
    completed_at TIMESTAMP,                       -- 완료일시
    completion_notes TEXT,                        -- 완료 비고
    requester_satisfaction INTEGER,               -- 요청자 만족도 (1-5)
    requester_feedback TEXT,                      -- 요청자 피드백
    
    -- 첨부 자료
    attachments JSONB,                            -- 첨부파일 (사진, 문서 등)
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT maintenance_requests_requester_type_check 
        CHECK (requester_type IN ('TENANT', 'LESSOR', 'MANAGER', 'STAFF', 'EXTERNAL')),
    CONSTRAINT maintenance_requests_satisfaction_check 
        CHECK (requester_satisfaction IS NULL OR (requester_satisfaction >= 1 AND requester_satisfaction <= 5)),
    CONSTRAINT maintenance_requests_cost_check 
        CHECK (estimated_cost IS NULL OR estimated_cost >= 0),
    CONSTRAINT maintenance_requests_budget_check 
        CHECK (approved_budget IS NULL OR approved_budget >= 0),
    CONSTRAINT maintenance_requests_time_check 
        CHECK (preferred_time_end IS NULL OR preferred_time_start IS NULL OR preferred_time_end > preferred_time_start)
);

-- =====================================================
-- 6. 유지보수 작업 테이블 (maintenance_works)
-- =====================================================
CREATE TABLE maintenance_works (
    id BIGSERIAL PRIMARY KEY,
    request_id BIGINT NOT NULL REFERENCES maintenance_requests(id) ON DELETE CASCADE,
    facility_id BIGINT REFERENCES facilities(id) ON DELETE SET NULL,
    vendor_id BIGINT REFERENCES facility_vendors(id) ON DELETE SET NULL,
    
    -- 작업 기본 정보
    work_order_number VARCHAR(50) UNIQUE NOT NULL, -- 작업지시서 번호
    work_title VARCHAR(255) NOT NULL,             -- 작업명
    work_description TEXT NOT NULL,               -- 작업 상세 설명
    work_type maintenance_request_type NOT NULL,  -- 작업 유형
    
    -- 일정 정보
    scheduled_start_date DATE NOT NULL,           -- 예정 시작일
    scheduled_end_date DATE,                      -- 예정 종료일
    scheduled_start_time TIME,                    -- 예정 시작시간
    scheduled_end_time TIME,                      -- 예정 종료시간
    
    -- 실제 작업 정보
    actual_start_time TIMESTAMP,                  -- 실제 시작시간
    actual_end_time TIMESTAMP,                    -- 실제 종료시간
    actual_duration_hours DECIMAL(6,2),           -- 실제 소요시간
    
    -- 작업자 정보
    primary_worker_name VARCHAR(255),             -- 주 작업자명
    worker_count INTEGER DEFAULT 1,               -- 작업자 수
    worker_details JSONB,                         -- 작업자 상세정보
    supervisor_name VARCHAR(255),                 -- 감독자명
    
    -- 비용 정보
    labor_cost DECIMAL(12,2) DEFAULT 0,           -- 인건비
    material_cost DECIMAL(12,2) DEFAULT 0,        -- 자재비
    equipment_cost DECIMAL(12,2) DEFAULT 0,       -- 장비비
    other_cost DECIMAL(12,2) DEFAULT 0,           -- 기타비용
    total_cost DECIMAL(12,2) GENERATED ALWAYS AS (
        COALESCE(labor_cost, 0) + COALESCE(material_cost, 0) + 
        COALESCE(equipment_cost, 0) + COALESCE(other_cost, 0)
    ) STORED,                                     -- 총 비용 (자동계산)
    
    -- 자재 및 부품 정보
    materials_used JSONB,                         -- 사용 자재 목록
    parts_replaced JSONB,                         -- 교체 부품 목록
    tools_used JSONB,                             -- 사용 도구 목록
    
    -- 작업 결과
    status maintenance_work_status DEFAULT 'SCHEDULED', -- 작업 상태
    work_quality_rating INTEGER,                 -- 작업 품질 평가 (1-5)
    completion_percentage INTEGER DEFAULT 0,     -- 완료율
    work_result_summary TEXT,                     -- 작업 결과 요약
    issues_encountered TEXT,                      -- 발생한 문제점
    recommendations TEXT,                         -- 권고사항
    
    -- 안전 및 규정 준수
    safety_measures_taken TEXT,                   -- 안전조치 사항
    permits_obtained JSONB,                       -- 취득한 허가증
    regulations_compliance BOOLEAN DEFAULT true,  -- 규정 준수 여부
    
    -- 품질 관리
    inspection_required BOOLEAN DEFAULT false,    -- 검수 필요 여부
    inspected_by BIGINT,                          -- 검수자
    inspected_at TIMESTAMP,                       -- 검수일시
    inspection_notes TEXT,                        -- 검수 의견
    
    -- 보증 정보
    warranty_period_months INTEGER,               -- 보증 기간 (개월)
    warranty_start_date DATE,                     -- 보증 시작일
    warranty_end_date DATE,                       -- 보증 종료일
    warranty_terms TEXT,                          -- 보증 조건
    
    -- 첨부 자료
    before_photos JSONB,                          -- 작업 전 사진
    after_photos JSONB,                           -- 작업 후 사진
    work_documents JSONB,                         -- 작업 관련 문서
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT maintenance_works_schedule_check 
        CHECK (scheduled_end_date IS NULL OR scheduled_end_date >= scheduled_start_date),
    CONSTRAINT maintenance_works_time_check 
        CHECK (scheduled_end_time IS NULL OR scheduled_start_time IS NULL OR scheduled_end_time > scheduled_start_time),
    CONSTRAINT maintenance_works_actual_time_check 
        CHECK (actual_end_time IS NULL OR actual_start_time IS NULL OR actual_end_time >= actual_start_time),
    CONSTRAINT maintenance_works_cost_check 
        CHECK (labor_cost >= 0 AND material_cost >= 0 AND equipment_cost >= 0 AND other_cost >= 0),
    CONSTRAINT maintenance_works_quality_check 
        CHECK (work_quality_rating IS NULL OR (work_quality_rating >= 1 AND work_quality_rating <= 5)),
    CONSTRAINT maintenance_works_completion_check 
        CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    CONSTRAINT maintenance_works_worker_count_check 
        CHECK (worker_count > 0),
    CONSTRAINT maintenance_works_warranty_check 
        CHECK (warranty_end_date IS NULL OR warranty_start_date IS NULL OR warranty_end_date >= warranty_start_date)
);

-- =====================================================
-- 7. 유지보수 작업 진행 상황 테이블 (maintenance_work_progress)
-- =====================================================
CREATE TABLE maintenance_work_progress (
    id BIGSERIAL PRIMARY KEY,
    work_id BIGINT NOT NULL REFERENCES maintenance_works(id) ON DELETE CASCADE,
    
    -- 진행 상황 정보
    progress_date DATE NOT NULL,                  -- 진행일
    progress_time TIME DEFAULT CURRENT_TIME,     -- 진행시간
    progress_percentage INTEGER NOT NULL,        -- 진행률
    status_description TEXT NOT NULL,            -- 상태 설명
    
    -- 작업 내용
    work_performed TEXT,                          -- 수행한 작업
    materials_consumed JSONB,                     -- 소모한 자재
    time_spent_hours DECIMAL(4,2),               -- 소요시간
    
    -- 문제 및 지연 사항
    issues_encountered TEXT,                      -- 발생한 문제
    delays_reason TEXT,                           -- 지연 사유
    next_steps TEXT,                              -- 다음 단계
    
    -- 사진 및 문서
    progress_photos JSONB,                        -- 진행 상황 사진
    
    -- 기록자 정보
    reported_by VARCHAR(255) NOT NULL,           -- 보고자
    reporter_role VARCHAR(50),                    -- 보고자 역할
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    
    -- 제약조건
    CONSTRAINT work_progress_percentage_check 
        CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    CONSTRAINT work_progress_time_check 
        CHECK (time_spent_hours IS NULL OR time_spent_hours >= 0)
);

-- =====================================================
-- 8. 유지보수 비용 상세 테이블 (maintenance_cost_details)
-- =====================================================
CREATE TABLE maintenance_cost_details (
    id BIGSERIAL PRIMARY KEY,
    work_id BIGINT NOT NULL REFERENCES maintenance_works(id) ON DELETE CASCADE,
    
    -- 비용 항목 정보
    cost_category VARCHAR(50) NOT NULL,          -- 비용 카테고리 (LABOR, MATERIAL, EQUIPMENT, OTHER)
    item_name VARCHAR(255) NOT NULL,             -- 항목명
    item_description TEXT,                       -- 항목 설명
    
    -- 수량 및 단가
    quantity DECIMAL(10,3) NOT NULL,             -- 수량
    unit VARCHAR(20),                            -- 단위
    unit_price DECIMAL(12,2) NOT NULL,           -- 단가
    total_price DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price) STORED, -- 총액
    
    -- 공급업체 정보
    supplier_name VARCHAR(255),                  -- 공급업체명
    supplier_contact VARCHAR(100),               -- 공급업체 연락처
    
    -- 세금 정보
    is_taxable BOOLEAN DEFAULT true,             -- 과세 여부
    tax_rate DECIMAL(5,2) DEFAULT 10.0,          -- 세율
    tax_amount DECIMAL(12,2) GENERATED ALWAYS AS (
        CASE WHEN is_taxable THEN total_price * tax_rate / 100 ELSE 0 END
    ) STORED,                                    -- 세액
    
    -- 결제 정보
    payment_method VARCHAR(50),                  -- 결제 방법
    payment_date DATE,                           -- 결제일
    invoice_number VARCHAR(100),                 -- 세금계산서 번호
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT cost_details_category_check 
        CHECK (cost_category IN ('LABOR', 'MATERIAL', 'EQUIPMENT', 'OTHER')),
    CONSTRAINT cost_details_quantity_check 
        CHECK (quantity > 0),
    CONSTRAINT cost_details_unit_price_check 
        CHECK (unit_price >= 0),
    CONSTRAINT cost_details_tax_rate_check 
        CHECK (tax_rate >= 0 AND tax_rate <= 100)
);-
- =====================================================
-- 유지보수 요청 및 작업 관리 인덱스
-- =====================================================

-- maintenance_requests 테이블 인덱스
CREATE INDEX idx_maintenance_requests_building_id ON maintenance_requests(building_id);
CREATE INDEX idx_maintenance_requests_facility_id ON maintenance_requests(facility_id) WHERE facility_id IS NOT NULL;
CREATE INDEX idx_maintenance_requests_unit_id ON maintenance_requests(unit_id) WHERE unit_id IS NOT NULL;
CREATE INDEX idx_maintenance_requests_status ON maintenance_requests(status);
CREATE INDEX idx_maintenance_requests_priority ON maintenance_requests(priority);
CREATE INDEX idx_maintenance_requests_assigned_to ON maintenance_requests(assigned_to) WHERE assigned_to IS NOT NULL;
CREATE INDEX idx_maintenance_requests_requested_at ON maintenance_requests(requested_at);
CREATE INDEX idx_maintenance_requests_requester_type ON maintenance_requests(requester_type);
CREATE INDEX idx_maintenance_requests_urgent ON maintenance_requests(priority, status) 
    WHERE priority IN ('URGENT', 'CRITICAL') AND status NOT IN ('COMPLETED', 'CANCELLED', 'REJECTED');

-- maintenance_works 테이블 인덱스
CREATE INDEX idx_maintenance_works_request_id ON maintenance_works(request_id);
CREATE INDEX idx_maintenance_works_facility_id ON maintenance_works(facility_id) WHERE facility_id IS NOT NULL;
CREATE INDEX idx_maintenance_works_vendor_id ON maintenance_works(vendor_id) WHERE vendor_id IS NOT NULL;
CREATE INDEX idx_maintenance_works_status ON maintenance_works(status);
CREATE INDEX idx_maintenance_works_scheduled_date ON maintenance_works(scheduled_start_date);
CREATE INDEX idx_maintenance_works_completion ON maintenance_works(actual_end_time) WHERE actual_end_time IS NOT NULL;
CREATE INDEX idx_maintenance_works_cost ON maintenance_works(total_cost);
CREATE INDEX idx_maintenance_works_warranty ON maintenance_works(warranty_end_date) WHERE warranty_end_date IS NOT NULL;

-- maintenance_work_progress 테이블 인덱스
CREATE INDEX idx_work_progress_work_id ON maintenance_work_progress(work_id);
CREATE INDEX idx_work_progress_date ON maintenance_work_progress(progress_date);
CREATE INDEX idx_work_progress_percentage ON maintenance_work_progress(progress_percentage);

-- maintenance_cost_details 테이블 인덱스
CREATE INDEX idx_cost_details_work_id ON maintenance_cost_details(work_id);
CREATE INDEX idx_cost_details_category ON maintenance_cost_details(cost_category);
CREATE INDEX idx_cost_details_payment_date ON maintenance_cost_details(payment_date) WHERE payment_date IS NOT NULL;

-- =====================================================
-- 뷰 생성 - 유지보수 요청 현황 대시보드
-- =====================================================
CREATE VIEW maintenance_request_dashboard AS
SELECT 
    mr.building_id,
    mr.status,
    mr.priority,
    COUNT(*) as request_count,
    AVG(EXTRACT(EPOCH FROM (COALESCE(mr.completed_at, CURRENT_TIMESTAMP) - mr.requested_at))/3600) as avg_resolution_hours,
    COUNT(CASE WHEN mr.requested_at >= CURRENT_DATE - INTERVAL '7 days' THEN 1 END) as requests_last_7_days,
    COUNT(CASE WHEN mr.requested_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as requests_last_30_days,
    AVG(mr.requester_satisfaction) as avg_satisfaction
FROM maintenance_requests mr
GROUP BY mr.building_id, mr.status, mr.priority;

-- =====================================================
-- 뷰 생성 - 작업자별 성과 현황
-- =====================================================
CREATE VIEW worker_performance_summary AS
SELECT 
    mw.primary_worker_name,
    mw.vendor_id,
    COUNT(*) as total_works,
    COUNT(CASE WHEN mw.status = 'COMPLETED' THEN 1 END) as completed_works,
    ROUND(COUNT(CASE WHEN mw.status = 'COMPLETED' THEN 1 END) * 100.0 / COUNT(*), 2) as completion_rate,
    AVG(mw.work_quality_rating) as avg_quality_rating,
    SUM(mw.total_cost) as total_cost,
    AVG(mw.actual_duration_hours) as avg_duration_hours
FROM maintenance_works mw
WHERE mw.primary_worker_name IS NOT NULL
GROUP BY mw.primary_worker_name, mw.vendor_id;

-- =====================================================
-- 뷰 생성 - 시설물별 유지보수 이력 요약
-- =====================================================
CREATE VIEW facility_maintenance_summary AS
SELECT 
    f.id as facility_id,
    f.facility_name,
    f.category,
    COUNT(mr.id) as total_requests,
    COUNT(mw.id) as total_works,
    SUM(mw.total_cost) as total_maintenance_cost,
    MAX(mw.actual_end_time) as last_maintenance_date,
    AVG(mr.requester_satisfaction) as avg_satisfaction,
    COUNT(CASE WHEN mr.priority IN ('URGENT', 'CRITICAL') THEN 1 END) as urgent_requests
FROM facilities f
LEFT JOIN maintenance_requests mr ON f.id = mr.facility_id
LEFT JOIN maintenance_works mw ON mr.id = mw.request_id
GROUP BY f.id, f.facility_name, f.category;

-- =====================================================
-- 함수 생성 - 요청번호 자동 생성
-- =====================================================
CREATE OR REPLACE FUNCTION generate_request_number(p_building_id BIGINT) RETURNS VARCHAR(50) AS $$
DECLARE
    v_year VARCHAR(4);
    v_month VARCHAR(2);
    v_sequence INTEGER;
    v_request_number VARCHAR(50);
BEGIN
    -- 현재 년월 추출
    v_year := EXTRACT(YEAR FROM CURRENT_DATE)::VARCHAR;
    v_month := LPAD(EXTRACT(MONTH FROM CURRENT_DATE)::VARCHAR, 2, '0');
    
    -- 해당 건물의 당월 요청 순번 계산
    SELECT COALESCE(MAX(
        CASE 
            WHEN request_number ~ ('^REQ-' || p_building_id || '-' || v_year || v_month || '-[0-9]+$')
            THEN SUBSTRING(request_number FROM '[0-9]+$')::INTEGER
            ELSE 0
        END
    ), 0) + 1 INTO v_sequence
    FROM maintenance_requests
    WHERE building_id = p_building_id
    AND EXTRACT(YEAR FROM requested_at) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND EXTRACT(MONTH FROM requested_at) = EXTRACT(MONTH FROM CURRENT_DATE);
    
    -- 요청번호 생성: REQ-{건물ID}-{YYYYMM}-{순번}
    v_request_number := 'REQ-' || p_building_id || '-' || v_year || v_month || '-' || LPAD(v_sequence::VARCHAR, 4, '0');
    
    RETURN v_request_number;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 함수 생성 - 작업지시서 번호 자동 생성
-- =====================================================
CREATE OR REPLACE FUNCTION generate_work_order_number(p_request_id BIGINT) RETURNS VARCHAR(50) AS $$
DECLARE
    v_building_id BIGINT;
    v_year VARCHAR(4);
    v_month VARCHAR(2);
    v_sequence INTEGER;
    v_work_order_number VARCHAR(50);
BEGIN
    -- 요청의 건물 ID 조회
    SELECT building_id INTO v_building_id
    FROM maintenance_requests
    WHERE id = p_request_id;
    
    -- 현재 년월 추출
    v_year := EXTRACT(YEAR FROM CURRENT_DATE)::VARCHAR;
    v_month := LPAD(EXTRACT(MONTH FROM CURRENT_DATE)::VARCHAR, 2, '0');
    
    -- 해당 건물의 당월 작업지시서 순번 계산
    SELECT COALESCE(MAX(
        CASE 
            WHEN mw.work_order_number ~ ('^WO-' || v_building_id || '-' || v_year || v_month || '-[0-9]+$')
            THEN SUBSTRING(mw.work_order_number FROM '[0-9]+$')::INTEGER
            ELSE 0
        END
    ), 0) + 1 INTO v_sequence
    FROM maintenance_works mw
    JOIN maintenance_requests mr ON mw.request_id = mr.id
    WHERE mr.building_id = v_building_id
    AND EXTRACT(YEAR FROM mw.created_at) = EXTRACT(YEAR FROM CURRENT_DATE)
    AND EXTRACT(MONTH FROM mw.created_at) = EXTRACT(MONTH FROM CURRENT_DATE);
    
    -- 작업지시서 번호 생성: WO-{건물ID}-{YYYYMM}-{순번}
    v_work_order_number := 'WO-' || v_building_id || '-' || v_year || v_month || '-' || LPAD(v_sequence::VARCHAR, 4, '0');
    
    RETURN v_work_order_number;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 트리거 함수 - 요청번호 자동 설정
-- =====================================================
CREATE OR REPLACE FUNCTION set_request_number() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.request_number IS NULL OR NEW.request_number = '' THEN
        NEW.request_number := generate_request_number(NEW.building_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_set_request_number
    BEFORE INSERT ON maintenance_requests
    FOR EACH ROW
    EXECUTE FUNCTION set_request_number();

-- =====================================================
-- 트리거 함수 - 작업지시서 번호 자동 설정
-- =====================================================
CREATE OR REPLACE FUNCTION set_work_order_number() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.work_order_number IS NULL OR NEW.work_order_number = '' THEN
        NEW.work_order_number := generate_work_order_number(NEW.request_id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_set_work_order_number
    BEFORE INSERT ON maintenance_works
    FOR EACH ROW
    EXECUTE FUNCTION set_work_order_number();

-- =====================================================
-- 트리거 함수 - 요청 상태 자동 업데이트
-- =====================================================
CREATE OR REPLACE FUNCTION update_request_status_from_work() RETURNS TRIGGER AS $$
BEGIN
    -- 작업이 완료되면 요청도 완료로 변경
    IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
        UPDATE maintenance_requests 
        SET 
            status = 'COMPLETED',
            completed_at = NEW.actual_end_time,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.request_id;
    END IF;
    
    -- 작업이 진행중이면 요청도 진행중으로 변경
    IF NEW.status = 'IN_PROGRESS' AND OLD.status != 'IN_PROGRESS' THEN
        UPDATE maintenance_requests 
        SET 
            status = 'IN_PROGRESS',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.request_id AND status != 'IN_PROGRESS';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_request_status_from_work
    AFTER UPDATE ON maintenance_works
    FOR EACH ROW
    EXECUTE FUNCTION update_request_status_from_work();

-- =====================================================
-- 트리거 함수 - 작업 진행률 자동 업데이트
-- =====================================================
CREATE OR REPLACE FUNCTION update_work_completion_percentage() RETURNS TRIGGER AS $$
BEGIN
    -- 작업 진행 상황이 기록되면 해당 작업의 완료율 업데이트
    UPDATE maintenance_works 
    SET 
        completion_percentage = NEW.progress_percentage,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.work_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_work_completion_percentage
    AFTER INSERT OR UPDATE ON maintenance_work_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_work_completion_percentage();

-- =====================================================
-- 코멘트 추가
-- =====================================================
COMMENT ON TABLE maintenance_requests IS '유지보수 요청 관리';
COMMENT ON TABLE maintenance_works IS '유지보수 작업 관리';
COMMENT ON TABLE maintenance_work_progress IS '유지보수 작업 진행 상황 추적';
COMMENT ON TABLE maintenance_cost_details IS '유지보수 비용 상세 내역';

COMMENT ON COLUMN maintenance_requests.request_number IS '자동 생성되는 고유 요청번호';
COMMENT ON COLUMN maintenance_requests.requester_satisfaction IS '요청자 만족도 (1-5점)';
COMMENT ON COLUMN maintenance_works.work_order_number IS '자동 생성되는 작업지시서 번호';
COMMENT ON COLUMN maintenance_works.total_cost IS '총 비용 (자동 계산)';
COMMENT ON COLUMN maintenance_cost_details.total_price IS '항목별 총액 (수량 × 단가)';
COMMENT ON COLUMN maintenance_cost_details.tax_amount IS '세액 (자동 계산)';-- ====
=================================================
-- 협력업체 관리 테이블
-- =====================================================

-- 업체 유형 ENUM 타입
CREATE TYPE vendor_type AS ENUM (
    'INDIVIDUAL',        -- 개인사업자
    'CORPORATION',       -- 법인
    'PARTNERSHIP'        -- 조합/파트너십
);

-- 업체 상태 ENUM 타입
CREATE TYPE vendor_status AS ENUM (
    'ACTIVE',           -- 활성
    'INACTIVE',         -- 비활성
    'SUSPENDED',        -- 정지
    'BLACKLISTED',      -- 블랙리스트
    'UNDER_REVIEW'      -- 검토중
);

-- 계약 상태 ENUM 타입
CREATE TYPE contract_status AS ENUM (
    'DRAFT',            -- 초안
    'ACTIVE',           -- 활성
    'EXPIRED',          -- 만료
    'TERMINATED',       -- 해지
    'SUSPENDED'         -- 정지
);

-- 평가 등급 ENUM 타입
CREATE TYPE vendor_grade AS ENUM (
    'S',                -- 최우수
    'A',                -- 우수
    'B',                -- 보통
    'C',                -- 미흡
    'D'                 -- 불량
);

-- =====================================================
-- 9. 협력업체 기본 정보 테이블 (facility_vendors) - 기존 테이블 확장
-- =====================================================
-- 기존 facility_vendors 테이블을 DROP하고 새로 생성
DROP TABLE IF EXISTS facility_vendors CASCADE;

CREATE TABLE facility_vendors (
    id BIGSERIAL PRIMARY KEY,
    
    -- 기본 정보
    vendor_code VARCHAR(50) UNIQUE NOT NULL,     -- 업체 코드 (자동생성)
    company_name VARCHAR(255) NOT NULL,          -- 업체명
    vendor_type vendor_type NOT NULL,            -- 업체 유형
    business_registration_number VARCHAR(20) UNIQUE, -- 사업자등록번호
    corporate_registration_number VARCHAR(20),   -- 법인등록번호 (법인인 경우)
    
    -- 연락처 정보
    contact_person VARCHAR(255),                 -- 담당자명
    contact_phone VARCHAR(20),                   -- 대표 전화번호
    contact_mobile VARCHAR(20),                  -- 휴대폰 번호
    contact_email VARCHAR(255),                  -- 이메일
    contact_fax VARCHAR(20),                     -- 팩스번호
    
    -- 주소 정보
    address TEXT,                                -- 주소
    postal_code VARCHAR(10),                     -- 우편번호
    
    -- 전문 분야
    specialization JSONB,                        -- 전문 분야 (배열 형태)
    service_areas JSONB,                         -- 서비스 지역
    certifications JSONB,                        -- 보유 자격증/인증
    
    -- 사업 정보
    establishment_date DATE,                     -- 설립일
    employee_count INTEGER,                      -- 직원 수
    annual_revenue DECIMAL(15,2),                -- 연매출액
    
    -- 보험 및 보증
    insurance_info JSONB,                        -- 보험 정보
    guarantee_amount DECIMAL(15,2),              -- 보증금액
    guarantee_expiry_date DATE,                  -- 보증 만료일
    
    -- 평가 정보
    overall_grade vendor_grade,                  -- 종합 등급
    quality_score DECIMAL(3,1),                  -- 품질 점수 (0.0-5.0)
    reliability_score DECIMAL(3,1),              -- 신뢰도 점수 (0.0-5.0)
    cost_competitiveness_score DECIMAL(3,1),     -- 가격 경쟁력 점수 (0.0-5.0)
    
    -- 계약 정보
    preferred_vendor BOOLEAN DEFAULT false,      -- 우선 협력업체 여부
    exclusive_contract BOOLEAN DEFAULT false,    -- 전속 계약 여부
    
    -- 상태 및 관리
    status vendor_status DEFAULT 'ACTIVE',       -- 업체 상태
    registration_date DATE DEFAULT CURRENT_DATE, -- 등록일
    last_work_date DATE,                         -- 최근 작업일
    
    -- 비고 및 첨부
    notes TEXT,                                  -- 비고
    attachments JSONB,                           -- 첨부파일 (사업자등록증, 보험증서 등)
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT vendors_employee_count_check 
        CHECK (employee_count IS NULL OR employee_count >= 0),
    CONSTRAINT vendors_revenue_check 
        CHECK (annual_revenue IS NULL OR annual_revenue >= 0),
    CONSTRAINT vendors_guarantee_check 
        CHECK (guarantee_amount IS NULL OR guarantee_amount >= 0),
    CONSTRAINT vendors_quality_score_check 
        CHECK (quality_score IS NULL OR (quality_score >= 0.0 AND quality_score <= 5.0)),
    CONSTRAINT vendors_reliability_score_check 
        CHECK (reliability_score IS NULL OR (reliability_score >= 0.0 AND reliability_score <= 5.0)),
    CONSTRAINT vendors_cost_score_check 
        CHECK (cost_competitiveness_score IS NULL OR (cost_competitiveness_score >= 0.0 AND cost_competitiveness_score <= 5.0))
);

-- =====================================================
-- 10. 협력업체 계약 관리 테이블 (vendor_contracts)
-- =====================================================
CREATE TABLE vendor_contracts (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES facility_vendors(id) ON DELETE CASCADE,
    
    -- 계약 기본 정보
    contract_number VARCHAR(50) UNIQUE NOT NULL, -- 계약번호
    contract_name VARCHAR(255) NOT NULL,         -- 계약명
    contract_type VARCHAR(50) NOT NULL,          -- 계약 유형 (MAINTENANCE, REPAIR, SUPPLY, CONSULTING)
    
    -- 계약 기간
    start_date DATE NOT NULL,                    -- 계약 시작일
    end_date DATE NOT NULL,                      -- 계약 종료일
    auto_renewal BOOLEAN DEFAULT false,          -- 자동 연장 여부
    renewal_period_months INTEGER,               -- 연장 기간 (개월)
    
    -- 계약 금액
    contract_amount DECIMAL(15,2) NOT NULL,      -- 계약 금액
    payment_terms TEXT,                          -- 지급 조건
    penalty_rate DECIMAL(5,2),                   -- 위약금 비율
    
    -- 서비스 범위
    service_scope TEXT NOT NULL,                 -- 서비스 범위
    service_level_agreement TEXT,                -- SLA (서비스 수준 협약)
    response_time_hours INTEGER,                 -- 응답 시간 (시간)
    
    -- 품질 기준
    quality_standards TEXT,                      -- 품질 기준
    performance_metrics JSONB,                   -- 성과 지표
    
    -- 계약 상태
    status contract_status DEFAULT 'DRAFT',      -- 계약 상태
    signed_date DATE,                            -- 서명일
    
    -- 담당자 정보
    company_signatory VARCHAR(255),              -- 회사 서명자
    vendor_signatory VARCHAR(255),               -- 업체 서명자
    
    -- 첨부 문서
    contract_documents JSONB,                    -- 계약서 문서
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT vendor_contracts_period_check 
        CHECK (end_date > start_date),
    CONSTRAINT vendor_contracts_amount_check 
        CHECK (contract_amount >= 0),
    CONSTRAINT vendor_contracts_penalty_check 
        CHECK (penalty_rate IS NULL OR (penalty_rate >= 0 AND penalty_rate <= 100)),
    CONSTRAINT vendor_contracts_response_time_check 
        CHECK (response_time_hours IS NULL OR response_time_hours > 0),
    CONSTRAINT vendor_contracts_type_check 
        CHECK (contract_type IN ('MAINTENANCE', 'REPAIR', 'SUPPLY', 'CONSULTING', 'COMPREHENSIVE'))
);

-- =====================================================
-- 11. 협력업체 평가 테이블 (vendor_evaluations)
-- =====================================================
CREATE TABLE vendor_evaluations (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES facility_vendors(id) ON DELETE CASCADE,
    work_id BIGINT REFERENCES maintenance_works(id) ON DELETE SET NULL,
    
    -- 평가 기본 정보
    evaluation_period_start DATE NOT NULL,       -- 평가 기간 시작
    evaluation_period_end DATE NOT NULL,         -- 평가 기간 종료
    evaluation_type VARCHAR(50) NOT NULL,        -- 평가 유형 (WORK_BASED, PERIODIC, CONTRACT_RENEWAL)
    
    -- 평가 항목별 점수 (1-5점)
    work_quality_score INTEGER NOT NULL,         -- 작업 품질
    schedule_adherence_score INTEGER NOT NULL,   -- 일정 준수
    cost_effectiveness_score INTEGER NOT NULL,   -- 비용 효율성
    communication_score INTEGER NOT NULL,        -- 의사소통
    safety_compliance_score INTEGER NOT NULL,    -- 안전 준수
    customer_satisfaction_score INTEGER,         -- 고객 만족도
    
    -- 종합 평가
    total_score DECIMAL(4,1) GENERATED ALWAYS AS (
        (work_quality_score + schedule_adherence_score + cost_effectiveness_score + 
         communication_score + safety_compliance_score + COALESCE(customer_satisfaction_score, 0)) / 
        CASE WHEN customer_satisfaction_score IS NOT NULL THEN 6.0 ELSE 5.0 END
    ) STORED,                                    -- 총점 (자동 계산)
    
    final_grade vendor_grade,                    -- 최종 등급
    
    -- 상세 평가
    strengths TEXT,                              -- 강점
    weaknesses TEXT,                             -- 약점
    improvement_suggestions TEXT,                -- 개선 제안사항
    
    -- 평가자 정보
    evaluator_name VARCHAR(255) NOT NULL,       -- 평가자명
    evaluator_position VARCHAR(100),            -- 평가자 직책
    evaluation_date DATE DEFAULT CURRENT_DATE,  -- 평가일
    
    -- 후속 조치
    follow_up_actions TEXT,                      -- 후속 조치 사항
    next_evaluation_date DATE,                   -- 다음 평가 예정일
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT vendor_evaluations_period_check 
        CHECK (evaluation_period_end >= evaluation_period_start),
    CONSTRAINT vendor_evaluations_type_check 
        CHECK (evaluation_type IN ('WORK_BASED', 'PERIODIC', 'CONTRACT_RENEWAL', 'INCIDENT_BASED')),
    CONSTRAINT vendor_evaluations_scores_check 
        CHECK (work_quality_score BETWEEN 1 AND 5 AND
               schedule_adherence_score BETWEEN 1 AND 5 AND
               cost_effectiveness_score BETWEEN 1 AND 5 AND
               communication_score BETWEEN 1 AND 5 AND
               safety_compliance_score BETWEEN 1 AND 5 AND
               (customer_satisfaction_score IS NULL OR customer_satisfaction_score BETWEEN 1 AND 5))
);

-- =====================================================
-- 12. 협력업체 작업 이력 요약 테이블 (vendor_work_history_summary)
-- =====================================================
CREATE TABLE vendor_work_history_summary (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES facility_vendors(id) ON DELETE CASCADE,
    
    -- 집계 기간
    summary_year INTEGER NOT NULL,               -- 집계 년도
    summary_month INTEGER,                       -- 집계 월 (NULL이면 연간 집계)
    
    -- 작업 통계
    total_works INTEGER DEFAULT 0,               -- 총 작업 건수
    completed_works INTEGER DEFAULT 0,           -- 완료 작업 건수
    cancelled_works INTEGER DEFAULT 0,           -- 취소 작업 건수
    
    -- 비용 통계
    total_contract_amount DECIMAL(15,2) DEFAULT 0, -- 총 계약 금액
    total_actual_cost DECIMAL(15,2) DEFAULT 0,   -- 총 실제 비용
    
    -- 성과 지표
    completion_rate DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE WHEN total_works > 0 
        THEN ROUND(completed_works * 100.0 / total_works, 2)
        ELSE 0 END
    ) STORED,                                    -- 완료율
    
    avg_work_duration_hours DECIMAL(8,2),        -- 평균 작업 소요시간
    avg_quality_rating DECIMAL(3,1),             -- 평균 품질 평가
    on_time_completion_rate DECIMAL(5,2),        -- 정시 완료율
    
    -- 고객 만족도
    avg_customer_satisfaction DECIMAL(3,1),      -- 평균 고객 만족도
    complaint_count INTEGER DEFAULT 0,           -- 불만 건수
    
    -- 안전 지표
    safety_incident_count INTEGER DEFAULT 0,     -- 안전사고 건수
    safety_violation_count INTEGER DEFAULT 0,    -- 안전규정 위반 건수
    
    -- 업데이트 정보
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- 제약조건
    CONSTRAINT vendor_history_summary_year_check 
        CHECK (summary_year >= 2000 AND summary_year <= 2100),
    CONSTRAINT vendor_history_summary_month_check 
        CHECK (summary_month IS NULL OR (summary_month >= 1 AND summary_month <= 12)),
    CONSTRAINT vendor_history_summary_counts_check 
        CHECK (total_works >= 0 AND completed_works >= 0 AND cancelled_works >= 0 AND
               completed_works <= total_works AND cancelled_works <= total_works),
    CONSTRAINT vendor_history_summary_rates_check 
        CHECK (on_time_completion_rate IS NULL OR (on_time_completion_rate >= 0 AND on_time_completion_rate <= 100)),
    
    -- 유니크 제약조건
    UNIQUE(vendor_id, summary_year, summary_month)
);

-- =====================================================
-- 13. 협력업체 블랙리스트 관리 테이블 (vendor_blacklist)
-- =====================================================
CREATE TABLE vendor_blacklist (
    id BIGSERIAL PRIMARY KEY,
    vendor_id BIGINT NOT NULL REFERENCES facility_vendors(id) ON DELETE CASCADE,
    
    -- 블랙리스트 정보
    blacklist_reason TEXT NOT NULL,              -- 블랙리스트 사유
    incident_date DATE NOT NULL,                 -- 사건 발생일
    severity_level VARCHAR(20) NOT NULL,         -- 심각도 (LOW, MEDIUM, HIGH, CRITICAL)
    
    -- 기간 정보
    blacklist_start_date DATE DEFAULT CURRENT_DATE, -- 블랙리스트 시작일
    blacklist_end_date DATE,                     -- 블랙리스트 종료일 (NULL이면 영구)
    
    -- 관련 정보
    related_work_id BIGINT REFERENCES maintenance_works(id), -- 관련 작업
    financial_loss DECIMAL(12,2),                -- 재정적 손실
    
    -- 결정 정보
    decision_maker VARCHAR(255) NOT NULL,        -- 결정권자
    decision_date DATE DEFAULT CURRENT_DATE,     -- 결정일
    appeal_allowed BOOLEAN DEFAULT true,         -- 이의제기 허용 여부
    
    -- 해제 정보
    lifted_date DATE,                            -- 해제일
    lifted_by VARCHAR(255),                      -- 해제자
    lift_reason TEXT,                            -- 해제 사유
    
    -- 상태
    is_active BOOLEAN DEFAULT true,              -- 활성 상태
    
    -- 감사 필드
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT,
    updated_by BIGINT,
    
    -- 제약조건
    CONSTRAINT vendor_blacklist_severity_check 
        CHECK (severity_level IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT vendor_blacklist_period_check 
        CHECK (blacklist_end_date IS NULL OR blacklist_end_date >= blacklist_start_date),
    CONSTRAINT vendor_blacklist_lift_check 
        CHECK (lifted_date IS NULL OR lifted_date >= blacklist_start_date),
    CONSTRAINT vendor_blacklist_financial_loss_check 
        CHECK (financial_loss IS NULL OR financial_loss >= 0)
);-- ==
===================================================
-- 협력업체 관리 인덱스
-- =====================================================

-- facility_vendors 테이블 인덱스
CREATE INDEX idx_vendors_status ON facility_vendors(status);
CREATE INDEX idx_vendors_specialization ON facility_vendors USING GIN(specialization);
CREATE INDEX idx_vendors_grade ON facility_vendors(overall_grade);
CREATE INDEX idx_vendors_preferred ON facility_vendors(preferred_vendor) WHERE preferred_vendor = true;
CREATE INDEX idx_vendors_registration_date ON facility_vendors(registration_date);
CREATE INDEX idx_vendors_last_work_date ON facility_vendors(last_work_date) WHERE last_work_date IS NOT NULL;

-- vendor_contracts 테이블 인덱스
CREATE INDEX idx_vendor_contracts_vendor_id ON vendor_contracts(vendor_id);
CREATE INDEX idx_vendor_contracts_status ON vendor_contracts(status);
CREATE INDEX idx_vendor_contracts_start_date ON vendor_contracts(start_date);
CREATE INDEX idx_vendor_contracts_end_date ON vendor_contracts(end_date);
CREATE INDEX idx_vendor_contracts_expiring ON vendor_contracts(end_date) 
    WHERE status = 'ACTIVE' AND end_date <= CURRENT_DATE + INTERVAL '90 days';

-- vendor_evaluations 테이블 인덱스
CREATE INDEX idx_vendor_evaluations_vendor_id ON vendor_evaluations(vendor_id);
CREATE INDEX idx_vendor_evaluations_work_id ON vendor_evaluations(work_id) WHERE work_id IS NOT NULL;
CREATE INDEX idx_vendor_evaluations_date ON vendor_evaluations(evaluation_date);
CREATE INDEX idx_vendor_evaluations_grade ON vendor_evaluations(final_grade);
CREATE INDEX idx_vendor_evaluations_total_score ON vendor_evaluations(total_score);

-- vendor_work_history_summary 테이블 인덱스
CREATE INDEX idx_vendor_history_vendor_id ON vendor_work_history_summary(vendor_id);
CREATE INDEX idx_vendor_history_period ON vendor_work_history_summary(summary_year, summary_month);
CREATE INDEX idx_vendor_history_completion_rate ON vendor_work_history_summary(completion_rate);

-- vendor_blacklist 테이블 인덱스
CREATE INDEX idx_vendor_blacklist_vendor_id ON vendor_blacklist(vendor_id);
CREATE INDEX idx_vendor_blacklist_active ON vendor_blacklist(is_active) WHERE is_active = true;
CREATE INDEX idx_vendor_blacklist_severity ON vendor_blacklist(severity_level);
CREATE INDEX idx_vendor_blacklist_period ON vendor_blacklist(blacklist_start_date, blacklist_end_date);

-- =====================================================
-- 뷰 생성 - 협력업체 성과 대시보드
-- =====================================================
CREATE VIEW vendor_performance_dashboard AS
SELECT 
    v.id,
    v.vendor_code,
    v.company_name,
    v.overall_grade,
    v.status,
    v.preferred_vendor,
    
    -- 최근 평가 정보
    ve.total_score as latest_evaluation_score,
    ve.final_grade as latest_evaluation_grade,
    ve.evaluation_date as latest_evaluation_date,
    
    -- 작업 통계 (최근 12개월)
    COALESCE(vhs_year.total_works, 0) as works_last_12_months,
    COALESCE(vhs_year.completion_rate, 0) as completion_rate_last_12_months,
    COALESCE(vhs_year.avg_quality_rating, 0) as avg_quality_rating,
    COALESCE(vhs_year.total_actual_cost, 0) as total_cost_last_12_months,
    
    -- 계약 정보
    vc.contract_number as active_contract_number,
    vc.end_date as contract_end_date,
    CASE 
        WHEN vc.end_date <= CURRENT_DATE + INTERVAL '90 days' THEN true 
        ELSE false 
    END as contract_expiring_soon,
    
    -- 블랙리스트 상태
    CASE WHEN vb.id IS NOT NULL THEN true ELSE false END as is_blacklisted

FROM facility_vendors v
LEFT JOIN LATERAL (
    SELECT * FROM vendor_evaluations ve2 
    WHERE ve2.vendor_id = v.id 
    ORDER BY ve2.evaluation_date DESC 
    LIMIT 1
) ve ON true
LEFT JOIN vendor_work_history_summary vhs_year ON (
    v.id = vhs_year.vendor_id AND 
    vhs_year.summary_year = EXTRACT(YEAR FROM CURRENT_DATE) AND 
    vhs_year.summary_month IS NULL
)
LEFT JOIN vendor_contracts vc ON (
    v.id = vc.vendor_id AND 
    vc.status = 'ACTIVE' AND 
    vc.start_date <= CURRENT_DATE AND 
    vc.end_date >= CURRENT_DATE
)
LEFT JOIN vendor_blacklist vb ON (
    v.id = vb.vendor_id AND 
    vb.is_active = true AND 
    (vb.blacklist_end_date IS NULL OR vb.blacklist_end_date >= CURRENT_DATE)
);

-- =====================================================
-- 뷰 생성 - 협력업체 계약 현황
-- =====================================================
CREATE VIEW vendor_contract_status AS
SELECT 
    vc.id,
    vc.contract_number,
    v.company_name,
    vc.contract_type,
    vc.start_date,
    vc.end_date,
    vc.contract_amount,
    vc.status,
    
    -- 계약 상태 분류
    CASE 
        WHEN vc.status = 'ACTIVE' AND vc.end_date < CURRENT_DATE THEN 'EXPIRED'
        WHEN vc.status = 'ACTIVE' AND vc.end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 'EXPIRING_SOON'
        WHEN vc.status = 'ACTIVE' AND vc.end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 'EXPIRING_LATER'
        ELSE vc.status::text
    END as contract_status_detail,
    
    -- 계약 기간 정보
    vc.end_date - vc.start_date as contract_duration_days,
    CURRENT_DATE - vc.start_date as elapsed_days,
    vc.end_date - CURRENT_DATE as remaining_days

FROM vendor_contracts vc
JOIN facility_vendors v ON vc.vendor_id = v.id;

-- =====================================================
-- 함수 생성 - 업체 코드 자동 생성
-- =====================================================
CREATE OR REPLACE FUNCTION generate_vendor_code() RETURNS VARCHAR(50) AS $$
DECLARE
    v_year VARCHAR(2);
    v_sequence INTEGER;
    v_vendor_code VARCHAR(50);
BEGIN
    -- 현재 년도 뒤 2자리 추출
    v_year := RIGHT(EXTRACT(YEAR FROM CURRENT_DATE)::VARCHAR, 2);
    
    -- 해당 년도의 업체 순번 계산
    SELECT COALESCE(MAX(
        CASE 
            WHEN vendor_code ~ ('^VD' || v_year || '[0-9]+$')
            THEN SUBSTRING(vendor_code FROM '[0-9]+$')::INTEGER
            ELSE 0
        END
    ), 0) + 1 INTO v_sequence
    FROM facility_vendors
    WHERE EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM CURRENT_DATE);
    
    -- 업체 코드 생성: VD{YY}{순번}
    v_vendor_code := 'VD' || v_year || LPAD(v_sequence::VARCHAR, 4, '0');
    
    RETURN v_vendor_code;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 함수 생성 - 협력업체 종합 평가 점수 계산
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_vendor_overall_score(p_vendor_id BIGINT) RETURNS DECIMAL(3,1) AS $$
DECLARE
    v_avg_score DECIMAL(3,1);
    v_work_count INTEGER;
    v_recent_score DECIMAL(3,1);
BEGIN
    -- 최근 12개월 평가 점수 평균 계산
    SELECT 
        AVG(total_score),
        COUNT(*)
    INTO v_avg_score, v_work_count
    FROM vendor_evaluations
    WHERE vendor_id = p_vendor_id
    AND evaluation_date >= CURRENT_DATE - INTERVAL '12 months';
    
    -- 평가가 없는 경우 기본값 반환
    IF v_work_count = 0 THEN
        RETURN 3.0;
    END IF;
    
    -- 최근 3개월 평가가 있는 경우 가중치 적용
    SELECT AVG(total_score) INTO v_recent_score
    FROM vendor_evaluations
    WHERE vendor_id = p_vendor_id
    AND evaluation_date >= CURRENT_DATE - INTERVAL '3 months';
    
    -- 최근 평가가 있으면 70% 가중치, 전체 평균에 30% 가중치
    IF v_recent_score IS NOT NULL THEN
        RETURN ROUND((v_recent_score * 0.7 + v_avg_score * 0.3), 1);
    ELSE
        RETURN ROUND(v_avg_score, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 함수 생성 - 협력업체 등급 자동 계산
-- =====================================================
CREATE OR REPLACE FUNCTION calculate_vendor_grade(p_score DECIMAL(3,1)) RETURNS vendor_grade AS $$
BEGIN
    CASE 
        WHEN p_score >= 4.5 THEN RETURN 'S';
        WHEN p_score >= 4.0 THEN RETURN 'A';
        WHEN p_score >= 3.0 THEN RETURN 'B';
        WHEN p_score >= 2.0 THEN RETURN 'C';
        ELSE RETURN 'D';
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 트리거 함수 - 업체 코드 자동 설정
-- =====================================================
CREATE OR REPLACE FUNCTION set_vendor_code() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.vendor_code IS NULL OR NEW.vendor_code = '' THEN
        NEW.vendor_code := generate_vendor_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_set_vendor_code
    BEFORE INSERT ON facility_vendors
    FOR EACH ROW
    EXECUTE FUNCTION set_vendor_code();

-- =====================================================
-- 트리거 함수 - 평가 후 업체 등급 자동 업데이트
-- =====================================================
CREATE OR REPLACE FUNCTION update_vendor_grade_after_evaluation() RETURNS TRIGGER AS $$
DECLARE
    v_overall_score DECIMAL(3,1);
    v_new_grade vendor_grade;
BEGIN
    -- 업체의 종합 점수 계산
    v_overall_score := calculate_vendor_overall_score(NEW.vendor_id);
    
    -- 등급 계산
    v_new_grade := calculate_vendor_grade(v_overall_score);
    
    -- 업체 정보 업데이트
    UPDATE facility_vendors 
    SET 
        overall_grade = v_new_grade,
        quality_score = v_overall_score,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.vendor_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_vendor_grade_after_evaluation
    AFTER INSERT OR UPDATE ON vendor_evaluations
    FOR EACH ROW
    EXECUTE FUNCTION update_vendor_grade_after_evaluation();

-- =====================================================
-- 트리거 함수 - 작업 완료 시 업체 최근 작업일 업데이트
-- =====================================================
CREATE OR REPLACE FUNCTION update_vendor_last_work_date() RETURNS TRIGGER AS $$
BEGIN
    -- 작업이 완료된 경우 해당 업체의 최근 작업일 업데이트
    IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' AND NEW.vendor_id IS NOT NULL THEN
        UPDATE facility_vendors 
        SET 
            last_work_date = NEW.actual_end_time::DATE,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.vendor_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_vendor_last_work_date
    AFTER UPDATE ON maintenance_works
    FOR EACH ROW
    EXECUTE FUNCTION update_vendor_last_work_date();

-- =====================================================
-- 트리거 함수 - 블랙리스트 등록 시 업체 상태 자동 변경
-- =====================================================
CREATE OR REPLACE FUNCTION update_vendor_status_on_blacklist() RETURNS TRIGGER AS $$
BEGIN
    -- 블랙리스트 등록 시
    IF TG_OP = 'INSERT' AND NEW.is_active = true THEN
        UPDATE facility_vendors 
        SET 
            status = 'BLACKLISTED',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.vendor_id;
    END IF;
    
    -- 블랙리스트 해제 시
    IF TG_OP = 'UPDATE' AND OLD.is_active = true AND NEW.is_active = false THEN
        UPDATE facility_vendors 
        SET 
            status = 'ACTIVE',
            updated_at = CURRENT_TIMESTAMP
        WHERE id = NEW.vendor_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 트리거 생성
CREATE TRIGGER trigger_update_vendor_status_on_blacklist
    AFTER INSERT OR UPDATE ON vendor_blacklist
    FOR EACH ROW
    EXECUTE FUNCTION update_vendor_status_on_blacklist();

-- =====================================================
-- 저장 프로시저 - 협력업체 작업 이력 요약 업데이트
-- =====================================================
CREATE OR REPLACE FUNCTION update_vendor_work_history_summary(
    p_vendor_id BIGINT,
    p_year INTEGER,
    p_month INTEGER DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
    v_start_date DATE;
    v_end_date DATE;
    v_total_works INTEGER;
    v_completed_works INTEGER;
    v_cancelled_works INTEGER;
    v_total_contract_amount DECIMAL(15,2);
    v_total_actual_cost DECIMAL(15,2);
    v_avg_duration DECIMAL(8,2);
    v_avg_quality DECIMAL(3,1);
    v_on_time_rate DECIMAL(5,2);
    v_avg_satisfaction DECIMAL(3,1);
    v_complaint_count INTEGER;
BEGIN
    -- 집계 기간 설정
    IF p_month IS NULL THEN
        -- 연간 집계
        v_start_date := DATE(p_year || '-01-01');
        v_end_date := DATE(p_year || '-12-31');
    ELSE
        -- 월간 집계
        v_start_date := DATE(p_year || '-' || LPAD(p_month::text, 2, '0') || '-01');
        v_end_date := (v_start_date + INTERVAL '1 month - 1 day')::DATE;
    END IF;
    
    -- 작업 통계 계산
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN mw.status = 'COMPLETED' THEN 1 END),
        COUNT(CASE WHEN mw.status = 'CANCELLED' THEN 1 END),
        SUM(COALESCE(mw.total_cost, 0)),
        SUM(COALESCE(mw.total_cost, 0)),
        AVG(mw.actual_duration_hours),
        AVG(mw.work_quality_rating),
        ROUND(COUNT(CASE WHEN mw.actual_end_time <= mw.scheduled_end_date::timestamp + mw.scheduled_end_time::interval THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN mw.status = 'COMPLETED' THEN 1 END), 0), 2),
        AVG(mr.requester_satisfaction),
        0  -- complaint_count는 별도 계산 필요
    INTO 
        v_total_works, v_completed_works, v_cancelled_works,
        v_total_contract_amount, v_total_actual_cost,
        v_avg_duration, v_avg_quality, v_on_time_rate,
        v_avg_satisfaction, v_complaint_count
    FROM maintenance_works mw
    JOIN maintenance_requests mr ON mw.request_id = mr.id
    WHERE mw.vendor_id = p_vendor_id
    AND mw.created_at::DATE BETWEEN v_start_date AND v_end_date;
    
    -- 데이터 삽입 또는 업데이트
    INSERT INTO vendor_work_history_summary (
        vendor_id, summary_year, summary_month,
        total_works, completed_works, cancelled_works,
        total_contract_amount, total_actual_cost,
        avg_work_duration_hours, avg_quality_rating,
        on_time_completion_rate, avg_customer_satisfaction,
        complaint_count
    ) VALUES (
        p_vendor_id, p_year, p_month,
        COALESCE(v_total_works, 0), COALESCE(v_completed_works, 0), COALESCE(v_cancelled_works, 0),
        COALESCE(v_total_contract_amount, 0), COALESCE(v_total_actual_cost, 0),
        v_avg_duration, v_avg_quality,
        v_on_time_rate, v_avg_satisfaction,
        COALESCE(v_complaint_count, 0)
    )
    ON CONFLICT (vendor_id, summary_year, summary_month)
    DO UPDATE SET
        total_works = EXCLUDED.total_works,
        completed_works = EXCLUDED.completed_works,
        cancelled_works = EXCLUDED.cancelled_works,
        total_contract_amount = EXCLUDED.total_contract_amount,
        total_actual_cost = EXCLUDED.total_actual_cost,
        avg_work_duration_hours = EXCLUDED.avg_work_duration_hours,
        avg_quality_rating = EXCLUDED.avg_quality_rating,
        on_time_completion_rate = EXCLUDED.on_time_completion_rate,
        avg_customer_satisfaction = EXCLUDED.avg_customer_satisfaction,
        complaint_count = EXCLUDED.complaint_count,
        last_updated = CURRENT_TIMESTAMP,
        updated_at = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 코멘트 추가
-- =====================================================
COMMENT ON TABLE facility_vendors IS '협력업체 기본 정보 및 평가 관리';
COMMENT ON TABLE vendor_contracts IS '협력업체 계약 관리';
COMMENT ON TABLE vendor_evaluations IS '협력업체 성과 평가';
COMMENT ON TABLE vendor_work_history_summary IS '협력업체 작업 이력 요약 통계';
COMMENT ON TABLE vendor_blacklist IS '협력업체 블랙리스트 관리';

COMMENT ON COLUMN facility_vendors.vendor_code IS '자동 생성되는 고유 업체 코드';
COMMENT ON COLUMN facility_vendors.overall_grade IS '종합 평가 등급 (S/A/B/C/D)';
COMMENT ON COLUMN vendor_evaluations.total_score IS '총점 (자동 계산)';
COMMENT ON COLUMN vendor_work_history_summary.completion_rate IS '완료율 (자동 계산)';
COMMENT ON COLUMN vendor_blacklist.is_active IS '현재 블랙리스트 적용 여부';