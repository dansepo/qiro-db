-- =====================================================
-- 완전한 한글 커멘트 추가 스크립트
-- 1. 영어 테이블 커멘트를 한글로 변경
-- 2. 모든 테이블의 컬럼에 한글 커멘트 추가
-- =====================================================

-- 영어 테이블 커멘트를 한글로 변경
COMMENT ON TABLE bms.asset_depreciation IS '자산 감가상각 테이블 - 감가상각 계산 및 장부가액 추적';
COMMENT ON TABLE bms.asset_documents IS '자산 문서 테이블 - 시설 자산 관련 문서 관리';
COMMENT ON TABLE bms.asset_status_history IS '자산 상태 이력 테이블 - 자산 상태 변경의 완전한 감사 추적';
COMMENT ON TABLE bms.contract_modifications IS '계약 변경 테이블 - 임대차 계약의 모든 변경 및 수정 사항 추적';
COMMENT ON TABLE bms.contract_renewal_processes IS '계약 갱신 프로세스 테이블 - 계약 갱신 워크플로우 및 협상 관리';
COMMENT ON TABLE bms.contractor_blacklist IS '협력업체 블랙리스트 테이블 - 정지 또는 금지된 협력업체';
COMMENT ON TABLE bms.contractor_categories IS '협력업체 분류 테이블 - 협력업체 유형 및 전문 분야 분류';
COMMENT ON TABLE bms.contractor_certifications IS '협력업체 인증 테이블 - 품질 및 전문 인증서';
COMMENT ON TABLE bms.contractor_contracts IS '협력업체 계약 테이블 - 서비스 계약 및 협약';
COMMENT ON TABLE bms.contractor_evaluations IS '협력업체 평가 테이블 - 성과 평가 및 등급';
COMMENT ON TABLE bms.contractor_insurances IS '협력업체 보험 테이블 - 보험 적용 범위 및 정책';
COMMENT ON TABLE bms.contractor_licenses IS '협력업체 면허 테이블 - 사업 및 전문 면허';
COMMENT ON TABLE bms.contractor_performance_history IS '협력업체 성과 이력 테이블 - 과거 성과 지표';
COMMENT ON TABLE bms.contractors IS '협력업체 테이블 - 등록된 협력업체 및 서비스 제공업체';
COMMENT ON TABLE bms.dispute_cases IS '분쟁 사건 테이블 - 법적 분쟁 및 해결 프로세스 관리';
COMMENT ON TABLE bms.facility_assets IS '시설 자산 테이블 - 생애주기 관리를 포함한 완전한 자산 등록부';
COMMENT ON TABLE bms.facility_categories IS '시설 분류 테이블 - 시설 자산의 분류 시스템';
COMMENT ON TABLE bms.facility_condition_trends IS '시설 상태 트렌드 테이블 - 트렌드 분석 및 예측 유지보수 지표';
COMMENT ON TABLE bms.facility_performance_metrics IS '시설 성과 지표 테이블 - 계산된 성과 지표 및 KPI';
COMMENT ON TABLE bms.facility_status_monitoring IS '시설 상태 모니터링 테이블 - 시설 자산의 실시간 및 주기적 모니터링 데이터';
COMMENT ON TABLE bms.fault_categories IS '고장 분류 테이블 - 다양한 시설 고장 및 문제 유형의 분류 시스템';
COMMENT ON TABLE bms.fault_escalation_rules IS '고장 에스컬레이션 규칙 테이블 - 고장 관리를 위한 자동 에스컬레이션 규칙';
COMMENT ON TABLE bms.fault_report_communications IS '고장 신고 소통 테이블 - 고장 신고에 대한 소통 로그';
COMMENT ON TABLE bms.fault_report_feedback IS '고장 신고 피드백 테이블 - 고장 해결에 대한 피드백 및 만족도 추적';
COMMENT ON TABLE bms.fault_reports IS '고장 신고 테이블 - 포괄적인 고장 신고 및 추적 시스템';
COMMENT ON TABLE bms.goods_receipts IS '물품 입고 테이블 - 배송된 물품의 입고 및 검수';
COMMENT ON TABLE bms.inspection_checklist_results IS '점검 체크리스트 결과 테이블 - 각 체크리스트 항목의 상세 결과';
COMMENT ON TABLE bms.inspection_executions IS '점검 실행 테이블 - 실제 점검 활동 및 결과 기록';
COMMENT ON TABLE bms.inspection_schedules IS '점검 일정 테이블 - 시설 자산의 예정된 점검 계획';
COMMENT ON TABLE bms.inspection_templates IS '점검 템플릿 테이블 - 표준화된 점검 절차 및 체크리스트';
COMMENT ON TABLE bms.insurance_policies IS '보험 정책 테이블 - 보험 정책 관리 및 모니터링';
COMMENT ON TABLE bms.legal_compliance_requirements IS '법적 준수 요구사항 테이블 - 법적 및 규제 준수 요구사항 추적';
COMMENT ON TABLE bms.maintenance_task_executions IS '유지보수 작업 실행 테이블 - 개별 유지보수 작업의 상세 실행 기록';
COMMENT ON TABLE bms.market_analysis IS '시장 분석 테이블 - 시장 조사 및 경쟁 분석 데이터 저장';
COMMENT ON TABLE bms.marketing_campaigns IS '마케팅 캠페인 테이블 - 임대 부동산 마케팅 캠페인 관리';
COMMENT ON TABLE bms.material_categories IS '자재 분류 테이블 - 자재의 계층적 분류 시스템';
COMMENT ON TABLE bms.material_suppliers IS '자재 공급업체 테이블 - 자재와 공급업체 간의 관계';
COMMENT ON TABLE bms.material_units IS '자재 단위 테이블 - 변환 계수를 포함한 자재 측정 단위';
COMMENT ON TABLE bms.materials IS '자재 테이블 - 사양 및 재고 설정을 포함한 모든 자재의 마스터 데이터';
COMMENT ON TABLE bms.move_out_checklist_templates IS '퇴거 체크리스트 템플릿 테이블 - 건물별 퇴거 프로세스 템플릿';
COMMENT ON TABLE bms.move_out_processes IS '퇴거 프로세스 테이블 - 계약별 퇴거 프로세스 관리';
COMMENT ON TABLE bms.outsourcing_work_assignments IS '외주 작업 할당 테이블 - 협력업체에 할당된 작업';
COMMENT ON TABLE bms.outsourcing_work_requests IS '외주 작업 요청 테이블 - 외주 작업에 대한 초기 요청';
COMMENT ON TABLE bms.prevention_measures IS '예방 조치 테이블 - 근본 원인 분석 및 재발 방지를 위한 예방 조치';
COMMENT ON TABLE bms.preventive_maintenance_executions IS '예방 유지보수 실행 테이블 - 실제 수행된 예방 유지보수 작업 기록';
COMMENT ON TABLE bms.purchase_approval_workflow IS '구매 승인 워크플로우 테이블 - 승인 규칙 및 프로세스';
COMMENT ON TABLE bms.purchase_invoices IS '구매 송장 테이블 - 결제 처리를 위한 공급업체 송장';
COMMENT ON TABLE bms.purchase_orders IS '구매 주문 테이블 - 공급업체에 대한 확정 주문';
COMMENT ON TABLE bms.purchase_quotation_items IS '구매 견적 항목 테이블 - 견적서의 개별 항목';
COMMENT ON TABLE bms.purchase_quotations IS '구매 견적 테이블 - 구매 요청에 대한 공급업체 견적';
COMMENT ON TABLE bms.purchase_request_items IS '구매 요청 항목 테이블 - 구매 요청의 개별 항목';
COMMENT ON TABLE bms.purchase_requests IS '구매 요청 테이블 - 자재 또는 서비스에 대한 초기 요청';
COMMENT ON TABLE bms.risk_assessments IS '위험 평가 테이블 - 포괄적인 위험 평가 및 완화 추적';
COMMENT ON TABLE bms.safety_incidents IS '안전 사고 테이블 - 안전 사고 및 사고 보고서';
COMMENT ON TABLE bms.safety_inspection_categories IS '안전 점검 분류 테이블 - 안전 점검의 유형 및 분류';
COMMENT ON TABLE bms.safety_inspection_items IS '안전 점검 항목 테이블 - 점검 중 확인하는 개별 항목';
COMMENT ON TABLE bms.safety_inspection_schedules IS '안전 점검 일정 테이블 - 예정된 안전 점검';
COMMENT ON TABLE bms.safety_inspections IS '안전 점검 테이블 - 실제 안전 점검 기록';
COMMENT ON TABLE bms.settlement_processes IS '정산 프로세스 테이블 - 퇴거 시 주요 정산 프로세스 관리';
COMMENT ON TABLE bms.suppliers IS '공급업체 테이블 - 포괄적인 공급업체 정보 및 성과 추적';
COMMENT ON TABLE bms.unit_condition_assessments IS '세대 상태 평가 테이블 - 퇴거 시 세대 상태 평가';
COMMENT ON TABLE bms.vacancy_tracking IS '공실 추적 테이블 - 공실 세대, 사유, 비용 및 해결 추적';
COMMENT ON TABLE bms.work_completion_inspections IS '작업 완료 점검 테이블 - 완료된 작업의 품질 및 안전 점검';
COMMENT ON TABLE bms.work_completion_reports IS '작업 완료 보고서 테이블 - 기술적 세부사항을 포함한 포괄적인 완료 보고서';
COMMENT ON TABLE bms.work_cost_settlements IS '작업 비용 정산 테이블 - 완료된 작업의 비용 분석 및 재정 정산';
COMMENT ON TABLE bms.work_inspection_records IS '작업 점검 기록 테이블 - 품질 및 준수 점검';
COMMENT ON TABLE bms.work_issue_tracking IS '작업 이슈 추적 테이블 - 작업 실행 중 발생한 이슈 및 문제';
COMMENT ON TABLE bms.work_order_assignments IS '작업 지시 할당 테이블 - 기술자 및 협력업체에 대한 작업 지시 할당';
COMMENT ON TABLE bms.work_order_materials IS '작업 지시 자재 테이블 - 작업 지시의 자재 요구사항 및 사용량 추적';
COMMENT ON TABLE bms.work_order_progress IS '작업 지시 진행 테이블 - 작업 지시의 진행 추적 및 상태 업데이트';
COMMENT ON TABLE bms.work_order_templates IS '작업 지시 템플릿 테이블 - 다양한 유지보수 작업 유형의 표준화된 작업 지시 템플릿';
COMMENT ON TABLE bms.work_orders IS '작업 지시 테이블 - 수리 및 유지보수 작업의 포괄적인 작업 지시 관리';
COMMENT ON TABLE bms.work_progress_milestones IS '작업 진행 마일스톤 테이블 - 프로젝트 마일스톤 및 진행 추적';
COMMENT ON TABLE bms.work_warranties IS '작업 보증 테이블 - 완료된 작업 및 설치된 구성 요소의 보증 관리';-
- =====================================================
-- 주요 테이블 컬럼 한글 커멘트 추가
-- =====================================================

-- 시설 자산 관리 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.facility_assets.asset_id IS '시설 자산 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.category_id IS '시설 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.asset_code IS '자산 코드';
COMMENT ON COLUMN bms.facility_assets.asset_name IS '자산명';
COMMENT ON COLUMN bms.facility_assets.asset_type IS '자산 유형';
COMMENT ON COLUMN bms.facility_assets.manufacturer IS '제조사';
COMMENT ON COLUMN bms.facility_assets.model_number IS '모델 번호';
COMMENT ON COLUMN bms.facility_assets.serial_number IS '시리얼 번호';
COMMENT ON COLUMN bms.facility_assets.installation_date IS '설치일';
COMMENT ON COLUMN bms.facility_assets.warranty_start_date IS '보증 시작일';
COMMENT ON COLUMN bms.facility_assets.warranty_end_date IS '보증 종료일';
COMMENT ON COLUMN bms.facility_assets.last_maintenance_date IS '마지막 유지보수일';
COMMENT ON COLUMN bms.facility_assets.next_maintenance_date IS '다음 유지보수 예정일';
COMMENT ON COLUMN bms.facility_assets.status IS '자산 상태';
COMMENT ON COLUMN bms.facility_assets.condition_rating IS '상태 등급';
COMMENT ON COLUMN bms.facility_assets.location_details IS '위치 상세 정보';
COMMENT ON COLUMN bms.facility_assets.specifications IS '사양 정보 (JSON)';
COMMENT ON COLUMN bms.facility_assets.created_at IS '생성 일시';
COMMENT ON COLUMN bms.facility_assets.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.facility_assets.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.facility_assets.updated_by IS '수정자 사용자 ID';

-- 고장 신고 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.fault_reports.report_id IS '고장 신고 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.unit_id IS '세대 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.fault_reports.asset_id IS '시설 자산 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.fault_reports.category_id IS '고장 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.report_number IS '신고 번호';
COMMENT ON COLUMN bms.fault_reports.subject IS '신고 제목';
COMMENT ON COLUMN bms.fault_reports.description IS '고장 상세 설명';
COMMENT ON COLUMN bms.fault_reports.location IS '고장 발생 위치';
COMMENT ON COLUMN bms.fault_reports.reporter_name IS '신고자 이름';
COMMENT ON COLUMN bms.fault_reports.reporter_contact IS '신고자 연락처';
COMMENT ON COLUMN bms.fault_reports.priority_level IS '우선순위 (CRITICAL, HIGH, MEDIUM, LOW)';
COMMENT ON COLUMN bms.fault_reports.status IS '처리 상태';
COMMENT ON COLUMN bms.fault_reports.assigned_to IS '담당자 사용자 ID';
COMMENT ON COLUMN bms.fault_reports.reported_at IS '신고 일시';
COMMENT ON COLUMN bms.fault_reports.resolved_at IS '해결 완료 일시';
COMMENT ON COLUMN bms.fault_reports.resolution_notes IS '해결 내용';
COMMENT ON COLUMN bms.fault_reports.created_at IS '생성 일시';
COMMENT ON COLUMN bms.fault_reports.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.fault_reports.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.fault_reports.updated_by IS '수정자 사용자 ID';

-- 작업 지시 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.work_orders.work_order_id IS '작업 지시 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.work_orders.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.work_orders.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.work_orders.fault_report_id IS '고장 신고 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.work_orders.asset_id IS '시설 자산 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.work_orders.work_order_number IS '작업 지시 번호';
COMMENT ON COLUMN bms.work_orders.title IS '작업 제목';
COMMENT ON COLUMN bms.work_orders.description IS '작업 설명';
COMMENT ON COLUMN bms.work_orders.work_type IS '작업 유형 (REPAIR, MAINTENANCE, INSPECTION)';
COMMENT ON COLUMN bms.work_orders.priority IS '우선순위';
COMMENT ON COLUMN bms.work_orders.status IS '작업 상태';
COMMENT ON COLUMN bms.work_orders.assigned_to IS '담당자 사용자 ID';
COMMENT ON COLUMN bms.work_orders.contractor_id IS '협력업체 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.work_orders.scheduled_start_date IS '예정 시작일';
COMMENT ON COLUMN bms.work_orders.scheduled_end_date IS '예정 완료일';
COMMENT ON COLUMN bms.work_orders.actual_start_date IS '실제 시작일';
COMMENT ON COLUMN bms.work_orders.actual_end_date IS '실제 완료일';
COMMENT ON COLUMN bms.work_orders.estimated_cost IS '예상 비용';
COMMENT ON COLUMN bms.work_orders.actual_cost IS '실제 비용';
COMMENT ON COLUMN bms.work_orders.completion_notes IS '완료 메모';
COMMENT ON COLUMN bms.work_orders.created_at IS '생성 일시';
COMMENT ON COLUMN bms.work_orders.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.work_orders.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.work_orders.updated_by IS '수정자 사용자 ID';

-- 협력업체 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.contractors.contractor_id IS '협력업체 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.contractors.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.contractors.contractor_name IS '협력업체명';
COMMENT ON COLUMN bms.contractors.business_registration_number IS '사업자등록번호';
COMMENT ON COLUMN bms.contractors.representative_name IS '대표자명';
COMMENT ON COLUMN bms.contractors.contact_person IS '담당자명';
COMMENT ON COLUMN bms.contractors.phone_number IS '전화번호';
COMMENT ON COLUMN bms.contractors.email IS '이메일';
COMMENT ON COLUMN bms.contractors.address IS '주소';
COMMENT ON COLUMN bms.contractors.specialization IS '전문 분야';
COMMENT ON COLUMN bms.contractors.rating IS '평가 등급';
COMMENT ON COLUMN bms.contractors.status IS '협력업체 상태';
COMMENT ON COLUMN bms.contractors.contract_start_date IS '계약 시작일';
COMMENT ON COLUMN bms.contractors.contract_end_date IS '계약 종료일';
COMMENT ON COLUMN bms.contractors.created_at IS '등록 일시';
COMMENT ON COLUMN bms.contractors.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.contractors.created_by IS '등록자 사용자 ID';
COMMENT ON COLUMN bms.contractors.updated_by IS '수정자 사용자 ID';

-- 자재 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.materials.material_id IS '자재 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.materials.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.materials.category_id IS '자재 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.materials.material_code IS '자재 코드';
COMMENT ON COLUMN bms.materials.material_name IS '자재명';
COMMENT ON COLUMN bms.materials.description IS '자재 설명';
COMMENT ON COLUMN bms.materials.unit_of_measure IS '측정 단위';
COMMENT ON COLUMN bms.materials.unit_cost IS '단위 비용';
COMMENT ON COLUMN bms.materials.minimum_stock_level IS '최소 재고 수준';
COMMENT ON COLUMN bms.materials.maximum_stock_level IS '최대 재고 수준';
COMMENT ON COLUMN bms.materials.reorder_point IS '재주문 시점';
COMMENT ON COLUMN bms.materials.supplier_id IS '주 공급업체 식별자 (UUID)';
COMMENT ON COLUMN bms.materials.specifications IS '사양 정보 (JSON)';
COMMENT ON COLUMN bms.materials.is_active IS '활성 상태';
COMMENT ON COLUMN bms.materials.created_at IS '생성 일시';
COMMENT ON COLUMN bms.materials.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.materials.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.materials.updated_by IS '수정자 사용자 ID';

-- 점검 실행 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.inspection_executions.execution_id IS '점검 실행 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.inspection_executions.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.inspection_executions.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.inspection_executions.schedule_id IS '점검 일정 식별자 (UUID)';
COMMENT ON COLUMN bms.inspection_executions.asset_id IS '시설 자산 식별자 (UUID)';
COMMENT ON COLUMN bms.inspection_executions.inspector_id IS '점검자 사용자 ID';
COMMENT ON COLUMN bms.inspection_executions.inspection_date IS '점검 일자';
COMMENT ON COLUMN bms.inspection_executions.start_time IS '점검 시작 시간';
COMMENT ON COLUMN bms.inspection_executions.end_time IS '점검 종료 시간';
COMMENT ON COLUMN bms.inspection_executions.overall_status IS '전체 점검 상태';
COMMENT ON COLUMN bms.inspection_executions.overall_rating IS '전체 점검 등급';
COMMENT ON COLUMN bms.inspection_executions.findings_summary IS '발견사항 요약';
COMMENT ON COLUMN bms.inspection_executions.recommendations IS '권고사항';
COMMENT ON COLUMN bms.inspection_executions.next_inspection_date IS '다음 점검 예정일';
COMMENT ON COLUMN bms.inspection_executions.created_at IS '생성 일시';
COMMENT ON COLUMN bms.inspection_executions.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.inspection_executions.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.inspection_executions.updated_by IS '수정자 사용자 ID';

-- 임대차 계약 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.lease_contracts.contract_id IS '계약 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.lease_contracts.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.lease_contracts.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.lease_contracts.unit_id IS '세대 식별자 (UUID)';
COMMENT ON COLUMN bms.lease_contracts.contract_number IS '계약 번호';
COMMENT ON COLUMN bms.lease_contracts.contract_type IS '계약 유형 (LEASE, RENT)';
COMMENT ON COLUMN bms.lease_contracts.contract_status IS '계약 상태';
COMMENT ON COLUMN bms.lease_contracts.start_date IS '계약 시작일';
COMMENT ON COLUMN bms.lease_contracts.end_date IS '계약 종료일';
COMMENT ON COLUMN bms.lease_contracts.monthly_rent IS '월 임대료';
COMMENT ON COLUMN bms.lease_contracts.deposit_amount IS '보증금';
COMMENT ON COLUMN bms.lease_contracts.maintenance_fee IS '관리비';
COMMENT ON COLUMN bms.lease_contracts.rent_due_date IS '임대료 납부일';
COMMENT ON COLUMN bms.lease_contracts.auto_renewal IS '자동 갱신 여부';
COMMENT ON COLUMN bms.lease_contracts.renewal_notice_period IS '갱신 통지 기간 (일)';
COMMENT ON COLUMN bms.lease_contracts.special_terms IS '특약 사항';
COMMENT ON COLUMN bms.lease_contracts.created_at IS '생성 일시';
COMMENT ON COLUMN bms.lease_contracts.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.lease_contracts.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.lease_contracts.updated_by IS '수정자 사용자 ID';

-- 계약 당사자 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.contract_parties.party_id IS '당사자 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.contract_parties.contract_id IS '계약 식별자 (UUID)';
COMMENT ON COLUMN bms.contract_parties.party_type IS '당사자 유형 (LESSOR, LESSEE, GUARANTOR, AGENT)';
COMMENT ON COLUMN bms.contract_parties.party_name IS '당사자명';
COMMENT ON COLUMN bms.contract_parties.id_number IS '주민등록번호/사업자등록번호';
COMMENT ON COLUMN bms.contract_parties.phone_number IS '전화번호';
COMMENT ON COLUMN bms.contract_parties.email IS '이메일';
COMMENT ON COLUMN bms.contract_parties.address IS '주소';
COMMENT ON COLUMN bms.contract_parties.emergency_contact IS '비상 연락처';
COMMENT ON COLUMN bms.contract_parties.is_primary IS '주 당사자 여부';
COMMENT ON COLUMN bms.contract_parties.created_at IS '생성 일시';
COMMENT ON COLUMN bms.contract_parties.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.contract_parties.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.contract_parties.updated_by IS '수정자 사용자 ID';-- 
민원 관리 테이블 컬럼 커멘트 (실제 존재하는 컬럼들만)
COMMENT ON COLUMN bms.complaints.complaint_id IS '민원 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.complaints.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.complaints.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.complaints.unit_id IS '세대 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.complaints.complaint_number IS '민원 번호';
COMMENT ON COLUMN bms.complaints.subject IS '민원 제목';
COMMENT ON COLUMN bms.complaints.content IS '민원 내용';
COMMENT ON COLUMN bms.complaints.complainant_name IS '민원인 이름';
COMMENT ON COLUMN bms.complaints.complainant_contact IS '민원인 연락처';
COMMENT ON COLUMN bms.complaints.complaint_type IS '민원 유형';
COMMENT ON COLUMN bms.complaints.priority_level IS '우선순위';
COMMENT ON COLUMN bms.complaints.status IS '처리 상태';
COMMENT ON COLUMN bms.complaints.assigned_to IS '담당자 사용자 ID';
COMMENT ON COLUMN bms.complaints.due_date IS '처리 기한';
COMMENT ON COLUMN bms.complaints.resolved_at IS '해결 완료 일시';
COMMENT ON COLUMN bms.complaints.resolution_details IS '해결 내용';
COMMENT ON COLUMN bms.complaints.satisfaction_rating IS '만족도 평가';
COMMENT ON COLUMN bms.complaints.created_at IS '접수 일시';
COMMENT ON COLUMN bms.complaints.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.complaints.created_by IS '접수자 사용자 ID';
COMMENT ON COLUMN bms.complaints.updated_by IS '수정자 사용자 ID';

-- 민원 분류 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.complaint_categories.category_id IS '분류 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_categories.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_categories.parent_category_id IS '상위 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_categories.category_name IS '분류명';
COMMENT ON COLUMN bms.complaint_categories.category_code IS '분류 코드';
COMMENT ON COLUMN bms.complaint_categories.description IS '분류 설명';
COMMENT ON COLUMN bms.complaint_categories.default_priority IS '기본 우선순위';
COMMENT ON COLUMN bms.complaint_categories.is_active IS '활성 상태';
COMMENT ON COLUMN bms.complaint_categories.created_at IS '생성 일시';
COMMENT ON COLUMN bms.complaint_categories.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.complaint_categories.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.complaint_categories.updated_by IS '수정자 사용자 ID';

-- 회계 항목 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.accounting_entries.entry_id IS '회계 항목 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.account_code_id IS '계정과목 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.entry_date IS '거래 일자';
COMMENT ON COLUMN bms.accounting_entries.description IS '거래 설명';
COMMENT ON COLUMN bms.accounting_entries.debit_amount IS '차변 금액';
COMMENT ON COLUMN bms.accounting_entries.credit_amount IS '대변 금액';
COMMENT ON COLUMN bms.accounting_entries.entry_type IS '항목 유형';
COMMENT ON COLUMN bms.accounting_entries.reference_number IS '참조 번호';
COMMENT ON COLUMN bms.accounting_entries.approval_status IS '승인 상태';
COMMENT ON COLUMN bms.accounting_entries.approved_by IS '승인자 사용자 ID';
COMMENT ON COLUMN bms.accounting_entries.approved_at IS '승인 일시';
COMMENT ON COLUMN bms.accounting_entries.created_at IS '생성 일시';
COMMENT ON COLUMN bms.accounting_entries.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.accounting_entries.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.accounting_entries.updated_by IS '수정자 사용자 ID';

-- 계정과목 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.account_codes.code_id IS '계정과목 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.parent_code_id IS '상위 계정과목 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.account_code IS '계정과목 코드';
COMMENT ON COLUMN bms.account_codes.account_name IS '계정과목명';
COMMENT ON COLUMN bms.account_codes.description IS '계정과목 설명';
COMMENT ON COLUMN bms.account_codes.account_type IS '계정 유형';
COMMENT ON COLUMN bms.account_codes.account_level IS '계정 레벨';
COMMENT ON COLUMN bms.account_codes.is_active IS '활성 상태';
COMMENT ON COLUMN bms.account_codes.created_at IS '생성 일시';
COMMENT ON COLUMN bms.account_codes.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.account_codes.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.account_codes.updated_by IS '수정자 사용자 ID';

-- 세무 거래 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.tax_transactions.transaction_id IS '세무 거래 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_transactions.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_transactions.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.tax_transactions.transaction_date IS '거래 일자';
COMMENT ON COLUMN bms.tax_transactions.transaction_type IS '거래 유형';
COMMENT ON COLUMN bms.tax_transactions.amount IS '거래 금액';
COMMENT ON COLUMN bms.tax_transactions.vat_amount IS '부가세 금액';
COMMENT ON COLUMN bms.tax_transactions.tax_rate IS '세율';
COMMENT ON COLUMN bms.tax_transactions.description IS '거래 설명';
COMMENT ON COLUMN bms.tax_transactions.tax_invoice_number IS '세금계산서 번호';
COMMENT ON COLUMN bms.tax_transactions.counterpart_name IS '거래처명';
COMMENT ON COLUMN bms.tax_transactions.counterpart_business_number IS '거래처 사업자번호';
COMMENT ON COLUMN bms.tax_transactions.created_at IS '생성 일시';
COMMENT ON COLUMN bms.tax_transactions.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.tax_transactions.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.tax_transactions.updated_by IS '수정자 사용자 ID';

-- 부가세 신고 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.vat_returns.return_id IS '부가세 신고 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.vat_returns.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.vat_returns.return_period IS '신고 기간';
COMMENT ON COLUMN bms.vat_returns.return_year IS '신고 연도';
COMMENT ON COLUMN bms.vat_returns.return_month IS '신고 월';
COMMENT ON COLUMN bms.vat_returns.total_sales IS '총 매출액';
COMMENT ON COLUMN bms.vat_returns.total_purchases IS '총 매입액';
COMMENT ON COLUMN bms.vat_returns.output_vat IS '매출 부가세';
COMMENT ON COLUMN bms.vat_returns.input_vat IS '매입 부가세';
COMMENT ON COLUMN bms.vat_returns.payable_vat IS '납부할 부가세';
COMMENT ON COLUMN bms.vat_returns.refundable_vat IS '환급받을 부가세';
COMMENT ON COLUMN bms.vat_returns.filing_status IS '신고 상태';
COMMENT ON COLUMN bms.vat_returns.filed_date IS '신고일';
COMMENT ON COLUMN bms.vat_returns.due_date IS '납부 기한';
COMMENT ON COLUMN bms.vat_returns.created_at IS '생성 일시';
COMMENT ON COLUMN bms.vat_returns.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.vat_returns.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.vat_returns.updated_by IS '수정자 사용자 ID';

-- 직원 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.employees.employee_id IS '직원 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.employees.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.employees.building_id IS '근무 건물 식별자 (UUID)';
COMMENT ON COLUMN bms.employees.user_id IS '사용자 계정 식별자 (UUID)';
COMMENT ON COLUMN bms.employees.employee_number IS '직원 번호';
COMMENT ON COLUMN bms.employees.name IS '직원명';
COMMENT ON COLUMN bms.employees.position IS '직책';
COMMENT ON COLUMN bms.employees.department IS '부서';
COMMENT ON COLUMN bms.employees.phone_number IS '전화번호';
COMMENT ON COLUMN bms.employees.email IS '이메일';
COMMENT ON COLUMN bms.employees.hire_date IS '입사일';
COMMENT ON COLUMN bms.employees.employment_status IS '재직 상태';
COMMENT ON COLUMN bms.employees.salary IS '급여';
COMMENT ON COLUMN bms.employees.work_schedule IS '근무 일정';
COMMENT ON COLUMN bms.employees.emergency_contact IS '비상 연락처';
COMMENT ON COLUMN bms.employees.notes IS '비고';
COMMENT ON COLUMN bms.employees.created_at IS '생성 일시';
COMMENT ON COLUMN bms.employees.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.employees.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.employees.updated_by IS '수정자 사용자 ID';

-- 서비스 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.services.service_id IS '서비스 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.services.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.services.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.services.service_name IS '서비스명';
COMMENT ON COLUMN bms.services.description IS '서비스 설명';
COMMENT ON COLUMN bms.services.service_type IS '서비스 유형';
COMMENT ON COLUMN bms.services.provider IS '서비스 제공자';
COMMENT ON COLUMN bms.services.cost IS '서비스 비용';
COMMENT ON COLUMN bms.services.duration_minutes IS '소요 시간 (분)';
COMMENT ON COLUMN bms.services.availability_schedule IS '이용 가능 시간';
COMMENT ON COLUMN bms.services.max_capacity IS '최대 수용 인원';
COMMENT ON COLUMN bms.services.booking_required IS '예약 필요 여부';
COMMENT ON COLUMN bms.services.advance_booking_hours IS '사전 예약 시간';
COMMENT ON COLUMN bms.services.is_active IS '활성 상태';
COMMENT ON COLUMN bms.services.created_at IS '생성 일시';
COMMENT ON COLUMN bms.services.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.services.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.services.updated_by IS '수정자 사용자 ID';