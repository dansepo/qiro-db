package com.qiro.domain.invoice.repository

import com.qiro.domain.billing.entity.MonthlyBilling
import com.qiro.domain.invoice.entity.Invoice
import com.qiro.domain.invoice.entity.InvoiceStatus
import com.qiro.domain.unit.entity.Unit
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.extensions.spring.SpringExtension
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager
import org.springframework.data.domain.PageRequest
import org.springframework.test.context.ActiveProfiles
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * InvoiceRepository 테스트
 */
@DataJpaTest
@ActiveProfiles("test")
class InvoiceRepositoryTest(
    private val invoiceRepository: InvoiceRepository,
    private val entityManager: TestEntityManager
) : BehaviorSpec({
    
    extension(SpringExtension)

    given("고지서 Repository 테스트") {
        val companyId = UUID.randomUUID()
        val otherCompanyId = UUID.randomUUID()
        
        // 테스트 데이터 준비
        val unit = Unit(
            companyId = companyId,
            unitNumber = "101",
            buildingId = UUID.randomUUID(),
            area = BigDecimal("84.5"),
            roomCount = 3
        )
        entityManager.persistAndFlush(unit)
        
        val billing = MonthlyBilling(
            companyId = companyId,
            billingMonth = "2024-01",
            totalAmount = BigDecimal("100000")
        )
        entityManager.persistAndFlush(billing)
        
        val invoice1 = Invoice(
            companyId = companyId,
            unit = unit,
            billing = billing,
            invoiceNumber = "INV-20240101-0001",
            issueDate = LocalDate.of(2024, 1, 1),
            dueDate = LocalDate.of(2024, 1, 31),
            totalAmount = BigDecimal("100000"),
            status = InvoiceStatus.ISSUED
        )
        
        val invoice2 = Invoice(
            companyId = companyId,
            unit = unit,
            billing = billing,
            invoiceNumber = "INV-20240101-0002",
            issueDate = LocalDate.of(2024, 1, 2),
            dueDate = LocalDate.now().minusDays(10), // 연체된 고지서
            totalAmount = BigDecimal("150000"),
            status = InvoiceStatus.SENT
        )
        
        val otherCompanyInvoice = Invoice(
            companyId = otherCompanyId,
            unit = unit,
            billing = billing,
            invoiceNumber = "INV-20240101-0003",
            issueDate = LocalDate.of(2024, 1, 3),
            dueDate = LocalDate.of(2024, 1, 31),
            totalAmount = BigDecimal("120000"),
            status = InvoiceStatus.ISSUED
        )
        
        entityManager.persistAndFlush(invoice1)
        entityManager.persistAndFlush(invoice2)
        entityManager.persistAndFlush(otherCompanyInvoice)

        `when`("회사별 고지서 목록을 조회할 때") {
            val pageable = PageRequest.of(0, 10)
            val result = invoiceRepository.findByCompanyIdOrderByIssueDateDesc(companyId, pageable)

            then("해당 회사의 고지서만 반환된다") {
                result.content.size shouldBe 2
                result.content.all { it.companyId == companyId } shouldBe true
                result.content[0].issueDate.isAfter(result.content[1].issueDate) shouldBe true
            }
        }

        `when`("특정 상태의 고지서를 조회할 때") {
            val pageable = PageRequest.of(0, 10)
            val result = invoiceRepository.findByCompanyIdAndStatusOrderByIssueDateDesc(
                companyId, InvoiceStatus.ISSUED, pageable
            )

            then("해당 상태의 고지서만 반환된다") {
                result.content.size shouldBe 1
                result.content[0].status shouldBe InvoiceStatus.ISSUED
            }
        }

        `when`("연체된 고지서를 조회할 때") {
            val pageable = PageRequest.of(0, 10)
            val result = invoiceRepository.findOverdueInvoices(companyId, LocalDate.now(), pageable)

            then("연체된 고지서만 반환된다") {
                result.content.size shouldBe 1
                result.content[0].dueDate.isBefore(LocalDate.now()) shouldBe true
                result.content[0].status shouldNotBe InvoiceStatus.PAID
                result.content[0].status shouldNotBe InvoiceStatus.CANCELLED
            }
        }

        `when`("고지서 번호로 조회할 때") {
            val result = invoiceRepository.findByCompanyIdAndInvoiceNumber(companyId, "INV-20240101-0001")

            then("해당 고지서가 반환된다") {
                result shouldNotBe null
                result?.invoiceNumber shouldBe "INV-20240101-0001"
                result?.companyId shouldBe companyId
            }
        }

        `when`("다른 회사의 고지서 번호로 조회할 때") {
            val result = invoiceRepository.findByCompanyIdAndInvoiceNumber(companyId, "INV-20240101-0003")

            then("null이 반환된다") {
                result shouldBe null
            }
        }

        `when`("특정 기간의 고지서를 조회할 때") {
            val startDate = LocalDate.of(2024, 1, 1)
            val endDate = LocalDate.of(2024, 1, 2)
            val pageable = PageRequest.of(0, 10)
            
            val result = invoiceRepository.findByCompanyIdAndIssueDateBetween(
                companyId, startDate, endDate, pageable
            )

            then("해당 기간의 고지서만 반환된다") {
                result.content.size shouldBe 2
                result.content.all { 
                    !it.issueDate.isBefore(startDate) && !it.issueDate.isAfter(endDate) 
                } shouldBe true
            }
        }

        `when`("고지서 통계를 조회할 때") {
            val stats = invoiceRepository.getInvoiceStatistics(companyId)

            then("올바른 통계가 반환된다") {
                stats.totalCount shouldBe 2L
                stats.totalAmount shouldBe BigDecimal("250000") // 100000 + 150000
                stats.paidAmount shouldBe BigDecimal.ZERO
                stats.outstandingAmount shouldBe BigDecimal("250000")
            }
        }

        `when`("연체 통계를 조회할 때") {
            val stats = invoiceRepository.getOverdueStatistics(companyId)

            then("올바른 연체 통계가 반환된다") {
                stats.overdueCount shouldBe 1L
                stats.overdueAmount shouldBe BigDecimal("150000")
            }
        }
    }
})