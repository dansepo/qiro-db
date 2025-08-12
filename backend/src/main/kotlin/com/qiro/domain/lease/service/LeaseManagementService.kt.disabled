package com.qiro.domain.lease.service

import com.qiro.domain.migration.dto.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.math.BigDecimal
import java.time.LocalDate
import java.util.*

/**
 * 계약 및 임대 관리 서비스 인터페이스
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 계약 관리 (13개 프로시저)
 * - 보증금 관리 (5개 프로시저)
 * - 입주/퇴거 관리 (8개 프로시저)
 * - 정산 관리 (10개 프로시저)
 */
interface LeaseManagementService {
    
    // === 계약 관리 ===
    
    /**
     * 임대차 계약 생성
     * 기존 프로시저: bms.create_lease_contract
     */
    fun createLeaseContract(request: CreateLeaseContractRequest): LeaseContractDto
    
    /**
     * 임대차 계약 조회
     */
    fun getLeaseContract(companyId: UUID, contractId: UUID): LeaseContractDto?
    
    /**
     * 임대차 계약 목록 조회
     */
    fun getLeaseContracts(companyId: UUID, pageable: Pageable): Page<LeaseContractDto>
    
    /**
     * 임대차 계약 필터 조회
     */
    fun getLeaseContractsWithFilter(filter: LeaseManagementFilter, pageable: Pageable): Page<LeaseContractDto>
    
    /**
     * 계약 상태 업데이트
     * 기존 프로시저: bms.update_contract_status
     */
    fun updateContractStatus(contractId: UUID, request: UpdateContractStatusRequest): LeaseContractDto
    
    /**
     * 계약 승인
     */
    fun approveContract(companyId: UUID, contractId: UUID, approvedBy: UUID): LeaseContractDto
    
    /**
     * 계약 해지
     */
    fun terminateContract(
        companyId: UUID, 
        contractId: UUID, 
        terminationDate: LocalDate, 
        terminationReason: String
    ): LeaseContractDto
    
    /**
     * 계약 삭제 (비활성화)
     */
    fun deleteContract(companyId: UUID, contractId: UUID): Boolean
    
    /**
     * 계약 당사자 추가
     * 기존 프로시저: bms.add_contract_party
     */
    fun addContractParty(request: AddContractPartyRequest): ContractPartyDto
    
    /**
     * 계약 당사자 조회
     */
    fun getContractParties(companyId: UUID, contractId: UUID): List<ContractPartyDto>
    
    /**
     * 계약 상태 이력 조회
     */
    fun getContractStatusHistory(companyId: UUID, contractId: UUID): List<ContractStatusHistoryDto>
    
    /**
     * 만료 예정 계약 조회
     * 기존 프로시저: bms.get_expiring_contracts
     */
    fun getExpiringContracts(companyId: UUID, daysAhead: Int = 90, pageable: Pageable): Page<ExpiringContractDto>
    
    /**
     * 호실별 현재 계약 조회
     */
    fun getCurrentContractByUnit(companyId: UUID, unitId: UUID): LeaseContractDto?
    
    // === 보증금 관리 ===
    
    /**
     * 보증금 수납 처리
     * 기존 프로시저: bms.process_deposit_receipt
     */
    fun processDepositReceipt(request: ProcessDepositReceiptRequest): DepositManagementDto
    
    /**
     * 보증금 조회
     */
    fun getDepositManagement(companyId: UUID, depositId: UUID): DepositManagementDto?
    
    /**
     * 계약별 보증금 조회
     */
    fun getDepositsByContract(companyId: UUID, contractId: UUID, pageable: Pageable): Page<DepositManagementDto>
    
    /**
     * 보증금 목록 조회
     */
    fun getDepositManagements(companyId: UUID, pageable: Pageable): Page<DepositManagementDto>
    
    /**
     * 보증금 이자 계산
     * 기존 프로시저: bms.calculate_deposit_interest
     */
    fun calculateDepositInterest(
        companyId: UUID, 
        contractId: UUID, 
        calculationDate: LocalDate = LocalDate.now()
    ): DepositInterestCalculationResult
    
    /**
     * 보증금 일괄 이자 계산
     * 기존 프로시저: bms.bulk_calculate_deposit_interest
     */
    fun bulkCalculateDepositInterest(
        companyId: UUID, 
        calculationDate: LocalDate = LocalDate.now()
    ): List<DepositInterestCalculationResult>
    
    /**
     * 보증금 반환 처리
     * 기존 프로시저: bms.process_deposit_refund
     */
    fun processDepositRefund(request: ProcessDepositRefundRequest): DepositManagementDto
    
    /**
     * 보증금 상태 업데이트
     */
    fun updateDepositStatus(depositId: UUID, status: String, notes: String? = null): DepositManagementDto
    
    /**
     * 반환 예정 보증금 조회
     */
    fun getDepositsForRefund(companyId: UUID, daysAhead: Int = 30, pageable: Pageable): Page<DepositManagementDto>
    
    // === 계약 갱신 관리 ===
    
    /**
     * 계약 갱신 처리
     * 기존 프로시저: bms.process_contract_renewal
     */
    fun processContractRenewal(request: ProcessContractRenewalRequest): ContractRenewalDto
    
    /**
     * 계약 갱신 조회
     */
    fun getContractRenewal(companyId: UUID, renewalId: UUID): ContractRenewalDto?
    
    /**
     * 계약별 갱신 이력 조회
     */
    fun getContractRenewals(companyId: UUID, contractId: UUID): List<ContractRenewalDto>
    
    /**
     * 갱신 대상 계약 조회
     */
    fun getContractsForRenewal(companyId: UUID, daysAhead: Int = 60): List<LeaseContractDto>
    
    /**
     * 자동 갱신 처리
     */
    fun processAutoRenewal(companyId: UUID, contractId: UUID): ContractRenewalDto
    
    /**
     * 갱신 응답 처리
     */
    fun processTenantResponse(renewalId: UUID, response: String, responseDate: LocalDate): ContractRenewalDto
    
    // === 입주/퇴거 관리 ===
    
    /**
     * 입주 처리
     */
    fun processMoveIn(request: ProcessMoveInOutRequest): LeaseContractDto
    
    /**
     * 퇴거 처리
     */
    fun processMoveOut(request: ProcessMoveInOutRequest): LeaseContractDto
    
    /**
     * 입주 전 점검
     */
    fun conductPreMoveInInspection(
        companyId: UUID, 
        contractId: UUID, 
        inspectionDate: LocalDate,
        inspectionResults: Map<String, Any>
    ): Map<String, Any>
    
    /**
     * 퇴거 후 점검
     */
    fun conductPostMoveOutInspection(
        companyId: UUID, 
        contractId: UUID, 
        inspectionDate: LocalDate,
        inspectionResults: Map<String, Any>
    ): Map<String, Any>
    
    /**
     * 입주/퇴거 일정 조회
     */
    fun getMoveInOutSchedule(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate
    ): List<Map<String, Any>>
    
    /**
     * 입주 준비 체크리스트
     */
    fun getMoveInChecklist(companyId: UUID, contractId: UUID): Map<String, Any>
    
    /**
     * 퇴거 준비 체크리스트
     */
    fun getMoveOutChecklist(companyId: UUID, contractId: UUID): Map<String, Any>
    
    /**
     * 열쇠 관리
     */
    fun manageKeys(
        companyId: UUID, 
        contractId: UUID, 
        action: String, // ISSUE, RETURN, REPLACE
        keyDetails: Map<String, Any>
    ): Map<String, Any>
    
    // === 정산 관리 ===
    
    /**
     * 정산 처리
     */
    fun processSettlement(request: ProcessSettlementRequest): SettlementResultDto
    
    /**
     * 퇴거 정산
     */
    fun processMoveOutSettlement(
        companyId: UUID, 
        contractId: UUID, 
        settlementDate: LocalDate
    ): SettlementResultDto
    
    /**
     * 갱신 정산
     */
    fun processRenewalSettlement(
        companyId: UUID, 
        contractId: UUID, 
        renewalId: UUID
    ): SettlementResultDto
    
    /**
     * 정산 내역 조회
     */
    fun getSettlementDetails(companyId: UUID, contractId: UUID): Map<String, Any>
    
    /**
     * 정산 승인
     */
    fun approveSettlement(
        companyId: UUID, 
        settlementId: UUID, 
        approvedBy: UUID
    ): SettlementResultDto
    
    /**
     * 정산 이의제기 처리
     */
    fun processSettlementDispute(
        companyId: UUID, 
        settlementId: UUID, 
        disputeReason: String,
        disputeAmount: BigDecimal? = null
    ): Map<String, Any>
    
    /**
     * 보증금 차감 내역 관리
     */
    fun manageDepositDeductions(
        companyId: UUID, 
        contractId: UUID, 
        deductions: List<Map<String, Any>>
    ): Map<String, Any>
    
    /**
     * 추가 비용 청구
     */
    fun processAdditionalCharges(
        companyId: UUID, 
        contractId: UUID, 
        charges: List<Map<String, Any>>
    ): Map<String, Any>
    
    /**
     * 정산 완료 처리
     */
    fun completeSettlement(
        companyId: UUID, 
        settlementId: UUID, 
        completionNotes: String? = null
    ): SettlementResultDto
    
    /**
     * 정산 통계 조회
     */
    fun getSettlementStatistics(companyId: UUID): Map<String, Any>
    
    // === 통계 및 분석 ===
    
    /**
     * 임대 관리 통계 조회
     */
    fun getLeaseManagementStatistics(companyId: UUID): LeaseManagementStatisticsDto
    
    /**
     * 월별 임대 요약 조회
     */
    fun getMonthlyLeaseSummary(
        companyId: UUID, 
        year: Int, 
        month: Int
    ): MonthlyLeaseSummaryDto?
    
    /**
     * 기간별 임대 요약 조회
     */
    fun getLeaseSummaryByPeriod(
        companyId: UUID, 
        startDate: LocalDate, 
        endDate: LocalDate
    ): List<MonthlyLeaseSummaryDto>
    
    /**
     * 계약 갱신율 분석
     */
    fun getRenewalRateAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 공실률 분석
     */
    fun getVacancyRateAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 임대료 수익 분석
     */
    fun getRentRevenueAnalysis(companyId: UUID, period: String): Map<String, Any>
    
    /**
     * 보증금 현황 분석
     */
    fun getDepositStatusAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 계약 기간 분석
     */
    fun getContractPeriodAnalysis(companyId: UUID): Map<String, Any>
    
    /**
     * 임차인 분석
     */
    fun getTenantAnalysis(companyId: UUID): Map<String, Any>
    
    // === 알림 및 자동화 ===
    
    /**
     * 계약 만료 알림 생성
     */
    fun generateExpirationAlerts(companyId: UUID, daysAhead: Int = 90): List<Map<String, Any>>
    
    /**
     * 보증금 반환 알림 생성
     */
    fun generateDepositRefundAlerts(companyId: UUID, daysAhead: Int = 30): List<Map<String, Any>>
    
    /**
     * 갱신 알림 생성
     */
    fun generateRenewalAlerts(companyId: UUID, daysAhead: Int = 60): List<Map<String, Any>>
    
    /**
     * 자동 갱신 처리 실행
     */
    fun executeAutoRenewals(companyId: UUID): List<ContractRenewalDto>
    
    /**
     * 계약 상태 자동 업데이트
     */
    fun updateContractStatusAutomatically(companyId: UUID): Map<String, Any>
    
    /**
     * 보증금 이자 자동 계산 실행
     */
    fun executeAutoDepositInterestCalculation(companyId: UUID): List<DepositInterestCalculationResult>
}