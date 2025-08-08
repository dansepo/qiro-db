-- =====================================================
-- 고지서 배포 관리 시스템 테이블 생성 스크립트
-- Phase 4.3: 고지서 배포 관리 (알림톡 포함)
-- =====================================================

-- 1. 배포 채널 설정 테이블
CREATE TABLE IF NOT EXISTS bms.distribution_channels (
    channel_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체
    
    -- 채널 기본 정보
    channel_name VARCHAR(100) NOT NULL,                    -- 채널명
    channel_type VARCHAR(20) NOT NULL,                     -- 채널 유형
    channel_description TEXT,                              -- 채널 설명
    
    -- 채널 설정
    provider_name VARCHAR(50),                             -- 서비스 제공업체
    api_endpoint TEXT,                                     -- API 엔드포인트
    api_credentials JSONB,                                 -- API 인증 정보 (암호화)
    
    -- 전송 설정
    max_retry_count INTEGER DEFAULT 3,                     -- 최대 재시도 횟수
    retry_interval_minutes INTEGER DEFAULT 30,             -- 재시도 간격 (분)
    timeout_seconds INTEGER DEFAULT 30,                    -- 타임아웃 (초)
    
    -- 용량 제한
    max_file_size_mb INTEGER DEFAULT 10,                   -- 최대 파일 크기 (MB)
    supported_formats TEXT[],                              -- 지원 포맷
    max_recipients_per_batch INTEGER DEFAULT 100,          -- 배치당 최대 수신자 수
    
    -- 비용 설정
    cost_per_message DECIMAL(10,4) DEFAULT 0,              -- 메시지당 비용
    cost_currency VARCHAR(3) DEFAULT 'KRW',                -- 통화
    billing_unit VARCHAR(20) DEFAULT 'MESSAGE',            -- 과금 단위
    
    -- 템플릿 설정 (알림톡용)
    template_code VARCHAR(50),                             -- 템플릿 코드
    template_content TEXT,                                 -- 템플릿 내용
    template_variables JSONB,                              -- 템플릿 변수
    
    -- 상태 및 제한
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    daily_limit INTEGER,                                   -- 일일 전송 한도
    monthly_limit INTEGER,                                 -- 월간 전송 한도
    
    -- 통계
    total_sent INTEGER DEFAULT 0,                          -- 총 전송 수
    total_delivered INTEGER DEFAULT 0,                     -- 총 배달 수
    total_failed INTEGER DEFAULT 0,                        -- 총 실패 수
    last_used_at TIMESTAMP WITH TIME ZONE,                -- 마지막 사용 시간
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_channels_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_channels_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_channels_name UNIQUE (company_id, building_id, channel_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_channel_type CHECK (channel_type IN (
        'EMAIL',               -- 이메일
        'SMS',                 -- SMS
        'KAKAO_TALK',          -- 카카오톡 알림톡
        'KAKAO_BIZ_TALK',      -- 카카오톡 비즈톡
        'NAVER_TALK',          -- 네이버 톡톡
        'POSTAL',              -- 우편
        'PICKUP',              -- 직접 수령
        'PORTAL',              -- 웹 포털
        'MOBILE_APP',          -- 모바일 앱
        'PUSH_NOTIFICATION',   -- 푸시 알림
        'FAX',                 -- 팩스
        'VOICE_CALL'           -- 음성 통화
    )),
    CONSTRAINT chk_billing_unit CHECK (billing_unit IN (
        'MESSAGE',             -- 메시지당
        'RECIPIENT',           -- 수신자당
        'FILE_SIZE',           -- 파일 크기당
        'BATCH'                -- 배치당
    )),
    CONSTRAINT chk_limits CHECK (
        max_retry_count >= 0 AND retry_interval_minutes > 0 AND
        timeout_seconds > 0 AND max_file_size_mb > 0 AND
        max_recipients_per_batch > 0 AND cost_per_message >= 0 AND
        (daily_limit IS NULL OR daily_limit > 0) AND
        (monthly_limit IS NULL OR monthly_limit > 0)
    ),
    CONSTRAINT chk_statistics CHECK (
        total_sent >= 0 AND total_delivered >= 0 AND total_failed >= 0 AND
        total_delivered <= total_sent AND total_failed <= total_sent
    )
);

-- 2. 수신자 그룹 관리 테이블
CREATE TABLE IF NOT EXISTS bms.recipient_groups (
    group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체
    
    -- 그룹 기본 정보
    group_name VARCHAR(100) NOT NULL,                      -- 그룹명
    group_description TEXT,                                -- 그룹 설명
    group_type VARCHAR(20) NOT NULL,                       -- 그룹 유형
    
    -- 그룹 조건
    selection_criteria JSONB NOT NULL,                     -- 선택 조건
    dynamic_group BOOLEAN DEFAULT false,                   -- 동적 그룹 여부
    
    -- 연락처 설정
    default_channel_types TEXT[],                          -- 기본 채널 유형
    contact_preferences JSONB,                             -- 연락처 선호도
    
    -- 통계
    member_count INTEGER DEFAULT 0,                        -- 멤버 수
    active_member_count INTEGER DEFAULT 0,                 -- 활성 멤버 수
    last_updated_at TIMESTAMP WITH TIME ZONE,              -- 마지막 업데이트
    
    -- 상태
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_groups_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_groups_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT uk_groups_name UNIQUE (company_id, building_id, group_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_group_type CHECK (group_type IN (
        'ALL_RESIDENTS',       -- 전체 입주자
        'UNIT_OWNERS',         -- 소유자
        'TENANTS',             -- 임차인
        'BUILDING_SPECIFIC',   -- 특정 건물
        'FLOOR_SPECIFIC',      -- 특정 층
        'UNIT_TYPE_SPECIFIC',  -- 특정 호실 유형
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_member_counts CHECK (
        member_count >= 0 AND active_member_count >= 0 AND
        active_member_count <= member_count
    )
);

-- 3. 수신자 연락처 정보 테이블
CREATE TABLE IF NOT EXISTS bms.recipient_contacts (
    contact_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    
    -- 수신자 기본 정보
    contact_name VARCHAR(100),                             -- 연락처명
    contact_type VARCHAR(20) NOT NULL,                     -- 연락처 유형
    contact_role VARCHAR(20) DEFAULT 'PRIMARY',            -- 연락처 역할
    
    -- 연락처 정보
    email_address VARCHAR(255),                            -- 이메일 주소
    phone_number VARCHAR(20),                              -- 전화번호
    mobile_number VARCHAR(20),                             -- 휴대폰 번호
    kakao_id VARCHAR(100),                                 -- 카카오 ID
    naver_id VARCHAR(100),                                 -- 네이버 ID
    postal_address TEXT,                                   -- 우편 주소
    postal_code VARCHAR(10),                               -- 우편번호
    
    -- 수신 설정
    email_enabled BOOLEAN DEFAULT true,                    -- 이메일 수신 허용
    sms_enabled BOOLEAN DEFAULT true,                      -- SMS 수신 허용
    kakao_talk_enabled BOOLEAN DEFAULT true,               -- 카카오톡 수신 허용
    push_enabled BOOLEAN DEFAULT true,                     -- 푸시 알림 수신 허용
    postal_enabled BOOLEAN DEFAULT false,                  -- 우편 수신 허용
    
    -- 수신 시간 설정
    preferred_time_start TIME DEFAULT '09:00',             -- 선호 시작 시간
    preferred_time_end TIME DEFAULT '21:00',               -- 선호 종료 시간
    timezone VARCHAR(50) DEFAULT 'Asia/Seoul',             -- 시간대
    
    -- 언어 설정
    preferred_language VARCHAR(10) DEFAULT 'ko',           -- 선호 언어
    
    -- 검증 상태
    email_verified BOOLEAN DEFAULT false,                  -- 이메일 검증 여부
    phone_verified BOOLEAN DEFAULT false,                  -- 전화번호 검증 여부
    kakao_verified BOOLEAN DEFAULT false,                  -- 카카오 검증 여부
    
    -- 상태
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    is_primary BOOLEAN DEFAULT false,                      -- 주 연락처 여부
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_contacts_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_contacts_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_contact_type CHECK (contact_type IN (
        'OWNER',               -- 소유자
        'TENANT',              -- 임차인
        'MANAGER',             -- 관리인
        'EMERGENCY',           -- 비상 연락처
        'BILLING',             -- 청구서 수신자
        'OTHER'                -- 기타
    )),
    CONSTRAINT chk_contact_role CHECK (contact_role IN (
        'PRIMARY',             -- 주 연락처
        'SECONDARY',           -- 보조 연락처
        'EMERGENCY',           -- 비상 연락처
        'BILLING_ONLY'         -- 청구서 전용
    )),
    CONSTRAINT chk_preferred_language CHECK (preferred_language IN ('ko', 'en', 'zh', 'ja')),
    CONSTRAINT chk_preferred_times CHECK (preferred_time_end > preferred_time_start),
    CONSTRAINT chk_contact_info CHECK (
        email_address IS NOT NULL OR phone_number IS NOT NULL OR 
        mobile_number IS NOT NULL OR kakao_id IS NOT NULL OR postal_address IS NOT NULL
    )
);

-- 4. 배포 작업 큐 테이블
CREATE TABLE IF NOT EXISTS bms.distribution_queue (
    queue_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    issuance_id UUID NOT NULL,
    
    -- 배포 설정
    channel_id UUID NOT NULL,                              -- 배포 채널
    recipient_contact_id UUID NOT NULL,                    -- 수신자 연락처
    
    -- 우선순위 및 스케줄
    priority_level INTEGER DEFAULT 5,                      -- 우선순위 (1=높음, 10=낮음)
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),   -- 예약 시간
    
    -- 메시지 내용
    message_subject VARCHAR(500),                          -- 메시지 제목
    message_content TEXT,                                  -- 메시지 내용
    message_template_id UUID,                              -- 메시지 템플릿 ID
    message_variables JSONB,                               -- 메시지 변수
    
    -- 첨부 파일
    attachment_file_path TEXT,                             -- 첨부 파일 경로
    attachment_file_name VARCHAR(255),                     -- 첨부 파일명
    attachment_file_size BIGINT,                           -- 첨부 파일 크기
    
    -- 처리 상태
    queue_status VARCHAR(20) DEFAULT 'PENDING',            -- 큐 상태
    processing_status VARCHAR(20) DEFAULT 'WAITING',       -- 처리 상태
    
    -- 처리 시도
    attempt_count INTEGER DEFAULT 0,                       -- 시도 횟수
    max_attempts INTEGER DEFAULT 3,                        -- 최대 시도 횟수
    last_attempt_at TIMESTAMP WITH TIME ZONE,              -- 마지막 시도 시간
    next_attempt_at TIMESTAMP WITH TIME ZONE,              -- 다음 시도 시간
    
    -- 처리 결과
    delivery_result VARCHAR(20),                           -- 배포 결과
    response_code VARCHAR(20),                             -- 응답 코드
    response_message TEXT,                                 -- 응답 메시지
    delivery_reference VARCHAR(100),                       -- 배포 참조번호
    
    -- 비용
    estimated_cost DECIMAL(10,4) DEFAULT 0,                -- 예상 비용
    actual_cost DECIMAL(10,4) DEFAULT 0,                   -- 실제 비용
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_queue_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_queue_issuance FOREIGN KEY (issuance_id) REFERENCES bms.bill_issuances(issuance_id) ON DELETE CASCADE,
    CONSTRAINT fk_queue_channel FOREIGN KEY (channel_id) REFERENCES bms.distribution_channels(channel_id) ON DELETE CASCADE,
    CONSTRAINT fk_queue_contact FOREIGN KEY (recipient_contact_id) REFERENCES bms.recipient_contacts(contact_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_priority_level CHECK (priority_level >= 1 AND priority_level <= 10),
    CONSTRAINT chk_queue_status CHECK (queue_status IN (
        'PENDING',             -- 대기중
        'PROCESSING',          -- 처리중
        'COMPLETED',           -- 완료
        'FAILED',              -- 실패
        'CANCELLED',           -- 취소
        'EXPIRED'              -- 만료
    )),
    CONSTRAINT chk_processing_status CHECK (processing_status IN (
        'WAITING',             -- 대기중
        'SENDING',             -- 전송중
        'SENT',                -- 전송됨
        'DELIVERED',           -- 배달됨
        'FAILED',              -- 실패
        'BOUNCED',             -- 반송됨
        'EXPIRED'              -- 만료됨
    )),
    CONSTRAINT chk_delivery_result CHECK (delivery_result IN (
        'SUCCESS',             -- 성공
        'FAILED',              -- 실패
        'PARTIAL',             -- 부분 성공
        'RETRY',               -- 재시도 필요
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_attempt_counts CHECK (
        attempt_count >= 0 AND max_attempts > 0 AND attempt_count <= max_attempts
    ),
    CONSTRAINT chk_costs CHECK (estimated_cost >= 0 AND actual_cost >= 0)
);

-- 5. 배포 통계 및 로그 테이블
CREATE TABLE IF NOT EXISTS bms.distribution_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    queue_id UUID,                                         -- NULL이면 시스템 로그
    
    -- 로그 정보
    log_level VARCHAR(10) NOT NULL,                        -- 로그 레벨
    log_category VARCHAR(20) NOT NULL,                     -- 로그 분류
    log_message TEXT NOT NULL,                             -- 로그 메시지
    
    -- 컨텍스트 정보
    channel_type VARCHAR(20),                              -- 채널 유형
    recipient_info JSONB,                                  -- 수신자 정보
    processing_context JSONB,                              -- 처리 컨텍스트
    
    -- 성능 정보
    processing_time_ms INTEGER,                            -- 처리 시간 (밀리초)
    memory_usage_mb DECIMAL(10,2),                         -- 메모리 사용량 (MB)
    
    -- 오류 정보
    error_code VARCHAR(20),                                -- 오류 코드
    error_details JSONB,                                   -- 오류 상세
    stack_trace TEXT,                                      -- 스택 트레이스
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_logs_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_logs_queue FOREIGN KEY (queue_id) REFERENCES bms.distribution_queue(queue_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_log_level CHECK (log_level IN ('DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL')),
    CONSTRAINT chk_log_category CHECK (log_category IN (
        'SYSTEM',              -- 시스템
        'CHANNEL',             -- 채널
        'QUEUE',               -- 큐
        'DELIVERY',            -- 배포
        'NOTIFICATION',        -- 알림
        'ERROR',               -- 오류
        'PERFORMANCE'          -- 성능
    )),
    CONSTRAINT chk_performance_metrics CHECK (
        (processing_time_ms IS NULL OR processing_time_ms >= 0) AND
        (memory_usage_mb IS NULL OR memory_usage_mb >= 0)
    )
);

-- 6. RLS 정책 활성화
ALTER TABLE bms.distribution_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.recipient_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.recipient_contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.distribution_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.distribution_logs ENABLE ROW LEVEL SECURITY;

-- 7. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY distribution_channels_isolation_policy ON bms.distribution_channels
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY recipient_groups_isolation_policy ON bms.recipient_groups
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY recipient_contacts_isolation_policy ON bms.recipient_contacts
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY distribution_queue_isolation_policy ON bms.distribution_queue
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY distribution_logs_isolation_policy ON bms.distribution_logs
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 8. 성능 최적화 인덱스 생성
-- 배포 채널 인덱스
CREATE INDEX idx_channels_company_id ON bms.distribution_channels(company_id);
CREATE INDEX idx_channels_building_id ON bms.distribution_channels(building_id);
CREATE INDEX idx_channels_type ON bms.distribution_channels(channel_type);
CREATE INDEX idx_channels_active ON bms.distribution_channels(is_active);
CREATE INDEX idx_channels_last_used ON bms.distribution_channels(last_used_at DESC);

-- 수신자 그룹 인덱스
CREATE INDEX idx_groups_company_id ON bms.recipient_groups(company_id);
CREATE INDEX idx_groups_building_id ON bms.recipient_groups(building_id);
CREATE INDEX idx_groups_type ON bms.recipient_groups(group_type);
CREATE INDEX idx_groups_active ON bms.recipient_groups(is_active);
CREATE INDEX idx_groups_dynamic ON bms.recipient_groups(dynamic_group);

-- 수신자 연락처 인덱스
CREATE INDEX idx_contacts_company_id ON bms.recipient_contacts(company_id);
CREATE INDEX idx_contacts_unit_id ON bms.recipient_contacts(unit_id);
CREATE INDEX idx_contacts_type ON bms.recipient_contacts(contact_type);
CREATE INDEX idx_contacts_role ON bms.recipient_contacts(contact_role);
CREATE INDEX idx_contacts_active ON bms.recipient_contacts(is_active);
CREATE INDEX idx_contacts_primary ON bms.recipient_contacts(is_primary);
CREATE INDEX idx_contacts_email ON bms.recipient_contacts(email_address);
CREATE INDEX idx_contacts_phone ON bms.recipient_contacts(mobile_number);

-- 배포 큐 인덱스
CREATE INDEX idx_queue_company_id ON bms.distribution_queue(company_id);
CREATE INDEX idx_queue_issuance_id ON bms.distribution_queue(issuance_id);
CREATE INDEX idx_queue_channel_id ON bms.distribution_queue(channel_id);
CREATE INDEX idx_queue_contact_id ON bms.distribution_queue(recipient_contact_id);
CREATE INDEX idx_queue_status ON bms.distribution_queue(queue_status);
CREATE INDEX idx_queue_processing_status ON bms.distribution_queue(processing_status);
CREATE INDEX idx_queue_priority ON bms.distribution_queue(priority_level);
CREATE INDEX idx_queue_scheduled_at ON bms.distribution_queue(scheduled_at);
CREATE INDEX idx_queue_next_attempt ON bms.distribution_queue(next_attempt_at);

-- 배포 로그 인덱스
CREATE INDEX idx_logs_company_id ON bms.distribution_logs(company_id);
CREATE INDEX idx_logs_queue_id ON bms.distribution_logs(queue_id);
CREATE INDEX idx_logs_level ON bms.distribution_logs(log_level);
CREATE INDEX idx_logs_category ON bms.distribution_logs(log_category);
CREATE INDEX idx_logs_created_at ON bms.distribution_logs(created_at DESC);
CREATE INDEX idx_logs_channel_type ON bms.distribution_logs(channel_type);

-- 복합 인덱스
CREATE INDEX idx_channels_company_type_active ON bms.distribution_channels(company_id, channel_type, is_active);
CREATE INDEX idx_contacts_unit_active_primary ON bms.recipient_contacts(unit_id, is_active, is_primary);
CREATE INDEX idx_queue_status_priority_scheduled ON bms.distribution_queue(queue_status, priority_level, scheduled_at);
CREATE INDEX idx_queue_processing_next_attempt ON bms.distribution_queue(processing_status, next_attempt_at);

-- 9. updated_at 자동 업데이트 트리거
CREATE TRIGGER distribution_channels_updated_at_trigger
    BEFORE UPDATE ON bms.distribution_channels
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER recipient_groups_updated_at_trigger
    BEFORE UPDATE ON bms.recipient_groups
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER recipient_contacts_updated_at_trigger
    BEFORE UPDATE ON bms.recipient_contacts
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER distribution_queue_updated_at_trigger
    BEFORE UPDATE ON bms.distribution_queue
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 10. 배포 관리 뷰 생성
CREATE OR REPLACE VIEW bms.v_distribution_dashboard AS
SELECT 
    dc.channel_id,
    dc.company_id,
    c.company_name,
    dc.channel_name,
    dc.channel_type,
    dc.is_active,
    dc.total_sent,
    dc.total_delivered,
    dc.total_failed,
    CASE WHEN dc.total_sent > 0 THEN 
        ROUND((dc.total_delivered::DECIMAL / dc.total_sent) * 100, 2)
    ELSE 0 END as delivery_rate,
    COUNT(dq.queue_id) as pending_queue_count,
    COUNT(CASE WHEN dq.queue_status = 'PROCESSING' THEN 1 END) as processing_count,
    COUNT(CASE WHEN dq.queue_status = 'FAILED' THEN 1 END) as failed_count,
    dc.last_used_at,
    dc.created_at
FROM bms.distribution_channels dc
JOIN bms.companies c ON dc.company_id = c.company_id
LEFT JOIN bms.distribution_queue dq ON dc.channel_id = dq.channel_id
    AND dq.created_at >= CURRENT_DATE - INTERVAL '7 days'  -- 최근 7일
GROUP BY dc.channel_id, c.company_name
ORDER BY c.company_name, dc.channel_name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_distribution_dashboard OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 4.3 고지서 배포 관리 시스템 (알림톡 포함) 테이블 생성이 완료되었습니다!' as result;