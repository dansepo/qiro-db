-- =====================================================
-- 최종 컬럼 한글 커멘트 추가 스크립트
-- 실제 존재하는 컬럼들에만 커멘트 추가
-- =====================================================

-- 공통 컬럼 커멘트 (모든 테이블에 공통으로 있는 컬럼들)
-- 이미 추가된 테이블들은 제외하고 나머지 테이블들에 추가

-- 만족도 조사 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.satisfaction_surveys.survey_id IS '만족도 조사 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.satisfaction_surveys.complaint_id IS '민원 식별자 (UUID)';
COMMENT ON COLUMN bms.satisfaction_surveys.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.satisfaction_surveys.survey_type IS '조사 유형';
COMMENT ON COLUMN bms.satisfaction_surveys.respondent_name IS '응답자 이름';
COMMENT ON COLUMN bms.satisfaction_surveys.respondent_contact IS '응답자 연락처';
COMMENT ON COLUMN bms.satisfaction_surveys.overall_rating IS '전체 만족도 (1-5점)';
COMMENT ON COLUMN bms.satisfaction_surveys.response_time_rating IS '응답 시간 만족도';
COMMENT ON COLUMN bms.satisfaction_surveys.solution_quality_rating IS '해결 품질 만족도';
COMMENT ON COLUMN bms.satisfaction_surveys.staff_friendliness_rating IS '직원 친절도 만족도';
COMMENT ON COLUMN bms.satisfaction_surveys.additional_comments IS '추가 의견';
COMMENT ON COLUMN bms.satisfaction_surveys.survey_date IS '조사 일자';
COMMENT ON COLUMN bms.satisfaction_surveys.created_at IS '생성 일시';
COMMENT ON COLUMN bms.satisfaction_surveys.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.satisfaction_surveys.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.satisfaction_surveys.updated_by IS '수정자 사용자 ID';

-- 피드백 응답 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.feedback_responses.response_id IS '피드백 응답 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.feedback_responses.survey_id IS '만족도 조사 식별자 (UUID)';
COMMENT ON COLUMN bms.feedback_responses.question_text IS '질문 내용';
COMMENT ON COLUMN bms.feedback_responses.response_text IS '응답 내용';
COMMENT ON COLUMN bms.feedback_responses.rating_value IS '평가 점수';
COMMENT ON COLUMN bms.feedback_responses.response_type IS '응답 유형';
COMMENT ON COLUMN bms.feedback_responses.created_at IS '생성 일시';
COMMENT ON COLUMN bms.feedback_responses.updated_at IS '수정 일시';

-- 예산 계획 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.budget_plans.budget_id IS '예산 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.budget_plans.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.budget_plans.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.budget_plans.budget_year IS '예산 연도';
COMMENT ON COLUMN bms.budget_plans.budget_month IS '예산 월';
COMMENT ON COLUMN bms.budget_plans.account_code_id IS '계정과목 식별자 (UUID)';
COMMENT ON COLUMN bms.budget_plans.planned_amount IS '계획 금액';
COMMENT ON COLUMN bms.budget_plans.actual_amount IS '실제 금액';
COMMENT ON COLUMN bms.budget_plans.variance_amount IS '차이 금액';
COMMENT ON COLUMN bms.budget_plans.variance_percentage IS '차이 비율 (%)';
COMMENT ON COLUMN bms.budget_plans.notes IS '비고';
COMMENT ON COLUMN bms.budget_plans.created_at IS '생성 일시';
COMMENT ON COLUMN bms.budget_plans.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.budget_plans.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.budget_plans.updated_by IS '수정자 사용자 ID';

-- 재무 보고서 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.financial_reports.report_id IS '보고서 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.financial_reports.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.financial_reports.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.financial_reports.report_type IS '보고서 유형';
COMMENT ON COLUMN bms.financial_reports.report_period IS '보고 기간';
COMMENT ON COLUMN bms.financial_reports.start_date IS '시작 일자';
COMMENT ON COLUMN bms.financial_reports.end_date IS '종료 일자';
COMMENT ON COLUMN bms.financial_reports.total_income IS '총 수입';
COMMENT ON COLUMN bms.financial_reports.total_expense IS '총 지출';
COMMENT ON COLUMN bms.financial_reports.net_income IS '순이익';
COMMENT ON COLUMN bms.financial_reports.report_data IS '보고서 데이터 (JSON)';
COMMENT ON COLUMN bms.financial_reports.generated_at IS '생성 일시';
COMMENT ON COLUMN bms.financial_reports.generated_by IS '생성자 사용자 ID';

-- 거래 분류 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.transaction_categories.category_id IS '거래 분류 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.transaction_categories.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.transaction_categories.parent_category_id IS '상위 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.transaction_categories.category_name IS '분류명';
COMMENT ON COLUMN bms.transaction_categories.category_code IS '분류 코드';
COMMENT ON COLUMN bms.transaction_categories.description IS '분류 설명';
COMMENT ON COLUMN bms.transaction_categories.transaction_type IS '거래 유형 (INCOME, EXPENSE)';
COMMENT ON COLUMN bms.transaction_categories.is_active IS '활성 상태';
COMMENT ON COLUMN bms.transaction_categories.created_at IS '생성 일시';
COMMENT ON COLUMN bms.transaction_categories.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.transaction_categories.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.transaction_categories.updated_by IS '수정자 사용자 ID';

-- 승인 워크플로우 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.approval_workflows.workflow_id IS '워크플로우 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_workflows.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_workflows.workflow_name IS '워크플로우명';
COMMENT ON COLUMN bms.approval_workflows.description IS '워크플로우 설명';
COMMENT ON COLUMN bms.approval_workflows.workflow_type IS '워크플로우 유형';
COMMENT ON COLUMN bms.approval_workflows.min_amount IS '최소 금액';
COMMENT ON COLUMN bms.approval_workflows.max_amount IS '최대 금액';
COMMENT ON COLUMN bms.approval_workflows.approval_steps IS '승인 단계 (JSON)';
COMMENT ON COLUMN bms.approval_workflows.is_active IS '활성 상태';
COMMENT ON COLUMN bms.approval_workflows.created_at IS '생성 일시';
COMMENT ON COLUMN bms.approval_workflows.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.approval_workflows.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.approval_workflows.updated_by IS '수정자 사용자 ID';

-- 승인 요청 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.approval_requests.request_id IS '승인 요청 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_requests.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_requests.workflow_id IS '워크플로우 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_requests.entry_id IS '회계 항목 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_requests.request_title IS '승인 요청 제목';
COMMENT ON COLUMN bms.approval_requests.request_amount IS '승인 요청 금액';
COMMENT ON COLUMN bms.approval_requests.current_step IS '현재 승인 단계';
COMMENT ON COLUMN bms.approval_requests.overall_status IS '전체 승인 상태';
COMMENT ON COLUMN bms.approval_requests.requested_by IS '요청자 사용자 ID';
COMMENT ON COLUMN bms.approval_requests.requested_at IS '요청 일시';
COMMENT ON COLUMN bms.approval_requests.completed_at IS '완료 일시';
COMMENT ON COLUMN bms.approval_requests.created_at IS '생성 일시';
COMMENT ON COLUMN bms.approval_requests.updated_at IS '수정 일시';

-- 승인 이력 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.approval_history.history_id IS '승인 이력 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_history.request_id IS '승인 요청 식별자 (UUID)';
COMMENT ON COLUMN bms.approval_history.step_number IS '승인 단계 번호';
COMMENT ON COLUMN bms.approval_history.approver_id IS '승인자 사용자 ID';
COMMENT ON COLUMN bms.approval_history.approval_status IS '승인 상태';
COMMENT ON COLUMN bms.approval_history.approval_comments IS '승인 의견';
COMMENT ON COLUMN bms.approval_history.approved_at IS '승인 일시';
COMMENT ON COLUMN bms.approval_history.created_at IS '생성 일시';

-- 세무 계산 규칙 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.tax_calculation_rules.rule_id IS '규칙 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_calculation_rules.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_calculation_rules.rule_name IS '규칙명';
COMMENT ON COLUMN bms.tax_calculation_rules.tax_type IS '세금 유형';
COMMENT ON COLUMN bms.tax_calculation_rules.calculation_method IS '계산 방법';
COMMENT ON COLUMN bms.tax_calculation_rules.tax_rate IS '세율 (%)';
COMMENT ON COLUMN bms.tax_calculation_rules.effective_date IS '시행일';
COMMENT ON COLUMN bms.tax_calculation_rules.expiry_date IS '만료일';
COMMENT ON COLUMN bms.tax_calculation_rules.rule_conditions IS '규칙 조건 (JSON)';
COMMENT ON COLUMN bms.tax_calculation_rules.is_active IS '활성 상태';
COMMENT ON COLUMN bms.tax_calculation_rules.created_at IS '생성 일시';
COMMENT ON COLUMN bms.tax_calculation_rules.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.tax_calculation_rules.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.tax_calculation_rules.updated_by IS '수정자 사용자 ID';

-- 세무 신고 일정 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.tax_filing_schedule.schedule_id IS '일정 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_filing_schedule.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_filing_schedule.tax_type IS '세금 유형';
COMMENT ON COLUMN bms.tax_filing_schedule.filing_period IS '신고 기간';
COMMENT ON COLUMN bms.tax_filing_schedule.due_date IS '신고 기한';
COMMENT ON COLUMN bms.tax_filing_schedule.filing_status IS '신고 상태';
COMMENT ON COLUMN bms.tax_filing_schedule.filed_date IS '신고일';
COMMENT ON COLUMN bms.tax_filing_schedule.filed_by IS '신고자 사용자 ID';
COMMENT ON COLUMN bms.tax_filing_schedule.notes IS '비고';
COMMENT ON COLUMN bms.tax_filing_schedule.created_at IS '생성 일시';
COMMENT ON COLUMN bms.tax_filing_schedule.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.tax_filing_schedule.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.tax_filing_schedule.updated_by IS '수정자 사용자 ID';

-- 원천징수 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.withholding_tax.withholding_id IS '원천징수 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.withholding_tax.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.withholding_tax.payment_date IS '지급일';
COMMENT ON COLUMN bms.withholding_tax.payee_name IS '지급받는자 이름';
COMMENT ON COLUMN bms.withholding_tax.payee_id_number IS '지급받는자 주민번호/사업자번호';
COMMENT ON COLUMN bms.withholding_tax.income_type IS '소득 유형';
COMMENT ON COLUMN bms.withholding_tax.gross_amount IS '지급 총액';
COMMENT ON COLUMN bms.withholding_tax.tax_rate IS '원천징수율 (%)';
COMMENT ON COLUMN bms.withholding_tax.withheld_amount IS '원천징수액';
COMMENT ON COLUMN bms.withholding_tax.net_amount IS '실지급액';
COMMENT ON COLUMN bms.withholding_tax.filing_year IS '신고 연도';
COMMENT ON COLUMN bms.withholding_tax.filing_month IS '신고 월';
COMMENT ON COLUMN bms.withholding_tax.created_at IS '생성 일시';
COMMENT ON COLUMN bms.withholding_tax.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.withholding_tax.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.withholding_tax.updated_by IS '수정자 사용자 ID';

-- 세무 검증 로그 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.tax_validation_log.log_id IS '로그 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_validation_log.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_validation_log.validation_type IS '검증 유형';
COMMENT ON COLUMN bms.tax_validation_log.target_id IS '검증 대상 ID';
COMMENT ON COLUMN bms.tax_validation_log.validation_result IS '검증 결과';
COMMENT ON COLUMN bms.tax_validation_log.error_message IS '오류 메시지';
COMMENT ON COLUMN bms.tax_validation_log.validation_data IS '검증 데이터 (JSON)';
COMMENT ON COLUMN bms.tax_validation_log.validated_at IS '검증 일시';
COMMENT ON COLUMN bms.tax_validation_log.validated_by IS '검증자 사용자 ID';
COMMENT ON COLUMN bms.tax_validation_log.created_at IS '생성 일시';