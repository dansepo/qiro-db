package com.qiro.domain.invoice.entity

import com.qiro.domain.billing.entity.MonthlyBilling
import com.qiro.domain.unit.entity.Unit
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * Invoice 엔티티 단위 테스트
 */
class InvoiceTest : BehaviorSpec({

    given("고지서 엔티티가 생성되었을 때") {
        val companyId = UUID.randomUUID()
        val unit = mockk<Unit>()
        val billing = mockk<MonthlyBilling>()
        
        val invoice = Invoice(
            companyId = companyId,
            unit = unit,
            billing = billing,
            invoiceNumber = "INV-20240101-1234",
            issueDate = LocalDate.of(2024, 1, 1),
            dueDate = LocalDate.of(2024, 1, 31),
            totalAmount = BigDecimal("100000")
        )

        `when`("초기 상태를 확인할 때") {
            then("기본값들이 올바르게 설정된다") {
                invoice.status shouldBe InvoiceStatus.ISSUED
                invoice.paidAmount shouldBe BigDecimal.ZERO
                invoice.lateFee shouldBe BigDecimal.ZERO
                invoice.discountAmount shouldBe BigDecimal.ZERO
                invoice.outstandingAmount shouldBe BigDecimal("100000")
                invoice.isFullyPaid shouldBe false
            }
        }

        `when`("결제를 처리할 때") {
            val paymentAmount = BigDecimal("50000")
            
            then("부분 결제가 올바르게 처리된다") {
                invoice.processPayment(paymentAmount)
                
                invoice.paidAmount shouldBe paymentAmount
                invoice.outstandingAmount shouldBe BigDecimal("50000")
                invoice.status shouldBe InvoiceStatus.PARTIALLY_PAID
                invoice.isFullyPaid shouldBe false
            }
        }

        `when`("전액 결제를 처리할 때") {
            val fullPayment = BigDecimal("100000")
            
            then("완납 처리가 올바르게 된다") {
                invoice.processPayment(fullPayment)
                
                invoice.paidAmount shouldBe fullPayment
                invoice.outstandingAmount shouldBe BigDecimal.ZERO
                invoice.status shouldBe InvoiceStatus.PAID
                invoice.isFullyPaid shouldBe true
            }
        }

        `when`("0 이하의 금액으로 결제를 시도할 때") {
            then("예외가 발생한다") {
                shouldThrow<IllegalArgumentException> {
                    invoice.processPayment(BigDecimal.ZERO)
                }.message shouldBe "결제 금액은 0보다 커야 합니다."
                
                shouldThrow<IllegalArgumentException> {
                    invoice.processPayment(BigDecimal("-1000"))
                }.message shouldBe "결제 금액은 0보다 커야 합니다."
            }
        }

        `when`("연체료를 적용할 때") {
            val lateFee = BigDecimal("10000")
            
            then("연체료가 올바르게 적용된다") {
                invoice.applyLateFee(lateFee)
                
                invoice.lateFee shouldBe lateFee
                invoice.outstandingAmount shouldBe BigDecimal("110000")
            }
        }

        `when`("음수 연체료를 적용하려 할 때") {
            then("예외가 발생한다") {
                shouldThrow<IllegalArgumentException> {
                    invoice.applyLateFee(BigDecimal("-1000"))
                }.message shouldBe "연체료는 0 이상이어야 합니다."
            }
        }

        `when`("할인을 적용할 때") {
            val discount = BigDecimal("5000")
            
            then("할인이 올바르게 적용된다") {
                invoice.applyDiscount(discount)
                
                invoice.discountAmount shouldBe discount
                invoice.outstandingAmount shouldBe BigDecimal("95000")
            }
        }

        `when`("음수 할인을 적용하려 할 때") {
            then("예외가 발생한다") {
                shouldThrow<IllegalArgumentException> {
                    invoice.applyDiscount(BigDecimal("-1000"))
                }.message shouldBe "할인 금액은 0 이상이어야 합니다."
            }
        }
    }

    given("연체된 고지서가 있을 때") {
        val companyId = UUID.randomUUID()
        val unit = mockk<Unit>()
        val billing = mockk<MonthlyBilling>()
        
        val overdueInvoice = Invoice(
            companyId = companyId,
            unit = unit,
            billing = billing,
            invoiceNumber = "INV-20240101-1234",
            issueDate = LocalDate.of(2024, 1, 1),
            dueDate = LocalDate.now().minusDays(10), // 10일 전 만료
            totalAmount = BigDecimal("100000")
        )

        `when`("연체 상태를 확인할 때") {
            then("연체로 판정된다") {
                overdueInvoice.isOverdue shouldBe true
                overdueInvoice.overdueDays shouldBe 10L
            }
        }
    }

    given("미래 만료일의 고지서가 있을 때") {
        val companyId = UUID.randomUUID()
        val unit = mockk<Unit>()
        val billing = mockk<MonthlyBilling>()
        
        val futureInvoice = Invoice(
            companyId = companyId,
            unit = unit,
            billing = billing,
            invoiceNumber = "INV-20240101-1234",
            issueDate = LocalDate.of(2024, 1, 1),
            dueDate = LocalDate.now().plusDays(10), // 10일 후 만료
            totalAmount = BigDecimal("100000")
        )

        `when`("연체 상태를 확인할 때") {
            then("연체가 아닌 것으로 판정된다") {
                futureInvoice.isOverdue shouldBe false
                futureInvoice.overdueDays shouldBe 0L
            }
        }
    }
})