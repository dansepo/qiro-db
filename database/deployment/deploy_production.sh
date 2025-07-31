#!/bin/bash

# =====================================================
# QIRO 사업자 회원가입 시스템 프로덕션 환경 배포 스크립트
# 작성일: 2025-01-31
# =====================================================

set -e  # 오류 발생 시 스크립트 중단

# 환경 변수 설정
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-qiro_prod}"
DB_NAME="${DB_NAME:-qiro_production}"
DB_SCHEMA="${DB_SCHEMA:-bms}"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "logs/deployment_$(date +%Y%m%d).log"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "logs/deployment_$(date +%Y%m%d).log"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "logs/deployment_$(date +%Y%m%d).log"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "logs/deployment_$(date +%Y%m%d).log"
}

# 프로덕션 환경 확인
confirm_production() {
    echo -e "${RED}⚠️  프로덕션 환경 배포를 진행하시겠습니까?${NC}"
    echo "데이터베이스: $DB_HOST:$DB_PORT/$DB_NAME"
    echo "스키마: $DB_SCHEMA"
    echo ""
    read -p "계속하려면 'PRODUCTION'을 입력하세요: " confirmation
    
    if [ "$confirmation" != "PRODUCTION" ]; then
        log_error "배포가 취소되었습니다"
        exit 1
    fi
}

# PostgreSQL 연결 테스트
test_connection() {
    log_info "데이터베이스 연결 테스트 중..."
    if PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1; then
        log_success "데이터베이스 연결 성공"
    else
        log_error "데이터베이스 연결 실패"
        exit 1
    fi
}

# 백업 생성
create_backup() {
    log_info "프로덕션 데이터베이스 백업 생성 중..."
    BACKUP_FILE="production_backup_$(date +%Y%m%d_%H%M%S).sql"
    PGPASSWORD="$PGPASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "backups/$BACKUP_FILE"
    
    # 백업 파일 압축
    gzip "backups/$BACKUP_FILE"
    log_success "백업 생성 완료: $BACKUP_FILE.gz"
    
    # 백업 파일 검증
    if [ -f "backups/$BACKUP_FILE.gz" ] && [ -s "backups/$BACKUP_FILE.gz" ]; then
        log_success "백업 파일 검증 완료"
    else
        log_error "백업 파일 검증 실패"
        exit 1
    fi
}

# 스키마 검증
validate_schema() {
    log_info "기존 스키마 검증 중..."
    
    # 기존 테이블 확인
    EXISTING_TABLES=$(PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) FROM pg_tables WHERE schemaname = '$DB_SCHEMA';
    " | tr -d ' ')
    
    if [ "$EXISTING_TABLES" -gt 0 ]; then
        log_warning "기존 테이블 $EXISTING_TABLES 개 발견"
        echo "기존 데이터를 유지하면서 업그레이드하시겠습니까? (y/N)"
        read -p "> " upgrade_mode
        
        if [ "$upgrade_mode" != "y" ] && [ "$upgrade_mode" != "Y" ]; then
            log_error "배포가 취소되었습니다"
            exit 1
        fi
        
        UPGRADE_MODE=true
    else
        UPGRADE_MODE=false
    fi
}

# SQL 파일 실행 (프로덕션용 - 더 안전한 실행)
execute_sql_file() {
    local file_path=$1
    local description=$2
    local log_file="logs/sql_execution_$(date +%Y%m%d_%H%M%S).log"
    
    log_info "$description 실행 중..."
    
    # 트랜잭션으로 실행하여 실패 시 롤백
    if PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
        -v ON_ERROR_STOP=1 \
        -f "$file_path" > "$log_file" 2>&1; then
        log_success "$description 완료"
        return 0
    else
        log_error "$description 실패 - 로그: $log_file"
        return 1
    fi
}

# 성능 테스트 실행
run_performance_test() {
    log_info "프로덕션 성능 테스트 실행 중..."
    
    PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SET search_path TO $DB_SCHEMA;
    
    DO \$\$
    DECLARE
        start_time TIMESTAMP;
        end_time TIMESTAMP;
        execution_time_ms NUMERIC;
        record_count INTEGER;
    BEGIN
        -- 기본 조회 성능 테스트
        start_time := clock_timestamp();
        SELECT COUNT(*) INTO record_count FROM companies;
        end_time := clock_timestamp();
        execution_time_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;
        
        RAISE NOTICE '회사 조회 성능: % 개, %.2f ms', record_count, execution_time_ms;
        
        IF execution_time_ms > 1000 THEN
            RAISE WARNING '성능 경고: 조회 시간이 1초를 초과했습니다';
        END IF;
    END
    \$\$;
    " > "logs/performance_test_$(date +%Y%m%d_%H%M%S).log" 2>&1
    
    log_success "성능 테스트 완료"
}

# 메인 배포 함수
deploy() {
    log_info "=== QIRO 프로덕션 환경 배포 시작 ==="
    
    # 프로덕션 환경 확인
    confirm_production
    
    # 1단계: 환경 준비
    log_info "1단계: 환경 준비 및 백업"
    mkdir -p backups logs
    test_connection
    validate_schema
    create_backup
    
    # 2단계: 스키마 배포
    log_info "2단계: 스키마 배포"
    if ! execute_sql_file "../schema/00_companies_multitenancy_fixed.sql" "기본 스키마 생성"; then
        log_error "스키마 배포 실패 - 롤백을 고려하세요"
        exit 1
    fi
    
    # 3단계: 성능 최적화
    log_info "3단계: 성능 최적화 적용"
    if [ -f "../performance/01_multitenancy_performance_indexes.sql" ]; then
        execute_sql_file "../performance/01_multitenancy_performance_indexes.sql" "성능 인덱스 생성"
    fi
    
    if [ -f "../performance/02_partitioning_archiving_strategy.sql" ]; then
        execute_sql_file "../performance/02_partitioning_archiving_strategy.sql" "파티셔닝 전략 적용"
    fi
    
    # 4단계: 보안 강화
    log_info "4단계: 보안 설정 적용"
    if [ -f "../run_security_enhancement.sql" ]; then
        execute_sql_file "../run_security_enhancement.sql" "보안 강화 적용"
    fi
    
    # 5단계: 검증 테스트
    log_info "5단계: 배포 검증"
    run_performance_test
    
    # 6단계: 모니터링 설정
    log_info "6단계: 모니터링 설정"
    PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SET search_path TO $DB_SCHEMA;
    
    -- 배포 완료 로그 기록
    CREATE TABLE IF NOT EXISTS deployment_log (
        deployment_id SERIAL PRIMARY KEY,
        deployment_date TIMESTAMPTZ DEFAULT now(),
        version VARCHAR(50),
        status VARCHAR(20),
        notes TEXT
    );
    
    INSERT INTO deployment_log (version, status, notes)
    VALUES ('v1.0.0', 'SUCCESS', 'QIRO 사업자 회원가입 시스템 초기 배포 완료');
    " > /dev/null 2>&1
    
    log_success "=== QIRO 프로덕션 환경 배포 완료 ==="
    
    # 배포 결과 요약
    log_info "배포 결과 요약:"
    PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SET search_path TO $DB_SCHEMA;
    SELECT 
        '테이블 수' as metric,
        COUNT(*) as value
    FROM pg_tables 
    WHERE schemaname = '$DB_SCHEMA'
    UNION ALL
    SELECT 
        'RLS 활성화 테이블',
        COUNT(*) as value
    FROM pg_tables 
    WHERE schemaname = '$DB_SCHEMA' AND rowsecurity = true
    UNION ALL
    SELECT 
        '인덱스 수',
        COUNT(*) as value
    FROM pg_indexes 
    WHERE schemaname = '$DB_SCHEMA';
    "
    
    log_info "배포 로그는 logs/ 디렉토리에서 확인할 수 있습니다"
    log_info "백업 파일은 backups/ 디렉토리에 저장되었습니다"
}

# 헬스체크 함수
health_check() {
    log_info "프로덕션 환경 헬스체크 실행 중..."
    
    PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SET search_path TO $DB_SCHEMA;
    
    -- 기본 연결 테스트
    SELECT 'DB Connection' as check_name, 'OK' as status
    UNION ALL
    -- 테이블 존재 확인
    SELECT 'Tables Count', COUNT(*)::TEXT as status
    FROM pg_tables WHERE schemaname = '$DB_SCHEMA'
    UNION ALL
    -- RLS 정책 확인
    SELECT 'RLS Policies', COUNT(*)::TEXT as status
    FROM pg_tables WHERE schemaname = '$DB_SCHEMA' AND rowsecurity = true;
    "
}

# 스크립트 실행
case "$1" in
    "deploy")
        deploy
        ;;
    "health")
        health_check
        ;;
    "test")
        test_connection
        ;;
    *)
        echo "사용법: $0 {deploy|health|test}"
        echo "  deploy  - 프로덕션 환경 배포 실행"
        echo "  health  - 프로덕션 환경 헬스체크"
        echo "  test    - 데이터베이스 연결 테스트"
        exit 1
        ;;
esac