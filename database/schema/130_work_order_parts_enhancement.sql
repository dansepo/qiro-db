-- =====================================================
-- 작업 부품 사용 내역 관리 시스템 강화
-- 태스크 4.1: 작업 부품 사용 내역 관리 엔티티 구현
-- =====================================================

-- 1. 부품 사용 내역 상세 추적을 위한 테이블 생성
CREATE TABLE IF NOT EXISTS bms.work_order_part_usage (
    usage_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    material_usage_id UUID NOT NULL, -- work_order_materials 테이블 참조
    
    -- 사용 세부 정보
    usage_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    used_by UUID NOT NULL, -- 사용한 작업자
    usage_location TEXT, -- 사용 위치
    
    -- 수량 정보
    quantity_used DECIMAL(10,3) NOT NULL,
    unit_id UUID NOT NULL,
    
    -- 배치/시리얼 추적
    batch_number VARCHAR(50),
    serial_numbers JSONB, -- 시리얼 번호 배열
    
    -- 품질 정보
    quality_status VARCHAR(20) DEFAULT 'GOOD',
    quality_notes TEXT,
    
    -- 사용 목적 및 위치
    usage_purpose TEXT,
    installation_location TEXT,
    
    -- 폐기/반품 정보
    waste_quantity DECIMAL(10,3) DEFAULT 0,
    waste_reason TEXT,
    return_quantity DECIMAL(10,3) DEFAULT 0,
    return_reason TEXT,
    
    -- 비용 정보
    unit_cost DECIMAL(12,2) DEFAULT 0,
    total_cost DECIMAL(12,2) DEFAULT 0,
    
    -- 승인 정보
    approved_by UUID,
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- 상태
    usage_status VARCHAR(20) DEFAULT 'USED',
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_part_usage_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_part_usage_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_part_usage_material FOREIGN KEY (material_usage_id) REFERENCES bms.work_order_materials(material_usage_id) ON DELETE CASCADE,
    CONSTRAINT fk_part_usage_unit FOREIGN KEY (unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    
    -- 체크 제약 조건
    CONSTRAINT chk_usage_quantities CHECK (
        quantity_used > 0 AND
        waste_quantity >= 0 AND
        return_quantity >= 0 AND
        (quantity_used >= waste_quantity + return_quantity)
    ),
    CONSTRAINT chk_usage_costs CHECK (
        unit_cost >= 0 AND
        total_cost >= 0
    ),
    CONSTRAINT chk_quality_status_usage CHECK (quality_status IN (
        'GOOD', 'DAMAGED', 'DEFECTIVE', 'EXPIRED', 'RETURNED'
    )),
    CONSTRAINT chk_usage_status CHECK (usage_status IN (
        'USED', 'PARTIALLY_USED', 'RETURNED', 'WASTED', 'CANCELLED'
    ))
);

-- 2. 부품 재고 연동을 위한 재고 차감 로그 테이블
CREATE TABLE IF NOT EXISTS bms.inventory_deduction_log (
    deduction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 연관 정보
    work_order_id UUID NOT NULL,
    material_usage_id UUID NOT NULL,
    part_usage_id UUID NOT NULL,
    
    -- 재고 정보
    material_id UUID NOT NULL,
    location_id UUID NOT NULL,
    
    -- 차감 정보
    deduction_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    quantity_deducted DECIMAL(10,3) NOT NULL,
    unit_id UUID NOT NULL,
    
    -- 재고 상태 (차감 전/후)
    stock_before DECIMAL(15,3) NOT NULL,
    stock_after DECIMAL(15,3) NOT NULL,
    
    -- 배치/시리얼 정보
    batch_number VARCHAR(50),
    serial_numbers JSONB,
    
    -- 차감 유형
    deduction_type VARCHAR(20) DEFAULT 'WORK_ORDER',
    deduction_reason TEXT,
    
    -- 자동/수동 구분
    is_automatic BOOLEAN DEFAULT true,
    processed_by UUID,
    
    -- 상태
    deduction_status VARCHAR(20) DEFAULT 'COMPLETED',
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_deduction_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_deduction_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    CONSTRAINT fk_deduction_material_usage FOREIGN KEY (material_usage_id) REFERENCES bms.work_order_materials(material_usage_id) ON DELETE CASCADE,
    CONSTRAINT fk_deduction_part_usage FOREIGN KEY (part_usage_id) REFERENCES bms.work_order_part_usage(usage_id) ON DELETE CASCADE,
    CONSTRAINT fk_deduction_material FOREIGN KEY (material_id) REFERENCES bms.materials(material_id) ON DELETE RESTRICT,
    CONSTRAINT fk_deduction_location FOREIGN KEY (location_id) REFERENCES bms.storage_locations(location_id) ON DELETE RESTRICT,
    CONSTRAINT fk_deduction_unit FOREIGN KEY (unit_id) REFERENCES bms.material_units(unit_id) ON DELETE RESTRICT,
    
    -- 체크 제약 조건
    CONSTRAINT chk_deduction_quantities CHECK (
        quantity_deducted > 0 AND
        stock_before >= 0 AND
        stock_after >= 0 AND
        stock_after = stock_before - quantity_deducted
    ),
    CONSTRAINT chk_deduction_type CHECK (deduction_type IN (
        'WORK_ORDER', 'MAINTENANCE', 'EMERGENCY', 'ADJUSTMENT', 'TRANSFER'
    )),
    CONSTRAINT chk_deduction_status CHECK (deduction_status IN (
        'PENDING', 'COMPLETED', 'FAILED', 'REVERSED'
    ))
);

-- 3. 부품 사용 승인 워크플로우 테이블
CREATE TABLE IF NOT EXISTS bms.part_usage_approvals (
    approval_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    
    -- 승인 대상
    part_usage_id UUID NOT NULL,
    work_order_id UUID NOT NULL,
    
    -- 승인 요청 정보
    requested_by UUID NOT NULL,
    request_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    request_reason TEXT,
    
    -- 승인자 정보
    approver_id UUID,
    approval_level INTEGER DEFAULT 1,
    
    -- 승인 상태
    approval_status VARCHAR(20) DEFAULT 'PENDING',
    approval_date TIMESTAMP WITH TIME ZONE,
    approval_notes TEXT,
    
    -- 거부 정보
    rejection_reason TEXT,
    rejection_date TIMESTAMP WITH TIME ZONE,
    
    -- 승인 조건
    approval_conditions JSONB,
    budget_impact DECIMAL(12,2) DEFAULT 0,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    
    -- 제약 조건
    CONSTRAINT fk_part_approval_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id) ON DELETE CASCADE,
    CONSTRAINT fk_part_approval_usage FOREIGN KEY (part_usage_id) REFERENCES bms.work_order_part_usage(usage_id) ON DELETE CASCADE,
    CONSTRAINT fk_part_approval_work_order FOREIGN KEY (work_order_id) REFERENCES bms.work_orders(work_order_id) ON DELETE CASCADE,
    
    -- 체크 제약 조건
    CONSTRAINT chk_approval_status CHECK (approval_status IN (
        'PENDING', 'APPROVED', 'REJECTED', 'EXPIRED', 'CANCELLED'
    )),
    CONSTRAINT chk_approval_level CHECK (approval_level >= 1 AND approval_level <= 5)
);

-- 4. RLS 정책 설정
ALTER TABLE bms.work_order_part_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.inventory_deduction_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE bms.part_usage_approvals ENABLE ROW LEVEL SECURITY;

-- RLS 정책 생성
CREATE POLICY work_order_part_usage_isolation_policy ON bms.work_order_part_usage
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY inventory_deduction_log_isolation_policy ON bms.inventory_deduction_log
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

CREATE POLICY part_usage_approvals_isolation_policy ON bms.part_usage_approvals
    FOR ALL TO application_role
    USING (company_id = (current_setting('app.current_company_id', true))::uuid);

-- 5. 인덱스 생성
-- work_order_part_usage 인덱스
CREATE INDEX IF NOT EXISTS idx_part_usage_company_id ON bms.work_order_part_usage(company_id);
CREATE INDEX IF NOT EXISTS idx_part_usage_work_order ON bms.work_order_part_usage(work_order_id);
CREATE INDEX IF NOT EXISTS idx_part_usage_material ON bms.work_order_part_usage(material_usage_id);
CREATE INDEX IF NOT EXISTS idx_part_usage_date ON bms.work_order_part_usage(usage_date);
CREATE INDEX IF NOT EXISTS idx_part_usage_used_by ON bms.work_order_part_usage(used_by);
CREATE INDEX IF NOT EXISTS idx_part_usage_status ON bms.work_order_part_usage(usage_status);
CREATE INDEX IF NOT EXISTS idx_part_usage_batch ON bms.work_order_part_usage(batch_number);

-- inventory_deduction_log 인덱스
CREATE INDEX IF NOT EXISTS idx_deduction_company_id ON bms.inventory_deduction_log(company_id);
CREATE INDEX IF NOT EXISTS idx_deduction_work_order ON bms.inventory_deduction_log(work_order_id);
CREATE INDEX IF NOT EXISTS idx_deduction_material ON bms.inventory_deduction_log(material_id);
CREATE INDEX IF NOT EXISTS idx_deduction_location ON bms.inventory_deduction_log(location_id);
CREATE INDEX IF NOT EXISTS idx_deduction_date ON bms.inventory_deduction_log(deduction_date);
CREATE INDEX IF NOT EXISTS idx_deduction_type ON bms.inventory_deduction_log(deduction_type);
CREATE INDEX IF NOT EXISTS idx_deduction_status ON bms.inventory_deduction_log(deduction_status);

-- part_usage_approvals 인덱스
CREATE INDEX IF NOT EXISTS idx_part_approval_company_id ON bms.part_usage_approvals(company_id);
CREATE INDEX IF NOT EXISTS idx_part_approval_usage ON bms.part_usage_approvals(part_usage_id);
CREATE INDEX IF NOT EXISTS idx_part_approval_work_order ON bms.part_usage_approvals(work_order_id);
CREATE INDEX IF NOT EXISTS idx_part_approval_status ON bms.part_usage_approvals(approval_status);
CREATE INDEX IF NOT EXISTS idx_part_approval_requested_by ON bms.part_usage_approvals(requested_by);
CREATE INDEX IF NOT EXISTS idx_part_approval_approver ON bms.part_usage_approvals(approver_id);

-- 복합 인덱스
CREATE INDEX IF NOT EXISTS idx_part_usage_work_order_date ON bms.work_order_part_usage(work_order_id, usage_date);
CREATE INDEX IF NOT EXISTS idx_deduction_material_date ON bms.inventory_deduction_log(material_id, deduction_date);
CREATE INDEX IF NOT EXISTS idx_part_approval_status_date ON bms.part_usage_approvals(approval_status, request_date);

-- 6. 업데이트 트리거 설정
CREATE TRIGGER work_order_part_usage_updated_at_trigger
    BEFORE UPDATE ON bms.work_order_part_usage
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

CREATE TRIGGER part_usage_approvals_updated_at_trigger
    BEFORE UPDATE ON bms.part_usage_approvals
    FOR EACH ROW EXECUTE FUNCTION bms.update_updated_at_column();

-- 7. 테이블 코멘트
COMMENT ON TABLE bms.work_order_part_usage IS '작업 지시서 부품 사용 내역 - 부품 사용의 상세 추적 및 관리';
COMMENT ON TABLE bms.inventory_deduction_log IS '재고 차감 로그 - 부품 사용에 따른 재고 자동 차감 이력';
COMMENT ON TABLE bms.part_usage_approvals IS '부품 사용 승인 - 부품 사용에 대한 승인 워크플로우 관리';

-- 스크립트 완료 메시지
SELECT '작업 부품 사용 내역 관리 엔티티가 성공적으로 생성되었습니다.' as message;