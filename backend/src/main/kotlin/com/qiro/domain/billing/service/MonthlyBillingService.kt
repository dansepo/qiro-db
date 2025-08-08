package com.qiro.domain.billing.service

import com.qiro.domain.billing.dto.*
import com.qiro.domain.billing.entity.BillingStatus
import com.qiro.domain.billing.entity.MonthlyBilling
import com.qiro.domain.billing.repository.MonthlyBillingRepository
import com.qiro.domain.building.repository.BuildingRepository
import com.qiro.domain.lease.entity.ContractStatus
import com.qiro.domain.lease.repository.LeaseContractRepository
import com.qiro.domain.unit.repository.UnitRepository
import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.*

@Service
@Transactional(readOnly = true)
class MonthlyBillingService(
    private val monthlyBillingRepository: MonthlyBillingRepository,
    private val unitRepository: UnitRepository,
    private val leaseContractRepository: LeaseContractRepository,
    private val buildingRepository: BuildingRepository
) {

    fun getBillings(companyId: UUID, pageable: Pageable): Page<MonthlyBillingSummaryDto> {
        return monthlyBillingRepository.findByCompanyId(companyId, pageable)
            .map { it.toSummaryDto() }
    }

    fun getBillingsByStatus(
        companyId: UUID,
        status: BillingStatus,
        pageable: Pageable
    ): Page<MonthlyBillingSummaryDto> {
        return monthlyBillingRepository.findByCompanyIdAndBillingStatus(companyId, status, pageable)
            .map { it.toSummaryDto() }
    }

    fun getBillingsByYearMonth(
        companyId: UUID,
        year: Int,
        month: Int,
        pageable: Pageable
    ): Page<MonthlyBillingSummaryDto> {
        return monthlyBillingRepository.findByCompanyIdAndBillingYearAndBillingMonth(
            companyId, year, month, pageable
        ).map { it.toSummaryDto() }
    }

    fun searchBillings(
        companyId: UUID,
        status: BillingStatus,
        search: String,
        pageable: Pageable
    ): Page<MonthlyBillingSummaryDto> {
        return monthlyBillingRepository.findByCompanyIdAndBillingStatusAndSearch(
            companyId, status, search, pageable
        ).map { it.toSummaryDto() }
    }

    fun getBilling(billingId: UUID, companyId: UUID): MonthlyBillingDto {
        val billing = monthlyBillingRepository.findByIdAndCompanyId(billingId, companyId)
            ?: throw BusinessException(ErrorCode.BILLING_NOT_FOUND)
        
        return billing.toDto()
    }

    fun getOverdueBillings(companyId: UUID, pageable: Pageable): Page<MonthlyBillingSummaryDto> {
        val overdueStatuses = listOf(
            BillingStatus.ISSUED,
            BillingStatus.SENT,
            BillingStatus.PARTIAL_PAID
        )
        
        return monthlyBillingRepository.findOverdueBillings(
            companyId, overdueStatuses, LocalDate.now(), pageable
        ).map { it.toSummaryDto() }
    }

    fun getUpcomingDueBillings(
        companyId: UUID,
        days: Int = 7,
        pageable: Pageable
    ): Page<MonthlyBillingSummaryDto> {
        val startDate = LocalDate.now()
        val endDate = startDate.plusDays(days.toLong())
        
        return monthlyBillingRepository.findBillingsWithUpcomingDueDate(
            companyId, startDate, endDate, pageable
        ).map { it.toSummaryDto() }
    }

    fun getBillingStatistics(companyId: UUID, year: Int, month: Int?): BillingStatisticsDto {
        val statusStats = monthlyBillingRepository.getBillingStatusStatistics(companyId, year, month)
        val monthlyStats = monthlyBillingRepository.getMonthlyBillingStatistics(companyId, year - 1)
        
        val totalBillings = statusStats.sumOf { it.count }
        val totalAmount = statusStats.sumOf { it.totalAmount }
        val paidAmount = statusStats
            .filter { it.status == BillingStatus.PAID }
            .sumOf { it.totalAmount }
        val unpaidAmount = totalAmount.subtract(paidAmount)
        
        val overdueAmount = monthlyBillingRepository.getTotalOverdueAmount(
            companyId,
            listOf(BillingStatus.ISSUED, BillingStatus.SENT, BillingStatus.PARTIAL_PAID),
            LocalDate.now()
        )
        
        val collectionRate = if (totalAmount > BigDecimal.ZERO) {
            paidAmount.divide(totalAmount, 4, java.math.RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
        } else BigDecimal.ZERO
        
        val averageBillingAmount = if (totalBillings > 0) {
            totalAmount.divide(BigDecimal.valueOf(totalBillings), 2, java.math.RoundingMode.HALF_UP)
        } else BigDecimal.ZERO
        
        return BillingStatisticsDto(
            totalBillings = totalBillings,
            totalAmount = totalAmount,
            paidAmount = paidAmount,
            unpaidAmount = unpaidAmount,
            overdueAmount = overdueAmount,
            collectionRate = collectionRate,
            averageBillingAmount = averageBillingAmount,
            statusStats = statusStats.map { stat ->
                BillingStatusStatsDto(
                    status = stat.status,
                    count = stat.count,
                    totalAmount = stat.totalAmount,
                    percentage = if (totalAmount > BigDecimal.ZERO) {
                        stat.totalAmount.divide(totalAmount, 4, java.math.RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                    } else BigDecimal.ZERO
                )
            },
            monthlyStats = monthlyStats.map { stat ->
                BillingMonthlyStatsDto(
                    year = stat.year,
                    month = stat.month,
                    totalBillings = stat.totalBillings,
                    totalAmount = stat.totalAmount,
                    paidAmount = stat.paidAmount,
                    collectionRate = if (stat.totalAmount > BigDecimal.ZERO) {
                        stat.paidAmount.divide(stat.totalAmount, 4, java.math.RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                    } else BigDecimal.ZERO
                )
            }
        )
    }

    @Transactional
    fun createBilling(companyId: UUID, request: CreateMonthlyBillingRequest): MonthlyBillingDto {
        // 중복 생성 방지
        if (monthlyBillingRepository.existsByUnitIdAndBillingYearAndBillingMonth(
                request.unitId, request.billingYear, request.billingMonth
            )) {
            throw BusinessException(ErrorCode.BILLING_ALREADY_EXISTS)
        }
        
        val unit = unitRepository.findByIdAndCompanyId(request.unitId, companyId)
            ?: throw BusinessException(ErrorCode.UNIT_NOT_FOUND)
        
        val contract = leaseContractRepository.findByIdAndCompanyId(request.contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        // 활성 계약인지 확인
        if (contract.contractStatus != ContractStatus.ACTIVE) {
            throw BusinessException(ErrorCode.CONTRACT_NOT_ACTIVE)
        }
        
        val billingNumber = generateBillingNumber(companyId, request.billingYear, request.billingMonth)
        
        val billing = MonthlyBilling(
            companyId = companyId,
            unit = unit,
            contract = contract,
            billingNumber = billingNumber,
            billingYear = request.billingYear,
            billingMonth = request.billingMonth,
            billingStatus = BillingStatus.DRAFT,
            issueDate = request.issueDate,
            dueDate = request.dueDate,
            monthlyRent = contract.monthlyRent,
            maintenanceFee = contract.maintenanceFee,
            parkingFee = contract.parkingFee,
            electricityFee = request.electricityFee,
            gasFee = request.gasFee,
            waterFee = request.waterFee,
            heatingFee = request.heatingFee,
            internetFee = request.internetFee,
            tvFee = request.tvFee,
            cleaningFee = request.cleaningFee,
            securityFee = request.securityFee,
            elevatorFee = request.elevatorFee,
            commonAreaFee = request.commonAreaFee,
            repairReserveFee = request.repairReserveFee,
            insuranceFee = request.insuranceFee,
            otherFees = request.otherFees,
            discountAmount = request.discountAmount,
            discountReason = request.discountReason,
            adjustmentAmount = request.adjustmentAmount,
            adjustmentReason = request.adjustmentReason,
            notes = request.notes
        )
        
        val savedBilling = monthlyBillingRepository.save(billing)
        return savedBilling.toDto()
    }

    @Transactional
    fun updateBilling(
        billingId: UUID,
        companyId: UUID,
        request: UpdateMonthlyBillingRequest
    ): MonthlyBillingDto {
        val billing = monthlyBillingRepository.findByIdAndCompanyId(billingId, companyId)
            ?: throw BusinessException(ErrorCode.BILLING_NOT_FOUND)
        
        // 결제 완료된 청구서는 수정 불가
        if (billing.billingStatus == BillingStatus.PAID) {
            throw BusinessException(ErrorCode.BILLING_CANNOT_BE_MODIFIED)
        }
        
        billing.apply {
            electricityFee = request.electricityFee
            gasFee = request.gasFee
            waterFee = request.waterFee
            heatingFee = request.heatingFee
            internetFee = request.internetFee
            tvFee = request.tvFee
            cleaningFee = request.cleaningFee
            securityFee = request.securityFee
            elevatorFee = request.elevatorFee
            commonAreaFee = request.commonAreaFee
            repairReserveFee = request.repairReserveFee
            insuranceFee = request.insuranceFee
            otherFees = request.otherFees
            discountAmount = request.discountAmount
            discountReason = request.discountReason
            adjustmentAmount = request.adjustmentAmount
            adjustmentReason = request.adjustmentReason
            notes = request.notes
        }
        
        val savedBilling = monthlyBillingRepository.save(billing)
        return savedBilling.toDto()
    }

    @Transactional
    fun processPayment(
        billingId: UUID,
        companyId: UUID,
        request: ProcessPaymentRequest
    ): MonthlyBillingDto {
        val billing = monthlyBillingRepository.findByIdAndCompanyId(billingId, companyId)
            ?: throw BusinessException(ErrorCode.BILLING_NOT_FOUND)
        
        if (billing.billingStatus == BillingStatus.PAID) {
            throw BusinessException(ErrorCode.BILLING_ALREADY_PAID)
        }
        
        val unpaidAmount = billing.calculateUnpaidAmount()
        if (request.amount > unpaidAmount) {
            throw BusinessException(ErrorCode.PAYMENT_AMOUNT_EXCEEDS_UNPAID)
        }
        
        billing.processPayment(
            request.amount,
            request.paymentDate,
            request.paymentMethod,
            request.paymentReference
        )
        
        val savedBilling = monthlyBillingRepository.save(billing)
        return savedBilling.toDto()
    }

    @Transactional
    fun sendBilling(
        billingId: UUID,
        companyId: UUID,
        request: SendBillingRequest
    ): MonthlyBillingDto {
        val billing = monthlyBillingRepository.findByIdAndCompanyId(billingId, companyId)
            ?: throw BusinessException(ErrorCode.BILLING_NOT_FOUND)
        
        if (billing.billingStatus == BillingStatus.DRAFT) {
            billing.billingStatus = BillingStatus.ISSUED
        }
        
        billing.markAsSent(request.sendMethod, request.recipientEmail, request.recipientPhone)
        
        val savedBilling = monthlyBillingRepository.save(billing)
        return savedBilling.toDto()
    }

    @Transactional
    fun calculateLateFees(companyId: UUID, year: Int, month: Int): Int {
        val overdueBillings = monthlyBillingRepository.findOverdueBillings(
            companyId,
            listOf(BillingStatus.ISSUED, BillingStatus.SENT, BillingStatus.PARTIAL_PAID),
            LocalDate.now(),
            Pageable.unpaged()
        ).content
        
        var updatedCount = 0
        
        overdueBillings.forEach { billing ->
            val lateFeeRate = billing.contract.lateFeeRate
            if (lateFeeRate != null && lateFeeRate > BigDecimal.ZERO) {
                billing.calculateAndApplyLateFee(lateFeeRate)
                monthlyBillingRepository.save(billing)
                updatedCount++
            }
        }
        
        return updatedCount
    }

    @Transactional
    fun bulkCreateBillings(
        companyId: UUID,
        request: BulkCreateBillingRequest
    ): BulkCreateResultDto {
        val createdBillings = mutableListOf<UUID>()
        val errors = mutableListOf<String>()
        
        // 지정된 건물들의 활성 계약 조회
        val buildings = buildingRepository.findByCompanyIdAndBuildingIdIn(companyId, request.buildingIds)
        
        buildings.forEach { building ->
            val units = unitRepository.findByBuildingId(building.buildingId)
            
            units.forEach { unit ->
                try {
                    // 해당 세대의 활성 계약 조회
                    val activeContract = leaseContractRepository.findByUnitIdAndContractStatus(
                        unit.unitId, ContractStatus.ACTIVE
                    )
                    
                    if (activeContract != null) {
                        // 이미 해당 월 청구서가 있는지 확인
                        val existingBilling = monthlyBillingRepository.existsByUnitIdAndBillingYearAndBillingMonth(
                            unit.unitId, request.billingYear, request.billingMonth
                        )
                        
                        if (!existingBilling) {
                            val billingNumber = generateBillingNumber(
                                companyId, request.billingYear, request.billingMonth
                            )
                            
                            val billing = MonthlyBilling(
                                companyId = companyId,
                                unit = unit,
                                contract = activeContract,
                                billingNumber = billingNumber,
                                billingYear = request.billingYear,
                                billingMonth = request.billingMonth,
                                billingStatus = BillingStatus.DRAFT,
                                issueDate = request.issueDate,
                                dueDate = request.dueDate,
                                monthlyRent = activeContract.monthlyRent,
                                maintenanceFee = activeContract.maintenanceFee,
                                parkingFee = activeContract.parkingFee
                            )
                            
                            val savedBilling = monthlyBillingRepository.save(billing)
                            createdBillings.add(savedBilling.billingId)
                        }
                    }
                } catch (e: Exception) {
                    errors.add("세대 ${unit.unitNumber}: ${e.message}")
                }
            }
        }
        
        return BulkCreateResultDto(
            successCount = createdBillings.size,
            failureCount = errors.size,
            createdBillings = createdBillings,
            errors = errors
        )
    }

    @Transactional
    fun deleteBilling(billingId: UUID, companyId: UUID) {
        val billing = monthlyBillingRepository.findByIdAndCompanyId(billingId, companyId)
            ?: throw BusinessException(ErrorCode.BILLING_NOT_FOUND)
        
        // 초안 상태의 청구서만 삭제 가능
        if (billing.billingStatus != BillingStatus.DRAFT) {
            throw BusinessException(ErrorCode.BILLING_CANNOT_BE_DELETED)
        }
        
        monthlyBillingRepository.delete(billing)
    }

    private fun generateBillingNumber(companyId: UUID, year: Int, month: Int): String {
        val count = monthlyBillingRepository.countByCompanyIdAndBillingYearAndBillingMonth(
            companyId, year, month
        )
        return String.format("B%04d%02d%04d", year, month, count + 1)
    }

    private fun MonthlyBilling.toDto(): MonthlyBillingDto {
        val daysPastDue = if (isOverdue()) {
            ChronoUnit.DAYS.between(dueDate, LocalDate.now())
        } else null
        
        return MonthlyBillingDto(
            billingId = billingId,
            billingNumber = billingNumber,
            billingYear = billingYear,
            billingMonth = billingMonth,
            billingStatus = billingStatus,
            issueDate = issueDate,
            dueDate = dueDate,
            monthlyRent = monthlyRent,
            maintenanceFee = maintenanceFee,
            parkingFee = parkingFee,
            electricityFee = electricityFee,
            gasFee = gasFee,
            waterFee = waterFee,
            heatingFee = heatingFee,
            internetFee = internetFee,
            tvFee = tvFee,
            cleaningFee = cleaningFee,
            securityFee = securityFee,
            elevatorFee = elevatorFee,
            commonAreaFee = commonAreaFee,
            repairReserveFee = repairReserveFee,
            insuranceFee = insuranceFee,
            otherFees = otherFees,
            discountAmount = discountAmount,
            discountReason = discountReason,
            lateFee = lateFee,
            adjustmentAmount = adjustmentAmount,
            adjustmentReason = adjustmentReason,
            totalAmount = calculateTotalAmount(),
            paidAmount = paidAmount,
            unpaidAmount = calculateUnpaidAmount(),
            paymentDate = paymentDate,
            paymentMethod = paymentMethod,
            paymentReference = paymentReference,
            sentDate = sentDate,
            sentMethod = sentMethod,
            recipientEmail = recipientEmail,
            recipientPhone = recipientPhone,
            unit = BillingUnitDto(
                unitId = unit.unitId,
                unitNumber = unit.unitNumber,
                buildingName = unit.building.buildingName,
                floor = unit.floor
            ),
            contract = BillingContractDto(
                contractId = contract.contractId,
                contractNumber = contract.contractNumber,
                tenantName = contract.tenant.tenantName,
                lessorName = contract.lessor.lessorName,
                monthlyRent = contract.monthlyRent,
                maintenanceFee = contract.maintenanceFee,
                parkingFee = contract.parkingFee
            ),
            isFullyPaid = isFullyPaid(),
            isOverdue = isOverdue(),
            daysPastDue = daysPastDue,
            notes = notes,
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }

    private fun MonthlyBilling.toSummaryDto(): MonthlyBillingSummaryDto {
        val daysPastDue = if (isOverdue()) {
            ChronoUnit.DAYS.between(dueDate, LocalDate.now())
        } else null
        
        return MonthlyBillingSummaryDto(
            billingId = billingId,
            billingNumber = billingNumber,
            billingYear = billingYear,
            billingMonth = billingMonth,
            billingStatus = billingStatus,
            dueDate = dueDate,
            totalAmount = calculateTotalAmount(),
            paidAmount = paidAmount,
            unpaidAmount = calculateUnpaidAmount(),
            unitNumber = unit.unitNumber,
            buildingName = unit.building.buildingName,
            tenantName = contract.tenant.tenantName,
            isOverdue = isOverdue(),
            daysPastDue = daysPastDue
        )
    }
}