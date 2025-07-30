-- =====================================================
-- QIRO 건물 그룹 관리 시스템
-- Building Groups 테이블 및 관련 구조 생성
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 건물 그룹 관련 ENUM 타입 정의
-- =====================================================

-- 건물 그룹 타입
CREATE TYPE building_group_type AS ENUM (
    'COST_ALLOCATION',    -- 비용 배분 그룹
    'MANAGEMENT_UNIT',    -- 관리 단위 그룹
    'GEOGRAPHIC',         -- 지역별 그룹
    'CUSTOM'              -- 사용자 정의 그룹
);

-- =====================================================
-- 2. Building_groups 테이블 생성
-- =====================================================

CREATE TABLE building_groups (
    group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES companies(company_id) ON DELETE CASCADE,
    
    -- 기본 정보
    group_name VARCHAR(255) NOT NULL,
    group_type building_group_type NOT NULL,
    description TEXT,
    
    -- 상태 관리
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- 추가 설정 (JSONB로 확장 가능한 구조)
    group_settings JSONB DEFAULT '{}',
    
    -- 감사 필드
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_by UUID REFERENCES users(user_id),
    updated_by UUID REFERENCES users(user_id),
    
    -- 제약조건
    CONSTRAINT building_groups_company_name_unique UNIQUE(company_id, group_name),
    CONSTRAINT chk_group_name_length CHECK (LENGTH(TRIM(group_name)) >= 2),
    CONSTRAINT chk_group_settings_valid CHECK (jsonb_typeof(group_settings) = 'object')
);

-- =====================================================
-- 3. 인덱스 생성
-- =====================================================

-- 조직별 그룹 조회용 인덱스
CREATE INDEX idx_building_groups_company_id ON building_groups(company_id);

-- 그룹 타입별 조회용 인덱스
CREATE INDEX idx_building_groups_type ON building_groups(group_type);

-- 활성 그룹 조회용 인덱스
CREATE INDEX idx_building_groups_active ON building_groups(is_active) WHERE is_active = true;

-- 그룹명 검색용 인덱스 (한국어 지원)
CREATE INDEX idx_building_groups_name_search ON building_groups 
    USING gin(to_tsvector('korean', group_name));

-- 생성일 기준 정렬용 인덱스
CREATE INDEX idx_building_groups_created_at ON building_groups(created_at DESC);

-- 복합 인덱스: 조직별 활성 그룹
CREATE INDEX idx_building_groups_company_active ON building_groups(company_id, is_active) 
    WHERE is_active = true;

-- 복합 인덱스: 조직별 그룹 타입
CREATE INDEX idx_building_groups_company_type ON building_groups(company_id, group_type);

-- =====================================================
-- 4. 트리거 설정
-- =====================================================

-- updated_at 자동 업데이트 트리거 (update_updated_at_column 함수가 이미 존재한다고 가정)
CREATE TRIGGER building_groups_updated_at_trigger
    BEFORE UPDATE ON building_groups
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 5. 건물 그룹 관리 함수들
-- =====================================================

-- 그룹 생성 함수
CREATE OR REPLACE FUNCTION create_building_group(
    p_company_id UUID,
    p_group_name VARCHAR(255),
    p_group_type building_group_type,
    p_description TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL,
    p_group_settings JSONB DEFAULT '{}'
)
RETURNS UUID AS $
DECLARE
    new_group_id UUID;
BEGIN
    -- 그룹명 중복 검사
    IF EXISTS (
        SELECT 1 FROM building_groups 
        WHERE company_id = p_company_id 
        AND group_name = p_group_name 
        AND is_active = true
    ) THEN
        RAISE EXCEPTION '이미 존재하는 그룹명입니다: %', p_group_name;
    END IF;
    
    -- 그룹 생성
    INSERT INTO building_groups (
        company_id,
        group_name,
        group_type,
        description,
        created_by,
        group_settings
    ) VALUES (
        p_company_id,
        TRIM(p_group_name),
        p_group_type,
        p_description,
        p_created_by,
        p_group_settings
    ) RETURNING group_id INTO new_group_id;
    
    RETURN new_group_id;
END;
$ LANGUAGE plpgsql;

-- 그룹 수정 함수
CREATE OR REPLACE FUNCTION update_building_group(
    p_group_id UUID,
    p_group_name VARCHAR(255) DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_group_settings JSONB DEFAULT NULL,
    p_updated_by UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $
DECLARE
    current_company_id UUID;
BEGIN
    -- 그룹 존재 여부 및 회사 ID 확인
    SELECT company_id INTO current_company_id
    FROM building_groups 
    WHERE group_id = p_group_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 그룹입니다: %', p_group_id;
    END IF;
    
    -- 그룹명 변경 시 중복 검사
    IF p_group_name IS NOT NULL AND EXISTS (
        SELECT 1 FROM building_groups 
        WHERE company_id = current_company_id 
        AND group_name = TRIM(p_group_name)
        AND group_id != p_group_id
        AND is_active = true
    ) THEN
        RAISE EXCEPTION '이미 존재하는 그룹명입니다: %', p_group_name;
    END IF;
    
    -- 그룹 정보 업데이트
    UPDATE building_groups 
    SET 
        group_name = COALESCE(TRIM(p_group_name), group_name),
        description = COALESCE(p_description, description),
        group_settings = COALESCE(p_group_settings, group_settings),
        updated_by = p_updated_by,
        updated_at = now()
    WHERE group_id = p_group_id;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- 그룹 비활성화 함수 (소프트 삭제)
CREATE OR REPLACE FUNCTION deactivate_building_group(
    p_group_id UUID,
    p_updated_by UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $
BEGIN
    UPDATE building_groups 
    SET 
        is_active = false,
        updated_by = p_updated_by,
        updated_at = now()
    WHERE group_id = p_group_id AND is_active = true;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않거나 이미 비활성화된 그룹입니다: %', p_group_id;
    END IF;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- 그룹 활성화 함수
CREATE OR REPLACE FUNCTION activate_building_group(
    p_group_id UUID,
    p_updated_by UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $
BEGIN
    UPDATE building_groups 
    SET 
        is_active = true,
        updated_by = p_updated_by,
        updated_at = now()
    WHERE group_id = p_group_id AND is_active = false;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않거나 이미 활성화된 그룹입니다: %', p_group_id;
    END IF;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- 조직별 그룹 목록 조회 함수
CREATE OR REPLACE FUNCTION get_company_building_groups(
    p_company_id UUID,
    p_group_type building_group_type DEFAULT NULL,
    p_active_only BOOLEAN DEFAULT true
)
RETURNS TABLE (
    group_id UUID,
    group_name VARCHAR(255),
    group_type building_group_type,
    description TEXT,
    is_active BOOLEAN,
    building_count BIGINT,
    user_count BIGINT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        bg.group_id,
        bg.group_name,
        bg.group_type,
        bg.description,
        bg.is_active,
        COALESCE(building_counts.building_count, 0) as building_count,
        COALESCE(user_counts.user_count, 0) as user_count,
        bg.created_at,
        bg.updated_at
    FROM building_groups bg
    LEFT JOIN (
        SELECT 
            bga.group_id,
            COUNT(*) as building_count
        FROM building_group_assignments bga
        GROUP BY bga.group_id
    ) building_counts ON bg.group_id = building_counts.group_id
    LEFT JOIN (
        SELECT 
            uga.group_id,
            COUNT(*) as user_count
        FROM user_group_assignments uga
        WHERE uga.is_active = true
        GROUP BY uga.group_id
    ) user_counts ON bg.group_id = user_counts.group_id
    WHERE 
        bg.company_id = p_company_id
        AND (p_group_type IS NULL OR bg.group_type = p_group_type)
        AND (NOT p_active_only OR bg.is_active = true)
    ORDER BY bg.created_at DESC;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. Row Level Security (RLS) 설정
-- =====================================================

-- RLS 활성화
ALTER TABLE building_groups ENABLE ROW LEVEL SECURITY;

-- 조직별 데이터 격리 정책
CREATE POLICY building_groups_company_isolation_policy ON building_groups
    FOR ALL
    TO application_role
    USING (company_id = current_setting('app.current_company_id', true)::UUID);

-- 시스템 관리자는 모든 데이터 접근 가능
CREATE POLICY building_groups_admin_policy ON building_groups
    FOR ALL
    TO postgres
    USING (true);

-- =====================================================
-- 7. 코멘트 추가
-- =====================================================

COMMENT ON TABLE building_groups IS '조직별 건물 그룹 관리 테이블';
COMMENT ON COLUMN building_groups.group_id IS '그룹 고유 식별자 (UUID)';
COMMENT ON COLUMN building_groups.company_id IS '소속 회사 식별자 (외래키)';
COMMENT ON COLUMN building_groups.group_name IS '그룹명 (조직 내 유일)';
COMMENT ON COLUMN building_groups.group_type IS '그룹 타입 (COST_ALLOCATION, MANAGEMENT_UNIT, GEOGRAPHIC, CUSTOM)';
COMMENT ON COLUMN building_groups.description IS '그룹 설명';
COMMENT ON COLUMN building_groups.is_active IS '그룹 활성화 상태';
COMMENT ON COLUMN building_groups.group_settings IS '그룹별 추가 설정 (JSONB)';
COMMENT ON COLUMN building_groups.created_at IS '생성 일시';
COMMENT ON COLUMN building_groups.updated_at IS '수정 일시';
COMMENT ON COLUMN building_groups.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN building_groups.updated_by IS '수정자 사용자 ID';

-- ENUM 타입에 대한 코멘트
COMMENT ON TYPE building_group_type IS '건물 그룹 타입: COST_ALLOCATION(비용배분), MANAGEMENT_UNIT(관리단위), GEOGRAPHIC(지역별), CUSTOM(사용자정의)';