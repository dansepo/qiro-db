-- =====================================================
-- QIRO 조직 관리 자동화 및 비즈니스 로직 구현
-- 그룹 관리 비즈니스 로직 통합 함수
-- PostgreSQL 17.5 기반
-- 작성일: 2025-01-30
-- =====================================================

-- =====================================================
-- 1. 그룹 생성/수정/삭제 통합 함수들
-- =====================================================

-- 그룹 생성과 동시에 건물 및 담당자 배정하는 통합 함수
CREATE OR REPLACE FUNCTION create_group_with_assignments(
    p_company_id UUID,
    p_group_name VARCHAR(255),
    p_group_type building_group_type,
    p_description TEXT DEFAULT NULL,
    p_building_ids BIGINT[] DEFAULT ARRAY[]::BIGINT[],
    p_user_assignments JSONB DEFAULT '[]'::JSONB,
    p_created_by UUID DEFAULT NULL,
    p_group_settings JSONB DEFAULT '{}'
)
RETURNS UUID AS $
DECLARE
    new_group_id UUID;
    building_id BIGINT;
    user_assignment JSONB;
    assignment_user_id UUID;
    assignment_access_level access_level;
    assignment_reason TEXT;
    assignment_expires_at TIMESTAMPTZ;
BEGIN
    -- 입력 검증
    IF p_company_id IS NULL THEN
        RAISE EXCEPTION '회사 ID는 필수입니다.';
    END IF;
    
    IF p_group_name IS NULL OR LENGTH(TRIM(p_group_name)) < 2 THEN
        RAISE EXCEPTION '그룹명은 최소 2자 이상이어야 합니다.';
    END IF;
    
    -- 그룹 생성
    SELECT create_building_group(
        p_company_id,
        p_group_name,
        p_group_type,
        p_description,
        p_created_by,
        p_group_settings
    ) INTO new_group_id;
    
    -- 건물 배정
    IF array_length(p_building_ids, 1) > 0 THEN
        FOREACH building_id IN ARRAY p_building_ids
        LOOP
            BEGIN
                PERFORM assign_building_to_group(
                    new_group_id,
                    building_id,
                    p_created_by,
                    '그룹 생성 시 초기 배정',
                    NULL
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING '건물 % 배정 중 오류: %', building_id, SQLERRM;
            END;
        END LOOP;
    END IF;
    
    -- 사용자 배정
    -- p_user_assignments 형식: [{"user_id": "uuid", "access_level": "read", "reason": "text", "expires_at": "timestamp"}]
    IF jsonb_array_length(p_user_assignments) > 0 THEN
        FOR user_assignment IN SELECT * FROM jsonb_array_elements(p_user_assignments)
        LOOP
            BEGIN
                assignment_user_id := (user_assignment->>'user_id')::UUID;
                assignment_access_level := (user_assignment->>'access_level')::access_level;
                assignment_reason := user_assignment->>'reason';
                assignment_expires_at := CASE 
                    WHEN user_assignment->>'expires_at' IS NOT NULL 
                    THEN (user_assignment->>'expires_at')::TIMESTAMPTZ 
                    ELSE NULL 
                END;
                
                PERFORM assign_user_to_group(
                    assignment_user_id,
                    new_group_id,
                    COALESCE(assignment_access_level, 'read'),
                    p_created_by,
                    assignment_expires_at,
                    COALESCE(assignment_reason, '그룹 생성 시 초기 배정'),
                    NULL
                );
            EXCEPTION
                WHEN OTHERS THEN
                    RAISE WARNING '사용자 % 배정 중 오류: %', assignment_user_id, SQLERRM;
            END;
        END LOOP;
    END IF;
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'building_groups',
        'GROUP_CREATED_WITH_ASSIGNMENTS',
        new_group_id::TEXT,
        NULL,
        jsonb_build_object(
            'group_id', new_group_id,
            'group_name', p_group_name,
            'group_type', p_group_type,
            'building_count', array_length(p_building_ids, 1),
            'user_assignment_count', jsonb_array_length(p_user_assignments)
        ),
        p_created_by,
        now()
    );
    
    RAISE NOTICE '그룹 생성 완료: % (ID: %)', p_group_name, new_group_id;
    RETURN new_group_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '그룹 생성 중 오류 발생: %', SQLERRM;
END;
$ LANGUAGE plpgsql;

-- 그룹 완전 삭제 함수 (모든 관련 데이터 정리)
CREATE OR REPLACE FUNCTION delete_group_completely(
    p_group_id UUID,
    p_deleted_by UUID DEFAULT NULL,
    p_deletion_reason TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $
DECLARE
    group_info RECORD;
    building_count INTEGER;
    user_count INTEGER;
BEGIN
    -- 그룹 정보 조회
    SELECT group_name, company_id, is_active INTO group_info
    FROM building_groups
    WHERE group_id = p_group_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION '존재하지 않는 그룹입니다: %', p_group_id;
    END IF;
    
    -- 관련 배정 수 조회
    SELECT COUNT(*) INTO building_count
    FROM building_group_assignments
    WHERE group_id = p_group_id AND is_active = true;
    
    SELECT COUNT(*) INTO user_count
    FROM user_group_assignments
    WHERE group_id = p_group_id AND is_active = true;
    
    -- 모든 건물 배정 해제
    IF building_count > 0 THEN
        PERFORM unassign_all_buildings_from_group(
            p_group_id,
            p_deleted_by,
            COALESCE(p_deletion_reason, '그룹 삭제로 인한 일괄 해제')
        );
    END IF;
    
    -- 모든 사용자 배정 해제
    IF user_count > 0 THEN
        PERFORM unassign_all_users_from_group(
            p_group_id,
            p_deleted_by,
            COALESCE(p_deletion_reason, '그룹 삭제로 인한 일괄 해제')
        );
    END IF;
    
    -- 그룹 비활성화
    PERFORM deactivate_building_group(p_group_id, p_deleted_by);
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'building_groups',
        'GROUP_DELETED_COMPLETELY',
        p_group_id::TEXT,
        jsonb_build_object(
            'group_name', group_info.group_name,
            'company_id', group_info.company_id,
            'was_active', group_info.is_active
        ),
        jsonb_build_object(
            'deletion_reason', p_deletion_reason,
            'buildings_unassigned', building_count,
            'users_unassigned', user_count
        ),
        p_deleted_by,
        now()
    );
    
    RAISE NOTICE '그룹 완전 삭제 완료: % (건물: %개, 사용자: %개 해제)', 
        group_info.group_name, building_count, user_count;
    
    RETURN true;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 2. 건물 배정 및 해제 통합 함수들
-- =====================================================

-- 여러 건물을 한 번에 그룹에 배정하는 함수
CREATE OR REPLACE FUNCTION assign_multiple_buildings_to_group(
    p_group_id UUID,
    p_building_ids BIGINT[],
    p_assigned_by UUID DEFAULT NULL,
    p_assignment_reason TEXT DEFAULT NULL
)
RETURNS TABLE(
    building_id BIGINT,
    assignment_id UUID,
    success BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    building_id BIGINT;
    result_assignment_id UUID;
    result_success BOOLEAN;
    result_error TEXT;
BEGIN
    FOREACH building_id IN ARRAY p_building_ids
    LOOP
        BEGIN
            SELECT assign_building_to_group(
                p_group_id,
                building_id,
                p_assigned_by,
                p_assignment_reason,
                NULL
            ) INTO result_assignment_id;
            
            result_success := true;
            result_error := NULL;
            
        EXCEPTION
            WHEN OTHERS THEN
                result_assignment_id := NULL;
                result_success := false;
                result_error := SQLERRM;
        END;
        
        RETURN QUERY SELECT building_id, result_assignment_id, result_success, result_error;
    END LOOP;
END;
$ LANGUAGE plpgsql;

-- 건물을 여러 그룹에 한 번에 배정하는 함수
CREATE OR REPLACE FUNCTION assign_building_to_multiple_groups(
    p_building_id BIGINT,
    p_group_ids UUID[],
    p_assigned_by UUID DEFAULT NULL,
    p_assignment_reason TEXT DEFAULT NULL
)
RETURNS TABLE(
    group_id UUID,
    assignment_id UUID,
    success BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    group_id UUID;
    result_assignment_id UUID;
    result_success BOOLEAN;
    result_error TEXT;
BEGIN
    FOREACH group_id IN ARRAY p_group_ids
    LOOP
        BEGIN
            SELECT assign_building_to_group(
                group_id,
                p_building_id,
                p_assigned_by,
                p_assignment_reason,
                NULL
            ) INTO result_assignment_id;
            
            result_success := true;
            result_error := NULL;
            
        EXCEPTION
            WHEN OTHERS THEN
                result_assignment_id := NULL;
                result_success := false;
                result_error := SQLERRM;
        END;
        
        RETURN QUERY SELECT group_id, result_assignment_id, result_success, result_error;
    END LOOP;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 3. 담당자 배치 및 권한 관리 통합 함수들
-- =====================================================

-- 여러 사용자를 한 번에 그룹에 배정하는 함수
CREATE OR REPLACE FUNCTION assign_multiple_users_to_group(
    p_group_id UUID,
    p_user_assignments JSONB,
    p_assigned_by UUID DEFAULT NULL
)
RETURNS TABLE(
    user_id UUID,
    assignment_id UUID,
    success BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    user_assignment JSONB;
    assignment_user_id UUID;
    assignment_access_level access_level;
    assignment_reason TEXT;
    assignment_expires_at TIMESTAMPTZ;
    result_assignment_id UUID;
    result_success BOOLEAN;
    result_error TEXT;
BEGIN
    -- p_user_assignments 형식: [{"user_id": "uuid", "access_level": "read", "reason": "text", "expires_at": "timestamp"}]
    FOR user_assignment IN SELECT * FROM jsonb_array_elements(p_user_assignments)
    LOOP
        BEGIN
            assignment_user_id := (user_assignment->>'user_id')::UUID;
            assignment_access_level := COALESCE((user_assignment->>'access_level')::access_level, 'read');
            assignment_reason := user_assignment->>'reason';
            assignment_expires_at := CASE 
                WHEN user_assignment->>'expires_at' IS NOT NULL 
                THEN (user_assignment->>'expires_at')::TIMESTAMPTZ 
                ELSE NULL 
            END;
            
            SELECT assign_user_to_group(
                assignment_user_id,
                p_group_id,
                assignment_access_level,
                p_assigned_by,
                assignment_expires_at,
                assignment_reason,
                NULL
            ) INTO result_assignment_id;
            
            result_success := true;
            result_error := NULL;
            
        EXCEPTION
            WHEN OTHERS THEN
                result_assignment_id := NULL;
                result_success := false;
                result_error := SQLERRM;
        END;
        
        RETURN QUERY SELECT assignment_user_id, result_assignment_id, result_success, result_error;
    END LOOP;
END;
$ LANGUAGE plpgsql;

-- 사용자를 여러 그룹에 한 번에 배정하는 함수
CREATE OR REPLACE FUNCTION assign_user_to_multiple_groups(
    p_user_id UUID,
    p_group_assignments JSONB,
    p_assigned_by UUID DEFAULT NULL
)
RETURNS TABLE(
    group_id UUID,
    assignment_id UUID,
    success BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    group_assignment JSONB;
    assignment_group_id UUID;
    assignment_access_level access_level;
    assignment_reason TEXT;
    assignment_expires_at TIMESTAMPTZ;
    result_assignment_id UUID;
    result_success BOOLEAN;
    result_error TEXT;
BEGIN
    -- p_group_assignments 형식: [{"group_id": "uuid", "access_level": "read", "reason": "text", "expires_at": "timestamp"}]
    FOR group_assignment IN SELECT * FROM jsonb_array_elements(p_group_assignments)
    LOOP
        BEGIN
            assignment_group_id := (group_assignment->>'group_id')::UUID;
            assignment_access_level := COALESCE((group_assignment->>'access_level')::access_level, 'read');
            assignment_reason := group_assignment->>'reason';
            assignment_expires_at := CASE 
                WHEN group_assignment->>'expires_at' IS NOT NULL 
                THEN (group_assignment->>'expires_at')::TIMESTAMPTZ 
                ELSE NULL 
            END;
            
            SELECT assign_user_to_group(
                p_user_id,
                assignment_group_id,
                assignment_access_level,
                p_assigned_by,
                assignment_expires_at,
                assignment_reason,
                NULL
            ) INTO result_assignment_id;
            
            result_success := true;
            result_error := NULL;
            
        EXCEPTION
            WHEN OTHERS THEN
                result_assignment_id := NULL;
                result_success := false;
                result_error := SQLERRM;
        END;
        
        RETURN QUERY SELECT assignment_group_id, result_assignment_id, result_success, result_error;
    END LOOP;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 4. 그룹 구조 변경 및 이관 함수들
-- =====================================================

-- 그룹 간 건물 이관 함수
CREATE OR REPLACE FUNCTION transfer_buildings_between_groups(
    p_source_group_id UUID,
    p_target_group_id UUID,
    p_building_ids BIGINT[] DEFAULT NULL, -- NULL이면 모든 건물 이관
    p_transferred_by UUID DEFAULT NULL,
    p_transfer_reason TEXT DEFAULT NULL
)
RETURNS TABLE(
    building_id BIGINT,
    unassign_success BOOLEAN,
    assign_success BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    building_id BIGINT;
    buildings_to_transfer BIGINT[];
    unassign_success BOOLEAN;
    assign_success BOOLEAN;
    error_msg TEXT;
BEGIN
    -- 이관할 건물 목록 결정
    IF p_building_ids IS NULL THEN
        -- 모든 건물 이관
        SELECT array_agg(bga.building_id) INTO buildings_to_transfer
        FROM building_group_assignments bga
        WHERE bga.group_id = p_source_group_id AND bga.is_active = true;
    ELSE
        buildings_to_transfer := p_building_ids;
    END IF;
    
    -- 이관할 건물이 없으면 종료
    IF buildings_to_transfer IS NULL OR array_length(buildings_to_transfer, 1) = 0 THEN
        RAISE NOTICE '이관할 건물이 없습니다.';
        RETURN;
    END IF;
    
    -- 각 건물에 대해 이관 처리
    FOREACH building_id IN ARRAY buildings_to_transfer
    LOOP
        unassign_success := false;
        assign_success := false;
        error_msg := NULL;
        
        BEGIN
            -- 원본 그룹에서 해제
            PERFORM unassign_building_from_group(
                p_source_group_id,
                building_id,
                p_transferred_by,
                COALESCE(p_transfer_reason, '그룹 간 이관')
            );
            unassign_success := true;
            
            -- 대상 그룹에 배정
            PERFORM assign_building_to_group(
                p_target_group_id,
                building_id,
                p_transferred_by,
                COALESCE(p_transfer_reason, '그룹 간 이관'),
                NULL
            );
            assign_success := true;
            
        EXCEPTION
            WHEN OTHERS THEN
                error_msg := SQLERRM;
        END;
        
        RETURN QUERY SELECT building_id, unassign_success, assign_success, error_msg;
    END LOOP;
    
    -- 감사 로그 기록
    INSERT INTO audit_logs (
        table_name,
        operation,
        record_id,
        old_values,
        new_values,
        user_id,
        timestamp
    ) VALUES (
        'building_group_assignments',
        'BUILDINGS_TRANSFERRED',
        p_source_group_id::TEXT,
        jsonb_build_object('source_group_id', p_source_group_id),
        jsonb_build_object(
            'target_group_id', p_target_group_id,
            'building_count', array_length(buildings_to_transfer, 1),
            'transfer_reason', p_transfer_reason
        ),
        p_transferred_by,
        now()
    );
END;
$ LANGUAGE plpgsql;

-- 그룹 간 담당자 이관 함수
CREATE OR REPLACE FUNCTION transfer_users_between_groups(
    p_source_group_id UUID,
    p_target_group_id UUID,
    p_user_ids UUID[] DEFAULT NULL, -- NULL이면 모든 사용자 이관
    p_maintain_access_level BOOLEAN DEFAULT true,
    p_transferred_by UUID DEFAULT NULL,
    p_transfer_reason TEXT DEFAULT NULL
)
RETURNS TABLE(
    user_id UUID,
    unassign_success BOOLEAN,
    assign_success BOOLEAN,
    error_message TEXT
) AS $
DECLARE
    user_record RECORD;
    users_to_transfer RECORD[];
    unassign_success BOOLEAN;
    assign_success BOOLEAN;
    error_msg TEXT;
BEGIN
    -- 이관할 사용자 목록 결정
    IF p_user_ids IS NULL THEN
        -- 모든 사용자 이관
        SELECT array_agg(
            ROW(uga.user_id, uga.access_level)::RECORD
        ) INTO users_to_transfer
        FROM user_group_assignments uga
        WHERE uga.group_id = p_source_group_id AND uga.is_active = true;
    ELSE
        -- 지정된 사용자들의 정보 조회
        SELECT array_agg(
            ROW(uga.user_id, uga.access_level)::RECORD
        ) INTO users_to_transfer
        FROM user_group_assignments uga
        WHERE uga.group_id = p_source_group_id 
        AND uga.user_id = ANY(p_user_ids)
        AND uga.is_active = true;
    END IF;
    
    -- 이관할 사용자가 없으면 종료
    IF users_to_transfer IS NULL OR array_length(users_to_transfer, 1) = 0 THEN
        RAISE NOTICE '이관할 사용자가 없습니다.';
        RETURN;
    END IF;
    
    -- 각 사용자에 대해 이관 처리
    FOREACH user_record IN ARRAY users_to_transfer
    LOOP
        unassign_success := false;
        assign_success := false;
        error_msg := NULL;
        
        BEGIN
            -- 원본 그룹에서 해제
            PERFORM unassign_user_from_group(
                user_record.user_id,
                p_source_group_id,
                p_transferred_by,
                COALESCE(p_transfer_reason, '그룹 간 이관')
            );
            unassign_success := true;
            
            -- 대상 그룹에 배정
            PERFORM assign_user_to_group(
                user_record.user_id,
                p_target_group_id,
                CASE WHEN p_maintain_access_level THEN user_record.access_level ELSE 'read' END,
                p_transferred_by,
                NULL,
                COALESCE(p_transfer_reason, '그룹 간 이관'),
                NULL
            );
            assign_success := true;
            
        EXCEPTION
            WHEN OTHERS THEN
                error_msg := SQLERRM;
        END;
        
        RETURN QUERY SELECT user_record.user_id, unassign_success, assign_success, error_msg;
    END LOOP;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 5. 그룹 통계 및 분석 함수들
-- =====================================================

-- 회사의 그룹 관리 현황 요약 조회
CREATE OR REPLACE FUNCTION get_company_group_management_summary(p_company_id UUID)
RETURNS TABLE(
    total_groups BIGINT,
    active_groups BIGINT,
    total_buildings BIGINT,
    assigned_buildings BIGINT,
    total_users BIGINT,
    assigned_users BIGINT,
    group_types JSONB,
    access_levels JSONB
) AS $
BEGIN
    RETURN QUERY
    WITH group_stats AS (
        SELECT 
            COUNT(*) as total_groups,
            COUNT(*) FILTER (WHERE is_active = true) as active_groups
        FROM building_groups
        WHERE company_id = p_company_id
    ),
    building_stats AS (
        SELECT 
            COUNT(DISTINCT b.id) as total_buildings,
            COUNT(DISTINCT bga.building_id) as assigned_buildings
        FROM buildings b
        LEFT JOIN building_group_assignments bga ON b.id = bga.building_id AND bga.is_active = true
        LEFT JOIN building_groups bg ON bga.group_id = bg.group_id
        WHERE bg.company_id = p_company_id OR bg.company_id IS NULL
    ),
    user_stats AS (
        SELECT 
            COUNT(DISTINCT u.user_id) as total_users,
            COUNT(DISTINCT uga.user_id) as assigned_users
        FROM users u
        LEFT JOIN user_group_assignments uga ON u.user_id = uga.user_id AND uga.is_active = true
        LEFT JOIN building_groups bg ON uga.group_id = bg.group_id
        WHERE u.company_id = p_company_id
    ),
    group_type_stats AS (
        SELECT jsonb_object_agg(
            group_type::TEXT, 
            group_count
        ) as group_types
        FROM (
            SELECT 
                group_type,
                COUNT(*) as group_count
            FROM building_groups
            WHERE company_id = p_company_id AND is_active = true
            GROUP BY group_type
        ) gt
    ),
    access_level_stats AS (
        SELECT jsonb_object_agg(
            access_level::TEXT,
            user_count
        ) as access_levels
        FROM (
            SELECT 
                uga.access_level,
                COUNT(*) as user_count
            FROM user_group_assignments uga
            JOIN building_groups bg ON uga.group_id = bg.group_id
            WHERE bg.company_id = p_company_id AND uga.is_active = true
            GROUP BY uga.access_level
        ) al
    )
    SELECT 
        gs.total_groups,
        gs.active_groups,
        bs.total_buildings,
        bs.assigned_buildings,
        us.total_users,
        us.assigned_users,
        COALESCE(gts.group_types, '{}'::jsonb),
        COALESCE(als.access_levels, '{}'::jsonb)
    FROM group_stats gs
    CROSS JOIN building_stats bs
    CROSS JOIN user_stats us
    CROSS JOIN group_type_stats gts
    CROSS JOIN access_level_stats als;
END;
$ LANGUAGE plpgsql;

-- 그룹별 상세 현황 조회
CREATE OR REPLACE FUNCTION get_group_detailed_status(p_group_id UUID)
RETURNS TABLE(
    group_id UUID,
    group_name VARCHAR(255),
    group_type building_group_type,
    is_active BOOLEAN,
    building_count BIGINT,
    user_count BIGINT,
    admin_count BIGINT,
    write_count BIGINT,
    read_count BIGINT,
    recent_activity JSONB
) AS $
BEGIN
    RETURN QUERY
    SELECT 
        bg.group_id,
        bg.group_name,
        bg.group_type,
        bg.is_active,
        COALESCE(building_counts.building_count, 0) as building_count,
        COALESCE(user_counts.total_users, 0) as user_count,
        COALESCE(user_counts.admin_users, 0) as admin_count,
        COALESCE(user_counts.write_users, 0) as write_count,
        COALESCE(user_counts.read_users, 0) as read_count,
        COALESCE(recent_activities.activities, '[]'::jsonb) as recent_activity
    FROM building_groups bg
    LEFT JOIN (
        SELECT 
            bga.group_id,
            COUNT(*) as building_count
        FROM building_group_assignments bga
        WHERE bga.is_active = true
        GROUP BY bga.group_id
    ) building_counts ON bg.group_id = building_counts.group_id
    LEFT JOIN (
        SELECT 
            uga.group_id,
            COUNT(*) as total_users,
            COUNT(*) FILTER (WHERE uga.access_level = 'admin') as admin_users,
            COUNT(*) FILTER (WHERE uga.access_level = 'write') as write_users,
            COUNT(*) FILTER (WHERE uga.access_level = 'read') as read_users
        FROM user_group_assignments uga
        WHERE uga.is_active = true
        GROUP BY uga.group_id
    ) user_counts ON bg.group_id = user_counts.group_id
    LEFT JOIN (
        SELECT 
            group_id,
            jsonb_agg(
                jsonb_build_object(
                    'type', 'building_assignment',
                    'timestamp', assigned_at,
                    'user', assigned_by
                )
                ORDER BY assigned_at DESC
            ) as activities
        FROM (
            SELECT 
                bga.group_id,
                bga.assigned_at,
                bga.assigned_by
            FROM building_group_assignments bga
            WHERE bga.group_id = p_group_id
            ORDER BY bga.assigned_at DESC
            LIMIT 10
        ) recent_building_activities
        GROUP BY group_id
    ) recent_activities ON bg.group_id = recent_activities.group_id
    WHERE bg.group_id = p_group_id;
END;
$ LANGUAGE plpgsql;

-- =====================================================
-- 6. 코멘트 추가
-- =====================================================

COMMENT ON FUNCTION create_group_with_assignments(UUID, VARCHAR, building_group_type, TEXT, BIGINT[], JSONB, UUID, JSONB) IS '그룹 생성과 동시에 건물 및 담당자를 배정하는 통합 함수';
COMMENT ON FUNCTION delete_group_completely(UUID, UUID, TEXT) IS '그룹과 관련된 모든 배정을 해제하고 그룹을 완전히 삭제하는 함수';
COMMENT ON FUNCTION assign_multiple_buildings_to_group(UUID, BIGINT[], UUID, TEXT) IS '여러 건물을 한 번에 그룹에 배정하는 함수';
COMMENT ON FUNCTION assign_building_to_multiple_groups(BIGINT, UUID[], UUID, TEXT) IS '건물을 여러 그룹에 한 번에 배정하는 함수';
COMMENT ON FUNCTION assign_multiple_users_to_group(UUID, JSONB, UUID) IS '여러 사용자를 한 번에 그룹에 배정하는 함수';
COMMENT ON FUNCTION assign_user_to_multiple_groups(UUID, JSONB, UUID) IS '사용자를 여러 그룹에 한 번에 배정하는 함수';
COMMENT ON FUNCTION transfer_buildings_between_groups(UUID, UUID, BIGINT[], UUID, TEXT) IS '그룹 간 건물을 이관하는 함수';
COMMENT ON FUNCTION transfer_users_between_groups(UUID, UUID, UUID[], BOOLEAN, UUID, TEXT) IS '그룹 간 담당자를 이관하는 함수';
COMMENT ON FUNCTION get_company_group_management_summary(UUID) IS '회사의 그룹 관리 현황을 요약하여 조회하는 함수';
COMMENT ON FUNCTION get_group_detailed_status(UUID) IS '특정 그룹의 상세 현황을 조회하는 함수';