# QIRO 사업자 회원가입 시스템 배포 가이드

## 개요
이 가이드는 QIRO 사업자 회원가입 시스템의 데이터베이스 스키마를 다양한 환경에 배포하는 방법을 설명합니다.

## 파일 구조
```
database/deployment/
├── README.md                    # 이 파일
├── deployment_tasks.md          # 상세 배포 태스크
├── deploy_dev.sh               # 개발 환경 배포 스크립트
├── deploy_production.sh        # 프로덕션 환경 배포 스크립트
├── rollback.sh                 # 롤백 스크립트
├── backups/                    # 백업 파일 저장소
└── logs/                       # 배포 로그 저장소
```

## 사전 준비사항

### 1. 환경 변수 설정
배포 전에 다음 환경 변수를 설정하세요:

```bash
# 개발 환경
export DB_HOST="59.1.24.88"
export DB_PORT="65432"
export DB_USER="qiro"
export DB_NAME="qiro_dev"
export DB_SCHEMA="bms"
export PGPASSWORD="p@ssword"

# 프로덕션 환경
export DB_HOST="your-production-host"
export DB_PORT="5432"
export DB_USER="qiro_prod"
export DB_NAME="qiro_production"
export DB_SCHEMA="bms"
export PGPASSWORD="your-production-password"
```

### 2. 권한 설정
배포 스크립트에 실행 권한을 부여하세요:

```bash
chmod +x deploy_dev.sh
chmod +x deploy_production.sh
chmod +x rollback.sh
```

### 3. 디렉토리 생성
필요한 디렉토리를 생성하세요:

```bash
mkdir -p backups logs
```

## 배포 절차

### 개발 환경 배포

1. **연결 테스트**
   ```bash
   ./deploy_dev.sh test
   ```

2. **배포 실행**
   ```bash
   ./deploy_dev.sh deploy
   ```

3. **배포 결과 확인**
   - 로그 파일 확인: `logs/` 디렉토리
   - 백업 파일 확인: `backups/` 디렉토리

### 프로덕션 환경 배포

⚠️ **주의: 프로덕션 배포는 신중하게 진행하세요!**

1. **연결 테스트**
   ```bash
   ./deploy_production.sh test
   ```

2. **헬스체크**
   ```bash
   ./deploy_production.sh health
   ```

3. **배포 실행**
   ```bash
   ./deploy_production.sh deploy
   ```
   - 프로덕션 확인 프롬프트에서 `PRODUCTION` 입력
   - 자동 백업 생성 및 검증
   - 단계별 배포 진행

4. **배포 후 검증**
   ```bash
   ./deploy_production.sh health
   ```

## 롤백 절차

### 1. 백업 파일 확인
```bash
./rollback.sh list
```

### 2. 안전한 롤백
```bash
./rollback.sh rollback backup_20250131_143022.sql
```
- 롤백 전 현재 상태 백업 생성
- 확인 프롬프트에서 `ROLLBACK` 입력

### 3. 긴급 롤백 (확인 없이)
```bash
./rollback.sh emergency production_backup_20250131_120000.sql.gz
```

## 배포 단계별 상세 설명

### 1단계: 환경 준비
- 데이터베이스 연결 테스트
- 자동 백업 생성
- 로그 디렉토리 준비

### 2단계: 스키마 배포
- 기본 스키마 및 ENUM 타입 생성
- 테이블 생성 (companies, users, roles 등)
- 외래키 제약조건 설정

### 3단계: 성능 최적화
- 인덱스 생성
- 파티션 테이블 설정
- 쿼리 최적화

### 4단계: 보안 설정
- RLS (Row Level Security) 정책 적용
- 사용자 권한 설정
- 멀티테넌시 격리 구현

### 5단계: 검증 및 테스트
- 스키마 무결성 검증
- 성능 테스트 실행
- 기능 테스트 수행

## 모니터링 및 유지보수

### 로그 파일 위치
- 배포 로그: `logs/deployment_YYYYMMDD.log`
- SQL 실행 로그: `logs/sql_execution_YYYYMMDD_HHMMSS.log`
- 성능 테스트 로그: `logs/performance_test_YYYYMMDD_HHMMSS.log`
- 롤백 로그: `logs/rollback_YYYYMMDD_HHMMSS.log`

### 백업 파일 관리
- 자동 백업: `backups/backup_YYYYMMDD_HHMMSS.sql`
- 프로덕션 백업: `backups/production_backup_YYYYMMDD_HHMMSS.sql.gz`
- 롤백 전 백업: `backups/pre_rollback_backup_YYYYMMDD_HHMMSS.sql`

### 정기 점검 항목
1. **일일 점검**
   - 데이터베이스 연결 상태
   - 로그 파일 확인
   - 성능 지표 모니터링

2. **주간 점검**
   - 백업 파일 검증
   - 디스크 사용량 확인
   - 인덱스 성능 분석

3. **월간 점검**
   - 파티션 테이블 관리
   - 보안 정책 검토
   - 성능 튜닝

## 문제 해결

### 일반적인 문제들

1. **연결 실패**
   ```
   ERROR: 데이터베이스 연결 실패
   ```
   - 환경 변수 확인 (DB_HOST, DB_PORT, PGPASSWORD)
   - 네트워크 연결 상태 확인
   - 데이터베이스 서버 상태 확인

2. **권한 오류**
   ```
   ERROR: permission denied for schema
   ```
   - 데이터베이스 사용자 권한 확인
   - 스키마 생성 권한 확인

3. **백업 실패**
   ```
   ERROR: 백업 파일 검증 실패
   ```
   - 디스크 공간 확인
   - pg_dump 권한 확인
   - 백업 디렉토리 권한 확인

4. **스키마 충돌**
   ```
   ERROR: relation already exists
   ```
   - 기존 스키마 확인
   - 업그레이드 모드 사용 고려
   - 필요시 수동 정리 후 재배포

### 긴급 상황 대응

1. **배포 중 실패**
   - 즉시 배포 중단
   - 자동 생성된 백업으로 롤백
   - 로그 파일 분석 후 원인 파악

2. **성능 저하**
   - 현재 쿼리 실행 상태 확인
   - 인덱스 사용률 점검
   - 필요시 성능 최적화 스크립트 재실행

3. **데이터 손실**
   - 즉시 서비스 중단
   - 최신 백업으로 긴급 복구
   - 데이터 무결성 검증

## 연락처 및 지원

- **개발팀**: dev-team@qiro.com
- **인프라팀**: infra-team@qiro.com
- **긴급 상황**: emergency@qiro.com
- **문서 업데이트**: docs@qiro.com

## 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|----------|
| v1.0.0 | 2025-01-31 | 초기 배포 시스템 구축 |

---

**⚠️ 중요 알림**: 프로덕션 환경 배포 전에는 반드시 스테이징 환경에서 충분한 테스트를 진행하세요.