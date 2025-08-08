package com.qiro.common.dto

import com.qiro.domain.validation.dto.DataIntegrityCheckResultDto
import com.qiro.domain.performance.dto.SystemHealthDto
import com.qiro.common.service.TestExecutionService
import java.time.LocalDateTime
import java.util.*

/**
 * 통합 시스템 상태 DTO
 */
data class IntegratedSystemStatusDto(
    val companyId: UUID,
    val overallStatus: String, // EXCELLENT, GOOD, FAIR, POOR, CRITICAL
    val dataIntegrityStatus: DataIntegrityStatusDto,
    val performanceStatus: SystemHealthDto,
    val testResults: List<TestExecutionService.TestResult>,
    val lastChecked: LocalDateTime,
    val recommendations: List<String>
)

/**
 * 데이터 무결성 상태 DTO
 */
data class DataIntegrityStatusDto(
    val companyId: UUID,
    val totalRecords: Long,
    val validRecords: Long,
    val invalidRecords: Long,
    val integrityScore: Double, // 0-100
    val status: String, // EXCELLENT, GOOD, FAIR, POOR
    val lastChecked: LocalDateTime,
    val detailResults: List<DataIntegrityCheckResultDto>
)

/**
 * 최적화 옵션 DTO
 */
data class OptimizationOptionsDto(
    val includeDataIntegrity: Boolean = true,
    val includePerformanceOptimization: Boolean = true,
    val includeCacheOptimization: Boolean = true,
    val includeDatabaseOptimization: Boolean = true
)

/**
 * 통합 최적화 결과 DTO
 */
data class IntegratedOptimizationResultDto(
    val companyId: UUID,
    val optimizationId: UUID,
    val startTime: LocalDateTime,
    val endTime: LocalDateTime,
    val totalDurationMs: Long,
    val results: List<OptimizationStepResultDto>,
    val overallSuccess: Boolean,
    val performanceImprovement: Double, // 0-100
    val recommendations: List<String>
)

/**
 * 최적화 단계 결과 DTO
 */
data class OptimizationStepResultDto(
    val stepName: String,
    val success: Boolean,
    val duration: Long,
    val details: String,
    val metrics: Map<String, Any>
)

/**
 * 통합 테스트 옵션 DTO
 */
data class IntegratedTestOptionsDto(
    val includeIntegrationTests: Boolean = true,
    val includeDataIntegrityTests: Boolean = true,
    val includePerformanceTests: Boolean = true,
    val includeSecurityTests: Boolean = true
)

/**
 * 통합 테스트 결과 DTO
 */
data class IntegratedTestResultDto(
    val testSessionId: UUID,
    val companyId: UUID,
    val startTime: LocalDateTime,
    val endTime: LocalDateTime,
    val totalTests: Int,
    val passedTests: Int,
    val failedTests: Int,
    val errorTests: Int,
    val warningTests: Int,
    val overallSuccessRate: Double, // 0-100
    val testResults: List<TestExecutionService.TestResult>,
    val summary: List<TestExecutionService.TestSummary>,
    val failedTestsDetail: List<TestExecutionService.TestResult>,
    val systemHealthAfterTests: SystemHealthDto,
    val recommendations: List<String>
)

/**
 * 서비스 의존성 최적화 결과 DTO
 */
data class ServiceDependencyOptimizationResultDto(
    val companyId: UUID,
    val optimizationId: UUID,
    val startTime: LocalDateTime,
    val endTime: LocalDateTime,
    val totalDurationMs: Long,
    val optimizationSteps: List<DependencyOptimizationStepDto>,
    val overallSuccess: Boolean,
    val performanceImprovement: Double, // 0-100
    val recommendations: List<String>
)

/**
 * 의존성 최적화 단계 DTO
 */
data class DependencyOptimizationStepDto(
    val stepName: String,
    val status: String, // COMPLETED, FAILED, IN_PROGRESS
    val details: String,
    val duration: Long
)

/**
 * 프로시저 이관 상태 DTO
 */
data class ProcedureMigrationStatusDto(
    val totalProcedures: Int,
    val migratedProcedures: Int,
    val remainingProcedures: Int,
    val migrationProgress: Double, // 0-100
    val migrationChecks: List<ProcedureMigrationCheckDto>,
    val isFullyMigrated: Boolean,
    val lastChecked: LocalDateTime
)

/**
 * 프로시저 이관 체크 DTO
 */
data class ProcedureMigrationCheckDto(
    val category: String,
    val totalProcedures: Int,
    val migratedProcedures: Int,
    val migrationStatus: String, // COMPLETED, IN_PROGRESS, NOT_STARTED
    val details: String
)

/**
 * 시스템 리소스 사용량 DTO
 */
data class SystemResourceUsageDto(
    val cpuUsage: Double, // 0-100
    val memoryUsage: Double, // 0-100
    val diskUsage: Double, // 0-100
    val networkUsage: Double, // 0-100
    val activeConnections: Int,
    val threadCount: Int,
    val heapMemoryUsed: Long,
    val heapMemoryMax: Long,
    val gcCount: Long,
    val gcTime: Long,
    val timestamp: LocalDateTime
)

/**
 * 통합 모니터링 대시보드 DTO
 */
data class IntegratedMonitoringDashboardDto(
    val companyId: UUID,
    val systemStatus: IntegratedSystemStatusDto,
    val resourceUsage: SystemResourceUsageDto,
    val recentOptimizations: List<IntegratedOptimizationResultDto>,
    val recentTests: List<IntegratedTestResultDto>,
    val migrationStatus: ProcedureMigrationStatusDto,
    val alerts: List<SystemAlertDto>,
    val recommendations: List<SystemRecommendationDto>,
    val lastUpdated: LocalDateTime
)

/**
 * 시스템 알림 DTO
 */
data class SystemAlertDto(
    val alertId: UUID,
    val alertType: String, // PERFORMANCE, DATA_INTEGRITY, SECURITY, SYSTEM
    val severity: String, // LOW, MEDIUM, HIGH, CRITICAL
    val title: String,
    val message: String,
    val source: String,
    val timestamp: LocalDateTime,
    val isResolved: Boolean,
    val resolvedAt: LocalDateTime?
)

/**
 * 시스템 권장사항 DTO
 */
data class SystemRecommendationDto(
    val recommendationId: UUID,
    val category: String, // PERFORMANCE, DATA_INTEGRITY, SECURITY, MAINTENANCE
    val priority: Int, // 1-5 (1이 가장 높음)
    val title: String,
    val description: String,
    val expectedBenefit: String,
    val implementationEffort: String, // LOW, MEDIUM, HIGH
    val estimatedTimeToComplete: String,
    val relatedMetrics: List<String>,
    val createdAt: LocalDateTime,
    val isImplemented: Boolean,
    val implementedAt: LocalDateTime?
)

/**
 * 성능 벤치마크 결과 DTO
 */
data class PerformanceBenchmarkResultDto(
    val benchmarkId: UUID,
    val benchmarkName: String,
    val companyId: UUID,
    val startTime: LocalDateTime,
    val endTime: LocalDateTime,
    val totalDurationMs: Long,
    val benchmarkResults: List<BenchmarkStepResultDto>,
    val overallScore: Double, // 0-100
    val comparisonWithBaseline: Double, // percentage improvement/degradation
    val recommendations: List<String>
)

/**
 * 벤치마크 단계 결과 DTO
 */
data class BenchmarkStepResultDto(
    val stepName: String,
    val category: String, // DATABASE, API, CACHE, MEMORY, CPU
    val executionTimeMs: Long,
    val throughput: Double, // operations per second
    val errorRate: Double, // 0-100
    val resourceUsage: Map<String, Double>,
    val score: Double, // 0-100
    val status: String // PASS, FAIL, WARNING
)

/**
 * 자동화 규칙 DTO
 */
data class AutomationRuleDto(
    val ruleId: UUID,
    val ruleName: String,
    val category: String, // OPTIMIZATION, MONITORING, MAINTENANCE, ALERT
    val trigger: AutomationTriggerDto,
    val actions: List<AutomationActionDto>,
    val isEnabled: Boolean,
    val lastExecuted: LocalDateTime?,
    val executionCount: Long,
    val successRate: Double, // 0-100
    val createdAt: LocalDateTime,
    val updatedAt: LocalDateTime
)

/**
 * 자동화 트리거 DTO
 */
data class AutomationTriggerDto(
    val triggerType: String, // SCHEDULE, THRESHOLD, EVENT
    val condition: String,
    val parameters: Map<String, Any>
)

/**
 * 자동화 액션 DTO
 */
data class AutomationActionDto(
    val actionType: String, // OPTIMIZE, ALERT, CLEANUP, RESTART
    val actionName: String,
    val parameters: Map<String, Any>,
    val retryCount: Int,
    val timeoutSeconds: Int
)

/**
 * 시스템 상태 히스토리 DTO
 */
data class SystemStatusHistoryDto(
    val companyId: UUID,
    val timestamp: LocalDateTime,
    val overallStatus: String,
    val dataIntegrityScore: Double,
    val performanceScore: Double,
    val testSuccessRate: Double,
    val resourceUsage: SystemResourceUsageDto,
    val activeAlerts: Int,
    val resolvedIssues: Int,
    val notes: String?
)

/**
 * 용량 계획 DTO
 */
data class CapacityPlanningDto(
    val companyId: UUID,
    val resourceType: String, // CPU, MEMORY, DISK, NETWORK, DATABASE
    val currentUsage: Double, // 0-100
    val projectedUsage: Map<String, Double>, // time period -> usage percentage
    val recommendedCapacity: Double,
    val estimatedGrowthRate: Double, // percentage per month
    val capacityThresholds: Map<String, Double>, // warning, critical thresholds
    val recommendations: List<String>,
    val lastAnalyzed: LocalDateTime
)

/**
 * 비용 최적화 분석 DTO
 */
data class CostOptimizationAnalysisDto(
    val companyId: UUID,
    val analysisId: UUID,
    val analysisDate: LocalDateTime,
    val currentMonthlyCost: Double,
    val projectedMonthlyCost: Double,
    val potentialSavings: Double,
    val optimizationOpportunities: List<CostOptimizationOpportunityDto>,
    val implementationPlan: List<CostOptimizationStepDto>,
    val roi: Double, // return on investment percentage
    val paybackPeriodMonths: Int
)

/**
 * 비용 최적화 기회 DTO
 */
data class CostOptimizationOpportunityDto(
    val opportunityId: UUID,
    val category: String, // INFRASTRUCTURE, SOFTWARE, PROCESS
    val title: String,
    val description: String,
    val currentCost: Double,
    val optimizedCost: Double,
    val potentialSavings: Double,
    val implementationEffort: String, // LOW, MEDIUM, HIGH
    val riskLevel: String, // LOW, MEDIUM, HIGH
    val priority: Int // 1-5
)

/**
 * 비용 최적화 단계 DTO
 */
data class CostOptimizationStepDto(
    val stepId: UUID,
    val stepName: String,
    val description: String,
    val estimatedSavings: Double,
    val implementationTimeWeeks: Int,
    val dependencies: List<UUID>,
    val status: String, // NOT_STARTED, IN_PROGRESS, COMPLETED, CANCELLED
    val assignedTo: String?,
    val dueDate: LocalDateTime?,
    val completedAt: LocalDateTime?
)