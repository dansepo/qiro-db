# 시설 관리 시스템 배포 가이드

## 목차
1. [개요](#개요)
2. [사전 준비](#사전-준비)
3. [환경별 배포](#환경별-배포)
4. [모니터링 및 로그](#모니터링-및-로그)
5. [트러블슈팅](#트러블슈팅)
6. [롤백 절차](#롤백-절차)

## 개요

시설 관리 시스템은 Docker 컨테이너 기반으로 배포되며, 다음과 같은 환경을 지원합니다:

- **개발 환경 (dev)**: 개발자 테스트용
- **스테이징 환경 (staging)**: QA 및 사용자 테스트용  
- **프로덕션 환경 (prod)**: 실제 서비스 운영용

### 아키텍처 구성

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Nginx       │    │   Spring Boot   │    │   PostgreSQL    │
│  (Reverse Proxy)│────│   (Backend API) │────│   (Database)    │
│     Port 80/443 │    │     Port 8080   │    │     Port 5432   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │              ┌─────────────────┐              │
         │              │      Redis      │              │
         └──────────────│     (Cache)     │──────────────┘
                        │    Port 6379    │
                        └─────────────────┘
```

## 사전 준비

### 1. 시스템 요구사항

**최소 사양:**
- CPU: 2 Core
- RAM: 4GB
- Disk: 50GB
- OS: Ubuntu 20.04 LTS 이상

**권장 사양:**
- CPU: 4 Core
- RAM: 8GB
- Disk: 100GB SSD
- OS: Ubuntu 22.04 LTS

### 2. 필수 소프트웨어 설치

```bash
# Docker 설치
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Docker Compose 설치
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Git 설치
sudo apt update
sudo apt install -y git curl wget

# 방화벽 설정
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

### 3. 프로젝트 클론

```bash
git clone https://github.com/your-org/qiro-facility-management.git
cd qiro-facility-management
```

### 4. 환경 변수 설정

```bash
# 환경별 설정 파일 생성
cp .env.example .env.prod
cp .env.example .env.staging
cp .env.example .env.dev

# 각 환경에 맞게 설정 값 수정
nano .env.prod
```

**필수 환경 변수:**
```bash
# 데이터베이스
DATABASE_PASSWORD=your_secure_password

# JWT 보안
JWT_SECRET=your_256_bit_secret_key

# Redis
REDIS_PASSWORD=your_redis_password

# 외부 서비스
SMS_API_KEY=your_sms_api_key
SMTP_PASSWORD=your_email_password
FCM_SERVER_KEY=your_fcm_key
```

### 5. SSL 인증서 준비

**Let's Encrypt 사용 (권장):**
```bash
# Certbot 설치
sudo apt install -y certbot

# 인증서 발급
sudo certbot certonly --standalone -d api.qiro.com
sudo certbot certonly --standalone -d api-staging.qiro.com

# 인증서 복사
sudo cp /etc/letsencrypt/live/api.qiro.com/fullchain.pem ssl/api.qiro.com.crt
sudo cp /etc/letsencrypt/live/api.qiro.com/privkey.pem ssl/api.qiro.com.key
```

## 환경별 배포

### 1. 개발 환경 배포

```bash
# 개발 환경 배포
./scripts/deploy.sh dev v1.0.0

# 로그 확인
docker-compose -f docker-compose.dev.yml logs -f backend

# 상태 확인
curl http://localhost:8080/actuator/health
```

### 2. 스테이징 환경 배포

```bash
# 스테이징 환경 배포
./scripts/deploy.sh staging v1.0.0

# API 테스트
curl https://api-staging.qiro.com/api/v1/health

# Swagger UI 확인
open https://api-staging.qiro.com/swagger-ui.html
```

### 3. 프로덕션 환경 배포

```bash
# 프로덕션 배포 전 체크리스트
./scripts/pre-deploy-check.sh prod

# 프로덕션 배포
./scripts/deploy.sh prod v1.0.0

# 배포 후 검증
./scripts/post-deploy-verify.sh prod
```

**프로덕션 배포 체크리스트:**
- [ ] 데이터베이스 백업 완료
- [ ] 환경 변수 설정 확인
- [ ] SSL 인증서 유효성 확인
- [ ] 모니터링 시스템 준비
- [ ] 롤백 계획 수립
- [ ] 사용자 공지 완료

## 모니터링 및 로그

### 1. 애플리케이션 모니터링

**Grafana 대시보드:**
```bash
# Grafana 접속
open http://localhost:3000

# 기본 계정: admin / [GRAFANA_ADMIN_PASSWORD]
```

**주요 메트릭:**
- API 응답 시간
- 데이터베이스 연결 수
- 메모리 사용률
- CPU 사용률
- 오류율

### 2. 로그 관리

**애플리케이션 로그:**
```bash
# 실시간 로그 확인
docker-compose logs -f backend

# 특정 시간대 로그
docker-compose logs --since="2024-01-01T00:00:00" backend

# 오류 로그만 필터링
docker-compose logs backend | grep ERROR
```

**로그 위치:**
- 애플리케이션 로그: `/var/log/qiro/application.log`
- Nginx 로그: `/var/log/nginx/access.log`, `/var/log/nginx/error.log`
- 데이터베이스 로그: Docker 컨테이너 내부

### 3. 헬스체크

**자동 헬스체크:**
```bash
# 전체 서비스 상태 확인
docker-compose ps

# 개별 서비스 헬스체크
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/info
```

**수동 헬스체크:**
```bash
# API 응답 테스트
curl -X GET "http://localhost:8080/api/v1/health" \
  -H "accept: application/json"

# 데이터베이스 연결 테스트
docker-compose exec postgres pg_isready -U qiro

# Redis 연결 테스트
docker-compose exec redis redis-cli ping
```

## 트러블슈팅

### 1. 일반적인 문제

**컨테이너 시작 실패:**
```bash
# 로그 확인
docker-compose logs backend

# 컨테이너 상태 확인
docker-compose ps

# 리소스 사용량 확인
docker stats
```

**데이터베이스 연결 실패:**
```bash
# PostgreSQL 상태 확인
docker-compose exec postgres pg_isready -U qiro -d qiro_prod

# 연결 설정 확인
docker-compose exec backend env | grep DATABASE

# 네트워크 연결 확인
docker-compose exec backend ping postgres
```

**메모리 부족:**
```bash
# 메모리 사용량 확인
free -h
docker stats

# JVM 힙 덤프 생성
docker-compose exec backend jcmd 1 GC.run_finalization
docker-compose exec backend jcmd 1 VM.gc
```

### 2. 성능 문제

**느린 API 응답:**
```bash
# 응답 시간 측정
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:8080/api/v1/dashboard"

# 데이터베이스 쿼리 분석
docker-compose exec postgres psql -U qiro -d qiro_prod -c "
SELECT query, mean_time, calls 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;"
```

**높은 CPU 사용률:**
```bash
# JVM 스레드 덤프
docker-compose exec backend jcmd 1 Thread.print

# 프로파일링 활성화
docker-compose exec backend curl -X POST "http://localhost:8080/actuator/metrics"
```

### 3. 보안 문제

**무단 접근 시도:**
```bash
# Nginx 액세스 로그 분석
tail -f /var/log/nginx/access.log | grep -E "(40[1-4]|50[0-5])"

# 실패한 로그인 시도 확인
docker-compose logs backend | grep "Authentication failed"

# IP 차단
sudo ufw deny from [suspicious_ip]
```

## 롤백 절차

### 1. 긴급 롤백

```bash
# 이전 버전으로 즉시 롤백
./scripts/rollback.sh prod v1.0.0

# 또는 수동 롤백
docker-compose down
docker tag qiro-backend:v1.0.0 qiro-backend:latest
docker-compose up -d
```

### 2. 데이터베이스 롤백

```bash
# 백업에서 복원
docker-compose exec postgres psql -U qiro -d qiro_prod < backups/backup_20240101_120000.sql

# 마이그레이션 롤백
docker-compose exec backend java -jar app.jar --spring.flyway.command=undo
```

### 3. 설정 롤백

```bash
# Git에서 이전 설정 복원
git checkout v1.0.0 -- .env.prod
git checkout v1.0.0 -- docker-compose.yml

# 컨테이너 재시작
docker-compose restart
```

## 배포 자동화

### 1. CI/CD 파이프라인

**GitHub Actions 예제:**
```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to server
        run: |
          ssh ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_HOST }} \
            "cd /opt/qiro && ./scripts/deploy.sh prod ${{ github.ref_name }}"
```

### 2. 배포 스케줄링

```bash
# 정기 배포 (매주 일요일 새벽 2시)
0 2 * * 0 /opt/qiro/scripts/deploy.sh prod latest

# 자동 백업 (매일 새벽 1시)
0 1 * * * /opt/qiro/scripts/backup.sh
```

## 보안 고려사항

### 1. 네트워크 보안

```bash
# 방화벽 설정
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Docker 네트워크 격리
docker network create --driver bridge qiro-network
```

### 2. 컨테이너 보안

```bash
# 컨테이너 스캔
docker scan qiro-backend:latest

# 보안 업데이트
docker-compose pull
docker-compose up -d
```

### 3. 데이터 보안

```bash
# 데이터베이스 암호화
docker-compose exec postgres psql -U qiro -c "
ALTER SYSTEM SET ssl = on;
SELECT pg_reload_conf();"

# 백업 암호화
gpg --cipher-algo AES256 --compress-algo 1 --s2k-cipher-algo AES256 \
    --s2k-digest-algo SHA512 --s2k-mode 3 --s2k-count 65536 \
    --symmetric backup.sql
```

## 성능 최적화

### 1. 데이터베이스 최적화

```sql
-- 인덱스 분석
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats 
WHERE schemaname = 'bms' 
ORDER BY n_distinct DESC;

-- 쿼리 성능 분석
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM bms.fault_reports 
WHERE status = 'OPEN' 
ORDER BY created_at DESC;
```

### 2. 애플리케이션 최적화

```bash
# JVM 튜닝
export JAVA_OPTS="-Xms2g -Xmx4g -XX:+UseG1GC -XX:MaxGCPauseMillis=200"

# 커넥션 풀 최적화
export HIKARI_MAXIMUM_POOL_SIZE=20
export HIKARI_MINIMUM_IDLE=5
```

### 3. 캐시 최적화

```bash
# Redis 메모리 최적화
docker-compose exec redis redis-cli CONFIG SET maxmemory 1gb
docker-compose exec redis redis-cli CONFIG SET maxmemory-policy allkeys-lru
```

---

## 지원 및 문의

- **기술 지원**: devops@qiro.com
- **긴급 상황**: +82-10-1234-5678
- **문서 업데이트**: https://docs.qiro.com/deployment
- **상태 페이지**: https://status.qiro.com

마지막 업데이트: 2024년 1월 1일