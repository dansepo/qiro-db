package com.qiro.config

import io.swagger.v3.oas.models.OpenAPI
import io.swagger.v3.oas.models.info.Contact
import io.swagger.v3.oas.models.info.Info
import io.swagger.v3.oas.models.info.License
import io.swagger.v3.oas.models.security.SecurityRequirement
import io.swagger.v3.oas.models.security.SecurityScheme
import io.swagger.v3.oas.models.servers.Server
import io.swagger.v3.oas.models.tags.Tag
import org.springdoc.core.models.GroupedOpenApi
import org.springframework.beans.factory.annotation.Value
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

/**
 * OpenAPI/Swagger 설정
 * 시설 관리 시스템 API 문서화를 위한 설정
 */
@Configuration
class OpenApiConfig {

    @Value("\${server.port:8080}")
    private val serverPort: String = "8080"

    @Value("\${spring.profiles.active:dev}")
    private val activeProfile: String = "dev"

    /**
     * 메인 OpenAPI 설정
     */
    @Bean
    fun customOpenAPI(): OpenAPI {
        return OpenAPI()
            .info(
                Info()
                    .title("시설 관리 시스템 API")
                    .description("""
                        ## 시설 관리 시스템 REST API 문서
                        
                        이 API는 건물 내 시설물의 고장 신고, 수리 요청, 작업 관리, 예방 정비 등을 
                        통합적으로 관리하는 시설 관리 시스템의 백엔드 API입니다.
                        
                        ### 주요 기능
                        - 🏢 **건물 및 시설물 관리**: 건물, 호실, 시설물 정보 관리
                        - 🚨 **고장 신고 관리**: 입주민 고장 신고 접수 및 처리
                        - 🔧 **작업 지시서 관리**: 수리 작업 생성, 배정, 진행 관리
                        - 🛠️ **예방 정비 관리**: 정기 점검 일정 및 예방 정비 관리
                        - 💰 **비용 관리**: 작업 비용 추적 및 예산 관리
                        - 📱 **알림 시스템**: 다채널 알림 발송 및 에스컬레이션
                        - 📊 **대시보드 및 보고서**: 실시간 현황 및 통계 리포트
                        - 🔐 **사용자 및 권한 관리**: 역할 기반 접근 제어
                        
                        ### 인증 방식
                        이 API는 JWT(JSON Web Token) 기반 인증을 사용합니다.
                        로그인 후 받은 토큰을 `Authorization: Bearer <token>` 헤더에 포함하여 요청하세요.
                        
                        ### 응답 형식
                        모든 API 응답은 다음과 같은 공통 형식을 따릅니다:
                        ```json
                        {
                          "success": true,
                          "message": "요청이 성공적으로 처리되었습니다",
                          "data": { ... },
                          "timestamp": "2024-01-01T00:00:00Z"
                        }
                        ```
                        
                        ### 오류 처리
                        오류 발생 시 HTTP 상태 코드와 함께 다음과 같은 형식으로 응답합니다:
                        ```json
                        {
                          "success": false,
                          "message": "오류 메시지",
                          "errorCode": "ERROR_CODE",
                          "timestamp": "2024-01-01T00:00:00Z"
                        }
                        ```
                        
                        ### 페이징
                        목록 조회 API는 페이징을 지원합니다:
                        - `page`: 페이지 번호 (0부터 시작)
                        - `size`: 페이지 크기 (기본값: 20)
                        - `sort`: 정렬 기준 (예: name,asc)
                        
                        ### 버전 관리
                        API 버전은 URL 경로에 포함됩니다: `/api/v1/...`
                        
                        ### 지원 및 문의
                        - 개발팀: dev@qiro.com
                        - 기술지원: support@qiro.com
                        - 문서 업데이트: 2024년 1월
                    """.trimIndent())
                    .version("1.0.0")
                    .contact(
                        Contact()
                            .name("QIRO 개발팀")
                            .email("dev@qiro.com")
                            .url("https://qiro.com")
                    )
                    .license(
                        License()
                            .name("MIT License")
                            .url("https://opensource.org/licenses/MIT")
                    )
            )
            .servers(
                listOf(
                    Server()
                        .url("http://localhost:$serverPort")
                        .description("로컬 개발 서버"),
                    Server()
                        .url("https://api-dev.qiro.com")
                        .description("개발 서버"),
                    Server()
                        .url("https://api-staging.qiro.com")
                        .description("스테이징 서버"),
                    Server()
                        .url("https://api.qiro.com")
                        .description("프로덕션 서버")
                )
            )
            .addSecurityItem(
                SecurityRequirement().addList("bearerAuth")
            )
            .components(
                io.swagger.v3.oas.models.Components()
                    .addSecuritySchemes(
                        "bearerAuth",
                        SecurityScheme()
                            .type(SecurityScheme.Type.HTTP)
                            .scheme("bearer")
                            .bearerFormat("JWT")
                            .description("JWT 토큰을 입력하세요 (Bearer 접두사 제외)")
                    )
            )
            .tags(
                listOf(
                    Tag().name("인증 및 사용자 관리").description("로그인, 회원가입, 사용자 정보 관리"),
                    Tag().name("건물 관리").description("건물, 호실, 공용시설 정보 관리"),
                    Tag().name("시설물 자산 관리").description("시설물 등록, 상태 관리, 이력 추적"),
                    Tag().name("고장 신고 관리").description("고장 신고 접수, 처리, 상태 추적"),
                    Tag().name("작업 지시서 관리").description("수리 작업 생성, 배정, 진행 관리"),
                    Tag().name("예방 정비 관리").description("정기 점검 일정, 예방 정비 계획 관리"),
                    Tag().name("비용 관리").description("작업 비용 추적, 예산 관리, 정산"),
                    Tag().name("알림 시스템").description("다채널 알림 발송, 에스컬레이션"),
                    Tag().name("대시보드 및 보고서").description("실시간 현황, 통계, 성과 분석"),
                    Tag().name("통합 공통 서비스").description("데이터 무결성, 성능 모니터링, 테스트 실행"),
                    Tag().name("시스템 관리").description("시스템 설정, 코드 관리, 감사 로그")
                )
            )
    }

    /**
     * 인증 및 사용자 관리 API 그룹
     */
    @Bean
    fun authApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("01-auth")
            .displayName("인증 및 사용자 관리")
            .pathsToMatch("/api/v1/auth/**", "/api/v1/users/**")
            .build()
    }

    /**
     * 건물 및 시설물 관리 API 그룹
     */
    @Bean
    fun facilityApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("02-facility")
            .displayName("건물 및 시설물 관리")
            .pathsToMatch(
                "/api/v1/buildings/**",
                "/api/v1/units/**",
                "/api/v1/assets/**",
                "/api/v1/facilities/**"
            )
            .build()
    }

    /**
     * 고장 신고 및 작업 관리 API 그룹
     */
    @Bean
    fun workManagementApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("03-work-management")
            .displayName("고장 신고 및 작업 관리")
            .pathsToMatch(
                "/api/v1/fault-reports/**",
                "/api/v1/work-orders/**",
                "/api/v1/work-assignments/**"
            )
            .build()
    }

    /**
     * 예방 정비 관리 API 그룹
     */
    @Bean
    fun maintenanceApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("04-maintenance")
            .displayName("예방 정비 관리")
            .pathsToMatch(
                "/api/v1/maintenance/**",
                "/api/v1/inspections/**",
                "/api/v1/preventive-maintenance/**"
            )
            .build()
    }

    /**
     * 비용 및 예산 관리 API 그룹
     */
    @Bean
    fun costManagementApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("05-cost-management")
            .displayName("비용 및 예산 관리")
            .pathsToMatch(
                "/api/v1/costs/**",
                "/api/v1/budgets/**",
                "/api/v1/expenses/**",
                "/api/v1/invoices/**"
            )
            .build()
    }

    /**
     * 알림 시스템 API 그룹
     */
    @Bean
    fun notificationApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("06-notification")
            .displayName("알림 시스템")
            .pathsToMatch(
                "/api/v1/notifications/**",
                "/api/v1/alerts/**",
                "/api/v1/escalations/**"
            )
            .build()
    }

    /**
     * 대시보드 및 보고서 API 그룹
     */
    @Bean
    fun dashboardApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("07-dashboard")
            .displayName("대시보드 및 보고서")
            .pathsToMatch(
                "/api/v1/dashboard/**",
                "/api/v1/reports/**",
                "/api/v1/statistics/**",
                "/api/v1/analytics/**"
            )
            .build()
    }

    /**
     * 통합 공통 서비스 API 그룹
     */
    @Bean
    fun integratedServicesApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("08-integrated-services")
            .displayName("통합 공통 서비스")
            .pathsToMatch(
                "/api/v1/integrated/**",
                "/api/v1/data-integrity/**",
                "/api/v1/performance/**",
                "/api/v1/tests/**"
            )
            .build()
    }

    /**
     * 시스템 관리 API 그룹
     */
    @Bean
    fun systemApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("09-system")
            .displayName("시스템 관리")
            .pathsToMatch(
                "/api/v1/system/**",
                "/api/v1/settings/**",
                "/api/v1/codes/**",
                "/api/v1/audit/**"
            )
            .build()
    }

    /**
     * 모바일 API 그룹
     */
    @Bean
    fun mobileApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("10-mobile")
            .displayName("모바일 API")
            .pathsToMatch("/api/v1/mobile/**")
            .build()
    }

    /**
     * 관리자 전용 API 그룹
     */
    @Bean
    fun adminApiGroup(): GroupedOpenApi {
        return GroupedOpenApi.builder()
            .group("11-admin")
            .displayName("관리자 전용")
            .pathsToMatch("/api/v1/admin/**")
            .build()
    }
}