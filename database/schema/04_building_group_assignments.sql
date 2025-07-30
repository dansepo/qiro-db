-- =====================================================
-- QIRO 건물 그룹 배정 관리 시스템
-- Building Group Assignments 테이블 및 관련 구조 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. Building_group_assignments 테이블 생성
-- =====================================================

CREATE TABLE building_group_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 관계 정보
    group_id UUID NOT NULL REFERENCES building_groups(group_id) ON DELETE CASCADE,
    building_id BIGINT NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    
    -- 배정 이력 정보
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID REFERENCES users(user_id),
    
    -- 배정 해제 정보 (소프트 삭제 지원)
    unassigned_at TIMESTAMPTZ,
    unassigned_by UUID REFERENCES users(user_id),
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- 배정 관련 추가 정보
    assignment_reason TEXT,
    assignment_notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    -- 제약조건
    CONSTRAINT building_group_assignments_unique UNIQUE(group_id, building_id),
    CONSTRAINT chk_assignment_dates CHECK (
        unassigned_at IS NULL OR unassigned_at >= assigned_at
    ),
    CONSTRAINT chk_active_unassigned CHECK (
        NOT (is_active = true AND unassigned_at IS NOT NULL)
    )
);

-- =====================================================
-- 2. 인덱스 생성
-- =====================================================

-- 그룹별 건물 조회용 인덱스
CREATE INDEX idx_building_group_assignments_group_id ON building_group_assignments(group_id);

-- 건물별 그룹 조회용 인덱스
CREATE INDEX idx_building_group_assignments_building_id ON building_group_assignments(building_id);

-- 활성 배정 조회용 인덱스
CREATE INDEX idx_building_group_assignments_active ON building_group_assignments(is_active) 
    WHERE is_active = true;

-- 배정일 기준 정렬용 인덱스
CREATE INDEX idx_building_group_assignments_assigned_at ON building_group_assignments(assigned_at DESC);

-- 복합 인덱스: 그룹별 활성 건물
CREATE INDEX idx_building_group_assignments_group_active ON building_group_assignments(group_id, is_active) 
    WHERE is_active = true;

-- 복합 인덱스: 건물별 활성 그룹
CREATE INDEX idx_building_group_assignments_building_active ON building_group_assignments(building_id, is_active) 
    WHERE is_active = true;

-- 배정자별 이력 조회용 인덱스
CREATE INDEX idx_building_group_assignments_assigned_by ON building_group_assignments(assigned_by);

-- =====================================================
-- 3. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER building_group_assignments_updated_at_trigger
    BEFORE UPDATE ON building_group_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 4. 건물 그룹 배정 관리 함수들
-- =====================================================

-- 건물을 그룹에 배정하는 함수
CREATE OR REPLACE FUNCTION assign_building_to_group(
    p_group_id UUID,
    p_building_id BIGINT,
    p_assigned_by UUID DEFAULT NULL,
    p_assignment_reason TEXT DEFAULT NULL,
    p_assignment_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    assignment_id UUID;
    group_company_id UUID;
    building_company_id UUID;
BEGIN
    -- 그룹과 건물이 같은 조직에 속하는지 확인
    SELECT company_id INTO group_company_id
    FROM building_groups 
    WHERE group_id = p_group_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않거나 비활성화된 그룹입니다: %', p_group_id;
    END IF;
    
    -- 건물이 존재하는지 확인 (멀티테넌시 지원 시 company_id 확인 필요)
    IF NOT EXISTS (SELECT 1 FROM buildings WHERE id = p_building_id) THEN
        RAISE EXCEPTION '존재하지 않는 건물입니다: %', p_building_id;
    END IF;
    
    -- 이미 활성 배정이 있는지 확인
    IF EXISTS (
        SELECT 1 FROM building_group_assignments 
        WHERE group_id = p_group_id 
        AND building_id = p_building_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION '이미 해당 그룹에 배정된 건물입니다. 그룹: %, 건물: %', p_group_id, p_building_id;
    END IF;
    
    -- 기존 비활성 배정이 있다면 재활성화, 없다면 새로 생성
    UPDATE building_group_assignments 
    SET 
        is_active = true,
        unassigned_at = NULL,
        unassigned_by = NULL,
        assigned_at = now(),
        assigned_by = p_assigned_by,
        assignment_reason = p_assignment_reason,
        assignment_notes = p_assignment_notes,
        updated_at = now()
    WHERE group_id = p_group_id 
    AND building_id = p_building_id 
    AND is_active = false
    RETURNING assignment_id;
    
    -- 기존 배정이 없다면 새로 생성
    IF NOT FOUND THEN
        INSERT INTO building_group_assignments (
            group_id,
            building_id,
            assigned_by,
            assignment_reason,
            assignment_notes
        ) VALUES (
            p_group_id,
            p_building_id,
            p_assigned_by,
            p_assignment_reason,
            p_assignment_notes
        ) RETURNING assignment_id;
    END IF;
    
    RETURN assignment_id;
END;
$ LANGUAGE plpgsql;

-- 건물의 그룹 배정을 해제하는 함수
CREATE OR REPLACE FUNCTION unassign_building_from_group(
    p_group_id UUID,
    p_building_id BIGINT,
    p_unassigned_by UUID DEFAULT NULL,
    p_unassignment_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $
BEGIN
    UPDATE building_group_assignments 
    SET 
        is_active = false,
        unassigned_at = now(),
        unassigned_by = p_unassigned_by,
        assignment_notes = CASE 
            WHEN p_unassignment_reason IS NOT NULL THEN 
                COALESCE(assignment_notes, '') || 
                CASE WHEN assignment_notes IS NOT NULL THEN E'\n' ELSE '' END ||
                '[해제사유] ' || p_unassignment_reason
            ELSE assignment_notes
        END,
        updated_at = now()
    WHERE group_id = p_group_id 
    AND building_id = p_building_id 
    AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '활성 상태의 배정을 찾을 수 없습니다. 그룹: %, 건물: %', p_group_id, p_building_id;
    END IF;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- 그룹의 모든 건물 배정을 해제하는 함수
CREATE OR REPLACE FUNCTION unassign_all_buildings_from_group(
    p_group_id UUID,
    p_unassigned_by UUID DEFAULT NULL,
    p_unassignment_reason TEXT DEFAULT NULL
)
RETURNS INTEGER AS $
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE building_group_assignments 
    SET 
        is_active = false,
        unassigned_at = now(),
        unassigned_by = p_unassigned_by,
        assignment_notes = CASE 
            WHEN p_unassignment_reason IS NOT NULL THEN 
                COALESCE(assignment_notes, '') || 
                CASE WHEN assignment_notes IS NOT NULL THEN E'\n' ELSE '' END ||
                '[일괄해제사유] ' || p_unassignment_reason
            ELSE assignment_notes
        END,
        updated_at = now()
    WHERE group_id = p_group_id 
    AND is_active = true;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$ LANGUAGE plpgsql;

-- 건물의 모든 그룹 배정을 해제하는 함수
CREATE OR REPLACE FUNCTION unassign_building_from_all_groups(
    p_building_id BIGINT,
    p_unassigned_by UUID DEFAULT NULL,
    p_unassignment_reason TEXT DEFAULT NULL
)
RETURNS INTEGER AS $
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE building_group_assignments 
    SET 
        is_active = false,
        unassigned_at = now(),
        unassigned_by = p_unassigned_by,
        assignment_notes = CASE 
            WHEN p_unassignment_reason IS NOT NULL THEN 
                COALESCE(assignment_notes, '') || 
                CASE WHEN assignment_notes IS NOT NULL THEN E'\n' ELSE '' END ||
                '[일괄해제사유] ' || p_unassignment_reason
            ELSE assignment_notes
        END,
        updated_at = now()
    WHERE building_id = p_building_id 
    AND is_active = true;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$ LANGUAGE plpgsql;

-- 그룹별 건물 목록 조회 함수
CREATE OR REPLACE FUNCTION get_group_buildings(
    p_group_id UUID,
    p_active_only BOOLEAN DEFAULT true
)
RETURNS TABLE (
    assignment_id UUID,
    building_id BIGINT,
    building_name VARCHAR(255),
    building_address TEXT,
    building_type building_type,
    total_units INTEGER,
    assigned_at TIMESTAMPTZ,
    assigned_by_name VARCHAR(100),
    assignment_reason TEXT,
    is_active BOOLEAN
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        bga.assignment_id,
        b.id as building_id,
        b.name as building_name,
        b.address as building_address,
        b.building_type,
        b.total_units,
        bga.assigned_at,
        u.full_name as assigned_by_name,
        bga.assignment_reason,
        bga.is_active
    FROM building_group_assignments bga
    JOIN buildings b ON bga.building_id = b.id
    LEFT JOIN users u ON bga.assigned_by = u.user_id
    WHERE 
        bga.group_id = p_group_id
        AND (NOT p_active_only OR bga.is_active = true)
    ORDER BY bga.assigned_at DESC;
END;
$ LANGUAGE plpgsql;

-- 건물별 그룹 목록 조회 함수
CREATE OR REPLACE FUNCTION get_building_groups(
    p_building_id BIGINT,
    p_active_only BOOLEAN DEFAULT true
)
RETURNS TABLE (
    assignment_id UUID,
    group_id UUID,
    group_name VARCHAR(255),
    group_type building_group_type,
    assigned_at TIMESTAMPTZ,
    assigned_by_name VARCHAR(100),
    assignment_reason TEXT,
    is_active BOOLEAN
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        bga.assignment_id,
        bg.group_id,
        bg.group_name,
        bg.group_type,
        bga.assigned_at,
        u.full_name as assigned_by_name,
        bga.assignment_reason,
        bga.is_active
    FROM building_group_assignments bga
    JOIN building_groups bg ON bga.group_id = bg.group_id
    LEFT JOIN users u ON bga.assigned_by = u.user_id
    WHERE 
        bga.building_id = p_building_id
        AND (NOT p_active_only OR bga.is_active = true)
    ORDER BY bga.assigned_at DESC;
END;
$ LANGUAGE plpgsql;

-- 배정 이력 조회 함수
CREATE OR REPLACE FUNCTION get_assignment_history(
    p_group_id UUID DEFAULT NULL,
    p_building_id BIGINT DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    assignment_id UUID,
    group_id UUID,
    group_name VARCHAR(255),
    building_id BIGINT,
    building_name VARCHAR(255),
    assigned_at TIMESTAMPTZ,
    unassigned_at TIMESTAMPTZ,
    assigned_by_name VARCHAR(100),
    unassigned_by_name VARCHAR(100),
    assignment_reason TEXT,
    is_active BOOLEAN
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        bga.assignment_id,
        bg.group_id,
        bg.group_name,
        b.id as building_id,
        b.name as building_name,
        bga.assigned_at,
        bga.unassigned_at,
        u1.full_name as assigned_by_name,
        u2.full_name as unassigned_by_name,
        bga.assignment_reason,
        bga.is_active
    FROM building_group_assignments bga
    JOIN building_groups bg ON bga.group_id = bg.group_id
    JOIN buildings b ON bga.building_id = b.id
    LEFT JOIN users u1 ON bga.assigned_by = u1.user_id
    LEFT JOIN users u2 ON bga.unassigned_by = u2.user_id
    WHERE 
        (p_group_id IS NULL OR bga.group_id = p_group_id)
        AND (p_building_id IS NULL OR bga.building_id = p_building_id)
    ORDER BY bga.assigned_at DESC
    LIMIT p_limit;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. Row Level Security (RLS) 설정
-- =====================================================

-- RLS 활성화
ALTER TABLE building_group_assignments ENABLE ROW LEVEL SECURITY;

-- 조직별 데이터 격리 정책 (building_groups를 통한 간접 격리)
CREATE POLICY building_group_assignments_company_isolation_policy ON building_group_assignments
    FOR ALL
    TO application_role
    USING (
        group_id IN (
            SELECT group_id 
            FROM building_groups 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY building_group_assignments_admin_policy ON building_group_assignments
    FOR ALL
    TO postgres
    USING (true);

-- =====================================================
-- 6. 코멘트 추가
-- =====================================================

COMMENT ON TABLE building_group_assignments IS '건물과 그룹 간의 다대다 관계를 관리하는 배정 테이블';
COMMENT ON COLUMN building_group_assignments.assignment_id IS '배정 고유 식별자 (UUID)';
COMMENT ON COLUMN building_group_assignments.group_id IS '건물 그룹 식별자 (외래키)';
COMMENT ON COLUMN building_group_assignments.building_id IS '건물 식별자 (외래키)';
COMMENT ON COLUMN building_group_assignments.assigned_at IS '배정 일시';
COMMENT ON COLUMN building_group_assignments.assigned_by IS '배정 담당자 사용자 ID';
COMMENT ON COLUMN building_group_assignments.unassigned_at IS '배정 해제 일시';
COMMENT ON COLUMN building_group_assignments.unassigned_by IS '배정 해제 담당자 사용자 ID';
COMMENT ON COLUMN building_group_assignments.is_active IS '배정 활성화 상태';
COMMENT ON COLUMN building_group_assignments.assignment_reason IS '배정 사유';
COMMENT ON COLUMN building_group_assignments.assignment_notes IS '배정 관련 메모';
COMMENT ON COLUMN building_group_assignments.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN building_group_assignments.updated_at IS '레코드 수정 일시';