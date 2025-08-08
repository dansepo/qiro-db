#!/bin/bash

# 시설 관리 시스템 프로덕션 배포 스크립트
# 사용법: ./scripts/deploy-prod.sh [version]

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

# 설정 변수
PROJECT_NAME="qiro-facility-management"
DOCKER_REGISTRY="registry.qiro.com"
DOCKER_IMAGE_NAME="qiro-backend"
DEPLOYMENT_ENV="prod"
HEALTH_CHECK_URL="https://api.qiro.com/api/actuator/health"
BACKUP_RETENTION_DAYS=7

# 버전 파라미터 확인
VERSION=${1:-$(date +%Y%m%d-%H%M%S)}
DOCKER_TAG="${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${VERSION}"
LATEST_TAG="${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:latest"

log_info "시설 관리 시스템 프로덕션 배포 시작"
log_info "버전: ${VERSION}"
log_info "Docker 이미지: ${DOCKER_TAG}"

# 1. 사전 검사
log_info "1. 사전 검사 수행 중..."

# Git 상태 확인
if [ -n "$(git status --porcelain)" ]; then
    log_warning "Git 작업 디렉토리에 커밋되지 않은 변경사항이 있습니다."
    read -p "계속 진행하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "배포가 취소되었습니다."
        exit 1
    fi
fi

# Docker 데몬 확인
if ! docker info > /dev/null 2>&1; then
    log_error "Docker 데몬이 실행되고 있지 않습니다."
    exit 1
fi

# 필수 환경 변수 확인
required_vars=(
    "PROD_DB_URL"
    "PROD_DB_USERNAME" 
    "PROD_DB_PASSWORD"
    "JWT_SECRET"
    "REDIS_HOST"
    "REDIS_PASSWORD"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        log_error "필수 환경 변수 ${var}가 설정되지 않았습니다."
        exit 1
    fi
done

log_success "사전 검사 완료"

# 2. 테스트 실행
log_info "2. 테스트 실행 중..."

cd backend

# 단위 테스트
log_info "단위 테스트 실행 중..."
if ! ./gradlew clean unitTest; then
    log_error "단위 테스트 실패"
    exit 1
fi

# 통합 테스트
log_info "통합 테스트 실행 중..."
if ! ./gradlew integrationTest; then
    log_error "통합 테스트 실패"
    exit 1
fi

log_success "모든 테스트 통과"

# 3. 애플리케이션 빌드
log_info "3. 애플리케이션 빌드 중..."

if ! ./gradlew buildForDeploy -Pprofile=prod; then
    log_error "애플리케이션 빌드 실패"
    exit 1
fi

JAR_FILE=$(find build/libs -name "*.jar" | head -1)
if [ ! -f "$JAR_FILE" ]; then
    log_error "빌드된 JAR 파일을 찾을 수 없습니다."
    exit 1
fi

JAR_SIZE=$(du -h "$JAR_FILE" | cut -f1)
log_success "애플리케이션 빌드 완료 (크기: ${JAR_SIZE})"

cd ..

# 4. Docker 이미지 빌드
log_info "4. Docker 이미지 빌드 중..."

# Dockerfile 생성 (프로덕션용)
cat > backend/Dockerfile.prod << EOF
FROM openjdk:21-jre-slim

# 시스템 패키지 업데이트 및 필수 도구 설치
RUN apt-get update && apt-get install -y \\
    curl \\
    wget \\
    dumb-init \\
    && rm -rf /var/lib/apt/lists/*

# 애플리케이션 사용자 생성
RUN groupadd -r qiro && useradd -r -g qiro qiro

# 작업 디렉토리 설정
WORKDIR /app

# JAR 파일 복사
COPY build/libs/*.jar app.jar

# 로그 및 업로드 디렉토리 생성
RUN mkdir -p /app/logs /app/uploads /app/thumbnails && \\
    chown -R qiro:qiro /app

# 사용자 변경
USER qiro

# 헬스체크 설정
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \\
    CMD curl -f http://localhost:8080/api/actuator/health || exit 1

# JVM 옵션 설정
ENV JAVA_OPTS="-Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -Dspring.profiles.active=prod"

# 포트 노출
EXPOSE 8080

# 애플리케이션 실행
ENTRYPOINT ["dumb-init", "--"]
CMD ["sh", "-c", "java \$JAVA_OPTS -jar app.jar"]
EOF

# Docker 이미지 빌드
if ! docker build -f backend/Dockerfile.prod -t "$DOCKER_TAG" -t "$LATEST_TAG" backend/; then
    log_error "Docker 이미지 빌드 실패"
    exit 1
fi

log_success "Docker 이미지 빌드 완료"

# 5. 보안 스캔 (선택사항)
log_info "5. 보안 스캔 수행 중..."

if command -v trivy &> /dev/null; then
    log_info "Trivy를 사용한 보안 스캔 실행 중..."
    if ! trivy image --exit-code 1 --severity HIGH,CRITICAL "$DOCKER_TAG"; then
        log_warning "보안 취약점이 발견되었습니다. 계속 진행하시겠습니까?"
        read -p "(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_error "배포가 취소되었습니다."
            exit 1
        fi
    fi
else
    log_warning "Trivy가 설치되지 않아 보안 스캔을 건너뜁니다."
fi

# 6. Docker 레지스트리에 푸시
log_info "6. Docker 이미지 푸시 중..."

# Docker 레지스트리 로그인
if ! docker login "$DOCKER_REGISTRY"; then
    log_error "Docker 레지스트리 로그인 실패"
    exit 1
fi

# 이미지 푸시
if ! docker push "$DOCKER_TAG"; then
    log_error "Docker 이미지 푸시 실패"
    exit 1
fi

if ! docker push "$LATEST_TAG"; then
    log_error "Latest 태그 푸시 실패"
    exit 1
fi

log_success "Docker 이미지 푸시 완료"

# 7. 데이터베이스 백업 (배포 전)
log_info "7. 데이터베이스 백업 수행 중..."

BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${BACKUP_TIMESTAMP}.sql"

# PostgreSQL 백업
if ! PGPASSWORD="$PROD_DB_PASSWORD" pg_dump -h "$PROD_DB_HOST" -U "$PROD_DB_USERNAME" -d "$PROD_DB_NAME" > "/tmp/$BACKUP_FILE"; then
    log_error "데이터베이스 백업 실패"
    exit 1
fi

# 백업 파일을 S3에 업로드 (선택사항)
if command -v aws &> /dev/null && [ -n "$BACKUP_S3_BUCKET" ]; then
    aws s3 cp "/tmp/$BACKUP_FILE" "s3://$BACKUP_S3_BUCKET/database-backups/$BACKUP_FILE"
    log_success "데이터베이스 백업이 S3에 업로드되었습니다."
fi

log_success "데이터베이스 백업 완료"

# 8. Kubernetes 배포 (또는 Docker Compose)
log_info "8. 애플리케이션 배포 중..."

# Kubernetes 배포 매니페스트 생성
cat > k8s-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: qiro-backend
  namespace: production
  labels:
    app: qiro-backend
    version: ${VERSION}
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: qiro-backend
  template:
    metadata:
      labels:
        app: qiro-backend
        version: ${VERSION}
    spec:
      containers:
      - name: qiro-backend
        image: ${DOCKER_TAG}
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        - name: PROD_DB_URL
          valueFrom:
            secretKeyRef:
              name: qiro-secrets
              key: db-url
        - name: PROD_DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: qiro-secrets
              key: db-username
        - name: PROD_DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: qiro-secrets
              key: db-password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: qiro-secrets
              key: jwt-secret
        - name: REDIS_HOST
          valueFrom:
            secretKeyRef:
              name: qiro-secrets
              key: redis-host
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: qiro-secrets
              key: redis-password
        resources:
          requests:
            memory: "2Gi"
            cpu: "500m"
          limits:
            memory: "4Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /api/actuator/health/liveness
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 30
          timeoutSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /api/actuator/health/readiness
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        volumeMounts:
        - name: logs
          mountPath: /app/logs
        - name: uploads
          mountPath: /app/uploads
      volumes:
      - name: logs
        persistentVolumeClaim:
          claimName: qiro-logs-pvc
      - name: uploads
        persistentVolumeClaim:
          claimName: qiro-uploads-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: qiro-backend-service
  namespace: production
spec:
  selector:
    app: qiro-backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: ClusterIP
EOF

# Kubernetes 배포 실행
if command -v kubectl &> /dev/null; then
    log_info "Kubernetes에 배포 중..."
    
    if ! kubectl apply -f k8s-deployment.yaml; then
        log_error "Kubernetes 배포 실패"
        exit 1
    fi
    
    # 배포 상태 확인
    log_info "배포 상태 확인 중..."
    kubectl rollout status deployment/qiro-backend -n production --timeout=600s
    
    log_success "Kubernetes 배포 완료"
else
    log_warning "kubectl이 설치되지 않아 Kubernetes 배포를 건너뜁니다."
fi

# 9. 헬스체크 및 배포 검증
log_info "9. 배포 검증 중..."

# 헬스체크 대기
log_info "애플리케이션 시작 대기 중..."
sleep 60

# 헬스체크 수행
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s "$HEALTH_CHECK_URL" > /dev/null; then
        log_success "헬스체크 성공"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        log_info "헬스체크 재시도 ($RETRY_COUNT/$MAX_RETRIES)..."
        sleep 30
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    log_error "헬스체크 실패 - 배포 롤백을 고려하세요"
    exit 1
fi

# API 기능 테스트
log_info "API 기능 테스트 수행 중..."

# 기본 API 엔드포인트 테스트
if ! curl -f -s "https://api.qiro.com/api/v1/health" > /dev/null; then
    log_error "API 기능 테스트 실패"
    exit 1
fi

log_success "배포 검증 완료"

# 10. 정리 작업
log_info "10. 정리 작업 수행 중..."

# 임시 파일 정리
rm -f k8s-deployment.yaml
rm -f backend/Dockerfile.prod
rm -f "/tmp/$BACKUP_FILE"

# 오래된 Docker 이미지 정리
docker image prune -f

# 오래된 백업 파일 정리 (로컬)
find /tmp -name "backup_*.sql" -mtime +$BACKUP_RETENTION_DAYS -delete 2>/dev/null || true

log_success "정리 작업 완료"

# 11. 배포 완료 알림
log_info "11. 배포 완료 알림 발송 중..."

# Slack 알림 (선택사항)
if [ -n "$SLACK_WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"🚀 시설 관리 시스템 프로덕션 배포 완료\\n버전: ${VERSION}\\n시간: $(date)\"}" \
        "$SLACK_WEBHOOK_URL"
fi

# 이메일 알림 (선택사항)
if [ -n "$NOTIFICATION_EMAIL" ]; then
    echo "시설 관리 시스템 프로덕션 배포가 완료되었습니다.

버전: ${VERSION}
배포 시간: $(date)
헬스체크 URL: ${HEALTH_CHECK_URL}

배포 로그는 서버에서 확인하실 수 있습니다." | \
    mail -s "🚀 시설 관리 시스템 배포 완료 - ${VERSION}" "$NOTIFICATION_EMAIL"
fi

# 12. 배포 요약 출력
log_success "======================================"
log_success "시설 관리 시스템 프로덕션 배포 완료!"
log_success "======================================"
log_info "배포 버전: ${VERSION}"
log_info "Docker 이미지: ${DOCKER_TAG}"
log_info "배포 시간: $(date)"
log_info "헬스체크 URL: ${HEALTH_CHECK_URL}"
log_info "API 문서: https://api.qiro.com/api/swagger-ui.html"
log_info "모니터링: https://monitoring.qiro.com"
log_success "======================================"

# 배포 후 권장사항 출력
log_info "배포 후 권장사항:"
log_info "1. 모니터링 대시보드에서 시스템 상태 확인"
log_info "2. 로그 파일에서 오류 메시지 확인"
log_info "3. 주요 기능 수동 테스트 수행"
log_info "4. 성능 메트릭 모니터링"
log_info "5. 사용자 피드백 수집"

exit 0