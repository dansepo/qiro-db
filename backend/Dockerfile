# 시설 관리 시스템 백엔드 Dockerfile

# 빌드 스테이지
FROM gradle:8.5-jdk21 AS builder

WORKDIR /app

# Gradle 캐시를 위한 의존성 파일 복사
COPY build.gradle.kts settings.gradle.kts ./
COPY gradle gradle

# 의존성 다운로드 (캐시 최적화)
RUN gradle dependencies --no-daemon

# 소스 코드 복사
COPY src src

# 애플리케이션 빌드
RUN gradle bootJar --no-daemon

# 런타임 스테이지
FROM openjdk:21-jre-slim

# 시스템 패키지 업데이트 및 필요한 도구 설치
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    dumb-init \
    && rm -rf /var/lib/apt/lists/*

# 애플리케이션 사용자 생성
RUN groupadd -r qiro && useradd -r -g qiro qiro

# 작업 디렉토리 설정
WORKDIR /app

# 빌드된 JAR 파일 복사
COPY --from=builder /app/build/libs/*.jar app.jar

# 로그 디렉토리 생성
RUN mkdir -p /var/log/qiro && chown -R qiro:qiro /var/log/qiro

# 파일 업로드 디렉토리 생성
RUN mkdir -p /var/qiro/uploads && chown -R qiro:qiro /var/qiro

# 애플리케이션 소유권 변경
RUN chown -R qiro:qiro /app

# 사용자 전환
USER qiro

# 포트 노출
EXPOSE 8080

# 헬스체크 설정
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# JVM 옵션 설정
ENV JAVA_OPTS="-Xms512m -Xmx2g -XX:+UseG1GC -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# 애플리케이션 실행
ENTRYPOINT ["dumb-init", "--"]
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]

# 메타데이터
LABEL maintainer="QIRO Development Team <dev@qiro.com>"
LABEL version="1.0.0"
LABEL description="시설 관리 시스템 백엔드 API 서버"