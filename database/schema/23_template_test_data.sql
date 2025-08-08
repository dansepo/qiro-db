-- =====================================================
-- 고지서 템플릿 시스템 테스트 데이터 생성 스크립트
-- =====================================================

-- 테스트 데이터 생성
DO $$
DECLARE
    company_rec RECORD;
    building_rec RECORD;
    template_count INTEGER := 0;
    section_count INTEGER := 0;
    field_count INTEGER := 0;
    usage_count INTEGER := 0;
    
    -- 템플릿 ID 저장용 변수들
    v_standard_template_id UUID;
    v_premium_template_id UUID;
    v_simple_template_id UUID;
    v_admin_user_id UUID;
BEGIN
    -- 각 회사에 대해 고지서 템플릿 시스템 데이터 생성
    FOR company_rec IN 
        SELECT company_id, company_name
        FROM bms.companies 
        WHERE company_id IN (
            SELECT DISTINCT company_id 
            FROM bms.buildings 
            LIMIT 3  -- 3개 회사만 테스트 데이터 생성
        )
    LOOP
        RAISE NOTICE '회사 % (%) 고지서 템플릿 시스템 데이터 생성 시작', company_rec.company_name, company_rec.company_id;
        
        -- 관리자 사용자 ID 조회
        SELECT user_id INTO v_admin_user_id 
        FROM bms.users 
        WHERE company_id = company_rec.company_id 
        LIMIT 1;
        
        -- 1. 기본 템플릿들 생성
        -- 표준 관리비 고지서 템플릿
        v_standard_template_id := gen_random_uuid();
        INSERT INTO bms.bill_templates (
            template_id, company_id, building_id,
            template_name, template_description, template_type, template_category,
            language_code, paper_size, orientation, layout_type,
            font_family, font_size, primary_color, secondary_color,
            template_structure, style_definitions,
            show_company_logo, show_qr_code, show_payment_info,
            version_number, is_default, is_active,
            created_by
        ) VALUES (
            v_standard_template_id, company_rec.company_id, NULL,
            '표준 관리비 고지서', '일반적인 관리비 고지서 템플릿', 'MAINTENANCE_FEE', 'STANDARD',
            'ko', 'A4', 'PORTRAIT', 'SINGLE_COLUMN',
            'NanumGothic', 12, '#2563eb', '#64748b',
            jsonb_build_object(
                'header', jsonb_build_object('height', 120, 'sections', jsonb_build_array('company_info', 'title')),
                'body', jsonb_build_object('sections', jsonb_build_array('recipient_info', 'bill_summary', 'fee_details')),
                'footer', jsonb_build_object('height', 80, 'sections', jsonb_build_array('payment_info', 'contact_info'))
            ),
            jsonb_build_object(
                'title_style', jsonb_build_object('font_size', 18, 'font_weight', 'BOLD', 'color', '#2563eb'),
                'header_style', jsonb_build_object('background_color', '#f8fafc', 'border_bottom', '2px solid #e2e8f0'),
                'table_style', jsonb_build_object('border', '1px solid #e2e8f0', 'alternate_row_color', '#f8fafc')
            ),
            true, true, true,
            '1.0', true, true,
            v_admin_user_id
        );
        
        -- 프리미엄 관리비 고지서 템플릿
        v_premium_template_id := gen_random_uuid();
        INSERT INTO bms.bill_templates (
            template_id, company_id, building_id,
            template_name, template_description, template_type, template_category,
            language_code, paper_size, orientation, layout_type,
            font_family, font_size, primary_color, secondary_color,
            template_structure, style_definitions,
            show_company_logo, show_qr_code, show_barcode, show_payment_info,
            multilingual_support, supported_languages,
            version_number, is_default, is_active,
            created_by
        ) VALUES (
            v_premium_template_id, company_rec.company_id, NULL,
            '프리미엄 관리비 고지서', '고급 디자인의 관리비 고지서 템플릿', 'MAINTENANCE_FEE', 'PREMIUM',
            'ko', 'A4', 'PORTRAIT', 'TWO_COLUMN',
            'NanumGothic', 11, '#1e40af', '#475569',
            jsonb_build_object(
                'header', jsonb_build_object('height', 140, 'sections', jsonb_build_array('company_info', 'title', 'period_info')),
                'body', jsonb_build_object('sections', jsonb_build_array('recipient_info', 'bill_summary', 'fee_details', 'usage_chart')),
                'footer', jsonb_build_object('height', 100, 'sections', jsonb_build_array('payment_info', 'qr_code', 'contact_info'))
            ),
            jsonb_build_object(
                'title_style', jsonb_build_object('font_size', 20, 'font_weight', 'BOLD', 'color', '#1e40af'),
                'header_style', jsonb_build_object('background_color', '#f1f5f9', 'border_bottom', '3px solid #1e40af'),
                'table_style', jsonb_build_object('border', '1px solid #cbd5e1', 'header_bg', '#e2e8f0'),
                'chart_style', jsonb_build_object('colors', jsonb_build_array('#1e40af', '#3b82f6', '#60a5fa'))
            ),
            true, true, true, true,
            true, ARRAY['ko', 'en'],
            '1.0', false, true,
            v_admin_user_id
        );
        
        -- 간단한 관리비 고지서 템플릿
        v_simple_template_id := gen_random_uuid();
        INSERT INTO bms.bill_templates (
            template_id, company_id, building_id,
            template_name, template_description, template_type, template_category,
            language_code, paper_size, orientation, layout_type,
            font_family, font_size, primary_color, secondary_color,
            template_structure, style_definitions,
            show_company_logo, show_qr_code, show_payment_info,
            version_number, is_default, is_active,
            created_by
        ) VALUES (
            v_simple_template_id, company_rec.company_id, NULL,
            '간단한 관리비 고지서', '최소한의 정보만 포함한 간단한 템플릿', 'MAINTENANCE_FEE', 'SIMPLE',
            'ko', 'A4', 'PORTRAIT', 'SINGLE_COLUMN',
            'NanumGothic', 11, '#059669', '#6b7280',
            jsonb_build_object(
                'header', jsonb_build_object('height', 80, 'sections', jsonb_build_array('title')),
                'body', jsonb_build_object('sections', jsonb_build_array('recipient_info', 'bill_summary')),
                'footer', jsonb_build_object('height', 60, 'sections', jsonb_build_array('payment_info'))
            ),
            jsonb_build_object(
                'title_style', jsonb_build_object('font_size', 16, 'font_weight', 'BOLD', 'color', '#059669'),
                'table_style', jsonb_build_object('border', '1px solid #d1d5db')
            ),
            false, true, true,
            '1.0', false, true,
            v_admin_user_id
        );
        
        template_count := template_count + 3;
        
        -- 2. 표준 템플릿의 섹션들 생성
        DECLARE
            v_header_section_id UUID := gen_random_uuid();
            v_recipient_section_id UUID := gen_random_uuid();
            v_summary_section_id UUID := gen_random_uuid();
            v_details_section_id UUID := gen_random_uuid();
            v_payment_section_id UUID := gen_random_uuid();
        BEGIN
            -- 헤더 섹션
            INSERT INTO bms.template_sections (
                section_id, template_id, company_id,
                section_name, section_type, section_title,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                background_color, border_style, border_width, border_color,
                content_type, content_source, content_template
            ) VALUES (
                v_header_section_id, v_standard_template_id, company_rec.company_id,
                'header', 'HEADER', '관리비 고지서',
                0, 0, 100, 120,
                1, true, true,
                '#f8fafc', 'SOLID', 1, '#e2e8f0',
                'TEXT', 'static', '<h1 style="text-align: center; color: #2563eb;">{{company_name}} 관리비 고지서</h1>'
            );
            
            -- 수신자 정보 섹션
            INSERT INTO bms.template_sections (
                section_id, template_id, company_id,
                section_name, section_type, section_title,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                content_type, content_source, content_template
            ) VALUES (
                v_recipient_section_id, v_standard_template_id, company_rec.company_id,
                'recipient_info', 'RECIPIENT_INFO', '수신자 정보',
                0, 120, 100, 80,
                2, true, true,
                'TABLE', 'database', 'recipient_info_table'
            );
            
            -- 고지서 요약 섹션
            INSERT INTO bms.template_sections (
                section_id, template_id, company_id,
                section_name, section_type, section_title,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                background_color, border_style, border_width, border_color,
                content_type, content_source, content_template
            ) VALUES (
                v_summary_section_id, v_standard_template_id, company_rec.company_id,
                'bill_summary', 'BILL_SUMMARY', '관리비 요약',
                0, 200, 100, 100,
                3, true, true,
                '#fefefe', 'SOLID', 1, '#d1d5db',
                'TABLE', 'database', 'bill_summary_table'
            );
            
            -- 관리비 상세 섹션
            INSERT INTO bms.template_sections (
                section_id, template_id, company_id,
                section_name, section_type, section_title,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                content_type, content_source, content_template
            ) VALUES (
                v_details_section_id, v_standard_template_id, company_rec.company_id,
                'fee_details', 'FEE_DETAILS', '관리비 상세 내역',
                0, 300, 100, 200,
                4, true, true,
                'TABLE', 'database', 'fee_details_table'
            );
            
            -- 결제 정보 섹션
            INSERT INTO bms.template_sections (
                section_id, template_id, company_id,
                section_name, section_type, section_title,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                background_color, border_style, border_width, border_color,
                content_type, content_source, content_template
            ) VALUES (
                v_payment_section_id, v_standard_template_id, company_rec.company_id,
                'payment_info', 'PAYMENT_INFO', '결제 정보',
                0, 500, 100, 80,
                5, true, true,
                '#f0f9ff', 'SOLID', 1, '#0ea5e9',
                'TABLE', 'database', 'payment_info_table'
            );
            
            section_count := section_count + 5;
            
            -- 3. 각 섹션의 필드들 생성
            -- 헤더 섹션 필드들
            INSERT INTO bms.template_fields (
                section_id, template_id, company_id,
                field_name, field_label, field_type, data_source,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                font_size, font_weight, font_color, text_align,
                data_format
            ) VALUES 
            (v_header_section_id, v_standard_template_id, company_rec.company_id,
             'company_name', '회사명', 'TEXT', 'companies.company_name',
             10, 10, 80, 30,
             1, true, true,
             18, 'BOLD', '#2563eb', 'CENTER',
             'text'),
            (v_header_section_id, v_standard_template_id, company_rec.company_id,
             'bill_title', '고지서 제목', 'TEXT', 'static',
             10, 50, 80, 25,
             2, true, true,
             16, 'BOLD', '#1f2937', 'CENTER',
             'text'),
            (v_header_section_id, v_standard_template_id, company_rec.company_id,
             'bill_period', '고지 기간', 'TEXT', 'calculations.calculation_period',
             10, 80, 80, 20,
             3, true, true,
             12, 'NORMAL', '#6b7280', 'CENTER',
             'YYYY년 MM월');
            
            -- 수신자 정보 섹션 필드들
            INSERT INTO bms.template_fields (
                section_id, template_id, company_id,
                field_name, field_label, field_type, data_source,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                font_size, font_weight, text_align,
                data_format
            ) VALUES 
            (v_recipient_section_id, v_standard_template_id, company_rec.company_id,
             'building_name', '건물명', 'TEXT', 'buildings.name',
             10, 10, 40, 20,
             1, true, true,
             12, 'NORMAL', 'LEFT',
             'text'),
            (v_recipient_section_id, v_standard_template_id, company_rec.company_id,
             'unit_number', '호실', 'TEXT', 'units.unit_number',
             60, 10, 30, 20,
             2, true, true,
             12, 'NORMAL', 'LEFT',
             'text'),
            (v_recipient_section_id, v_standard_template_id, company_rec.company_id,
             'unit_area', '면적', 'NUMBER', 'units.exclusive_area',
             10, 40, 40, 20,
             3, true, false,
             12, 'NORMAL', 'LEFT',
             '0.00㎡');
            
            -- 고지서 요약 섹션 필드들
            INSERT INTO bms.template_fields (
                section_id, template_id, company_id,
                field_name, field_label, field_type, data_source,
                position_x, position_y, width, height,
                display_order, is_visible, is_required,
                font_size, font_weight, text_align,
                data_format
            ) VALUES 
            (v_summary_section_id, v_standard_template_id, company_rec.company_id,
             'total_amount', '총 관리비', 'CURRENCY', 'unit_fees.total_amount',
             10, 10, 80, 25,
             1, true, true,
             16, 'BOLD', 'RIGHT',
             '#,##0원'),
            (v_summary_section_id, v_standard_template_id, company_rec.company_id,
             'due_date', '납부 기한', 'DATE', 'calculated',
             10, 45, 80, 20,
             2, true, true,
             12, 'NORMAL', 'RIGHT',
             'YYYY년 MM월 DD일'),
            (v_summary_section_id, v_standard_template_id, company_rec.company_id,
             'previous_balance', '전월 미납액', 'CURRENCY', 'calculated',
             10, 70, 80, 20,
             3, true, false,
             12, 'NORMAL', 'RIGHT',
             '#,##0원');
            
            field_count := field_count + 9;
        END;
        
        -- 4. 템플릿 사용 이력 생성 (시뮬레이션)
        FOR i IN 1..10 LOOP
            INSERT INTO bms.template_usage_history (
                template_id, company_id,
                used_for_type, used_for_id, usage_context,
                generated_format, generated_file_path, generated_file_size,
                generation_start_time, generation_end_time, generation_duration_ms,
                generation_status, generated_by
            ) VALUES (
                CASE 
                    WHEN i % 3 = 0 THEN v_standard_template_id
                    WHEN i % 3 = 1 THEN v_premium_template_id
                    ELSE v_simple_template_id
                END,
                company_rec.company_id,
                CASE WHEN random() < 0.8 THEN 'BILL_GENERATION' ELSE 'PREVIEW' END,
                gen_random_uuid(),
                jsonb_build_object(
                    'bill_period', '2025-' || LPAD((1 + random() * 12)::integer::text, 2, '0') || '-01',
                    'unit_count', (10 + random() * 50)::integer,
                    'generation_reason', 'monthly_billing'
                ),
                CASE WHEN random() < 0.9 THEN 'PDF' ELSE 'HTML' END,
                '/bills/' || company_rec.company_id || '/' || gen_random_uuid() || '.pdf',
                (500000 + random() * 2000000)::bigint,  -- 0.5MB ~ 2.5MB
                NOW() - (random() * 30 || ' days')::INTERVAL,
                NOW() - (random() * 30 || ' days')::INTERVAL + (random() * 5000 || ' milliseconds')::INTERVAL,
                (1000 + random() * 4000)::integer,  -- 1~5초
                CASE WHEN random() < 0.95 THEN 'SUCCESS' ELSE 'FAILED' END,
                v_admin_user_id
            );
            
            usage_count := usage_count + 1;
        END LOOP;
        
        RAISE NOTICE '회사 % 고지서 템플릿 시스템 데이터 생성 완료', company_rec.company_name;
    END LOOP;
    
    -- 최종 결과 출력
    RAISE NOTICE '=== 고지서 템플릿 시스템 테스트 데이터 생성 완료 ===';
    RAISE NOTICE '생성된 템플릿: %개', template_count;
    RAISE NOTICE '생성된 섹션: %개', section_count;
    RAISE NOTICE '생성된 필드: %개', field_count;
    RAISE NOTICE '생성된 사용 이력: %개', usage_count;
END;
$$;

-- 완료 메시지
SELECT '✅ 고지서 템플릿 시스템 테스트 데이터 생성이 완료되었습니다!' as result;