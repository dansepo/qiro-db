package com.qiro.domain.invoice.service

import com.qiro.domain.billing.entity.MonthlyBilling
import com.qiro.domain.billing.repository.MonthlyBillingRepository
import com.qiro.domain.invoice.dto.CreateInvoiceRequest
import com.qiro.domain.invoice.entity.Invoice
import com.qiro.domain.invoice.entity.InvoiceStatus
import com.qiro.domain.invoice.repository.InvoiceRepository
import com.qiro.domain.unit.entity.Unit
import com.qiro.domain.unit.repository.UnitRepository
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.springframework.data.repository.findByIdOrNull
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * InvoiceService 단위 테스트
 */
class InvoiceServiceImplTest : BehaviorSpec({

    val invoiceRepository = mockk<InvoiceRepository>()
    val unitRepository = mockk<UnitRepository>()
    val billingRepository = mockk<MonthlyBillingRepository>()
    
    val invoiceService = InvoiceServiceImpl(
        invoiceRepository = invoiceRepository,
        unitRepository = unitRepository,
        billingRepository = billingRepository
    )

    given("고지서 생성 요청이 주어졌을 때") {
        val companyId = UUID.randomUUID()
        val unitId = UUID.randomUUID()
        val billingId = UUID.randomUUID()
        
        val unit = mockk<Unit> {
            every { id } returns unitId
            every { companyId } returns companyId
            every { unitNumber } returns "101"
        }
        
        val billing = mockk<MonthlyBilling> {
            every { id } returns billingId
            every { companyId } returns companyId
            every { billingMonth } returns "2024-01"
            every { totalAmount } returns BigDecimal("100000")
        }
        
        val request = CreateInvoiceRequest(
            unitId = unitId,
            billingId = billingId,
            dueDate = LocalDate.now().plusDays(30)
        )

        `when`("유효한 세대와 청구 정보가 존재할 때") {
            every { unitRepository.findByIdOrNull(unitId) } returns unit
            every { billingRepository.findByIdOrNull(billingId) } returns billing
            every { invoiceRepository.save(any<Invoice>()) } answers { firstArg() }

            then("고지서가 성공적으로 생성된다") {
                val result = invoiceService.createInvoice(companyId, request)
                
                result shouldNotBe null
                result.unitId shouldBe unitId
                result.billingId shouldBe billingId
                result.totalAmount shouldBe BigDecimal("100000")
                result.status shouldBe InvoiceStatus.ISSUED
                
                verify { invoiceRepository.save(any<Invoice>()) }
            }
        }

        `when`("세대를 찾을 수 없을 때") {
            every { unitRepository.findByIdOrNull(unitId) } returns null

            then("IllegalArgumentException이 발생한다") {
                shouldThrow<IllegalArgumentException> {
                    invoiceService.createInvoice(companyId, request)
                }.message shouldBe "세대를 찾을 수 없습니다."
            }
        }

        `when`("다른 회사의 세대에 접근할 때") {
            val otherCompanyUnit = mockk<Unit> {
                every { companyId } returns UUID.randomUUID()
            }
            every { unitRepository.findByIdOrNull(unitId) } returns otherCompanyUnit

            then("접근 권한 오류가 발생한다") {
                shouldThrow<IllegalArgumentException> {
                    invoiceService.createInvoice(companyId, request)
                }.message shouldBe "접근 권한이 없습니다."
            }
        }
    }

    given("고지서 결제 처리 요청이 주어졌을 때") {
        val companyId = UUID.randomUUID()
        val invoiceId = UUID.randomUUID()
        val paymentAmount = BigDecimal("50000")
        
        val invoice = mockk<Invoice>(relaxed = true) {
            every { id } returns invoiceId
            every { companyId } returns companyId
            every { totalAmount } returns BigDecimal("100000")
            every { paidAmount } returns BigDecimal.ZERO
            every { status } returns InvoiceStatus.SENT
        }

        `when`("유효한 고지서에 결제를 처리할 때") {
            every { invoiceRepository.findByIdOrNull(invoiceId) } returns invoice
            every { invoiceRepository.save(any<Invoice>()) } answers { firstArg() }
            every { invoice.processPayment(paymentAmount) } returns Unit

            then("결제가 성공적으로 처리된다") {
                val request = com.qiro.domain.invoice.dto.ProcessPaymentRequest(
                    amount = paymentAmount,
                    paymentMethod = "BANK_TRANSFER"
                )
                
                val result = invoiceService.processPayment(companyId, invoiceId, request)
                
                result shouldNotBe null
                verify { invoice.processPayment(paymentAmount) }
                verify { invoiceRepository.save(invoice) }
            }
        }

        `when`("존재하지 않는 고지서에 결제를 시도할 때") {
            every { invoiceRepository.findByIdOrNull(invoiceId) } returns null

            then("IllegalArgumentException이 발생한다") {
                val request = com.qiro.domain.invoice.dto.ProcessPaymentRequest(
                    amount = paymentAmount,
                    paymentMethod = "BANK_TRANSFER"
                )
                
                shouldThrow<IllegalArgumentException> {
                    invoiceService.processPayment(companyId, invoiceId, request)
                }.message shouldBe "고지서를 찾을 수 없습니다."
            }
        }
    }

    given("연체료 적용 요청이 주어졌을 때") {
        val companyId = UUID.randomUUID()
        val invoiceId = UUID.randomUUID()
        val lateFee = BigDecimal("10000")
        
        val invoice = mockk<Invoice>(relaxed = true) {
            every { id } returns invoiceId
            every { companyId } returns companyId
        }

        `when`("유효한 고지서에 연체료를 적용할 때") {
            every { invoiceRepository.findByIdOrNull(invoiceId) } returns invoice
            every { invoiceRepository.save(any<Invoice>()) } answers { firstArg() }
            every { invoice.applyLateFee(lateFee) } returns Unit

            then("연체료가 성공적으로 적용된다") {
                val request = com.qiro.domain.invoice.dto.ApplyLateFeeRequest(
                    lateFee = lateFee
                )
                
                val result = invoiceService.applyLateFee(companyId, invoiceId, request)
                
                result shouldNotBe null
                verify { invoice.applyLateFee(lateFee) }
                verify { invoiceRepository.save(invoice) }
            }
        }
    }
})