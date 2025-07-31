#!/bin/bash

# =====================================================
# QIRO 사업자 회원가입 시스템 개발 환경 배포 스크립트
# 작성일: 2025-01-31
# =====================================================

set -e  # 오류 발생 시 스크립트 중단

# 환경 변수 설정
DB_HOST="${DB_HOST:-59.1.24.88}"
DB_PORT="${DB_PORT:-65432}"
DB_USER="${DB_USER:-qiro}"
DB_NAME="${DB_NAME:-qiro_dev}"
DB_SCHEMA="${DB_SCHEMA:-bms}"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
    log_info "데이터베이스 백업 생성 중..."
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    PGPASSWORD="$PGPASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "backups/$BACKUP_FILE"
    log_success "백업 생성 완료: $BACKUP_FILE"
}

# SQL 파일 실행
execute_sql_file() {
    local file_path=$1
    local description=$2
    
    log_info "$description 실행 중..."
    if PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file_path" > /dev/null 2>&1; then
        log_success "$description 완료"
    else
        log_error "$description 실패"
        return 1
    fi
}

# 메인 배포 함수
deploy() {
    log_info "=== QIRO 개발 환경 배포 시작 ==="
    
    # 1단계: 환경 준비
    log_info "1단계: 환경 준비 및 백업"
    test_connection
    mkdir -p backups logs
    create_backup
    
    # 2단계: 기본 스키마 설정
    log_info "2단계: 기본 스키마 및 확장 기능 설정"
    execute_sql_file "../schema/00_companies_multitenancy_fixed.sql" "기본 스키마 생성"
    
    # 3단계: 성능 최적화
    log_info "3단계: 성능 최적화 적용"
    if [ -f "../performance/01_multitenancy_performance_indexes.sql" ]; then
        execute_sql_file "../performance/01_multitenancy_performance_indexes.sql" "성능 인덱스 생성"
    fi
    
    # 4단계: 테스트 데이터 생성 (개발 환경만)
    log_info "4단계: 테스트 데이터 생성"
    execute_sql_file "../test_data/performance_test_data_fixed.sql" "성능 테스트 데이터 함수 생성"
    
    # 소규모 테스트 데이터 생성
    PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
    SET search_path TO $DB_SCHEMA;
    SELECT setup_performance_test_data(50, 2, 1, 1);
    " > /dev/null 2>&1
    
    # 5단계: 테스트 실행
    log_info "5단계: 배포 검증 테스트"
    execute_sql_file "../run_integration_tests_fixed.sql" "통합 테스트 실행"
    
    log_success "=== QIRO 개발 환경 배포 완료 ==="
    
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
        '총 회사 수',
        COUNT(*) as value
    FROM companies
    UNION ALL
    SELECT 
        '총 사용자 수',
        COUNT(*) as value
    FROM users;
    "
}

# 롤백 함수
rollback() {
    local backup_file=$1
    if [ -z "$backup_file" ]; then
        log_error "백업 파일을 지정해주세요"
        exit 1
    fi
    
    log_warning "롤백 실행 중: $backup_file"
    PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" < "backups/$backup_file"
    log_success "롤백 완료"
}

# 스크립트 실행
case "$1" in
    "deploy")
        deploy
        ;;
    "rollback")
        rollback "$2"
        ;;
    "test")
        test_connection
        ;;
    *)
        echo "사용법: $0 {deploy|rollback|test}"
        echo "  deploy  - 개발 환경 배포 실행"
        echo "  rollback [backup_file] - 지정된 백업으로 롤백"
        echo "  test    - 데이터베이스 연결 테스트"
        exit 1
        ;;
esac