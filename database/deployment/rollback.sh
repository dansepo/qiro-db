#!/bin/bash

# =====================================================
# QIRO 사업자 회원가입 시스템 롤백 스크립트
# 작성일: 2025-01-31
# =====================================================

set -e  # 오류 발생 시 스크립트 중단

# 환경 변수 설정
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
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
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') $1"
}

# 백업 파일 목록 표시
list_backups() {
    log_info "사용 가능한 백업 파일:"
    echo ""
    
    if [ -d "backups" ]; then
        ls -la backups/ | grep -E "\.(sql|gz)$" | while read -r line; do
            echo "  $line"
        done
    else
        log_warning "백업 디렉토리가 존재하지 않습니다"
    fi
    echo ""
}

# 롤백 확인
confirm_rollback() {
    local backup_file=$1
    
    echo -e "${RED}⚠️  데이터베이스 롤백을 진행하시겠습니까?${NC}"
    echo "데이터베이스: $DB_HOST:$DB_PORT/$DB_NAME"
    echo "백업 파일: $backup_file"
    echo ""
    echo -e "${YELLOW}주의: 현재 데이터가 모두 손실될 수 있습니다!${NC}"
    echo ""
    read -p "계속하려면 'ROLLBACK'을 입력하세요: " confirmation
    
    if [ "$confirmation" != "ROLLBACK" ]; then
        log_error "롤백이 취소되었습니다"
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

# 현재 상태 백업
create_pre_rollback_backup() {
    log_info "롤백 전 현재 상태 백업 생성 중..."
    PRE_ROLLBACK_BACKUP="pre_rollback_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if PGPASSWORD="$PGPASSWORD" pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "backups/$PRE_ROLLBACK_BACKUP"; then
        log_success "롤백 전 백업 생성 완료: $PRE_ROLLBACK_BACKUP"
    else
        log_error "롤백 전 백업 생성 실패"
        exit 1
    fi
}

# 스키마 정리
cleanup_schema() {
    log_info "기존 스키마 정리 중..."
    
    PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" << EOF
-- 기존 테이블 삭제 (CASCADE로 의존성도 함께 삭제)
DROP SCHEMA IF EXISTS $DB_SCHEMA CASCADE;

-- 스키마 재생성
CREATE SCHEMA IF NOT EXISTS $DB_SCHEMA;
EOF
    
    log_success "스키마 정리 완료"
}

# 백업 파일 복원
restore_backup() {
    local backup_file=$1
    local full_path="backups/$backup_file"
    
    log_info "백업 파일 복원 중: $backup_file"
    
    # 파일 존재 확인
    if [ ! -f "$full_path" ]; then
        log_error "백업 파일을 찾을 수 없습니다: $full_path"
        exit 1
    fi
    
    # 압축 파일인지 확인
    if [[ "$backup_file" == *.gz ]]; then
        log_info "압축된 백업 파일 복원 중..."
        if gunzip -c "$full_path" | PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > "logs/rollback_$(date +%Y%m%d_%H%M%S).log" 2>&1; then
            log_success "백업 파일 복원 완료"
        else
            log_error "백업 파일 복원 실패"
            exit 1
        fi
    else
        log_info "일반 백업 파일 복원 중..."
        if PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" < "$full_path" > "logs/rollback_$(date +%Y%m%d_%H%M%S).log" 2>&1; then
            log_success "백업 파일 복원 완료"
        else
            log_error "백업 파일 복원 실패"
            exit 1
        fi
    fi
}

# 복원 후 검증
verify_rollback() {
    log_info "롤백 결과 검증 중..."
    
    # 기본 테이블 존재 확인
    TABLE_COUNT=$(PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "
    SELECT COUNT(*) FROM pg_tables WHERE schemaname = '$DB_SCHEMA';
    " | tr -d ' ')
    
    log_info "복원된 테이블 수: $TABLE_COUNT"
    
    if [ "$TABLE_COUNT" -gt 0 ]; then
        log_success "롤백 검증 완료"
        
        # 상세 정보 출력
        PGPASSWORD="$PGPASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "
        SET search_path TO $DB_SCHEMA;
        SELECT 
            '테이블 수' as metric,
            COUNT(*) as value
        FROM pg_tables 
        WHERE schemaname = '$DB_SCHEMA'
        UNION ALL
        SELECT 
            '인덱스 수',
            COUNT(*) as value
        FROM pg_indexes 
        WHERE schemaname = '$DB_SCHEMA';
        "
    else
        log_warning "복원된 테이블이 없습니다. 백업 파일을 확인하세요."
    fi
}

# 메인 롤백 함수
rollback() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        log_error "백업 파일을 지정해주세요"
        list_backups
        exit 1
    fi
    
    log_info "=== QIRO 데이터베이스 롤백 시작 ==="
    
    # 환경 준비
    mkdir -p logs
    test_connection
    confirm_rollback "$backup_file"
    
    # 롤백 전 백업 생성
    create_pre_rollback_backup
    
    # 스키마 정리
    cleanup_schema
    
    # 백업 복원
    restore_backup "$backup_file"
    
    # 검증
    verify_rollback
    
    log_success "=== QIRO 데이터베이스 롤백 완료 ==="
    log_info "롤백 로그는 logs/ 디렉토리에서 확인할 수 있습니다"
}

# 긴급 롤백 (확인 없이 실행)
emergency_rollback() {
    local backup_file=$1
    
    if [ -z "$backup_file" ]; then
        log_error "백업 파일을 지정해주세요"
        exit 1
    fi
    
    log_warning "=== 긴급 롤백 실행 ==="
    
    mkdir -p logs
    test_connection
    cleanup_schema
    restore_backup "$backup_file"
    verify_rollback
    
    log_success "=== 긴급 롤백 완료 ==="
}

# 스크립트 실행
case "$1" in
    "rollback")
        rollback "$2"
        ;;
    "emergency")
        emergency_rollback "$2"
        ;;
    "list")
        list_backups
        ;;
    "test")
        test_connection
        ;;
    *)
        echo "사용법: $0 {rollback|emergency|list|test} [backup_file]"
        echo ""
        echo "명령어:"
        echo "  rollback [backup_file]  - 지정된 백업으로 안전한 롤백"
        echo "  emergency [backup_file] - 확인 없이 긴급 롤백"
        echo "  list                    - 사용 가능한 백업 파일 목록"
        echo "  test                    - 데이터베이스 연결 테스트"
        echo ""
        echo "예시:"
        echo "  $0 list"
        echo "  $0 rollback backup_20250131_143022.sql"
        echo "  $0 emergency production_backup_20250131_120000.sql.gz"
        exit 1
        ;;
esac