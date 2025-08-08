import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.time.Duration

plugins {
    alias(libs.plugins.spring.boot)
    alias(libs.plugins.spring.dependency.management)
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.spring)
    alias(libs.plugins.kotlin.jpa)
    alias(libs.plugins.kotlin.kapt)
    alias(libs.plugins.springdoc.openapi)
}

group = "com.qiro"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    // Spring Boot Starters
    implementation(libs.spring.boot.starter.web)
    implementation(libs.spring.boot.starter.data.jpa)
    implementation(libs.spring.boot.starter.security)
    implementation(libs.spring.boot.starter.validation)
    implementation(libs.spring.boot.starter.actuator)
    implementation(libs.spring.boot.starter.thymeleaf)

    // Kotlin
    implementation(libs.jackson.module.kotlin)
    implementation(libs.kotlin.reflect)

    // Database
    runtimeOnly(libs.postgresql)
    runtimeOnly(libs.h2)

    // QueryDSL
    implementation(libs.querydsl.jpa) { artifact { classifier = "jakarta" } }
    // Use annotationProcessor for QueryDSL to avoid potential kapt classpath issues.
    annotationProcessor(libs.querydsl.apt) { artifact { classifier = "jakarta" } }
    // JWT
    implementation(libs.jjwt.api)
    runtimeOnly(libs.jjwt.impl)
    runtimeOnly(libs.jjwt.jackson)

    // API Documentation
    implementation(libs.springdoc.openapi.starter.webmvc.ui)

    // Image Processing
    implementation(libs.imgscalr.lib)
    implementation(libs.imageio.jpeg)
    implementation(libs.imageio.tiff)
    implementation(libs.imageio.webp)

    // Testing
    testImplementation(libs.spring.boot.starter.test)
    testImplementation(libs.spring.security.test)
    testImplementation(libs.kotest.runner.junit5)
    testImplementation(libs.kotest.assertions.core)
    testImplementation(libs.kotest.property)
    testImplementation(libs.kotest.extensions.spring)
    testImplementation(libs.springmockk)
    testImplementation(libs.rest.assured)
    testImplementation(libs.rest.assured.kotlin.extensions)

    // Development Tools
    developmentOnly(libs.spring.boot.devtools)
    annotationProcessor(libs.spring.boot.configuration.processor)
}

tasks.withType<KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs += "-Xjsr305=strict"
        jvmTarget = "21"
    }
}

tasks.withType<Test> {
    useJUnitPlatform()

    // 테스트 실행 시 JVM 옵션 설정
    jvmArgs = listOf(
        "-Xmx2g",
        "-XX:+UseG1GC",
        "-Dspring.profiles.active=test"
    )

    // 테스트 병렬 실행 설정
    maxParallelForks = Runtime.getRuntime().availableProcessors().div(2).takeIf { it > 0 } ?: 1

    // 테스트 결과 출력 설정
    testLogging {
        events("passed", "skipped", "failed")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        showStandardStreams = false
    }
}

// 통합 테스트 전용 태스크
tasks.register<Test>("integrationTest") {
    description = "시설 관리 시스템 통합 테스트 실행"
    group = "verification"

    useJUnitPlatform {
        includeTags("integration")
    }

    // 통합 테스트용 설정
    systemProperty("spring.profiles.active", "integration")
    systemProperty("spring.config.location", "classpath:application-integration.yml")

    // 통합 테스트 패키지만 실행
    include("**/integration/**")

    // 테스트 실행 시간 제한 (10분)
    timeout.set(Duration.ofMinutes(10))

    // 테스트 결과 상세 출력
    testLogging {
        events("started", "passed", "skipped", "failed")
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        showStandardStreams = true
        showCauses = true
        showExceptions = true
        showStackTraces = true
    }

    // 테스트 완료 후 리포트 생성
    finalizedBy("jacocoTestReport")
}

// 단위 테스트 전용 태스크
tasks.register<Test>("unitTest") {
    description = "단위 테스트만 실행"
    group = "verification"

    useJUnitPlatform {
        excludeTags("integration")
    }

    // 통합 테스트 패키지 제외
    exclude("**/integration/**")

    // 단위 테스트용 설정
    systemProperty("spring.profiles.active", "test")
}

// 성능 테스트 전용 태스크
tasks.register<Test>("performanceTest") {
    description = "성능 테스트 실행"
    group = "verification"

    useJUnitPlatform {
        includeTags("performance")
    }

    // 성능 테스트용 JVM 옵션
    jvmArgs = listOf(
        "-Xmx4g",
        "-XX:+UseG1GC",
        "-XX:+UnlockExperimentalVMOptions",
        "-XX:+UseZGC"
    )

    // 성능 테스트는 순차 실행
    maxParallelForks = 1

    // 성능 테스트 시간 제한 (30분)
    timeout.set(Duration.ofMinutes(30))
}

// 전체 테스트 실행 태스크
tasks.register<Test>("allTests") {
    description = "모든 테스트 실행 (단위 + 통합 + 성능)"
    group = "verification"

    dependsOn("unitTest", "integrationTest", "performanceTest")
}

// API 문서 생성 태스크
//tasks.register("generateApiDocs") {
//    description = "OpenAPI 문서 생성"
//    group = "documentation"
//
//    dependsOn("bootRun")
//
//    doLast {
//        println("OpenAPI 문서가 생성되었습니다.")
//        println("Swagger UI: http://localhost:8080/swagger-ui.html")
//        println("OpenAPI JSON: http://localhost:8080/v3/api-docs")
//    }
//}

// 배포용 JAR 빌드 태스크
tasks.register("buildForDeploy") {
    description = "배포용 JAR 파일 빌드"
    group = "build"

    dependsOn("clean", "test", "bootJar")

    doLast {
        val jarFile = file("build/libs").listFiles()?.find { it.name.endsWith(".jar") }
        if (jarFile != null) {
            println("배포용 JAR 파일이 생성되었습니다: ${jarFile.absolutePath}")
            println("파일 크기: ${jarFile.length() / 1024 / 1024}MB")
        }
    }
}

// Docker 이미지 빌드 태스크
tasks.register<Exec>("buildDockerImage") {
    description = "Docker 이미지 빌드"
    group = "docker"

    dependsOn("buildForDeploy")

    commandLine("docker", "build", "-t", "qiro-backend:latest", ".")
    workingDir = file(".")

    doLast {
        println("Docker 이미지가 빌드되었습니다: qiro-backend:latest")
    }
}

// 프로덕션 배포 준비 태스크
tasks.register("prepareForProduction") {
    description = "프로덕션 배포 준비"
    group = "deployment"

    dependsOn("allTests", "buildForDeploy")

    doLast {
        println("프로덕션 배포 준비가 완료되었습니다.")
        println("다음 단계:")
        println("1. 환경 변수 설정 확인")
        println("2. 데이터베이스 마이그레이션 실행")
        println("3. Docker 이미지 빌드: ./gradlew buildDockerImage")
        println("4. 배포 스크립트 실행: ./scripts/deploy.sh prod v1.0.0")
    }
}