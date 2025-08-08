-- =====================================================
-- 추가 테이블 및 컬럼 한글 커멘트
-- =====================================================

-- 역할 및 권한 관리 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.roles.role_id IS '역할 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.roles.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.roles.role_name IS '역할명';
COMMENT ON COLUMN bms.roles.description IS '역할 설명';
COMMENT ON COLUMN bms.roles.is_system_role IS '시스템 기본 역할 여부';
COMMENT ON COLUMN bms.roles.is_active IS '활성 상태';
COMMENT ON COLUMN bms.roles.created_at IS '생성 일시';
COMMENT ON COLUMN bms.roles.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.roles.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.roles.updated_by IS '수정자 사용자 ID';

-- 사용자 권한 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.user_permissions.permission_id IS '권한 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.user_permissions.permission_name IS '권한명';
COMMENT ON COLUMN bms.user_permissions.permission_code IS '권한 코드';
COMMENT ON COLUMN bms.user_permissions.description IS '권한 설명';
COMMENT ON COLUMN bms.user_permissions.resource_type IS '리소스 유형';
COMMENT ON COLUMN bms.user_permissions.action_type IS '액션 유형 (CREATE, READ, UPDATE, DELETE)';
COMMENT ON COLUMN bms.user_permissions.is_active IS '활성 상태';
COMMENT ON COLUMN bms.user_permissions.created_at IS '생성 일시';
COMMENT ON COLUMN bms.user_permissions.updated_at IS '수정 일시';

-- 사용자 역할 할당 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.user_role_assignments.assignment_id IS '할당 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.user_role_assignments.user_id IS '사용자 식별자 (UUID)';
COMMENT ON COLUMN bms.user_role_assignments.role_id IS '역할 식별자 (UUID)';
COMMENT ON COLUMN bms.user_role_assignments.assigned_by IS '할당자 사용자 ID';
COMMENT ON COLUMN bms.user_role_assignments.assigned_at IS '할당 일시';
COMMENT ON COLUMN bms.user_role_assignments.is_active IS '활성 상태';
COMMENT ON COLUMN bms.user_role_assignments.created_at IS '생성 일시';
COMMENT ON COLUMN bms.user_role_assignments.updated_at IS '수정 일시';

-- 역할별 권한 할당 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.role_permissions.role_permission_id IS '역할 권한 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.role_permissions.role_id IS '역할 식별자 (UUID)';
COMMENT ON COLUMN bms.role_permissions.permission_id IS '권한 식별자 (UUID)';
COMMENT ON COLUMN bms.role_permissions.granted_by IS '권한 부여자 사용자 ID';
COMMENT ON COLUMN bms.role_permissions.granted_at IS '권한 부여 일시';
COMMENT ON COLUMN bms.role_permissions.is_active IS '활성 상태';
COMMENT ON COLUMN bms.role_permissions.created_at IS '생성 일시';
COMMENT ON COLUMN bms.role_permissions.updated_at IS '수정 일시';

-- 접근 로그 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.access_logs.log_id IS '로그 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.access_logs.user_id IS '사용자 식별자 (UUID)';
COMMENT ON COLUMN bms.access_logs.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.access_logs.action IS '수행 액션';
COMMENT ON COLUMN bms.access_logs.resource_type IS '접근 리소스 유형';
COMMENT ON COLUMN bms.access_logs.resource_id IS '접근 리소스 ID';
COMMENT ON COLUMN bms.access_logs.ip_address IS '접근 IP 주소';
COMMENT ON COLUMN bms.access_logs.user_agent IS '사용자 에이전트';
COMMENT ON COLUMN bms.access_logs.success IS '성공 여부';
COMMENT ON COLUMN bms.access_logs.error_message IS '오류 메시지';
COMMENT ON COLUMN bms.access_logs.created_at IS '생성 일시';

-- 시스템 로그 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.system_logs.log_id IS '로그 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.system_logs.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.system_logs.log_level IS '로그 레벨 (ERROR, WARN, INFO, DEBUG)';
COMMENT ON COLUMN bms.system_logs.category IS '로그 카테고리';
COMMENT ON COLUMN bms.system_logs.message IS '로그 메시지';
COMMENT ON COLUMN bms.system_logs.details IS '상세 정보 (JSON)';
COMMENT ON COLUMN bms.system_logs.user_id IS '관련 사용자 ID';
COMMENT ON COLUMN bms.system_logs.created_at IS '생성 일시';

-- 시스템 설정 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.system_settings.setting_id IS '설정 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.system_settings.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.system_settings.setting_key IS '설정 키';
COMMENT ON COLUMN bms.system_settings.setting_value IS '설정 값';
COMMENT ON COLUMN bms.system_settings.setting_type IS '설정 유형 (STRING, NUMBER, BOOLEAN, JSON)';
COMMENT ON COLUMN bms.system_settings.description IS '설정 설명';
COMMENT ON COLUMN bms.system_settings.is_encrypted IS '암호화 여부';
COMMENT ON COLUMN bms.system_settings.created_at IS '생성 일시';
COMMENT ON COLUMN bms.system_settings.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.system_settings.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.system_settings.updated_by IS '수정자 사용자 ID';

-- 암호화 키 관리 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.encryption_keys.key_id IS '키 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.encryption_keys.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.encryption_keys.key_name IS '키 이름';
COMMENT ON COLUMN bms.encryption_keys.key_type IS '키 유형 (AES, RSA)';
COMMENT ON COLUMN bms.encryption_keys.key_size IS '키 크기 (비트)';
COMMENT ON COLUMN bms.encryption_keys.encrypted_key IS '암호화된 키 데이터';
COMMENT ON COLUMN bms.encryption_keys.key_status IS '키 상태 (ACTIVE, EXPIRED, REVOKED)';
COMMENT ON COLUMN bms.encryption_keys.created_at IS '생성 일시';
COMMENT ON COLUMN bms.encryption_keys.expires_at IS '만료 일시';
COMMENT ON COLUMN bms.encryption_keys.created_by IS '생성자 사용자 ID';

-- 개인정보 처리 로그 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.privacy_processing_logs.log_id IS '로그 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.privacy_processing_logs.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.privacy_processing_logs.user_id IS '처리자 사용자 ID';
COMMENT ON COLUMN bms.privacy_processing_logs.data_subject_id IS '정보주체 ID';
COMMENT ON COLUMN bms.privacy_processing_logs.processing_purpose IS '처리 목적';
COMMENT ON COLUMN bms.privacy_processing_logs.data_type IS '개인정보 유형';
COMMENT ON COLUMN bms.privacy_processing_logs.processing_method IS '처리 방법 (CREATE, READ, UPDATE, DELETE)';
COMMENT ON COLUMN bms.privacy_processing_logs.legal_basis IS '처리 근거';
COMMENT ON COLUMN bms.privacy_processing_logs.retention_period IS '보유 기간';
COMMENT ON COLUMN bms.privacy_processing_logs.created_at IS '처리 일시';

-- 공지사항 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.announcements.announcement_id IS '공지사항 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.announcements.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.announcements.building_id IS '건물 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.announcements.category_id IS '공지사항 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.announcements.title IS '공지사항 제목';
COMMENT ON COLUMN bms.announcements.content IS '공지사항 내용';
COMMENT ON COLUMN bms.announcements.priority IS '우선순위 (HIGH, MEDIUM, LOW)';
COMMENT ON COLUMN bms.announcements.target_audience IS '대상 (ALL, TENANTS, OWNERS, STAFF)';
COMMENT ON COLUMN bms.announcements.status IS '상태 (DRAFT, PUBLISHED, ARCHIVED)';
COMMENT ON COLUMN bms.announcements.publish_date IS '게시 일시';
COMMENT ON COLUMN bms.announcements.expire_date IS '만료 일시';
COMMENT ON COLUMN bms.announcements.view_count IS '조회수';
COMMENT ON COLUMN bms.announcements.is_pinned IS '상단 고정 여부';
COMMENT ON COLUMN bms.announcements.created_at IS '생성 일시';
COMMENT ON COLUMN bms.announcements.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.announcements.created_by IS '작성자 사용자 ID';
COMMENT ON COLUMN bms.announcements.updated_by IS '수정자 사용자 ID';

-- 공지사항 분류 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.announcement_categories.category_id IS '분류 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.announcement_categories.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.announcement_categories.category_name IS '분류명';
COMMENT ON COLUMN bms.announcement_categories.description IS '분류 설명';
COMMENT ON COLUMN bms.announcement_categories.color_code IS '분류 색상 코드';
COMMENT ON COLUMN bms.announcement_categories.sort_order IS '정렬 순서';
COMMENT ON COLUMN bms.announcement_categories.is_active IS '활성 상태';
COMMENT ON COLUMN bms.announcement_categories.created_at IS '생성 일시';
COMMENT ON COLUMN bms.announcement_categories.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.announcement_categories.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.announcement_categories.updated_by IS '수정자 사용자 ID';

-- 공지사항 첨부파일 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.announcement_attachments.attachment_id IS '첨부파일 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.announcement_attachments.announcement_id IS '공지사항 식별자 (UUID)';
COMMENT ON COLUMN bms.announcement_attachments.file_name IS '파일명';
COMMENT ON COLUMN bms.announcement_attachments.original_name IS '원본 파일명';
COMMENT ON COLUMN bms.announcement_attachments.file_path IS '파일 경로';
COMMENT ON COLUMN bms.announcement_attachments.file_size IS '파일 크기 (바이트)';
COMMENT ON COLUMN bms.announcement_attachments.mime_type IS 'MIME 타입';
COMMENT ON COLUMN bms.announcement_attachments.download_count IS '다운로드 횟수';
COMMENT ON COLUMN bms.announcement_attachments.created_at IS '업로드 일시';
COMMENT ON COLUMN bms.announcement_attachments.created_by IS '업로드자 사용자 ID';

-- 공지사항 대상자 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.announcement_targets.target_id IS '대상자 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.announcement_targets.announcement_id IS '공지사항 식별자 (UUID)';
COMMENT ON COLUMN bms.announcement_targets.target_type IS '대상 유형 (USER, UNIT, BUILDING)';
COMMENT ON COLUMN bms.announcement_targets.target_reference_id IS '대상 참조 ID';
COMMENT ON COLUMN bms.announcement_targets.is_read IS '읽음 여부';
COMMENT ON COLUMN bms.announcement_targets.read_at IS '읽은 일시';
COMMENT ON COLUMN bms.announcement_targets.created_at IS '생성 일시';