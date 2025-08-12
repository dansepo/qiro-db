package com.qiro.domain.invoice.controller

import com.fasterxml.jackson.databind.ObjectMapper
import com.qiro.domain.invoice.dto.CreateInvoiceRequest
import com.qiro.domain.invoice.dto.ProcessPaymentRequest
import com.qiro.domain.invoice.entity.Invoice
import com.qiro.domain.invoice.entity.InvoiceStatus
import com.qiro.domain.invoice.repository.InvoiceRepository
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
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * InvoiceController 통합 테스트
 */
@SpringBootTest
@AutoConfigureWebMvc
@ActiveProfiles("test")
@Transactional
class InvoiceControllerIntegrationTest(
    private val mockMvc: MockMvc,
    private val objectMapper: ObjectMapper,
    private val invoiceRepository: InvoiceRepository
) : BehaviorSpec({
    
    extension(SpringExtension)

    given("고지서 API 통합 테스트") {
        val companyId = UUID.randomUUID()
        val unitId = UUID.randomUUID()
        val billingId = UUID.randomUUID()

        `when`("고지서 생성 API를 호출할 때") {
            val request = CreateInvoiceRequest(
                unitId = unitId,
                billingId = billingId,
                dueDate = LocalDate.now().plusDays(30)
            )

            then("고지서가 성공적으로 생성된다") {
                mockMvc.perform(
                    post("/api/v1/invoices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Company-Id", companyId.toString())
                        .content(objectMapper.writeValueAsString(request))
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.unitId").value(unitId.toString()))
                    .andExpect(jsonPath("$.data.billingId").value(billingId.toString()))
                    .andExpect(jsonPath("$.data.status").value("ISSUED"))
            }
        }

        `when`("고지서 목록 조회 API를 호출할 때") {
            then("고지서 목록이 반환된다") {
                mockMvc.perform(
                    get("/api/v1/invoices")
                        .header("X-Company-Id", companyId.toString())
                        .param("page", "0")
                        .param("size", "20")
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.content").isArray)
            }
        }

        `when`("고지서 상세 조회 API를 호출할 때") {
            val invoiceId = UUID.randomUUID()
            
            then("고지서 상세 정보가 반환된다") {
                mockMvc.perform(
                    get("/api/v1/invoices/{invoiceId}", invoiceId)
                        .header("X-Company-Id", companyId.toString())
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
            }
        }

        `when`("고지서 결제 처리 API를 호출할 때") {
            val invoiceId = UUID.randomUUID()
            val paymentRequest = ProcessPaymentRequest(
                amount = BigDecimal("50000"),
                paymentMethod = "BANK_TRANSFER"
            )

            then("결제가 성공적으로 처리된다") {
                mockMvc.perform(
                    post("/api/v1/invoices/{invoiceId}/payment", invoiceId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Company-Id", companyId.toString())
                        .content(objectMapper.writeValueAsString(paymentRequest))
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.message").value("결제가 처리되었습니다."))
            }
        }

        `when`("고지서 통계 API를 호출할 때") {
            then("통계 정보가 반환된다") {
                mockMvc.perform(
                    get("/api/v1/invoices/statistics")
                        .header("X-Company-Id", companyId.toString())
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.totalCount").exists())
                    .andExpect(jsonPath("$.data.totalAmount").exists())
                    .andExpect(jsonPath("$.data.paidAmount").exists())
                    .andExpect(jsonPath("$.data.outstandingAmount").exists())
                    .andExpect(jsonPath("$.data.collectionRate").exists())
            }
        }

        `when`("연체 통계 API를 호출할 때") {
            then("연체 통계가 반환된다") {
                mockMvc.perform(
                    get("/api/v1/invoices/statistics/overdue")
                        .header("X-Company-Id", companyId.toString())
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.overdueCount").exists())
                    .andExpect(jsonPath("$.data.overdueAmount").exists())
            }
        }

        `when`("월별 통계 API를 호출할 때") {
            then("월별 통계가 반환된다") {
                mockMvc.perform(
                    get("/api/v1/invoices/statistics/monthly")
                        .header("X-Company-Id", companyId.toString())
                        .param("year", "2024")
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data").isArray)
            }
        }

        `when`("대시보드 데이터 API를 호출할 때") {
            then("대시보드 데이터가 반환된다") {
                mockMvc.perform(
                    get("/api/v1/invoices/dashboard")
                        .header("X-Company-Id", companyId.toString())
                )
                    .andExpect(status().isOk)
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.data.totalStatistics").exists())
                    .andExpect(jsonPath("$.data.overdueStatistics").exists())
                    .andExpect(jsonPath("$.data.monthlyStats").exists())
                    .andExpect(jsonPath("$.data.topUnpaidUnits").exists())
            }
        }

        `when`("잘못된 요청으로 API를 호출할 때") {
            val invalidRequest = CreateInvoiceRequest(
                unitId = UUID.randomUUID(),
                billingId = UUID.randomUUID(),
                dueDate = LocalDate.now().minusDays(1) // 과거 날짜
            )

            then("적절한 오류 응답이 반환된다") {
                mockMvc.perform(
                    post("/api/v1/invoices")
                        .contentType(MediaType.APPLICATION_JSON)
                        .header("X-Company-Id", companyId.toString())
                        .content(objectMapper.writeValueAsString(invalidRequest))
                )
                    .andExpect(status().isBadRequest)
                    .andExpect(jsonPath("$.success").value(false))
                    .andExpect(jsonPath("$.errorCode").exists())
                    .andExpect(jsonPath("$.message").exists())
            }
        }
    }
})