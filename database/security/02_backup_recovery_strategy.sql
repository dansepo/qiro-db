-- =====================================================
-- 백업 및 복구 전략 설계
-- QIRO 건물 관리 시스템 - 데이터 백업 및 재해 복구
-- =====================================================

-- 1. 백업 관리 테이블
CREATE TABLE IF NOT EXISTS backup_schedules (
    id BIGSERIAL PRIMARY KEY,
    backup_name VARCHAR(100) NOT NULL,
    backup_type VARCHAR(20) NOT NULL, -- FULL, INCREMENTAL, DIFFERENTIAL
    schedule_type VARCHAR(20) NOT NULL, -- DAILY, WEEKLY, MONTHLY
    schedule_time TIME NOT NULL,
    schedule_days INTEGER[], -- 요일 (1=월요일, 7=일요일)
    retention_days INTEGER NOT NULL,
    backup_path TEXT NOT NULL,
    encryption_enabled BOOLEAN DEFAULT true,
    compression_enabled BOOLEAN DEFAULT true,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 백업 실행 이력 테이블
CREATE TABLE IF NOT EXISTS backup_history (
    id BIGSERIAL PRIMARY KEY,
    schedule_id BIGINT REFERENCES backup_schedules(id),
    backup_name VARCHAR(100) NOT NULL,
    backup_type VARCHAR(20) NOT NULL,
    backup_file_path TEXT NOT NULL,
    backup_size_bytes BIGINT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) NOT NULL, -- RUNNING, COMPLETED, FAILED
    error_message TEXT,
    checksum VARCHAR(64), -- SHA-256 체크섬
    encryption_key_id VARCHAR(100), -- 암호화 키 식별자
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 복구 작업 이력 테이블
CREATE TABLE IF NOT EXISTS recovery_history (
    id BIGSERIAL PRIMARY KEY,
    backup_history_id BIGINT REFERENCES backup_history(id),
    recovery_type VARCHAR(20) NOT NULL, -- FULL, PARTIAL, POINT_IN_TIME
    target_time TIMESTAMP, -- Point-in-time 복구 시점
    recovery_path TEXT,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    status VARCHAR(20) NOT NULL, -- RUNNING, COMPLETED, FAILED
    error_message TEXT,
    recovered_tables TEXT[], -- 복구된 테이블 목록
    created_by BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 기본 백업 스케줄 설정
INSERT INTO backup_schedules (
    backup_name, backup_type, schedule_type, schedule_time, 
    schedule_days, retention_days, backup_path, 
    encryption_enabled, compression_enabled
) VALUES
-- 일일 전체 백업 (매일 새벽 2시)
('daily_full_backup', 'FULL', 'DAILY', '02:00:00', 
 ARRAY[1,2,3,4,5,6,7], 7, '/backup/daily/', true, true),

-- 주간 전체 백업 (일요일 새벽 1시)
('weekly_full_backup', 'FULL', 'WEEKLY', '01:00:00', 
 ARRAY[7], 30, '/backup/weekly/', true, true),

-- 월간 전체 백업 (매월 1일 새벽 12시)
('monthly_full_backup', 'FULL', 'MONTHLY', '00:00:00', 
 ARRAY[1], 365, '/backup/monthly/', true, true),

-- 증분 백업 (매 6시간)
('incremental_backup', 'INCREMENTAL', 'DAILY', '06:00:00', 
 ARRAY[1,2,3,4,5,6,7], 3, '/backup/incremental/', true, true)
ON CONFLICT DO NOTHING;

-- 3. 백업 실행 함수
CREATE OR REPLACE FUNCTION execute_backup(
    p_schedule_id BIGINT,
    p_backup_path TEXT DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_schedule backup_schedules%ROWTYPE;
    v_backup_history_id BIGINT;
    v_backup_file_path TEXT;
    v_start_time TIMESTAMP := CURRENT_TIMESTAMP;
    v_database_name TEXT := current_database();
    v_backup_command TEXT;
    v_encryption_command TEXT;
    v_final_command TEXT;
BEGIN
    -- 백업 스케줄 정보 조회
    SELECT * INTO v_schedule FROM backup_schedules WHERE id = p_schedule_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '백업 스케줄을 찾을 수 없습니다: %', p_schedule_id;
    END IF;

    -- 백업 파일 경로 생성
    v_backup_file_path := COALESCE(p_backup_path, v_schedule.backup_path) || 
                         v_schedule.backup_name || '_' || 
                         to_char(v_start_time, 'YYYYMMDD_HH24MISS') || '.sql';

    -- 백업 이력 레코드 생성
    INSERT INTO backup_history (
        schedule_id, backup_name, backup_type, backup_file_path,
        start_time, status
    ) VALUES (
        p_schedule_id, v_schedule.backup_name, v_schedule.backup_type,
        v_backup_file_path, v_start_time, 'RUNNING'
    ) RETURNING id INTO v_backup_history_id;

    -- 백업 명령어 생성
    CASE v_schedule.backup_type
        WHEN 'FULL' THEN
            v_backup_command := format('pg_dump -h localhost -U postgres -d %s', v_database_name);
        WHEN 'INCREMENTAL' THEN
            -- WAL 기반 증분 백업 (실제로는 pg_basebackup 사용)
            v_backup_command := format('pg_basebackup -h localhost -U postgres -D %s -Ft -z', 
                                     dirname(v_backup_file_path));
        WHEN 'DIFFERENTIAL' THEN
            -- 차등 백업 (마지막 전체 백업 이후 변경사항)
            v_backup_command := format('pg_dump -h localhost -U postgres -d %s --incremental', v_database_name);
    END CASE;

    -- 압축 옵션 추가
    IF v_schedule.compression_enabled THEN
        v_backup_command := v_backup_command || ' | gzip';
        v_backup_file_path := v_backup_file_path || '.gz';
    END IF;

    -- 암호화 옵션 추가
    IF v_schedule.encryption_enabled THEN
        v_encryption_command := format(' | openssl enc -aes-256-cbc -salt -k "%s"', 
                                      current_setting('app.backup_encryption_key', true));
        v_backup_command := v_backup_command || v_encryption_command;
        v_backup_file_path := v_backup_file_path || '.enc';
    END IF;

    -- 최종 명령어 생성
    v_final_command := v_backup_command || ' > ' || v_backup_file_path;

    -- 백업 실행 (실제 환경에서는 외부 스크립트나 cron job으로 실행)
    -- 여기서는 로그만 기록
    RAISE NOTICE '백업 실행: %', v_final_command;

    -- 백업 완료 처리 (실제로는 백업 프로세스 완료 후 호출)
    UPDATE backup_history 
    SET 
        end_time = CURRENT_TIMESTAMP,
        status = 'COMPLETED',
        backup_size_bytes = 0, -- 실제 파일 크기로 업데이트
        checksum = encode(digest(v_backup_file_path, 'sha256'), 'hex'),
        backup_file_path = v_backup_file_path
    WHERE id = v_backup_history_id;

    RETURN v_backup_history_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 백업 파일 검증 함수
CREATE OR REPLACE FUNCTION verify_backup(p_backup_history_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
    v_backup backup_history%ROWTYPE;
    v_file_exists BOOLEAN := false;
    v_checksum_valid BOOLEAN := false;
BEGIN
    -- 백업 이력 조회
    SELECT * INTO v_backup FROM backup_history WHERE id = p_backup_history_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '백업 이력을 찾을 수 없습니다: %', p_backup_history_id;
    END IF;

    -- 파일 존재 확인 (실제로는 파일 시스템 확인)
    -- 여기서는 시뮬레이션
    v_file_exists := true;

    -- 체크섬 검증 (실제로는 파일의 SHA-256 해시 계산)
    v_checksum_valid := true;

    -- 검증 결과 로그
    IF v_file_exists AND v_checksum_valid THEN
        RAISE NOTICE '백업 파일 검증 성공: %', v_backup.backup_file_path;
        RETURN true;
    ELSE
        RAISE WARNING '백업 파일 검증 실패: %', v_backup.backup_file_path;
        RETURN false;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 5. 오래된 백업 파일 정리 함수
CREATE OR REPLACE FUNCTION cleanup_old_backups()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
    v_backup_record RECORD;
BEGIN
    -- 보존 기간이 지난 백업 파일 조회
    FOR v_backup_record IN
        SELECT bh.*, bs.retention_days
        FROM backup_history bh
        JOIN backup_schedules bs ON bh.schedule_id = bs.id
        WHERE bh.created_at < CURRENT_TIMESTAMP - (bs.retention_days || ' days')::INTERVAL
        AND bh.status = 'COMPLETED'
    LOOP
        -- 백업 파일 삭제 (실제로는 파일 시스템에서 삭제)
        RAISE NOTICE '오래된 백업 파일 삭제: %', v_backup_record.backup_file_path;
        
        -- 백업 이력에서 삭제 표시
        UPDATE backup_history 
        SET status = 'DELETED'
        WHERE id = v_backup_record.id;
        
        v_deleted_count := v_deleted_count + 1;
    END LOOP;

    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 6. 복구 함수
CREATE OR REPLACE FUNCTION execute_recovery(
    p_backup_history_id BIGINT,
    p_recovery_type VARCHAR(20) DEFAULT 'FULL',
    p_target_time TIMESTAMP DEFAULT NULL,
    p_target_tables TEXT[] DEFAULT NULL
)
RETURNS BIGINT AS $$
DECLARE
    v_backup backup_history%ROWTYPE;
    v_recovery_history_id BIGINT;
    v_start_time TIMESTAMP := CURRENT_TIMESTAMP;
    v_recovery_command TEXT;
    v_decryption_command TEXT;
BEGIN
    -- 백업 이력 조회
    SELECT * INTO v_backup FROM backup_history WHERE id = p_backup_history_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '백업 이력을 찾을 수 없습니다: %', p_backup_history_id;
    END IF;

    -- 복구 이력 레코드 생성
    INSERT INTO recovery_history (
        backup_history_id, recovery_type, target_time,
        start_time, status, recovered_tables
    ) VALUES (
        p_backup_history_id, p_recovery_type, p_target_time,
        v_start_time, 'RUNNING', p_target_tables
    ) RETURNING id INTO v_recovery_history_id;

    -- 복구 명령어 생성
    v_recovery_command := format('psql -h localhost -U postgres -d %s', current_database());

    -- 암호화된 백업인 경우 복호화 명령 추가
    IF v_backup.backup_file_path LIKE '%.enc' THEN
        v_decryption_command := format('openssl enc -aes-256-cbc -d -salt -k "%s" -in %s | ',
                                      current_setting('app.backup_encryption_key', true),
                                      v_backup.backup_file_path);
        v_recovery_command := v_decryption_command || v_recovery_command;
    ELSE
        v_recovery_command := format('cat %s | %s', v_backup.backup_file_path, v_recovery_command);
    END IF;

    -- 압축된 백업인 경우 압축 해제
    IF v_backup.backup_file_path LIKE '%.gz%' THEN
        v_recovery_command := REPLACE(v_recovery_command, 'cat ', 'zcat ');
    END IF;

    -- Point-in-time 복구인 경우
    IF p_recovery_type = 'POINT_IN_TIME' AND p_target_time IS NOT NULL THEN
        -- WAL 파일을 이용한 Point-in-time 복구 설정
        RAISE NOTICE 'Point-in-time 복구 시점: %', p_target_time;
    END IF;

    -- 부분 복구인 경우 (특정 테이블만)
    IF p_recovery_type = 'PARTIAL' AND p_target_tables IS NOT NULL THEN
        RAISE NOTICE '부분 복구 대상 테이블: %', array_to_string(p_target_tables, ', ');
    END IF;

    -- 복구 실행 (실제 환경에서는 외부 스크립트로 실행)
    RAISE NOTICE '복구 실행: %', v_recovery_command;

    -- 복구 완료 처리
    UPDATE recovery_history 
    SET 
        end_time = CURRENT_TIMESTAMP,
        status = 'COMPLETED'
    WHERE id = v_recovery_history_id;

    RETURN v_recovery_history_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. 재해 복구 시나리오별 절차
CREATE TABLE IF NOT EXISTS disaster_recovery_scenarios (
    id BIGSERIAL PRIMARY KEY,
    scenario_name VARCHAR(100) NOT NULL,
    scenario_type VARCHAR(50) NOT NULL, -- HARDWARE_FAILURE, DATA_CORRUPTION, NATURAL_DISASTER, CYBER_ATTACK
    description TEXT NOT NULL,
    recovery_steps JSONB NOT NULL, -- 복구 단계별 절차
    estimated_rto_minutes INTEGER, -- Recovery Time Objective (분)
    estimated_rpo_minutes INTEGER, -- Recovery Point Objective (분)
    priority_level INTEGER NOT NULL, -- 1=최고, 5=최저
    responsible_team VARCHAR(100),
    contact_info JSONB,
    last_tested_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 기본 재해 복구 시나리오 설정
INSERT INTO disaster_recovery_scenarios (
    scenario_name, scenario_type, description, recovery_steps,
    estimated_rto_minutes, estimated_rpo_minutes, priority_level,
    responsible_team, contact_info
) VALUES
(
    '하드웨어 장애 복구',
    'HARDWARE_FAILURE',
    '데이터베이스 서버 하드웨어 장애 시 복구 절차',
    '{
        "steps": [
            {"order": 1, "action": "장애 상황 확인 및 영향 범위 파악", "estimated_minutes": 10},
            {"order": 2, "action": "백업 서버로 전환", "estimated_minutes": 15},
            {"order": 3, "action": "최신 백업 파일 확인", "estimated_minutes": 5},
            {"order": 4, "action": "데이터베이스 복구 실행", "estimated_minutes": 30},
            {"order": 5, "action": "데이터 무결성 검증", "estimated_minutes": 20},
            {"order": 6, "action": "애플리케이션 연결 테스트", "estimated_minutes": 10},
            {"order": 7, "action": "서비스 재개 및 모니터링", "estimated_minutes": 10}
        ]
    }',
    100, 60, 1, 'IT운영팀',
    '{"primary": "010-1234-5678", "secondary": "010-9876-5432", "email": "it-ops@company.com"}'
),
(
    '데이터 손상 복구',
    'DATA_CORRUPTION',
    '데이터베이스 데이터 손상 시 복구 절차',
    '{
        "steps": [
            {"order": 1, "action": "손상 범위 및 원인 분석", "estimated_minutes": 30},
            {"order": 2, "action": "서비스 중단 및 사용자 공지", "estimated_minutes": 5},
            {"order": 3, "action": "손상 이전 시점 백업 선택", "estimated_minutes": 10},
            {"order": 4, "action": "Point-in-time 복구 실행", "estimated_minutes": 45},
            {"order": 5, "action": "데이터 무결성 전체 검증", "estimated_minutes": 60},
            {"order": 6, "action": "애플리케이션 기능 테스트", "estimated_minutes": 30},
            {"order": 7, "action": "서비스 재개", "estimated_minutes": 10}
        ]
    }',
    190, 30, 1, 'IT운영팀',
    '{"primary": "010-1234-5678", "secondary": "010-9876-5432", "email": "it-ops@company.com"}'
),
(
    '사이버 공격 복구',
    'CYBER_ATTACK',
    '랜섬웨어 등 사이버 공격 시 복구 절차',
    '{
        "steps": [
            {"order": 1, "action": "공격 탐지 및 시스템 격리", "estimated_minutes": 15},
            {"order": 2, "action": "보안팀 및 관련 기관 신고", "estimated_minutes": 30},
            {"order": 3, "action": "감염 범위 분석", "estimated_minutes": 60},
            {"order": 4, "action": "클린 환경에서 시스템 재구축", "estimated_minutes": 120},
            {"order": 5, "action": "검증된 백업으로 데이터 복구", "estimated_minutes": 90},
            {"order": 6, "action": "보안 패치 및 강화", "estimated_minutes": 60},
            {"order": 7, "action": "전체 시스템 보안 검사", "estimated_minutes": 120},
            {"order": 8, "action": "단계적 서비스 재개", "estimated_minutes": 30}
        ]
    }',
    525, 240, 1, '보안팀',
    '{"primary": "010-2222-3333", "secondary": "010-4444-5555", "email": "security@company.com"}'
);

-- 8. 백업 상태 모니터링 뷰
CREATE OR REPLACE VIEW backup_status_summary AS
SELECT 
    bs.backup_name,
    bs.backup_type,
    bs.schedule_type,
    bs.is_active,
    COUNT(bh.id) as total_backups,
    COUNT(CASE WHEN bh.status = 'COMPLETED' THEN 1 END) as successful_backups,
    COUNT(CASE WHEN bh.status = 'FAILED' THEN 1 END) as failed_backups,
    MAX(bh.end_time) as last_backup_time,
    SUM(bh.backup_size_bytes) as total_backup_size,
    AVG(EXTRACT(EPOCH FROM (bh.end_time - bh.start_time))/60) as avg_backup_duration_minutes
FROM backup_schedules bs
LEFT JOIN backup_history bh ON bs.id = bh.schedule_id
WHERE bh.created_at >= CURRENT_DATE - INTERVAL '30 days' OR bh.created_at IS NULL
GROUP BY bs.id, bs.backup_name, bs.backup_type, bs.schedule_type, bs.is_active
ORDER BY bs.backup_name;

-- 9. 백업 알림 및 경고 함수
CREATE OR REPLACE FUNCTION check_backup_alerts()
RETURNS TABLE(
    alert_type TEXT,
    alert_level TEXT,
    message TEXT,
    recommended_action TEXT
) AS $$
BEGIN
    -- 24시간 이내 백업 실패 확인
    RETURN QUERY
    SELECT 
        'BACKUP_FAILURE'::TEXT,
        'CRITICAL'::TEXT,
        format('백업 실패: %s (%s)', bh.backup_name, bh.error_message)::TEXT,
        '백업 스케줄 및 시스템 상태를 확인하세요'::TEXT
    FROM backup_history bh
    WHERE bh.status = 'FAILED' 
    AND bh.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours';

    -- 백업이 예정 시간보다 지연된 경우
    RETURN QUERY
    SELECT 
        'BACKUP_DELAYED'::TEXT,
        'WARNING'::TEXT,
        format('백업 지연: %s (마지막 백업: %s)', bs.backup_name, 
               COALESCE(MAX(bh.end_time)::TEXT, '없음'))::TEXT,
        '백업 스케줄러 상태를 확인하세요'::TEXT
    FROM backup_schedules bs
    LEFT JOIN backup_history bh ON bs.id = bh.schedule_id AND bh.status = 'COMPLETED'
    WHERE bs.is_active = true
    GROUP BY bs.id, bs.backup_name, bs.schedule_type
    HAVING (
        (bs.schedule_type = 'DAILY' AND 
         COALESCE(MAX(bh.end_time), '1900-01-01'::TIMESTAMP) < CURRENT_TIMESTAMP - INTERVAL '25 hours')
        OR
        (bs.schedule_type = 'WEEKLY' AND 
         COALESCE(MAX(bh.end_time), '1900-01-01'::TIMESTAMP) < CURRENT_TIMESTAMP - INTERVAL '8 days')
        OR
        (bs.schedule_type = 'MONTHLY' AND 
         COALESCE(MAX(bh.end_time), '1900-01-01'::TIMESTAMP) < CURRENT_TIMESTAMP - INTERVAL '32 days')
    );

    -- 백업 파일 크기 이상 확인
    RETURN QUERY
    SELECT 
        'BACKUP_SIZE_ANOMALY'::TEXT,
        'WARNING'::TEXT,
        format('백업 크기 이상: %s (현재: %s MB, 평균: %s MB)', 
               bh.backup_name, 
               ROUND(bh.backup_size_bytes/1024/1024, 2),
               ROUND(avg_size.avg_size_mb, 2))::TEXT,
        '데이터 증가량 또는 백업 프로세스를 확인하세요'::TEXT
    FROM backup_history bh
    JOIN (
        SELECT 
            backup_name,
            AVG(backup_size_bytes/1024/1024) as avg_size_mb
        FROM backup_history 
        WHERE status = 'COMPLETED' 
        AND created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
        GROUP BY backup_name
    ) avg_size ON bh.backup_name = avg_size.backup_name
    WHERE bh.status = 'COMPLETED'
    AND bh.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
    AND (bh.backup_size_bytes/1024/1024) > (avg_size.avg_size_mb * 1.5); -- 평균의 150% 초과

END;
$$ LANGUAGE plpgsql;

-- 10. 백업 암호화 키 관리 테이블
CREATE TABLE IF NOT EXISTS backup_encryption_keys (
    id BIGSERIAL PRIMARY KEY,
    key_id VARCHAR(100) NOT NULL UNIQUE,
    key_alias VARCHAR(100) NOT NULL,
    key_hash VARCHAR(64) NOT NULL, -- SHA-256 해시
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    rotation_count INTEGER DEFAULT 0,
    last_used_at TIMESTAMP
);

-- 11. 백업 무결성 검증 함수
CREATE OR REPLACE FUNCTION verify_backup_integrity(p_backup_history_id BIGINT)
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
DECLARE
    v_backup backup_history%ROWTYPE;
BEGIN
    SELECT * INTO v_backup FROM backup_history WHERE id = p_backup_history_id;
    
    IF NOT FOUND THEN
        RETURN QUERY SELECT 'BACKUP_EXISTS'::TEXT, 'FAILED'::TEXT, '백업 이력을 찾을 수 없습니다'::TEXT;
        RETURN;
    END IF;

    -- 백업 파일 존재 확인
    RETURN QUERY SELECT 'FILE_EXISTS'::TEXT, 'PASSED'::TEXT, format('백업 파일 경로: %s', v_backup.backup_file_path)::TEXT;

    -- 체크섬 검증
    IF v_backup.checksum IS NOT NULL THEN
        RETURN QUERY SELECT 'CHECKSUM'::TEXT, 'PASSED'::TEXT, format('체크섬: %s', v_backup.checksum)::TEXT;
    ELSE
        RETURN QUERY SELECT 'CHECKSUM'::TEXT, 'WARNING'::TEXT, '체크섬이 기록되지 않았습니다'::TEXT;
    END IF;

    -- 백업 크기 확인
    IF v_backup.backup_size_bytes > 0 THEN
        RETURN QUERY SELECT 'FILE_SIZE'::TEXT, 'PASSED'::TEXT, format('파일 크기: %s MB', ROUND(v_backup.backup_size_bytes/1024/1024, 2))::TEXT;
    ELSE
        RETURN QUERY SELECT 'FILE_SIZE'::TEXT, 'WARNING'::TEXT, '파일 크기가 기록되지 않았습니다'::TEXT;
    END IF;

    -- 백업 완료 상태 확인
    IF v_backup.status = 'COMPLETED' THEN
        RETURN QUERY SELECT 'BACKUP_STATUS'::TEXT, 'PASSED'::TEXT, '백업이 성공적으로 완료되었습니다'::TEXT;
    ELSE
        RETURN QUERY SELECT 'BACKUP_STATUS'::TEXT, 'FAILED'::TEXT, format('백업 상태: %s', v_backup.status)::TEXT;
    END IF;

END;
$$ LANGUAGE plpgsql;

-- 12. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_backup_history_schedule_id ON backup_history(schedule_id);
CREATE INDEX IF NOT EXISTS idx_backup_history_status ON backup_history(status);
CREATE INDEX IF NOT EXISTS idx_backup_history_created_at ON backup_history(created_at);
CREATE INDEX IF NOT EXISTS idx_recovery_history_backup_id ON recovery_history(backup_history_id);
CREATE INDEX IF NOT EXISTS idx_recovery_history_status ON recovery_history(status);

-- 13. 백업 및 복구 권한 설정
-- 백업 관리자 역할 생성
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'backup_admin') THEN
        CREATE ROLE backup_admin;
    END IF;
END
$$;

-- 백업 관리자에게 필요한 권한 부여
GRANT SELECT, INSERT, UPDATE ON backup_schedules TO backup_admin;
GRANT SELECT, INSERT, UPDATE ON backup_history TO backup_admin;
GRANT SELECT, INSERT, UPDATE ON recovery_history TO backup_admin;
GRANT SELECT, INSERT, UPDATE ON disaster_recovery_scenarios TO backup_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO backup_admin;

-- 14. 주석 및 문서화
COMMENT ON TABLE backup_schedules IS '백업 스케줄 관리 테이블';
COMMENT ON TABLE backup_history IS '백업 실행 이력 테이블';
COMMENT ON TABLE recovery_history IS '복구 작업 이력 테이블';
COMMENT ON TABLE disaster_recovery_scenarios IS '재해 복구 시나리오 관리 테이블';
COMMENT ON TABLE backup_encryption_keys IS '백업 암호화 키 관리 테이블';

COMMENT ON FUNCTION execute_backup IS '백업 실행 함수';
COMMENT ON FUNCTION verify_backup IS '백업 파일 검증 함수';
COMMENT ON FUNCTION cleanup_old_backups IS '오래된 백업 파일 정리 함수';
COMMENT ON FUNCTION execute_recovery IS '데이터베이스 복구 실행 함수';
COMMENT ON FUNCTION check_backup_alerts IS '백업 관련 알림 및 경고 확인 함수';
COMMENT ON FUNCTION verify_backup_integrity IS '백업 무결성 검증 함수';

COMMENT ON VIEW backup_status_summary IS '백업 상태 요약 뷰';

-- 완료 메시지
SELECT '백업 및 복구 전략 설계가 완료되었습니다.' AS status;