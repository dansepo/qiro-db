-- =====================================================
-- 고지서 템플릿 관리 시스템 테이블 생성 스크립트
-- Phase 4.1: 고지서 템플릿 관리
-- =====================================================

-- 1. 고지서 템플릿 마스터 테이블
CREATE TABLE IF NOT EXISTS bms.bill_templates (
    template_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체 템플릿
    
    -- 템플릿 기본 정보
    template_name VARCHAR(100) NOT NULL,                   -- 템플릿명
    template_description TEXT,                             -- 템플릿 설명
    template_type VARCHAR(20) NOT NULL,                    -- 템플릿 유형
    template_category VARCHAR(20) NOT NULL,                -- 템플릿 분류
    
    -- 템플릿 설정
    language_code VARCHAR(10) DEFAULT 'ko',                -- 언어 코드
    paper_size VARCHAR(10) DEFAULT 'A4',                   -- 용지 크기
    orientation VARCHAR(10) DEFAULT 'PORTRAIT',            -- 용지 방향
    
    -- 레이아웃 설정
    layout_type VARCHAR(20) NOT NULL,                      -- 레이아웃 유형
    header_height INTEGER DEFAULT 100,                     -- 헤더 높이 (px)
    footer_height INTEGER DEFAULT 80,                      -- 푸터 높이 (px)
    margin_top INTEGER DEFAULT 20,                         -- 상단 여백 (mm)
    margin_bottom INTEGER DEFAULT 20,                      -- 하단 여백 (mm)
    margin_left INTEGER DEFAULT 15,                        -- 좌측 여백 (mm)
    margin_right INTEGER DEFAULT 15,                       -- 우측 여백 (mm)
    
    -- 스타일 설정
    font_family VARCHAR(50) DEFAULT 'NanumGothic',         -- 기본 폰트
    font_size INTEGER DEFAULT 12,                          -- 기본 폰트 크기
    primary_color VARCHAR(7) DEFAULT '#2563eb',            -- 주 색상
    secondary_color VARCHAR(7) DEFAULT '#64748b',          -- 보조 색상
    
    -- 템플릿 구조 (JSON)
    template_structure JSONB NOT NULL,                     -- 템플릿 구조 정의
    style_definitions JSONB,                               -- 스타일 정의
    
    -- 표시 설정
    show_company_logo BOOLEAN DEFAULT true,                -- 회사 로고 표시
    show_qr_code BOOLEAN DEFAULT true,                     -- QR 코드 표시
    show_barcode BOOLEAN DEFAULT false,                    -- 바코드 표시
    show_payment_info BOOLEAN DEFAULT true,                -- 결제 정보 표시
    show_contact_info BOOLEAN DEFAULT true,                -- 연락처 정보 표시
    
    -- 다국어 지원
    multilingual_support BOOLEAN DEFAULT false,            -- 다국어 지원 여부
    supported_languages TEXT[],                           -- 지원 언어 목록
    
    -- 버전 관리
    version_number VARCHAR(10) DEFAULT '1.0',              -- 버전 번호
    is_default BOOLEAN DEFAULT false,                      -- 기본 템플릿 여부
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    
    -- 승인 정보
    approval_required BOOLEAN DEFAULT false,               -- 승인 필요 여부
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_templates_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_templates_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_templates_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_templates_name UNIQUE (company_id, building_id, template_name, version_number),
    
    -- 체크 제약조건
    CONSTRAINT chk_template_type CHECK (template_type IN (
        'MAINTENANCE_FEE',     -- 관리비 고지서
        'UTILITY_BILL',        -- 공과금 고지서
        'PARKING_FEE',         -- 주차비 고지서
        'LATE_FEE',            -- 연체료 고지서
        'RECEIPT',             -- 영수증
        'NOTICE',              -- 공지사항
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_template_category CHECK (template_category IN (
        'STANDARD',            -- 표준
        'PREMIUM',             -- 프리미엄
        'SIMPLE',              -- 간단
        'DETAILED',            -- 상세
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_language_code CHECK (language_code IN ('ko', 'en', 'zh', 'ja')),
    CONSTRAINT chk_paper_size CHECK (paper_size IN ('A4', 'A3', 'LETTER', 'LEGAL')),
    CONSTRAINT chk_orientation CHECK (orientation IN ('PORTRAIT', 'LANDSCAPE')),
    CONSTRAINT chk_layout_type CHECK (layout_type IN (
        'SINGLE_COLUMN',       -- 단일 컬럼
        'TWO_COLUMN',          -- 2컬럼
        'THREE_COLUMN',        -- 3컬럼
        'GRID',                -- 그리드
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_dimensions CHECK (
        header_height > 0 AND footer_height > 0 AND
        margin_top >= 0 AND margin_bottom >= 0 AND
        margin_left >= 0 AND margin_right >= 0 AND
        font_size > 0
    )
);

-- 2. 템플릿 섹션 정의 테이블
CREATE TABLE IF NOT EXISTS bms.template_sections (
    section_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 섹션 기본 정보
    section_name VARCHAR(100) NOT NULL,                   -- 섹션명
    section_type VARCHAR(20) NOT NULL,                    -- 섹션 유형
    section_title VARCHAR(200),                           -- 섹션 제목
    section_description TEXT,                             -- 섹션 설명
    
    -- 위치 및 크기
    position_x INTEGER NOT NULL DEFAULT 0,                -- X 좌표
    position_y INTEGER NOT NULL DEFAULT 0,                -- Y 좌표
    width INTEGER NOT NULL DEFAULT 100,                   -- 너비 (%)
    height INTEGER,                                       -- 높이 (px, NULL이면 자동)
    
    -- 순서 및 표시
    display_order INTEGER NOT NULL DEFAULT 1,             -- 표시 순서
    is_visible BOOLEAN DEFAULT true,                      -- 표시 여부
    is_required BOOLEAN DEFAULT false,                    -- 필수 여부
    
    -- 스타일 설정
    background_color VARCHAR(7),                          -- 배경색
    border_style VARCHAR(20),                             -- 테두리 스타일
    border_width INTEGER DEFAULT 0,                       -- 테두리 두께
    border_color VARCHAR(7),                              -- 테두리 색상
    padding_top INTEGER DEFAULT 5,                        -- 상단 패딩
    padding_bottom INTEGER DEFAULT 5,                     -- 하단 패딩
    padding_left INTEGER DEFAULT 5,                       -- 좌측 패딩
    padding_right INTEGER DEFAULT 5,                      -- 우측 패딩
    
    -- 내용 설정
    content_type VARCHAR(20) NOT NULL,                    -- 내용 유형
    content_source VARCHAR(50),                           -- 내용 소스
    content_template TEXT,                                -- 내용 템플릿
    content_format JSONB,                                 -- 내용 포맷 설정
    
    -- 조건부 표시
    display_condition JSONB,                              -- 표시 조건
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_sections_template FOREIGN KEY (template_id) REFERENCES bms.bill_templates(template_id) ON DELETE CASCADE,
    CONSTRAINT fk_sections_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_sections_name UNIQUE (template_id, section_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_section_type CHECK (section_type IN (
        'HEADER',              -- 헤더
        'FOOTER',              -- 푸터
        'COMPANY_INFO',        -- 회사 정보
        'RECIPIENT_INFO',      -- 수신자 정보
        'BILL_SUMMARY',        -- 고지서 요약
        'FEE_DETAILS',         -- 관리비 상세
        'PAYMENT_INFO',        -- 결제 정보
        'NOTICE',              -- 공지사항
        'QR_CODE',             -- QR 코드
        'BARCODE',             -- 바코드
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_content_type CHECK (content_type IN (
        'TEXT',                -- 텍스트
        'TABLE',               -- 테이블
        'IMAGE',               -- 이미지
        'QR_CODE',             -- QR 코드
        'BARCODE',             -- 바코드
        'CHART',               -- 차트
        'DYNAMIC'              -- 동적 내용
    )),
    CONSTRAINT chk_border_style CHECK (border_style IN (
        'NONE', 'SOLID', 'DASHED', 'DOTTED', 'DOUBLE'
    )),
    CONSTRAINT chk_position_size CHECK (
        position_x >= 0 AND position_y >= 0 AND
        width > 0 AND width <= 100 AND
        (height IS NULL OR height > 0) AND
        display_order > 0
    ),
    CONSTRAINT chk_padding CHECK (
        padding_top >= 0 AND padding_bottom >= 0 AND
        padding_left >= 0 AND padding_right >= 0
    )
);

-- 3. 템플릿 필드 정의 테이블
CREATE TABLE IF NOT EXISTS bms.template_fields (
    field_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    section_id UUID NOT NULL,
    template_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 필드 기본 정보
    field_name VARCHAR(100) NOT NULL,                     -- 필드명
    field_label VARCHAR(200),                             -- 필드 라벨
    field_type VARCHAR(20) NOT NULL,                      -- 필드 유형
    data_source VARCHAR(50) NOT NULL,                     -- 데이터 소스
    
    -- 위치 및 크기
    position_x INTEGER NOT NULL DEFAULT 0,                -- X 좌표 (섹션 내)
    position_y INTEGER NOT NULL DEFAULT 0,                -- Y 좌표 (섹션 내)
    width INTEGER NOT NULL DEFAULT 100,                   -- 너비 (%)
    height INTEGER,                                       -- 높이 (px)
    
    -- 표시 설정
    display_order INTEGER NOT NULL DEFAULT 1,             -- 표시 순서
    is_visible BOOLEAN DEFAULT true,                      -- 표시 여부
    is_required BOOLEAN DEFAULT false,                    -- 필수 여부
    
    -- 스타일 설정
    font_family VARCHAR(50),                              -- 폰트
    font_size INTEGER,                                    -- 폰트 크기
    font_weight VARCHAR(20) DEFAULT 'NORMAL',             -- 폰트 굵기
    font_color VARCHAR(7) DEFAULT '#000000',              -- 폰트 색상
    text_align VARCHAR(10) DEFAULT 'LEFT',                -- 텍스트 정렬
    
    -- 데이터 포맷
    data_format VARCHAR(50),                              -- 데이터 포맷
    format_pattern VARCHAR(100),                          -- 포맷 패턴
    prefix_text VARCHAR(50),                              -- 접두사
    suffix_text VARCHAR(50),                              -- 접미사
    
    -- 조건부 표시
    display_condition JSONB,                              -- 표시 조건
    default_value TEXT,                                   -- 기본값
    
    -- 다국어 지원
    multilingual_labels JSONB,                            -- 다국어 라벨
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_fields_section FOREIGN KEY (section_id) REFERENCES bms.template_sections(section_id) ON DELETE CASCADE,
    CONSTRAINT fk_fields_template FOREIGN KEY (template_id) REFERENCES bms.bill_templates(template_id) ON DELETE CASCADE,
    CONSTRAINT fk_fields_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_fields_name UNIQUE (section_id, field_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_field_type CHECK (field_type IN (
        'TEXT',                -- 텍스트
        'NUMBER',              -- 숫자
        'CURRENCY',            -- 통화
        'DATE',                -- 날짜
        'DATETIME',            -- 날짜시간
        'BOOLEAN',             -- 불린
        'IMAGE',               -- 이미지
        'QR_CODE',             -- QR 코드
        'BARCODE'              -- 바코드
    )),
    CONSTRAINT chk_font_weight CHECK (font_weight IN ('NORMAL', 'BOLD', 'LIGHT')),
    CONSTRAINT chk_text_align CHECK (text_align IN ('LEFT', 'CENTER', 'RIGHT', 'JUSTIFY')),
    CONSTRAINT chk_field_position_size CHECK (
        position_x >= 0 AND position_y >= 0 AND
        width > 0 AND width <= 100 AND
        (height IS NULL OR height > 0) AND
        display_order > 0
    )
);

-- 4. 템플릿 사용 이력 테이블
CREATE TABLE IF NOT EXISTS bms.template_usage_history (
    usage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 사용 정보
    used_for_type VARCHAR(20) NOT NULL,                   -- 사용 목적
    used_for_id UUID,                                     -- 사용 대상 ID
    usage_context JSONB,                                  -- 사용 컨텍스트
    
    -- 생성 정보
    generated_format VARCHAR(10) NOT NULL,                -- 생성 포맷
    generated_file_path TEXT,                             -- 생성 파일 경로
    generated_file_size BIGINT,                           -- 파일 크기
    
    -- 성능 정보
    generation_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    generation_end_time TIMESTAMP WITH TIME ZONE,
    generation_duration_ms INTEGER,                       -- 생성 시간 (밀리초)
    
    -- 결과 정보
    generation_status VARCHAR(20) NOT NULL,               -- 생성 상태
    error_message TEXT,                                   -- 오류 메시지
    
    -- 사용자 정보
    generated_by UUID,                                    -- 생성자
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_usage_template FOREIGN KEY (template_id) REFERENCES bms.bill_templates(template_id) ON DELETE CASCADE,
    CONSTRAINT fk_usage_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_usage_generator FOREIGN KEY (generated_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_used_for_type CHECK (used_for_type IN (
        'BILL_GENERATION',     -- 고지서 생성
        'PREVIEW',             -- 미리보기
        'TEST',                -- 테스트
        'EXPORT'               -- 내보내기
    )),
    CONSTRAINT chk_generated_format CHECK (generated_format IN (
        'PDF',                 -- PDF
        'HTML',                -- HTML
        'PNG',                 -- PNG 이미지
        'JPEG',                -- JPEG 이미지
        'DOCX'                 -- Word 문서
    )),
    CONSTRAINT chk_generation_status CHECK (generation_status IN (
        'SUCCESS',             -- 성공
        'FAILED',              -- 실패
        'CANCELLED',           -- 취소
        'TIMEOUT'              -- 시간 초과
    )),
    CONSTRAINT chk_generation_times CHECK (
        generation_end_time IS NULL OR generation_end_time >= generation_start_time
    )
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.bill_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.template_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.template_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.template_usage_history ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY bill_templates_isolation_policy ON bms.bill_templates
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY template_sections_isolation_policy ON bms.template_sections
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY template_fields_isolation_policy ON bms.template_fields
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY template_usage_history_isolation_policy ON bms.template_usage_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 템플릿 마스터 인덱스
CREATE INDEX idx_templates_company_id ON bms.bill_templates(company_id);
CREATE INDEX idx_templates_building_id ON bms.bill_templates(building_id);
CREATE INDEX idx_templates_type ON bms.bill_templates(template_type);
CREATE INDEX idx_templates_category ON bms.bill_templates(template_category);
CREATE INDEX idx_templates_active ON bms.bill_templates(is_active);
CREATE INDEX idx_templates_default ON bms.bill_templates(is_default);
CREATE INDEX idx_templates_language ON bms.bill_templates(language_code);

-- 템플릿 섹션 인덱스
CREATE INDEX idx_sections_template_id ON bms.template_sections(template_id);
CREATE INDEX idx_sections_company_id ON bms.template_sections(company_id);
CREATE INDEX idx_sections_type ON bms.template_sections(section_type);
CREATE INDEX idx_sections_order ON bms.template_sections(display_order);
CREATE INDEX idx_sections_visible ON bms.template_sections(is_visible);

-- 템플릿 필드 인덱스
CREATE INDEX idx_fields_section_id ON bms.template_fields(section_id);
CREATE INDEX idx_fields_template_id ON bms.template_fields(template_id);
CREATE INDEX idx_fields_company_id ON bms.template_fields(company_id);
CREATE INDEX idx_fields_type ON bms.template_fields(field_type);
CREATE INDEX idx_fields_source ON bms.template_fields(data_source);
CREATE INDEX idx_fields_order ON bms.template_fields(display_order);

-- 사용 이력 인덱스
CREATE INDEX idx_usage_template_id ON bms.template_usage_history(template_id);
CREATE INDEX idx_usage_company_id ON bms.template_usage_history(company_id);
CREATE INDEX idx_usage_type ON bms.template_usage_history(used_for_type);
CREATE INDEX idx_usage_status ON bms.template_usage_history(generation_status);
CREATE INDEX idx_usage_created_at ON bms.template_usage_history(created_at DESC);

-- 복합 인덱스
CREATE INDEX idx_templates_company_active ON bms.bill_templates(company_id, is_active);
CREATE INDEX idx_templates_type_active ON bms.bill_templates(template_type, is_active);
CREATE INDEX idx_sections_template_order ON bms.template_sections(template_id, display_order);
CREATE INDEX idx_fields_section_order ON bms.template_fields(section_id, display_order);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER bill_templates_updated_at_trigger
    BEFORE UPDATE ON bms.bill_templates
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER template_sections_updated_at_trigger
    BEFORE UPDATE ON bms.template_sections
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER template_fields_updated_at_trigger
    BEFORE UPDATE ON bms.template_fields
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 템플릿 관리 뷰 생성
CREATE OR REPLACE VIEW bms.v_template_overview AS
SELECT 
    bt.template_id,
    bt.company_id,
    c.company_name,
    bt.building_id,
    b.name as building_name,
    bt.template_name,
    bt.template_type,
    bt.template_category,
    bt.language_code,
    bt.version_number,
    bt.is_default,
    bt.is_active,
    COUNT(ts.section_id) as section_count,
    COUNT(tf.field_id) as field_count,
    COUNT(tuh.usage_id) as usage_count,
    MAX(tuh.created_at) as last_used_at,
    bt.created_at,
    bt.updated_at
FROM bms.bill_templates bt
JOIN bms.companies c ON bt.company_id = c.company_id
LEFT JOIN bms.buildings b ON bt.building_id = b.building_id
LEFT JOIN bms.template_sections ts ON bt.template_id = ts.template_id
LEFT JOIN bms.template_fields tf ON bt.template_id = tf.template_id
LEFT JOIN bms.template_usage_history tuh ON bt.template_id = tuh.template_id
    AND tuh.created_at >= CURRENT_DATE - INTERVAL '30 days'  -- 최근 30일
GROUP BY bt.template_id, c.company_name, b.name
ORDER BY c.company_name, b.name, bt.template_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_template_overview OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 4.1 고지서 템플릿 관리 테이블 생성이 완료되었습니다!' as result;