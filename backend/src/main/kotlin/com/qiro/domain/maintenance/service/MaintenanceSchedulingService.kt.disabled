package com.qiro.domain.maintenance.service

import com.qiro.domain.maintenance.dto.*
import com.qiro.domain.maintenance.entity.*
import com.qiro.domain.maintenance.repository.MaintenancePlanRepository
import com.qiro.domain.maintenance.repository.PreventiveMaintenanceExecutionRepository
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.*

/**
 * 정비 스케줄링 서비스
 * 자동 정비 일정 생성 및 알림 기능을 제공합니다.
 */
@Service
@Transactional
class MaintenanceSchedulingService(
    private val maintenancePlanRepository: MaintenancePlanRepository,
    private val preventiveMaintenanceExecutionRepository: PreventiveMaintenanceExecutionRepository
) {
    private val logger = LoggerFactory.getLogger(MaintenanceSchedulingService::class.java)

    /**
     * 정비 계획 생성
     */
    fun createMaintenancePlan(request: CreateMaintenancePlanRequest): MaintenancePlanDto {
        logger.info("정비 계획 생성 시작: planCode={}, assetId={}", request.planCode, request.assetId)

        // 중복 계획 코드 확인
        maintenancePlanRepository.findByCompanyIdAndPlanCode(request.companyId, request.planCode)?.let {
            throw IllegalArgumentException("이미 존재하는 계획 코드입니다: ${request.planCode}")
        }

        val maintenancePlan = MaintenancePlan(
            companyId = request.companyId,
            assetId = request.assetId,
            planName = request.planName,
            planCode = request.planCode,
            planDescription = request.planDescription,
            planType = request.planType,
            maintenanceStrategy = request.maintenanceStrategy,
            maintenanceApproach = request.maintenanceApproach,
            criticalityAnalysis = request.criticalityAnalysis,
            frequencyType = request.frequencyType,
            frequencyInterval = request.frequencyInterval,
            frequencyUnit = request.frequencyUnit,
            estimatedDurationHours = request.estimatedDurationHours,
            estimatedCost = request.estimatedCost,
            requiredDowntimeHours = request.requiredDowntimeHours,
            requiredPersonnel = request.requiredPersonnel,
            requiredSkills = request.requiredSkills,
            requiredTools = request.requiredTools,
            requiredParts = request.requiredParts,
            safetyRequirements = request.safetyRequirements,
            permitRequirements = request.permitRequirements,
            regulatoryCompliance = request.regulatoryCompliance,
            targetAvailability = request.targetAvailability,
            targetReliability = request.targetReliability,
            targetCostPerYear = request.targetCostPerYear,
            effectiveDate = request.effectiveDate,
            reviewDate = request.reviewDate,
            createdBy = request.createdBy
        )

        val savedPlan = maintenancePlanRepository.save(maintenancePlan)
        logger.info("정비 계획 생성 완료: planId={}", savedPlan.planId)

        return convertToDto(savedPlan)
    }

    /**
     * 자동 정비 일정 생성
     */
    fun generateMaintenanceSchedules(companyId: UUID, targetDate: LocalDate): List<PreventiveMaintenanceExecutionDto> {
        logger.info("자동 정비 일정 생성 시작: companyId={}, targetDate={}", companyId, targetDate)

        val plansNeedingExecution = maintenancePlanRepository.findPlansNeedingExecution(
            companyId = companyId,
            currentDate = targetDate,
            lastExecutionDate = targetDate.minusDays(365) // 지난 1년간 실행 내역 확인
        )

        val generatedExecutions = mutableListOf<PreventiveMaintenanceExecutionDto>()

        plansNeedingExecution.forEach { plan ->
            try {
                val nextExecutionDate = calculateNextExecutionDate(plan, targetDate)
                if (nextExecutionDate != null && nextExecutionDate <= targetDate.plusDays(30)) { // 30일 이내 실행 예정
                    val execution = createScheduledExecution(plan, nextExecutionDate)
                    generatedExecutions.add(execution)
                }
            } catch (e: Exception) {
                logger.error("정비 일정 생성 실패: planId={}, error={}", plan.planId, e.message)
            }
        }

        logger.info("자동 정비 일정 생성 완료: 생성된 일정 수={}", generatedExecutions.size)
        return generatedExecutions
    }

    /**
     * 다음 실행 날짜 계산
     */
    private fun calculateNextExecutionDate(plan: MaintenancePlan, baseDate: LocalDate): LocalDate? {
        val lastExecution = preventiveMaintenanceExecutionRepository.findLastCompletedExecutionByPlan(plan.planId)
        val lastExecutionDate = lastExecution?.executionDate ?: plan.effectiveDate

        return when (plan.frequencyType) {
            FrequencyType.DAILY -> lastExecutionDate.plusDays(plan.frequencyInterval.toLong())
            FrequencyType.WEEKLY -> lastExecutionDate.plusWeeks(plan.frequencyInterval.toLong())
            FrequencyType.MONTHLY -> lastExecutionDate.plusMonths(plan.frequencyInterval.toLong())
            FrequencyType.QUARTERLY -> lastExecutionDate.plusMonths((plan.frequencyInterval * 3).toLong())
            FrequencyType.SEMI_ANNUALLY -> lastExecutionDate.plusMonths((plan.frequencyInterval * 6).toLong())
            FrequencyType.ANNUALLY -> lastExecutionDate.plusYears(plan.frequencyInterval.toLong())
            FrequencyType.CUSTOM -> {
                // 사용자 정의 주기는 frequencyUnit에 따라 처리
                when (plan.frequencyUnit?.uppercase()) {
                    "DAYS" -> lastExecutionDate.plusDays(plan.frequencyInterval.toLong())
                    "WEEKS" -> lastExecutionDate.plusWeeks(plan.frequencyInterval.toLong())
                    "MONTHS" -> lastExecutionDate.plusMonths(plan.frequencyInterval.toLong())
                    "YEARS" -> lastExecutionDate.plusYears(plan.frequencyInterval.toLong())
                    else -> null
                }
            }
        }
    }

    /**
     * 예약된 실행 생성
     */
    private fun createScheduledExecution(plan: MaintenancePlan, executionDate: LocalDate): PreventiveMaintenanceExecutionDto {
        val executionNumber = generateExecutionNumber(plan.companyId, executionDate)
        
        val execution = PreventiveMaintenanceExecution(
            companyId = plan.companyId,
            planId = plan.planId,
            assetId = plan.assetId,
            executionNumber = executionNumber,
            executionType = ExecutionType.SCHEDULED,
            executionDate = executionDate,
            plannedDurationHours = plan.estimatedDurationHours,
            equipmentShutdownRequired = plan.requiredDowntimeHours > BigDecimal.ZERO,
            plannedCost = plan.estimatedCost,
            executionStatus = ExecutionStatus.PLANNED
        )

        val savedExecution = preventiveMaintenanceExecutionRepository.save(execution)
        logger.info("예약된 정비 실행 생성: executionId={}, executionNumber={}", 
                   savedExecution.executionId, savedExecution.executionNumber)

        return convertToDto(savedExecution)
    }

    /**
     * 실행 번호 생성
     */
    private fun generateExecutionNumber(companyId: UUID, executionDate: LocalDate): String {
        val datePrefix = executionDate.format(DateTimeFormatter.ofPattern("yyyyMMdd"))
        val sequence = preventiveMaintenanceExecutionRepository.getNextExecutionSequence(companyId, datePrefix)
        return "${datePrefix}-${String.format("%03d", sequence)}"
    }

    /**
     * 예정된 정비 알림 조회
     */
    @Transactional(readOnly = true)
    fun getUpcomingMaintenanceNotifications(companyId: UUID, days: Int): List<MaintenanceScheduleNotificationDto> {
        logger.info("예정된 정비 알림 조회: companyId={}, days={}", companyId, days)

        val startDate = LocalDate.now()
        val endDate = startDate.plusDays(days.toLong())

        val upcomingExecutions = preventiveMaintenanceExecutionRepository.findUpcomingExecutions(
            companyId = companyId,
            startDate = startDate,
            endDate = endDate
        )

        return upcomingExecutions.map { execution ->
            val plan = maintenancePlanRepository.findById(execution.planId).orElse(null)
            val daysUntil = java.time.temporal.ChronoUnit.DAYS.between(startDate, execution.executionDate)
            
            MaintenanceScheduleNotificationDto(
                executionId = execution.executionId,
                executionNumber = execution.executionNumber,
                planName = plan?.planName ?: "Unknown Plan",
                assetName = "Asset-${execution.assetId}", // 실제로는 Asset 정보를 조회해야 함
                executionDate = execution.executionDate,
                plannedStartTime = execution.plannedStartTime,
                leadTechnicianId = execution.leadTechnicianId,
                notificationType = when {
                    daysUntil <= 1 -> NotificationType.URGENT_MAINTENANCE
                    daysUntil <= 3 -> NotificationType.UPCOMING_MAINTENANCE
                    else -> NotificationType.MAINTENANCE_REMINDER
                },
                daysUntilExecution = daysUntil
            )
        }
    }

    /**
     * 지연된 정비 알림 조회
     */
    @Transactional(readOnly = true)
    fun getOverdueMaintenanceNotifications(companyId: UUID): List<MaintenanceScheduleNotificationDto> {
        logger.info("지연된 정비 알림 조회: companyId={}", companyId)

        val overdueExecutions = preventiveMaintenanceExecutionRepository.findOverdueExecutions(
            companyId = companyId,
            currentDate = LocalDate.now()
        )

        return overdueExecutions.map { execution ->
            val plan = maintenancePlanRepository.findById(execution.planId).orElse(null)
            val daysOverdue = java.time.temporal.ChronoUnit.DAYS.between(execution.executionDate, LocalDate.now())
            
            MaintenanceScheduleNotificationDto(
                executionId = execution.executionId,
                executionNumber = execution.executionNumber,
                planName = plan?.planName ?: "Unknown Plan",
                assetName = "Asset-${execution.assetId}",
                executionDate = execution.executionDate,
                plannedStartTime = execution.plannedStartTime,
                leadTechnicianId = execution.leadTechnicianId,
                notificationType = NotificationType.OVERDUE_MAINTENANCE,
                daysUntilExecution = -daysOverdue
            )
        }
    }

    /**
     * 정비 계획 조회
     */
    @Transactional(readOnly = true)
    fun getMaintenancePlans(filter: MaintenancePlanFilter, pageable: Pageable): Page<MaintenancePlanDto> {
        val plans = maintenancePlanRepository.findByCompanyIdAndPlanStatus(
            filter.companyId,
            filter.planStatus ?: PlanStatus.ACTIVE,
            pageable
        )
        return plans.map { convertToDto(it) }
    }

    /**
     * 정비 계획 상세 조회
     */
    @Transactional(readOnly = true)
    fun getMaintenancePlan(planId: UUID): MaintenancePlanDto {
        val plan = maintenancePlanRepository.findById(planId)
            .orElseThrow { IllegalArgumentException("정비 계획을 찾을 수 없습니다: $planId") }
        return convertToDto(plan)
    }

    /**
     * 정비 계획 통계 조회
     */
    @Transactional(readOnly = true)
    fun getMaintenancePlanStatistics(companyId: UUID): MaintenancePlanStatisticsDto {
        val statistics = maintenancePlanRepository.getMaintenancePlanStatistics(companyId)
        val totalPlans = statistics.sumOf { it[1] as Long }
        val activePlans = statistics.find { it[0] == PlanStatus.ACTIVE }?.get(1) as Long? ?: 0L
        
        return MaintenancePlanStatisticsDto(
            totalPlans = totalPlans,
            activePlans = activePlans,
            pendingApprovalPlans = statistics.find { it[0] == ApprovalStatus.PENDING }?.get(1) as Long? ?: 0L,
            overdueReviewPlans = maintenancePlanRepository.findPlansForReview(companyId, LocalDate.now()).size.toLong(),
            lowEffectivenessPlans = maintenancePlanRepository.findLowEffectivenessPlan(companyId, 70.0).size.toLong(),
            budgetRiskPlans = maintenancePlanRepository.findBudgetRiskPlans(companyId, 0.8).size.toLong(),
            plansByType = emptyMap(), // 실제 구현에서는 통계 데이터 변환 필요
            plansByStrategy = emptyMap()
        )
    }

    /**
     * MaintenancePlan 엔티티를 DTO로 변환
     */
    private fun convertToDto(plan: MaintenancePlan): MaintenancePlanDto {
        return MaintenancePlanDto(
            planId = plan.planId,
            companyId = plan.companyId,
            assetId = plan.assetId,
            planName = plan.planName,
            planCode = plan.planCode,
            planDescription = plan.planDescription,
            planType = plan.planType,
            maintenanceStrategy = plan.maintenanceStrategy,
            maintenanceApproach = plan.maintenanceApproach,
            criticalityAnalysis = plan.criticalityAnalysis,
            frequencyType = plan.frequencyType,
            frequencyInterval = plan.frequencyInterval,
            frequencyUnit = plan.frequencyUnit,
            estimatedDurationHours = plan.estimatedDurationHours,
            estimatedCost = plan.estimatedCost,
            requiredDowntimeHours = plan.requiredDowntimeHours,
            requiredPersonnel = plan.requiredPersonnel,
            requiredSkills = plan.requiredSkills,
            requiredTools = plan.requiredTools,
            requiredParts = plan.requiredParts,
            safetyRequirements = plan.safetyRequirements,
            permitRequirements = plan.permitRequirements,
            regulatoryCompliance = plan.regulatoryCompliance,
            targetAvailability = plan.targetAvailability,
            targetReliability = plan.targetReliability,
            targetCostPerYear = plan.targetCostPerYear,
            planStatus = plan.planStatus,
            approvalStatus = plan.approvalStatus,
            effectiveDate = plan.effectiveDate,
            reviewDate = plan.reviewDate,
            actualCostYtd = plan.actualCostYtd,
            actualHoursYtd = plan.actualHoursYtd,
            completionRate = plan.completionRate,
            effectivenessScore = plan.effectivenessScore,
            createdAt = plan.createdAt,
            updatedAt = plan.updatedAt,
            createdBy = plan.createdBy,
            updatedBy = plan.updatedBy,
            approvedBy = plan.approvedBy,
            approvedAt = plan.approvedAt
        )
    }

    /**
     * PreventiveMaintenanceExecution 엔티티를 DTO로 변환
     */
    private fun convertToDto(execution: PreventiveMaintenanceExecution): PreventiveMaintenanceExecutionDto {
        return PreventiveMaintenanceExecutionDto(
            executionId = execution.executionId,
            companyId = execution.companyId,
            planId = execution.planId,
            assetId = execution.assetId,
            executionNumber = execution.executionNumber,
            executionType = execution.executionType,
            executionDate = execution.executionDate,
            plannedStartTime = execution.plannedStartTime,
            actualStartTime = execution.actualStartTime,
            plannedEndTime = execution.plannedEndTime,
            actualEndTime = execution.actualEndTime,
            plannedDurationHours = execution.plannedDurationHours,
            actualDurationHours = execution.actualDurationHours,
            downtimeHours = execution.downtimeHours,
            maintenanceTeam = execution.maintenanceTeam,
            leadTechnicianId = execution.leadTechnicianId,
            supportingTechnicians = execution.supportingTechnicians,
            contractorId = execution.contractorId,
            executionStatus = execution.executionStatus,
            completionPercentage = execution.completionPercentage,
            equipmentShutdownRequired = execution.equipmentShutdownRequired,
            shutdownStartTime = execution.shutdownStartTime,
            shutdownEndTime = execution.shutdownEndTime,
            environmentalConditions = execution.environmentalConditions,
            safetyBriefingCompleted = execution.safetyBriefingCompleted,
            permitsObtained = execution.permitsObtained,
            lockoutTagoutApplied = execution.lockoutTagoutApplied,
            safetyIncidents = execution.safetyIncidents,
            materialsUsed = execution.materialsUsed,
            toolsUsed = execution.toolsUsed,
            sparePartsConsumed = execution.sparePartsConsumed,
            plannedCost = execution.plannedCost,
            actualCost = execution.actualCost,
            laborCost = execution.laborCost,
            materialCost = execution.materialCost,
            contractorCost = execution.contractorCost,
            workQualityRating = execution.workQualityRating,
            assetConditionBefore = execution.assetConditionBefore,
            assetConditionAfter = execution.assetConditionAfter,
            performanceImprovement = execution.performanceImprovement,
            issuesEncountered = execution.issuesEncountered,
            unexpectedFindings = execution.unexpectedFindings,
            additionalWorkRequired = execution.additionalWorkRequired,
            followUpActions = execution.followUpActions,
            workPhotos = execution.workPhotos,
            completionCertificates = execution.completionCertificates,
            testResults = execution.testResults,
            maintenanceReports = execution.maintenanceReports,
            workCompletedBy = execution.workCompletedBy,
            workCompletionDate = execution.workCompletionDate,
            reviewedBy = execution.reviewedBy,
            reviewDate = execution.reviewDate,
            approvedBy = execution.approvedBy,
            approvalDate = execution.approvalDate,
            technicianNotes = execution.technicianNotes,
            supervisorComments = execution.supervisorComments,
            lessonsLearned = execution.lessonsLearned,
            recommendations = execution.recommendations,
            createdAt = execution.createdAt,
            updatedAt = execution.updatedAt,
            createdBy = execution.createdBy,
            updatedBy = execution.updatedBy
        )
    }
}