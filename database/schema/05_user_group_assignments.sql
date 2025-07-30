-- =====================================================
-- QIRO 사용자 그룹 배정 관리 시스템
-- User Group Assignments 테이블 및 관련 구조 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 사용자 그룹 접근 권한 ENUM 타입 정의
-- =====================================================

-- 접근 권한 레벨
CREATE TYPE access_level AS ENUM (
    'read',     -- 읽기 권한
    'write',    -- 읽기/쓰기 권한
    'admin'     -- 관리자 권한 (모든 권한)
);

-- =====================================================
-- 2. User_group_assignments 테이블 생성
-- =====================================================

CREATE TABLE user_group_assignments (
    assignment_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- 관계 정보
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    group_id UUID NOT NULL REFERENCES building_groups(group_id) ON DELETE CASCADE,
    
    -- 권한 정보
    access_level access_level NOT NULL DEFAULT 'read',
    
    -- 배정 이력 정보
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    assigned_by UUID REFERENCES users(user_id),
    
    -- 배정 만료 및 상태 관리
    expires_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- 배정 해제 정보 (소프트 삭제 지원)
    unassigned_at TIMESTAMPTZ,
    unassigned_by UUID REFERENCES users(user_id),
    
    -- 배정 관련 추가 정보
    assignment_reason TEXT,
    assignment_notes TEXT,
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);    -- 제약조건

    CONSTRAINT user_group_assignments_unique UNIQUE(user_id, group_id),
    CONSTRAINT chk_assignment_dates CHECK (
        unassigned_at IS NULL OR unassigned_at >= assigned_at
    ),
    CONSTRAINT chk_expires_at CHECK (
        expires_at IS NULL OR expires_at > assigned_at
    ),
    CONSTRAINT chk_active_unassigned CHECK (
        NOT (is_active = true AND unassigned_at IS NOT NULL)
    ),
    CONSTRAINT chk_active_expired CHECK (
        NOT (is_active = true AND expires_at IS NOT NULL AND expires_at <= now())
    )
);

-- =====================================================
-- 3. 인덱스 생성
-- =====================================================

-- 사용자별 그룹 조회용 인덱스
CREATE INDEX idx_user_group_assignments_user_id ON user_group_assignments(user_id);

-- 그룹별 사용자 조회용 인덱스
CREATE INDEX idx_user_group_assignments_group_id ON user_group_assignments(group_id);

-- 활성 배정 조회용 인덱스
CREATE INDEX idx_user_group_assignments_active ON user_group_assignments(is_active) 
    WHERE is_active = true;

-- 권한 레벨별 조회용 인덱스
CREATE INDEX idx_user_group_assignments_access_level ON user_group_assignments(access_level);

-- 배정일 기준 정렬용 인덱스
CREATE INDEX idx_user_group_assignments_assigned_at ON user_group_assignments(assigned_at DESC);

-- 만료일 기준 조회용 인덱스
CREATE INDEX idx_user_group_assignments_expires_at ON user_group_assignments(expires_at) 
    WHERE expires_at IS NOT NULL;

-- 복합 인덱스: 사용자별 활성 그룹
CREATE INDEX idx_user_group_assignments_user_active ON user_group_assignments(user_id, is_active) 
    WHERE is_active = true;

-- 복합 인덱스: 그룹별 활성 사용자
CREATE INDEX idx_user_group_assignments_group_active ON user_group_assignments(group_id, is_active) 
    WHERE is_active = true;

-- 복합 인덱스: 권한별 활성 배정
CREATE INDEX idx_user_group_assignments_access_active ON user_group_assignments(access_level, is_active) 
    WHERE is_active = true;

-- 배정자별 이력 조회용 인덱스
CREATE INDEX idx_user_group_assignments_assigned_by ON user_group_assignments(assigned_by);-
- =====================================================
-- 4. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 트리거
CREATE TRIGGER user_group_assignments_updated_at_trigger
    BEFORE UPDATE ON user_group_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 만료된 배정 자동 비활성화 트리거 함수
CREATE OR REPLACE FUNCTION auto_deactivate_expired_assignments()
RETURNS TRIGGER AS $
BEGIN
    -- 만료일이 현재 시간보다 이전이면 자동으로 비활성화
    IF NEW.expires_at IS NOT NULL AND NEW.expires_at <= now() THEN
        NEW.is_active = false;
        NEW.unassigned_at = now();
        NEW.assignment_notes = COALESCE(NEW.assignment_notes, '') || 
                              CASE WHEN NEW.assignment_notes IS NOT NULL THEN E'\n' ELSE '' END ||
                              '[자동만료] ' || to_char(NEW.expires_at, 'YYYY-MM-DD HH24:MI:SS');
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- 만료 자동 처리 트리거
CREATE TRIGGER user_group_assignments_auto_expire_trigger
    BEFORE INSERT OR UPDATE ON user_group_assignments
    FOR EACH ROW
    EXECUTE FUNCTION auto_deactivate_expired_assignments();

-- =====================================================
-- 5. 사용자 그룹 배정 관리 함수들
-- =====================================================

-- 사용자를 그룹에 배정하는 함수
CREATE OR REPLACE FUNCTION assign_user_to_group(
    p_user_id UUID,
    p_group_id UUID,
    p_access_level access_level DEFAULT 'read',
    p_assigned_by UUID DEFAULT NULL,
    p_expires_at TIMESTAMPTZ DEFAULT NULL,
    p_assignment_reason TEXT DEFAULT NULL,
    p_assignment_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $
DECLARE
    assignment_id UUID;
    user_company_id UUID;
    group_company_id UUID;
BEGIN
    -- 사용자와 그룹이 같은 조직에 속하는지 확인
    SELECT company_id INTO user_company_id
    FROM users 
    WHERE user_id = p_user_id AND status = 'ACTIVE';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않거나 비활성화된 사용자입니다: %', p_user_id;
    END IF;
    
    SELECT company_id INTO group_company_id
    FROM building_groups 
    WHERE group_id = p_group_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않거나 비활성화된 그룹입니다: %', p_group_id;
    END IF;
    
    IF user_company_id != group_company_id THEN
        RAISE EXCEPTION '사용자와 그룹이 다른 조직에 속해 있습니다. 사용자: %, 그룹: %', user_company_id, group_company_id;
    END IF;    -
- 이미 활성 배정이 있는지 확인
    IF EXISTS (
        SELECT 1 FROM user_group_assignments 
        WHERE user_id = p_user_id 
        AND group_id = p_group_id 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION '이미 해당 그룹에 배정된 사용자입니다. 사용자: %, 그룹: %', p_user_id, p_group_id;
    END IF;
    
    -- 기존 비활성 배정이 있다면 재활성화, 없다면 새로 생성
    UPDATE user_group_assignments 
    SET 
        is_active = true,
        access_level = p_access_level,
        unassigned_at = NULL,
        unassigned_by = NULL,
        assigned_at = now(),
        assigned_by = p_assigned_by,
        expires_at = p_expires_at,
        assignment_reason = p_assignment_reason,
        assignment_notes = p_assignment_notes,
        updated_at = now()
    WHERE user_id = p_user_id 
    AND group_id = p_group_id 
    AND is_active = false
    RETURNING assignment_id;
    
    -- 기존 배정이 없다면 새로 생성
    IF NOT FOUND THEN
        INSERT INTO user_group_assignments (
            user_id,
            group_id,
            access_level,
            assigned_by,
            expires_at,
            assignment_reason,
            assignment_notes
        ) VALUES (
            p_user_id,
            p_group_id,
            p_access_level,
            p_assigned_by,
            p_expires_at,
            p_assignment_reason,
            p_assignment_notes
        ) RETURNING assignment_id;
    END IF;
    
    RETURN assignment_id;
END;
$ LANGUAGE plpgsql;

-- 사용자의 그룹 배정을 해제하는 함수
CREATE OR REPLACE FUNCTION unassign_user_from_group(
    p_user_id UUID,
    p_group_id UUID,
    p_unassigned_by UUID DEFAULT NULL,
    p_unassignment_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $
BEGIN
    UPDATE user_group_assignments 
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
    WHERE user_id = p_user_id 
    AND group_id = p_group_id 
    AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '활성 상태의 배정을 찾을 수 없습니다. 사용자: %, 그룹: %', p_user_id, p_group_id;
    END IF;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;-- 사용자의 권한 레
벨을 변경하는 함수
CREATE OR REPLACE FUNCTION update_user_group_access_level(
    p_user_id UUID,
    p_group_id UUID,
    p_new_access_level access_level,
    p_updated_by UUID DEFAULT NULL,
    p_update_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $
BEGIN
    UPDATE user_group_assignments 
    SET 
        access_level = p_new_access_level,
        updated_at = now(),
        assignment_notes = CASE 
            WHEN p_update_reason IS NOT NULL THEN 
                COALESCE(assignment_notes, '') || 
                CASE WHEN assignment_notes IS NOT NULL THEN E'\n' ELSE '' END ||
                '[권한변경] ' || p_update_reason
            ELSE assignment_notes
        END
    WHERE user_id = p_user_id 
    AND group_id = p_group_id 
    AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '활성 상태의 배정을 찾을 수 없습니다. 사용자: %, 그룹: %', p_user_id, p_group_id;
    END IF;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- 그룹의 모든 사용자 배정을 해제하는 함수
CREATE OR REPLACE FUNCTION unassign_all_users_from_group(
    p_group_id UUID,
    p_unassigned_by UUID DEFAULT NULL,
    p_unassignment_reason TEXT DEFAULT NULL
)
RETURNS INTEGER AS $
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE user_group_assignments 
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

-- 사용자의 모든 그룹 배정을 해제하는 함수
CREATE OR REPLACE FUNCTION unassign_user_from_all_groups(
    p_user_id UUID,
    p_unassigned_by UUID DEFAULT NULL,
    p_unassignment_reason TEXT DEFAULT NULL
)
RETURNS INTEGER AS $
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE user_group_assignments 
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
    WHERE user_id = p_user_id 
    AND is_active = true;
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$ LANGUAGE plpgsql;-- 사용자별 그
룹 목록 조회 함수
CREATE OR REPLACE FUNCTION get_user_groups(
    p_user_id UUID,
    p_active_only BOOLEAN DEFAULT true
)
RETURNS TABLE (
    assignment_id UUID,
    group_id UUID,
    group_name VARCHAR(255),
    group_type building_group_type,
    access_level access_level,
    assigned_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    assigned_by_name VARCHAR(100),
    assignment_reason TEXT,
    is_active BOOLEAN,
    building_count BIGINT
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        uga.assignment_id,
        bg.group_id,
        bg.group_name,
        bg.group_type,
        uga.access_level,
        uga.assigned_at,
        uga.expires_at,
        u.full_name as assigned_by_name,
        uga.assignment_reason,
        uga.is_active,
        COALESCE(building_counts.building_count, 0) as building_count
    FROM user_group_assignments uga
    JOIN building_groups bg ON uga.group_id = bg.group_id
    LEFT JOIN users u ON uga.assigned_by = u.user_id
    LEFT JOIN (
        SELECT 
            bga.group_id,
            COUNT(*) as building_count
        FROM building_group_assignments bga
        WHERE bga.is_active = true
        GROUP BY bga.group_id
    ) building_counts ON bg.group_id = building_counts.group_id
    WHERE 
        uga.user_id = p_user_id
        AND (NOT p_active_only OR uga.is_active = true)
        AND bg.is_active = true
    ORDER BY uga.assigned_at DESC;
END;
$ LANGUAGE plpgsql;

-- 그룹별 사용자 목록 조회 함수
CREATE OR REPLACE FUNCTION get_group_users(
    p_group_id UUID,
    p_active_only BOOLEAN DEFAULT true
)
RETURNS TABLE (
    assignment_id UUID,
    user_id UUID,
    full_name VARCHAR(100),
    email VARCHAR(255),
    department VARCHAR(100),
    position VARCHAR(100),
    access_level access_level,
    assigned_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    assigned_by_name VARCHAR(100),
    assignment_reason TEXT,
    is_active BOOLEAN
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        uga.assignment_id,
        u.user_id,
        u.full_name,
        u.email,
        u.department,
        u.position,
        uga.access_level,
        uga.assigned_at,
        uga.expires_at,
        u2.full_name as assigned_by_name,
        uga.assignment_reason,
        uga.is_active
    FROM user_group_assignments uga
    JOIN users u ON uga.user_id = u.user_id
    LEFT JOIN users u2 ON uga.assigned_by = u2.user_id
    WHERE 
        uga.group_id = p_group_id
        AND (NOT p_active_only OR uga.is_active = true)
        AND u.status = 'ACTIVE'
    ORDER BY uga.assigned_at DESC;
END;
$ LANGUAGE plpgsql;-- 사용자의
 특정 그룹에 대한 권한 확인 함수
CREATE OR REPLACE FUNCTION check_user_group_access(
    p_user_id UUID,
    p_group_id UUID,
    p_required_access access_level DEFAULT 'read'
)
RETURNS BOOLEAN AS $
DECLARE
    user_access access_level;
BEGIN
    SELECT access_level INTO user_access
    FROM user_group_assignments 
    WHERE user_id = p_user_id 
    AND group_id = p_group_id 
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > now());
    
    IF NOT FOUND THEN
        RETURN false;
    END IF;
    
    -- 권한 레벨 체크 (admin > write > read)
    CASE p_required_access
        WHEN 'read' THEN
            RETURN user_access IN ('read', 'write', 'admin');
        WHEN 'write' THEN
            RETURN user_access IN ('write', 'admin');
        WHEN 'admin' THEN
            RETURN user_access = 'admin';
        ELSE
            RETURN false;
    END CASE;
END;
$ LANGUAGE plpgsql;

-- 만료된 배정 자동 정리 함수 (스케줄러용)
CREATE OR REPLACE FUNCTION cleanup_expired_assignments()
RETURNS INTEGER AS $
DECLARE
    affected_count INTEGER;
BEGIN
    UPDATE user_group_assignments 
    SET 
        is_active = false,
        unassigned_at = now(),
        assignment_notes = COALESCE(assignment_notes, '') || 
                          CASE WHEN assignment_notes IS NOT NULL THEN E'\n' ELSE '' END ||
                          '[자동만료] ' || to_char(expires_at, 'YYYY-MM-DD HH24:MI:SS'),
        updated_at = now()
    WHERE 
        is_active = true 
        AND expires_at IS NOT NULL 
        AND expires_at <= now();
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$ LANGUAGE plpgsql;

-- 배정 이력 조회 함수
CREATE OR REPLACE FUNCTION get_assignment_history_detailed(
    p_user_id UUID DEFAULT NULL,
    p_group_id UUID DEFAULT NULL,
    p_limit INTEGER DEFAULT 100
)
RETURNS TABLE (
    assignment_id UUID,
    user_id UUID,
    user_name VARCHAR(100),
    group_id UUID,
    group_name VARCHAR(255),
    access_level access_level,
    assigned_at TIMESTAMPTZ,
    unassigned_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    assigned_by_name VARCHAR(100),
    unassigned_by_name VARCHAR(100),
    assignment_reason TEXT,
    is_active BOOLEAN
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        uga.assignment_id,
        u.user_id,
        u.full_name as user_name,
        bg.group_id,
        bg.group_name,
        uga.access_level,
        uga.assigned_at,
        uga.unassigned_at,
        uga.expires_at,
        u1.full_name as assigned_by_name,
        u2.full_name as unassigned_by_name,
        uga.assignment_reason,
        uga.is_active
    FROM user_group_assignments uga
    JOIN users u ON uga.user_id = u.user_id
    JOIN building_groups bg ON uga.group_id = bg.group_id
    LEFT JOIN users u1 ON uga.assigned_by = u1.user_id
    LEFT JOIN users u2 ON uga.unassigned_by = u2.user_id
    WHERE 
        (p_user_id IS NULL OR uga.user_id = p_user_id)
        AND (p_group_id IS NULL OR uga.group_id = p_group_id)
    ORDER BY uga.assigned_at DESC
    LIMIT p_limit;
END;
$ LANGUAGE plpgsql;-
- =====================================================
-- 6. Row Level Security (RLS) 설정
-- =====================================================

-- RLS 활성화
ALTER TABLE user_group_assignments ENABLE ROW LEVEL SECURITY;

-- 조직별 데이터 격리 정책 (building_groups를 통한 간접 격리)
CREATE POLICY user_group_assignments_company_isolation_policy ON user_group_assignments
    FOR ALL
    TO application_role
    USING (
        group_id IN (
            SELECT group_id 
            FROM building_groups 
            WHERE company_id = current_setting('app.current_company_id', true)::UUID
        )
    );

-- 사용자 자신의 배정 정보 접근 정책
CREATE POLICY user_group_assignments_self_access_policy ON user_group_assignments
    FOR SELECT
    TO application_role
    USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY user_group_assignments_admin_policy ON user_group_assignments
    FOR ALL
    TO postgres
    USING (true);

-- =====================================================
-- 7. 코멘트 추가
-- =====================================================

COMMENT ON TABLE user_group_assignments IS '사용자와 건물 그룹 간의 담당자 배치를 관리하는 테이블';
COMMENT ON COLUMN user_group_assignments.assignment_id IS '배정 고유 식별자 (UUID)';
COMMENT ON COLUMN user_group_assignments.user_id IS '사용자 식별자 (외래키)';
COMMENT ON COLUMN user_group_assignments.group_id IS '건물 그룹 식별자 (외래키)';
COMMENT ON COLUMN user_group_assignments.access_level IS '접근 권한 레벨 (read, write, admin)';
COMMENT ON COLUMN user_group_assignments.assigned_at IS '배정 일시';
COMMENT ON COLUMN user_group_assignments.assigned_by IS '배정 담당자 사용자 ID';
COMMENT ON COLUMN user_group_assignments.expires_at IS '배정 만료 일시';
COMMENT ON COLUMN user_group_assignments.is_active IS '배정 활성화 상태';
COMMENT ON COLUMN user_group_assignments.unassigned_at IS '배정 해제 일시';
COMMENT ON COLUMN user_group_assignments.unassigned_by IS '배정 해제 담당자 사용자 ID';
COMMENT ON COLUMN user_group_assignments.assignment_reason IS '배정 사유';
COMMENT ON COLUMN user_group_assignments.assignment_notes IS '배정 관련 메모';
COMMENT ON COLUMN user_group_assignments.created_at IS '레코드 생성 일시';
COMMENT ON COLUMN user_group_assignments.updated_at IS '레코드 수정 일시';

-- ENUM 타입에 대한 코멘트
COMMENT ON TYPE access_level IS '접근 권한 레벨: read(읽기), write(읽기/쓰기), admin(관리자)';