package com.qiro.common.config

import io.swagger.v3.oas.models.Components
import io.swagger.v3.oas.models.OpenAPI
import io.swagger.v3.oas.models.info.Contact
import io.swagger.v3.oas.models.info.Info
import io.swagger.v3.oas.models.info.License
import io.swagger.v3.oas.models.security.SecurityRequirement
import io.swagger.v3.oas.models.security.SecurityScheme
import io.swagger.v3.oas.models.servers.Server
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration

/**
 * OpenAPI 3.0 설정
 */
@Configuration
class OpenApiConfig {

    @Bean
    fun openAPI(): OpenAPI {
        return OpenAPI()
            .info(apiInfo())
            .servers(listOf(
                Server().url("http://localhost:8080").description("개발 서버"),
                Server().url("https://api.qiro.com").description("운영 서버")
            ))
            .components(
                Components()
                    .addSecuritySchemes("bearerAuth", 
                        SecurityScheme()
                            .type(SecurityScheme.Type.HTTP)
                            .scheme("bearer")
                            .bearerFormat("JWT")
                            .description("JWT 토큰을 입력하세요")
                    )
                    .addSecuritySchemes("companyId",
                        SecurityScheme()
                            .type(SecurityScheme.Type.APIKEY)
                            .`in`(SecurityScheme.In.HEADER)
                            .name("X-Company-Id")
                            .description("회사 ID를 입력하세요")
                    )
            )
            .addSecurityItem(
                SecurityRequirement()
                    .addList("bearerAuth")
                    .addList("companyId")
            )
    }

    private fun apiInfo(): Info {
        return Info()
            .title("QIRO 건물관리 시스템 API")
            .description("""
                QIRO 건물관리 시스템의 RESTful API 문서입니다.
                
                ## 주요 기능
                - 건물 및 세대 관리
                - 임대차 계약 관리
                - 월별 관리비 처리
                - 고지서 및 수납 관리
                - 시설 유지보수 관리
                - 미납 관리 및 연체료 처리
                
                ## 인증 방식
                - JWT Bearer Token 인증
                - 멀티테넌시를 위한 Company ID 헤더 필수
                
                ## API 버전 관리
                - 현재 버전: v1
                - URL 패턴: /api/v1/{resource}
                
                ## 오류 처리
                - 표준화된 오류 응답 형식 사용
                - HTTP 상태 코드와 함께 상세한 오류 정보 제공
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
    }
}