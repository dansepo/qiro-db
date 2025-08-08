-- =====================================================
-- 배치 커멘트 추가 (Part 1)
-- 남은 컬럼들에 대한 한글 커멘트 추가
-- =====================================================

-- 회사 테이블 남은 컬럼들
COMMENT ON COLUMN bms.companies.created_at IS '생성 일시';
COMMENT ON COLUMN bms.companies.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.companies.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.companies.updated_by IS '수정자 사용자 ID';

-- 접근 제어 기록 테이블
COMMENT ON COLUMN bms.access_control_records.record_id IS '기록 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.access_time IS '접근 시간';
COMMENT ON COLUMN bms.access_control_records.device_id IS '장치 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.zone_id IS '구역 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.person_id IS '인물 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.person_name IS '인물명';
COMMENT ON COLUMN bms.access_control_records.person_type IS '인물 유형';
COMMENT ON COLUMN bms.access_control_records.employee_id IS '직원 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.visitor_id IS '방문자 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.access_method IS '접근 방법';
COMMENT ON COLUMN bms.access_control_records.credential_type IS '인증 유형';
COMMENT ON COLUMN bms.access_control_records.credential_id IS '인증 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.access_direction IS '접근 방향';
COMMENT ON COLUMN bms.access_control_records.purpose_of_visit IS '방문 목적';
COMMENT ON COLUMN bms.access_control_records.authorized_by IS '승인자 사용자 ID';
COMMENT ON COLUMN bms.access_control_records.escort_required IS '에스코트 필요 여부';
COMMENT ON COLUMN bms.access_control_records.escort_person_id IS '에스코트 인물 식별자 (UUID)';
COMMENT ON COLUMN bms.access_control_records.biometric_template_matched IS '생체 인식 템플릿 일치 여부';
COMMENT ON COLUMN bms.access_control_records.biometric_confidence_score IS '생체 인식 신뢰도 점수';
COMMENT ON COLUMN bms.access_control_records.photo_captured IS '사진 촬영 여부';
COMMENT ON COLUMN bms.access_control_records.photo_path IS '사진 경로';
COMMENT ON COLUMN bms.access_control_records.video_clip_path IS '비디오 클립 경로';
COMMENT ON COLUMN bms.access_control_records.anomaly_detected IS '이상 감지 여부';
COMMENT ON COLUMN bms.access_control_records.anomaly_type IS '이상 유형';
COMMENT ON COLUMN bms.access_control_records.anomaly_description IS '이상 설명';
COMMENT ON COLUMN bms.access_control_records.alert_generated IS '알림 생성 여부';
COMMENT ON COLUMN bms.access_control_records.security_notified IS '보안팀 알림 여부';
COMMENT ON COLUMN bms.access_control_records.investigation_required IS '조사 필요 여부';
COMMENT ON COLUMN bms.access_control_records.created_at IS '생성 일시';

-- 접근 로그 테이블
COMMENT ON COLUMN bms.access_logs.access_time IS '접근 시간';
COMMENT ON COLUMN bms.access_logs.access_type IS '접근 유형';
COMMENT ON COLUMN bms.access_logs.session_id IS '세션 식별자';
COMMENT ON COLUMN bms.access_logs.request_method IS '요청 방법';
COMMENT ON COLUMN bms.access_logs.request_url IS '요청 URL';
COMMENT ON COLUMN bms.access_logs.request_params IS '요청 매개변수 (JSON)';
COMMENT ON COLUMN bms.access_logs.response_status IS '응답 상태';
COMMENT ON COLUMN bms.access_logs.metadata IS '메타데이터 (JSON)';

-- 계정 코드 테이블
COMMENT ON COLUMN bms.account_codes.account_id IS '계정 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.parent_account_id IS '상위 계정 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.is_system_account IS '시스템 계정 여부';

-- 회계 항목 테이블
COMMENT ON COLUMN bms.accounting_entries.reference_document_type IS '참조 문서 유형';
COMMENT ON COLUMN bms.accounting_entries.reference_document_id IS '참조 문서 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.budget_item_id IS '예산 항목 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.approval_comment IS '승인 의견';
COMMENT ON COLUMN bms.accounting_entries.posted_by IS '게시자 사용자 ID';
COMMENT ON COLUMN bms.accounting_entries.posted_at IS '게시 일시';
COMMENT ON COLUMN bms.accounting_entries.fiscal_year IS '회계 연도';
COMMENT ON COLUMN bms.accounting_entries.fiscal_month IS '회계 월';

-- 할당 조정 이력 테이블
COMMENT ON COLUMN bms.allocation_adjustment_history.adjustment_id IS '조정 식별자 (UUID)';
COMMENT ON COLUMN bms.allocation_adjustment_history.allocation_id IS '할당 식별자 (UUID)';
COMMENT ON COLUMN bms.allocation_adjustment_history.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.allocation_adjustment_history.adjustment_type IS '조정 유형';
COMMENT ON COLUMN bms.allocation_adjustment_history.original_amount IS '원래 금액';
COMMENT ON COLUMN bms.allocation_adjustment_history.adjusted_amount IS '조정된 금액';
COMMENT ON COLUMN bms.allocation_adjustment_history.adjustment_difference IS '조정 차액';
COMMENT ON COLUMN bms.allocation_adjustment_history.adjustment_reason IS '조정 사유';
COMMENT ON COLUMN bms.allocation_adjustment_history.adjustment_description IS '조정 설명';
COMMENT ON COLUMN bms.allocation_adjustment_history.supporting_documents IS '지원 문서';
COMMENT ON COLUMN bms.allocation_adjustment_history.requested_by IS '요청자 사용자 ID';
COMMENT ON COLUMN bms.allocation_adjustment_history.approved_by IS '승인자 사용자 ID';
COMMENT ON COLUMN bms.allocation_adjustment_history.approved_at IS '승인 일시';
COMMENT ON COLUMN bms.allocation_adjustment_history.applied_at IS '적용 일시';
COMMENT ON COLUMN bms.allocation_adjustment_history.created_at IS '생성 일시';

-- 할당 기준 데이터 테이블
COMMENT ON COLUMN bms.allocation_basis_data.basis_data_id IS '기준 데이터 식별자 (UUID)';
COMMENT ON COLUMN bms.allocation_basis_data.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.allocation_basis_data.unit_id IS '세대 식별자 (UUID)';
COMMENT ON COLUMN bms.allocation_basis_data.data_type IS '데이터 유형';
COMMENT ON COLUMN bms.allocation_basis_data.data_category IS '데이터 분류';
COMMENT ON COLUMN bms.allocation_basis_data.numeric_value IS '숫자 값';
COMMENT ON COLUMN bms.allocation_basis_data.text_value IS '텍스트 값';
COMMENT ON COLUMN bms.allocation_basis_data.json_value IS 'JSON 값 (JSON)';
COMMENT ON COLUMN bms.allocation_basis_data.weight_factor IS '가중치';
COMMENT ON COLUMN bms.allocation_basis_data.effective_start_date IS '유효 시작일';
COMMENT ON COLUMN bms.allocation_basis_data.effective_end_date IS '유효 종료일';
COMMENT ON COLUMN bms.allocation_basis_data.data_source IS '데이터 소스';
COMMENT ON COLUMN bms.allocation_basis_data.last_updated_at IS '마지막 업데이트 일시';
COMMENT ON COLUMN bms.allocation_basis_data.is_active IS '활성 여부';
COMMENT ON COLUMN bms.allocation_basis_data.created_at IS '생성 일시';
COMMENT ON COLUMN bms.allocation_basis_data.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.allocation_basis_data.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.allocation_basis_data.updated_by IS '수정자 사용자 ID';