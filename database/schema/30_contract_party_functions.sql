-- =====================================================
-- 계약 당사자 관리 시스템 함수 생성 스크립트
-- Phase 3.2: 계약 당사자 관리 함수
-- =====================================================

-- 1. 계약 당사자 연락처 추가 함수
CREATE OR REPLACE FUNCTION bms.add_party_contact(
    p_party_id UUID,
    p_contact_type VARCHAR(20),
    p_contact_value VARCHAR(255),
    p_is_primary BOOLEAN DEFAULT false,
    p_usage_purpose TEXT[] DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_contact_id UUID;
    v_company_id UUID;
BEGIN
    -- 당사자의 회사 ID 조회
    SELECT cp.company_id INTO v_company_id
    FROM bms.contract_parties cp
    WHERE cp.party_id = p_party_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약 당사자를 찾을 수 없습니다: %', p_party_id;
    END IF;
    
    -- 주 연락처로 설정하는 경우 기존 주 연락처 해제
    IF p_is_primary THEN
        UPDATE bms.contract_party_contacts
        SET is_primary = false
        WHERE party_id = p_party_id AND contact_type = p_contact_type;
    END IF;
    
    -- 연락처 추가
    INSERT INTO bms.contract_party_contacts (
        party_id,
        company_id,
        contact_type,
        contact_value,
        is_primary,
        usage_purpose
    ) VALUES (
        p_party_id,
        v_company_id,
        p_contact_type,
        p_contact_value,
        p_is_primary,
        p_usage_purpose
    ) RETURNING contact_id INTO v_contact_id;
    
    RETURN v_contact_id;
END;
$$;

-- 2. 계약 당사자 신용 평가 함수
CREATE OR REPLACE FUNCTION bms.evaluate_party_credit(
    p_party_id UUID,
    p_monthly_income DECIMAL(15,2),
    p_total_assets DECIMAL(15,2),
    p_total_debts DECIMAL(15,2),
    p_employment_status VARCHAR(20),
    p_credit_score INTEGER DEFAULT NULL,
    p_evaluated_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_credit_id UUID;
    v_company_id UUID;
    v_credit_grade VARCHAR(10);
    v_evaluation_result VARCHAR(20);
    v_risk_level VARCHAR(20);
    v_recommended_deposit_ratio DECIMAL(5,2);
    v_recommended_guarantor BOOLEAN := false;
    v_debt_to_income_ratio DECIMAL(5,2);
BEGIN
    -- 당사자의 회사 ID 조회
    SELECT cp.company_id INTO v_company_id
    FROM bms.contract_parties cp
    WHERE cp.party_id = p_party_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약 당사자를 찾을 수 없습니다: %', p_party_id;
    END IF;
    
    -- 부채 대비 소득 비율 계산
    IF p_monthly_income > 0 THEN
        v_debt_to_income_ratio := (p_total_debts / (p_monthly_income * 12)) * 100;
    ELSE
        v_debt_to_income_ratio := 100;
    END IF;
    
    -- 신용 등급 결정 (신용점수 기반)
    IF p_credit_score IS NOT NULL THEN
        CASE 
            WHEN p_credit_score >= 900 THEN v_credit_grade := 'AAA';
            WHEN p_credit_score >= 850 THEN v_credit_grade := 'AA+';
            WHEN p_credit_score >= 800 THEN v_credit_grade := 'AA';
            WHEN p_credit_score >= 750 THEN v_credit_grade := 'AA-';
            WHEN p_credit_score >= 700 THEN v_credit_grade := 'A+';
            WHEN p_credit_score >= 650 THEN v_credit_grade := 'A';
            WHEN p_credit_score >= 600 THEN v_credit_grade := 'A-';
            WHEN p_credit_score >= 550 THEN v_credit_grade := 'BBB+';
            WHEN p_credit_score >= 500 THEN v_credit_grade := 'BBB';
            WHEN p_credit_score >= 450 THEN v_credit_grade := 'BBB-';
            WHEN p_credit_score >= 400 THEN v_credit_grade := 'BB+';
            WHEN p_credit_score >= 350 THEN v_credit_grade := 'BB';
            WHEN p_credit_score >= 300 THEN v_credit_grade := 'BB-';
            ELSE v_credit_grade := 'B';
        END CASE;
    END IF;
    
    -- 평가 결과 결정
    CASE 
        WHEN p_credit_score >= 750 AND v_debt_to_income_ratio <= 30 AND p_employment_status IN ('EMPLOYED', 'SELF_EMPLOYED') THEN
            v_evaluation_result := 'EXCELLENT';
            v_risk_level := 'LOW';
            v_recommended_deposit_ratio := 10;
        WHEN p_credit_score >= 650 AND v_debt_to_income_ratio <= 50 AND p_employment_status IN ('EMPLOYED', 'CONTRACT', 'SELF_EMPLOYED') THEN
            v_evaluation_result := 'GOOD';
            v_risk_level := 'LOW';
            v_recommended_deposit_ratio := 20;
        WHEN p_credit_score >= 550 AND v_debt_to_income_ratio <= 70 THEN
            v_evaluation_result := 'FAIR';
            v_risk_level := 'MEDIUM';
            v_recommended_deposit_ratio := 30;
            v_recommended_guarantor := true;
        WHEN p_credit_score >= 400 AND v_debt_to_income_ratio <= 80 THEN
            v_evaluation_result := 'POOR';
            v_risk_level := 'HIGH';
            v_recommended_deposit_ratio := 50;
            v_recommended_guarantor := true;
        ELSE
            v_evaluation_result := 'REJECTED';
            v_risk_level := 'VERY_HIGH';
            v_recommended_deposit_ratio := 100;
            v_recommended_guarantor := true;
    END CASE;
    
    -- 신용 정보 저장
    INSERT INTO bms.contract_party_credit (
        party_id,
        company_id,
        credit_evaluation_date,
        credit_score,
        credit_grade,
        monthly_income,
        annual_income,
        employment_status,
        total_assets,
        total_debts,
        evaluation_result,
        risk_level,
        recommended_deposit_ratio,
        recommended_guarantor,
        evaluated_by,
        valid_until
    ) VALUES (
        p_party_id,
        v_company_id,
        CURRENT_DATE,
        p_credit_score,
        v_credit_grade,
        p_monthly_income,
        p_monthly_income * 12,
        p_employment_status,
        p_total_assets,
        p_total_debts,
        v_evaluation_result,
        v_risk_level,
        v_recommended_deposit_ratio,
        v_recommended_guarantor,
        p_evaluated_by,
        CURRENT_DATE + INTERVAL '1 year'
    ) RETURNING credit_id INTO v_credit_id;
    
    RETURN v_credit_id;
END;
$$;

-- 3. 계약 당사자 관계 설정 함수
CREATE OR REPLACE FUNCTION bms.create_party_relationship(
    p_contract_id UUID,
    p_primary_party_id UUID,
    p_related_party_id UUID,
    p_relationship_type VARCHAR(20),
    p_legal_relationship VARCHAR(20) DEFAULT 'INDIVIDUAL_LIABILITY',
    p_responsibility_level VARCHAR(20) DEFAULT 'PARTIAL',
    p_liability_amount DECIMAL(15,2) DEFAULT NULL,
    p_authorization_scope TEXT[] DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_relationship_id UUID;
    v_company_id UUID;
    v_can_sign BOOLEAN := false;
    v_can_modify BOOLEAN := false;
    v_can_terminate BOOLEAN := false;
BEGIN
    -- 계약의 회사 ID 조회
    SELECT company_id INTO v_company_id
    FROM bms.lease_contracts
    WHERE contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 관계 유형에 따른 권한 설정
    CASE p_relationship_type
        WHEN 'SPOUSE' THEN
            v_can_sign := true;
            v_can_modify := true;
            v_can_terminate := true;
        WHEN 'REPRESENTATIVE' THEN
            v_can_sign := true;
            v_can_modify := true;
            v_can_terminate := false;
        WHEN 'GUARANTOR' THEN
            v_can_sign := true;
            v_can_modify := false;
            v_can_terminate := false;
        WHEN 'CO_TENANT' THEN
            v_can_sign := true;
            v_can_modify := true;
            v_can_terminate := true;
        ELSE
            v_can_sign := false;
            v_can_modify := false;
            v_can_terminate := false;
    END CASE;
    
    -- 관계 생성
    INSERT INTO bms.contract_party_relationships (
        contract_id,
        company_id,
        primary_party_id,
        related_party_id,
        relationship_type,
        legal_relationship,
        responsibility_level,
        liability_amount,
        authorization_scope,
        can_sign_contract,
        can_modify_contract,
        can_terminate_contract
    ) VALUES (
        p_contract_id,
        v_company_id,
        p_primary_party_id,
        p_related_party_id,
        p_relationship_type,
        p_legal_relationship,
        p_responsibility_level,
        p_liability_amount,
        p_authorization_scope,
        v_can_sign,
        v_can_modify,
        v_can_terminate
    ) RETURNING relationship_id INTO v_relationship_id;
    
    RETURN v_relationship_id;
END;
$$;

-- 4. 계약 당사자 변경 처리 함수
CREATE OR REPLACE FUNCTION bms.process_party_change(
    p_contract_id UUID,
    p_change_type VARCHAR(20),
    p_change_reason VARCHAR(20),
    p_affected_party_id UUID DEFAULT NULL,
    p_new_party_id UUID DEFAULT NULL,
    p_changed_fields JSONB DEFAULT NULL,
    p_effective_date DATE DEFAULT CURRENT_DATE,
    p_approved_by UUID DEFAULT NULL
) RETURNS UUID LANGUAGE plpgsql AS $$
DECLARE
    v_change_id UUID;
    v_company_id UUID;
    v_previous_values JSONB;
    v_new_values JSONB;
BEGIN
    -- 계약의 회사 ID 조회
    SELECT company_id INTO v_company_id
    FROM bms.lease_contracts
    WHERE contract_id = p_contract_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '계약을 찾을 수 없습니다: %', p_contract_id;
    END IF;
    
    -- 기존 값 조회 (정보 업데이트인 경우)
    IF p_change_type = 'UPDATE_INFO' AND p_affected_party_id IS NOT NULL THEN
        SELECT to_jsonb(cp.*) INTO v_previous_values
        FROM bms.contract_parties cp
        WHERE cp.party_id = p_affected_party_id;
    END IF;
    
    -- 변경 이력 생성
    INSERT INTO bms.contract_party_changes (
        contract_id,
        company_id,
        change_type,
        change_reason,
        affected_party_id,
        new_party_id,
        changed_fields,
        previous_values,
        new_values,
        effective_date,
        approved_by,
        approved_at,
        change_status
    ) VALUES (
        p_contract_id,
        v_company_id,
        p_change_type,
        p_change_reason,
        p_affected_party_id,
        p_new_party_id,
        p_changed_fields,
        v_previous_values,
        p_changed_fields,
        p_effective_date,
        p_approved_by,
        CASE WHEN p_approved_by IS NOT NULL THEN NOW() ELSE NULL END,
        CASE WHEN p_approved_by IS NOT NULL THEN 'APPROVED' ELSE 'PENDING' END
    ) RETURNING change_id INTO v_change_id;
    
    -- 승인된 경우 즉시 적용
    IF p_approved_by IS NOT NULL THEN
        PERFORM bms.apply_party_change(v_change_id);
    END IF;
    
    RETURN v_change_id;
END;
$$;

-- 5. 계약 당사자 변경 적용 함수
CREATE OR REPLACE FUNCTION bms.apply_party_change(
    p_change_id UUID
) RETURNS BOOLEAN LANGUAGE plpgsql AS $$
DECLARE
    v_change RECORD;
    v_field_name TEXT;
    v_field_value TEXT;
BEGIN
    -- 변경 정보 조회
    SELECT * INTO v_change
    FROM bms.contract_party_changes
    WHERE change_id = p_change_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '변경 이력을 찾을 수 없습니다: %', p_change_id;
    END IF;
    
    -- 승인되지 않은 변경은 적용할 수 없음
    IF v_change.change_status != 'APPROVED' THEN
        RAISE EXCEPTION '승인되지 않은 변경입니다: %', p_change_id;
    END IF;
    
    -- 변경 유형에 따른 처리
    CASE v_change.change_type
        WHEN 'UPDATE_INFO' THEN
            -- 당사자 정보 업데이트
            IF v_change.changed_fields IS NOT NULL THEN
                FOR v_field_name, v_field_value IN SELECT * FROM jsonb_each_text(v_change.changed_fields)
                LOOP
                    EXECUTE format('UPDATE bms.contract_parties SET %I = %L WHERE party_id = %L',
                        v_field_name, v_field_value, v_change.affected_party_id);
                END LOOP;
            END IF;
            
        WHEN 'REPLACE_PARTY' THEN
            -- 당사자 교체 (기존 당사자 비활성화, 새 당사자 활성화)
            UPDATE bms.contract_parties
            SET is_active = false
            WHERE party_id = v_change.affected_party_id;
            
            UPDATE bms.contract_parties
            SET is_active = true
            WHERE party_id = v_change.new_party_id;
            
        WHEN 'REMOVE_PARTY' THEN
            -- 당사자 제거 (비활성화)
            UPDATE bms.contract_parties
            SET is_active = false
            WHERE party_id = v_change.affected_party_id;
    END CASE;
    
    -- 변경 상태 업데이트
    UPDATE bms.contract_party_changes
    SET change_status = 'APPLIED',
        applied_at = NOW()
    WHERE change_id = p_change_id;
    
    RETURN true;
END;
$$;

-- 6. 계약 당사자 종합 정보 조회 뷰
CREATE OR REPLACE VIEW bms.v_contract_party_summary AS
SELECT 
    cp.party_id,
    cp.contract_id,
    cp.company_id,
    lc.contract_number,
    u.unit_number,
    b.name as building_name,
    
    -- 당사자 기본 정보
    cp.party_type,
    cp.party_role,
    cp.name,
    cp.id_number,
    cp.is_primary,
    cp.is_active,
    
    -- 연락처 정보 (주 연락처)
    pc_phone.contact_value as primary_phone,
    pc_email.contact_value as primary_email,
    cp.address,
    
    -- 신용 정보 (최신)
    pcr.credit_score,
    pcr.credit_grade,
    pcr.evaluation_result,
    pcr.risk_level,
    pcr.monthly_income,
    pcr.recommended_guarantor,
    
    -- 관계 정보
    ARRAY_AGG(DISTINCT pr.relationship_type) FILTER (WHERE pr.relationship_type IS NOT NULL) as relationships,
    
    -- 변경 이력 (최근)
    pch.change_type as last_change_type,
    pch.change_reason as last_change_reason,
    pch.created_at as last_change_date,
    
    -- 계산된 필드
    CASE 
        WHEN cp.party_role = 'TENANT' AND pcr.evaluation_result = 'REJECTED' THEN '계약불가'
        WHEN cp.party_role = 'TENANT' AND pcr.risk_level = 'VERY_HIGH' THEN '고위험'
        WHEN cp.party_role = 'TENANT' AND pcr.risk_level = 'HIGH' THEN '위험'
        WHEN cp.party_role = 'GUARANTOR' AND pcr.evaluation_result IN ('POOR', 'REJECTED') THEN '보증불가'
        ELSE '정상'
    END as status_assessment
    
FROM bms.contract_parties cp
JOIN bms.lease_contracts lc ON cp.contract_id = lc.contract_id
JOIN bms.units u ON lc.unit_id = u.unit_id
JOIN bms.buildings b ON u.building_id = b.building_id
LEFT JOIN bms.contract_party_contacts pc_phone ON cp.party_id = pc_phone.party_id 
    AND pc_phone.contact_type = 'MOBILE' AND pc_phone.is_primary = true
LEFT JOIN bms.contract_party_contacts pc_email ON cp.party_id = pc_email.party_id 
    AND pc_email.contact_type = 'EMAIL' AND pc_email.is_primary = true
LEFT JOIN LATERAL (
    SELECT * FROM bms.contract_party_credit 
    WHERE party_id = cp.party_id 
    ORDER BY credit_evaluation_date DESC 
    LIMIT 1
) pcr ON true
LEFT JOIN bms.contract_party_relationships pr ON cp.party_id = pr.primary_party_id 
    OR cp.party_id = pr.related_party_id
LEFT JOIN LATERAL (
    SELECT * FROM bms.contract_party_changes 
    WHERE affected_party_id = cp.party_id 
    ORDER BY created_at DESC 
    LIMIT 1
) pch ON true
WHERE cp.is_active = true
GROUP BY 
    cp.party_id, cp.contract_id, cp.company_id, lc.contract_number, u.unit_number, b.name,
    cp.party_type, cp.party_role, cp.name, cp.id_number, cp.is_primary, cp.is_active,
    pc_phone.contact_value, pc_email.contact_value, cp.address,
    pcr.credit_score, pcr.credit_grade, pcr.evaluation_result, pcr.risk_level, 
    pcr.monthly_income, pcr.recommended_guarantor,
    pch.change_type, pch.change_reason, pch.created_at;

-- 7. 코멘트 추가
COMMENT ON TABLE bms.contract_party_contacts IS '계약 당사자 연락처 이력 테이블 - 다양한 연락처 정보와 인증 상태를 관리';
COMMENT ON TABLE bms.contract_party_credit IS '계약 당사자 신용 정보 테이블 - 신용평가 결과와 재무 상태를 관리';
COMMENT ON TABLE bms.contract_party_relationships IS '계약 당사자 관계 테이블 - 당사자 간의 법적/개인적 관계를 관리';
COMMENT ON TABLE bms.contract_party_changes IS '계약 당사자 변경 이력 테이블 - 당사자 정보 변경 과정을 추적';

COMMENT ON FUNCTION bms.add_party_contact(UUID, VARCHAR, VARCHAR, BOOLEAN, TEXT[]) IS '계약 당사자 연락처 추가 함수 - 새로운 연락처를 추가하고 주 연락처 설정';
COMMENT ON FUNCTION bms.evaluate_party_credit(UUID, DECIMAL, DECIMAL, DECIMAL, VARCHAR, INTEGER, UUID) IS '계약 당사자 신용 평가 함수 - 재무 정보를 바탕으로 신용도 평가';
COMMENT ON FUNCTION bms.create_party_relationship(UUID, UUID, UUID, VARCHAR, VARCHAR, VARCHAR, DECIMAL, TEXT[]) IS '계약 당사자 관계 설정 함수 - 당사자 간의 관계와 권한을 설정';
COMMENT ON FUNCTION bms.process_party_change(UUID, VARCHAR, VARCHAR, UUID, UUID, JSONB, DATE, UUID) IS '계약 당사자 변경 처리 함수 - 당사자 정보 변경 요청을 처리';
COMMENT ON FUNCTION bms.apply_party_change(UUID) IS '계약 당사자 변경 적용 함수 - 승인된 변경사항을 실제로 적용';

COMMENT ON VIEW bms.v_contract_party_summary IS '계약 당사자 종합 정보 뷰 - 당사자의 기본정보, 연락처, 신용정보, 관계정보를 종합 조회';

-- 스크립트 완료 메시지
SELECT '계약 당사자 관리 시스템 함수 생성이 완료되었습니다.' as message;