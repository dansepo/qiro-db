-- =====================================================
-- 한글 커멘트 추가 스크립트
-- 모든 테이블과 컬럼에 한글 설명 추가
-- =====================================================

-- 테이블 커멘트 추가 (커멘트가 없는 테이블들)
COMMENT ON TABLE bms.allocation_adjustment_history IS '사용량 배분 조정 이력 테이블 - 사용량 배분 조정 내역 관리';
COMMENT ON TABLE bms.allocation_basis_data IS '사용량 배분 기준 데이터 테이블 - 배분 계산을 위한 기준 데이터';
COMMENT ON TABLE bms.anomaly_detection_configs IS '이상 감지 설정 테이블 - 시설 이상 감지를 위한 설정 관리';
COMMENT ON TABLE bms.audit_log_config IS '감사 로그 설정 테이블 - 감사 로그 수집 정책 설정';
COMMENT ON TABLE bms.audit_logs IS '감사 로그 테이블 - 시스템 감사 추적을 위한 로그 기록';
COMMENT ON TABLE bms.auto_debit_settings IS '자동이체 설정 테이블 - 관리비 자동이체 설정 관리';
COMMENT ON TABLE bms.bill_delivery_history IS '청구서 발송 이력 테이블 - 청구서 발송 결과 및 이력 관리';
COMMENT ON TABLE bms.bill_import_configurations IS '청구서 가져오기 설정 테이블 - 외부 청구서 가져오기 설정';
COMMENT ON TABLE bms.bill_issuance_batches IS '청구서 발행 배치 테이블 - 청구서 일괄 발행 작업 관리';
COMMENT ON TABLE bms.bill_issuance_schedules IS '청구서 발행 일정 테이블 - 청구서 발행 스케줄 관리';
COMMENT ON TABLE bms.bill_issuances IS '청구서 발행 테이블 - 청구서 발행 내역 관리';
COMMENT ON TABLE bms.bill_mapping_rules IS '청구서 매핑 규칙 테이블 - 외부 청구서 데이터 매핑 규칙';
COMMENT ON TABLE bms.bill_processing_history IS '청구서 처리 이력 테이블 - 청구서 처리 과정 이력 관리';
COMMENT ON TABLE bms.bill_templates IS '청구서 템플릿 테이블 - 청구서 양식 및 템플릿 관리';
COMMENT ON TABLE bms.building_fee_item_settings IS '건물별 관리비 항목 설정 테이블 - 건물별 관리비 항목 개별 설정';
COMMENT ON TABLE bms.building_group_assignments IS '건물 그룹 할당 테이블 - 건물의 그룹 소속 관리';
COMMENT ON TABLE bms.code_groups IS '코드 그룹 테이블 - 공통 코드의 그룹 분류 관리';
COMMENT ON TABLE bms.common_facilities IS '공용 시설 테이블 - 건물 내 공용 시설 정보 관리';
COMMENT ON TABLE bms.deposit_management IS '보증금 관리 테이블 - 임대차 보증금 관리';
COMMENT ON TABLE bms.deposit_receipts IS '보증금 수령 테이블 - 보증금 수령 내역 관리';
COMMENT ON TABLE bms.deposit_refunds IS '보증금 환불 테이블 - 보증금 환불 처리 관리';
COMMENT ON TABLE bms.distribution_channels IS '배포 채널 테이블 - 청구서 및 공지사항 배포 채널 관리';
COMMENT ON TABLE bms.distribution_logs IS '배포 로그 테이블 - 배포 결과 및 이력 기록';
COMMENT ON TABLE bms.distribution_queue IS '배포 대기열 테이블 - 배포 대기 중인 항목 관리';
COMMENT ON TABLE bms.email_verification_tokens IS '이메일 인증 토큰 테이블 - 이메일 인증을 위한 토큰 관리';
COMMENT ON TABLE bms.email_verification_tokens_current IS '현재 이메일 인증 토큰 테이블 - 활성 이메일 인증 토큰';
COMMENT ON TABLE bms.external_bills IS '외부 청구서 테이블 - 외부에서 가져온 청구서 데이터';
COMMENT ON TABLE bms.external_suppliers IS '외부 공급업체 테이블 - 외부 서비스 공급업체 정보';
COMMENT ON TABLE bms.facility_alerts IS '시설 알림 테이블 - 시설 관련 알림 및 경고 관리';
COMMENT ON TABLE bms.facility_orientations IS '시설 방향 테이블 - 시설의 방향 정보 관리';
COMMENT ON TABLE bms.fee_adjustment_history IS '관리비 조정 이력 테이블 - 관리비 조정 내역 관리';
COMMENT ON TABLE bms.fee_calculation_logs IS '관리비 계산 로그 테이블 - 관리비 계산 과정 로그';
COMMENT ON TABLE bms.fee_item_categories IS '관리비 항목 분류 테이블 - 관리비 항목의 분류 체계';
COMMENT ON TABLE bms.fee_item_price_history IS '관리비 항목 가격 이력 테이블 - 관리비 항목별 가격 변동 이력';
COMMENT ON TABLE bms.fee_item_rates IS '관리비 항목 요율 테이블 - 관리비 항목별 요율 정보';
COMMENT ON TABLE bms.fee_items IS '관리비 항목 테이블 - 관리비 구성 항목 정의';
COMMENT ON TABLE bms.fee_policy_change_history IS '관리비 정책 변경 이력 테이블 - 관리비 정책 변경 내역';
COMMENT ON TABLE bms.fee_policy_templates IS '관리비 정책 템플릿 테이블 - 관리비 정책 템플릿 관리';
COMMENT ON TABLE bms.fee_rate_change_history IS '관리비 요율 변경 이력 테이블 - 관리비 요율 변경 내역';
COMMENT ON TABLE bms.fee_rate_systems IS '관리비 요율 시스템 테이블 - 관리비 요율 체계 관리';
COMMENT ON TABLE bms.fee_seasonal_rates IS '관리비 계절별 요율 테이블 - 계절별 차등 요율 관리';
COMMENT ON TABLE bms.fee_tier_rates IS '관리비 구간별 요율 테이블 - 사용량 구간별 차등 요율';
COMMENT ON TABLE bms.fee_time_rates IS '관리비 시간대별 요율 테이블 - 시간대별 차등 요율';
COMMENT ON TABLE bms.inspection_corrective_actions IS '점검 시정조치 테이블 - 점검 결과에 따른 시정조치 관리';
COMMENT ON TABLE bms.inspection_findings IS '점검 발견사항 테이블 - 점검 중 발견된 문제점 관리';
COMMENT ON TABLE bms.inventory_balances IS '재고 잔량 테이블 - 자재별 현재 재고 수량 관리';
COMMENT ON TABLE bms.inventory_locations IS '재고 위치 테이블 - 재고 보관 위치 정보 관리';
COMMENT ON TABLE bms.inventory_transactions IS '재고 거래 테이블 - 재고 입출고 거래 내역';
COMMENT ON TABLE bms.lessor_building_assignments IS '임대인 건물 할당 테이블 - 임대인별 관리 건물 할당';
COMMENT ON TABLE bms.lessors IS '임대인 테이블 - 임대인 정보 관리';
COMMENT ON TABLE bms.maintenance_effectiveness_analysis IS '유지보수 효과 분석 테이블 - 유지보수 효과성 분석 결과';
COMMENT ON TABLE bms.maintenance_fee_items IS '관리비 항목 테이블 - 관리비 구성 항목 정의';
COMMENT ON TABLE bms.maintenance_fee_policies IS '관리비 정책 테이블 - 관리비 정책 및 규칙 정의';
COMMENT ON TABLE bms.maintenance_optimization_recommendations IS '유지보수 최적화 권고 테이블 - 유지보수 최적화 제안사항';
COMMENT ON TABLE bms.maintenance_plans IS '유지보수 계획 테이블 - 예방 유지보수 계획 관리';
COMMENT ON TABLE bms.maintenance_tasks IS '유지보수 작업 테이블 - 개별 유지보수 작업 정의';
COMMENT ON TABLE bms.meter_reading_schedules IS '검침 일정 테이블 - 검침 스케줄 관리';
COMMENT ON TABLE bms.meter_reading_tasks IS '검침 작업 테이블 - 개별 검침 작업 관리';
COMMENT ON TABLE bms.meter_readings IS '검침 데이터 테이블 - 계량기 검침 결과 저장';
COMMENT ON TABLE bms.meters IS '계량기 테이블 - 전기, 수도, 가스 계량기 정보';
COMMENT ON TABLE bms.monthly_fee_calculations IS '월별 관리비 계산 테이블 - 월별 관리비 계산 결과';
COMMENT ON TABLE bms.move_in_checklist_items IS '입주 체크리스트 항목 테이블 - 입주 시 확인 항목 관리';
COMMENT ON TABLE bms.move_out_checklist_items IS '퇴거 체크리스트 항목 테이블 - 퇴거 시 확인 항목 관리';
COMMENT ON TABLE bms.notification_settings IS '알림 설정 테이블 - 사용자별 알림 설정 관리';
COMMENT ON TABLE bms.payment_methods IS '결제 수단 테이블 - 사용 가능한 결제 수단 정의';
COMMENT ON TABLE bms.payment_reconciliation IS '결제 대사 테이블 - 결제 내역 대사 및 정합성 확인';
COMMENT ON TABLE bms.payment_transactions IS '결제 거래 테이블 - 모든 결제 거래 내역 관리';
COMMENT ON TABLE bms.phone_verification_tokens IS '전화번호 인증 토큰 테이블 - 전화번호 인증용 토큰 관리';
COMMENT ON TABLE bms.phone_verification_tokens_current IS '현재 전화번호 인증 토큰 테이블 - 활성 전화번호 인증 토큰';
COMMENT ON TABLE bms.prospect_inquiries IS '임대 문의 테이블 - 임대 희망자 문의 내역 관리';
COMMENT ON TABLE bms.recipient_contacts IS '수신자 연락처 테이블 - 알림 수신자 연락처 정보';
COMMENT ON TABLE bms.recipient_groups IS '수신자 그룹 테이블 - 알림 수신자 그룹 관리';
COMMENT ON TABLE bms.rent_adjustment_policies IS '임대료 조정 정책 테이블 - 임대료 조정 규칙 및 정책';
COMMENT ON TABLE bms.rental_fee_charges IS '임대료 청구 테이블 - 임대료 청구 내역 관리';
COMMENT ON TABLE bms.rental_fee_payments IS '임대료 납부 테이블 - 임대료 납부 내역 관리';
COMMENT ON TABLE bms.rental_fee_policies IS '임대료 정책 테이블 - 임대료 정책 및 규칙 정의';
COMMENT ON TABLE bms.security_event_logs IS '보안 이벤트 로그 테이블 - 보안 관련 이벤트 기록';
COMMENT ON TABLE bms.sensitive_audit_logs IS '민감정보 감사 로그 테이블 - 민감정보 접근 및 처리 로그';
COMMENT ON TABLE bms.settlement_disputes IS '정산 분쟁 테이블 - 정산 관련 분쟁 사항 관리';
COMMENT ON TABLE bms.settlement_line_items IS '정산 항목 테이블 - 정산 세부 항목 관리';
COMMENT ON TABLE bms.settlement_payments IS '정산 지급 테이블 - 정산 지급 내역 관리';
COMMENT ON TABLE bms.storage_locations IS '보관 위치 테이블 - 자재 및 장비 보관 위치 정보';
COMMENT ON TABLE bms.system_setting_history IS '시스템 설정 이력 테이블 - 시스템 설정 변경 이력';
COMMENT ON TABLE bms.template_fields IS '템플릿 필드 테이블 - 템플릿 구성 필드 정의';
COMMENT ON TABLE bms.template_sections IS '템플릿 섹션 테이블 - 템플릿 섹션 구성 정의';
COMMENT ON TABLE bms.template_usage_history IS '템플릿 사용 이력 테이블 - 템플릿 사용 내역 추적';
COMMENT ON TABLE bms.tenants IS '임차인 테이블 - 임차인 정보 관리';
COMMENT ON TABLE bms.unit_fee_policy_overrides IS '세대별 관리비 정책 예외 테이블 - 세대별 관리비 정책 예외 설정';
COMMENT ON TABLE bms.unit_monthly_fees IS '세대별 월 관리비 테이블 - 세대별 월별 관리비 내역';
COMMENT ON TABLE bms.unit_restoration_works IS '세대 원상복구 작업 테이블 - 퇴거 시 원상복구 작업 관리';
COMMENT ON TABLE bms.usage_allocation_rules IS '사용량 배분 규칙 테이블 - 공용 사용량 배분 규칙 정의';
COMMENT ON TABLE bms.usage_allocations IS '사용량 배분 테이블 - 세대별 사용량 배분 결과';
COMMENT ON TABLE bms.user_activity_logs IS '사용자 활동 로그 테이블 - 사용자 활동 내역 기록';
COMMENT ON TABLE bms.user_group_assignments IS '사용자 그룹 할당 테이블 - 사용자의 그룹 소속 관리';
COMMENT ON TABLE bms.user_role_links IS '사용자 역할 연결 테이블 - 사용자와 역할의 연결 관리';
COMMENT ON TABLE bms.user_sessions IS '사용자 세션 테이블 - 사용자 로그인 세션 관리';
COMMENT ON TABLE bms.utility_providers IS '공급업체 테이블 - 전기, 수도, 가스 등 공급업체 정보';
COMMENT ON TABLE bms.validation_execution_history IS '검증 실행 이력 테이블 - 데이터 검증 실행 내역';
COMMENT ON TABLE bms.validation_results IS '검증 결과 테이블 - 데이터 검증 결과 저장';
COMMENT ON TABLE bms.validation_rules IS '검증 규칙 테이블 - 데이터 검증 규칙 정의';
--
 =====================================================
-- 주요 테이블 컬럼 커멘트 추가
-- =====================================================

-- users 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.users.user_id IS '사용자 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.users.company_id IS '소속 회사 식별자 (UUID)';
COMMENT ON COLUMN bms.users.email IS '사용자 이메일 주소 (로그인 ID)';
COMMENT ON COLUMN bms.users.password_hash IS '암호화된 비밀번호 해시';
COMMENT ON COLUMN bms.users.full_name IS '사용자 실명';
COMMENT ON COLUMN bms.users.phone_number IS '연락처 전화번호';
COMMENT ON COLUMN bms.users.user_type IS '사용자 유형 - SUPER_ADMIN(슈퍼관리자), ADMIN(관리자), EMPLOYEE(직원), USER(일반사용자)';
COMMENT ON COLUMN bms.users.status IS '사용자 상태 - ACTIVE(활성), INACTIVE(비활성), SUSPENDED(정지)';
COMMENT ON COLUMN bms.users.email_verified IS '이메일 인증 완료 여부';
COMMENT ON COLUMN bms.users.email_verified_at IS '이메일 인증 완료 일시';
COMMENT ON COLUMN bms.users.last_login_at IS '마지막 로그인 일시';
COMMENT ON COLUMN bms.users.last_login_ip IS '마지막 로그인 IP 주소';
COMMENT ON COLUMN bms.users.password_changed_at IS '비밀번호 마지막 변경 일시';
COMMENT ON COLUMN bms.users.failed_login_attempts IS '로그인 실패 횟수';
COMMENT ON COLUMN bms.users.locked_until IS '계정 잠금 해제 일시';
COMMENT ON COLUMN bms.users.created_at IS '생성 일시';
COMMENT ON COLUMN bms.users.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.users.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.users.updated_by IS '수정자 사용자 ID';

-- buildings 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.buildings.building_id IS '건물 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.buildings.company_id IS '관리 회사 식별자 (UUID)';
COMMENT ON COLUMN bms.buildings.name IS '건물명';
COMMENT ON COLUMN bms.buildings.address IS '건물 주소';
COMMENT ON COLUMN bms.buildings.address_detail IS '상세 주소';
COMMENT ON COLUMN bms.buildings.postal_code IS '우편번호';
COMMENT ON COLUMN bms.buildings.building_type IS '건물 유형 (아파트, 오피스텔, 상가 등)';
COMMENT ON COLUMN bms.buildings.total_floors IS '지상 층수';
COMMENT ON COLUMN bms.buildings.basement_floors IS '지하 층수';
COMMENT ON COLUMN bms.buildings.total_area IS '총 면적 (㎡)';
COMMENT ON COLUMN bms.buildings.total_units IS '총 세대수';
COMMENT ON COLUMN bms.buildings.construction_date IS '준공일';
COMMENT ON COLUMN bms.buildings.building_status IS '건물 상태 (신축, 기존, 리모델링 등)';
COMMENT ON COLUMN bms.buildings.management_office_name IS '관리사무소명';
COMMENT ON COLUMN bms.buildings.management_office_phone IS '관리사무소 전화번호';
COMMENT ON COLUMN bms.buildings.manager_name IS '관리소장 이름';
COMMENT ON COLUMN bms.buildings.manager_phone IS '관리소장 전화번호';
COMMENT ON COLUMN bms.buildings.manager_email IS '관리소장 이메일';
COMMENT ON COLUMN bms.buildings.has_elevator IS '엘리베이터 보유 여부';
COMMENT ON COLUMN bms.buildings.elevator_count IS '엘리베이터 대수';
COMMENT ON COLUMN bms.buildings.has_parking IS '주차장 보유 여부';
COMMENT ON COLUMN bms.buildings.parking_spaces IS '주차 가능 대수';
COMMENT ON COLUMN bms.buildings.has_security IS '보안 시설 보유 여부';
COMMENT ON COLUMN bms.buildings.security_system IS '보안 시스템 종류';
COMMENT ON COLUMN bms.buildings.heating_system IS '난방 시스템 종류';
COMMENT ON COLUMN bms.buildings.water_supply_system IS '급수 시스템 종류';
COMMENT ON COLUMN bms.buildings.fire_safety_grade IS '소방 안전 등급';
COMMENT ON COLUMN bms.buildings.energy_efficiency_grade IS '에너지 효율 등급';
COMMENT ON COLUMN bms.buildings.maintenance_fee_base IS '기본 관리비 (원/㎡)';
COMMENT ON COLUMN bms.buildings.common_area_ratio IS '공용면적 비율 (%)';
COMMENT ON COLUMN bms.buildings.land_area IS '대지 면적 (㎡)';
COMMENT ON COLUMN bms.buildings.building_coverage_ratio IS '건폐율 (%)';
COMMENT ON COLUMN bms.buildings.floor_area_ratio IS '용적률 (%)';
COMMENT ON COLUMN bms.buildings.building_permit_number IS '건축허가번호';
COMMENT ON COLUMN bms.buildings.completion_approval_number IS '사용승인번호';
COMMENT ON COLUMN bms.buildings.property_tax_standard IS '재산세 과세표준액';
COMMENT ON COLUMN bms.buildings.building_insurance_info IS '건물 보험 정보';
COMMENT ON COLUMN bms.buildings.special_notes IS '특이사항';
COMMENT ON COLUMN bms.buildings.last_renovation_date IS '마지막 리모델링 일자';
COMMENT ON COLUMN bms.buildings.next_inspection_date IS '다음 점검 예정일';
COMMENT ON COLUMN bms.buildings.status IS '건물 관리 상태';
COMMENT ON COLUMN bms.buildings.created_at IS '생성 일시';
COMMENT ON COLUMN bms.buildings.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.buildings.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.buildings.updated_by IS '수정자 사용자 ID';

-- units 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.units.unit_id IS '세대 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.units.company_id IS '관리 회사 식별자 (UUID)';
COMMENT ON COLUMN bms.units.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.units.unit_number IS '호실 번호 (예: 101, 102)';
COMMENT ON COLUMN bms.units.floor_number IS '층수';
COMMENT ON COLUMN bms.units.unit_type IS '세대 유형 (원룸, 투룸, 쓰리룸 등)';
COMMENT ON COLUMN bms.units.unit_status IS '세대 상태 (입주, 공실, 수리중 등)';
COMMENT ON COLUMN bms.units.exclusive_area IS '전용면적 (㎡)';
COMMENT ON COLUMN bms.units.common_area IS '공용면적 (㎡)';
COMMENT ON COLUMN bms.units.total_area IS '총 면적 (㎡)';
COMMENT ON COLUMN bms.units.monthly_rent IS '월 임대료 (원)';
COMMENT ON COLUMN bms.units.deposit IS '보증금 (원)';
COMMENT ON COLUMN bms.units.maintenance_fee IS '월 관리비 (원)';
COMMENT ON COLUMN bms.units.room_count IS '방 개수';
COMMENT ON COLUMN bms.units.bathroom_count IS '화장실 개수';
COMMENT ON COLUMN bms.units.has_balcony IS '발코니 보유 여부';
COMMENT ON COLUMN bms.units.has_parking IS '주차장 보유 여부';
COMMENT ON COLUMN bms.units.parking_spaces IS '주차 가능 대수';
COMMENT ON COLUMN bms.units.heating_type IS '난방 방식';
COMMENT ON COLUMN bms.units.cooling_type IS '냉방 방식';
COMMENT ON COLUMN bms.units.ventilation_type IS '환기 방식';
COMMENT ON COLUMN bms.units.has_gas IS '가스 공급 여부';
COMMENT ON COLUMN bms.units.has_water IS '급수 공급 여부';
COMMENT ON COLUMN bms.units.has_internet IS '인터넷 설치 여부';
COMMENT ON COLUMN bms.units.direction IS '향 (남향, 동향 등)';
COMMENT ON COLUMN bms.units.view_type IS '조망 (산뷰, 시티뷰 등)';
COMMENT ON COLUMN bms.units.noise_level IS '소음 수준';
COMMENT ON COLUMN bms.units.move_in_date IS '입주 가능일';
COMMENT ON COLUMN bms.units.move_out_date IS '퇴거 예정일';
COMMENT ON COLUMN bms.units.last_maintenance_date IS '마지막 보수 일자';
COMMENT ON COLUMN bms.units.next_maintenance_date IS '다음 보수 예정일';
COMMENT ON COLUMN bms.units.special_features IS '특별 시설 (붙박이장, 에어컨 등)';
COMMENT ON COLUMN bms.units.restrictions IS '제약 사항';
COMMENT ON COLUMN bms.units.notes IS '기타 메모';
COMMENT ON COLUMN bms.units.created_at IS '생성 일시';
COMMENT ON COLUMN bms.units.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.units.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.units.updated_by IS '수정자 사용자 ID';-- =
====================================================
-- 민원 관리 시스템 테이블 컬럼 커멘트
-- =====================================================

-- complaints 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.complaints.complaint_id IS '민원 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.complaints.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.complaints.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.complaints.unit_id IS '세대 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.complaints.category_id IS '민원 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.complaints.complaint_number IS '민원 번호 (자동 생성)';
COMMENT ON COLUMN bms.complaints.title IS '민원 제목';
COMMENT ON COLUMN bms.complaints.description IS '민원 상세 내용';
COMMENT ON COLUMN bms.complaints.complainant_name IS '민원인 이름';
COMMENT ON COLUMN bms.complaints.complainant_phone IS '민원인 전화번호';
COMMENT ON COLUMN bms.complaints.complainant_email IS '민원인 이메일';
COMMENT ON COLUMN bms.complaints.priority IS '우선순위 (HIGH, MEDIUM, LOW)';
COMMENT ON COLUMN bms.complaints.status IS '처리 상태 (RECEIVED, IN_PROGRESS, RESOLVED, CLOSED)';
COMMENT ON COLUMN bms.complaints.channel IS '접수 채널 (PHONE, EMAIL, WEB, VISIT, MOBILE)';
COMMENT ON COLUMN bms.complaints.assigned_to IS '담당자 사용자 ID';
COMMENT ON COLUMN bms.complaints.due_date IS '처리 기한';
COMMENT ON COLUMN bms.complaints.resolved_at IS '해결 완료 일시';
COMMENT ON COLUMN bms.complaints.resolution_summary IS '해결 요약';
COMMENT ON COLUMN bms.complaints.satisfaction_rating IS '만족도 평가 (1-5점)';
COMMENT ON COLUMN bms.complaints.created_at IS '접수 일시';
COMMENT ON COLUMN bms.complaints.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.complaints.created_by IS '접수자 사용자 ID';
COMMENT ON COLUMN bms.complaints.updated_by IS '수정자 사용자 ID';

-- complaint_categories 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.complaint_categories.category_id IS '민원 분류 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_categories.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_categories.parent_category_id IS '상위 분류 식별자 (UUID, 계층 구조)';
COMMENT ON COLUMN bms.complaint_categories.category_name IS '분류명';
COMMENT ON COLUMN bms.complaint_categories.category_code IS '분류 코드';
COMMENT ON COLUMN bms.complaint_categories.description IS '분류 설명';
COMMENT ON COLUMN bms.complaint_categories.default_priority IS '기본 우선순위';
COMMENT ON COLUMN bms.complaint_categories.default_sla_hours IS '기본 SLA 시간';
COMMENT ON COLUMN bms.complaint_categories.auto_assign_to IS '자동 배정 담당자 ID';
COMMENT ON COLUMN bms.complaint_categories.is_active IS '활성 상태';
COMMENT ON COLUMN bms.complaint_categories.sort_order IS '정렬 순서';
COMMENT ON COLUMN bms.complaint_categories.created_at IS '생성 일시';
COMMENT ON COLUMN bms.complaint_categories.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.complaint_categories.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.complaint_categories.updated_by IS '수정자 사용자 ID';

-- =====================================================
-- 회계 관리 시스템 테이블 컬럼 커멘트
-- =====================================================

-- account_codes 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.account_codes.account_code_id IS '계정과목 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.parent_code_id IS '상위 계정과목 식별자 (UUID)';
COMMENT ON COLUMN bms.account_codes.code IS '계정과목 코드';
COMMENT ON COLUMN bms.account_codes.name IS '계정과목명';
COMMENT ON COLUMN bms.account_codes.description IS '계정과목 설명';
COMMENT ON COLUMN bms.account_codes.account_type IS '계정 유형 (ASSET, LIABILITY, EQUITY, REVENUE, EXPENSE)';
COMMENT ON COLUMN bms.account_codes.level IS '계정 레벨 (1: 대분류, 2: 중분류, 3: 소분류)';
COMMENT ON COLUMN bms.account_codes.is_active IS '활성 상태';
COMMENT ON COLUMN bms.account_codes.created_at IS '생성 일시';
COMMENT ON COLUMN bms.account_codes.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.account_codes.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.account_codes.updated_by IS '수정자 사용자 ID';

-- accounting_entries 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.accounting_entries.entry_id IS '회계 항목 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.account_code_id IS '계정과목 식별자 (UUID)';
COMMENT ON COLUMN bms.accounting_entries.transaction_date IS '거래 일자';
COMMENT ON COLUMN bms.accounting_entries.description IS '거래 설명';
COMMENT ON COLUMN bms.accounting_entries.debit_amount IS '차변 금액';
COMMENT ON COLUMN bms.accounting_entries.credit_amount IS '대변 금액';
COMMENT ON COLUMN bms.accounting_entries.entry_type IS '항목 유형 (INCOME, EXPENSE, TRANSFER)';
COMMENT ON COLUMN bms.accounting_entries.reference_number IS '참조 번호 (영수증, 계약서 등)';
COMMENT ON COLUMN bms.accounting_entries.approval_status IS '승인 상태 (PENDING, APPROVED, REJECTED)';
COMMENT ON COLUMN bms.accounting_entries.approved_by IS '승인자 사용자 ID';
COMMENT ON COLUMN bms.accounting_entries.approved_at IS '승인 일시';
COMMENT ON COLUMN bms.accounting_entries.created_at IS '생성 일시';
COMMENT ON COLUMN bms.accounting_entries.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.accounting_entries.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.accounting_entries.updated_by IS '수정자 사용자 ID';

-- =====================================================
-- 관리비 관리 시스템 테이블 컬럼 커멘트
-- =====================================================

-- maintenance_fee_policies 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.maintenance_fee_policies.policy_id IS '관리비 정책 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.maintenance_fee_policies.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.maintenance_fee_policies.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.maintenance_fee_policies.policy_name IS '정책명';
COMMENT ON COLUMN bms.maintenance_fee_policies.description IS '정책 설명';
COMMENT ON COLUMN bms.maintenance_fee_policies.effective_date IS '시행일';
COMMENT ON COLUMN bms.maintenance_fee_policies.expiry_date IS '만료일';
COMMENT ON COLUMN bms.maintenance_fee_policies.is_active IS '활성 상태';
COMMENT ON COLUMN bms.maintenance_fee_policies.created_at IS '생성 일시';
COMMENT ON COLUMN bms.maintenance_fee_policies.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.maintenance_fee_policies.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.maintenance_fee_policies.updated_by IS '수정자 사용자 ID';

-- fee_items 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.fee_items.item_id IS '관리비 항목 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.fee_items.policy_id IS '관리비 정책 식별자 (UUID)';
COMMENT ON COLUMN bms.fee_items.item_code IS '항목 코드';
COMMENT ON COLUMN bms.fee_items.item_name IS '항목명';
COMMENT ON COLUMN bms.fee_items.description IS '항목 설명';
COMMENT ON COLUMN bms.fee_items.calculation_type IS '계산 방식 (FIXED, AREA_BASED, USAGE_BASED, PERCENTAGE)';
COMMENT ON COLUMN bms.fee_items.unit_price IS '단가';
COMMENT ON COLUMN bms.fee_items.is_required IS '필수 항목 여부';
COMMENT ON COLUMN bms.fee_items.sort_order IS '정렬 순서';
COMMENT ON COLUMN bms.fee_items.created_at IS '생성 일시';
COMMENT ON COLUMN bms.fee_items.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.fee_items.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.fee_items.updated_by IS '수정자 사용자 ID';

-- =====================================================
-- 시설 관리 시스템 테이블 컬럼 커멘트
-- =====================================================

-- facility_assets 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.facility_assets.asset_id IS '시설 자산 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.category_id IS '시설 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.facility_assets.asset_code IS '자산 코드';
COMMENT ON COLUMN bms.facility_assets.asset_name IS '자산명';
COMMENT ON COLUMN bms.facility_assets.description IS '자산 설명';
COMMENT ON COLUMN bms.facility_assets.location IS '설치 위치';
COMMENT ON COLUMN bms.facility_assets.manufacturer IS '제조사';
COMMENT ON COLUMN bms.facility_assets.model_number IS '모델 번호';
COMMENT ON COLUMN bms.facility_assets.serial_number IS '시리얼 번호';
COMMENT ON COLUMN bms.facility_assets.purchase_date IS '구매일';
COMMENT ON COLUMN bms.facility_assets.purchase_cost IS '구매 비용';
COMMENT ON COLUMN bms.facility_assets.installation_date IS '설치일';
COMMENT ON COLUMN bms.facility_assets.warranty_start_date IS '보증 시작일';
COMMENT ON COLUMN bms.facility_assets.warranty_end_date IS '보증 종료일';
COMMENT ON COLUMN bms.facility_assets.expected_life_years IS '예상 수명 (년)';
COMMENT ON COLUMN bms.facility_assets.current_condition IS '현재 상태 (EXCELLENT, GOOD, FAIR, POOR, CRITICAL)';
COMMENT ON COLUMN bms.facility_assets.operational_status IS '운영 상태 (OPERATIONAL, MAINTENANCE, OUT_OF_ORDER, RETIRED)';
COMMENT ON COLUMN bms.facility_assets.last_maintenance_date IS '마지막 유지보수일';
COMMENT ON COLUMN bms.facility_assets.next_maintenance_date IS '다음 유지보수 예정일';
COMMENT ON COLUMN bms.facility_assets.maintenance_interval_days IS '유지보수 주기 (일)';
COMMENT ON COLUMN bms.facility_assets.created_at IS '생성 일시';
COMMENT ON COLUMN bms.facility_assets.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.facility_assets.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.facility_assets.updated_by IS '수정자 사용자 ID';

-- fault_reports 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.fault_reports.fault_id IS '고장 신고 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.unit_id IS '세대 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.fault_reports.asset_id IS '시설 자산 식별자 (UUID, 선택사항)';
COMMENT ON COLUMN bms.fault_reports.category_id IS '고장 분류 식별자 (UUID)';
COMMENT ON COLUMN bms.fault_reports.fault_number IS '고장 신고 번호';
COMMENT ON COLUMN bms.fault_reports.title IS '고장 제목';
COMMENT ON COLUMN bms.fault_reports.description IS '고장 상세 설명';
COMMENT ON COLUMN bms.fault_reports.location IS '고장 발생 위치';
COMMENT ON COLUMN bms.fault_reports.reporter_name IS '신고자 이름';
COMMENT ON COLUMN bms.fault_reports.reporter_phone IS '신고자 전화번호';
COMMENT ON COLUMN bms.fault_reports.reporter_email IS '신고자 이메일';
COMMENT ON COLUMN bms.fault_reports.priority IS '우선순위 (CRITICAL, HIGH, MEDIUM, LOW)';
COMMENT ON COLUMN bms.fault_reports.status IS '처리 상태 (REPORTED, ASSIGNED, IN_PROGRESS, RESOLVED, CLOSED)';
COMMENT ON COLUMN bms.fault_reports.urgency IS '긴급도 (EMERGENCY, URGENT, NORMAL)';
COMMENT ON COLUMN bms.fault_reports.assigned_to IS '담당자 사용자 ID';
COMMENT ON COLUMN bms.fault_reports.estimated_cost IS '예상 수리 비용';
COMMENT ON COLUMN bms.fault_reports.actual_cost IS '실제 수리 비용';
COMMENT ON COLUMN bms.fault_reports.resolved_at IS '해결 완료 일시';
COMMENT ON COLUMN bms.fault_reports.resolution_summary IS '해결 요약';
COMMENT ON COLUMN bms.fault_reports.created_at IS '신고 일시';
COMMENT ON COLUMN bms.fault_reports.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.fault_reports.created_by IS '신고자 사용자 ID';
COMMENT ON COLUMN bms.fault_reports.updated_by IS '수정자 사용자 ID';