package com.qiro.domain.accounting.entity

import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 시설 관리 비용 연동 엔티티
 * 지출과 시설 관리 작업을 연결하여 비용을 추적
 */
@Entity
@Table(name = "facility_expense_links", schema = "bms")
data class FacilityExpenseLink(
    @Id
    @Column(name = "link_id")
    val linkId: UUID = UUID.randomUUID(),

    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "expense_record_id", nullable = false)
    val expenseRecord: ExpenseRecord,

    @Column(name = "work_order_id")
    val workOrderId: UUID? = null,

    @Column(name = "maintenance_task_id")
    val maintenanceTaskId: UUID? = null,

    @Column(name = "facility_id")
    val facilityId: UUID? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "link_type", nullable = false, length = 50)
    val linkType: LinkType,

    @Column(name = "linked_amount", nullable = false, precision = 15, scale = 2)
    val linkedAmount: BigDecimal,

    @Column(name = "allocation_ratio", precision = 5, scale = 4)
    val allocationRatio: BigDecimal = BigDecimal.ONE,

    @Column(name = "notes", columnDefinition = "TEXT")
    val notes: String? = null,

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: LocalDateTime = LocalDateTime.now()
) {
    /**
     * 연동 유형
     */
    enum class LinkType(val displayName: String) {
        WORK_ORDER("작업 지시서"),
        MAINTENANCE_TASK("유지보수 작업"),
        FACILITY_REPAIR("시설 수리"),
        PREVENTIVE_MAINTENANCE("예방 정비")
    }

    /**
     * 배분된 금액 계산
     */
    fun getAllocatedAmount(): BigDecimal {
        return linkedAmount * allocationRatio
    }

    /**
     * 연동 정보 업데이트
     */
    fun updateAllocation(
        linkedAmount: BigDecimal? = null,
        allocationRatio: BigDecimal? = null,
        notes: String? = null
    ): FacilityExpenseLink {
        return this.copy(
            linkedAmount = linkedAmount ?: this.linkedAmount,
            allocationRatio = allocationRatio ?: this.allocationRatio,
            notes = notes ?: this.notes
        )
    }

    /**
     * 작업 지시서 연동 여부 확인
     */
    fun isLinkedToWorkOrder(): Boolean {
        return linkType == LinkType.WORK_ORDER && workOrderId != null
    }

    /**
     * 유지보수 작업 연동 여부 확인
     */
    fun isLinkedToMaintenanceTask(): Boolean {
        return linkType == LinkType.MAINTENANCE_TASK && maintenanceTaskId != null
    }
}