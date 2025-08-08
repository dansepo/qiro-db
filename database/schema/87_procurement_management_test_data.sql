-- =====================================================
-- Procurement Management Test Data
-- Phase 4.4.3: Sample data for procurement management system
-- =====================================================

-- Set company context for testing
SET app.current_company_id = 'c1234567-89ab-cdef-0123-456789abcdef';

-- 1. Insert approval workflow
INSERT INTO bms.purchase_approval_workflow (
    company_id, workflow_name, workflow_type,
    min_amount, max_amount, approval_levels, is_active
) VALUES 
-- Basic approval workflow for purchase requests
('c1234567-89ab-cdef-0123-456789abcdef', '기본 구매요청 승인', 'PURCHASE_REQUEST',
 0, 1000000, '[
   {"level": 1, "approver_id": "u1234567-89ab-cdef-0123-456789abcdef", "approver_name": "부서장", "required": true},
   {"level": 2, "approver_id": "u2345678-9abc-def0-1234-56789abcdef0", "approver_name": "관리소장", "required": true}
 ]'::jsonb, true),

-- High value approval workflow
('c1234567-89ab-cdef-0123-456789abcdef', '고액 구매요청 승인', 'PURCHASE_REQUEST',
 1000000, NULL, '[
   {"level": 1, "approver_id": "u1234567-89ab-cdef-0123-456789abcdef", "approver_name": "부서장", "required": true},
   {"level": 2, "approver_id": "u2345678-9abc-def0-1234-56789abcdef0", "approver_name": "관리소장", "required": true},
   {"level": 3, "approver_id": "u3456789-abcd-ef01-2345-6789abcdef01", "approver_name": "본사승인", "required": true}
 ]'::jsonb, true),

-- Purchase order approval workflow
('c1234567-89ab-cdef-0123-456789abcdef', '발주서 승인', 'PURCHASE_ORDER',
 0, NULL, '[
   {"level": 1, "approver_id": "u1234567-89ab-cdef-0123-456789abcdef", "approver_name": "구매담당자", "required": true}
 ]'::jsonb, true),

-- Invoice approval workflow
('c1234567-89ab-cdef-0123-456789abcdef', '송장 승인', 'INVOICE_APPROVAL',
 0, NULL, '[
   {"level": 1, "approver_id": "u1234567-89ab-cdef-0123-456789abcdef", "approver_name": "회계담당자", "required": true}
 ]'::jsonb, true);

-- 2. Create purchase requests using function
DO $$
DECLARE
    v_request_id_1 UUID;
    v_request_id_2 UUID;
    v_request_id_3 UUID;
BEGIN
    -- Request 1: LED 전구 구매 요청
    SELECT bms.create_purchase_request(
        'c1234567-89ab-cdef-0123-456789abcdef',
        'LED 전구 교체용 구매',
        'MATERIAL',
        'u1234567-89ab-cdef-0123-456789abcdef',
        '시설관리팀',
        '1층 복도 LED 전구 교체 필요',
        'NORMAL',
        '2024-12-15'::DATE,
        '메인 창고',
        500000.00,
        'MAINT-2024'
    ) INTO v_request_id_1;
    
    -- Add items to request 1
    PERFORM bms.add_purchase_request_item(
        v_request_id_1,
        (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001'),
        'LED 전구 20W',
        50.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        15000.00,
        '{"wattage": "20W", "color_temp": "6500K", "lifespan": "50000h"}'::jsonb,
        '2024-12-15'::DATE,
        '1층 복도 조명 교체용'
    );
    
    PERFORM bms.add_purchase_request_item(
        v_request_id_1,
        (SELECT material_id FROM bms.materials WHERE material_code = 'FL-001'),
        '형광등 32W',
        20.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        25000.00,
        '{"wattage": "32W", "length": "1200mm", "type": "T8"}'::jsonb,
        '2024-12-15'::DATE,
        '지하 주차장 조명 교체용'
    );
    
    -- Request 2: 배관 자재 구매 요청
    SELECT bms.create_purchase_request(
        'c1234567-89ab-cdef-0123-456789abcdef',
        '배관 수리용 자재 구매',
        'MATERIAL',
        'u1234567-89ab-cdef-0123-456789abcdef',
        '시설관리팀',
        '화장실 급수관 교체 작업 필요',
        'HIGH',
        '2024-12-10'::DATE,
        '배관 자재실',
        800000.00,
        'REPAIR-2024'
    ) INTO v_request_id_2;
    
    -- Add items to request 2
    PERFORM bms.add_purchase_request_item(
        v_request_id_2,
        (SELECT material_id FROM bms.materials WHERE material_code = 'PIPE-001'),
        'PVC 파이프 50mm',
        100.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
        8000.00,
        '{"diameter": "50mm", "pressure": "10bar", "material": "PVC"}'::jsonb,
        '2024-12-10'::DATE,
        '화장실 급수관 교체용'
    );
    
    PERFORM bms.add_purchase_request_item(
        v_request_id_2,
        (SELECT material_id FROM bms.materials WHERE material_code = 'FIT-001'),
        '배관 피팅 세트',
        30.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        5000.00,
        '{"type": "elbow_tee_coupling", "size": "50mm", "material": "PVC"}'::jsonb,
        '2024-12-10'::DATE,
        '배관 연결용 피팅'
    );
    
    -- Request 3: 청소 용품 구매 요청
    SELECT bms.create_purchase_request(
        'c1234567-89ab-cdef-0123-456789abcdef',
        '월간 청소 용품 구매',
        'MATERIAL',
        'u1234567-89ab-cdef-0123-456789abcdef',
        '청소팀',
        '월간 정기 청소용품 보충',
        'NORMAL',
        '2024-12-20'::DATE,
        '청소 용품실',
        300000.00,
        'CLEAN-2024'
    ) INTO v_request_id_3;
    
    -- Add items to request 3
    PERFORM bms.add_purchase_request_item(
        v_request_id_3,
        (SELECT material_id FROM bms.materials WHERE material_code = 'CLEAN-001'),
        '다목적 세제',
        20.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'L'),
        12000.00,
        '{"type": "multi_purpose", "ph": "neutral", "eco_friendly": true}'::jsonb,
        '2024-12-20'::DATE,
        '일반 청소용'
    );
    
    PERFORM bms.add_purchase_request_item(
        v_request_id_3,
        (SELECT material_id FROM bms.materials WHERE material_code = 'TISSUE-001'),
        '화장지',
        100.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'ROLL'),
        1500.00,
        '{"ply": "2", "length": "30m", "recycled": true}'::jsonb,
        '2024-12-20'::DATE,
        '화장실용'
    );
    
    -- Submit requests for approval
    PERFORM bms.submit_purchase_request(v_request_id_1, 'u1234567-89ab-cdef-0123-456789abcdef');
    PERFORM bms.submit_purchase_request(v_request_id_2, 'u1234567-89ab-cdef-0123-456789abcdef');
    PERFORM bms.submit_purchase_request(v_request_id_3, 'u1234567-89ab-cdef-0123-456789abcdef');
END $$;

-- 3. Create quotations for the requests
DO $$
DECLARE
    v_request_id_1 UUID;
    v_request_id_2 UUID;
    v_quotation_id_1a UUID;
    v_quotation_id_1b UUID;
    v_quotation_id_2a UUID;
    v_quotation_id_2b UUID;
BEGIN
    -- Get request IDs
    SELECT request_id INTO v_request_id_1 FROM bms.purchase_requests WHERE request_title = 'LED 전구 교체용 구매';
    SELECT request_id INTO v_request_id_2 FROM bms.purchase_requests WHERE request_title = '배관 수리용 자재 구매';
    
    -- Quotation 1A: LED 전구 - 공급업체 A
    SELECT bms.create_purchase_quotation(
        'c1234567-89ab-cdef-0123-456789abcdef',
        'LED 전구 견적서 - 전기자재상',
        v_request_id_1,
        (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'SUP-001'),
        '2024-12-31'::DATE,
        '월말 결제',
        'EXW 공장도',
        '1년 품질보증',
        'u1234567-89ab-cdef-0123-456789abcdef'
    ) INTO v_quotation_id_1a;
    
    -- Add items to quotation 1A
    PERFORM bms.add_quotation_item(
        v_quotation_id_1a,
        (SELECT item_id FROM bms.purchase_request_items WHERE request_id = v_request_id_1 AND line_number = 1),
        (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001'),
        'LED 전구 20W 고효율',
        50.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        14500.00,
        'OSRAM',
        'LED-20W-6500K',
        '{"efficiency": "120lm/W", "warranty": "3years", "certification": "KC"}'::jsonb,
        7,
        36
    );
    
    PERFORM bms.add_quotation_item(
        v_quotation_id_1a,
        (SELECT item_id FROM bms.purchase_request_items WHERE request_id = v_request_id_1 AND line_number = 2),
        (SELECT material_id FROM bms.materials WHERE material_code = 'FL-001'),
        '형광등 32W T8',
        20.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        24000.00,
        'PHILIPS',
        'TL-D32W',
        '{"type": "T8", "color_temp": "4000K", "life": "20000h"}'::jsonb,
        5,
        12
    );
    
    -- Quotation 1B: LED 전구 - 공급업체 B
    SELECT bms.create_purchase_quotation(
        'c1234567-89ab-cdef-0123-456789abcdef',
        'LED 전구 견적서 - 조명전문업체',
        v_request_id_1,
        (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'SUP-002'),
        '2024-12-31'::DATE,
        '현금 결제시 3% 할인',
        'DDP 현장도',
        '2년 품질보증',
        'u1234567-89ab-cdef-0123-456789abcdef'
    ) INTO v_quotation_id_1b;
    
    -- Add items to quotation 1B
    PERFORM bms.add_quotation_item(
        v_quotation_id_1b,
        (SELECT item_id FROM bms.purchase_request_items WHERE request_id = v_request_id_1 AND line_number = 1),
        (SELECT material_id FROM bms.materials WHERE material_code = 'LED-001'),
        'LED 전구 20W 프리미엄',
        50.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        15500.00,
        'SAMSUNG',
        'LED-20W-PRO',
        '{"efficiency": "130lm/W", "warranty": "5years", "dimming": true}'::jsonb,
        3,
        60
    );
    
    PERFORM bms.add_quotation_item(
        v_quotation_id_1b,
        (SELECT item_id FROM bms.purchase_request_items WHERE request_id = v_request_id_1 AND line_number = 2),
        (SELECT material_id FROM bms.materials WHERE material_code = 'FL-001'),
        '형광등 32W 고효율',
        20.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        26000.00,
        'LG',
        'FL-32W-ECO',
        '{"type": "T8", "efficiency": "high", "mercury_free": true}'::jsonb,
        3,
        24
    );
    
    -- Quotation 2A: 배관 자재 - 공급업체 A
    SELECT bms.create_purchase_quotation(
        'c1234567-89ab-cdef-0123-456789abcdef',
        '배관 자재 견적서 - 배관자재상',
        v_request_id_2,
        (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'SUP-003'),
        '2024-12-25'::DATE,
        '30일 후 결제',
        'EXW 창고도',
        '6개월 품질보증',
        'u1234567-89ab-cdef-0123-456789abcdef'
    ) INTO v_quotation_id_2a;
    
    -- Add items to quotation 2A
    PERFORM bms.add_quotation_item(
        v_quotation_id_2a,
        (SELECT item_id FROM bms.purchase_request_items WHERE request_id = v_request_id_2 AND line_number = 1),
        (SELECT material_id FROM bms.materials WHERE material_code = 'PIPE-001'),
        'PVC 파이프 50mm KS규격',
        100.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'M'),
        7500.00,
        'KP케미칼',
        'PVC-50-10BAR',
        '{"standard": "KS", "pressure": "10bar", "color": "gray"}'::jsonb,
        2,
        6
    );
    
    PERFORM bms.add_quotation_item(
        v_quotation_id_2a,
        (SELECT item_id FROM bms.purchase_request_items WHERE request_id = v_request_id_2 AND line_number = 2),
        (SELECT material_id FROM bms.materials WHERE material_code = 'FIT-001'),
        '배관 피팅 세트 50mm',
        30.000000,
        (SELECT unit_id FROM bms.material_units WHERE unit_code = 'EA'),
        4800.00,
        'KP케미칼',
        'FIT-50-SET',
        '{"includes": "elbow_tee_coupling", "material": "PVC", "size": "50mm"}'::jsonb,
        2,
        6
    );
    
    -- Update quotation totals
    PERFORM bms.update_quotation_totals(v_quotation_id_1a);
    PERFORM bms.update_quotation_totals(v_quotation_id_1b);
    PERFORM bms.update_quotation_totals(v_quotation_id_2a);
    
    -- Select winning quotations
    PERFORM bms.select_quotation(v_quotation_id_1a, '가격 경쟁력 및 납기 우수', 'u1234567-89ab-cdef-0123-456789abcdef');
    PERFORM bms.select_quotation(v_quotation_id_2a, '기존 거래처로 품질 신뢰성 높음', 'u1234567-89ab-cdef-0123-456789abcdef');
END $$;

-- 4. Create purchase orders from selected quotations
DO $$
DECLARE
    v_quotation_id_1 UUID;
    v_quotation_id_2 UUID;
    v_order_id_1 UUID;
    v_order_id_2 UUID;
BEGIN
    -- Get selected quotation IDs
    SELECT quotation_id INTO v_quotation_id_1 
    FROM bms.purchase_quotations 
    WHERE quotation_title = 'LED 전구 견적서 - 전기자재상' AND is_selected = true;
    
    SELECT quotation_id INTO v_quotation_id_2 
    FROM bms.purchase_quotations 
    WHERE quotation_title = '배관 자재 견적서 - 배관자재상' AND is_selected = true;
    
    -- Create purchase orders
    SELECT bms.create_purchase_order_from_quotation(
        v_quotation_id_1,
        '서울시 강남구 테헤란로 123 ABC빌딩 지하1층 창고',
        '김창고',
        '02-1234-5678',
        '2024-12-20'::DATE,
        '평일 오전 9-12시 납품 가능',
        'u1234567-89ab-cdef-0123-456789abcdef'
    ) INTO v_order_id_1;
    
    SELECT bms.create_purchase_order_from_quotation(
        v_quotation_id_2,
        '서울시 강남구 테헤란로 123 ABC빌딩 지하1층 창고',
        '김창고',
        '02-1234-5678',
        '2024-12-15'::DATE,
        '긴급 배송 요청',
        'u1234567-89ab-cdef-0123-456789abcdef'
    ) INTO v_order_id_2;
    
    -- Approve purchase orders
    UPDATE bms.purchase_orders 
    SET 
        order_status = 'CONFIRMED',
        approved_by = 'u1234567-89ab-cdef-0123-456789abcdef',
        approval_date = NOW()
    WHERE order_id IN (v_order_id_1, v_order_id_2);
END $$;-- 5.
 Create goods receipts for delivered orders
DO $$
DECLARE
    v_order_id_1 UUID;
    v_order_id_2 UUID;
    v_receipt_id_1 UUID;
    v_receipt_id_2 UUID;
    v_order_item RECORD;
BEGIN
    -- Get order IDs
    SELECT po.order_id INTO v_order_id_1
    FROM bms.purchase_orders po
    JOIN bms.purchase_quotations pq ON po.quotation_id = pq.quotation_id
    WHERE pq.quotation_title = 'LED 전구 견적서 - 전기자재상';
    
    SELECT po.order_id INTO v_order_id_2
    FROM bms.purchase_orders po
    JOIN bms.purchase_quotations pq ON po.quotation_id = pq.quotation_id
    WHERE pq.quotation_title = '배관 자재 견적서 - 배관자재상';
    
    -- Create goods receipt for order 1 (LED 전구)
    SELECT bms.create_goods_receipt(
        v_order_id_1,
        'DN-2024-001',
        '2024-12-18'::DATE,
        '이배송',
        'u1234567-89ab-cdef-0123-456789abcdef',
        '메인 창고',
        true,
        'LED 전구 및 형광등 납품 완료'
    ) INTO v_receipt_id_1;
    
    -- Add receipt items for order 1
    FOR v_order_item IN 
        SELECT * FROM bms.purchase_order_items 
        WHERE order_id = v_order_id_1 
        ORDER BY line_number
    LOOP
        PERFORM bms.add_goods_receipt_item(
            v_receipt_id_1,
            v_order_item.order_item_id,
            v_order_item.ordered_quantity,
            v_order_item.ordered_quantity, -- All accepted
            0, -- No rejection
            'PASSED',
            'A',
            CASE 
                WHEN v_order_item.line_number = 1 THEN 'LED-BATCH-20241218'
                ELSE 'FL-BATCH-20241218'
            END,
            CASE 
                WHEN v_order_item.line_number = 1 THEN '2029-12-18'::DATE
                ELSE '2027-12-18'::DATE
            END,
            CASE 
                WHEN v_order_item.line_number = 1 THEN (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001')
                ELSE (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-001')
            END,
            '품질 검사 통과, 창고 입고 완료'
        );
    END LOOP;
    
    -- Create goods receipt for order 2 (배관 자재)
    SELECT bms.create_goods_receipt(
        v_order_id_2,
        'DN-2024-002',
        '2024-12-14'::DATE,
        '박운송',
        'u1234567-89ab-cdef-0123-456789abcdef',
        '배관 자재실',
        true,
        '배관 자재 납품 완료'
    ) INTO v_receipt_id_2;
    
    -- Add receipt items for order 2
    FOR v_order_item IN 
        SELECT * FROM bms.purchase_order_items 
        WHERE order_id = v_order_id_2 
        ORDER BY line_number
    LOOP
        PERFORM bms.add_goods_receipt_item(
            v_receipt_id_2,
            v_order_item.order_item_id,
            v_order_item.ordered_quantity,
            v_order_item.ordered_quantity, -- All accepted
            0, -- No rejection
            'PASSED',
            'A',
            CASE 
                WHEN v_order_item.line_number = 1 THEN 'PIPE-BATCH-20241214'
                ELSE 'FIT-BATCH-20241214'
            END,
            NULL, -- No expiry for pipes/fittings
            CASE 
                WHEN v_order_item.line_number = 1 THEN (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002')
                ELSE (SELECT location_id FROM bms.inventory_locations WHERE location_code = 'SR-002')
            END,
            '품질 검사 통과, 창고 입고 완료'
        );
    END LOOP;
    
    -- Update receipt status to completed
    UPDATE bms.goods_receipts 
    SET 
        receipt_status = 'ACCEPTED',
        inspection_completed = true,
        inspector_id = 'u1234567-89ab-cdef-0123-456789abcdef',
        inspection_date = NOW(),
        inspection_result = 'PASSED',
        inspection_notes = '모든 품목 품질 기준 통과'
    WHERE receipt_id IN (v_receipt_id_1, v_receipt_id_2);
    
    -- Update order delivery status
    UPDATE bms.purchase_orders 
    SET 
        delivery_status = 'DELIVERED',
        order_status = 'COMPLETED',
        completed_date = NOW()
    WHERE order_id IN (v_order_id_1, v_order_id_2);
END $$;

-- 6. Create purchase invoices
DO $$
DECLARE
    v_order_id_1 UUID;
    v_order_id_2 UUID;
    v_receipt_id_1 UUID;
    v_receipt_id_2 UUID;
    v_invoice_id_1 UUID;
    v_invoice_id_2 UUID;
    v_supplier_id_1 UUID;
    v_supplier_id_2 UUID;
BEGIN
    -- Get order and receipt IDs
    SELECT po.order_id, po.supplier_id INTO v_order_id_1, v_supplier_id_1
    FROM bms.purchase_orders po
    JOIN bms.purchase_quotations pq ON po.quotation_id = pq.quotation_id
    WHERE pq.quotation_title = 'LED 전구 견적서 - 전기자재상';
    
    SELECT po.order_id, po.supplier_id INTO v_order_id_2, v_supplier_id_2
    FROM bms.purchase_orders po
    JOIN bms.purchase_quotations pq ON po.quotation_id = pq.quotation_id
    WHERE pq.quotation_title = '배관 자재 견적서 - 배관자재상';
    
    SELECT receipt_id INTO v_receipt_id_1 FROM bms.goods_receipts WHERE order_id = v_order_id_1;
    SELECT receipt_id INTO v_receipt_id_2 FROM bms.goods_receipts WHERE order_id = v_order_id_2;
    
    -- Create invoice for order 1
    SELECT bms.create_purchase_invoice(
        'c1234567-89ab-cdef-0123-456789abcdef',
        'SUP001-2024-1201',
        '2024-12-18'::DATE,
        '2025-01-17'::DATE, -- 30 days payment term
        v_order_id_1,
        v_receipt_id_1,
        v_supplier_id_1,
        (SELECT subtotal_amount FROM bms.purchase_orders WHERE order_id = v_order_id_1),
        (SELECT tax_amount FROM bms.purchase_orders WHERE order_id = v_order_id_1),
        0, -- No discount
        '월말 결제',
        'BANK_TRANSFER',
        'u1234567-89ab-cdef-0123-456789abcdef'
    ) INTO v_invoice_id_1;
    
    -- Create invoice for order 2
    SELECT bms.create_purchase_invoice(
        'c1234567-89ab-cdef-0123-456789abcdef',
        'SUP003-2024-1202',
        '2024-12-14'::DATE,
        '2025-01-13'::DATE, -- 30 days payment term
        v_order_id_2,
        v_receipt_id_2,
        v_supplier_id_2,
        (SELECT subtotal_amount FROM bms.purchase_orders WHERE order_id = v_order_id_2),
        (SELECT tax_amount FROM bms.purchase_orders WHERE order_id = v_order_id_2),
        0, -- No discount
        '30일 후 결제',
        'BANK_TRANSFER',
        'u1234567-89ab-cdef-0123-456789abcdef'
    ) INTO v_invoice_id_2;
    
    -- Approve invoices
    PERFORM bms.approve_purchase_invoice(
        v_invoice_id_1,
        'u1234567-89ab-cdef-0123-456789abcdef',
        '검수 완료, 지급 승인'
    );
    
    PERFORM bms.approve_purchase_invoice(
        v_invoice_id_2,
        'u1234567-89ab-cdef-0123-456789abcdef',
        '검수 완료, 지급 승인'
    );
    
    -- Process payments
    PERFORM bms.process_invoice_payment(
        v_invoice_id_1,
        (SELECT total_amount FROM bms.purchase_invoices WHERE invoice_id = v_invoice_id_1),
        '2024-12-20 14:30:00+09'::TIMESTAMP WITH TIME ZONE,
        'TXN-20241220-001',
        'u1234567-89ab-cdef-0123-456789abcdef'
    );
    
    -- Partial payment for invoice 2
    PERFORM bms.process_invoice_payment(
        v_invoice_id_2,
        (SELECT total_amount * 0.5 FROM bms.purchase_invoices WHERE invoice_id = v_invoice_id_2),
        '2024-12-15 10:00:00+09'::TIMESTAMP WITH TIME ZONE,
        'TXN-20241215-001',
        'u1234567-89ab-cdef-0123-456789abcdef'
    );
END $$;

-- 7. Insert additional sample data for reporting
INSERT INTO bms.purchase_requests (
    company_id, request_number, request_title, request_type,
    requester_id, department, request_reason, urgency_level,
    required_date, estimated_total_amount, request_status,
    approval_status, created_by
) VALUES 
-- Emergency repair request
('c1234567-89ab-cdef-0123-456789abcdef', 'PR-2024-0004', '긴급 엘리베이터 부품 교체', 'EMERGENCY',
 'u1234567-89ab-cdef-0123-456789abcdef', '시설관리팀', '엘리베이터 고장으로 긴급 부품 교체 필요',
 'EMERGENCY', '2024-12-08'::DATE, 2500000.00, 'APPROVED', 'APPROVED',
 'u1234567-89ab-cdef-0123-456789abcdef'),

-- Service request
('c1234567-89ab-cdef-0123-456789abcdef', 'PR-2024-0005', '에어컨 정기 점검 서비스', 'SERVICE',
 'u1234567-89ab-cdef-0123-456789abcdef', '시설관리팀', '하절기 대비 에어컨 시스템 정기 점검',
 'NORMAL', '2024-12-25'::DATE, 800000.00, 'IN_APPROVAL', 'PENDING',
 'u1234567-89ab-cdef-0123-456789abcdef'),

-- Equipment request
('c1234567-89ab-cdef-0123-456789abcdef', 'PR-2024-0006', '신규 청소 장비 구매', 'EQUIPMENT',
 'u1234567-89ab-cdef-0123-456789abcdef', '청소팀', '기존 장비 노후화로 신규 장비 필요',
 'HIGH', '2025-01-15'::DATE, 1200000.00, 'DRAFT', 'PENDING',
 'u1234567-89ab-cdef-0123-456789abcdef');

-- Update some requests to different statuses for variety
UPDATE bms.purchase_requests 
SET 
    request_status = 'APPROVED',
    approval_status = 'APPROVED',
    final_approval_date = NOW() - INTERVAL '2 days'
WHERE request_number = 'PR-2024-0001';

UPDATE bms.purchase_requests 
SET 
    request_status = 'APPROVED',
    approval_status = 'APPROVED',
    final_approval_date = NOW() - INTERVAL '1 day'
WHERE request_number = 'PR-2024-0002';

-- Create some expired quotations for testing
INSERT INTO bms.purchase_quotations (
    company_id, quotation_number, quotation_title,
    supplier_id, quotation_date, quotation_valid_until,
    quotation_status, subtotal_amount, tax_amount, total_amount,
    created_by
) VALUES 
('c1234567-89ab-cdef-0123-456789abcdef', 'QT-2024-0005', '만료된 견적서 샘플',
 (SELECT supplier_id FROM bms.suppliers WHERE supplier_code = 'SUP-001'),
 '2024-11-01'::TIMESTAMP WITH TIME ZONE, '2024-11-30'::DATE,
 'EXPIRED', 500000.00, 50000.00, 550000.00,
 'u1234567-89ab-cdef-0123-456789abcdef');

-- Script completion message
SELECT 
    'Procurement Management test data inserted successfully!' as status,
    COUNT(DISTINCT pr.request_id) as purchase_requests,
    COUNT(DISTINCT pq.quotation_id) as quotations,
    COUNT(DISTINCT po.order_id) as purchase_orders,
    COUNT(DISTINCT gr.receipt_id) as goods_receipts,
    COUNT(DISTINCT pi.invoice_id) as invoices
FROM bms.purchase_requests pr
FULL OUTER JOIN bms.purchase_quotations pq ON pr.company_id = pq.company_id
FULL OUTER JOIN bms.purchase_orders po ON pr.company_id = po.company_id
FULL OUTER JOIN bms.goods_receipts gr ON pr.company_id = gr.company_id
FULL OUTER JOIN bms.purchase_invoices pi ON pr.company_id = pi.company_id
WHERE COALESCE(pr.company_id, pq.company_id, po.company_id, gr.company_id, pi.company_id) = 'c1234567-89ab-cdef-0123-456789abcdef';