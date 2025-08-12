-- =====================================================
-- 공지사항 시스템 데이터베이스 스키마
-- 생성일: 2025-01-08
-- 설명: 건물관리 시스템의 공지사항 및 알림 기능
-- =====================================================

-- 공지사항 테이블
CREATE TABLE IF NOT EXISTS notices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (category IN (
        'GENERAL', 'URGENT', 'MAINTENANCE', 'MANAGEMENT_FEE', 
        'FACILITY', 'EVENT', 'SECURITY', 'OTHER'
    )),
    priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL' CHECK (priority IN (
        'NORMAL', 'IMPORTANT', 'URGENT'
    )),
    published_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_by UUID NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 공지사항 첨부파일 테이블
CREATE TABLE IF NOT EXISTS notice_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notice_id UUID NOT NULL REFERENCES notices(id) ON DELETE CASCADE,
    filename VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT,
    content_type VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 알림 테이블
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    notice_id UUID REFERENCES notices(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT,
    notification_type VARCHAR(50) NOT NULL DEFAULT 'NOTICE' CHECK (notification_type IN (
        'NOTICE', 'URGENT', 'MAINTENANCE', 'MANAGEMENT_FEE', 'SYSTEM', 'OTHER'
    )),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 인덱스 생성
-- 공지사항 인덱스
CREATE INDEX IF NOT EXISTS idx_notices_category ON notices(category);
CREATE INDEX IF NOT EXISTS idx_notices_priority ON notices(priority);
CREATE INDEX IF NOT EXISTS idx_notices_published_at ON notices(published_at);
CREATE INDEX IF NOT EXISTS idx_notices_expires_at ON notices(expires_at);
CREATE INDEX IF NOT EXISTS idx_notices_created_by ON notices(created_by);
CREATE INDEX IF NOT EXISTS idx_notices_created_at ON notices(created_at);

-- 복합 인덱스 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_notices_active ON notices(category, priority, published_at, expires_at) 
WHERE published_at IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_notices_urgent ON notices(priority, published_at) 
WHERE priority = 'URGENT' AND published_at IS NOT NULL;

-- 첨부파일 인덱스
CREATE INDEX IF NOT EXISTS idx_notice_attachments_notice_id ON notice_attachments(notice_id);
CREATE INDEX IF NOT EXISTS idx_notice_attachments_created_at ON notice_attachments(created_at);
CREATE INDEX IF NOT EXISTS idx_notice_attachments_content_type ON notice_attachments(content_type);

-- 알림 인덱스
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_notice_id ON notifications(notice_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- 복합 인덱스 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read, created_at) 
WHERE is_read = FALSE;

CREATE INDEX IF NOT EXISTS idx_notifications_user_type ON notifications(user_id, notification_type, created_at);

CREATE INDEX IF NOT EXISTS idx_notifications_urgent ON notifications(user_id, notification_type, is_read) 
WHERE notification_type = 'URGENT';

-- 테이블 코멘트
COMMENT ON TABLE notices IS '공지사항 테이블';
COMMENT ON COLUMN notices.id IS '공지사항 ID';
COMMENT ON COLUMN notices.title IS '공지사항 제목';
COMMENT ON COLUMN notices.content IS '공지사항 내용';
COMMENT ON COLUMN notices.category IS '공지사항 분류 (GENERAL, URGENT, MAINTENANCE, etc.)';
COMMENT ON COLUMN notices.priority IS '중요도 (NORMAL, IMPORTANT, URGENT)';
COMMENT ON COLUMN notices.published_at IS '발행일시';
COMMENT ON COLUMN notices.expires_at IS '만료일시';
COMMENT ON COLUMN notices.created_by IS '작성자 ID';
COMMENT ON COLUMN notices.created_at IS '생성일시';
COMMENT ON COLUMN notices.updated_at IS '수정일시';

COMMENT ON TABLE notice_attachments IS '공지사항 첨부파일 테이블';
COMMENT ON COLUMN notice_attachments.id IS '첨부파일 ID';
COMMENT ON COLUMN notice_attachments.notice_id IS '공지사항 ID';
COMMENT ON COLUMN notice_attachments.filename IS '원본 파일명';
COMMENT ON COLUMN notice_attachments.file_path IS '저장된 파일 경로';
COMMENT ON COLUMN notice_attachments.file_size IS '파일 크기 (bytes)';
COMMENT ON COLUMN notice_attachments.content_type IS '파일 MIME 타입';
COMMENT ON COLUMN notice_attachments.created_at IS '업로드일시';

COMMENT ON TABLE notifications IS '알림 테이블';
COMMENT ON COLUMN notifications.id IS '알림 ID';
COMMENT ON COLUMN notifications.user_id IS '알림 받을 사용자 ID';
COMMENT ON COLUMN notifications.notice_id IS '관련 공지사항 ID (선택적)';
COMMENT ON COLUMN notifications.title IS '알림 제목';
COMMENT ON COLUMN notifications.message IS '알림 메시지';
COMMENT ON COLUMN notifications.notification_type IS '알림 타입 (NOTICE, URGENT, MAINTENANCE, etc.)';
COMMENT ON COLUMN notifications.is_read IS '읽음 여부';
COMMENT ON COLUMN notifications.read_at IS '읽은 일시';
COMMENT ON COLUMN notifications.created_at IS '생성일시';

-- 트리거 함수: updated_at 자동 업데이트
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거 생성
DROP TRIGGER IF EXISTS update_notices_updated_at ON notices;
CREATE TRIGGER update_notices_updated_at
    BEFORE UPDATE ON notices
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 샘플 데이터 삽입 (개발/테스트용)
-- 공지사항 분류별 샘플 데이터
INSERT INTO notices (id, title, content, category, priority, published_at, created_by) VALUES
(
    '11111111-1111-1111-1111-111111111111',
    '정기 엘리베이터 점검 안내',
    '다음 주 화요일(1월 15일) 오전 9시부터 12시까지 엘리베이터 정기점검이 실시됩니다. 점검 시간 동안 엘리베이터 이용이 제한되오니 양해 부탁드립니다.',
    'MAINTENANCE',
    'IMPORTANT',
    NOW() - INTERVAL '1 day',
    '99999999-9999-9999-9999-999999999999'
),
(
    '22222222-2222-2222-2222-222222222222',
    '[긴급] 단수 공지',
    '수도관 파열로 인해 오늘 오후 2시부터 6시까지 단수가 예정되어 있습니다. 미리 물을 받아두시기 바랍니다.',
    'URGENT',
    'URGENT',
    NOW() - INTERVAL '2 hours',
    '99999999-9999-9999-9999-999999999999'
),
(
    '33333333-3333-3333-3333-333333333333',
    '2025년 1월 관리비 고지',
    '2025년 1월분 관리비가 고지되었습니다. 납부 기한은 1월 25일까지이며, 연체 시 연체료가 부과됩니다.',
    'MANAGEMENT_FEE',
    'NORMAL',
    NOW() - INTERVAL '3 days',
    '99999999-9999-9999-9999-999999999999'
),
(
    '44444444-4444-4444-4444-444444444444',
    '신년 인사 및 운영 안내',
    '새해 복 많이 받으시기 바랍니다. 2025년에도 더 나은 서비스로 보답하겠습니다.',
    'GENERAL',
    'NORMAL',
    NOW() - INTERVAL '5 days',
    '99999999-9999-9999-9999-999999999999'
),
(
    '55555555-5555-5555-5555-555555555555',
    '헬스장 이용 시간 변경 안내',
    '2월 1일부터 헬스장 이용 시간이 오전 6시부터 오후 10시로 변경됩니다.',
    'FACILITY',
    'NORMAL',
    NOW() + INTERVAL '1 day',
    '99999999-9999-9999-9999-999999999999'
);

-- 샘플 알림 데이터
INSERT INTO notifications (user_id, notice_id, title, message, notification_type) VALUES
(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    '[정기점검] 정기 엘리베이터 점검 안내',
    '다음 주 화요일(1월 15일) 오전 9시부터 12시까지 엘리베이터 정기점검이 실시됩니다.',
    'MAINTENANCE'
),
(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '22222222-2222-2222-2222-222222222222',
    '[긴급알림] 단수 공지',
    '수도관 파열로 인해 오늘 오후 2시부터 6시까지 단수가 예정되어 있습니다.',
    'URGENT'
),
(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '33333333-3333-3333-3333-333333333333',
    '[관리비] 2025년 1월 관리비 고지',
    '2025년 1월분 관리비가 고지되었습니다. 납부 기한은 1월 25일까지입니다.',
    'MANAGEMENT_FEE'
);

-- 데이터 검증 쿼리
SELECT 
    'notices' as table_name,
    COUNT(*) as record_count,
    COUNT(CASE WHEN published_at IS NOT NULL THEN 1 END) as published_count,
    COUNT(CASE WHEN priority = 'URGENT' THEN 1 END) as urgent_count
FROM notices
UNION ALL
SELECT 
    'notifications' as table_name,
    COUNT(*) as record_count,
    COUNT(CASE WHEN is_read = FALSE THEN 1 END) as unread_count,
    COUNT(CASE WHEN notification_type = 'URGENT' THEN 1 END) as urgent_count
FROM notifications;

-- 성능 확인 쿼리
EXPLAIN (ANALYZE, BUFFERS) 
SELECT n.*, COUNT(na.id) as attachment_count
FROM notices n
LEFT JOIN notice_attachments na ON n.id = na.notice_id
WHERE n.published_at IS NOT NULL 
  AND n.published_at <= NOW()
  AND (n.expires_at IS NULL OR n.expires_at > NOW())
GROUP BY n.id
ORDER BY n.priority DESC, n.published_at DESC
LIMIT 20;

COMMIT;