-- =====================================================
-- 시스템 설정 테이블 생성 스크립트
-- Phase 3.3: 시스템 설정 테이블
-- =====================================================

-- 1. 시스템 설정 테이블 생성
CREATE TABLE IF NOT EXISTS bms.system_settings (
    setting_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                   -- NULL이면 회사 전체 설정
    
    -- 설정 기본 정보
    setting_category VARCHAR(50) NOT NULL,              -- 설정 분류
    setting_key VARCHAR(100) NOT NULL,                  -- 설정 키
    setting_name VARCHAR(200) NOT NULL,                 -- 설정명
    setting_description TEXT,                           -- 설정 설명
    
    -- 설정 값
    setting_value TEXT,                                 -- 설정 값 (문자열)
    setting_value_type VARCHAR(20) DEFAULT 'STRING',    -- 값 타입
    default_value TEXT,                                 -- 기본값
    
    -- JSON 설정 (복합 설정용)
    json_value JSONB,                                   -- JSON 형태 설정값
    
    -- 설정 제약
    is_required BOOLEAN DEFAULT false,                  -- 필수 설정 여부
    is_system_setting BOOLEAN DEFAULT false,            -- 시스템 설정 여부 (수정 제한)
    is_encrypted BOOLEAN DEFAULT false,                 -- 암호화 필요 여부
    
    -- 값 검증
    validation_rule TEXT,                               -- 검증 규칙 (정규식 등)
    allowed_values TEXT[],                              -- 허용 값 목록
    min_value DECIMAL(15,4),                            -- 최소값
    max_value DECIMAL(15,4),                            -- 최대값
    
    -- 표시 설정
    display_order INTEGER DEFAULT 0,                    -- 표시 순서
    is_visible BOOLEAN DEFAULT true,                    -- 화면 표시 여부
    is_editable BOOLEAN DEFAULT true,                   -- 편집 가능 여부
    
    -- 그룹화
    setting_group VARCHAR(100),                         -- 설정 그룹
    parent_setting_id UUID,                             -- 상위 설정 ID
    
    -- 유효 기간
    effective_start_date DATE DEFAULT CURRENT_DATE,
    effective_end_date DATE,
    
    -- 상태
    is_active BOOLEAN DEFAULT true,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_system_settings_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_system_settings_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_system_settings_parent FOREIGN KEY (parent_setting_id) REFERENCES bms.system_settings(setting_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_setting_value_type CHECK (setting_value_type IN (
        'STRING',          -- 문자열
        'INTEGER',         -- 정수
        'DECIMAL',         -- 소수
        'BOOLEAN',         -- 불린
        'DATE',            -- 날짜
        'TIME',            -- 시간
        'DATETIME',        -- 날짜시간
        'JSON',            -- JSON
        'EMAIL',           -- 이메일
        'URL',             -- URL
        'PASSWORD',        -- 패스워드
        'FILE_PATH'        -- 파일 경로
    )),
    CONSTRAINT chk_setting_category CHECK (setting_category IN (
        'GENERAL',         -- 일반 설정
        'BILLING',         -- 청구 설정
        'NOTIFICATION',    -- 알림 설정
        'SECURITY',        -- 보안 설정
        'INTEGRATION',     -- 연동 설정
        'REPORT',          -- 보고서 설정
        'MAINTENANCE',     -- 유지보수 설정
        'BACKUP',          -- 백업 설정
        'PERFORMANCE',     -- 성능 설정
        'UI',              -- 사용자 인터페이스 설정
        'WORKFLOW',        -- 워크플로우 설정
        'CUSTOM'           -- 사용자 정의 설정
    )),
    CONSTRAINT chk_display_order CHECK (display_order >= 0),
    CONSTRAINT chk_effective_dates CHECK (effective_end_date IS NULL OR effective_end_date >= effective_start_date),
    CONSTRAINT chk_min_max_value CHECK (max_value IS NULL OR min_value IS NULL OR max_value >= min_value)
);

-- 유니크 인덱스 (회사/건물별 설정 키 중복 방지)
CREATE UNIQUE INDEX uk_system_settings_key 
ON bms.system_settings(company_id, setting_key, COALESCE(building_id::text, 'NULL'))
WHERE is_active = true;

-- 2. 시스템 설정 이력 테이블 생성
CREATE TABLE IF NOT EXISTS bms.system_setting_history (
    history_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 변경 정보
    change_type VARCHAR(20) NOT NULL,                   -- 변경 유형
    old_value TEXT,                                     -- 이전 값
    new_value TEXT,                                     -- 새 값
    old_json_value JSONB,                               -- 이전 JSON 값
    new_json_value JSONB,                               -- 새 JSON 값
    
    -- 변경 사유
    change_reason TEXT,                                 -- 변경 사유
    change_description TEXT,                            -- 변경 설명
    
    -- 변경자 정보
    changed_by UUID,                                    -- 변경자 ID
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- 변경 일시
    client_ip INET,                                     -- 클라이언트 IP
    user_agent TEXT,                                    -- 사용자 에이전트
    
    -- 제약조건
    CONSTRAINT fk_setting_history_setting FOREIGN KEY (setting_id) REFERENCES bms.system_settings(setting_id) ON DELETE CASCADE,
    CONSTRAINT fk_setting_history_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_change_type CHECK (change_type IN ('CREATE', 'UPDATE', 'DELETE', 'ACTIVATE', 'DEACTIVATE'))
);

-- 3. RLS 정책 활성화
ALTER TABLE bms.system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.system_setting_history ENABLE ROW LEVEL SECURITY;

-- 4. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY system_settings_isolation_policy ON bms.system_settings
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY system_setting_history_isolation_policy ON bms.system_setting_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 5. 성능 최적화 인덱스 생성
-- 시스템 설정 테이블 인덱스
CREATE INDEX idx_system_settings_company_id ON bms.system_settings(company_id);
CREATE INDEX idx_system_settings_building_id ON bms.system_settings(building_id);
CREATE INDEX idx_system_settings_category ON bms.system_settings(setting_category);
CREATE INDEX idx_system_settings_key ON bms.system_settings(setting_key);
CREATE INDEX idx_system_settings_group ON bms.system_settings(setting_group);
CREATE INDEX idx_system_settings_parent_id ON bms.system_settings(parent_setting_id);
CREATE INDEX idx_system_settings_is_active ON bms.system_settings(is_active);
CREATE INDEX idx_system_settings_effective_dates ON bms.system_settings(effective_start_date, effective_end_date);

-- 이력 테이블 인덱스
CREATE INDEX idx_setting_history_setting_id ON bms.system_setting_history(setting_id);
CREATE INDEX idx_setting_history_company_id ON bms.system_setting_history(company_id);
CREATE INDEX idx_setting_history_changed_at ON bms.system_setting_history(changed_at DESC);
CREATE INDEX idx_setting_history_changed_by ON bms.system_setting_history(changed_by);
CREATE INDEX idx_setting_history_change_type ON bms.system_setting_history(change_type);

-- 복합 인덱스
CREATE INDEX idx_system_settings_company_category ON bms.system_settings(company_id, setting_category);
CREATE INDEX idx_system_settings_company_active ON bms.system_settings(company_id, is_active);
CREATE INDEX idx_system_settings_category_group ON bms.system_settings(setting_category, setting_group);

-- 6. updated_at 자동 업데이트 트리거
CREATE TRIGGER system_settings_updated_at_trigger
    BEFORE UPDATE ON bms.system_settings
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 7. 시스템 설정 검증 함수
CREATE OR REPLACE FUNCTION bms.validate_system_setting_data()
RETURNS TRIGGER AS $$
BEGIN
    -- 유효 기간 검증
    IF NEW.effective_end_date IS NOT NULL AND NEW.effective_end_date < NEW.effective_start_date THEN
        RAISE EXCEPTION '유효 종료일은 시작일보다 늦어야 합니다.';
    END IF;
    
    -- 값 범위 검증
    IF NEW.max_value IS NOT NULL AND NEW.min_value IS NOT NULL AND NEW.max_value < NEW.min_value THEN
        RAISE EXCEPTION '최대값은 최소값보다 크거나 같아야 합니다.';
    END IF;
    
    -- 필수 설정 값 검증
    IF NEW.is_required = true AND NEW.setting_value IS NULL AND NEW.json_value IS NULL THEN
        RAISE EXCEPTION '필수 설정은 값이 설정되어야 합니다.';
    END IF;
    
    -- 값 타입별 검증
    IF NEW.setting_value IS NOT NULL THEN
        CASE NEW.setting_value_type
            WHEN 'INTEGER' THEN
                BEGIN
                    PERFORM NEW.setting_value::INTEGER;
                EXCEPTION WHEN OTHERS THEN
                    RAISE EXCEPTION '정수 형식이 아닙니다: %', NEW.setting_value;
                END;
                
            WHEN 'DECIMAL' THEN
                BEGIN
                    PERFORM NEW.setting_value::DECIMAL;
                EXCEPTION WHEN OTHERS THEN
                    RAISE EXCEPTION '소수 형식이 아닙니다: %', NEW.setting_value;
                END;
                
            WHEN 'BOOLEAN' THEN
                IF NEW.setting_value NOT IN ('true', 'false', '1', '0', 'yes', 'no', 'on', 'off') THEN
                    RAISE EXCEPTION '불린 형식이 아닙니다: %', NEW.setting_value;
                END IF;
                
            WHEN 'EMAIL' THEN
                IF NEW.setting_value !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$' THEN
                    RAISE EXCEPTION '올바른 이메일 형식이 아닙니다: %', NEW.setting_value;
                END IF;
                
            WHEN 'URL' THEN
                IF NEW.setting_value !~ '^https?://[^\\s/$.?#].[^\\s]*$' THEN
                    RAISE EXCEPTION '올바른 URL 형식이 아닙니다: %', NEW.setting_value;
                END IF;
            ELSE
                -- 다른 타입들은 검증하지 않음
                NULL;
        END CASE;
    END IF;
    
    -- 허용 값 목록 검증
    IF NEW.allowed_values IS NOT NULL AND array_length(NEW.allowed_values, 1) > 0 THEN
        IF NEW.setting_value IS NOT NULL AND NOT (NEW.setting_value = ANY(NEW.allowed_values)) THEN
            RAISE EXCEPTION '허용되지 않은 값입니다: %. 허용 값: %', NEW.setting_value, array_to_string(NEW.allowed_values, ', ');
        END IF;
    END IF;
    
    -- 시스템 설정 수정 제한
    IF TG_OP = 'UPDATE' AND OLD.is_system_setting = true THEN
        IF OLD.setting_key IS DISTINCT FROM NEW.setting_key OR
           OLD.setting_value_type IS DISTINCT FROM NEW.setting_value_type THEN
            RAISE EXCEPTION '시스템 설정의 핵심 속성은 수정할 수 없습니다.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. 시스템 설정 검증 트리거 생성
CREATE TRIGGER trg_validate_system_setting_data
    BEFORE INSERT OR UPDATE ON bms.system_settings
    FOR EACH ROW EXECUTE FUNCTION bms.validate_system_setting_data();

-- 9. 시스템 설정 이력 기록 함수
CREATE OR REPLACE FUNCTION bms.log_system_setting_changes()
RETURNS TRIGGER AS $$
BEGIN
    -- INSERT 시 생성 이력 기록
    IF TG_OP = 'INSERT' THEN
        INSERT INTO bms.system_setting_history (
            setting_id, company_id, change_type, new_value, new_json_value,
            change_reason, changed_by
        ) VALUES (
            NEW.setting_id, NEW.company_id, 'CREATE', NEW.setting_value, NEW.json_value,
            '설정 생성', NEW.created_by
        );
        RETURN NEW;
    END IF;
    
    -- UPDATE 시 변경 이력 기록
    IF TG_OP = 'UPDATE' THEN
        -- 값이 변경된 경우에만 기록
        IF OLD.setting_value IS DISTINCT FROM NEW.setting_value OR
           OLD.json_value IS DISTINCT FROM NEW.json_value OR
           OLD.is_active IS DISTINCT FROM NEW.is_active THEN
            
            INSERT INTO bms.system_setting_history (
                setting_id, company_id, change_type, old_value, new_value,
                old_json_value, new_json_value, change_reason, changed_by
            ) VALUES (
                NEW.setting_id, NEW.company_id, 
                CASE WHEN OLD.is_active IS DISTINCT FROM NEW.is_active THEN
                    CASE WHEN NEW.is_active THEN 'ACTIVATE' ELSE 'DEACTIVATE' END
                ELSE 'UPDATE' END,
                OLD.setting_value, NEW.setting_value,
                OLD.json_value, NEW.json_value,
                '설정 변경', NEW.updated_by
            );
        END IF;
        RETURN NEW;
    END IF;
    
    -- DELETE 시 삭제 이력 기록
    IF TG_OP = 'DELETE' THEN
        INSERT INTO bms.system_setting_history (
            setting_id, company_id, change_type, old_value, old_json_value,
            change_reason
        ) VALUES (
            OLD.setting_id, OLD.company_id, 'DELETE', OLD.setting_value, OLD.json_value,
            '설정 삭제'
        );
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 10. 시스템 설정 이력 트리거 생성
CREATE TRIGGER trg_log_system_setting_changes
    AFTER INSERT OR UPDATE OR DELETE ON bms.system_settings
    FOR EACH ROW EXECUTE FUNCTION bms.log_system_setting_changes();

-- 11. 활성 시스템 설정 뷰 생성
CREATE OR REPLACE VIEW bms.v_active_system_settings AS
SELECT 
    s.setting_id,
    s.company_id,
    s.building_id,
    b.name as building_name,
    s.setting_category,
    s.setting_key,
    s.setting_name,
    s.setting_description,
    s.setting_value,
    s.setting_value_type,
    s.default_value,
    s.json_value,
    s.is_required,
    s.is_system_setting,
    s.is_encrypted,
    s.validation_rule,
    s.allowed_values,
    s.min_value,
    s.max_value,
    s.display_order,
    s.is_visible,
    s.is_editable,
    s.setting_group,
    s.parent_setting_id,
    s.effective_start_date,
    s.effective_end_date
FROM bms.system_settings s
LEFT JOIN bms.buildings b ON s.building_id = b.building_id
WHERE s.is_active = true
  AND s.effective_start_date <= CURRENT_DATE
  AND (s.effective_end_date IS NULL OR s.effective_end_date >= CURRENT_DATE)
ORDER BY s.setting_category, s.setting_group, s.display_order, s.setting_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_active_system_settings OWNER TO qiro;

-- 12. 시스템 설정 조회 함수 생성
CREATE OR REPLACE FUNCTION bms.get_setting_value(
    p_setting_key VARCHAR(100),
    p_company_id UUID DEFAULT NULL,
    p_building_id UUID DEFAULT NULL,
    p_default_value TEXT DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
    v_setting_value TEXT;
    v_company_id UUID;
BEGIN
    -- company_id가 제공되지 않은 경우 현재 설정에서 가져오기
    IF p_company_id IS NULL THEN
        v_company_id := (current_setting('app.current_company_id', true))::uuid;
    ELSE
        v_company_id := p_company_id;
    END IF;
    
    -- 건물별 설정 우선 조회
    IF p_building_id IS NOT NULL THEN
        SELECT setting_value INTO v_setting_value
        FROM bms.system_settings
        WHERE setting_key = p_setting_key
          AND company_id = v_company_id
          AND building_id = p_building_id
          AND is_active = true
          AND effective_start_date <= CURRENT_DATE
          AND (effective_end_date IS NULL OR effective_end_date >= CURRENT_DATE)
        LIMIT 1;
        
        IF v_setting_value IS NOT NULL THEN
            RETURN v_setting_value;
        END IF;
    END IF;
    
    -- 회사 공통 설정 조회
    SELECT setting_value INTO v_setting_value
    FROM bms.system_settings
    WHERE setting_key = p_setting_key
      AND company_id = v_company_id
      AND building_id IS NULL
      AND is_active = true
      AND effective_start_date <= CURRENT_DATE
      AND (effective_end_date IS NULL OR effective_end_date >= CURRENT_DATE)
    LIMIT 1;
    
    -- 설정값이 없으면 기본값 반환
    RETURN COALESCE(v_setting_value, p_default_value);
END;
$$ LANGUAGE plpgsql;

-- 13. JSON 설정 조회 함수 생성
CREATE OR REPLACE FUNCTION bms.get_json_setting(
    p_setting_key VARCHAR(100),
    p_company_id UUID DEFAULT NULL,
    p_building_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_json_value JSONB;
    v_company_id UUID;
BEGIN
    -- company_id가 제공되지 않은 경우 현재 설정에서 가져오기
    IF p_company_id IS NULL THEN
        v_company_id := (current_setting('app.current_company_id', true))::uuid;
    ELSE
        v_company_id := p_company_id;
    END IF;
    
    -- 건물별 설정 우선 조회
    IF p_building_id IS NOT NULL THEN
        SELECT json_value INTO v_json_value
        FROM bms.system_settings
        WHERE setting_key = p_setting_key
          AND company_id = v_company_id
          AND building_id = p_building_id
          AND is_active = true
          AND effective_start_date <= CURRENT_DATE
          AND (effective_end_date IS NULL OR effective_end_date >= CURRENT_DATE)
        LIMIT 1;
        
        IF v_json_value IS NOT NULL THEN
            RETURN v_json_value;
        END IF;
    END IF;
    
    -- 회사 공통 설정 조회
    SELECT json_value INTO v_json_value
    FROM bms.system_settings
    WHERE setting_key = p_setting_key
      AND company_id = v_company_id
      AND building_id IS NULL
      AND is_active = true
      AND effective_start_date <= CURRENT_DATE
      AND (effective_end_date IS NULL OR effective_end_date >= CURRENT_DATE)
    LIMIT 1;
    
    RETURN v_json_value;
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 3.3 시스템 설정 테이블 생성이 완료되었습니다!' as result;