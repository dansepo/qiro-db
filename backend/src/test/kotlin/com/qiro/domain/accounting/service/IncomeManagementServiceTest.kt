package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.*
import com.qiro.domain.accounting.entity.*
import com.qiro.domain.accounting.repository.*
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.junit.jupiter.MockitoExtension
import org.mockito.kotlin.any
import org.mockito.kotlin.whenever
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 수입 관리 서비스 테스트
 */
@ExtendWith(MockitoExtension::class)
class IncomeManagementServiceTest {

    @Mock
    private lateinit var incomeTypeRepository: IncomeTypeRepository

    @Mock
    private lateinit var incomeRecordRepository: IncomeRecordRepository

    @Mock
    private lateinit var receivableRepository: ReceivableRepository

    @Mock
    private lateinit var paymentRecordRepository: PaymentRecordRepository

    @Mock
    private lateinit var lateFeePolicyRepository: LateFeePolicyRepository

    @Mock
    private lateinit var recurringIncomeScheduleRepository: RecurringIncomeScheduleRepository

    @InjectMocks
    private lateinit var incomeManagementService: IncomeManagementService

    private val testCompanyId = UUID.randomUUID()
    private val testUserId = UUID.randomUUID()

    @Test
    fun `수입 유형 생성 테스트`() {
        // Given
        val request = CreateIncomeTypeRequest(
            typeCode = "MAINTENANCE_FEE",
            typeName = "관리비",
            description = "월별 관리비 수입",
            isRecurring = true,
            defaultAccountId = null
        )

        val incomeType = IncomeType(
            companyId = testCompanyId,
            typeCode = request.typeCode,
            typeName = request.typeName,
            description = request.description,
            isRecurring = request.isRecurring,
            defaultAccountId = request.defaultAccountId
        )

        whenever(incomeTypeRepository.existsByCompanyIdAndTypeCode(testCompanyId, request.typeCode))
            .thenReturn(false)
        whenever(incomeTypeRepository.save(any<IncomeType>())).thenReturn(incomeType)

        // When
        val result = incomeManagementService.createIncomeType(testCompanyId, request)

        // Then
        assert(result.typeCode == request.typeCode)
        assert(result.typeName == request.typeName)
        assert(result.isRecurring == request.isRecurring)
    }

    @Test
    fun `수입 기록 생성 테스트`() {
        // Given
        val incomeTypeId = UUID.randomUUID()
        val incomeType = IncomeType(
            incomeTypeId = incomeTypeId,
            companyId = testCompanyId,
            typeCode = "MAINTENANCE_FEE",
            typeName = "관리비",
            isRecurring = true
        )

        val request = CreateIncomeRecordRequest(
            incomeTypeId = incomeTypeId,
            buildingId = UUID.randomUUID(),
            unitId = UUID.randomUUID(),
            contractId = UUID.randomUUID(),
            tenantId = UUID.randomUUID(),
            incomeDate = LocalDate.now(),
            dueDate = LocalDate.now().plusDays(30),
            amount = BigDecimal("150000"),
            taxAmount = BigDecimal.ZERO,
            paymentMethod = "BANK_TRANSFER",
            bankAccountId = null,
            referenceNumber = "REF-001",
            description = "101호 관리비"
        )

        val incomeRecord = IncomeRecord(
            companyId = testCompanyId,
            incomeType = incomeType,
            buildingId = request.buildingId,
            unitId = request.unitId,
            contractId = request.contractId,
            tenantId = request.tenantId,
            incomeDate = request.incomeDate,
            dueDate = request.dueDate,
            amount = request.amount,
            taxAmount = request.taxAmount,
            totalAmount = request.amount + request.taxAmount,
            paymentMethod = request.paymentMethod,
            bankAccountId = request.bankAccountId,
            referenceNumber = request.referenceNumber,
            description = request.description,
            createdBy = testUserId
        )

        val receivable = Receivable(
            companyId = testCompanyId,
            incomeRecord = incomeRecord,
            buildingId = request.buildingId,
            unitId = request.unitId,
            tenantId = request.tenantId,
            originalAmount = incomeRecord.totalAmount,
            outstandingAmount = incomeRecord.totalAmount,
            totalOutstanding = incomeRecord.totalAmount,
            dueDate = request.dueDate!!
        )

        whenever(incomeTypeRepository.findById(incomeTypeId)).thenReturn(Optional.of(incomeType))
        whenever(incomeRecordRepository.save(any<IncomeRecord>())).thenReturn(incomeRecord)
        whenever(receivableRepository.save(any<Receivable>())).thenReturn(receivable)

        // When
        val result = incomeManagementService.createIncomeRecord(testCompanyId, request, testUserId)

        // Then
        assert(result.amount == request.amount)
        assert(result.totalAmount == request.amount + request.taxAmount)
        assert(result.description == request.description)
    }

    @Test
    fun `연체료 정책 생성 테스트`() {
        // Given
        val incomeTypeId = UUID.randomUUID()
        val incomeType = IncomeType(
            incomeTypeId = incomeTypeId,
            companyId = testCompanyId,
            typeCode = "MAINTENANCE_FEE",
            typeName = "관리비",
            isRecurring = true
        )

        val request = CreateLateFeePolicyRequest(
            incomeTypeId = incomeTypeId,
            policyName = "관리비 연체료 정책",
            gracePeriodDays = 5,
            lateFeeType = LateFeePolicy.LateFeeType.PERCENTAGE,
            lateFeeRate = BigDecimal("2.0"),
            fixedLateFee = null,
            maxLateFee = BigDecimal("100000"),
            compoundInterest = false,
            effectiveFrom = LocalDate.now(),
            effectiveTo = null
        )

        val policy = LateFeePolicy(
            companyId = testCompanyId,
            incomeType = incomeType,
            policyName = request.policyName,
            gracePeriodDays = request.gracePeriodDays,
            lateFeeType = request.lateFeeType,
            lateFeeRate = request.lateFeeRate,
            fixedLateFee = request.fixedLateFee,
            maxLateFee = request.maxLateFee,
            compoundInterest = request.compoundInterest,
            effectiveFrom = request.effectiveFrom,
            effectiveTo = request.effectiveTo
        )

        whenever(incomeTypeRepository.findById(incomeTypeId)).thenReturn(Optional.of(incomeType))
        whenever(lateFeePolicyRepository.hasOverlappingPolicy(any(), any(), any(), any(), any()))
            .thenReturn(false)
        whenever(lateFeePolicyRepository.save(any<LateFeePolicy>())).thenReturn(policy)

        // When
        val result = incomeManagementService.createLateFeePolicy(testCompanyId, request)

        // Then
        assert(result.policyName == request.policyName)
        assert(result.lateFeeType == request.lateFeeType)
        assert(result.lateFeeRate == request.lateFeeRate)
    }
}