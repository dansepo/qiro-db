#!/bin/bash

# 시설 관리 시스템 배포 스크립트
# 사용법: ./scripts/deploy.sh [환경] [버전]
# 예시: ./scripts/deploy.sh prod v1.0.0

set -e  # 오류 발생 시 스크립트 중단

# 색상 정의
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

# 사용법 출력
usage() {
    echo "사용법: $0 [환경] [버전]"
    echo "환경: dev, staging, prod"
    echo "버전: v1.0.0 형식의 버전 태그"
    echo ""
    echo "예시:"
    echo "  $0 dev v1.0.0"
    echo "  $0 staging v1.0.1"
    echo "  $0 prod v1.0.2"
    exit 1
}

# 파라미터 검증
if [ $# -ne 2 ]; then
    log_error "잘못된 파라미터 개수입니다."
    usage
fi

ENVIRONMENT=$1
VERSION=$2

# 환경 검증
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "지원하지 않는 환경입니다: $ENVIRONMENT"
    usage
fi

# 버전 형식 검증
if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "잘못된 버전 형식입니다: $VERSION (예: v1.0.0)"
    usage
fi

log_info "배포 시작: $ENVIRONMENT 환경, 버전 $VERSION"

# 환경별 설정
case $ENVIRONMENT in
    "dev")
        DOCKER_COMPOSE_FILE="docker-compose.dev.yml"
        ENV_FILE=".env.dev"
        ;;
    "staging")
        DOCKER_COMPOSE_FILE="docker-compose.staging.yml"
        ENV_FILE=".env.staging"
        ;;
    "prod")
        DOCKER_COMPOSE_FILE="docker-compose.yml"
        ENV_FILE=".env.prod"
        ;;
esac

# 환경 파일 존재 확인
if [ ! -f "$ENV_FILE" ]; then
    log_error "환경 파일이 존재하지 않습니다: $ENV_FILE"
    exit 1
fi

# Docker Compose 파일 존재 확인
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    log_error "Docker Compose 파일이 존재하지 않습니다: $DOCKER_COMPOSE_FILE"
    exit 1
fi

# Git 상태 확인
log_info "Git 상태 확인 중..."
if [ -n "$(git status --porcelain)" ]; then
    log_warning "커밋되지 않은 변경사항이 있습니다."
    read -p "계속 진행하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "배포가 취소되었습니다."
        exit 1
    fi
fi

# 버전 태그 확인
log_info "버전 태그 확인 중..."
if ! git rev-parse "$VERSION" >/dev/null 2>&1; then
    log_error "버전 태그가 존재하지 않습니다: $VERSION"
    exit 1
fi

# 버전 태그로 체크아웃
log_info "버전 $VERSION 으로 체크아웃 중..."
git checkout "$VERSION"

# 환경 변수 로드
log_info "환경 변수 로드 중..."
set -a  # 자동으로 변수를 export
source "$ENV_FILE"
set +a

# 필수 환경 변수 확인
required_vars=(
    "DATABASE_PASSWORD"
    "JWT_SECRET"
    "REDIS_PASSWORD"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        log_error "필수 환경 변수가 설정되지 않았습니다: $var"
        exit 1
    fi
done

# 백업 생성 (프로덕션 환경만)
if [ "$ENVIRONMENT" = "prod" ]; then
    log_info "데이터베이스 백업 생성 중..."
    BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"
    
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T postgres pg_dump \
        -U qiro -d qiro_prod > "backups/$BACKUP_FILE" || {
        log_error "데이터베이스 백업 실패"
        exit 1
    }
    
    log_success "백업 생성 완료: backups/$BACKUP_FILE"
fi

# 이전 컨테이너 중지 및 제거
log_info "기존 컨테이너 중지 중..."
docker-compose -f "$DOCKER_COMPOSE_FILE" down --remove-orphans

# 이미지 빌드
log_info "Docker 이미지 빌드 중..."
docker-compose -f "$DOCKER_COMPOSE_FILE" build --no-cache backend

# 이미지 태깅
log_info "이미지 태깅 중..."
docker tag qiro-backend:latest "qiro-backend:$VERSION"

# 컨테이너 시작
log_info "컨테이너 시작 중..."
docker-compose -f "$DOCKER_COMPOSE_FILE" up -d

# 헬스체크 대기
log_info "서비스 헬스체크 대기 중..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -f -s "http://localhost:8080/actuator/health" > /dev/null; then
        log_success "서비스가 정상적으로 시작되었습니다."
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        log_error "서비스 시작 실패 - 헬스체크 타임아웃"
        
        # 로그 출력
        log_info "컨테이너 로그:"
        docker-compose -f "$DOCKER_COMPOSE_FILE" logs --tail=50 backend
        
        exit 1
    fi
    
    log_info "헬스체크 대기 중... ($attempt/$max_attempts)"
    sleep 10
    ((attempt++))
done

# 배포 후 테스트
log_info "배포 후 테스트 실행 중..."

# API 응답 테스트
if curl -f -s "http://localhost:8080/api/v1/health" > /dev/null; then
    log_success "API 응답 테스트 통과"
else
    log_error "API 응답 테스트 실패"
    exit 1
fi

# 데이터베이스 연결 테스트
if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T postgres pg_isready -U qiro -d qiro_prod > /dev/null; then
    log_success "데이터베이스 연결 테스트 통과"
else
    log_error "데이터베이스 연결 테스트 실패"
    exit 1
fi

# Redis 연결 테스트
if docker-compose -f "$DOCKER_COMPOSE_FILE" exec -T redis redis-cli ping > /dev/null; then
    log_success "Redis 연결 테스트 통과"
else
    log_error "Redis 연결 테스트 실패"
    exit 1
fi

# 배포 정보 기록
log_info "배포 정보 기록 중..."
cat > "deployments/deployment_${ENVIRONMENT}_$(date +%Y%m%d_%H%M%S).json" << EOF
{
  "environment": "$ENVIRONMENT",
  "version": "$VERSION",
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "deployedBy": "$(whoami)",
  "gitCommit": "$(git rev-parse HEAD)",
  "gitBranch": "$(git rev-parse --abbrev-ref HEAD)",
  "dockerImages": {
    "backend": "qiro-backend:$VERSION",
    "postgres": "postgres:15-alpine",
    "redis": "redis:7-alpine",
    "nginx": "nginx:alpine"
  },
  "healthChecks": {
    "api": "PASS",
    "database": "PASS",
    "redis": "PASS"
  }
}
EOF

# 슬랙 알림 (선택사항)
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    log_info "슬랙 알림 발송 중..."
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚀 시설 관리 시스템 배포 완료\\n환경: $ENVIRONMENT\\n버전: $VERSION\\n시간: $(date)\"}" \
        "$SLACK_WEBHOOK_URL" || log_warning "슬랙 알림 발송 실패"
fi

# 정리 작업
log_info "정리 작업 수행 중..."

# 오래된 이미지 정리
docker image prune -f

# 오래된 백업 파일 정리 (30일 이상)
if [ "$ENVIRONMENT" = "prod" ]; then
    find backups/ -name "backup_*.sql" -mtime +30 -delete 2>/dev/null || true
fi

log_success "배포 완료!"
log_info "배포 정보:"
log_info "  환경: $ENVIRONMENT"
log_info "  버전: $VERSION"
log_info "  시간: $(date)"
log_info "  API URL: http://localhost:8080"

if [ "$ENVIRONMENT" = "prod" ]; then
    log_info "  백업 파일: backups/$BACKUP_FILE"
fi

log_info ""
log_info "유용한 명령어:"
log_info "  로그 확인: docker-compose -f $DOCKER_COMPOSE_FILE logs -f backend"
log_info "  상태 확인: docker-compose -f $DOCKER_COMPOSE_FILE ps"
log_info "  중지: docker-compose -f $DOCKER_COMPOSE_FILE down"
log_info "  재시작: docker-compose -f $DOCKER_COMPOSE_FILE restart backend"

# 모니터링 URL 출력
if [ "$ENVIRONMENT" = "prod" ]; then
    log_info ""
    log_info "모니터링 URL:"
    log_info "  Grafana: http://localhost:3000"
    log_info "  Prometheus: http://localhost:9090"
fi