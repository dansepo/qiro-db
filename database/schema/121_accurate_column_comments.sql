-- =====================================================
-- 실제 존재하는 컬럼들에 정확한 한글 커멘트 추가
-- 테이블 구조를 확인한 후 작성된 스크립트
-- =====================================================

-- 회사 테이블 실제 컬럼 커멘트
COMMENT ON COLUMN bms.companies.created_at IS '생성 일시';
COMMENT ON COLUMN bms.companies.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.companies.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.companies.updated_by IS '수정자 사용자 ID';

-- 고장 신고 테이블 실제 컬럼 커멘트
COMMENT ON COLUMN bms.fault_reports.report_title IS '신고 제목';
COMMENT ON COLUMN bms.fault_reports.report_description IS '신고 설명';
COMMENT ON COLUMN bms.fault_reports.reporter_type IS '신고자 유형';
COMMENT ON COLUMN bms.fault_reports.reporter_unit_id IS '신고자 세대 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.anonymous_report IS '익명 신고 여부';
COMMENT ON COLUMN bms.fault_reports.fault_type IS '고장 유형';
COMMENT ON COLUMN bms.fault_reports.fault_severity IS '고장 심각도';
COMMENT ON COLUMN bms.fault_reports.fault_urgency IS '고장 긴급도';
COMMENT ON COLUMN bms.fault_reports.fault_priority IS '고장 우선순위';
COMMENT ON COLUMN bms.fault_reports.fault_location IS '고장 위치';
COMMENT ON COLUMN bms.fault_reports.affected_areas IS '영향받은 구역 (JSON)';
COMMENT ON COLUMN bms.fault_reports.environmental_conditions IS '환경 조건';
COMMENT ON COLUMN bms.fault_reports.safety_impact IS '안전 영향도';
COMMENT ON COLUMN bms.fault_reports.operational_impact IS '운영 영향도';
COMMENT ON COLUMN bms.fault_reports.resident_impact IS '거주자 영향도';
COMMENT ON COLUMN bms.fault_reports.estimated_affected_units IS '예상 영향 세대 수';
COMMENT ON COLUMN bms.fault_reports.fault_occurred_at IS '고장 발생 일시';
COMMENT ON COLUMN bms.fault_reports.first_response_due IS '최초 응답 기한';
COMMENT ON COLUMN bms.fault_reports.resolution_due IS '해결 기한';
COMMENT ON COLUMN bms.fault_reports.report_status IS '신고 상태';
COMMENT ON COLUMN bms.fault_reports.resolution_status IS '해결 상태';
COMMENT ON COLUMN bms.fault_reports.assigned_team IS '배정 팀';
COMMENT ON COLUMN bms.fault_reports.contractor_id IS '협력업체 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.escalation_level IS '에스컬레이션 레벨';
COMMENT ON COLUMN bms.fault_reports.first_response_at IS '최초 응답 일시';
COMMENT ON COLUMN bms.fault_reports.acknowledged_at IS '접수 확인 일시';
COMMENT ON COLUMN bms.fault_reports.acknowledged_by IS '접수 확인자 사용자 ID';
COMMENT ON COLUMN bms.fault_reports.work_started_at IS '작업 시작 일시';
COMMENT ON COLUMN bms.fault_reports.resolved_by IS '해결자 사용자 ID';
COMMENT ON COLUMN bms.fault_reports.resolution_method IS '해결 방법';
COMMENT ON COLUMN bms.fault_reports.resolution_description IS '해결 설명';
COMMENT ON COLUMN bms.fault_reports.estimated_repair_cost IS '예상 수리 비용';
COMMENT ON COLUMN bms.fault_reports.actual_repair_cost IS '실제 수리 비용';
COMMENT ON COLUMN bms.fault_reports.resolution_quality_rating IS '해결 품질 평가';
COMMENT ON COLUMN bms.fault_reports.reporter_satisfaction_rating IS '신고자 만족도 평가';
COMMENT ON COLUMN bms.fault_reports.initial_photos IS '초기 사진 (JSON)';
COMMENT ON COLUMN bms.fault_reports.resolution_photos IS '해결 사진 (JSON)';
COMMENT ON COLUMN bms.fault_reports.supporting_documents IS '지원 문서 (JSON)';
COMMENT ON COLUMN bms.fault_reports.communication_log IS '소통 로그 (JSON)';
COMMENT ON COLUMN bms.fault_reports.internal_notes IS '내부 메모';
COMMENT ON COLUMN bms.fault_reports.follow_up_required IS '후속 조치 필요 여부';
COMMENT ON COLUMN bms.fault_reports.follow_up_date IS '후속 조치일';
COMMENT ON COLUMN bms.fault_reports.follow_up_notes IS '후속 조치 메모';
COMMENT ON COLUMN bms.fault_reports.is_recurring_issue IS '반복 문제 여부';
COMMENT ON COLUMN bms.fault_reports.related_reports IS '관련 신고 (JSON)';
COMMENT ON COLUMN bms.fault_reports.root_cause_identified IS '근본 원인 식별 여부';

-- 자재 테이블 실제 컬럼 커멘트 (추가분)
COMMENT ON COLUMN bms.materials.quality_standards IS '품질 기준 (JSON)';
COMMENT ON COLUMN bms.materials.certifications_required IS '필요 인증 (JSON)';
COMMENT ON COLUMN bms.materials.hazardous_material IS '위험 물질 여부';
COMMENT ON COLUMN bms.materials.safety_data_sheet IS '안전 데이터 시트 (JSON)';
COMMENT ON COLUMN bms.materials.shelf_life_days IS '유통 기한 (일)';
COMMENT ON COLUMN bms.materials.expiry_tracking_required IS '만료일 추적 필요 여부';
COMMENT ON COLUMN bms.materials.batch_tracking_required IS '배치 추적 필요 여부';
COMMENT ON COLUMN bms.materials.serial_tracking_required IS '시리얼 추적 필요 여부';
COMMENT ON COLUMN bms.materials.primary_supplier_id IS '주 공급업체 식별자 (UUID)';
COMMENT ON COLUMN bms.materials.alternative_suppliers IS '대체 공급업체 (JSON)';
COMMENT ON COLUMN bms.materials.lead_time_days IS '리드 타임 (일)';
COMMENT ON COLUMN bms.materials.storage_location IS '보관 위치';
COMMENT ON COLUMN bms.materials.storage_conditions IS '보관 조건 (JSON)';
COMMENT ON COLUMN bms.materials.handling_instructions IS '취급 지침';
COMMENT ON COLUMN bms.materials.usage_category IS '사용 분류';
COMMENT ON COLUMN bms.materials.consumption_pattern IS '소비 패턴';
COMMENT ON COLUMN bms.materials.seasonal_demand IS '계절별 수요 여부';
COMMENT ON COLUMN bms.materials.asset_account IS '자산 계정';
COMMENT ON COLUMN bms.materials.expense_account IS '비용 계정';
COMMENT ON COLUMN bms.materials.cost_center IS '비용 센터';
COMMENT ON COLUMN bms.materials.material_status IS '자재 상태';
COMMENT ON COLUMN bms.materials.lifecycle_stage IS '생명주기 단계';
COMMENT ON COLUMN bms.materials.discontinuation_date IS '단종일';
COMMENT ON COLUMN bms.materials.replacement_material_id IS '대체 자재 식별자 (UUID)';
COMMENT ON COLUMN bms.materials.technical_drawings IS '기술 도면 (JSON)';
COMMENT ON COLUMN bms.materials.installation_guides IS '설치 가이드 (JSON)';
COMMENT ON COLUMN bms.materials.maintenance_instructions IS '유지보수 지침 (JSON)';
COMMENT ON COLUMN bms.materials.warranty_information IS '보증 정보 (JSON)';
COMMENT ON COLUMN bms.materials.total_consumed IS '총 소비량';
COMMENT ON COLUMN bms.materials.total_purchased IS '총 구매량';
COMMENT ON COLUMN bms.materials.average_monthly_consumption IS '월평균 소비량';
COMMENT ON COLUMN bms.materials.last_used_date IS '마지막 사용일';
COMMENT ON COLUMN bms.materials.last_purchased_date IS '마지막 구매일';

-- 공급업체 테이블 실제 컬럼 커멘트 (추가분)
COMMENT ON COLUMN bms.suppliers.supplier_code IS '공급업체 코드';
COMMENT ON COLUMN bms.suppliers.supplier_type IS '공급업체 유형';
COMMENT ON COLUMN bms.suppliers.tax_id IS '사업자 등록번호';
COMMENT ON COLUMN bms.suppliers.contact_title IS '담당자 직책';
COMMENT ON COLUMN bms.suppliers.mobile_number IS '휴대폰 번호';
COMMENT ON COLUMN bms.suppliers.address_line1 IS '주소 1';
COMMENT ON COLUMN bms.suppliers.address_line2 IS '주소 2';
COMMENT ON COLUMN bms.suppliers.city IS '도시';
COMMENT ON COLUMN bms.suppliers.state_province IS '주/도';
COMMENT ON COLUMN bms.suppliers.country IS '국가';
COMMENT ON COLUMN bms.suppliers.certifications IS '인증서 (JSON)';
COMMENT ON COLUMN bms.suppliers.iso_certified IS 'ISO 인증 여부';
COMMENT ON COLUMN bms.suppliers.payment_method IS '결제 방법';
COMMENT ON COLUMN bms.suppliers.credit_limit IS '신용 한도';
COMMENT ON COLUMN bms.suppliers.payment_days IS '결제 기간 (일)';
COMMENT ON COLUMN bms.suppliers.lead_time_days IS '리드 타임 (일)';
COMMENT ON COLUMN bms.suppliers.minimum_order_amount IS '최소 주문 금액';
COMMENT ON COLUMN bms.suppliers.delivery_area IS '배송 지역 (JSON)';
COMMENT ON COLUMN bms.suppliers.on_time_delivery_rate IS '정시 배송률';
COMMENT ON COLUMN bms.suppliers.quality_score IS '품질 점수';
COMMENT ON COLUMN bms.suppliers.total_orders IS '총 주문 수';
COMMENT ON COLUMN bms.suppliers.total_order_value IS '총 주문 금액';
COMMENT ON COLUMN bms.suppliers.contract_terms IS '계약 조건';
COMMENT ON COLUMN bms.suppliers.bank_account_number IS '은행 계좌번호';
COMMENT ON COLUMN bms.suppliers.bank_routing_number IS '은행 라우팅 번호';
COMMENT ON COLUMN bms.suppliers.approval_status IS '승인 상태';
COMMENT ON COLUMN bms.suppliers.internal_notes IS '내부 메모';