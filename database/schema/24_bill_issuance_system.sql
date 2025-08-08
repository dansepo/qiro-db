-- =====================================================
-- 고지서 발행 시스템 테이블 생성 스크립트
-- Phase 4.2: 고지서 발행 시스템
-- =====================================================

-- 1. 고지서 발행 배치 테이블
CREATE TABLE IF NOT EXISTS bms.bill_issuance_batches (
    batch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체
    
    -- 배치 기본 정보
    batch_name VARCHAR(100) NOT NULL,                      -- 배치명
    batch_description TEXT,                                -- 배치 설명
    batch_type VARCHAR(20) NOT NULL,                       -- 배치 유형
    
    -- 발행 기간 및 대상
    target_period DATE NOT NULL,                           -- 대상 기간 (YYYY-MM-01)
    target_unit_count INTEGER NOT NULL DEFAULT 0,          -- 대상 호실 수
    target_unit_types TEXT[],                              -- 대상 호실 유형
    excluded_unit_ids UUID[],                              -- 제외 호실 ID
    
    -- 템플릿 설정
    template_id UUID NOT NULL,                             -- 사용 템플릿
    output_format VARCHAR(10) DEFAULT 'PDF',               -- 출력 포맷
    
    -- 배치 상태
    batch_status VARCHAR(20) DEFAULT 'DRAFT',              -- 배치 상태
    processing_status VARCHAR(20) DEFAULT 'PENDING',       -- 처리 상태
    
    -- 처리 결과
    total_bills INTEGER DEFAULT 0,                         -- 총 고지서 수
    successful_bills INTEGER DEFAULT 0,                    -- 성공한 고지서 수
    failed_bills INTEGER DEFAULT 0,                        -- 실패한 고지서 수
    
    -- 처리 시간
    scheduled_at TIMESTAMP WITH TIME ZONE,                 -- 예약 시간
    started_at TIMESTAMP WITH TIME ZONE,                   -- 시작 시간
    completed_at TIMESTAMP WITH TIME ZONE,                 -- 완료 시간
    processing_duration_ms INTEGER,                        -- 처리 시간 (밀리초)
    
    -- 파일 정보
    output_directory TEXT,                                 -- 출력 디렉토리
    archive_path TEXT,                                     -- 아카이브 경로
    total_file_size BIGINT DEFAULT 0,                      -- 총 파일 크기
    
    -- 승인 정보
    approval_required BOOLEAN DEFAULT false,               -- 승인 필요 여부
    approved_by UUID,                                      -- 승인자
    approved_at TIMESTAMP WITH TIME ZONE,                 -- 승인 일시
    approval_notes TEXT,                                   -- 승인 메모
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_batches_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_batches_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_batches_template FOREIGN KEY (template_id) REFERENCES bms.bill_templates(template_id) ON DELETE RESTRICT,
    CONSTRAINT fk_batches_approver FOREIGN KEY (approved_by) REFERENCES bms.users(user_id) ON DELETE SET NULL,
    CONSTRAINT uk_batches_name UNIQUE (company_id, building_id, batch_name, target_period),
    
    -- 체크 제약조건
    CONSTRAINT chk_batch_type CHECK (batch_type IN (
        'REGULAR',             -- 정기 발행
        'SPECIAL',             -- 특별 발행
        'CORRECTION',          -- 정정 발행
        'REISSUE',             -- 재발행
        'TEST'                 -- 테스트 발행
    )),
    CONSTRAINT chk_batch_status CHECK (batch_status IN (
        'DRAFT',               -- 초안
        'READY',               -- 준비 완료
        'APPROVED',            -- 승인 완료
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_processing_status CHECK (processing_status IN (
        'PENDING',             -- 대기중
        'RUNNING',             -- 실행중
        'COMPLETED',           -- 완료
        'FAILED',              -- 실패
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_output_format CHECK (output_format IN ('PDF', 'HTML', 'PNG', 'JPEG', 'DOCX')),
    CONSTRAINT chk_target_unit_count CHECK (target_unit_count >= 0),
    CONSTRAINT chk_bill_counts CHECK (
        total_bills >= 0 AND successful_bills >= 0 AND failed_bills >= 0 AND
        successful_bills + failed_bills <= total_bills
    ),
    CONSTRAINT chk_processing_times CHECK (
        (started_at IS NULL OR scheduled_at IS NULL OR started_at >= scheduled_at) AND
        (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
    )
);

-- 2. 개별 고지서 발행 테이블
CREATE TABLE IF NOT EXISTS bms.bill_issuances (
    issuance_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL,
    company_id UUID NOT NULL,
    calculation_id UUID NOT NULL,
    unit_id UUID NOT NULL,
    
    -- 고지서 기본 정보
    bill_number VARCHAR(50) NOT NULL,                      -- 고지서 번호
    bill_title VARCHAR(200),                               -- 고지서 제목
    bill_period DATE NOT NULL,                             -- 고지 기간
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,         -- 발행일
    due_date DATE NOT NULL,                                -- 납부 기한
    
    -- 금액 정보
    total_amount DECIMAL(15,2) NOT NULL,                   -- 총 금액
    previous_balance DECIMAL(15,2) DEFAULT 0,              -- 전월 미납액
    late_fee DECIMAL(15,2) DEFAULT 0,                      -- 연체료
    discount_amount DECIMAL(15,2) DEFAULT 0,               -- 할인 금액
    final_amount DECIMAL(15,2) NOT NULL,                   -- 최종 금액
    
    -- 발행 상태
    issuance_status VARCHAR(20) DEFAULT 'GENERATED',       -- 발행 상태
    generation_status VARCHAR(20) DEFAULT 'PENDING',       -- 생성 상태
    
    -- 파일 정보
    file_path TEXT,                                        -- 파일 경로
    file_name VARCHAR(255),                                -- 파일명
    file_size BIGINT,                                      -- 파일 크기
    file_hash VARCHAR(64),                                 -- 파일 해시
    
    -- 생성 정보
    template_id UUID NOT NULL,                             -- 사용된 템플릿
    output_format VARCHAR(10) NOT NULL,                    -- 출력 포맷
    generation_data JSONB,                                 -- 생성 데이터
    
    -- 처리 시간
    generation_start_time TIMESTAMP WITH TIME ZONE,
    generation_end_time TIMESTAMP WITH TIME ZONE,
    generation_duration_ms INTEGER,                        -- 생성 시간 (밀리초)
    
    -- 오류 정보
    error_code VARCHAR(20),                                -- 오류 코드
    error_message TEXT,                                    -- 오류 메시지
    retry_count INTEGER DEFAULT 0,                         -- 재시도 횟수
    
    -- 배포 정보
    delivery_method VARCHAR(20),                           -- 배포 방법
    delivery_status VARCHAR(20) DEFAULT 'PENDING',         -- 배포 상태
    delivered_at TIMESTAMP WITH TIME ZONE,                -- 배포 일시
    delivery_reference VARCHAR(100),                       -- 배포 참조번호
    
    -- 수신 확인
    is_viewed BOOLEAN DEFAULT false,                       -- 열람 여부
    viewed_at TIMESTAMP WITH TIME ZONE,                   -- 열람 일시
    view_count INTEGER DEFAULT 0,                         -- 열람 횟수
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_issuances_batch FOREIGN KEY (batch_id) REFERENCES bms.bill_issuance_batches(batch_id) ON DELETE CASCADE,
    CONSTRAINT fk_issuances_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_issuances_calculation FOREIGN KEY (calculation_id) REFERENCES bms.monthly_fee_calculations(calculation_id) ON DELETE CASCADE,
    CONSTRAINT fk_issuances_unit FOREIGN KEY (unit_id) REFERENCES bms.units(unit_id) ON DELETE CASCADE,
    CONSTRAINT fk_issuances_template FOREIGN KEY (template_id) REFERENCES bms.bill_templates(template_id) ON DELETE RESTRICT,
    CONSTRAINT uk_issuances_bill_number UNIQUE (company_id, bill_number),
    CONSTRAINT uk_issuances_batch_unit UNIQUE (batch_id, unit_id),
    
    -- 체크 제약조건
    CONSTRAINT chk_issuance_status CHECK (issuance_status IN (
        'GENERATED',           -- 생성됨
        'APPROVED',            -- 승인됨
        'DELIVERED',           -- 배포됨
        'VIEWED',              -- 열람됨
        'CANCELLED'            -- 취소됨
    )),
    CONSTRAINT chk_generation_status CHECK (generation_status IN (
        'PENDING',             -- 대기중
        'PROCESSING',          -- 처리중
        'COMPLETED',           -- 완료
        'FAILED',              -- 실패
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_delivery_method CHECK (delivery_method IN (
        'EMAIL',               -- 이메일
        'SMS',                 -- SMS
        'POSTAL',              -- 우편
        'PICKUP',              -- 직접 수령
        'PORTAL',              -- 포털 게시
        'MOBILE_APP'           -- 모바일 앱
    )),
    CONSTRAINT chk_delivery_status CHECK (delivery_status IN (
        'PENDING',             -- 대기중
        'SENT',                -- 발송됨
        'DELIVERED',           -- 배달됨
        'FAILED',              -- 실패
        'BOUNCED'              -- 반송됨
    )),
    CONSTRAINT chk_amounts CHECK (
        total_amount >= 0 AND previous_balance >= 0 AND
        late_fee >= 0 AND discount_amount >= 0 AND final_amount >= 0
    ),
    CONSTRAINT chk_dates CHECK (due_date >= issue_date),
    CONSTRAINT chk_retry_count CHECK (retry_count >= 0),
    CONSTRAINT chk_view_count CHECK (view_count >= 0),
    CONSTRAINT chk_generation_times CHECK (
        generation_end_time IS NULL OR generation_start_time IS NULL OR 
        generation_end_time >= generation_start_time
    )
);

-- 3. 고지서 배포 이력 테이블
CREATE TABLE IF NOT EXISTS bms.bill_delivery_history (
    delivery_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    issuance_id UUID NOT NULL,
    company_id UUID NOT NULL,
    
    -- 배포 정보
    delivery_method VARCHAR(20) NOT NULL,                  -- 배포 방법
    delivery_target TEXT NOT NULL,                         -- 배포 대상 (이메일, 전화번호 등)
    delivery_status VARCHAR(20) NOT NULL,                  -- 배포 상태
    
    -- 배포 시도 정보
    attempt_number INTEGER NOT NULL DEFAULT 1,             -- 시도 번호
    scheduled_at TIMESTAMP WITH TIME ZONE,                 -- 예약 시간
    attempted_at TIMESTAMP WITH TIME ZONE NOT NULL,        -- 시도 시간
    completed_at TIMESTAMP WITH TIME ZONE,                 -- 완료 시간
    
    -- 배포 결과
    delivery_result VARCHAR(20) NOT NULL,                  -- 배포 결과
    response_code VARCHAR(20),                             -- 응답 코드
    response_message TEXT,                                 -- 응답 메시지
    delivery_reference VARCHAR(100),                       -- 배포 참조번호
    
    -- 배포 상세
    delivery_details JSONB,                                -- 배포 상세 정보
    
    -- 비용 정보
    delivery_cost DECIMAL(10,4) DEFAULT 0,                 -- 배포 비용
    cost_currency VARCHAR(3) DEFAULT 'KRW',                -- 통화
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 제약조건
    CONSTRAINT fk_delivery_issuance FOREIGN KEY (issuance_id) REFERENCES bms.bill_issuances(issuance_id) ON DELETE CASCADE,
    CONSTRAINT fk_delivery_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    
    -- 체크 제약조건
    CONSTRAINT chk_delivery_method_history CHECK (delivery_method IN (
        'EMAIL', 'SMS', 'POSTAL', 'PICKUP', 'PORTAL', 'MOBILE_APP'
    )),
    CONSTRAINT chk_delivery_status_history CHECK (delivery_status IN (
        'PENDING', 'SENT', 'DELIVERED', 'FAILED', 'BOUNCED'
    )),
    CONSTRAINT chk_delivery_result CHECK (delivery_result IN (
        'SUCCESS',             -- 성공
        'FAILED',              -- 실패
        'RETRY',               -- 재시도 필요
        'CANCELLED'            -- 취소
    )),
    CONSTRAINT chk_attempt_number CHECK (attempt_number > 0),
    CONSTRAINT chk_delivery_cost CHECK (delivery_cost >= 0),
    CONSTRAINT chk_delivery_times CHECK (
        completed_at IS NULL OR completed_at >= attempted_at
    )
);

-- 4. 고지서 발행 스케줄 테이블
CREATE TABLE IF NOT EXISTS bms.bill_issuance_schedules (
    schedule_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    building_id UUID,                                      -- NULL이면 회사 전체
    
    -- 스케줄 기본 정보
    schedule_name VARCHAR(100) NOT NULL,                   -- 스케줄명
    schedule_description TEXT,                             -- 스케줄 설명
    schedule_type VARCHAR(20) NOT NULL,                    -- 스케줄 유형
    
    -- 실행 설정
    cron_expression VARCHAR(100) NOT NULL,                 -- Cron 표현식
    timezone VARCHAR(50) DEFAULT 'Asia/Seoul',             -- 시간대
    
    -- 발행 설정
    template_id UUID NOT NULL,                             -- 기본 템플릿
    output_format VARCHAR(10) DEFAULT 'PDF',               -- 출력 포맷
    auto_approval BOOLEAN DEFAULT false,                   -- 자동 승인
    auto_delivery BOOLEAN DEFAULT false,                   -- 자동 배포
    
    -- 대상 설정
    target_unit_types TEXT[],                              -- 대상 호실 유형
    excluded_unit_ids UUID[],                              -- 제외 호실 ID
    
    -- 배포 설정
    delivery_methods TEXT[],                               -- 배포 방법들
    delivery_delay_hours INTEGER DEFAULT 0,                -- 배포 지연 시간
    
    -- 알림 설정
    notification_enabled BOOLEAN DEFAULT true,             -- 알림 활성화
    notification_recipients TEXT[],                        -- 알림 수신자
    notification_events TEXT[],                            -- 알림 이벤트
    
    -- 상태 및 실행 정보
    is_active BOOLEAN DEFAULT true,                        -- 활성 상태
    last_execution_at TIMESTAMP WITH TIME ZONE,            -- 마지막 실행 시간
    next_execution_at TIMESTAMP WITH TIME ZONE,            -- 다음 실행 시간
    execution_count INTEGER DEFAULT 0,                     -- 실행 횟수
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약조건
    CONSTRAINT fk_schedules_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_schedules_building FOREIGN KEY (building_id) REFERENCES bms.buildings(building_id) ON DELETE CASCADE,
    CONSTRAINT fk_schedules_template FOREIGN KEY (template_id) REFERENCES bms.bill_templates(template_id) ON DELETE RESTRICT,
    CONSTRAINT uk_schedules_name UNIQUE (company_id, building_id, schedule_name),
    
    -- 체크 제약조건
    CONSTRAINT chk_schedule_type CHECK (schedule_type IN (
        'MONTHLY',             -- 월별
        'QUARTERLY',           -- 분기별
        'ANNUAL',              -- 연간
        'CUSTOM'               -- 사용자 정의
    )),
    CONSTRAINT chk_schedule_output_format CHECK (output_format IN ('PDF', 'HTML', 'PNG', 'JPEG', 'DOCX')),
    CONSTRAINT chk_delivery_delay CHECK (delivery_delay_hours >= 0),
    CONSTRAINT chk_execution_count CHECK (execution_count >= 0)
);

-- 5. RLS 정책 활성화
ALTER TABLE bms.bill_issuance_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.bill_issuances ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.bill_delivery_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.bill_issuance_schedules ENABLE ROW LEVEL SECURITY;

-- 6. RLS 정책 생성 (멀티테넌시 격리)
CREATE POLICY bill_issuance_batches_isolation_policy ON bms.bill_issuance_batches
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY bill_issuances_isolation_policy ON bms.bill_issuances
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY bill_delivery_history_isolation_policy ON bms.bill_delivery_history
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY bill_issuance_schedules_isolation_policy ON bms.bill_issuance_schedules
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 7. 성능 최적화 인덱스 생성
-- 발행 배치 인덱스
CREATE INDEX idx_batches_company_id ON bms.bill_issuance_batches(company_id);
CREATE INDEX idx_batches_building_id ON bms.bill_issuance_batches(building_id);
CREATE INDEX idx_batches_period ON bms.bill_issuance_batches(target_period DESC);
CREATE INDEX idx_batches_status ON bms.bill_issuance_batches(batch_status);
CREATE INDEX idx_batches_processing_status ON bms.bill_issuance_batches(processing_status);
CREATE INDEX idx_batches_scheduled_at ON bms.bill_issuance_batches(scheduled_at);
CREATE INDEX idx_batches_template_id ON bms.bill_issuance_batches(template_id);

-- 개별 고지서 발행 인덱스
CREATE INDEX idx_issuances_batch_id ON bms.bill_issuances(batch_id);
CREATE INDEX idx_issuances_company_id ON bms.bill_issuances(company_id);
CREATE INDEX idx_issuances_calculation_id ON bms.bill_issuances(calculation_id);
CREATE INDEX idx_issuances_unit_id ON bms.bill_issuances(unit_id);
CREATE INDEX idx_issuances_bill_number ON bms.bill_issuances(bill_number);
CREATE INDEX idx_issuances_period ON bms.bill_issuances(bill_period DESC);
CREATE INDEX idx_issuances_issue_date ON bms.bill_issuances(issue_date DESC);
CREATE INDEX idx_issuances_due_date ON bms.bill_issuances(due_date);
CREATE INDEX idx_issuances_status ON bms.bill_issuances(issuance_status);
CREATE INDEX idx_issuances_generation_status ON bms.bill_issuances(generation_status);
CREATE INDEX idx_issuances_delivery_status ON bms.bill_issuances(delivery_status);

-- 배포 이력 인덱스
CREATE INDEX idx_delivery_issuance_id ON bms.bill_delivery_history(issuance_id);
CREATE INDEX idx_delivery_company_id ON bms.bill_delivery_history(company_id);
CREATE INDEX idx_delivery_method ON bms.bill_delivery_history(delivery_method);
CREATE INDEX idx_delivery_status_history ON bms.bill_delivery_history(delivery_status);
CREATE INDEX idx_delivery_attempted_at ON bms.bill_delivery_history(attempted_at DESC);

-- 발행 스케줄 인덱스
CREATE INDEX idx_schedules_company_id ON bms.bill_issuance_schedules(company_id);
CREATE INDEX idx_schedules_building_id ON bms.bill_issuance_schedules(building_id);
CREATE INDEX idx_schedules_active ON bms.bill_issuance_schedules(is_active);
CREATE INDEX idx_schedules_next_execution ON bms.bill_issuance_schedules(next_execution_at);
CREATE INDEX idx_schedules_template_id ON bms.bill_issuance_schedules(template_id);

-- 복합 인덱스
CREATE INDEX idx_batches_company_period ON bms.bill_issuance_batches(company_id, target_period DESC);
CREATE INDEX idx_batches_status_processing ON bms.bill_issuance_batches(batch_status, processing_status);
CREATE INDEX idx_issuances_company_period ON bms.bill_issuances(company_id, bill_period DESC);
CREATE INDEX idx_issuances_unit_period ON bms.bill_issuances(unit_id, bill_period DESC);
CREATE INDEX idx_delivery_issuance_attempt ON bms.bill_delivery_history(issuance_id, attempt_number);

-- 8. updated_at 자동 업데이트 트리거
CREATE TRIGGER bill_issuance_batches_updated_at_trigger
    BEFORE UPDATE ON bms.bill_issuance_batches
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER bill_issuances_updated_at_trigger
    BEFORE UPDATE ON bms.bill_issuances
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER bill_issuance_schedules_updated_at_trigger
    BEFORE UPDATE ON bms.bill_issuance_schedules
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 9. 고지서 발행 관리 뷰 생성
CREATE OR REPLACE VIEW bms.v_bill_issuance_summary AS
SELECT 
    bib.batch_id,
    bib.company_id,
    c.company_name,
    bib.building_id,
    b.name as building_name,
    bib.batch_name,
    bib.target_period,
    bib.batch_status,
    bib.processing_status,
    bib.total_bills,
    bib.successful_bills,
    bib.failed_bills,
    CASE WHEN bib.total_bills > 0 THEN 
        ROUND((bib.successful_bills::DECIMAL / bib.total_bills) * 100, 2)
    ELSE 0 END as success_rate,
    bt.template_name,
    bib.started_at,
    bib.completed_at,
    bib.processing_duration_ms,
    COUNT(bi.issuance_id) as issued_count,
    COUNT(CASE WHEN bi.delivery_status = 'DELIVERED' THEN 1 END) as delivered_count,
    COUNT(CASE WHEN bi.is_viewed = true THEN 1 END) as viewed_count
FROM bms.bill_issuance_batches bib
JOIN bms.companies c ON bib.company_id = c.company_id
LEFT JOIN bms.buildings b ON bib.building_id = b.building_id
LEFT JOIN bms.bill_templates bt ON bib.template_id = bt.template_id
LEFT JOIN bms.bill_issuances bi ON bib.batch_id = bi.batch_id
GROUP BY bib.batch_id, c.company_name, b.name, bt.template_name
ORDER BY bib.target_period DESC, c.company_name, b.name;

-- RLS 정책이 뷰에도 적용되도록 설정
ALTER VIEW bms.v_bill_issuance_summary OWNER TO qiro;

-- 완료 메시지
SELECT '✅ 4.2 고지서 발행 시스템 테이블 생성이 완료되었습니다!' as result;