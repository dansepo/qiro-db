-- =====================================================
-- 한글 커멘트 추가 스크립트 (수정된 버전)
-- 실제 존재하는 컬럼에만 커멘트 추가
-- =====================================================

-- 기본 시스템 테이블 컬럼 커멘트 (이미 존재하는 컬럼들만)
-- companies 테이블은 이미 커멘트가 있으므로 생략

-- users 테이블 컬럼 커멘트 (커멘트가 없는 컬럼들만)
COMMENT ON COLUMN bms.users.user_id IS '사용자 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.users.company_id IS '소속 회사 식별자 (UUID)';
COMMENT ON COLUMN bms.users.email IS '사용자 이메일 주소 (로그인 ID)';
COMMENT ON COLUMN bms.users.password_hash IS '암호화된 비밀번호 해시';
COMMENT ON COLUMN bms.users.full_name IS '사용자 실명';
COMMENT ON COLUMN bms.users.phone_number IS '연락처 전화번호';
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

-- buildings 테이블 컬럼 커멘트 (커멘트가 없는 컬럼들만)
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
COMMENT ON COLUMN bms.units.updated_by IS '수정자 사용자 ID';

-- 공통 코드 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.common_codes.code_id IS '공통 코드 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.common_codes.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.common_codes.code_group IS '코드 그룹 (예: USER_TYPE, BUILDING_TYPE)';
COMMENT ON COLUMN bms.common_codes.code_value IS '코드 값';
COMMENT ON COLUMN bms.common_codes.code_name IS '코드명 (한글)';
COMMENT ON COLUMN bms.common_codes.description IS '코드 설명';
COMMENT ON COLUMN bms.common_codes.sort_order IS '정렬 순서';
COMMENT ON COLUMN bms.common_codes.is_active IS '활성 상태';
COMMENT ON COLUMN bms.common_codes.created_at IS '생성 일시';
COMMENT ON COLUMN bms.common_codes.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.common_codes.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.common_codes.updated_by IS '수정자 사용자 ID';