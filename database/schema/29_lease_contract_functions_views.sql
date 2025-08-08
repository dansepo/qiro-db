-- =====================================================
-- 임대차 계약 관리 시스템 함수 및 뷰 생성 스크립트
-- Phase 3.1: 임대차 계약 관리 함수 및 뷰
-- =====================================================

-- 1. 계약 생성 함수
CREATE OR REPLACE FUNCTION bms.create_lease_contract(
    p_company_id UUID,
    p_unit_id UUID,
    p_contract_type VARCHAR(20),
    p_contract_date DATE,
    p_move_in_date DATE,
    p_contract_start_date DATE,
    p_contract_end_date DATE,
    p_deposit_amount DECIMAL(15,2),
    p_monthly_rent DECIMAL(15,2),
    p_maintenance_fee_included BOOLEAN DEFAULT false,
    p_maintenance_fee_amount DECIMAL(15,2) DEFAULT 0,
    p_special_terms TEXT DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_contract_id UUID;
    v_contract_number VARCHAR(50);
    v_unit_info RECORD;
BEGIN
    -- 세대 정보 조회
    SELECT u.unit_number, b.building_name
    INTO v_unit_info
    FROM bms.units u
    JOIN bms.buildings b ON u.building_id = b.building_id
    WHERE u.unit_id = p_unit_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '세대 정보를 찾을 수 없습니다: %', p_unit_id;
    END IF;
    
    -- 계약 번호 생성
    v_contract_number := 'LC' || TO_CHAR(p_contract_date, 'YYYYMMDD') || '-' || 
                        REPLACE(v_unit_info.unit_number, ' ', '') || '-' ||
                        LPAD(EXTRACT(EPOCH FROM NOW())::TEXT, 6, '0');
    
    -- 기존 활성 계약 확인
    IF EXISTS (
        SELECT 1 FROM bms.lease_contracts 
        WHERE unit_id = p_unit_id 
        AND contract_status = 'ACTIVE'
        AND contract_end_date > CURRENT_DATE
    ) THEN
        RAISE EXCEPTION '해당 세대에 이미 활성 계약이 존재합니다: %', v_unit_info.unit_number;
    END IF;
    
    -- 계약 생성
    INSERT INTO bms.lease_contracts (
        company_id,
        unit_id,
        contract_number,
        contract_type,
        contract_date,
        move_in_date,
        contract_start_date,
        contract_end_date,
        deposit_amount,
        monthly_rent,
        maintenance_fee_included,
        maintenance_fee_amount,
        special_terms,
        created_by
    ) VALUES (
        p_company_id,
        p_unit_id,
        v_contract_number,
        p_contract_type,
        p_contract_date,
        p_move_in_date,
        p_contract_start_date,
        p_contract_end_date,
        p_deposit_amount,
        p_monthly_rent,
        p_maintenance_fee_included,
        p_maintenance_fee_amount,
        p_special_terms,
        p_created_by
    ) RETURNING contract_id INTO v_contract_id;
    
    -- 계약 상태 이력 생성
    INSERT INTO bms.contract_status_history (
        contract_id,
        company_id,
        previous_status,
        new_status,
        change_reason,
        change_description,
        changed_by
    ) VALUES (
        v_contract_id,
        p_company_id,
        NULL,
        'DRAFT',
        'INITIAL_CREATION',
        '계약 초안 생성',
        p_created_by
    );
    
    RETURN v_contract_id;
END;
$$;

-- 2. 계약 당사자 추가 함수
CREATE OR REPLACE FUNCTION bms.add_contract_party(
    p_contract_id UUID,
    p_party_type VARCHAR(20),
    p_party_role VARCHAR(20),
    p_name VARCHAR(100),
    p_id_number VARCHAR(20) DEFAULT NULL,
    p_phone_number VARCHAR(20) DEFAULT NULL,
    p_email VARCHAR(255) DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_is_primary BOOLEAN DEFAULT false,
    p_additional_info JSONB DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_party_id UUID;
    v_company_id UUID;
BEGIN
    -- 계약의 회사 ID 조회
    SELECT company_id INTO v_company_id
    FROM bms.lease_contracts
    WHERE contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 계약 당사자 추가
    INSERT INTO bms.contract_parties (
        contract_id,
        company_id,
        party_type,
        party_role,
        name,
        id_number,
        phone_number,
        email,
        address,
        is_primary
    ) VALUES (
        p_contract_id,
        v_company_id,
        p_party_type,
        p_party_role,
        p_name,
        p_id_number,
        p_phone_number,
        p_email,
        p_address,
        p_is_primary
    ) RETURNING party_id INTO v_party_id;
    
    RETURN v_party_id;
END;
$$;

-- 3. 계약 상태 변경 함수
CREATE OR REPLACE FUNCTION bms.update_contract_status(
    p_contract_id UUID,
    p_new_status VARCHAR(20),
    p_change_reason VARCHAR(20),
    p_description TEXT DEFAULT NULL,
    p_changed_by UUID DEFAULT NULL
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_current_status VARCHAR(20);
    v_company_id UUID;
BEGIN
    -- 현재 계약 상태 조회
    SELECT contract_status, company_id
    INTO v_current_status, v_company_id
    FROM bms.lease_contracts
    WHERE contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 상태가 동일한 경우 처리하지 않음
    IF v_current_status = p_new_status THEN
        RETURN false;
    END IF;
    
    -- 계약 상태 업데이트
    UPDATE bms.lease_contracts
    SET contract_status = p_new_status,
        updated_at = NOW()
    WHERE contract_id = p_contract_id;
    
    -- 상태 변경 이력 기록
    INSERT INTO bms.contract_status_history (
        contract_id,
        company_id,
        previous_status,
        new_status,
        change_reason,
        change_description,
        changed_by
    ) VALUES (
        p_contract_id,
        v_company_id,
        v_current_status,
        p_new_status,
        p_change_reason,
        p_description,
        p_changed_by
    );
    
    RETURN true;
END;
$$;

-- 4. 계약 갱신 처리 함수
CREATE OR REPLACE FUNCTION bms.process_contract_renewal(
    p_original_contract_id UUID,
    p_new_start_date DATE,
    p_new_end_date DATE,
    p_new_deposit DECIMAL(15,2),
    p_new_rent DECIMAL(15,2),
    p_renewal_type VARCHAR(20) DEFAULT 'NEGOTIATED',
    p_processed_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_renewal_id UUID;
    v_new_contract_id UUID;
    v_original_contract RECORD;
    v_company_id UUID;
BEGIN
    -- 원본 계약 정보 조회
    SELECT *
    INTO v_original_contract
    FROM bms.lease_contracts
    WHERE contract_id = p_original_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '원본 계약을 찾을 수 없습니다: %', p_original_contract_id;
    END IF;
    
    v_company_id := v_original_contract.company_id;
    
    -- 갱신 계약 생성
    SELECT bms.create_lease_contract(
        v_company_id,
        v_original_contract.unit_id,
        'RENEWAL',
        CURRENT_DATE,
        p_new_start_date,
        p_new_start_date,
        p_new_end_date,
        p_new_deposit,
        p_new_rent,
        v_original_contract.maintenance_fee_included,
        v_original_contract.maintenance_fee_amount,
        v_original_contract.special_terms,
        p_processed_by
    ) INTO v_new_contract_id;
    
    -- 갱신 계약에 원본 계약 ID 설정
    UPDATE bms.lease_contracts
    SET original_contract_id = p_original_contract_id,
        change_reason = 'RENEWAL',
        change_description = '계약 갱신'
    WHERE contract_id = v_new_contract_id;
    
    -- 갱신 이력 생성
    INSERT INTO bms.contract_renewals (
        original_contract_id,
        renewed_contract_id,
        company_id,
        renewal_type,
        renewal_status,
        renewal_decision_date,
        new_contract_start_date,
        new_contract_end_date,
        previous_deposit,
        new_deposit,
        previous_rent,
        new_rent,
        rent_increase_rate,
        deposit_adjustment,
        processed_by,
        processed_at
    ) VALUES (
        p_original_contract_id,
        v_new_contract_id,
        v_company_id,
        p_renewal_type,
        'COMPLETED',
        CURRENT_DATE,
        p_new_start_date,
        p_new_end_date,
        v_original_contract.deposit_amount,
        p_new_deposit,
        v_original_contract.monthly_rent,
        p_new_rent,
        CASE 
            WHEN v_original_contract.monthly_rent > 0 
            THEN ((p_new_rent - v_original_contract.monthly_rent) / v_original_contract.monthly_rent * 100)
            ELSE 0
        END,
        p_new_deposit - v_original_contract.deposit_amount,
        p_processed_by,
        NOW()
    ) RETURNING renewal_id INTO v_renewal_id;
    
    -- 원본 계약 상태를 만료로 변경
    PERFORM bms.update_contract_status(
        p_original_contract_id,
        'EXPIRED',
        'NATURAL_EXPIRATION',
        '계약 갱신으로 인한 만료',
        p_processed_by
    );
    
    -- 새 계약 상태를 활성으로 변경
    PERFORM bms.update_contract_status(
        v_new_contract_id,
        'ACTIVE',
        'CONTRACT_EXECUTION',
        '갱신 계약 활성화',
        p_processed_by
    );
    
    RETURN v_new_contract_id;
END;
$$;

-- 5. 계약 만료 예정 조회 함수
CREATE OR REPLACE FUNCTION bms.get_expiring_contracts(
    p_company_id UUID,
    p_days_ahead INTEGER DEFAULT 90
) RETURNS TABLE (
    contract_id UUID,
    unit_number VARCHAR(50),
    building_name VARCHAR(200),
    tenant_name VARCHAR(100),
    contract_end_date DATE,
    days_until_expiry INTEGER,
    monthly_rent DECIMAL(15,2),
    deposit_amount DECIMAL(15,2),
    renewal_option VARCHAR(20)
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT 
        lc.contract_id,
        u.unit_number,
        b.name as building_name,
        cp.name as tenant_name,
        lc.contract_end_date,
        (lc.contract_end_date - CURRENT_DATE)::INTEGER as days_until_expiry,
        lc.monthly_rent,
        lc.deposit_amount,
        lc.renewal_option
    FROM bms.lease_contracts lc
    JOIN bms.units u ON lc.unit_id = u.unit_id
    JOIN bms.buildings b ON u.building_id = b.building_id
    LEFT JOIN bms.contract_parties cp ON lc.contract_id = cp.contract_id 
        AND cp.party_role = 'TENANT' AND cp.is_primary = true
    WHERE lc.company_id = p_company_id
    AND lc.contract_status = 'ACTIVE'
    AND lc.contract_end_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + p_days_ahead)
    ORDER BY lc.contract_end_date ASC;
END;
$$;

-- 6. 계약 대시보드 뷰
CREATE OR REPLACE VIEW bms.v_contract_dashboard AS
SELECT 
    lc.contract_id,
    lc.company_id,
    lc.unit_id,
    u.unit_number,
    b.name as building_name,
    
    -- 계약 기본 정보
    lc.contract_number,
    lc.contract_type,
    lc.contract_status,
    lc.contract_date,
    lc.contract_start_date,
    lc.contract_end_date,
    
    -- 임대 조건
    lc.deposit_amount,
    lc.monthly_rent,
    lc.maintenance_fee_included,
    lc.maintenance_fee_amount,
    
    -- 임차인 정보
    tenant.name as tenant_name,
    tenant.phone_number as tenant_phone,
    tenant.email as tenant_email,
    
    -- 임대인 정보
    landlord.name as landlord_name,
    landlord.phone_number as landlord_phone,
    
    -- 계약 상태 정보
    CASE 
        WHEN lc.contract_status = 'ACTIVE' AND lc.contract_end_date <= CURRENT_DATE + INTERVAL '30 days' THEN '만료임박'
        WHEN lc.contract_status = 'ACTIVE' AND lc.contract_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN '갱신검토'
        WHEN lc.contract_status = 'ACTIVE' THEN '정상'
        WHEN lc.contract_status = 'EXPIRED' THEN '만료'
        WHEN lc.contract_status = 'TERMINATED' THEN '해지'
        ELSE lc.contract_status
    END as status_display,
    
    -- 계산된 필드
    (lc.contract_end_date - CURRENT_DATE)::INTEGER as days_until_expiry,
    CASE 
        WHEN lc.contract_status = 'ACTIVE' AND lc.contract_end_date <= CURRENT_DATE + INTERVAL '30 days' THEN 100
        WHEN lc.contract_status = 'ACTIVE' AND lc.contract_end_date <= CURRENT_DATE + INTERVAL '90 days' THEN 80
        WHEN lc.contract_status = 'PENDING' THEN 70
        ELSE 50
    END as priority_score,
    
    -- 총 임대료 (월세 + 관리비)
    lc.monthly_rent + CASE WHEN lc.maintenance_fee_included THEN 0 ELSE lc.maintenance_fee_amount END as total_monthly_fee
    
FROM bms.lease_contracts lc
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN bms.contract_parties tenant ON lc.contract_id = tenant.contract_id 
    AND tenant.party_role = 'TENANT' AND tenant.is_primary = true
LEFT JOIN bms.contract_parties landlord ON lc.contract_id = landlord.contract_id 
    AND landlord.party_role = 'LANDLORD' AND landlord.is_primary = true
WHERE lc.contract_status IN ('ACTIVE', 'PENDING', 'APPROVED');

-- 7. 계약 통계 뷰
CREATE OR REPLACE VIEW bms.v_contract_statistics AS
SELECT 
    company_id,
    
    -- 전체 통계
    COUNT(*) as total_contracts,
    COUNT(*) FILTER (WHERE contract_status = 'ACTIVE') as active_contracts,
    COUNT(*) FILTER (WHERE contract_status = 'EXPIRED') as expired_contracts,
    COUNT(*) FILTER (WHERE contract_status = 'TERMINATED') as terminated_contracts,
    
    -- 계약 유형별 통계
    COUNT(*) FILTER (WHERE contract_type = 'NEW') as new_contracts,
    COUNT(*) FILTER (WHERE contract_type = 'RENEWAL') as renewal_contracts,
    COUNT(*) FILTER (WHERE contract_type = 'TRANSFER') as transfer_contracts,
    
    -- 만료 예정 통계
    COUNT(*) FILTER (WHERE contract_status = 'ACTIVE' AND contract_end_date <= CURRENT_DATE + INTERVAL '30 days') as expiring_30days,
    COUNT(*) FILTER (WHERE contract_status = 'ACTIVE' AND contract_end_date <= CURRENT_DATE + INTERVAL '90 days') as expiring_90days,
    
    -- 금액 통계
    AVG(monthly_rent) FILTER (WHERE contract_status = 'ACTIVE') as avg_monthly_rent,
    SUM(monthly_rent) FILTER (WHERE contract_status = 'ACTIVE') as total_monthly_rent,
    AVG(deposit_amount) FILTER (WHERE contract_status = 'ACTIVE') as avg_deposit,
    SUM(deposit_amount) FILTER (WHERE contract_status = 'ACTIVE') as total_deposit,
    
    -- 기간 통계
    AVG(contract_end_date - contract_start_date) FILTER (WHERE contract_status = 'ACTIVE') as avg_contract_duration,
    
    -- 최신 업데이트 시간
    MAX(updated_at) as last_updated_at
    
FROM bms.lease_contracts
GROUP BY company_id;

-- 8. 계약 갱신 현황 뷰
CREATE OR REPLACE VIEW bms.v_contract_renewals AS
SELECT 
    cr.renewal_id,
    cr.company_id,
    cr.renewal_type,
    cr.renewal_status,
    
    -- 원본 계약 정보
    orig_lc.contract_number as original_contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- 갱신 일정
    cr.renewal_notice_date,
    cr.renewal_deadline_date,
    cr.renewal_decision_date,
    cr.new_contract_start_date,
    cr.new_contract_end_date,
    
    -- 조건 변경
    cr.previous_rent,
    cr.new_rent,
    cr.rent_increase_rate,
    cr.previous_deposit,
    cr.new_deposit,
    cr.deposit_adjustment,
    
    -- 임차인 정보
    cp.name as tenant_name,
    cp.phone_number as tenant_phone,
    
    -- 상태 표시
    CASE 
        WHEN cr.renewal_status = 'PENDING' THEN '대기중'
        WHEN cr.renewal_status = 'NOTIFIED' THEN '통지됨'
        WHEN cr.renewal_status = 'NEGOTIATING' THEN '협상중'
        WHEN cr.renewal_status = 'AGREED' THEN '합의됨'
        WHEN cr.renewal_status = 'COMPLETED' THEN '완료됨'
        WHEN cr.renewal_status = 'REJECTED' THEN '거부됨'
        ELSE cr.renewal_status
    END as status_display,
    
    -- 우선순위 계산
    CASE 
        WHEN cr.renewal_deadline_date <= CURRENT_DATE THEN 100
        WHEN cr.renewal_deadline_date <= CURRENT_DATE + INTERVAL '7 days' THEN 90
        WHEN cr.renewal_deadline_date <= CURRENT_DATE + INTERVAL '30 days' THEN 70
        ELSE 50
    END as priority_score
    
FROM bms.contract_renewals cr
JOIN bms.lease_contracts orig_lc ON cr.original_contract_id = orig_lc.contract_id
JOIN bms.units u ON orig_lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN bms.contract_parties cp ON orig_lc.contract_id = cp.contract_id 
    AND cp.party_role = 'TENANT' AND cp.is_primary = true
WHERE cr.renewal_status != 'CANCELLED';

-- 9. 코멘트 추가
COMMENT ON TABLE bms.lease_contracts IS '임대차 계약 기본 정보 테이블 - 계약 조건, 기간, 임대료 등을 관리';
COMMENT ON TABLE bms.contract_parties IS '계약 당사자 정보 테이블 - 임대인, 임차인, 보증인, 중개업소 정보를 관리';
COMMENT ON TABLE bms.contract_status_history IS '계약 상태 변경 이력 테이블 - 계약 상태 변경 과정을 추적';
COMMENT ON TABLE bms.contract_attachments IS '계약 첨부 문서 테이블 - 계약서, 신분증, 소득증명서 등 관련 문서를 관리';
COMMENT ON TABLE bms.contract_renewals IS '계약 갱신 이력 테이블 - 계약 갱신 과정과 조건 변경 내역을 관리';

COMMENT ON COLUMN bms.lease_contracts.renewal_option IS '갱신 옵션: AUTOMATIC(자동갱신), NEGOTIABLE(협의갱신), FIXED_TERM(정기계약), NO_RENEWAL(갱신불가)';
COMMENT ON COLUMN bms.lease_contracts.maintenance_fee_included IS '관리비 포함 여부 - true면 월세에 관리비 포함, false면 별도 부과';
COMMENT ON COLUMN bms.contract_parties.party_role IS '당사자 역할: LANDLORD(임대인), TENANT(임차인), GUARANTOR(보증인), AGENT(중개업소)';

COMMENT ON FUNCTION bms.create_lease_contract(UUID, UUID, VARCHAR, DATE, DATE, DATE, DATE, DECIMAL, DECIMAL, BOOLEAN, DECIMAL, TEXT, UUID) IS '임대차 계약 생성 함수 - 새로운 계약을 생성하고 상태 이력을 기록';
COMMENT ON FUNCTION bms.add_contract_party(UUID, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT, BOOLEAN, JSONB) IS '계약 당사자 추가 함수 - 계약에 임대인, 임차인 등을 추가';
COMMENT ON FUNCTION bms.update_contract_status(UUID, VARCHAR, VARCHAR, TEXT, UUID) IS '계약 상태 변경 함수 - 계약 상태를 변경하고 이력을 기록';
COMMENT ON FUNCTION bms.process_contract_renewal(UUID, DATE, DATE, DECIMAL, DECIMAL, VARCHAR, UUID) IS '계약 갱신 처리 함수 - 기존 계약을 갱신하여 새 계약을 생성';
COMMENT ON FUNCTION bms.get_expiring_contracts(UUID, INTEGER) IS '계약 만료 예정 조회 함수 - 지정된 기간 내 만료 예정 계약을 조회';

COMMENT ON VIEW bms.v_contract_dashboard IS '계약 대시보드 뷰 - 계약 현황을 종합적으로 조회';
COMMENT ON VIEW bms.v_contract_statistics IS '계약 통계 뷰 - 회사별 계약 현황 통계 정보';
COMMENT ON VIEW bms.v_contract_renewals IS '계약 갱신 현황 뷰 - 갱신 진행 상황과 우선순위 관리';

-- 스크립트 완료 메시지
SELECT '임대차 계약 관리 시스템 함수 및 뷰 생성이 완료되었습니다.' as message;