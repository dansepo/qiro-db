-- =====================================================
-- 공통 코드 테이블 생성 스크립트
-- Phase 3.1: 공통 코드 테이블 생성
-- =====================================================

-- 1. 공통 코드 그룹 테이블 생성
CREATE TABLE IF NOT EXISTS bms.code_groups (
    group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    group_code VARCHAR(50) NOT NULL,                     -- 그룹 코드 (BUILDING_TYPE, UNIT_TYPE 등)
    group_name VARCHAR(200) NOT NULL,                    -- 그룹명
    group_description TEXT,                              -- 그룹 설명
    display_order INTEGER DEFAULT 0,                     -- 표시 순서
    is_system_code BOOLEAN DEFAULT false,                -- 시스템 코드 여부 (수정 불가)
    is_active BOOLEAN DEFAULT true,                      -- 활성 상태
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_code_groups_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_code_groups_company_code UNIQUE (company_id, group_code), -- 회사 내 그룹 코드 중복 방지
    
    -- 체크 제약조건
    CONSTRAINT chk_display_order CHECK (display_order >= 0)
);

-- 2. 공통 코드 상세 테이블 생성
CREATE TABLE IF NOT EXISTS bms.common_codes (
    code_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    group_id UUID NOT NULL,
    code_value VARCHAR(50) NOT NULL,                     -- 코드 값
    code_name VARCHAR(200) NOT NULL,                     -- 코드명
    code_description TEXT,                               -- 코드 설명
    display_order INTEGER DEFAULT 0,                     -- 표시 순서
    
    -- 추가 속성 (JSON 형태로 확장 가능한 속성들)
    extra_attributes JSONB,                              -- 추가 속성 (색상, 아이콘 등)
    
    -- 계층 구조 지원
    parent_code_id UUID,                                 -- 상위 코드 ID
    depth_level INTEGER DEFAULT 0,                       -- 계층 깊이
    sort_path VARCHAR(500),                              -- 정렬 경로
    
    -- 상태 관리
    is_system_code BOOLEAN DEFAULT false,                -- 시스템 코드 여부 (수정 불가)
    is_active BOOLEAN DEFAULT true,                      -- 활성 상태
    effective_start_date DATE DEFAULT CURRENT_DATE,      -- 유효 시작일
    effective_end_date DATE,                             -- 유효 종료일
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_common_codes_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_common_codes_group FOREIGN KEY (group_id) REFERENCES bms.code_groups(group_id) ON DELETE CASCADE,
    CONSTRAINT fk_common_codes_parent FOREIGN KEY (parent_code_id) REFERENCES bms.common_codes(code_id) ON DELETE CASCADE,
    CONSTRAINT uk_common_codes_group_value UNIQUE (group_id, code_value), -- 그룹 내 코드 값 중복 방지
    
    -- 체크 제약조건
    CONSTRAINT chk_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_depth_level CHECK (depth_level >= 0),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date)
);

-- 3. RLS 정책 활성화
ALTER TABLE bms.code_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.common_codes ENABLE ROW LEVEL SECURITY;

-- 4. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY code_groups_isolation_policy ON bms.code_groups
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY common_codes_isolation_policy ON bms.common_codes
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 5. 성능 최적화 인덱스 생성
-- 코드 그룹 테이블 인덱스
CREATE INDEX idx_code_groups_company_id ON bms.code_groups(company_id);
CREATE INDEX idx_code_groups_group_code ON bms.code_groups(group_code);
CREATE INDEX idx_code_groups_is_active ON bms.code_groups(is_active);
CREATE INDEX idx_code_groups_display_order ON bms.code_groups(display_order);

-- 공통 코드 테이블 인덱스
CREATE INDEX idx_common_codes_company_id ON bms.common_codes(company_id);
CREATE INDEX idx_common_codes_group_id ON bms.common_codes(group_id);
CREATE INDEX idx_common_codes_code_value ON bms.common_codes(code_value);
CREATE INDEX idx_common_codes_parent_code_id ON bms.common_codes(parent_code_id);
CREATE INDEX idx_common_codes_is_active ON bms.common_codes(is_active);
CREATE INDEX idx_common_codes_effective_dates ON bms.common_codes(effective_start_date, effective_end_date);
CREATE INDEX idx_common_codes_display_order ON bms.common_codes(display_order);

-- 복합 인덱스
CREATE INDEX idx_code_groups_company_active ON bms.code_groups(company_id, is_active);
CREATE INDEX idx_common_codes_group_active ON bms.common_codes(group_id, is_active);
CREATE INDEX idx_common_codes_company_group ON bms.common_codes(company_id, group_id);

-- 6. updated_at 자동 업데이트 트리거
CREATE TRIGGER code_groups_updated_at_trigger
    BEFORE UPDATE ON bms.code_groups
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER common_codes_updated_at_trigger
    BEFORE UPDATE ON bms.common_codes
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 7. 공통 코드 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_common_code_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 유효 기간 검증
    IF NEW.effective_end_date IS NOT NULL AND NEW.effective_end_date < NEW.effective_start_date THEN
        RAISE EXCEPTION '유효 종료일은 시작일보다 늦어야 합니다.';
    END IF;
    
    -- 계층 구조 검증 (자기 자신을 부모로 설정 방지)
    IF NEW.parent_code_id = NEW.code_id THEN
        RAISE EXCEPTION '자기 자신을 부모 코드로 설정할 수 없습니다.';
    END IF;
    
    -- 계층 깊이 자동 계산
    IF NEW.parent_code_id IS NOT NULL THEN
        SELECT depth_level + 1, sort_path || '/' || NEW.code_value
        INTO NEW.depth_level, NEW.sort_path
        FROM bms.common_codes 
        WHERE code_id = NEW.parent_code_id;
    ELSE
        NEW.depth_level := 0;
        NEW.sort_path := NEW.code_value;
    END IF;
    
    -- 시스템 코드 수정 방지 (시스템 코드는 is_active만 변경 가능)
    IF TG_OP = 'UPDATE' AND OLD.is_system_code = true THEN
        IF OLD.code_value IS DISTINCT FROM NEW.code_value OR
           OLD.code_name IS DISTINCT FROM NEW.code_name OR
           OLD.group_id IS DISTINCT FROM NEW.group_id THEN
            RAISE EXCEPTION '시스템 코드는 수정할 수 없습니다.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. 공통 코드 검증 트리거 생성
CREATE TRIGGER trg_validate_common_code_data
    BEFORE INSERT OR UPDATE ON bms.common_codes
    FOR EACH ROW EXECUTE FUNCTION bms.validate_common_code_data();

-- 9. 공통 코드 뷰 생성 (계층 구조 포함)
CREATE OR REPLACE VIEW bms.v_common_codes_hierarchy AS
WITH RECURSIVE code_hierarchy AS (
    -- 최상위 코드들
    SELECT 
        c.code_id,
        c.company_id,
        c.group_id,
        g.group_code,
        g.group_name,
        c.code_value,
        c.code_name,
        c.code_description,
        c.parent_code_id,
        c.depth_level,
        c.sort_path,
        c.display_order,
        c.extra_attributes,
        c.is_active,
        c.effective_start_date,
        c.effective_end_date,
        ARRAY[c.code_name] as hierarchy_path,
        c.code_name as full_path
    FROM bms.common_codes c
    JOIN bms.code_groups g ON c.group_id = g.group_id
    WHERE c.parent_code_id IS NULL
    
    UNION ALL
    
    -- 하위 코드들
    SELECT 
        c.code_id,
        c.company_id,
        c.group_id,
        ch.group_code,
        ch.group_name,
        c.code_value,
        c.code_name,
        c.code_description,
        c.parent_code_id,
        c.depth_level,
        c.sort_path,
        c.display_order,
        c.extra_attributes,
        c.is_active,
        c.effective_start_date,
        c.effective_end_date,
        ch.hierarchy_path || c.code_name,
        ch.full_path || ' > ' || c.code_name
    FROM bms.common_codes c
    JOIN code_hierarchy ch ON c.parent_code_id = ch.code_id
)
SELECT * FROM code_hierarchy
ORDER BY group_code, sort_path, display_order;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_common_codes_hierarchy OWNER TO qiro;

-- 10. 활성 공통 코드 뷰 생성
CREATE OR REPLACE VIEW bms.v_active_common_codes AS
SELECT 
    c.code_id,
    c.company_id,
    c.group_id,
    g.group_code,
    g.group_name,
    c.code_value,
    c.code_name,
    c.code_description,
    c.display_order,
    c.extra_attributes,
    c.parent_code_id,
    c.depth_level,
    c.sort_path
FROM bms.common_codes c
JOIN bms.code_groups g ON c.group_id = g.group_id
WHERE c.is_active = true 
  AND g.is_active = true
  AND c.effective_start_date <= CURRENT_DATE
  AND (c.effective_end_date IS NULL OR c.effective_end_date >= CURRENT_DATE)
ORDER BY g.display_order, g.group_code, c.sort_path, c.display_order;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_active_common_codes OWNER TO qiro;

-- 11. 공통 코드 통계 뷰 생성
CREATE OR REPLACE VIEW bms.v_common_code_statistics AS
SELECT 
    g.group_id,
    g.company_id,
    g.group_code,
    g.group_name,
    COUNT(c.code_id) as total_codes,
    COUNT(CASE WHEN c.is_active = true THEN 1 END) as active_codes,
    COUNT(CASE WHEN c.is_active = false THEN 1 END) as inactive_codes,
    COUNT(CASE WHEN c.parent_code_id IS NULL THEN 1 END) as root_codes,
    MAX(c.depth_level) as max_depth_level,
    g.is_active as group_is_active
FROM bms.code_groups g
LEFT JOIN bms.common_codes c ON g.group_id = c.group_id
GROUP BY g.group_id, g.company_id, g.group_code, g.group_name, g.is_active
ORDER BY g.display_order, g.group_code;

-- RLS 정책이 통계 뷰에도 적용되도록 설정
ALTER VIEW bms.v_common_code_statistics OWNER TO qiro;

-- 12. 공통 코드 조회 함수 생성
CREATE OR REPLACE FUNCTION bms.get_code_name(
    p_group_code VARCHAR(50),
    p_code_value VARCHAR(50),
    p_company_id UUID DEFAULT NULL
)
RETURNS VARCHAR(200) AS $$
DECLARE
    v_code_name VARCHAR(200);
    v_company_id UUID;
BEGIN
    -- company_id가 제공되지 않은 경우 현재 설정에서 가져오기
    IF p_company_id IS NULL THEN
        v_company_id := (current_setting('app.current_company_id', true))::uuid;
    ELSE
        v_company_id := p_company_id;
    END IF;
    
    SELECT c.code_name INTO v_code_name
    FROM bms.common_codes c
    JOIN bms.code_groups g ON c.group_id = g.group_id
    WHERE g.group_code = p_group_code
      AND c.code_value = p_code_value
      AND c.company_id = v_company_id
      AND c.is_active = true
      AND g.is_active = true
      AND c.effective_start_date <= CURRENT_DATE
      AND (c.effective_end_date IS NULL OR c.effective_end_date >= CURRENT_DATE);
    
    RETURN COALESCE(v_code_name, p_code_value);
END;
$$ LANGUAGE plpgsql;

-- 13. 공통 코드 목록 조회 함수 생성
CREATE OR REPLACE FUNCTION bms.get_codes_by_group(
    p_group_code VARCHAR(50),
    p_company_id UUID DEFAULT NULL,
    p_include_inactive BOOLEAN DEFAULT false
)
RETURNS TABLE (
    code_value VARCHAR(50),
    code_name VARCHAR(200),
    code_description TEXT,
    display_order INTEGER,
    extra_attributes JSONB
) AS $$
DECLARE
    v_company_id UUID;
BEGIN
    -- company_id가 제공되지 않은 경우 현재 설정에서 가져오기
    IF p_company_id IS NULL THEN
        v_company_id := (current_setting('app.current_company_id', true))::uuid;
    ELSE
        v_company_id := p_company_id;
    END IF;
    
    RETURN QUERY
    SELECT 
        c.code_value,
        c.code_name,
        c.code_description,
        c.display_order,
        c.extra_attributes
    FROM bms.common_codes c
    JOIN bms.code_groups g ON c.group_id = g.group_id
    WHERE g.group_code = p_group_code
      AND c.company_id = v_company_id
      AND g.is_active = true
      AND (p_include_inactive = true OR c.is_active = true)
      AND c.effective_start_date <= CURRENT_DATE
      AND (c.effective_end_date IS NULL OR c.effective_end_date >= CURRENT_DATE)
    ORDER BY c.display_order, c.code_value;
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 3.1 공통 코드 테이블 생성이 완료되었습니다!' as result;