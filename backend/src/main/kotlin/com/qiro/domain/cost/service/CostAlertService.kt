package com.qiro.domain.cost.service

import com.qiro.common.exception.BusinessException
import com.qiro.common.exception.ErrorCode
import com.qiro.common.security.CurrentUser
import com.qiro.common.service.DataIntegrityService
import com.qiro.common.tenant.TenantContext
import com.qiro.domain.company.repository.CompanyRepository
import com.qiro.domain.cost.dto.*
import com.qiro.domain.cost.entity.CostAlert
import com.qiro.domain.cost.entity.CostBudget
import com.qiro.domain.cost.repository.CostAlertRepository
import com.qiro.domain.cost.repository.CostBudgetRepository
import com.qiro.domain.user.repository.UserRepository
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.*

/**
 * 비용 경고 관리 서비스
 * 예산 초과 및 비용 관련 경고를 생성하고 관리하는 서비스
 */
@Service
@Transactional(readOnly = true)
class CostAlertService(
    private val costAlertRepository: CostAlertRepository,
    private val costBudgetRepository: CostBudgetRepository,
    private val companyRepository: CompanyRepository,
    private val userRepository: UserRepository,
    private val dataIntegrityService: DataIntegrityService
) {
    
    /**
     * 경고 생성
     */
    @Transactional
    fun createAlert(request: CreateCostAlertRequest, @CurrentUser currentUser: UUID): CostAlertDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        // 데이터 무결성 검증
        dataIntegrityService.validateCompanyExists(companyId)
        
        val company = companyRepository.findById(companyId)
            .orElseThrow { BusinessException(ErrorCode.COMPANY_NOT_FOUND) }
        
        // 예산 검증 (있는 경우)
        val budget = request.budgetId?.let { budgetId ->
            costBudgetRepository.findById(budgetId)
                .orElseThrow { BusinessException(ErrorCode.BUDGET_NOT_FOUND) }
        }
        
        // 중복 경고 확인 (같은 예산, 같은 유형의 활성 경고)
        if (budget != null) {
            val duplicateAlerts = costAlertRepository.findDuplicateAlerts(
                companyId, budget.budgetId, request.alertType
            )
            if (duplicateAlerts.isNotEmpty()) {
                // 기존 경고의 재발생으로 처리
                val existingAlert = duplicateAlerts.first()
                existingAlert.recordRecurrence()
                costAlertRepository.save(existingAlert)
                return CostAlertDto.from(existingAlert)
            }
        }
        
        // 경고 엔티티 생성
        val alert = CostAlert().apply {
            this.company = company
            this.budget = budget
            this.alertType = request.alertType
            this.alertSeverity = request.alertSeverity
            this.alertTitle = request.alertTitle
            this.alertMessage = request.alertMessage
            this.thresholdValue = request.thresholdValue
            this.currentValue = request.currentValue
            this.varianceAmount = request.varianceAmount
            this.variancePercentage = request.variancePercentage
            this.metadata = request.metadata
            this.createdBy = currentUser
            this.updatedBy = currentUser
        }
        
        val savedAlert = costAlertRepository.save(alert)
        return CostAlertDto.from(savedAlert)
    }
    
    /**
     * 예산 임계값 경고 자동 생성
     */
    @Transactional
    fun generateBudgetThresholdAlerts(): List<CostAlertDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val generatedAlerts = mutableListOf<CostAlertDto>()
        
        // 경고 임계값 초과 예산 조회
        val alertingBudgets = costBudgetRepository.findBudgetsExceedingAlertThreshold(companyId)
        
        alertingBudgets.forEach { budget ->
            // 기존 활성 경고가 없는 경우에만 생성
            val existingAlerts = costAlertRepository.findDuplicateAlerts(
                companyId, budget.budgetId, CostAlert.AlertType.BUDGET_THRESHOLD
            )
            
            if (existingAlerts.isEmpty()) {
                val alert = createBudgetThresholdAlert(budget, CostAlert.AlertSeverity.MEDIUM)
                generatedAlerts.add(alert)
            }
        }
        
        // 위험 임계값 초과 예산 조회
        val criticalBudgets = costBudgetRepository.findBudgetsExceedingCriticalThreshold(companyId)
        
        criticalBudgets.forEach { budget ->
            val existingAlerts = costAlertRepository.findDuplicateAlerts(
                companyId, budget.budgetId, CostAlert.AlertType.BUDGET_THRESHOLD
            )
            
            if (existingAlerts.isEmpty()) {
                val alert = createBudgetThresholdAlert(budget, CostAlert.AlertSeverity.HIGH)
                generatedAlerts.add(alert)
            } else {
                // 기존 경고의 심각도 상승
                val existingAlert = existingAlerts.first()
                if (existingAlert.alertSeverity != CostAlert.AlertSeverity.CRITICAL) {
                    existingAlert.escalate()
                    costAlertRepository.save(existingAlert)
                }
            }
        }
        
        // 예산 초과 경고 생성
        val overBudgets = costBudgetRepository.findOverBudgets(companyId)
        
        overBudgets.forEach { budget ->
            val existingAlerts = costAlertRepository.findDuplicateAlerts(
                companyId, budget.budgetId, CostAlert.AlertType.BUDGET_EXCEEDED
            )
            
            if (existingAlerts.isEmpty()) {
                val alert = createBudgetExceededAlert(budget)
                generatedAlerts.add(alert)
            }
        }
        
        return generatedAlerts
    }
    
    /**
     * 예산 임계값 경고 생성
     */
    private fun createBudgetThresholdAlert(budget: CostBudget, severity: CostAlert.AlertSeverity): CostAlertDto {
        val company = budget.company
        
        val alert = CostAlert().apply {
            this.company = company
            this.budget = budget
            this.alertType = CostAlert.AlertType.BUDGET_THRESHOLD
            this.alertSeverity = severity
            this.alertTitle = "예산 임계값 초과 경고"
            this.alertMessage = generateAlertMessage()
            this.thresholdValue = if (severity == CostAlert.AlertSeverity.HIGH) {
                budget.criticalThreshold
            } else {
                budget.alertThreshold
            }
            this.currentValue = budget.utilizationRate
            this.varianceAmount = budget.spentAmount.subtract(
                budget.plannedAmount.multiply(thresholdValue!!).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP)
            )
            this.variancePercentage = budget.utilizationRate.subtract(thresholdValue!!)
        }
        
        val savedAlert = costAlertRepository.save(alert)
        return CostAlertDto.from(savedAlert)
    }
    
    /**
     * 예산 초과 경고 생성
     */
    private fun createBudgetExceededAlert(budget: CostBudget): CostAlertDto {
        val company = budget.company
        
        val alert = CostAlert().apply {
            this.company = company
            this.budget = budget
            this.alertType = CostAlert.AlertType.BUDGET_EXCEEDED
            this.alertSeverity = CostAlert.AlertSeverity.CRITICAL
            this.alertTitle = "예산 초과 경고"
            this.alertMessage = generateAlertMessage()
            this.thresholdValue = BigDecimal.valueOf(100) // 100%
            this.currentValue = budget.utilizationRate
            this.varianceAmount = budget.varianceAmount
            this.variancePercentage = budget.variancePercentage
        }
        
        val savedAlert = costAlertRepository.save(alert)
        return CostAlertDto.from(savedAlert)
    }
    
    /**
     * 경고 해결
     */
    @Transactional
    fun resolveAlert(alertId: UUID, request: ResolveCostAlertRequest, @CurrentUser currentUser: UUID): CostAlertDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val alert = costAlertRepository.findById(alertId)
            .orElseThrow { BusinessException(ErrorCode.ALERT_NOT_FOUND) }
        
        // 회사 권한 확인
        if (alert.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 해결 가능 상태 확인
        if (alert.alertStatus == CostAlert.AlertStatus.RESOLVED) {
            throw BusinessException(ErrorCode.ALERT_ALREADY_RESOLVED)
        }
        
        val resolver = userRepository.findById(currentUser)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        
        alert.resolve(resolver, request.resolutionNotes)
        
        val savedAlert = costAlertRepository.save(alert)
        return CostAlertDto.from(savedAlert)
    }
    
    /**
     * 경고 확인
     */
    @Transactional
    fun acknowledgeAlert(alertId: UUID, @CurrentUser currentUser: UUID): CostAlertDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val alert = costAlertRepository.findById(alertId)
            .orElseThrow { BusinessException(ErrorCode.ALERT_NOT_FOUND) }
        
        // 회사 권한 확인
        if (alert.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        val user = userRepository.findById(currentUser)
            .orElseThrow { BusinessException(ErrorCode.USER_NOT_FOUND) }
        
        alert.acknowledge(user)
        
        val savedAlert = costAlertRepository.save(alert)
        return CostAlertDto.from(savedAlert)
    }
    
    /**
     * 경고 억제
     */
    @Transactional
    fun suppressAlert(alertId: UUID, request: SuppressCostAlertRequest, @CurrentUser currentUser: UUID): CostAlertDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val alert = costAlertRepository.findById(alertId)
            .orElseThrow { BusinessException(ErrorCode.ALERT_NOT_FOUND) }
        
        // 회사 권한 확인
        if (alert.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        alert.suppress(request.suppressDurationMinutes)
        
        val savedAlert = costAlertRepository.save(alert)
        return CostAlertDto.from(savedAlert)
    }
    
    /**
     * 경고 에스컬레이션 처리
     */
    @Transactional
    fun processEscalations(): List<CostAlertDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val thresholdTime = LocalDateTime.now().minusHours(1) // 1시간 경과
        
        val alertsNeedingEscalation = costAlertRepository.findAlertsNeedingEscalation(companyId, thresholdTime)
        val escalatedAlerts = mutableListOf<CostAlertDto>()
        
        alertsNeedingEscalation.forEach { alert ->
            alert.escalate()
            val savedAlert = costAlertRepository.save(alert)
            escalatedAlerts.add(CostAlertDto.from(savedAlert))
        }
        
        return escalatedAlerts
    }
    
    /**
     * 억제된 경고 복원 처리
     */
    @Transactional
    fun restoreSuppressedAlerts(): List<CostAlertDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val currentTime = LocalDateTime.now()
        
        val expiredSuppressedAlerts = costAlertRepository.findExpiredSuppressedAlerts(companyId, currentTime)
        val restoredAlerts = mutableListOf<CostAlertDto>()
        
        expiredSuppressedAlerts.forEach { alert ->
            alert.alertStatus = CostAlert.AlertStatus.ACTIVE
            alert.suppressedUntil = null
            val savedAlert = costAlertRepository.save(alert)
            restoredAlerts.add(CostAlertDto.from(savedAlert))
        }
        
        return restoredAlerts
    }
    
    /**
     * 경고 조회
     */
    fun getAlert(alertId: UUID): CostAlertDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val alert = costAlertRepository.findById(alertId)
            .orElseThrow { BusinessException(ErrorCode.ALERT_NOT_FOUND) }
        
        // 회사 권한 확인
        if (alert.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        return CostAlertDto.from(alert)
    }
    
    /**
     * 경고 목록 조회
     */
    fun getAlerts(filter: AlertFilterDto?, pageable: Pageable): Page<CostAlertDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        
        // 필터가 없는 경우 전체 조회
        if (filter == null) {
            return costAlertRepository.findByCompanyCompanyIdOrderByTriggeredAtDesc(companyId, pageable)
                .map { CostAlertDto.from(it) }
        }
        
        // 필터 조건에 따른 조회 (간단한 구현, 실제로는 QueryDSL 사용 권장)
        return when {
            filter.alertTypes?.isNotEmpty() == true -> {
                costAlertRepository.findByCompanyCompanyIdAndAlertTypeOrderByTriggeredAtDesc(
                    companyId, filter.alertTypes.first(), pageable
                ).map { CostAlertDto.from(it) }
            }
            filter.alertSeverities?.isNotEmpty() == true -> {
                costAlertRepository.findByCompanyCompanyIdAndAlertSeverityOrderByTriggeredAtDesc(
                    companyId, filter.alertSeverities.first(), pageable
                ).map { CostAlertDto.from(it) }
            }
            filter.alertStatuses?.isNotEmpty() == true -> {
                costAlertRepository.findByCompanyCompanyIdAndAlertStatusOrderByTriggeredAtDesc(
                    companyId, filter.alertStatuses.first(), pageable
                ).map { CostAlertDto.from(it) }
            }
            else -> {
                costAlertRepository.findByCompanyCompanyIdOrderByTriggeredAtDesc(companyId, pageable)
                    .map { CostAlertDto.from(it) }
            }
        }
    }
    
    /**
     * 활성 경고 조회
     */
    fun getActiveAlerts(): List<CostAlertDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val activeStatuses = listOf(CostAlert.AlertStatus.ACTIVE, CostAlert.AlertStatus.ACKNOWLEDGED)
        
        return costAlertRepository.findByCompanyCompanyIdAndAlertStatusInOrderByAlertSeverityDescTriggeredAtDesc(
            companyId, activeStatuses
        ).map { CostAlertDto.from(it) }
    }
    
    /**
     * 위험 수준 경고 조회
     */
    fun getCriticalAlerts(): List<CostAlertDto> {
        val companyId = TenantContext.getCurrentCompanyId()
        val criticalSeverities = listOf(CostAlert.AlertSeverity.HIGH, CostAlert.AlertSeverity.CRITICAL)
        
        return costAlertRepository.findByCompanyCompanyIdAndAlertSeverityInAndAlertStatusOrderByTriggeredAtDesc(
            companyId, criticalSeverities, CostAlert.AlertStatus.ACTIVE
        ).map { CostAlertDto.from(it) }
    }
    
    /**
     * 경고 대시보드 조회
     */
    fun getAlertDashboard(startDate: LocalDateTime, endDate: LocalDateTime): AlertDashboardDto {
        val companyId = TenantContext.getCurrentCompanyId()
        
        // 활성 경고 통계
        val activeAlerts = getActiveAlerts()
        val totalActiveAlerts = activeAlerts.size.toLong()
        val criticalAlerts = activeAlerts.count { it.alertSeverity == CostAlert.AlertSeverity.CRITICAL }.toLong()
        val highAlerts = activeAlerts.count { it.alertSeverity == CostAlert.AlertSeverity.HIGH }.toLong()
        val mediumAlerts = activeAlerts.count { it.alertSeverity == CostAlert.AlertSeverity.MEDIUM }.toLong()
        val lowAlerts = activeAlerts.count { it.alertSeverity == CostAlert.AlertSeverity.LOW }.toLong()
        
        // 에스컬레이션된 경고
        val escalatedAlerts = costAlertRepository.findEscalatedAlerts(companyId).size.toLong()
        
        // 반복 경고
        val recurringAlerts = costAlertRepository.findRecurringAlerts(companyId).size.toLong()
        
        // 평균 해결 시간
        val resolutionAnalysis = costAlertRepository.findResolutionTimeAnalysis(companyId, startDate, endDate)
        val averageResolutionTime = if (resolutionAnalysis.isNotEmpty()) {
            resolutionAnalysis.map { it[1] as BigDecimal }.average().toBigDecimal()
        } else {
            BigDecimal.ZERO
        }
        
        // 경고 유형별 통계
        val alertsByType = costAlertRepository.findAlertStatisticsByType(companyId, startDate, endDate)
            .map { result ->
                val alertType = result[0] as CostAlert.AlertType
                val totalCount = result[1] as Long
                val activeCount = result[2] as Long
                val resolvedCount = result[3] as Long
                val avgRecurrence = result[4] as BigDecimal
                AlertStatisticsDto(
                    alertType = alertType,
                    totalCount = totalCount,
                    activeCount = activeCount,
                    resolvedCount = resolvedCount,
                    averageRecurrence = avgRecurrence
                )
            }
        
        // 심각도별 통계
        val alertsBySeverity = costAlertRepository.findAlertStatisticsBySeverity(companyId, startDate, endDate)
            .map { result ->
                val alertSeverity = result[0] as CostAlert.AlertSeverity
                val totalCount = result[1] as Long
                val activeCount = result[2] as Long
                val avgResolutionHours = result[3] as BigDecimal?
                AlertStatisticsBySeverityDto(
                    alertSeverity = alertSeverity,
                    totalCount = totalCount,
                    activeCount = activeCount,
                    averageResolutionHours = avgResolutionHours
                )
            }
        
        // 일별 추세
        val dailyTrend = costAlertRepository.findDailyAlertTrend(companyId, startDate, endDate)
            .map { result ->
                val alertDate = result[0].toString()
                val dailyCount = result[1] as Long
                val criticalCount = result[2] as Long
                DailyAlertTrendDto(
                    alertDate = alertDate,
                    dailyCount = dailyCount,
                    criticalCount = criticalCount
                )
            }
        
        // 예산별 경고 빈도
        val budgetAlertFrequency = costAlertRepository.findAlertFrequencyByBudget(companyId, startDate, endDate)
            .map { result ->
                val budgetId = result[0] as UUID
                val budgetName = result[1] as String
                val alertCount = result[2] as Long
                val lastAlertTime = result[3] as LocalDateTime
                AlertFrequencyByBudgetDto(
                    budgetId = budgetId,
                    budgetName = budgetName,
                    alertCount = alertCount,
                    lastAlertTime = lastAlertTime
                )
            }
        
        // 해결 시간 분석
        val resolutionAnalysisDto = resolutionAnalysis.map { result ->
            val alertType = result[0] as CostAlert.AlertType
            val avgResolutionHours = result[1] as BigDecimal
            val minResolutionHours = result[2] as BigDecimal
            val maxResolutionHours = result[3] as BigDecimal
            AlertResolutionAnalysisDto(
                alertType = alertType,
                averageResolutionHours = avgResolutionHours,
                minResolutionHours = minResolutionHours,
                maxResolutionHours = maxResolutionHours,
                totalResolved = 0L // 별도 계산 필요
            )
        }
        
        // 최근 위험 경고
        val recentCriticalAlerts = activeAlerts
            .filter { it.alertSeverity == CostAlert.AlertSeverity.CRITICAL }
            .sortedByDescending { it.triggeredAt }
            .take(10)
        
        // 에스컬레이션 대기 경고
        val pendingEscalation = costAlertRepository.findAlertsNeedingEscalation(
            companyId, LocalDateTime.now().minusMinutes(30)
        ).map { CostAlertDto.from(it) }
        
        return AlertDashboardDto(
            totalActiveAlerts = totalActiveAlerts,
            criticalAlerts = criticalAlerts,
            highAlerts = highAlerts,
            mediumAlerts = mediumAlerts,
            lowAlerts = lowAlerts,
            escalatedAlerts = escalatedAlerts,
            recurringAlerts = recurringAlerts,
            averageResolutionTime = averageResolutionTime,
            alertsByType = alertsByType,
            alertsBySeverity = alertsBySeverity,
            dailyTrend = dailyTrend,
            budgetAlertFrequency = budgetAlertFrequency,
            resolutionAnalysis = resolutionAnalysisDto,
            recentCriticalAlerts = recentCriticalAlerts,
            pendingEscalation = pendingEscalation
        )
    }
    
    /**
     * 경고 삭제
     */
    @Transactional
    fun deleteAlert(alertId: UUID, @CurrentUser currentUser: UUID) {
        val companyId = TenantContext.getCurrentCompanyId()
        
        val alert = costAlertRepository.findById(alertId)
            .orElseThrow { BusinessException(ErrorCode.ALERT_NOT_FOUND) }
        
        // 회사 권한 확인
        if (alert.company.companyId != companyId) {
            throw BusinessException(ErrorCode.ACCESS_DENIED)
        }
        
        // 활성 상태의 경고는 삭제 불가
        if (alert.alertStatus == CostAlert.AlertStatus.ACTIVE) {
            throw BusinessException(ErrorCode.CANNOT_DELETE_ACTIVE_ALERT)
        }
        
        costAlertRepository.delete(alert)
    }
}