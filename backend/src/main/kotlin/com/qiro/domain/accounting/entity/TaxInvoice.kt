package com.qiro.domain.accounting.entity

import com.fasterxml.jackson.databind.JsonNode
import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.annotations.UpdateTimestamp
import org.hibernate.type.SqlTypes
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 세금계산서 엔티티
 * 발행 및 수취한 세금계산서를 관리합니다.
 */
@Entity
@Table(
    name = "tax_invoices_new",
    schema = "bms",
    indexes = [
        Index(name = "idx_tax_invoices_new_company", columnList = "company_id"),
        Index(name = "idx_tax_invoices_new_type", columnList = "invoice_type"),
        Index(name = "idx_tax_invoices_new_issue_date", columnList = "issue_date"),
        Index(name = "idx_tax_invoices_new_supplier", columnList = "supplier_registration_number"),
        Index(name = "idx_tax_invoices_new_buyer", columnList = "buyer_registration_number"),
        Index(name = "idx_tax_invoices_new_number", columnList = "invoice_number")
    ]
)
data class TaxInvoice(
    @Id
    @GeneratedValue
    val id: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    // 세금계산서 기본 정보
    @Enumerated(EnumType.STRING)
    @Column(name = "invoice_type", nullable = false)
    val invoiceType: InvoiceType,

    @Column(name = "invoice_number", nullable = false, length = 50)
    val invoiceNumber: String,

    @Column(name = "issue_date", nullable = false)
    val issueDate: LocalDate,

    // 공급자 정보
    @Column(name = "supplier_name", nullable = false, length = 200)
    val supplierName: String,

    @Column(name = "supplier_registration_number", nullable = false, length = 20)
    val supplierRegistrationNumber: String,

    @Column(name = "supplier_address", columnDefinition = "TEXT")
    val supplierAddress: String? = null,

    @Column(name = "supplier_contact", length = 100)
    val supplierContact: String? = null,

    // 공급받는자 정보
    @Column(name = "buyer_name", nullable = false, length = 200)
    val buyerName: String,

    @Column(name = "buyer_registration_number", nullable = false, length = 20)
    val buyerRegistrationNumber: String,

    @Column(name = "buyer_address", columnDefinition = "TEXT")
    val buyerAddress: String? = null,

    @Column(name = "buyer_contact", length = 100)
    val buyerContact: String? = null,

    // 금액 정보
    @Column(name = "supply_amount", nullable = false, precision = 15, scale = 2)
    val supplyAmount: BigDecimal,

    @Column(name = "vat_amount", nullable = false, precision = 15, scale = 2)
    val vatAmount: BigDecimal,

    @Column(name = "total_amount", nullable = false, precision = 15, scale = 2)
    val totalAmount: BigDecimal,

    // 품목 정보
    @Column(name = "item_description", columnDefinition = "TEXT")
    val itemDescription: String? = null,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "item_details", columnDefinition = "jsonb")
    val itemDetails: JsonNode? = null,

    // 전자세금계산서 정보
    @Column(name = "electronic_invoice_id", length = 100)
    val electronicInvoiceId: String? = null,

    @Column(name = "nts_confirmation_number", length = 100)
    val ntsConfirmationNumber: String? = null,

    // 상태 관리
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    val status: InvoiceStatus = InvoiceStatus.DRAFT,

    // 연동 정보
    @Column(name = "related_transaction_id")
    val relatedTransactionId: UUID? = null,

    @Column(name = "related_expense_id")
    val relatedExpenseId: UUID? = null,

    @Column(name = "related_income_id")
    val relatedIncomeId: UUID? = null,

    // 메타데이터
    @Column(name = "notes", columnDefinition = "TEXT")
    val notes: String? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    val updatedAt: LocalDateTime = LocalDateTime.now(),

    @Column(name = "created_by")
    val createdBy: UUID? = null,

    @Column(name = "updated_by")
    val updatedBy: UUID? = null
) {
    /**
     * 세금계산서 유형
     */
    enum class InvoiceType {
        ISSUED,    // 발행
        RECEIVED,  // 수취
        MODIFIED,  // 수정
        CANCELLED  // 취소
    }

    /**
     * 세금계산서 상태
     */
    enum class InvoiceStatus {
        DRAFT,     // 임시저장
        ISSUED,    // 발행
        SENT,      // 전송
        RECEIVED,  // 수신
        CONFIRMED, // 확인
        CANCELLED  // 취소
    }

    /**
     * 부가세율 계산 (일반적으로 10%)
     */
    fun calculateVatRate(): BigDecimal {
        return if (supplyAmount.compareTo(BigDecimal.ZERO) > 0) {
            vatAmount.divide(supplyAmount, 4, BigDecimal.ROUND_HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }

    /**
     * 총액 검증
     */
    fun validateTotalAmount(): Boolean {
        return totalAmount == supplyAmount.add(vatAmount)
    }

    /**
     * 발행 세금계산서 여부
     */
    fun isIssued(): Boolean {
        return invoiceType == InvoiceType.ISSUED
    }

    /**
     * 수취 세금계산서 여부
     */
    fun isReceived(): Boolean {
        return invoiceType == InvoiceType.RECEIVED
    }
}