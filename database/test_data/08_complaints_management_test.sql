-- =====================================================
-- 민원 처리 관리 테스트 데이터
-- =====================================================

-- 테스트용 사용자 데이터 (민원 담당자)
INSERT INTO users (username, password_hash, email, full_name, role_id, is_active) VALUES
('complaint_manager', '$2a$10$example_hash', 'complaint@qiro.co.kr', '민원 담당자', 1, true),
('facility_manager', '$2a$10$example_hash', 'facility@qiro.co.kr', '시설 담당자', 1, true),
('admin_manager', '$2a$10$example_hash', 'admin@qiro.co.kr', '관리 담당자', 1, true);

-- 건물별 민원 SLA 설정 테스트 데이터
INSERT INTO complaint_sla_settings (building_id, category_id, priority, sla_hours, escalation_hours, auto_assign_to, notification_emails) VALUES
-- 건물 1 (아파트) - 시설 관련 긴급 민원
(1, 1, 'URGENT', 2, 1, 2, ARRAY['facility@qiro.co.kr', 'emergency@qiro.co.kr']),
(1, 1, 'HIGH', 8, 4, 2, ARRAY['facility@qiro.co.kr']),
(1, 1, 'MEDIUM', 24, 12, 2, ARRAY['facility@qiro.co.kr']),

-- 건물 1 - 보안 관련
(1, 5, 'URGENT', 1, 0, 3, ARRAY['security@qiro.co.kr', 'emergency@qiro.co.kr']),
(1, 5, 'HIGH', 4, 2, 3, ARRAY['security@qiro.co.kr']),

-- 건물 1 - 소음 관련
(1, 2, 'HIGH', 12, 6, 1, ARRAY['complaint@qiro.co.kr']),
(1, 2, 'MEDIUM', 48, 24, 1, ARRAY['complaint@qiro.co.kr']),

-- 건물 2 (오피스텔) - 시설 관련
(2, 1, 'URGENT', 3, 1, 2, ARRAY['facility@qiro.co.kr']),
(2, 1, 'HIGH', 12, 6, 2, ARRAY['facility@qiro.co.kr']),

-- 건물 2 - 주차 관련
(2, 3, 'HIGH', 6, 3, 1, ARRAY['parking@qiro.co.kr']),
(2, 3, 'MEDIUM', 24, 12, 1, ARRAY['parking@qiro.co.kr']);

-- 민원 테스트 데이터
INSERT INTO complaints (
    building_id, unit_id, category_id, complainant_name, complainant_contact, 
    complainant_email, complainant_type, title, description, location_detail,
    priority, status, assigned_to, submitted_at, created_by
) VALUES
-- 해결된 민원들
(1, 1, 1, '김철수', '010-1234-5678', 'kim@example.com', 'TENANT', 
 '엘리베이터 고장', '1호기 엘리베이터가 3층에서 멈춰서 작동하지 않습니다.', '1호기 엘리베이터', 
 'HIGH', 'RESOLVED', 2, '2024-01-15 09:30:00', 1),

(1, 3, 2, '이영희', '010-2345-6789', 'lee@example.com', 'TENANT',
 '층간소음 문제', '위층에서 밤늦게 발생하는 소음으로 인해 수면에 방해가 됩니다.', '301호 위층',
 'MEDIUM', 'RESOLVED', 1, '2024-01-16 22:15:00', 1),

(2, 5, 3, '박민수', '010-3456-7890', 'park@example.com', 'TENANT',
 '불법 주차', '제 주차 공간에 다른 차량이 주차되어 있습니다.', '지하 1층 B-15',
 'MEDIUM', 'RESOLVED', 1, '2024-01-17 08:45:00', 1),

-- 진행 중인 민원들
(1, 2, 4, '최정민', '010-4567-8901', 'choi@example.com', 'TENANT',
 '복도 청소 상태', '복도에 쓰레기가 며칠째 방치되어 있습니다.', '3층 복도',
 'LOW', 'IN_PROGRESS', 1, '2024-01-18 14:20:00', 1),

(2, 6, 5, '정수현', '010-5678-9012', 'jung@example.com', 'OWNER',
 'CCTV 고장', '주차장 CCTV가 작동하지 않아 보안에 문제가 있습니다.', '지하 1층 주차장',
 'HIGH', 'ASSIGNED', 3, '2024-01-19 11:00:00', 1),

-- 새로 접수된 민원들
(1, 4, 6, '홍길동', '010-6789-0123', 'hong@example.com', 'TENANT',
 '관리비 문의', '이번 달 관리비가 평소보다 많이 나왔는데 내역을 확인하고 싶습니다.', '관리사무소',
 'MEDIUM', 'RECEIVED', NULL, '2024-01-20 16:30:00', 1),

(2, 7, 1, '김영수', '010-7890-1234', 'kimys@example.com', 'TENANT',
 '보일러 고장', '온수가 나오지 않습니다. 긴급 수리가 필요합니다.', '502호 보일러실',
 'URGENT', 'RECEIVED', NULL, '2024-01-21 07:15:00', 1),

-- SLA 위반 민원 (테스트용)
(1, 5, 7, '서민지', '010-8901-2345', 'seo@example.com', 'TENANT',
 '이웃 분쟁', '옆집과 베란다 사용 관련 분쟁이 있습니다.', '304호 옆집',
 'MEDIUM', 'PENDING_INFO', 1, '2024-01-10 10:00:00', 1);

-- 민원 처리 이력 테스트 데이터
INSERT INTO complaint_histories (complaint_id, action_type, previous_status, new_status, action_by, action_at) VALUES
(1, 'STATUS_CHANGE', 'RECEIVED', 'ASSIGNED', 1, '2024-01-15 10:00:00'),
(1, 'ASSIGNMENT', NULL, NULL, 1, '2024-01-15 10:00:00'),
(1, 'STATUS_CHANGE', 'ASSIGNED', 'IN_PROGRESS', 2, '2024-01-15 11:30:00'),
(1, 'STATUS_CHANGE', 'IN_PROGRESS', 'RESOLVED', 2, '2024-01-15 15:45:00'),

(2, 'STATUS_CHANGE', 'RECEIVED', 'ASSIGNED', 1, '2024-01-16 23:00:00'),
(2, 'ASSIGNMENT', NULL, NULL, 1, '2024-01-16 23:00:00'),
(2, 'STATUS_CHANGE', 'ASSIGNED', 'IN_PROGRESS', 1, '2024-01-17 09:00:00'),
(2, 'STATUS_CHANGE', 'IN_PROGRESS', 'RESOLVED', 1, '2024-01-18 14:00:00'),

(3, 'STATUS_CHANGE', 'RECEIVED', 'ASSIGNED', 1, '2024-01-17 09:00:00'),
(3, 'STATUS_CHANGE', 'ASSIGNED', 'RESOLVED', 1, '2024-01-17 10:30:00');

-- 민원 댓글/메모 테스트 데이터
INSERT INTO complaint_comments (complaint_id, comment_type, content, is_visible_to_complainant, created_by) VALUES
(1, 'INTERNAL', '엘리베이터 업체에 연락하여 수리 일정 확인 중', false, 2),
(1, 'PUBLIC', '엘리베이터 수리가 완료되었습니다. 이용에 불편을 드려 죄송합니다.', true, 2),

(2, 'INTERNAL', '위층 세대주와 면담 예정', false, 1),
(2, 'PUBLIC', '이웃 간 대화를 통해 문제가 해결되었습니다.', true, 1),

(4, 'INTERNAL', '청소업체에 추가 청소 요청함', false, 1),

(5, 'INTERNAL', 'CCTV 업체 연락처 확인 필요', false, 3),
(5, 'SYSTEM', '담당자가 배정되었습니다.', false, NULL);

-- 민원 첨부파일 테스트 데이터
INSERT INTO complaint_attachments (complaint_id, file_name, file_path, file_size, file_type, uploaded_by) VALUES
(1, '엘리베이터_고장_사진.jpg', '/uploads/complaints/2024/01/elevator_broken.jpg', 2048576, 'image/jpeg', 1),
(2, '소음_녹음파일.mp3', '/uploads/complaints/2024/01/noise_recording.mp3', 5242880, 'audio/mpeg', 1),
(5, 'CCTV_위치도.pdf', '/uploads/complaints/2024/01/cctv_layout.pdf', 1024000, 'application/pdf', 1);

-- 해결된 민원들의 해결 정보 업데이트
UPDATE complaints SET 
    resolution = '엘리베이터 업체에서 부품 교체 완료. 정상 작동 확인됨.',
    resolution_cost = 350000,
    resolved_at = '2024-01-15 15:45:00',
    satisfaction_score = 5,
    satisfaction_comment = '신속한 처리에 만족합니다.'
WHERE id = 1;

UPDATE complaints SET 
    resolution = '위층 세대주와 대화를 통해 야간 소음 자제 약속 받음.',
    resolved_at = '2024-01-18 14:00:00',
    satisfaction_score = 4,
    satisfaction_comment = '친절한 중재에 감사합니다.'
WHERE id = 2;

UPDATE complaints SET 
    resolution = '불법 주차 차량 견인 조치 완료.',
    resolution_cost = 80000,
    resolved_at = '2024-01-17 10:30:00',
    satisfaction_score = 5
WHERE id = 3;

-- SLA 위반 민원 업데이트 (테스트용)
UPDATE complaints SET 
    is_sla_breached = true,
    sla_breach_reason = '추가 정보 대기로 인한 처리 지연'
WHERE id = 8;

-- 통계 확인을 위한 추가 민원 데이터 (다양한 상태와 분류)
INSERT INTO complaints (
    building_id, unit_id, category_id, complainant_name, complainant_contact,
    title, description, priority, status, assigned_to, submitted_at, resolved_at, created_by
) VALUES
-- 2024년 2월 데이터
(1, 6, 1, '김민수', '010-1111-2222', '난방 문제', '난방이 잘 안됩니다.', 'MEDIUM', 'RESOLVED', 2, '2024-02-01 09:00:00', '2024-02-01 18:00:00', 1),
(1, 7, 2, '이수진', '010-2222-3333', '음악 소음', '위층에서 음악 소리가 큽니다.', 'LOW', 'RESOLVED', 1, '2024-02-02 20:00:00', '2024-02-03 10:00:00', 1),
(2, 8, 3, '박철민', '010-3333-4444', '주차 문제', '주차 라인이 지워져 있습니다.', 'LOW', 'RESOLVED', 1, '2024-02-03 14:00:00', '2024-02-05 16:00:00', 1),

-- 2024년 3월 데이터
(1, 8, 4, '최영희', '010-4444-5555', '쓰레기 문제', '분리수거가 제대로 안되고 있습니다.', 'MEDIUM', 'IN_PROGRESS', 1, '2024-03-01 11:00:00', NULL, 1),
(2, 9, 5, '정민호', '010-5555-6666', '출입문 고장', '현관 자동문이 작동하지 않습니다.', 'HIGH', 'ASSIGNED', 3, '2024-03-02 08:30:00', NULL, 1);

-- 만족도 점수 업데이트
UPDATE complaints SET satisfaction_score = 4 WHERE id = 9;
UPDATE complaints SET satisfaction_score = 3 WHERE id = 10;
UPDATE complaints SET satisfaction_score = 5 WHERE id = 11;

-- =====================================================
-- 공지사항 및 알림 관리 테스트 데이터
-- =====================================================

-- 공지사항 테스트 데이터
INSERT INTO announcements (
    building_id, category_id, title, content, summary, target_audience, 
    is_urgent, is_pinned, status, published_at, expires_at, created_by
) VALUES
-- 전체 건물 대상 긴급 공지
(NULL, 4, '시스템 점검 안내', 
 '시스템 점검으로 인해 일시적으로 서비스 이용이 제한됩니다.\n\n점검 일시: 2024년 1월 25일 02:00 ~ 06:00\n점검 내용: 서버 업그레이드 및 보안 패치\n\n점검 중에는 웹사이트 및 모바일 앱 이용이 불가합니다.\n이용에 불편을 드려 죄송합니다.',
 '시스템 점검으로 인한 서비스 일시 중단 안내 (1/25 02:00~06:00)',
 'ALL', true, true, 'PUBLISHED', '2024-01-20 10:00:00', '2024-01-26 00:00:00', 1),

-- 건물 1 - 시설 공지
(1, 2, '엘리베이터 정기 점검 안내',
 '엘리베이터 정기 점검을 실시합니다.\n\n점검 일시: 2024년 1월 22일 09:00 ~ 12:00\n점검 대상: 1호기, 2호기\n점검 업체: (주)엘리베이터서비스\n\n점검 중에는 해당 엘리베이터 이용이 불가하니 양해 부탁드립니다.',
 '엘리베이터 정기 점검 실시 (1/22 09:00~12:00)',
 'ALL', false, false, 'PUBLISHED', '2024-01-18 14:00:00', '2024-01-23 00:00:00', 2),

-- 건물 1 - 행사 공지
(1, 3, '신년 떡국 나눔 행사',
 '새해를 맞아 입주민 여러분과 함께하는 떡국 나눔 행사를 개최합니다.\n\n일시: 2024년 1월 15일 12:00 ~ 14:00\n장소: 1층 커뮤니티룸\n대상: 전 입주민\n\n많은 참여 부탁드립니다.',
 '신년 떡국 나눔 행사 개최 안내 (1/15 12:00~14:00)',
 'TENANTS', false, false, 'PUBLISHED', '2024-01-10 09:00:00', '2024-01-16 00:00:00', 1),

-- 건물 2 - 요금 공지
(2, 5, '2024년 1월 관리비 안내',
 '2024년 1월 관리비를 다음과 같이 안내드립니다.\n\n납부 기한: 2024년 1월 31일\n납부 방법: 계좌이체, 무통장입금\n계좌번호: 국민은행 123-456-789012 (예금주: 건물관리사무소)\n\n기타 문의사항은 관리사무소로 연락 바랍니다.',
 '2024년 1월 관리비 납부 안내',
 'ALL', false, true, 'PUBLISHED', '2024-01-01 08:00:00', '2024-02-01 00:00:00', 1),

-- 건물 1 - 정책 공지
(1, 6, '주차장 이용 규정 변경 안내',
 '주차장 이용 규정이 다음과 같이 변경됩니다.\n\n시행일: 2024년 2월 1일\n주요 변경사항:\n1. 방문차량 주차 시간 제한 (최대 2시간)\n2. 장기 미사용 차량 견인 조치\n3. 전기차 충전구역 신설\n\n자세한 내용은 첨부파일을 참고하시기 바랍니다.',
 '주차장 이용 규정 변경 안내 (2/1 시행)',
 'ALL', false, false, 'PUBLISHED', '2024-01-19 16:00:00', '2024-02-15 00:00:00', 3),

-- 예약된 공지사항
(1, 7, '화재 대피 훈련 실시 안내',
 '화재 대피 훈련을 실시합니다.\n\n일시: 2024년 2월 5일 14:00\n소요 시간: 약 30분\n참여 대상: 전 입주민\n\n안전을 위한 훈련이니 적극적인 참여 부탁드립니다.',
 '화재 대피 훈련 실시 안내 (2/5 14:00)',
 'ALL', false, false, 'SCHEDULED', '2024-02-01 09:00:00', '2024-02-06 00:00:00', 1),

-- 임시저장 공지사항
(2, 1, '임시저장 공지', '임시저장된 공지사항입니다.', '임시저장 공지', 'ALL', false, false, 'DRAFT', NULL, NULL, 1);

-- 공지사항 첨부파일 테스트 데이터
INSERT INTO announcement_attachments (announcement_id, file_name, file_path, file_size, file_type, uploaded_by) VALUES
(5, '주차장_이용규정_개정안.pdf', '/uploads/announcements/2024/01/parking_rules.pdf', 2048000, 'application/pdf', 3),
(5, '주차장_배치도.jpg', '/uploads/announcements/2024/01/parking_layout.jpg', 1536000, 'image/jpeg', 3),
(6, '대피경로도.pdf', '/uploads/announcements/2024/01/evacuation_route.pdf', 1024000, 'application/pdf', 1);

-- 공지사항 댓글 테스트 데이터
INSERT INTO announcement_comments (announcement_id, commenter_name, commenter_contact, content, is_approved, approved_by, approved_at) VALUES
(3, '김민수', '010-1234-5678', '떡국 행사 참여하고 싶습니다. 몇 시까지 가면 될까요?', true, 1, '2024-01-11 10:00:00'),
(3, '이영희', '010-2345-6789', '아이들도 참여 가능한가요?', true, 1, '2024-01-11 11:00:00'),
(5, '박철수', '010-3456-7890', '전기차 충전구역은 몇 개 정도 만들어지나요?', true, 3, '2024-01-20 09:00:00');

-- 대댓글 테스트 데이터
INSERT INTO announcement_comments (announcement_id, parent_comment_id, commenter_name, content, is_approved, approved_by, approved_at) VALUES
(3, 1, '관리사무소', '12시부터 14시까지 언제든 오시면 됩니다.', true, 1, '2024-01-11 14:00:00'),
(3, 2, '관리사무소', '네, 아이들도 함께 참여 가능합니다.', true, 1, '2024-01-11 15:00:00'),
(5, 3, '관리사무소', '총 4개의 전기차 충전구역을 설치할 예정입니다.', true, 3, '2024-01-20 14:00:00');

-- 공지사항 조회 이력 테스트 데이터
INSERT INTO announcement_views (announcement_id, viewer_type, viewer_id, viewer_ip, viewed_at) VALUES
(1, 'USER', 1, '192.168.1.100', '2024-01-20 10:30:00'),
(1, 'USER', 2, '192.168.1.101', '2024-01-20 11:00:00'),
(1, 'USER', 3, '192.168.1.102', '2024-01-20 11:30:00'),
(2, 'USER', 1, '192.168.1.100', '2024-01-18 15:00:00'),
(2, 'USER', 2, '192.168.1.101', '2024-01-18 16:00:00'),
(3, 'USER', 1, '192.168.1.100', '2024-01-10 10:00:00'),
(3, 'USER', 2, '192.168.1.101', '2024-01-10 11:00:00'),
(3, 'USER', 3, '192.168.1.102', '2024-01-10 12:00:00'),
(4, 'USER', 1, '192.168.1.100', '2024-01-01 09:00:00'),
(5, 'USER', 1, '192.168.1.100', '2024-01-19 17:00:00'),
(5, 'USER', 2, '192.168.1.101', '2024-01-19 18:00:00');

-- 알림 테스트 데이터
INSERT INTO notifications (
    recipient_type, recipient_id, recipient_name, recipient_contact,
    notification_type, title, message, action_url, channels, priority,
    status, sent_at, delivered_at, read_at, related_entity_type, related_entity_id, created_by
) VALUES
-- 공지사항 알림
('USER', 1, '김철수', 'kim@example.com', 'ANNOUNCEMENT', 
 '새 공지사항: 시스템 점검 안내', '새로운 긴급 공지사항이 등록되었습니다.\n\n제목: 시스템 점검 안내\n내용: 시스템 점검으로 인해 일시적으로 서비스 이용이 제한됩니다.',
 '/announcements/1', ARRAY['IN_APP', 'EMAIL'], 5,
 'READ', '2024-01-20 10:05:00', '2024-01-20 10:05:00', '2024-01-20 10:30:00', 'ANNOUNCEMENT', 1, 1),

('USER', 2, '이영희', 'lee@example.com', 'ANNOUNCEMENT',
 '새 공지사항: 시스템 점검 안내', '새로운 긴급 공지사항이 등록되었습니다.\n\n제목: 시스템 점검 안내\n내용: 시스템 점검으로 인해 일시적으로 서비스 이용이 제한됩니다.',
 '/announcements/1', ARRAY['IN_APP', 'EMAIL'], 5,
 'DELIVERED', '2024-01-20 10:05:00', '2024-01-20 10:05:00', NULL, 'ANNOUNCEMENT', 1, 1),

-- 민원 관련 알림
('USER', 2, '시설 담당자', 'facility@qiro.co.kr', 'COMPLAINT_UPDATE',
 '민원이 배정되었습니다: C20240100001', '민원 C20240100001이(가) 귀하에게 배정되었습니다.\n\n제목: 엘리베이터 고장\n우선순위: HIGH',
 '/complaints/1', ARRAY['IN_APP', 'EMAIL'], 4,
 'READ', '2024-01-15 10:00:00', '2024-01-15 10:00:00', '2024-01-15 10:15:00', 'COMPLAINT', 1, 1),

('USER', 1, '김철수', 'kim@example.com', 'COMPLAINT_UPDATE',
 '민원이 해결되었습니다: C20240100001', '접수하신 민원이 해결되었습니다.\n\n민원번호: C20240100001\n해결내용: 엘리베이터 업체에서 부품 교체 완료. 정상 작동 확인됨.',
 '/complaints/1', ARRAY['IN_APP', 'EMAIL', 'SMS'], 3,
 'READ', '2024-01-15 16:00:00', '2024-01-15 16:00:00', '2024-01-15 16:30:00', 'COMPLAINT', 1, 2),

-- 관리비 알림
('USER', 1, '김철수', 'kim@example.com', 'BILLING_NOTICE',
 '관리비 납부 안내', '2024년 1월 관리비 납부 기한이 임박했습니다.\n\n금액: 150,000원\n납부기한: 2024-01-31',
 '/billing/invoices', ARRAY['IN_APP', 'EMAIL'], 3,
 'SENT', '2024-01-25 09:00:00', '2024-01-25 09:00:00', NULL, 'INVOICE', 1, 1),

-- 계약 만료 알림
('USER', 1, '김철수', 'kim@example.com', 'CONTRACT_EXPIRY',
 '임대 계약 만료 안내', '임대 계약이 곧 만료됩니다.\n\n만료일: 2024-12-31\n연장 문의: 관리사무소 02-1234-5678',
 '/contracts/1', ARRAY['IN_APP', 'EMAIL'], 4,
 'PENDING', NULL, NULL, NULL, 'CONTRACT', 1, 1),

-- 실패한 알림
('USER', 3, '박민수', 'invalid@email', 'ANNOUNCEMENT',
 '새 공지사항: 엘리베이터 정기 점검 안내', '새로운 공지사항이 등록되었습니다.',
 '/announcements/2', ARRAY['EMAIL'], 3,
 'FAILED', NULL, NULL, NULL, 'ANNOUNCEMENT', 2, 2);

-- 마지막 알림의 실패 사유 업데이트
UPDATE notifications SET 
    failed_reason = '유효하지 않은 이메일 주소',
    retry_count = 3
WHERE id = (SELECT MAX(id) FROM notifications WHERE status = 'FAILED');

-- 사용자별 알림 설정 테스트 데이터
INSERT INTO user_notification_settings (user_id, notification_type, enabled_channels, is_enabled, quiet_hours_start, quiet_hours_end) VALUES
(1, 'ANNOUNCEMENT', ARRAY['IN_APP', 'EMAIL'], true, '22:00', '08:00'),
(1, 'COMPLAINT_UPDATE', ARRAY['IN_APP', 'EMAIL', 'SMS'], true, '22:00', '08:00'),
(1, 'BILLING_NOTICE', ARRAY['IN_APP', 'EMAIL', 'SMS'], true, NULL, NULL),
(1, 'CONTRACT_EXPIRY', ARRAY['IN_APP', 'EMAIL'], true, NULL, NULL),

(2, 'ANNOUNCEMENT', ARRAY['IN_APP'], true, '23:00', '07:00'),
(2, 'COMPLAINT_UPDATE', ARRAY['IN_APP', 'EMAIL'], true, '23:00', '07:00'),
(2, 'MAINTENANCE_SCHEDULE', ARRAY['IN_APP', 'EMAIL'], true, NULL, NULL),

(3, 'ANNOUNCEMENT', ARRAY['IN_APP', 'EMAIL'], true, NULL, NULL),
(3, 'COMPLAINT_UPDATE', ARRAY['IN_APP'], false, NULL, NULL); -- 민원 알림 비활성화

-- 코멘트
COMMENT ON TABLE complaints IS '민원 관리 테스트 데이터 - 다양한 민원 유형과 처리 상태를 포함한 샘플 데이터';
COMMENT ON TABLE announcements IS '공지사항 관리 테스트 데이터 - 다양한 공지사항 유형과 상태를 포함한 샘플 데이터';
COMMENT ON TABLE notifications IS '알림 관리 테스트 데이터 - 다양한 알림 유형과 발송 상태를 포함한 샘플 데이터';