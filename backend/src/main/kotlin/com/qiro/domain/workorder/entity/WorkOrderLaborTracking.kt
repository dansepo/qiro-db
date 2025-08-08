package com.qiro.domain.workorder.entity

import com.fasterxml.jackson.databind.JsonNode
import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 작업 지시서 인력 시간 추적 엔티티
 * 작업자별 시간 및 비용 상세 추적
 */
@Entity
@Table(
    name = "work_order_labor_tracking",
    schema = "bms",
    indexes = [
        Index(name = "idx_labor_tracking_work_order", columnList = "workOrderId"),
        Index(name = "idx_labor_tracking_assignment", columnList = "assignmentId"),
        Index(name = "idx_labor_tracking_worker", columnList = "workerId"),
        Index(name = "idx_labor_tracking_date", columnList = "workDate"),
        Index(name = "idx_labor_tracking_status", columnList = "trackingStatus")
    ]
)
data class WorkOrderLaborTracking(
    @Id
    @Column(name = "labor_tracking_id")
    val laborTrackingId: UUID = UUID.randomUUID(),
    
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,
    
    @Column(name = "work_order_id", nullable = false)
    val workOrderId: UUID,
    
    @Column(name = "assignment_id", nullable = false)
    val assignmentId: UUID,
    
    // 작업자 정보
    @Column(name = "worker_id", nullable = false)
    val workerId: UUID,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "worker_role", length = 30, nullable = false)
    val workerRole: WorkerRole,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "skill_level", length = 20)
    val skillLevel: SkillLevel = SkillLevel.BASIC,
    
    // 시간 추적
    @Column(name = "work_date", nullable = false)
    val workDate: LocalDate,
    
    @Column(name = "start_time")
    val startTime: LocalDateTime? = null,
    
    @Column(name = "end_time")
    val endTime: LocalDateTime? = null,
    
    @Column(name = "break_duration_minutes")
    val breakDurationMinutes: Int = 0,
    
    @Column(name = "actual_work_hours", nullable = false, precision = 8, scale = 2)
    val actualWorkHours: BigDecimal,
    
    // 작업 내용
    @Column(name = "work_description", columnDefinition = "TEXT")
    val workDescription: String? = null,
    
    @Column(name = "work_location", columnDefinition = "TEXT")
    val workLocation: String? = null,
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_phase", length = 30)
    val workPhase: WorkPhase? = null,
    
    // 비용 정보
    @Column(name = "hourly_rate", precision = 10, scale = 2)
    val hourlyRate: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "overtime_rate", precision = 10, scale = 2)
    val overtimeRate: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "regular_hours", precision = 8, scale = 2)
    val regularHours: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "overtime_hours", precision = 8, scale = 2)
    val overtimeHours: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "total_labor_cost", precision = 12, scale = 2)
    val totalLaborCost: BigDecimal = BigDecimal.ZERO,
    
    // 성과 지표
    @Column(name = "productivity_score", precision = 3, scale = 1)
    val productivityScore: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "quality_score", precision = 3, scale = 1)
    val qualityScore: BigDecimal = BigDecimal.ZERO,
    
    @Column(name = "safety_score", precision = 3, scale = 1)
    val safetyScore: BigDecimal = BigDecimal.ZERO,
    
    // 도구 및 장비 사용
    @Column(name = "tools_used", columnDefinition = "jsonb")
    val toolsUsed: JsonNode? = null,
    
    @Column(name = "equipment_used", columnDefinition = "jsonb")
    val equipmentUsed: JsonNode? = null,
    
    // 상태 및 승인
    @Enumerated(EnumType.STRING)
    @Column(name = "tracking_status", length = 20)
    val trackingStatus: TrackingStatus = TrackingStatus.RECORDED,
    
    @Column(name = "approved_by")
    val approvedBy: UUID? = null,
    
    @Column(name = "approval_date")
    val approvalDate: LocalDateTime? = null,
    
    @Column(name = "approval_notes", columnDefinition = "TEXT")
    val approvalNotes: String? = null
    
) : BaseEntity() {
    
    /**
     * 작업자 역할 열거형
     */
    enum class WorkerRole {
        PRIMARY_TECHNICIAN,     // 주 기술자
        ASSISTANT_TECHNICIAN,   // 보조 기술자
        SUPERVISOR,             // 감독자
        SPECIALIST,             // 전문가
        CONTRACTOR,             // 계약자
        INSPECTOR,              // 검사자
        COORDINATOR,            // 조정자
        HELPER                  // 보조자
    }
    
    /**
     * 기술 수준 열거형
     */
    enum class SkillLevel {
        BASIC,          // 기초
        INTERMEDIATE,   // 중급
        ADVANCED,       // 고급
        EXPERT,         // 전문가
        SPECIALIST      // 특수 전문가
    }
    
    /**
     * 작업 단계 열거형
     */
    enum class WorkPhase {
        PLANNING,       // 계획
        PREPARATION,    // 준비
        EXECUTION,      // 실행
        TESTING,        // 테스트
        COMPLETION,     // 완료
        CLEANUP         // 정리
    }
    
    /**
     * 추적 상태 열거형
     */
    enum class TrackingStatus {
        RECORDED,       // 기록됨
        SUBMITTED,      // 제출됨
        APPROVED,       // 승인됨
        REJECTED,       // 거부됨
        REVISED         // 수정됨
    }
    
    /**
     * 총 작업 시간 계산 (정규 시간 + 초과 시간)
     */
    fun getTotalWorkHours(): BigDecimal {
        return regularHours.add(overtimeHours)
    }
    
    /**
     * 초과 근무 여부 확인
     */
    fun hasOvertime(): Boolean {
        return overtimeHours > BigDecimal.ZERO
    }
    
    /**
     * 승인 여부 확인
     */
    fun isApproved(): Boolean {
        return trackingStatus == TrackingStatus.APPROVED && approvedBy != null
    }
    
    /**
     * 평균 성과 점수 계산
     */
    fun getAveragePerformanceScore(): BigDecimal {
        val scores = listOf(productivityScore, qualityScore, safetyScore)
        val validScores = scores.filter { it > BigDecimal.ZERO }
        
        return if (validScores.isNotEmpty()) {
            validScores.reduce { acc, score -> acc.add(score) }
                .divide(BigDecimal.valueOf(validScores.size.toLong()), 1, java.math.RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }
    
    /**
     * 시간당 비용 효율성 계산
     */
    fun getCostEfficiency(): BigDecimal {
        return if (actualWorkHours > BigDecimal.ZERO) {
            totalLaborCost.divide(actualWorkHours, 2, java.math.RoundingMode.HALF_UP)
        } else {
            BigDecimal.ZERO
        }
    }
}