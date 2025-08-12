# 멀티 스테이지 빌드를 사용한 Docker 이미지 생성

# 빌드 스테이지
FROM gradle:8.5-jdk21 AS builder

WORKDIR /app

# Gradle 래퍼와 빌드 파일 복사
COPY gradle/ gradle/
COPY gradlew .
COPY build.gradle.kts .
COPY settings.gradle.kts .

# 의존성 다운로드 (캐시 최적화)
RUN ./gradlew dependencies --no-daemon

# 소스 코드 복사
COPY src/ src/

# 애플리케이션 빌드
RUN ./gradlew bootJar --no-daemon

# 런타임 스테이지
FROM openjdk:21-jre-slim

# 필요한 패키지 설치
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 애플리케이션 사용자 생성
RUN groupadd -r qiro && useradd -r -g qiro qiro

# 작업 디렉토리 설정
WORKDIR /app

# 빌드된 JAR 파일 복사
COPY --from=builder /app/build/libs/*.jar app.jar

# 로그 디렉토리 생성
RUN mkdir -p /app/logs && chown -R qiro:qiro /app

# 업로드 디렉토리 생성
RUN mkdir -p /app/uploads && chown -R qiro:qiro /app/uploads

# PDF 생성 임시 디렉토리 생성
RUN mkdir -p /app/pdf-temp && chown -R qiro:qiro /app/pdf-temp

# 사용자 변경
USER qiro

# 포트 노출
EXPOSE 8080

# 헬스 체크
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# JVM 옵션 설정
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:+UseG1GC -XX:+UseContainerSupport"

# 애플리케이션 실행
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]