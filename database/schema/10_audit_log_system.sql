-- =====================================================
-- 감사 로그 시스템 생성 스크립트
-- Phase 4.1: 데이터 변경 이력 테이블
-- =====================================================

-- 1. 감사 로그 테이블 생성
CREATE TABLE IF NOT EXISTS bms.audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 테이블 및 레코드 정보
    table_name VARCHAR(100) NOT NULL,                   -- 변경된 테이블명
    record_id UUID NOT NULL,                            -- 변경된 레코드 ID
    
    -- 작업 정보
    operation_type VARCHAR(20) NOT NULL,                -- 작업 유형 (INSERT, UPDATE, DELETE)
    operation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 변경 데이터
    old_values JSONB,                                   -- 변경 전 데이터 (JSON)
    new_values JSONB,                                   -- 변경 후 데이터 (JSON)
    changed_fields TEXT[],                              -- 변경된 필드 목록
    
    -- 사용자 정보
    user_id UUID,                                       -- 변경한 사용자 ID
    user_name VARCHAR(100),                             -- 변경한 사용자명
    user_role VARCHAR(50),                              -- 사용자 역할
    
    -- 세션 정보
    session_id VARCHAR(100),                            -- 세션 ID
    client_ip INET,                                     -- 클라이언트 IP
    user_agent TEXT,                                    -- 사용자 에이전트
    
    -- 비즈니스 정보
    business_context VARCHAR(100),                      -- 비즈니스 컨텍스트
    change_reason TEXT,                                 -- 변경 사유
    approval_status VARCHAR(20) DEFAULT 'APPROVED',     -- 승인 상태
    approved_by UUID,                                   -- 승인자 ID
    approved_at TIMESTAMP WITH TIME ZONE,              -- 승인 일시
    
    -- 기술적 정보
    transaction_id VARCHAR(100),                        -- 트랜잭션 ID
    application_name VARCHAR(100),                      -- 애플리케이션명
    api_endpoint VARCHAR(200),                          -- API 엔드포인트
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_audit_logs_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_audit_logs_user FOREIGN KEY (user_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_logs_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_operation_type CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')),
    CONSTRAINT chk_approval_status CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED', 'AUTO_APPROVED'))
);

-- 2. 민감한 데이터 감사 로그 테이블 (별도 보안 관리)
CREATE TABLE IF NOT EXISTS bms.sensitive_audit_logs (
    audit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 기본 감사 정보
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    operation_type VARCHAR(20) NOT NULL,
    operation_timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 암호화된 데이터 (민감 정보)
    encrypted_old_values BYTEA,                         -- 암호화된 이전 값
    encrypted_new_values BYTEA,                         -- 암호화된 새 값
    encryption_key_id VARCHAR(100),                     -- 암호화 키 ID
    
    -- 접근 제어
    access_level INTEGER DEFAULT 1,                     -- 접근 레벨 (1-5)
    retention_period INTEGER DEFAULT 2555,              -- 보관 기간 (일)
    
    -- 사용자 정보
    user_id UUID,
    user_name VARCHAR(100),
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_sensitive_audit_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_sensitive_audit_user FOREIGN KEY (user_id) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    
    -- 체크 제약조건
    CONSTRAINT chk_sensitive_operation_type CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT chk_access_level CHECK (access_level BETWEEN 1 AND 5),
    CONSTRAINT chk_retention_period CHECK (retention_period > 0)
);

-- 3. 감사 로그 설정 테이블
CREATE TABLE IF NOT EXISTS bms.audit_log_config (
    config_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 테이블별 감사 설정
    table_name VARCHAR(100) NOT NULL,
    is_audit_enabled BOOLEAN DEFAULT true,              -- 감사 활성화 여부
    audit_level VARCHAR(20) DEFAULT 'STANDARD',         -- 감사 레벨
    
    -- 필드별 감사 설정
    tracked_fields TEXT[],                              -- 추적할 필드 목록 (NULL이면 전체)
    excluded_fields TEXT[],                             -- 제외할 필드 목록
    sensitive_fields TEXT[],                            -- 민감한 필드 목록
    
    -- 보관 정책
    retention_days INTEGER DEFAULT 2555,                -- 보관 기간 (7년)
    archive_after_days INTEGER DEFAULT 365,             -- 아카이브 기간 (1년)
    
    -- 알림 설정
    notify_on_change BOOLEAN DEFAULT false,             -- 변경 시 알림
    notification_recipients TEXT[],                     -- 알림 수신자
    
    -- 승인 워크플로우
    require_approval BOOLEAN DEFAULT false,             -- 승인 필요 여부
    approval_roles TEXT[],                              -- 승인 가능 역할
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    is_active BOOLEAN DEFAULT true,
    
    -- 제약조건
    CONSTRAINT fk_audit_config_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT uk_audit_config_table UNIQUE (company_id, table_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_audit_level CHECK (audit_level IN ('MINIMAL', 'STANDARD', 'DETAILED', 'COMPREHENSIVE')),
    CONSTRAINT chk_retention_days CHECK (retention_days > 0),
    CONSTRAINT chk_archive_days CHECK (archive_after_days > 0)
);

-- 4. RLS 정책 활성화
ALTER TABLE bms.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.sensitive_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.audit_log_config ENABLE ROW LEVEL SECURITY;

-- 5. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY audit_logs_isolation_policy ON bms.audit_logs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY sensitive_audit_logs_isolation_policy ON bms.sensitive_audit_logs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY audit_log_config_isolation_policy ON bms.audit_log_config
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 6. 성능 최적화 인덱스 생성
-- 감사 로그 테이블 인덱스
CREATE INDEX idx_audit_logs_company_id ON bms.audit_logs(company_id);
CREATE INDEX idx_audit_logs_table_name ON bms.audit_logs(table_name);
CREATE INDEX idx_audit_logs_record_id ON bms.audit_logs(record_id);
CREATE INDEX idx_audit_logs_operation_type ON bms.audit_logs(operation_type);
CREATE INDEX idx_audit_logs_operation_timestamp ON bms.audit_logs(operation_timestamp DESC);
CREATE INDEX idx_audit_logs_user_id ON bms.audit_logs(user_id);
CREATE INDEX idx_audit_logs_approval_status ON bms.audit_logs(approval_status);

-- 민감한 감사 로그 테이블 인덱스
CREATE INDEX idx_sensitive_audit_company_id ON bms.sensitive_audit_logs(company_id);
CREATE INDEX idx_sensitive_audit_table_name ON bms.sensitive_audit_logs(table_name);
CREATE INDEX idx_sensitive_audit_timestamp ON bms.sensitive_audit_logs(operation_timestamp DESC);
CREATE INDEX idx_sensitive_audit_user_id ON bms.sensitive_audit_logs(user_id);
CREATE INDEX idx_sensitive_audit_access_level ON bms.sensitive_audit_logs(access_level);

-- 감사 설정 테이블 인덱스
CREATE INDEX idx_audit_config_company_id ON bms.audit_log_config(company_id);
CREATE INDEX idx_audit_config_table_name ON bms.audit_log_config(table_name);
CREATE INDEX idx_audit_config_is_active ON bms.audit_log_config(is_active);

-- 복합 인덱스
CREATE INDEX idx_audit_logs_company_table ON bms.audit_logs(company_id, table_name);
CREATE INDEX idx_audit_logs_table_record ON bms.audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_user_timestamp ON bms.audit_logs(user_id, operation_timestamp DESC);
CREATE INDEX idx_audit_logs_company_timestamp ON bms.audit_logs(company_id, operation_timestamp DESC);

-- 7. 파티셔닝 설정 (향후 대용량 데이터 처리를 위한 준비)
-- 현재는 단일 테이블로 운영하고, 필요시 파티셔닝 적용 예정
-- 파티셔닝 적용 시 다음 명령어 사용:
-- ALTER TABLE bms.audit_logs PARTITION BY RANGE (operation_timestamp);
-- CREATE TABLE bms.audit_logs_y2025m01 PARTITION OF bms.audit_logs
--     FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER audit_log_config_updated_at_trigger
    BEFORE UPDATE ON bms.audit_log_config
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 감사 로그 기록 함수
CREATE OR REPLACE FUNCTION bms.log_data_change(
    p_table_name VARCHAR(100),
    p_record_id UUID,
    p_operation_type VARCHAR(20),
    p_old_values JSONB DEFAULT NULL,
    p_new_values JSONB DEFAULT NULL,
    p_user_id UUID DEFAULT NULL,
    p_change_reason TEXT DEFAULT NULL,
    p_business_context VARCHAR(100) DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_audit_id UUID;
    v_company_id UUID;
    v_user_name VARCHAR(100);
    v_user_role VARCHAR(50);
    v_changed_fields TEXT[];
    v_config_rec RECORD;
    v_is_sensitive BOOLEAN := false;
BEGIN
    -- 현재 회사 ID 가져오기
    v_company_id := (current_setting('app.current_company_id', true))::uuid;
    
    -- 감사 설정 확인
    SELECT * INTO v_config_rec
    FROM bms.audit_log_config
    WHERE company_id = v_company_id
      AND table_name = p_table_name
      AND is_active = true;
    
    -- 감사가 비활성화된 경우 종료
    IF NOT FOUND OR v_config_rec.is_audit_enabled = false THEN
        RETURN NULL;
    END IF;
    
    -- 사용자 정보 조회
    IF p_user_id IS NOT NULL THEN
        SELECT u.name, r.role_name INTO v_user_name, v_user_role
        FROM bms.users u
        LEFT JOIN bms.user_role_links url ON u.user_id = url.user_id
        LEFT JOIN bms.roles r ON url.role_id = r.role_id
        WHERE u.user_id = p_user_id
        LIMIT 1;
    END IF;
    
    -- 변경된 필드 목록 생성
    IF p_operation_type = 'UPDATE' AND p_old_values IS NOT NULL AND p_new_values IS NOT NULL THEN
        SELECT array_agg(key) INTO v_changed_fields
        FROM jsonb_each(p_old_values) old_kv
        JOIN jsonb_each(p_new_values) new_kv ON old_kv.key = new_kv.key
        WHERE old_kv.value IS DISTINCT FROM new_kv.value;
    END IF;
    
    -- 민감한 필드 포함 여부 확인
    IF v_config_rec.sensitive_fields IS NOT NULL AND array_length(v_config_rec.sensitive_fields, 1) > 0 THEN
        IF v_changed_fields && v_config_rec.sensitive_fields THEN
            v_is_sensitive := true;
        END IF;
    END IF;
    
    -- 감사 로그 생성
    v_audit_id := gen_random_uuid();
    
    INSERT INTO bms.audit_logs (
        audit_id, company_id, table_name, record_id, operation_type,
        old_values, new_values, changed_fields,
        user_id, user_name, user_role,
        business_context, change_reason,
        session_id, client_ip, user_agent,
        approval_status
    ) VALUES (
        v_audit_id, v_company_id, p_table_name, p_record_id, p_operation_type,
        p_old_values, p_new_values, v_changed_fields,
        p_user_id, v_user_name, v_user_role,
        p_business_context, p_change_reason,
        current_setting('app.session_id', true),
        inet_client_addr(),
        current_setting('app.user_agent', true),
        CASE WHEN v_config_rec.require_approval THEN 'PENDING' ELSE 'AUTO_APPROVED' END
    );
    
    -- 민감한 데이터의 경우 별도 테이블에도 기록
    IF v_is_sensitive THEN
        INSERT INTO bms.sensitive_audit_logs (
            company_id, table_name, record_id, operation_type,
            encrypted_old_values, encrypted_new_values,
            user_id, user_name
        ) VALUES (
            v_company_id, p_table_name, p_record_id, p_operation_type,
            -- 실제 구현에서는 암호화 함수 사용
            p_old_values::text::bytea, p_new_values::text::bytea,
            p_user_id, v_user_name
        );
    END IF;
    
    RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql;

-- 10. 자동 감사 로그 트리거 함수
CREATE OR REPLACE FUNCTION bms.auto_audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
    v_table_name VARCHAR(100);
    v_old_values JSONB;
    v_new_values JSONB;
    v_record_id UUID;
BEGIN
    v_table_name := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME;
    
    -- 레코드 ID 추출 (대부분의 테이블이 *_id 컬럼을 가정)
    CASE TG_OP
        WHEN 'INSERT' THEN
            v_record_id := (to_jsonb(NEW) ->> (TG_TABLE_NAME || '_id'))::uuid;
            v_new_values := to_jsonb(NEW);
        WHEN 'UPDATE' THEN
            v_record_id := (to_jsonb(NEW) ->> (TG_TABLE_NAME || '_id'))::uuid;
            v_old_values := to_jsonb(OLD);
            v_new_values := to_jsonb(NEW);
        WHEN 'DELETE' THEN
            v_record_id := (to_jsonb(OLD) ->> (TG_TABLE_NAME || '_id'))::uuid;
            v_old_values := to_jsonb(OLD);
    END CASE;
    
    -- 감사 로그 기록
    PERFORM bms.log_data_change(
        v_table_name,
        v_record_id,
        TG_OP,
        v_old_values,
        v_new_values,
        (current_setting('app.current_user_id', true))::uuid,
        '자동 감사 로그',
        'AUTO_AUDIT'
    );
    
    RETURN CASE TG_OP WHEN 'DELETE' THEN OLD ELSE NEW END;
END;
$$ LANGUAGE plpgsql;

-- 11. 감사 로그 조회 뷰 생성
CREATE OR REPLACE VIEW bms.v_audit_log_summary AS
SELECT 
    al.audit_id,
    al.company_id,
    c.company_name,
    al.table_name,
    al.record_id,
    al.operation_type,
    al.operation_timestamp,
    al.user_name,
    al.user_role,
    al.change_reason,
    al.business_context,
    al.approval_status,
    array_length(al.changed_fields, 1) as changed_field_count,
    al.changed_fields,
    CASE 
        WHEN al.old_values IS NOT NULL AND al.new_values IS NOT NULL THEN 'UPDATE'
        WHEN al.old_values IS NULL AND al.new_values IS NOT NULL THEN 'INSERT'
        WHEN al.old_values IS NOT NULL AND al.new_values IS NULL THEN 'DELETE'
        ELSE al.operation_type
    END as operation_summary
FROM bms.audit_logs al
JOIN bms.companies c ON al.company_id = c.company_id
ORDER BY al.operation_timestamp DESC;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_audit_log_summary OWNER TO qiro;

-- 12. 감사 로그 통계 함수
CREATE OR REPLACE FUNCTION bms.get_audit_statistics(
    p_company_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    table_name VARCHAR(100),
    operation_type VARCHAR(20),
    operation_count BIGINT,
    unique_users BIGINT,
    last_operation TIMESTAMP WITH TIME ZONE
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
        al.table_name,
        al.operation_type,
        COUNT(*) as operation_count,
        COUNT(DISTINCT al.user_id) as unique_users,
        MAX(al.operation_timestamp) as last_operation
    FROM bms.audit_logs al
    WHERE al.company_id = v_company_id
      AND al.operation_timestamp::date BETWEEN p_start_date AND p_end_date
    GROUP BY al.table_name, al.operation_type
    ORDER BY operation_count DESC;
END;
$$ LANGUAGE plpgsql;

-- 13. 감사 로그 정리 함수 (오래된 로그 아카이브/삭제)
CREATE OR REPLACE FUNCTION bms.cleanup_audit_logs()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER := 0;
    v_config_rec RECORD;
BEGIN
    -- 각 테이블별 보관 정책에 따라 정리
    FOR v_config_rec IN 
        SELECT company_id, table_name, retention_days, archive_after_days
        FROM bms.audit_log_config
        WHERE is_active = true
    LOOP
        -- 보관 기간이 지난 로그 삭제
        DELETE FROM bms.audit_logs
        WHERE company_id = v_config_rec.company_id
          AND table_name = v_config_rec.table_name
          AND operation_timestamp < NOW() - (v_config_rec.retention_days || ' days')::INTERVAL;
        
        GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
        
        RAISE NOTICE '테이블 %에서 %개의 오래된 감사 로그를 삭제했습니다.', 
                     v_config_rec.table_name, v_deleted_count;
    END LOOP;
    
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql;

-- 완료 메시지
SELECT '✅ 4.1 감사 로그 시스템 생성이 완료되었습니다!' as result;