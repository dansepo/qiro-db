-- =====================================================
-- 사용자 권한 및 감사 로그 테스트 데이터 (User Management Test Data)
-- =====================================================

-- 테스트용 사용자 생성
INSERT INTO users (username, email, password_hash, full_name, phone_number, role_id, is_active, is_email_verified, created_by) VALUES
-- 시스템 관리자
('admin', 'admin@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '시스템 관리자', '010-1234-5678', 
 (SELECT id FROM roles WHERE name = 'SUPER_ADMIN'), true, true, 1),

-- 건물 관리자들
('manager1', 'manager1@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '김건물', '010-2345-6789', 
 (SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), true, true, 1),
('manager2', 'manager2@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '이관리', '010-3456-7890', 
 (SELECT id FROM roles WHERE name = 'BUILDING_ADMIN'), true, true, 1),

-- 회계 담당자
('accountant', 'accountant@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '박회계', '010-4567-8901', 
 (SELECT id FROM roles WHERE name = 'ACCOUNTING_MANAGER'), true, true, 1),

-- 시설 관리자
('facility', 'facility@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '최시설', '010-5678-9012', 
 (SELECT id FROM roles WHERE name = 'FACILITY_MANAGER'), true, true, 1),

-- 일반 직원들
('staff1', 'staff1@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '정직원', '010-6789-0123', 
 (SELECT id FROM roles WHERE name = 'STAFF'), true, true, 1),
('staff2', 'staff2@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '한사원', '010-7890-1234', 
 (SELECT id FROM roles WHERE name = 'STAFF'), true, true, 1),

-- 조회자
('viewer', 'viewer@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '조회자', '010-8901-2345', 
 (SELECT id FROM roles WHERE name = 'VIEWER'), true, true, 1),

-- 비활성 사용자 (테스트용)
('inactive', 'inactive@qiro.co.kr', '$2a$10$N.zmdr9k7uOCQb0VeCdmUOBYiZH5U5A7xNeoaUlQ.xeQW4nQzIdWG', '비활성사용자', '010-9012-3456', 
 (SELECT id FROM roles WHERE name = 'STAFF'), false, false, 1);

-- 사용자별 건물 접근 권한 설정
INSERT INTO user_building_access (user_id, building_id, access_level, granted_by) VALUES
-- 건물 관리자1은 건물1에 대한 관리자 권한
((SELECT id FROM users WHERE username = 'manager1'), 1, 'admin', (SELECT id FROM users WHERE username = 'admin')),
-- 건물 관리자2는 건물2에 대한 관리자 권한
((SELECT id FROM users WHERE username = 'manager2'), 2, 'admin', (SELECT id FROM users WHERE username = 'admin')),
-- 회계 담당자는 모든 건물에 대한 읽기/쓰기 권한
((SELECT id FROM users WHERE username = 'accountant'), 1, 'write', (SELECT id FROM users WHERE username = 'admin')),
((SELECT id FROM users WHERE username = 'accountant'), 2, 'write', (SELECT id FROM users WHERE username = 'admin')),
-- 시설 관리자는 모든 건물에 대한 읽기/쓰기 권한
((SELECT id FROM users WHERE username = 'facility'), 1, 'write', (SELECT id FROM users WHERE username = 'admin')),
((SELECT id FROM users WHERE username = 'facility'), 2, 'write', (SELECT id FROM users WHERE username = 'admin')),
-- 직원1은 건물1에 대한 읽기 권한
((SELECT id FROM users WHERE username = 'staff1'), 1, 'read', (SELECT id FROM users WHERE username = 'manager1')),
-- 직원2는 건물2에 대한 읽기 권한
((SELECT id FROM users WHERE username = 'staff2'), 2, 'read', (SELECT id FROM users WHERE username = 'manager2')),
-- 조회자는 모든 건물에 대한 읽기 권한
((SELECT id FROM users WHERE username = 'viewer'), 1, 'read', (SELECT id FROM users WHERE username = 'admin')),
((SELECT id FROM users WHERE username = 'viewer'), 2, 'read', (SELECT id FROM users WHERE username = 'admin'));

-- 테스트용 사용자 세션 데이터
INSERT INTO user_sessions (user_id, session_token, refresh_token, ip_address, user_agent, expires_at, is_active) VALUES
((SELECT id FROM users WHERE username = 'admin'), 'admin_session_token_123', 'admin_refresh_token_123', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', CURRENT_TIMESTAMP + INTERVAL '24 hours', true),
((SELECT id FROM users WHERE username = 'manager1'), 'manager1_session_token_456', 'manager1_refresh_token_456', '192.168.1.101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', CURRENT_TIMESTAMP + INTERVAL '24 hours', true),
((SELECT id FROM users WHERE username = 'accountant'), 'accountant_session_token_789', 'accountant_refresh_token_789', '192.168.1.102', 'Mozilla/5.0 (X11; Linux x86_64)', CURRENT_TIMESTAMP + INTERVAL '24 hours', true),
-- 만료된 세션 (테스트용)
((SELECT id FROM users WHERE username = 'staff1'), 'expired_session_token_999', 'expired_refresh_token_999', '192.168.1.103', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)', CURRENT_TIMESTAMP - INTERVAL '1 hour', false);

-- 테스트용 로그인 이력 데이터
INSERT INTO login_history (user_id, username, login_type, ip_address, user_agent, session_id) VALUES
-- 성공적인 로그인들
((SELECT id FROM users WHERE username = 'admin'), 'admin', 'SUCCESS', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 1),
((SELECT id FROM users WHERE username = 'manager1'), 'manager1', 'SUCCESS', '192.168.1.101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 2),
((SELECT id FROM users WHERE username = 'accountant'), 'accountant', 'SUCCESS', '192.168.1.102', 'Mozilla/5.0 (X11; Linux x86_64)', 3),
-- 실패한 로그인 시도들
(NULL, 'wronguser', 'FAILED', '192.168.1.200', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', NULL),
((SELECT id FROM users WHERE username = 'staff1'), 'staff1', 'FAILED', '192.168.1.103', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)', NULL),
((SELECT id FROM users WHERE username = 'staff1'), 'staff1', 'FAILED', '192.168.1.103', 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0)', NULL),
-- 계정 잠금
((SELECT id FROM users WHERE username = 'inactive'), 'inactive', 'LOCKED', '192.168.1.104', 'Mozilla/5.0 (Android 10)', NULL);

-- 테스트용 감사 로그 데이터 (수동 삽입 - 실제로는 트리거에 의해 자동 생성)
INSERT INTO audit_logs (table_name, record_id, action, old_values, new_values, changed_fields, user_id, building_id, ip_address, user_agent, request_id) VALUES
-- 건물 정보 수정 로그
('buildings', 1, 'UPDATE', 
 '{"name": "구 건물명", "address": "구 주소"}', 
 '{"name": "새 건물명", "address": "새 주소"}', 
 ARRAY['name', 'address'], 
 (SELECT id FROM users WHERE username = 'manager1'), 1, '192.168.1.101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 'req-001'),

-- 임차인 정보 생성 로그
('tenants', 1, 'INSERT', 
 NULL, 
 '{"name": "새 임차인", "contact_phone": "010-1111-2222"}', 
 NULL, 
 (SELECT id FROM users WHERE username = 'manager1'), 1, '192.168.1.101', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', 'req-002'),

-- 회계 전표 생성 로그
('journal_entries', 1, 'INSERT', 
 NULL, 
 '{"description": "임대료 수익", "total_debit": 1000000, "total_credit": 1000000}', 
 NULL, 
 (SELECT id FROM users WHERE username = 'accountant'), 1, '192.168.1.102', 'Mozilla/5.0 (X11; Linux x86_64)', 'req-003'),

-- 사용자 정보 수정 로그
('users', (SELECT id FROM users WHERE username = 'staff1'), 'UPDATE', 
 '{"full_name": "구 이름", "phone_number": "010-0000-0000"}', 
 '{"full_name": "정직원", "phone_number": "010-6789-0123"}', 
 ARRAY['full_name', 'phone_number'], 
 (SELECT id FROM users WHERE username = 'admin'), NULL, '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', 'req-004'),

-- 데이터 삭제 로그
('maintenance_requests', 999, 'DELETE', 
 '{"description": "삭제된 유지보수 요청", "status": "COMPLETED"}', 
 NULL, 
 NULL, 
 (SELECT id FROM users WHERE username = 'facility'), 1, '192.168.1.105', 'Mozilla/5.0 (Chrome)', 'req-005');

-- 테스트용 비밀번호 재설정 토큰
INSERT INTO password_reset_tokens (user_id, token, expires_at, is_used) VALUES
((SELECT id FROM users WHERE username = 'staff1'), 'reset_token_abc123def456', CURRENT_TIMESTAMP + INTERVAL '1 hour', false),
-- 만료된 토큰 (테스트용)
((SELECT id FROM users WHERE username = 'staff2'), 'expired_reset_token_xyz789', CURRENT_TIMESTAMP - INTERVAL '1 hour', false),
-- 사용된 토큰 (테스트용)
((SELECT id FROM users WHERE username = 'viewer'), 'used_reset_token_uvw456', CURRENT_TIMESTAMP + INTERVAL '30 minutes', true);

-- 테스트 쿼리 예제들
-- 1. 사용자별 권한 확인
/*
SELECT 
    u.username,
    u.full_name,
    r.display_name as role,
    pm.resource,
    pm.action,
    pm.is_allowed
FROM users u
JOIN roles r ON u.role_id = r.id
JOIN permission_matrix pm ON r.id = pm.role_id
WHERE u.username = 'manager1'
    AND pm.resource IN ('buildings', 'tenants', 'contracts')
ORDER BY pm.resource, pm.action;
*/

-- 2. 건물별 접근 권한 조회
/*
SELECT 
    u.username,
    u.full_name,
    b.name as building_name,
    uba.access_level,
    uba.granted_at,
    ug.username as granted_by
FROM user_building_access uba
JOIN users u ON uba.user_id = u.id
JOIN buildings b ON uba.building_id = b.id
LEFT JOIN users ug ON uba.granted_by = ug.id
WHERE uba.is_active = true
ORDER BY b.name, uba.access_level DESC;
*/

-- 3. 감사 로그 조회 (최근 활동)
/*
SELECT 
    al.created_at,
    u.username,
    al.table_name,
    al.action,
    al.record_id,
    al.changed_fields,
    b.name as building_name
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
LEFT JOIN buildings b ON al.building_id = b.id
WHERE al.created_at >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY al.created_at DESC
LIMIT 20;
*/

-- 4. 로그인 통계 조회
/*
SELECT 
    DATE(created_at) as login_date,
    login_type,
    COUNT(*) as count,
    COUNT(DISTINCT user_id) as unique_users
FROM login_history
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(created_at), login_type
ORDER BY login_date DESC, login_type;
*/

-- 5. 활성 세션 조회
/*
SELECT 
    u.username,
    u.full_name,
    us.ip_address,
    us.created_at as login_time,
    us.last_accessed_at,
    us.expires_at
FROM user_sessions us
JOIN users u ON us.user_id = u.id
WHERE us.is_active = true 
    AND us.expires_at > CURRENT_TIMESTAMP
ORDER BY us.last_accessed_at DESC;
*/

-- 6. 권한 확인 함수 테스트
/*
SELECT check_user_permission(
    (SELECT id FROM users WHERE username = 'manager1'),
    'tenants',
    'create',
    1
) as has_permission;
*/

-- 코멘트
COMMENT ON TABLE users IS '다양한 역할의 테스트 사용자 데이터';
COMMENT ON TABLE user_building_access IS '사용자별 건물 접근 권한 테스트 데이터';
COMMENT ON TABLE user_sessions IS '활성/비활성 세션 테스트 데이터';
COMMENT ON TABLE login_history IS '성공/실패 로그인 이력 테스트 데이터';
COMMENT ON TABLE audit_logs IS '다양한 테이블의 변경 이력 테스트 데이터';
COMMENT ON TABLE password_reset_tokens IS '비밀번호 재설정 토큰 테스트 데이터';-- ==
===================================================
-- 시스템 환경설정 테스트 데이터 (System Configuration Test Data)
-- =====================================================

-- 테스트용 설정 변경 이력 데이터
INSERT INTO setting_change_history (setting_key, old_value, new_value, change_reason, changed_by, ip_address, user_agent) VALUES
('security.session_timeout_minutes', '30', '60', '보안 정책 변경으로 세션 시간 연장', 
 (SELECT id FROM users WHERE username = 'admin'), '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
('notification.contract_expiry_days', '30', '45', '계약 만료 알림 기간 연장 요청', 
 (SELECT id FROM users WHERE username = 'admin'), '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
('email.from_address', 'old@qiro.co.kr', 'noreply@qiro.co.kr', '이메일 주소 정책 변경', 
 (SELECT id FROM users WHERE username = 'admin'), '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
('app.maintenance_mode', 'false', 'true', '시스템 업데이트를 위한 유지보수 모드 활성화', 
 (SELECT id FROM users WHERE username = 'admin'), '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'),
('app.maintenance_mode', 'true', 'false', '시스템 업데이트 완료 후 유지보수 모드 해제', 
 (SELECT id FROM users WHERE username = 'admin'), '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');

-- 테스트용 사용자별 알림 설정 데이터
INSERT INTO notification_settings (user_id, notification_type, channel, is_enabled, settings) VALUES
-- 관리자 알림 설정
((SELECT id FROM users WHERE username = 'admin'), 'contract_expiry', 'email', true, '{"advance_days": 30}'),
((SELECT id FROM users WHERE username = 'admin'), 'contract_expiry', 'sms', true, '{"advance_days": 7}'),
((SELECT id FROM users WHERE username = 'admin'), 'payment_overdue', 'email', true, '{"advance_days": 3}'),
((SELECT id FROM users WHERE username = 'admin'), 'system_alert', 'email', true, '{"severity": "critical"}'),

-- 건물 관리자 알림 설정
((SELECT id FROM users WHERE username = 'manager1'), 'contract_expiry', 'email', true, '{"advance_days": 30}'),
((SELECT id FROM users WHERE username = 'manager1'), 'payment_overdue', 'email', true, '{"advance_days": 5}'),
((SELECT id FROM users WHERE username = 'manager1'), 'maintenance_request', 'email', true, '{"priority": "high"}'),
((SELECT id FROM users WHERE username = 'manager1'), 'maintenance_request', 'in_app', true, '{"priority": "all"}'),

-- 회계 담당자 알림 설정
((SELECT id FROM users WHERE username = 'accountant'), 'payment_overdue', 'email', true, '{"advance_days": 1}'),
((SELECT id FROM users WHERE username = 'accountant'), 'payment_received', 'email', true, '{"amount_threshold": 1000000}'),
((SELECT id FROM users WHERE username = 'accountant'), 'monthly_report', 'email', true, '{"schedule": "monthly"}'),

-- 시설 관리자 알림 설정
((SELECT id FROM users WHERE username = 'facility'), 'maintenance_request', 'email', true, '{"priority": "all"}'),
((SELECT id FROM users WHERE username = 'facility'), 'maintenance_request', 'sms', true, '{"priority": "urgent"}'),
((SELECT id FROM users WHERE username = 'facility'), 'facility_inspection', 'email', true, '{"advance_days": 7}'),

-- 일반 직원 알림 설정 (최소한의 알림만)
((SELECT id FROM users WHERE username = 'staff1'), 'task_assigned', 'in_app', true, '{}'),
((SELECT id FROM users WHERE username = 'staff1'), 'system_announcement', 'in_app', true, '{}'),
((SELECT id FROM users WHERE username = 'staff2'), 'task_assigned', 'email', true, '{}'),
((SELECT id FROM users WHERE username = 'staff2'), 'task_assigned', 'in_app', true, '{}');

-- 테스트용 시스템 상태 로그 데이터
INSERT INTO system_health_logs (component, status, response_time_ms, error_message, additional_data) VALUES
-- 정상 상태 로그들
('database', 'healthy', 15, NULL, '{"connections": 10, "max_connections": 100}'),
('email_service', 'healthy', 250, NULL, '{"queue_size": 5, "sent_today": 150}'),
('file_storage', 'healthy', 8, NULL, '{"disk_usage": "45%", "available_space": "500GB"}'),
('external_api_kepco', 'healthy', 1200, NULL, '{"last_sync": "2024-01-15T10:30:00Z"}'),

-- 경고 상태 로그들
('database', 'warning', 85, NULL, '{"connections": 80, "max_connections": 100, "slow_queries": 3}'),
('email_service', 'warning', 2500, 'High response time detected', '{"queue_size": 25, "retry_count": 5}'),
('file_storage', 'warning', 12, NULL, '{"disk_usage": "85%", "available_space": "100GB"}'),

-- 오류 상태 로그들
('external_api_kepco', 'critical', NULL, 'Connection timeout after 30 seconds', '{"error_code": "TIMEOUT", "retry_attempts": 3}'),
('sms_service', 'critical', NULL, 'Authentication failed', '{"error_code": "AUTH_FAILED", "last_success": "2024-01-14T15:20:00Z"}'),
('backup_service', 'critical', NULL, 'Backup failed - insufficient disk space', '{"required_space": "10GB", "available_space": "2GB"}'),

-- 복구된 상태 로그들
('external_api_kepco', 'healthy', 800, NULL, '{"last_sync": "2024-01-15T11:00:00Z", "recovered_at": "2024-01-15T10:45:00Z"}'),
('sms_service', 'healthy', 150, NULL, '{"messages_sent": 10, "success_rate": "100%"}');

-- 테스트 쿼리 예제들
-- 1. 현재 시스템 설정 조회
/*
SELECT 
    category,
    setting_key,
    setting_value,
    setting_type,
    description,
    is_public
FROM system_settings
WHERE category IN ('security', 'notification', 'email')
ORDER BY category, setting_key;
*/

-- 2. 설정 변경 이력 조회
/*
SELECT 
    sch.changed_at,
    u.username as changed_by,
    sch.setting_key,
    sch.old_value,
    sch.new_value,
    sch.change_reason
FROM setting_change_history sch
LEFT JOIN users u ON sch.changed_by = u.id
WHERE sch.changed_at >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY sch.changed_at DESC;
*/

-- 3. 사용자별 알림 설정 조회
/*
SELECT 
    u.username,
    u.full_name,
    ns.notification_type,
    ns.channel,
    ns.is_enabled,
    ns.settings
FROM notification_settings ns
JOIN users u ON ns.user_id = u.id
WHERE u.username = 'manager1'
ORDER BY ns.notification_type, ns.channel;
*/

-- 4. 시스템 상태 모니터링 조회 (최근 24시간)
/*
SELECT 
    component,
    status,
    COUNT(*) as status_count,
    AVG(response_time_ms) as avg_response_time,
    MAX(checked_at) as last_check
FROM system_health_logs
WHERE checked_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY component, status
ORDER BY component, status;
*/

-- 5. 외부 서비스 설정 및 상태 조회
/*
SELECT 
    esc.service_name,
    esc.service_type,
    esc.is_active,
    esc.is_test_mode,
    esc.health_status,
    esc.last_health_check
FROM external_service_configs esc
ORDER BY esc.service_type, esc.service_name;
*/

-- 6. 조직 설정 조회
/*
SELECT 
    organization_name,
    business_registration_number,
    representative_name,
    contact_phone,
    contact_email,
    timezone,
    locale,
    currency
FROM organization_settings
LIMIT 1;
*/

-- 7. 시스템 설정 함수 테스트
/*
-- 설정값 조회
SELECT get_system_setting('security.session_timeout_minutes', '30') as session_timeout;

-- 설정값 업데이트 (함수 호출)
SELECT update_system_setting(
    'notification.contract_expiry_days',
    '60',
    (SELECT id FROM users WHERE username = 'admin'),
    '사용자 요청에 의한 알림 기간 연장'
) as update_success;
*/

-- 8. 시스템 상태 로그 기록 함수 테스트
/*
SELECT log_system_health(
    'test_component',
    'healthy',
    25,
    NULL,
    '{"test": true, "timestamp": "2024-01-15T12:00:00Z"}'::jsonb
);
*/

-- 코멘트
COMMENT ON TABLE setting_change_history IS '시스템 설정 변경 이력 테스트 데이터';
COMMENT ON TABLE notification_settings IS '사용자별 알림 채널 및 설정 테스트 데이터';
COMMENT ON TABLE system_health_logs IS '다양한 시스템 컴포넌트의 상태 로그 테스트 데이터';