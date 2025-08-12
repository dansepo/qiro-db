package com.qiro.domain.lease.service

import com.qiro.domain.lease.dto.*
import com.qiro.domain.lease.entity.ContractStatus
import com.qiro.domain.lease.entity.LeaseContract
import com.qiro.domain.lease.repository.LeaseContractRepository
import com.qiro.domain.lessor.repository.LessorRepository
import com.qiro.domain.tenant.repository.TenantRepository
import com.qiro.domain.unit.repository.UnitRepository
import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import java.util.*

@Service
@Transactional(readOnly = true)
class LeaseContractService(
    private val leaseContractRepository: LeaseContractRepository,
    private val unitRepository: UnitRepository,
    private val lessorRepository: LessorRepository,
    private val tenantRepository: TenantRepository
) {

    fun getContracts(companyId: UUID, pageable: Pageable): Page<LeaseContractSummaryDto> {
        return leaseContractRepository.findByCompanyId(companyId, pageable)
            .map { it.toSummaryDto() }
    }

    fun getContractsByStatus(
        companyId: UUID, 
        status: ContractStatus, 
        pageable: Pageable
    ): Page<LeaseContractSummaryDto> {
        return leaseContractRepository.findByCompanyIdAndContractStatus(companyId, status, pageable)
            .map { it.toSummaryDto() }
    }

    fun searchContracts(
        companyId: UUID,
        status: ContractStatus,
        search: String,
        pageable: Pageable
    ): Page<LeaseContractSummaryDto> {
        return leaseContractRepository.findByCompanyIdAndContractStatusAndSearch(
            companyId, status, search, pageable
        ).map { it.toSummaryDto() }
    }

    fun getContract(contractId: UUID, companyId: UUID): LeaseContractDto {
        val contract = leaseContractRepository.findByIdAndCompanyId(contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        return contract.toDto()
    }

    fun getExpiringContracts(
        companyId: UUID,
        days: Int = 30,
        pageable: Pageable
    ): Page<LeaseContractSummaryDto> {
        val startDate = LocalDate.now()
        val endDate = startDate.plusDays(days.toLong())
        
        return leaseContractRepository.findExpiringContracts(companyId, startDate, endDate, pageable)
            .map { it.toSummaryDto() }
    }

    fun getContractStatistics(companyId: UUID): ContractStatisticsDto {
        val totalContracts = leaseContractRepository.countByCompanyId(companyId)
        val activeContracts = leaseContractRepository.countByCompanyIdAndContractStatus(
            companyId, ContractStatus.ACTIVE
        )
        
        val expiringContracts = leaseContractRepository.findExpiringContracts(
            companyId, LocalDate.now(), LocalDate.now().plusDays(30), Pageable.unpaged()
        ).totalElements
        
        val contractTypeStats = leaseContractRepository.getContractTypeStatistics(companyId)
        val monthlyStats = leaseContractRepository.getMonthlyContractStatistics(
            companyId, LocalDate.now().minusMonths(12)
        )
        
        val totalMonthlyRent = contractTypeStats.sumOf { it.totalRent }
        val averageMonthlyRent = if (activeContracts > 0) {
            totalMonthlyRent.divide(BigDecimal.valueOf(activeContracts), 2, java.math.RoundingMode.HALF_UP)
        } else BigDecimal.ZERO
        
        return ContractStatisticsDto(
            totalContracts = totalContracts,
            activeContracts = activeContracts,
            expiringContracts = expiringContracts,
            totalMonthlyRent = totalMonthlyRent,
            averageMonthlyRent = averageMonthlyRent,
            contractTypeStats = contractTypeStats.map { stat ->
                ContractTypeStatsDto(
                    type = stat.type,
                    count = stat.count,
                    averageRent = stat.averageRent,
                    totalRent = stat.totalRent,
                    percentage = if (totalMonthlyRent > BigDecimal.ZERO) {
                        stat.totalRent.divide(totalMonthlyRent, 4, java.math.RoundingMode.HALF_UP)
                            .multiply(BigDecimal.valueOf(100))
                    } else BigDecimal.ZERO
                )
            },
            monthlyStats = monthlyStats.map { stat ->
                MonthlyStatsDto(
                    year = stat.year,
                    month = stat.month,
                    count = stat.count,
                    totalRent = stat.totalRent
                )
            }
        )
    }

    @Transactional
    fun createContract(companyId: UUID, request: CreateLeaseContractRequest): LeaseContractDto {
        // 유효성 검증
        validateCreateContractRequest(companyId, request)
        
        val unit = unitRepository.findByIdAndCompanyId(request.unitId, companyId)
            ?: throw BusinessException(ErrorCode.UNIT_NOT_FOUND)
        
        val lessor = lessorRepository.findByIdAndCompanyId(request.lessorId, companyId)
            ?: throw BusinessException(ErrorCode.LESSOR_NOT_FOUND)
        
        val tenant = tenantRepository.findByIdAndCompanyId(request.tenantId, companyId)
            ?: throw BusinessException(ErrorCode.TENANT_NOT_FOUND)
        
        // 계약 생성
        val contract = LeaseContract(
            companyId = companyId,
            unit = unit,
            lessor = lessor,
            tenant = tenant,
            contractNumber = request.contractNumber,
            contractType = request.contractType,
            contractStatus = ContractStatus.DRAFT,
            startDate = request.startDate,
            endDate = request.endDate,
            monthlyRent = request.monthlyRent,
            securityDeposit = request.securityDeposit,
            keyMoney = request.keyMoney,
            maintenanceFee = request.maintenanceFee,
            utilityDeposit = request.utilityDeposit,
            parkingFee = request.parkingFee,
            lateFeeRate = request.lateFeeRate,
            rentDueDay = request.rentDueDay,
            gracePeriodDays = request.gracePeriodDays,
            autoRenewal = request.autoRenewal,
            renewalNoticeDays = request.renewalNoticeDays,
            earlyTerminationAllowed = request.earlyTerminationAllowed,
            earlyTerminationPenalty = request.earlyTerminationPenalty,
            petAllowed = request.petAllowed,
            petDeposit = request.petDeposit,
            smokingAllowed = request.smokingAllowed,
            sublettingAllowed = request.sublettingAllowed,
            utilitiesIncluded = request.utilitiesIncluded,
            furnished = request.furnished,
            parkingSpaces = request.parkingSpaces,
            storageIncluded = request.storageIncluded,
            specialTerms = request.specialTerms,
            notes = request.notes
        )
        
        val savedContract = leaseContractRepository.save(contract)
        return savedContract.toDto()
    }

    @Transactional
    fun updateContract(
        contractId: UUID, 
        companyId: UUID, 
        request: UpdateLeaseContractRequest
    ): LeaseContractDto {
        val contract = leaseContractRepository.findByIdAndCompanyId(contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        // 서명된 계약은 수정 불가
        if (contract.contractStatus != ContractStatus.DRAFT) {
            throw BusinessException(ErrorCode.CONTRACT_CANNOT_BE_MODIFIED)
        }
        
        // 계약 정보 업데이트
        contract.apply {
            contractType = request.contractType
            startDate = request.startDate
            endDate = request.endDate
            monthlyRent = request.monthlyRent
            securityDeposit = request.securityDeposit
            keyMoney = request.keyMoney
            maintenanceFee = request.maintenanceFee
            utilityDeposit = request.utilityDeposit
            parkingFee = request.parkingFee
            lateFeeRate = request.lateFeeRate
            rentDueDay = request.rentDueDay
            gracePeriodDays = request.gracePeriodDays
            autoRenewal = request.autoRenewal
            renewalNoticeDays = request.renewalNoticeDays
            earlyTerminationAllowed = request.earlyTerminationAllowed
            earlyTerminationPenalty = request.earlyTerminationPenalty
            petAllowed = request.petAllowed
            petDeposit = request.petDeposit
            smokingAllowed = request.smokingAllowed
            sublettingAllowed = request.sublettingAllowed
            utilitiesIncluded = request.utilitiesIncluded
            furnished = request.furnished
            parkingSpaces = request.parkingSpaces
            storageIncluded = request.storageIncluded
            specialTerms = request.specialTerms
            notes = request.notes
        }
        
        val savedContract = leaseContractRepository.save(contract)
        return savedContract.toDto()
    }

    @Transactional
    fun signContract(
        contractId: UUID, 
        companyId: UUID, 
        request: SignContractRequest
    ): LeaseContractDto {
        val contract = leaseContractRepository.findByIdAndCompanyId(contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        if (contract.contractStatus != ContractStatus.DRAFT) {
            throw BusinessException(ErrorCode.CONTRACT_ALREADY_SIGNED)
        }
        
        contract.apply {
            contractStatus = ContractStatus.SIGNED
            signedDate = request.signatureDate
            lessorSignatureDate = request.signatureDate
            tenantSignatureDate = request.signatureDate
            witnessName = request.witnessName
            witnessSignatureDate = request.witnessSignatureDate
        }
        
        val savedContract = leaseContractRepository.save(contract)
        return savedContract.toDto()
    }

    @Transactional
    fun activateContract(
        contractId: UUID, 
        companyId: UUID, 
        request: ActivateContractRequest
    ): LeaseContractDto {
        val contract = leaseContractRepository.findByIdAndCompanyId(contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        if (contract.contractStatus != ContractStatus.SIGNED) {
            throw BusinessException(ErrorCode.CONTRACT_NOT_SIGNED)
        }
        
        // 해당 세대에 활성 계약이 있는지 확인
        val hasActiveContract = leaseContractRepository.existsByUnitIdAndContractStatusIn(
            contract.unit.unitId, 
            listOf(ContractStatus.ACTIVE)
        )
        
        if (hasActiveContract) {
            throw BusinessException(ErrorCode.UNIT_ALREADY_OCCUPIED)
        }
        
        contract.apply {
            contractStatus = ContractStatus.ACTIVE
            moveInDate = request.moveInDate
        }
        
        val savedContract = leaseContractRepository.save(contract)
        return savedContract.toDto()
    }

    @Transactional
    fun terminateContract(
        contractId: UUID, 
        companyId: UUID, 
        request: TerminateContractRequest
    ): LeaseContractDto {
        val contract = leaseContractRepository.findByIdAndCompanyId(contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        if (contract.contractStatus != ContractStatus.ACTIVE) {
            throw BusinessException(ErrorCode.CONTRACT_NOT_ACTIVE)
        }
        
        contract.apply {
            contractStatus = ContractStatus.TERMINATED
            actualEndDate = request.terminationDate
            moveOutDate = request.terminationDate
            terminationReason = request.reason
        }
        
        val savedContract = leaseContractRepository.save(contract)
        return savedContract.toDto()
    }

    @Transactional
    fun renewContract(
        contractId: UUID, 
        companyId: UUID, 
        request: RenewContractRequest
    ): LeaseContractDto {
        val originalContract = leaseContractRepository.findByIdAndCompanyId(contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        if (originalContract.contractStatus != ContractStatus.ACTIVE) {
            throw BusinessException(ErrorCode.CONTRACT_NOT_ACTIVE)
        }
        
        // 기존 계약 만료 처리
        originalContract.apply {
            contractStatus = ContractStatus.EXPIRED
            actualEndDate = endDate
        }
        
        // 새로운 갱신 계약 생성
        val renewedContract = LeaseContract(
            companyId = companyId,
            unit = originalContract.unit,
            lessor = originalContract.lessor,
            tenant = originalContract.tenant,
            contractNumber = generateRenewalContractNumber(originalContract.contractNumber),
            contractType = originalContract.contractType,
            contractStatus = ContractStatus.ACTIVE,
            startDate = originalContract.endDate.plusDays(1),
            endDate = request.newEndDate,
            monthlyRent = request.newMonthlyRent ?: originalContract.monthlyRent,
            securityDeposit = originalContract.securityDeposit,
            keyMoney = originalContract.keyMoney,
            maintenanceFee = originalContract.maintenanceFee,
            utilityDeposit = originalContract.utilityDeposit,
            parkingFee = originalContract.parkingFee,
            lateFeeRate = originalContract.lateFeeRate,
            rentDueDay = originalContract.rentDueDay,
            gracePeriodDays = originalContract.gracePeriodDays,
            autoRenewal = originalContract.autoRenewal,
            renewalNoticeDays = originalContract.renewalNoticeDays,
            earlyTerminationAllowed = originalContract.earlyTerminationAllowed,
            earlyTerminationPenalty = originalContract.earlyTerminationPenalty,
            petAllowed = originalContract.petAllowed,
            petDeposit = originalContract.petDeposit,
            smokingAllowed = originalContract.smokingAllowed,
            sublettingAllowed = originalContract.sublettingAllowed,
            utilitiesIncluded = originalContract.utilitiesIncluded,
            furnished = originalContract.furnished,
            parkingSpaces = originalContract.parkingSpaces,
            storageIncluded = originalContract.storageIncluded,
            specialTerms = originalContract.specialTerms,
            notes = originalContract.notes,
            renewalCount = originalContract.renewalCount + 1,
            parentContractId = originalContract.contractId,
            signedDate = LocalDate.now(),
            lessorSignatureDate = LocalDate.now(),
            tenantSignatureDate = LocalDate.now(),
            moveInDate = originalContract.moveInDate
        )
        
        leaseContractRepository.save(originalContract)
        val savedRenewedContract = leaseContractRepository.save(renewedContract)
        
        return savedRenewedContract.toDto()
    }

    @Transactional
    fun deleteContract(contractId: UUID, companyId: UUID) {
        val contract = leaseContractRepository.findByIdAndCompanyId(contractId, companyId)
            ?: throw BusinessException(ErrorCode.CONTRACT_NOT_FOUND)
        
        // 초안 상태의 계약만 삭제 가능
        if (contract.contractStatus != ContractStatus.DRAFT) {
            throw BusinessException(ErrorCode.CONTRACT_CANNOT_BE_DELETED)
        }
        
        leaseContractRepository.delete(contract)
    }

    private fun validateCreateContractRequest(companyId: UUID, request: CreateLeaseContractRequest) {
        // 계약 번호 중복 확인
        if (leaseContractRepository.existsByContractNumber(request.contractNumber)) {
            throw BusinessException(ErrorCode.CONTRACT_NUMBER_ALREADY_EXISTS)
        }
        
        // 계약 기간 유효성 확인
        if (request.endDate.isBefore(request.startDate)) {
            throw BusinessException(ErrorCode.INVALID_CONTRACT_PERIOD)
        }
        
        // 해당 세대에 활성 계약이 있는지 확인
        val hasActiveContract = leaseContractRepository.existsByUnitIdAndContractStatusIn(
            request.unitId, 
            listOf(ContractStatus.ACTIVE, ContractStatus.SIGNED)
        )
        
        if (hasActiveContract) {
            throw BusinessException(ErrorCode.UNIT_ALREADY_OCCUPIED)
        }
    }

    private fun generateRenewalContractNumber(originalNumber: String): String {
        return "${originalNumber}-R${System.currentTimeMillis()}"
    }

    private fun LeaseContract.toDto(): LeaseContractDto {
        return LeaseContractDto(
            contractId = contractId,
            contractNumber = contractNumber,
            contractType = contractType,
            contractStatus = contractStatus,
            startDate = startDate,
            endDate = endDate,
            monthlyRent = monthlyRent,
            securityDeposit = securityDeposit,
            keyMoney = keyMoney,
            maintenanceFee = maintenanceFee,
            utilityDeposit = utilityDeposit,
            parkingFee = parkingFee,
            totalDeposit = calculateTotalDeposit(),
            totalMonthlyPayment = calculateTotalMonthlyPayment(),
            lateFeeRate = lateFeeRate,
            rentDueDay = rentDueDay,
            gracePeriodDays = gracePeriodDays,
            autoRenewal = autoRenewal,
            renewalNoticeDays = renewalNoticeDays,
            earlyTerminationAllowed = earlyTerminationAllowed,
            earlyTerminationPenalty = earlyTerminationPenalty,
            petAllowed = petAllowed,
            petDeposit = petDeposit,
            smokingAllowed = smokingAllowed,
            sublettingAllowed = sublettingAllowed,
            utilitiesIncluded = utilitiesIncluded,
            furnished = furnished,
            parkingSpaces = parkingSpaces,
            storageIncluded = storageIncluded,
            signedDate = signedDate,
            moveInDate = moveInDate,
            moveOutDate = moveOutDate,
            actualEndDate = actualEndDate,
            renewalCount = renewalCount,
            parentContractId = parentContractId,
            terminationReason = terminationReason,
            specialTerms = specialTerms,
            lessorSignatureDate = lessorSignatureDate,
            tenantSignatureDate = tenantSignatureDate,
            witnessName = witnessName,
            witnessSignatureDate = witnessSignatureDate,
            contractDocumentPath = contractDocumentPath,
            notes = notes,
            unit = UnitSummaryDto(
                unitId = unit.unitId,
                unitNumber = unit.unitNumber,
                buildingName = unit.building.buildingName,
                floor = unit.floor,
                exclusiveArea = unit.exclusiveArea
            ),
            lessor = LessorSummaryDto(
                lessorId = lessor.lessorId,
                lessorName = lessor.lessorName,
                contactPhone = lessor.contactPhone,
                contactEmail = lessor.contactEmail
            ),
            tenant = TenantSummaryDto(
                tenantId = tenant.tenantId,
                tenantName = tenant.tenantName,
                contactPhone = tenant.contactPhone,
                contactEmail = tenant.contactEmail
            ),
            durationInMonths = ChronoUnit.MONTHS.between(startDate, endDate),
            isExpiringSoon = isExpiringSoon(),
            createdAt = createdAt,
            updatedAt = updatedAt
        )
    }

    private fun LeaseContract.toSummaryDto(): LeaseContractSummaryDto {
        return LeaseContractSummaryDto(
            contractId = contractId,
            contractNumber = contractNumber,
            contractType = contractType,
            contractStatus = contractStatus,
            startDate = startDate,
            endDate = endDate,
            monthlyRent = monthlyRent,
            securityDeposit = securityDeposit,
            totalMonthlyPayment = calculateTotalMonthlyPayment(),
            unitNumber = unit.unitNumber,
            buildingName = unit.building.buildingName,
            tenantName = tenant.tenantName,
            lessorName = lessor.lessorName,
            isExpiringSoon = isExpiringSoon()
        )
    }

    private fun LeaseContract.calculateTotalDeposit(): BigDecimal {
        return securityDeposit
            .add(keyMoney ?: BigDecimal.ZERO)
            .add(utilityDeposit ?: BigDecimal.ZERO)
            .add(petDeposit ?: BigDecimal.ZERO)
    }

    private fun LeaseContract.calculateTotalMonthlyPayment(): BigDecimal {
        return monthlyRent
            .add(maintenanceFee ?: BigDecimal.ZERO)
            .add(parkingFee ?: BigDecimal.ZERO)
    }

    private fun LeaseContract.isExpiringSoon(): Boolean {
        return contractStatus == ContractStatus.ACTIVE && 
               endDate.isBefore(LocalDate.now().plusDays(30))
    }
}