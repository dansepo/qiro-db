-- =====================================================
-- 입주 프로세스 관리 시스템 테이블 생성 스크립트
-- Phase 3.3.1: 입주 프로세스 관리
-- =====================================================

-- 1. 입주 체크리스트 템플릿 테이블
CREATE TABLE IF NOT EXISTS bms.move_in_checklist_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,
    
    -- 템플릿 기본 정보
    template_name VARCHAR(100) NOT NULL,
    template_description TEXT,
    template_type VARCHAR(20) NOT NULL DEFAULT 'STANDARD',
    
    -- 체크리스트 항목들 (JSON 배열)
    checklist_items JSONB NOT NULL,
    
    -- 상태 및 설정
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_move_in_templates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_in_templates_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_move_in_templates_name UNIQUE (company_id, building_id, template_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_template_type_move_in CHECK (template_type IN (
        'STANDARD', 'PREMIUM', 'COMMERCIAL', 'STUDIO', 'FAMILY', 'CUSTOM'
    ))
);

-- 2. 입주 프로세스 테이블
CREATE TABLE IF NOT EXISTS bms.move_in_processes (
    process_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    contract_id UUID NOT NULL,
    template_id UUID,
    
    -- 프로세스 기본 정보
    process_number VARCHAR(50) NOT NULL,
    process_status VARCHAR(20) DEFAULT 'PENDING',
    
    -- 일정 정보
    scheduled_move_in_date DATE,
    actual_move_in_date DATE,
    process_start_date DATE DEFAULT CURRENT_DATE,
    process_completion_date DATE,
    
    -- 담당자 정보
    assigned_staff_id UUID,
    contact_person_name VARCHAR(100),
    contact_person_phone VARCHAR(20),
    
    -- 특이사항 및 메모
    special_requirements TEXT,
    process_notes TEXT,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_move_in_processes_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_in_processes_contract FOREIGN KEY (contract_id) REFERENCES bms.lease_contracts(contract_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_in_processes_template FOREIGN KEY (template_id) REFERENCES bms.move_in_checklist_templates(template_id) ON DELETE SET NULL,
    CONSTRAINT uk_move_in_processes_number UNIQUE (company_id, process_number),
    CONSTRAINT uk_move_in_processes_contract UNIQUE (contract_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_process_status_move_in CHECK (process_status IN (
        'PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'ON_HOLD'
    )),
    CONSTRAINT chk_move_in_dates CHECK (
        (actual_move_in_date IS NULL OR actual_move_in_date >= process_start_date) AND
        (process_completion_date IS NULL OR process_completion_date >= process_start_date)
    )
);-- 3. 
입주 체크리스트 실행 테이블
CREATE TABLE IF NOT EXISTS bms.move_in_checklist_items (
    item_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    process_id UUID NOT NULL,
    
    -- 체크리스트 항목 정보
    item_category VARCHAR(50) NOT NULL,
    item_name VARCHAR(200) NOT NULL,
    item_description TEXT,
    item_order INTEGER DEFAULT 0,
    
    -- 실행 정보
    is_required BOOLEAN DEFAULT true,
    is_completed BOOLEAN DEFAULT false,
    completion_date TIMESTAMP WITH TIME ZONE,
    completed_by UUID,
    
    -- 결과 및 메모
    completion_result VARCHAR(20) DEFAULT 'PENDING',
    completion_notes TEXT,
    attached_files JSONB,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_move_in_items_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_move_in_items_process FOREIGN KEY (process_id) REFERENCES bms.move_in_processes(process_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_completion_result_move_in CHECK (completion_result IN (
        'PENDING', 'COMPLETED', 'FAILED', 'SKIPPED', 'DEFERRED'
    )),
    CONSTRAINT chk_item_category_move_in CHECK (item_category IN (
        'DOCUMENTATION', 'INSPECTION', 'KEY_HANDOVER', 'UTILITIES', 
        'ORIENTATION', 'SECURITY', 'MAINTENANCE', 'OTHER'
    ))
);

-- 4. 열쇠 및 보안카드 관리 테이블
CREATE TABLE IF NOT EXISTS bms.key_security_management (
    key_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    process_id UUID,
    
    -- 열쇠/카드 정보
    key_type VARCHAR(20) NOT NULL,
    key_number VARCHAR(50),
    key_description VARCHAR(200),
    
    -- 발급 정보
    issued_date DATE,
    issued_to_name VARCHAR(100),
    issued_to_phone VARCHAR(20),
    issued_by UUID,
    
    -- 반납 정보
    returned_date DATE,
    returned_by_name VARCHAR(100),
    returned_condition VARCHAR(20),
    received_by UUID,
    
    -- 상태 정보
    key_status VARCHAR(20) DEFAULT 'AVAILABLE',
    is_master_key BOOLEAN DEFAULT false,
    replacement_reason TEXT,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_key_security_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_key_security_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_key_security_process FOREIGN KEY (process_id) REFERENCES bms.move_in_processes(process_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_key_type CHECK (key_type IN (
        'PHYSICAL_KEY', 'SECURITY_CARD', 'DIGITAL_KEY', 'REMOTE_CONTROL', 'OTHER'
    )),
    CONSTRAINT chk_key_status CHECK (key_status IN (
        'AVAILABLE', 'ISSUED', 'RETURNED', 'LOST', 'DAMAGED', 'REPLACED'
    )),
    CONSTRAINT chk_returned_condition CHECK (returned_condition IN (
        'GOOD', 'FAIR', 'DAMAGED', 'LOST'
    ) OR returned_condition IS NULL)
);-- 5
. 시설 사용법 안내 테이블
CREATE TABLE IF NOT EXISTS bms.facility_orientations (
    orientation_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    process_id UUID NOT NULL,
    
    -- 안내 정보
    orientation_type VARCHAR(30) NOT NULL,
    orientation_title VARCHAR(200) NOT NULL,
    orientation_content TEXT,
    
    -- 실행 정보
    scheduled_date TIMESTAMP WITH TIME ZONE,
    completed_date TIMESTAMP WITH TIME ZONE,
    conducted_by UUID,
    
    -- 참석자 정보
    attendees JSONB,
    attendance_confirmed BOOLEAN DEFAULT false,
    
    -- 자료 및 결과
    materials_provided JSONB,
    completion_status VARCHAR(20) DEFAULT 'PENDING',
    feedback_notes TEXT,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_facility_orientations_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_facility_orientations_process FOREIGN KEY (process_id) REFERENCES bms.move_in_processes(process_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_orientation_type CHECK (orientation_type IN (
        'BUILDING_TOUR', 'SAFETY_BRIEFING', 'UTILITY_GUIDE', 'AMENITY_GUIDE',
        'PARKING_GUIDE', 'WASTE_MANAGEMENT', 'EMERGENCY_PROCEDURES', 'OTHER'
    )),
    CONSTRAINT chk_completion_status_orientation CHECK (completion_status IN (
        'PENDING', 'SCHEDULED', 'COMPLETED', 'CANCELLED', 'RESCHEDULED'
    ))
);

-- 6. RLS 정책 활성화
ALTER TABLE bms.move_in_checklist_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.move_in_processes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.move_in_checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.key_security_management ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.facility_orientations ENABLE ROW LEVEL SECURITY;

-- 7. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY move_in_templates_isolation_policy ON bms.move_in_checklist_templates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY move_in_processes_isolation_policy ON bms.move_in_processes
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY move_in_items_isolation_policy ON bms.move_in_checklist_items
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY key_security_isolation_policy ON bms.key_security_management
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY facility_orientations_isolation_policy ON bms.facility_orientations
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);-- 8.
 성능 최적화 인덱스 생성
-- 입주 체크리스트 템플릿 인덱스
CREATE INDEX IF NOT EXISTS idx_move_in_templates_company_id ON bms.move_in_checklist_templates(company_id);
CREATE INDEX IF NOT EXISTS idx_move_in_templates_building_id ON bms.move_in_checklist_templates(building_id);
CREATE INDEX IF NOT EXISTS idx_move_in_templates_active ON bms.move_in_checklist_templates(is_active);

-- 입주 프로세스 인덱스
CREATE INDEX IF NOT EXISTS idx_move_in_processes_company_id ON bms.move_in_processes(company_id);
CREATE INDEX IF NOT EXISTS idx_move_in_processes_contract_id ON bms.move_in_processes(contract_id);
CREATE INDEX IF NOT EXISTS idx_move_in_processes_status ON bms.move_in_processes(process_status);
CREATE INDEX IF NOT EXISTS idx_move_in_processes_move_in_date ON bms.move_in_processes(scheduled_move_in_date);
CREATE INDEX IF NOT EXISTS idx_move_in_processes_staff ON bms.move_in_processes(assigned_staff_id);

-- 입주 체크리스트 항목 인덱스
CREATE INDEX IF NOT EXISTS idx_move_in_items_company_id ON bms.move_in_checklist_items(company_id);
CREATE INDEX IF NOT EXISTS idx_move_in_items_process_id ON bms.move_in_checklist_items(process_id);
CREATE INDEX IF NOT EXISTS idx_move_in_items_category ON bms.move_in_checklist_items(item_category);
CREATE INDEX IF NOT EXISTS idx_move_in_items_completed ON bms.move_in_checklist_items(is_completed);

-- 열쇠 및 보안카드 관리 인덱스
CREATE INDEX IF NOT EXISTS idx_key_security_company_id ON bms.key_security_management(company_id);
CREATE INDEX IF NOT EXISTS idx_key_security_unit_id ON bms.key_security_management(unit_id);
CREATE INDEX IF NOT EXISTS idx_key_security_process_id ON bms.key_security_management(process_id);
CREATE INDEX IF NOT EXISTS idx_key_security_status ON bms.key_security_management(key_status);
CREATE INDEX IF NOT EXISTS idx_key_security_type ON bms.key_security_management(key_type);

-- 시설 사용법 안내 인덱스
CREATE INDEX IF NOT EXISTS idx_facility_orientations_company_id ON bms.facility_orientations(company_id);
CREATE INDEX IF NOT EXISTS idx_facility_orientations_process_id ON bms.facility_orientations(process_id);
CREATE INDEX IF NOT EXISTS idx_facility_orientations_type ON bms.facility_orientations(orientation_type);
CREATE INDEX IF NOT EXISTS idx_facility_orientations_status ON bms.facility_orientations(completion_status);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_move_in_processes_company_status ON bms.move_in_processes(company_id, process_status);
CREATE INDEX IF NOT EXISTS idx_move_in_items_process_completed ON bms.move_in_checklist_items(process_id, is_completed);

-- 9. updated_at 자동 업데이트 트리거
CREATE TRIGGER move_in_templates_updated_at_trigger
    BEFORE UPDATE ON bms.move_in_checklist_templates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER move_in_processes_updated_at_trigger
    BEFORE UPDATE ON bms.move_in_processes
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER move_in_items_updated_at_trigger
    BEFORE UPDATE ON bms.move_in_checklist_items
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER key_security_updated_at_trigger
    BEFORE UPDATE ON bms.key_security_management
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER facility_orientations_updated_at_trigger
    BEFORE UPDATE ON bms.facility_orientations
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 10. 코멘트 추가
COMMENT ON TABLE bms.move_in_checklist_templates IS '입주 체크리스트 템플릿 테이블 - 건물별 입주 프로세스 템플릿 관리';
COMMENT ON TABLE bms.move_in_processes IS '입주 프로세스 테이블 - 계약별 입주 프로세스 진행 상황 관리';
COMMENT ON TABLE bms.move_in_checklist_items IS '입주 체크리스트 항목 테이블 - 입주 프로세스의 세부 체크리스트 항목 관리';
COMMENT ON TABLE bms.key_security_management IS '열쇠 및 보안카드 관리 테이블 - 열쇠와 보안카드 발급 및 반납 관리';
COMMENT ON TABLE bms.facility_orientations IS '시설 사용법 안내 테이블 - 입주자 대상 시설 사용법 안내 관리';

-- 스크립트 완료 메시지
SELECT '입주 프로세스 관리 시스템 테이블 생성이 완료되었습니다.' as message;