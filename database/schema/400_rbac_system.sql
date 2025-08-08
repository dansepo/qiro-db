-- =====================================================
-- RBAC (Role-Based Access Control) 시스템 스키마
-- 작업: 18. 권한 관리 시스템 구현
-- =====================================================

-- 1. 역할 테이블
CREATE TABLE IF NOT EXISTS bms.roles (
    role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    role_name VARCHAR(100) NOT NULL,
    role_code VARCHAR(50) NOT NULL,
    description TEXT,
    is_system_role BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_by UUID,
    
    CONSTRAINT fk_roles_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id),
    CONSTRAINT uk_role_code_company UNIQUE (company_id, role_code),
    CONSTRAINT uk_role_name_company UNIQUE (company_id, role_name)
);

-- 2. 권한 테이블
CREATE TABLE IF NOT EXISTS bms.permissions (
    permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_name VARCHAR(100) NOT NULL,
    permission_code VARCHAR(100) NOT NULL,
    resource VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    is_system_permission BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uk_permission_code UNIQUE (permission_code),
    CONSTRAINT uk_permission_resource_action UNIQUE (resource, action)
);

-- 3. 역할-권한 매핑 테이블
CREATE TABLE IF NOT EXISTS bms.role_permissions (
    role_permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID NOT NULL,
    
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) REFERENCES bms.roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) REFERENCES bms.permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT uk_role_permission UNIQUE (role_id, permission_id)
);

-- 4. 사용자-역할 매핑 테이블
CREATE TABLE IF NOT EXISTS bms.user_roles (
    user_role_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    role_id UUID NOT NULL,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES bms.roles(role_id) ON DELETE CASCADE,
    CONSTRAINT uk_user_role UNIQUE (user_id, role_id)
);

-- 5. 리소스별 접근 권한 테이블 (시설물별 접근 권한)
CREATE TABLE IF NOT EXISTS bms.resource_permissions (
    resource_permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    resource_type VARCHAR(50) NOT NULL, -- FACILITY_ASSET, BUILDING, UNIT, LOCATION
    resource_id UUID NOT NULL,
    permission_type VARCHAR(50) NOT NULL, -- READ, WRITE, DELETE, MANAGE
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    granted_by UUID NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT uk_user_resource_permission UNIQUE (user_id, resource_type, resource_id, permission_type)
);

-- 6. 권한 그룹 테이블 (선택적)
CREATE TABLE IF NOT EXISTS bms.permission_groups (
    group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    group_name VARCHAR(100) NOT NULL,
    group_code VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL,
    
    CONSTRAINT fk_permission_groups_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id),
    CONSTRAINT uk_group_code_company UNIQUE (company_id, group_code)
);

-- 7. 권한 그룹-권한 매핑 테이블
CREATE TABLE IF NOT EXISTS bms.group_permissions (
    group_permission_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL,
    permission_id UUID NOT NULL,
    
    CONSTRAINT fk_group_permissions_group FOREIGN KEY (group_id) REFERENCES bms.permission_groups(group_id) ON DELETE CASCADE,
    CONSTRAINT fk_group_permissions_permission FOREIGN KEY (permission_id) REFERENCES bms.permissions(permission_id) ON DELETE CASCADE,
    CONSTRAINT uk_group_permission UNIQUE (group_id, permission_id)
);

-- 8. 역할-권한 그룹 매핑 테이블
CREATE TABLE IF NOT EXISTS bms.role_permission_groups (
    role_group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_id UUID NOT NULL,
    group_id UUID NOT NULL,
    
    CONSTRAINT fk_role_groups_role FOREIGN KEY (role_id) REFERENCES bms.roles(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_role_groups_group FOREIGN KEY (group_id) REFERENCES bms.permission_groups(group_id) ON DELETE CASCADE,
    CONSTRAINT uk_role_group UNIQUE (role_id, group_id)
);

-- 9. 권한 로그 테이블 (감사 추적)
CREATE TABLE IF NOT EXISTS bms.permission_audit_log (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL,
    user_id UUID NOT NULL,
    action VARCHAR(50) NOT NULL, -- GRANT, REVOKE, LOGIN, ACCESS_DENIED
    resource_type VARCHAR(50),
    resource_id UUID,
    permission_code VARCHAR(100),
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    performed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    performed_by UUID,
    
    CONSTRAINT fk_permission_audit_company FOREIGN KEY (company_id) REFERENCES bms.companies(company_id)
);

-- 10. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_roles_company ON bms.roles(company_id);
CREATE INDEX IF NOT EXISTS idx_roles_active ON bms.roles(company_id, is_active);
CREATE INDEX IF NOT EXISTS idx_role_permissions_role ON bms.role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission ON bms.role_permissions(permission_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_user ON bms.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON bms.user_roles(role_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON bms.user_roles(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_resource_permissions_user ON bms.resource_permissions(user_id);
CREATE INDEX IF NOT EXISTS idx_resource_permissions_resource ON bms.resource_permissions(resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_permission_audit_user ON bms.permission_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_permission_audit_performed_at ON bms.permission_audit_log(performed_at);

-- 11. 기본 권한 데이터 삽입
INSERT INTO bms.permissions (permission_name, permission_code, resource, action, description) VALUES
-- 고장 신고 권한
('고장 신고 조회', 'FAULT_REPORT_READ', 'FAULT_REPORT', 'READ', '고장 신고를 조회할 수 있는 권한'),
('고장 신고 생성', 'FAULT_REPORT_CREATE', 'FAULT_REPORT', 'CREATE', '고장 신고를 생성할 수 있는 권한'),
('고장 신고 수정', 'FAULT_REPORT_UPDATE', 'FAULT_REPORT', 'UPDATE', '고장 신고를 수정할 수 있는 권한'),
('고장 신고 삭제', 'FAULT_REPORT_DELETE', 'FAULT_REPORT', 'DELETE', '고장 신고를 삭제할 수 있는 권한'),
('고장 신고 배정', 'FAULT_REPORT_ASSIGN', 'FAULT_REPORT', 'ASSIGN', '고장 신고를 기술자에게 배정할 수 있는 권한'),

-- 작업 지시서 권한
('작업 지시서 조회', 'WORK_ORDER_READ', 'WORK_ORDER', 'READ', '작업 지시서를 조회할 수 있는 권한'),
('작업 지시서 생성', 'WORK_ORDER_CREATE', 'WORK_ORDER', 'CREATE', '작업 지시서를 생성할 수 있는 권한'),
('작업 지시서 수정', 'WORK_ORDER_UPDATE', 'WORK_ORDER', 'UPDATE', '작업 지시서를 수정할 수 있는 권한'),
('작업 지시서 삭제', 'WORK_ORDER_DELETE', 'WORK_ORDER', 'DELETE', '작업 지시서를 삭제할 수 있는 권한'),
('작업 지시서 실행', 'WORK_ORDER_EXECUTE', 'WORK_ORDER', 'EXECUTE', '작업 지시서를 실행할 수 있는 권한'),

-- 시설물 자산 권한
('시설물 자산 조회', 'FACILITY_ASSET_READ', 'FACILITY_ASSET', 'READ', '시설물 자산을 조회할 수 있는 권한'),
('시설물 자산 생성', 'FACILITY_ASSET_CREATE', 'FACILITY_ASSET', 'CREATE', '시설물 자산을 생성할 수 있는 권한'),
('시설물 자산 수정', 'FACILITY_ASSET_UPDATE', 'FACILITY_ASSET', 'UPDATE', '시설물 자산을 수정할 수 있는 권한'),
('시설물 자산 삭제', 'FACILITY_ASSET_DELETE', 'FACILITY_ASSET', 'DELETE', '시설물 자산을 삭제할 수 있는 권한'),

-- 정비 계획 권한
('정비 계획 조회', 'MAINTENANCE_PLAN_READ', 'MAINTENANCE_PLAN', 'READ', '정비 계획을 조회할 수 있는 권한'),
('정비 계획 생성', 'MAINTENANCE_PLAN_CREATE', 'MAINTENANCE_PLAN', 'CREATE', '정비 계획을 생성할 수 있는 권한'),
('정비 계획 수정', 'MAINTENANCE_PLAN_UPDATE', 'MAINTENANCE_PLAN', 'UPDATE', '정비 계획을 수정할 수 있는 권한'),
('정비 계획 삭제', 'MAINTENANCE_PLAN_DELETE', 'MAINTENANCE_PLAN', 'DELETE', '정비 계획을 삭제할 수 있는 권한'),
('정비 실행', 'MAINTENANCE_EXECUTE', 'MAINTENANCE_PLAN', 'EXECUTE', '정비를 실행할 수 있는 권한'),

-- 비용 관리 권한
('비용 조회', 'COST_READ', 'COST', 'READ', '비용을 조회할 수 있는 권한'),
('비용 기록', 'COST_CREATE', 'COST', 'CREATE', '비용을 기록할 수 있는 권한'),
('비용 수정', 'COST_UPDATE', 'COST', 'UPDATE', '비용을 수정할 수 있는 권한'),
('비용 승인', 'COST_APPROVE', 'COST', 'APPROVE', '비용을 승인할 수 있는 권한'),
('예산 관리', 'BUDGET_MANAGE', 'BUDGET', 'MANAGE', '예산을 관리할 수 있는 권한'),

-- 사용자 관리 권한
('사용자 조회', 'USER_READ', 'USER', 'READ', '사용자를 조회할 수 있는 권한'),
('사용자 생성', 'USER_CREATE', 'USER', 'CREATE', '사용자를 생성할 수 있는 권한'),
('사용자 수정', 'USER_UPDATE', 'USER', 'UPDATE', '사용자를 수정할 수 있는 권한'),
('사용자 삭제', 'USER_DELETE', 'USER', 'DELETE', '사용자를 삭제할 수 있는 권한'),

-- 역할 관리 권한
('역할 조회', 'ROLE_READ', 'ROLE', 'READ', '역할을 조회할 수 있는 권한'),
('역할 생성', 'ROLE_CREATE', 'ROLE', 'CREATE', '역할을 생성할 수 있는 권한'),
('역할 수정', 'ROLE_UPDATE', 'ROLE', 'UPDATE', '역할을 수정할 수 있는 권한'),
('역할 삭제', 'ROLE_DELETE', 'ROLE', 'DELETE', '역할을 삭제할 수 있는 권한'),
('역할 배정', 'ROLE_ASSIGN', 'ROLE', 'ASSIGN', '사용자에게 역할을 배정할 수 있는 권한'),

-- 시스템 관리 권한
('시스템 설정', 'SYSTEM_CONFIG', 'SYSTEM', 'CONFIG', '시스템 설정을 관리할 수 있는 권한'),
('감사 로그 조회', 'AUDIT_LOG_READ', 'AUDIT_LOG', 'READ', '감사 로그를 조회할 수 있는 권한'),
('대시보드 조회', 'DASHBOARD_READ', 'DASHBOARD', 'READ', '대시보드를 조회할 수 있는 권한'),
('보고서 생성', 'REPORT_CREATE', 'REPORT', 'CREATE', '보고서를 생성할 수 있는 권한')

ON CONFLICT (permission_code) DO NOTHING;

-- 12. 테이블 코멘트
COMMENT ON TABLE bms.roles IS '역할 테이블 - RBAC 시스템의 역할 정의';
COMMENT ON TABLE bms.permissions IS '권한 테이블 - 시스템의 모든 권한 정의';
COMMENT ON TABLE bms.role_permissions IS '역할-권한 매핑 테이블';
COMMENT ON TABLE bms.user_roles IS '사용자-역할 매핑 테이블';
COMMENT ON TABLE bms.resource_permissions IS '리소스별 접근 권한 테이블';
COMMENT ON TABLE bms.permission_groups IS '권한 그룹 테이블';
COMMENT ON TABLE bms.permission_audit_log IS '권한 감사 로그 테이블';

-- 13. 컬럼 코멘트
COMMENT ON COLUMN bms.roles.role_id IS '역할 고유 식별자';
COMMENT ON COLUMN bms.roles.company_id IS '회사 식별자';
COMMENT ON COLUMN bms.roles.role_name IS '역할 이름';
COMMENT ON COLUMN bms.roles.role_code IS '역할 코드';
COMMENT ON COLUMN bms.roles.is_system_role IS '시스템 기본 역할 여부';

COMMENT ON COLUMN bms.permissions.permission_id IS '권한 고유 식별자';
COMMENT ON COLUMN bms.permissions.permission_code IS '권한 코드';
COMMENT ON COLUMN bms.permissions.resource IS '리소스 타입';
COMMENT ON COLUMN bms.permissions.action IS '액션 타입';

COMMENT ON COLUMN bms.resource_permissions.resource_type IS '리소스 타입 (FACILITY_ASSET, BUILDING 등)';
COMMENT ON COLUMN bms.resource_permissions.resource_id IS '리소스 식별자';
COMMENT ON COLUMN bms.resource_permissions.permission_type IS '권한 타입 (READ, WRITE, DELETE, MANAGE)';

COMMENT ON COLUMN bms.permission_audit_log.action IS '수행된 액션 (GRANT, REVOKE, LOGIN, ACCESS_DENIED)';
COMMENT ON COLUMN bms.permission_audit_log.success IS '액션 성공 여부';
COMMENT ON COLUMN bms.permission_audit_log.ip_address IS '클라이언트 IP 주소';
COMMENT ON COLUMN bms.permission_audit_log.user_agent IS '클라이언트 User-Agent';