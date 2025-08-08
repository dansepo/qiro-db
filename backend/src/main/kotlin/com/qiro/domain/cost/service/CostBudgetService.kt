package com.qiro.domain.cost.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.common.security.CurrentUser
import com.qiro.common.service.DataIntegrityService
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.company.repository.CompanyRepository
import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.entity.CostBudget
import com.qiro.domain.cost.repository.CostBudgetRepository
import com.qiro.domain.user.repository.UserRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDate
import java.util.*

/**
 * 비용 예산 관리 서비스
 * 시설 관리 예산 계획 및 실행을 추적하고 관리하는 서비스
 */
@Service
@Transactional(readOnly = true)
class CostBudgetService(
    private val costBudgetRepository: CostBudgetRepository,
    private val companyRepository: CompanyRepository,
    private val userRepository: UserRepository,
    private val dataIntegrityService: DataIntegrityService
) {
    
    /**
     * 예산 생성
     */
    @Transactional
    fun createBudget(request: CreateCostBudgetRequest, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        // 데이터 무결성 검증
        dataIntegrityService.validateCompanyExists(companyId)
        
        val company = companyRepository.findById(companyId)
            .orElseThrow { BusinessException(ErrorCode.COMPANY_NOT_FOUND) }
        
        // 예산 코드 중복 확인
        costBudgetRepository.findByCompanyCompanyIdAndBudgetCode(companyId, request.budgetCode)?.let {
            throw BusinessException(ErrorCode.BUDGET_CODE_ALREADY_EXISTS)
        }
        
        // 예산 소유자 검증 (있는 경우)
        val budgetOwner = request.budgetOwnerId?.let { ownerId ->
            userRepository.findById(ownerId)
                .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        }
        
        // 날짜 유효성 검증
        if (request.endDate.isBefore(request.startDate)) {
            throw BusinessException(ErrorCode.INVALID_DATE_RANGE)
        }
        
        // 예산 엔티티 생성
        val budget = CostBudget().apply {
            this.company = company
            this.budgetCode = request.budgetCode
            this.budgetName = request.budgetName
            this.description = request.description
            this.budgetCategory = request.budgetCategory
            this.budgetPeriod = request.budgetPeriod
            this.fiscalYear = request.fiscalYear
            this.startDate = request.startDate
            this.endDate = request.endDate
            this.plannedAmount = request.plannedAmount
            this.alertThreshold = request.alertThreshold
            this.criticalThreshold = request.criticalThreshold
            this.autoApprovalLimit = request.autoApprovalLimit
            this.budgetOwner = budgetOwner
            this.reviewFrequency = request.reviewFrequency
            this.notes = request.notes
            this.createdBy = currentUser
            this.updatedBy = currentUser
            
            // 초기 메트릭 계산
            updateBudgetMetrics()
            
            // 다음 검토 일자 계산
            calculateNextReviewDate()
        }
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 업데이트
     */
    @Transactional
    fun updateBudget(budgetId: UUID, request: UpdateCostBudgetRequest, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 활성 상태의 예산은 제한적 수정만 가능
        if (budget.budgetStatus == CostBudget.BudgetStatus.ACTIVE) {
            // 활성 예산은 특정 필드만 수정 가능
            request.alertThreshold?.let { budget.alertThreshold = it }
            request.criticalThreshold?.let { budget.criticalThreshold = it }
            request.autoApprovalLimit?.let { budget.autoApprovalLimit = it }
            request.budgetOwnerId?.let { ownerId ->
                val owner = userRepository.findById(ownerId)
                    .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
                budget.budgetOwner = owner
            }
            request.reviewFrequency?.let { budget.reviewFrequency = it }
            request.notes?.let { budget.notes = it }
        } else {
            // 비활성 예산은 모든 필드 수정 가능
            request.budgetName?.let { budget.budgetName = it }
            request.description?.let { budget.description = it }
            request.budgetCategory?.let { budget.budgetCategory = it }
            request.budgetPeriod?.let { budget.budgetPeriod = it }
            request.startDate?.let { 
                if (request.endDate != null && it.isAfter(request.endDate)) {
                    throw BusinessException(ErrorCode.INVALID_DATE_RANGE)
                }
                budget.startDate = it 
            }
            request.endDate?.let { 
                if (it.isBefore(budget.startDate)) {
                    throw BusinessException(ErrorCode.INVALID_DATE_RANGE)
                }
                budget.endDate = it 
            }
            request.plannedAmount?.let { 
                budget.plannedAmount = it
                budget.updateBudgetMetrics() // 계획 금액 변경 시 메트릭 재계산
            }
            request.alertThreshold?.let { budget.alertThreshold = it }
            request.criticalThreshold?.let { budget.criticalThreshold = it }
            request.autoApprovalLimit?.let { budget.autoApprovalLimit = it }
            request.budgetOwnerId?.let { ownerId ->
                val owner = userRepository.findById(ownerId)
                    .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
                budget.budgetOwner = owner
            }
            request.reviewFrequency?.let { 
                budget.reviewFrequency = it
                budget.calculateNextReviewDate()
            }
            request.notes?.let { budget.notes = it }
        }
        
        budget.updatedBy = currentUser
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 승인
     */
    @Transactional
    fun approveBudget(budgetId: UUID, request: ApproveBudgetRequest, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 승인 가능 상태 확인
        if (budget.budgetStatus != CostBudget.BudgetStatus.SUBMITTED) {
            throw BusinessException(ErrorCode.INVALID_BUDGET_STATUS_FOR_APPROVAL)
        }
        
        val approver = userRepository.findById(currentUser)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        
        budget.approve(approver, request.approvalNotes)
        budget.updatedBy = currentUser
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 활성화
     */
    @Transactional
    fun activateBudget(budgetId: UUID, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        budget.activate()
        budget.updatedBy = currentUser
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 할당
     */
    @Transactional
    fun allocateBudget(budgetId: UUID, request: AllocateBudgetRequest, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 활성 상태 확인
        if (budget.budgetStatus != CostBudget.BudgetStatus.ACTIVE) {
            throw BusinessException(ErrorCode.BUDGET_NOT_ACTIVE)
        }
        
        // 할당 가능 여부 확인
        if (!budget.allocate(request.amount)) {
            throw BusinessException(ErrorCode.INSUFFICIENT_BUDGET_REMAINING)
        }
        
        budget.updatedBy = currentUser
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 사용
     */
    @Transactional
    fun spendBudget(budgetId: UUID, request: SpendBudgetRequest, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 활성 상태 확인
        if (budget.budgetStatus != CostBudget.BudgetStatus.ACTIVE) {
            throw BusinessException(ErrorCode.BUDGET_NOT_ACTIVE)
        }
        
        budget.spend(request.amount)
        budget.updatedBy = currentUser
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 약정
     */
    @Transactional
    fun commitBudget(budgetId: UUID, request: CommitBudgetRequest, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 활성 상태 확인
        if (budget.budgetStatus != CostBudget.BudgetStatus.ACTIVE) {
            throw BusinessException(ErrorCode.BUDGET_NOT_ACTIVE)
        }
        
        // 약정 가능 여부 확인
        if (!budget.commit(request.amount)) {
            throw BusinessException(ErrorCode.INSUFFICIENT_BUDGET_REMAINING)
        }
        
        budget.updatedBy = currentUser
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 조회
     */
    fun getBudget(budgetId: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        return CostBudgetDto.from(budget)
    }
    
    /**
     * 예산 목록 조회
     */
    fun getBudgets(filter: BudgetFilterDto?, pageable: Pageable): Page<CostBudgetDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        
        // 필터가 없는 경우 전체 조회
        if (filter == null) {
            return costBudgetRepository.findByCompanyCompanyIdOrderByCreatedAtDesc(companyId, pageable)
                .map { CostBudgetDto.from(it) }
        }
        
        // 필터 조건에 따른 조회 (간단한 구현, 실제로는 QueryDSL 사용 권장)
        return when {
            filter.budgetStatuses?.isNotEmpty() == true -> {
                costBudgetRepository.findByCompanyCompanyIdAndBudgetStatusOrderByCreatedAtDesc(
                    companyId, filter.budgetStatuses.first(), pageable
                ).map { CostBudgetDto.from(it) }
            }
            filter.budgetCategories?.isNotEmpty() == true -> {
                costBudgetRepository.findByCompanyCompanyIdAndBudgetCategoryOrderByCreatedAtDesc(
                    companyId, filter.budgetCategories.first(), pageable
                ).map { CostBudgetDto.from(it) }
            }
            filter.fiscalYear != null -> {
                costBudgetRepository.findByCompanyCompanyIdAndFiscalYearOrderByCreatedAtDesc(
                    companyId, filter.fiscalYear, pageable
                ).map { CostBudgetDto.from(it) }
            }
            else -> {
                costBudgetRepository.findByCompanyCompanyIdOrderByCreatedAtDesc(companyId, pageable)
                    .map { CostBudgetDto.from(it) }
            }
        }
    }
    
    /**
     * 활성 예산 조회
     */
    fun getActiveBudgets(): List<CostBudgetDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val currentDate = LocalDate.now()
        
        return costBudgetRepository.findByCompanyCompanyIdAndBudgetStatusAndStartDateLessThanEqualAndEndDateGreaterThanEqual(
            companyId, CostBudget.BudgetStatus.ACTIVE, currentDate, currentDate
        ).map { CostBudgetDto.from(it) }
    }
    
    /**
     * 경고 임계값 초과 예산 조회
     */
    fun getBudgetsExceedingAlertThreshold(): List<CostBudgetDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        
        return costBudgetRepository.findBudgetsExceedingAlertThreshold(companyId)
            .map { CostBudgetDto.from(it) }
    }
    
    /**
     * 위험 임계값 초과 예산 조회
     */
    fun getBudgetsExceedingCriticalThreshold(): List<CostBudgetDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        
        return costBudgetRepository.findBudgetsExceedingCriticalThreshold(companyId)
            .map { CostBudgetDto.from(it) }
    }
    
    /**
     * 예산 초과 조회
     */
    fun getOverBudgets(): List<CostBudgetDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        
        return costBudgetRepository.findOverBudgets(companyId)
            .map { CostBudgetDto.from(it) }
    }
    
    /**
     * 예산 상태 요약 조회
     */
    fun getBudgetStatus(fiscalYear: Int): BudgetStatusDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val totalStatus = costBudgetRepository.findTotalBudgetStatus(companyId, fiscalYear)
        val performanceMetrics = costBudgetRepository.findBudgetPerformanceMetrics(companyId)
        
        return if (totalStatus != null && performanceMetrics != null) {
            BudgetStatusDto(
                totalPlanned = totalStatus[0] as BigDecimal? ?: BigDecimal.ZERO,
                totalAllocated = totalStatus[1] as BigDecimal? ?: BigDecimal.ZERO,
                totalCommitted = totalStatus[2] as BigDecimal? ?: BigDecimal.ZERO,
                totalSpent = totalStatus[3] as BigDecimal? ?: BigDecimal.ZERO,
                totalRemaining = totalStatus[4] as BigDecimal? ?: BigDecimal.ZERO,
                overallUtilizationRate = performanceMetrics[4] as BigDecimal? ?: BigDecimal.ZERO,
                budgetCount = performanceMetrics[0] as Long? ?: 0L,
                activeBudgetCount = performanceMetrics[0] as Long? ?: 0L, // 별도 계산 필요
                alertCount = performanceMetrics[1] as Long? ?: 0L,
                criticalCount = performanceMetrics[2] as Long? ?: 0L,
                overBudgetCount = performanceMetrics[3] as Long? ?: 0L
            )
        } else {
            BudgetStatusDto(
                totalPlanned = BigDecimal.ZERO,
                totalAllocated = BigDecimal.ZERO,
                totalCommitted = BigDecimal.ZERO,
                totalSpent = BigDecimal.ZERO,
                totalRemaining = BigDecimal.ZERO,
                overallUtilizationRate = BigDecimal.ZERO,
                budgetCount = 0L,
                activeBudgetCount = 0L,
                alertCount = 0L,
                criticalCount = 0L,
                overBudgetCount = 0L
            )
        }
    }
    
    /**
     * 예산 대시보드 조회
     */
    fun getBudgetDashboard(fiscalYear: Int): BudgetDashboardDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        // 예산 상태
        val budgetStatus = getBudgetStatus(fiscalYear)
        
        // 분류별 예산 요약
        val budgetsByCategory = costBudgetRepository.findBudgetSummaryByCategory(companyId, fiscalYear)
            .map { result ->
                val category = result[0] as CostBudget.BudgetCategory
                val totalPlanned = result[1] as BigDecimal
                BudgetSummaryByCategoryDto(
                    budgetCategory = category,
                    totalPlanned = totalPlanned,
                    totalSpent = BigDecimal.ZERO, // 별도 쿼리 필요
                    utilizationRate = BigDecimal.ZERO, // 별도 계산 필요
                    budgetCount = 0L, // 별도 쿼리 필요
                    overBudgetCount = 0L // 별도 쿼리 필요
                )
            }
        
        // 기간별 예산 요약
        val budgetsByPeriod = costBudgetRepository.findBudgetSummaryByPeriod(companyId, fiscalYear)
            .map { result ->
                val period = result[0] as CostBudget.BudgetPeriod
                val totalPlanned = result[1] as BigDecimal
                val totalSpent = result[2] as BigDecimal
                BudgetSummaryByPeriodDto(
                    budgetPeriod = period,
                    totalPlanned = totalPlanned,
                    totalSpent = totalSpent,
                    utilizationRate = if (totalPlanned > BigDecimal.ZERO) {
                        totalSpent.divide(totalPlanned, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))
                    } else BigDecimal.ZERO,
                    budgetCount = 0L // 별도 쿼리 필요
                )
            }
        
        // 분기별 추세
        val quarterlyTrend = costBudgetRepository.findQuarterlyBudgetTrend(companyId, fiscalYear)
            .map { result ->
                val quarter = (result[0] as Number).toInt()
                val totalPlanned = result[1] as BigDecimal
                val totalSpent = result[2] as BigDecimal
                val avgUtilization = result[3] as BigDecimal
                QuarterlyBudgetTrendDto(
                    quarter = quarter,
                    totalPlanned = totalPlanned,
                    totalSpent = totalSpent,
                    averageUtilization = avgUtilization,
                    budgetCount = 0L // 별도 쿼리 필요
                )
            }
        
        // 성과 지표
        val performanceMetrics = costBudgetRepository.findBudgetPerformanceMetrics(companyId)?.let { metrics ->
            BudgetPerformanceDto(
                totalBudgets = metrics[0] as Long? ?: 0L,
                alertCount = metrics[1] as Long? ?: 0L,
                criticalCount = metrics[2] as Long? ?: 0L,
                overBudgetCount = metrics[3] as Long? ?: 0L,
                averageUtilization = metrics[4] as BigDecimal? ?: BigDecimal.ZERO,
                averageVariance = metrics[5] as BigDecimal? ?: BigDecimal.ZERO,
                onTimeCompletionRate = BigDecimal.ZERO, // 별도 계산 필요
                budgetAccuracyRate = BigDecimal.ZERO // 별도 계산 필요
            )
        } ?: BudgetPerformanceDto(
            totalBudgets = 0L,
            alertCount = 0L,
            criticalCount = 0L,
            overBudgetCount = 0L,
            averageUtilization = BigDecimal.ZERO,
            averageVariance = BigDecimal.ZERO,
            onTimeCompletionRate = BigDecimal.ZERO,
            budgetAccuracyRate = BigDecimal.ZERO
        )
        
        // 경고 예산들
        val alertingBudgets = getBudgetsExceedingAlertThreshold()
        val criticalBudgets = getBudgetsExceedingCriticalThreshold()
        val overBudgets = getOverBudgets()
        
        // 만료 예정 예산
        val expiringBudgets = costBudgetRepository.findExpiringBudgets(
            companyId, LocalDate.now(), LocalDate.now().plusDays(30)
        ).map { CostBudgetDto.from(it) }
        
        // 상위 성과자
        val topPerformers = costBudgetRepository.findBudgetPerformanceByOwner(companyId, fiscalYear)
            .map { result ->
                val ownerId = result[0] as UUID
                val budgetCount = result[1] as Long
                val totalPlanned = result[2] as BigDecimal
                val totalSpent = result[3] as BigDecimal
                val avgUtilization = result[4] as BigDecimal
                BudgetPerformanceByOwnerDto(
                    ownerId = ownerId,
                    budgetCount = budgetCount,
                    totalPlanned = totalPlanned,
                    totalSpent = totalSpent,
                    averageUtilization = avgUtilization,
                    overBudgetCount = 0L, // 별도 계산 필요
                    onTimeCompletionRate = BigDecimal.ZERO // 별도 계산 필요
                )
            }
        
        return BudgetDashboardDto(
            budgetStatus = budgetStatus,
            budgetsByCategory = budgetsByCategory,
            budgetsByPeriod = budgetsByPeriod,
            quarterlyTrend = quarterlyTrend,
            performanceMetrics = performanceMetrics,
            alertingBudgets = alertingBudgets,
            criticalBudgets = criticalBudgets,
            overBudgets = overBudgets,
            expiringBudgets = expiringBudgets,
            topPerformers = topPerformers
        )
    }
    
    /**
     * 예산 종료
     */
    @Transactional
    fun closeBudget(budgetId: UUID, reason: String?, @CurrentUser currentUser: UUID): CostBudgetDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        budget.close(reason)
        budget.updatedBy = currentUser
        
        val savedBudget = costBudgetRepository.save(budget)
        return CostBudgetDto.from(savedBudget)
    }
    
    /**
     * 예산 삭제
     */
    @Transactional
    fun deleteBudget(budgetId: UUID, @CurrentUser currentUser: UUID) {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val budget = costBudgetRepository.findById(budgetId)
            .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        
        // 회사 권한 확인
        if (budget.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 활성 상태의 예산은 삭제 불가
        if (budget.budgetStatus == CostBudget.BudgetStatus.ACTIVE) {
            throw BusinessException(ErrorCode.CANNOT_DELETE_ACTIVE_BUDGET)
        }
        
        // 사용된 예산은 삭제 불가
        if (budget.spentAmount > BigDecimal.ZERO) {
            throw BusinessException(ErrorCode.CANNOT_DELETE_USED_BUDGET)
        }
        
        costBudgetRepository.delete(budget)
    }
}