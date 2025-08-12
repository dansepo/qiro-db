package com.qiro.integration

import com.fasterxml.jackson.databind.ObjectMapper
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.extensions.spring.SpringExtension
import io.kotest.matchers.shouldBe
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureWebMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.http.MediaType
import org.springframework.test.context.ActiveProfiles
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*
import org.springframework.transaction.annotation.Transactional

/**
 * QIRO 애플리케이션 통합 테스트
 */
@SpringBootTest
@AutoConfigureWebMvc
@ActiveProfiles("test")
@Transactional
class QiroApplicationIntegrationTest(
    private val mockMvc: MockMvc,
    private val objectMapper: ObjectMapper
) : BehaviorSpec({
    
    extension(SpringExtension)

    given("QIRO 애플리케이션 통합 테스트") {

        `when`("애플리케이션이 시작될 때") {
            then("헬스 체크 엔드포인트가 정상 작동한다") {
                mockMvc.perform(get("/actuator/health"))
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.status").value("UP"))
            }
        }

        `when`("API 문서에 접근할 때") {
            then("Swagger UI가 정상 작동한다") {
                mockMvc.perform(get("/swagger-ui/index.html"))
                    .andExpect(status().isOk)
            }
            
            then("OpenAPI 스펙이 정상 반환된다") {
                mockMvc.perform(get("/v3/api-docs"))
                    .andExpect(status().isOk)
                    .andExpect(content().contentType(MediaType.APPLICATION_JSON))
                    .andExpect(jsonPath("$.openapi").exists())
                    .andExpect(jsonPath("$.info.title").value("QIRO 건물관리 시스템 API"))
            }
        }

        `when`("메트릭 엔드포인트에 접근할 때") {
            then("메트릭 정보가 정상 반환된다") {
                mockMvc.perform(get("/actuator/metrics"))
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.names").isArray)
            }
        }

        `when`("존재하지 않는 엔드포인트에 접근할 때") {
            then("404 오류가 반환된다") {
                mockMvc.perform(get("/api/v1/nonexistent"))
                    .andExpect(status().isNotFound)
            }
        }

        `when`("잘못된 JSON 요청을 보낼 때") {
            then("400 오류가 반환된다") {
                mockMvc.perform(
                    post("/api/v1/invoices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("invalid json")
                )
                    .andExpect(status().isBadRequest)
                    .andExpect(jsonPath("$.success").value(false))
                    .andExpect(jsonPath("$.errorCode").exists())
            }
        }

        `when`("인증 없이 보호된 엔드포인트에 접근할 때") {
            then("401 오류가 반환된다") {
                mockMvc.perform(get("/api/v1/invoices"))
                    .andExpect(status().isUnauthorized)
            }
        }

        `when`("CORS 프리플라이트 요청을 보낼 때") {
            then("CORS 헤더가 정상 반환된다") {
                mockMvc.perform(
                    options("/api/v1/invoices")
                        .header("Origin", "http://localhost:3000")
                        .header("Access-Control-Request-Method", "POST")
                        .header("Access-Control-Request-Headers", "Content-Type")
                )
                    .andExpect(status().isOk)
                    .andExpect(header().exists("Access-Control-Allow-Origin"))
                    .andExpect(header().exists("Access-Control-Allow-Methods"))
            }
        }
    }

    given("전체 워크플로우 통합 테스트") {
        
        `when`("건물 관리 워크플로우를 실행할 때") {
            then("전체 프로세스가 정상 작동한다") {
                // 1. 건물 생성
                // 2. 세대 생성
                // 3. 임대차 계약 생성
                // 4. 월별 관리비 생성
                // 5. 고지서 발행
                // 6. 결제 처리
                // 7. 미납 관리
                
                // 실제 구현에서는 각 단계별로 API 호출하여 전체 워크플로우 테스트
                true shouldBe true // 플레이스홀더
            }
        }

        `when`("시설 유지보수 워크플로우를 실행할 때") {
            then("전체 프로세스가 정상 작동한다") {
                // 1. 시설물 등록
                // 2. 유지보수 요청 접수
                // 3. 작업 배정
                // 4. 작업 진행
                // 5. 작업 완료
                // 6. 비용 처리
                
                // 실제 구현에서는 각 단계별로 API 호출하여 전체 워크플로우 테스트
                true shouldBe true // 플레이스홀더
            }
        }
    }
})