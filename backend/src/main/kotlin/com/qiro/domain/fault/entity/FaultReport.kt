package com.qiro.domain.fault.entity

import com.qiro.common.entity.BaseEntity
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.annotations.Type
import org.hibernate.type.SqlTypes
import java.math.BigDecimal
import java.time.LocalDateTime
import java.util.*

/**
 * 고장 신고 엔티티
 * 시설물 고장 신고 및 처리 과정을 관리
 */
@Entity
@Table(name = "fault_reports", schema = "bms")
data class FaultReport(
    @Id
    @Column(name = "report_id")
    val id: UUID = UUID.randomUUID(),

    /**
     * 회사 ID (멀티테넌시)
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 건물 ID
     */
    @Column(name = "building_id")
    val buildingId: UUID? = null,

    /**
     * 세대 ID
     */
    @Column(name = "unit_id")
    val unitId: UUID? = null,

    /**
     * 시설물 자산 ID
     */
    @Column(name = "asset_id")
    val assetId: UUID? = null,

    /**
     * 고장 분류 ID
     */
    @Column(name = "category_id", nullable = false)
    val categoryId: UUID,

    /**
     * 신고 번호 (고유 식별자)
     */
    @Column(name = "report_number", nullable = false, length = 50)
    val reportNumber: String,

    /**
     * 신고 제목
     */
    @Column(name = "report_title", nullable = false, length = 200)
    val reportTitle: String,

    /**
     * 신고 설명
     */
    @Column(name = "report_description", nullable = false, columnDefinition = "TEXT")
    val reportDescription: String,

    /**
     * 신고자 유형
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "reporter_type", nullable = false)
    val reporterType: ReporterType,

    /**
     * 신고자 이름
     */
    @Column(name = "reporter_name", length = 100)
    val reporterName: String? = null,

    /**
     * 신고자 연락처 (JSON 형태)
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "reporter_contact", columnDefinition = "jsonb")
    val reporterContact: Map<String, String>? = null,

    /**
     * 신고자 세대 ID
     */
    @Column(name = "reporter_unit_id")
    val reporterUnitId: UUID? = null,

    /**
     * 익명 신고 여부
     */
    @Column(name = "anonymous_report", nullable = false)
    val anonymousReport: Boolean = false,

    /**
     * 고장 유형
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "fault_type", nullable = false)
    val faultType: FaultType,

    /**
     * 고장 심각도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "fault_severity", nullable = false)
    val faultSeverity: FaultSeverity,

    /**
     * 고장 긴급도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "fault_urgency", nullable = false)
    val faultUrgency: FaultUrgency,

    /**
     * 고장 우선순위
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "fault_priority", nullable = false)
    val faultPriority: FaultPriority,

    /**
     * 고장 위치
     */
    @Column(name = "fault_location", columnDefinition = "TEXT")
    val faultLocation: String? = null,

    /**
     * 영향받은 구역 (JSON 형태)
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "affected_areas", columnDefinition = "jsonb")
    val affectedAreas: List<String>? = null,

    /**
     * 환경 조건
     */
    @Column(name = "environmental_conditions", columnDefinition = "TEXT")
    val environmentalConditions: String? = null,

    /**
     * 안전 영향도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "safety_impact", nullable = false)
    val safetyImpact: ImpactLevel = ImpactLevel.NONE,

    /**
     * 운영 영향도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "operational_impact", nullable = false)
    val operationalImpact: ImpactLevel = ImpactLevel.MINOR,

    /**
     * 거주자 영향도
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "resident_impact", nullable = false)
    val residentImpact: ImpactLevel = ImpactLevel.MINOR,

    /**
     * 예상 영향 세대 수
     */
    @Column(name = "estimated_affected_units", nullable = false)
    val estimatedAffectedUnits: Int = 0,

    /**
     * 고장 발생 일시
     */
    @Column(name = "fault_occurred_at")
    val faultOccurredAt: LocalDateTime? = null,

    /**
     * 신고 일시
     */
    @Column(name = "reported_at", nullable = false)
    val reportedAt: LocalDateTime = LocalDateTime.now(),

    /**
     * 최초 응답 기한
     */
    @Column(name = "first_response_due")
    val firstResponseDue: LocalDateTime? = null,

    /**
     * 해결 기한
     */
    @Column(name = "resolution_due")
    val resolutionDue: LocalDateTime? = null,

    /**
     * 신고 상태
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "report_status", nullable = false)
    val reportStatus: ReportStatus = ReportStatus.OPEN,

    /**
     * 해결 상태
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "resolution_status", nullable = false)
    val resolutionStatus: ResolutionStatus = ResolutionStatus.PENDING,

    /**
     * 담당자 ID
     */
    @Column(name = "assigned_to")
    val assignedTo: UUID? = null,

    /**
     * 담당 팀
     */
    @Column(name = "assigned_team", length = 50)
    val assignedTeam: String? = null,

    /**
     * 협력업체 ID
     */
    @Column(name = "contractor_id")
    val contractorId: UUID? = null,

    /**
     * 에스컬레이션 레벨
     */
    @Column(name = "escalation_level", nullable = false)
    val escalationLevel: Int = 1,

    /**
     * 최초 응답 일시
     */
    @Column(name = "first_response_at")
    val firstResponseAt: LocalDateTime? = null,

    /**
     * 접수 확인 일시
     */
    @Column(name = "acknowledged_at")
    val acknowledgedAt: LocalDateTime? = null,

    /**
     * 접수 확인자 ID
     */
    @Column(name = "acknowledged_by")
    val acknowledgedBy: UUID? = null,

    /**
     * 작업 시작 일시
     */
    @Column(name = "work_started_at")
    val workStartedAt: LocalDateTime? = null,

    /**
     * 해결 일시
     */
    @Column(name = "resolved_at")
    val resolvedAt: LocalDateTime? = null,

    /**
     * 해결자 ID
     */
    @Column(name = "resolved_by")
    val resolvedBy: UUID? = null,

    /**
     * 해결 방법
     */
    @Column(name = "resolution_method", length = 50)
    val resolutionMethod: String? = null,

    /**
     * 해결 설명
     */
    @Column(name = "resolution_description", columnDefinition = "TEXT")
    val resolutionDescription: String? = null,

    /**
     * 예상 수리 비용
     */
    @Column(name = "estimated_repair_cost", precision = 12, scale = 2)
    val estimatedRepairCost: BigDecimal = BigDecimal.ZERO,

    /**
     * 실제 수리 비용
     */
    @Column(name = "actual_repair_cost", precision = 12, scale = 2)
    val actualRepairCost: BigDecimal = BigDecimal.ZERO,

    /**
     * 해결 품질 평가
     */
    @Column(name = "resolution_quality_rating", precision = 3, scale = 1)
    val resolutionQualityRating: BigDecimal = BigDecimal.ZERO,

    /**
     * 신고자 만족도 평가
     */
    @Column(name = "reporter_satisfaction_rating", precision = 3, scale = 1)
    val reporterSatisfactionRating: BigDecimal = BigDecimal.ZERO,

    /**
     * 초기 사진 (JSON 형태)
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "initial_photos", columnDefinition = "jsonb")
    val initialPhotos: List<String>? = null,

    /**
     * 해결 사진 (JSON 형태)
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "resolution_photos", columnDefinition = "jsonb")
    val resolutionPhotos: List<String>? = null,

    /**
     * 지원 문서 (JSON 형태)
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "supporting_documents", columnDefinition = "jsonb")
    val supportingDocuments: List<String>? = null,

    /**
     * 소통 로그 (JSON 형태)
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "communication_log", columnDefinition = "jsonb")
    val communicationLog: List<Map<String, Any>>? = null,

    /**
     * 내부 메모
     */
    @Column(name = "internal_notes", columnDefinition = "TEXT")
    val internalNotes: String? = null,

    /**
     * 후속 조치 필요 여부
     */
    @Column(name = "follow_up_required", nullable = false)
    val followUpRequired: Boolean = false,

    /**
     * 후속 조치일
     */
    @Column(name = "follow_up_date")
    val followUpDate: LocalDateTime? = null,

    /**
     * 후속 조치 메모
     */
    @Column(name = "follow_up_notes", columnDefinition = "TEXT")
    val followUpNotes: String? = null,

    /**
     * 반복 문제 여부
     */
    @Column(name = "is_recurring_issue", nullable = false)
    val isRecurringIssue: Boolean = false

) : BaseEntity() {

    /**
     * 긴급 신고 여부 확인
     */
    fun isUrgent(): Boolean {
        return faultUrgency == FaultUrgency.CRITICAL || faultPriority == FaultPriority.EMERGENCY
    }

    /**
     * 응답 시간 초과 여부 확인
     */
    fun isResponseOverdue(): Boolean {
        return firstResponseDue?.isBefore(LocalDateTime.now()) == true && firstResponseAt == null
    }

    /**
     * 해결 시간 초과 여부 확인
     */
    fun isResolutionOverdue(): Boolean {
        return resolutionDue?.isBefore(LocalDateTime.now()) == true && resolvedAt == null
    }

    /**
     * 신고 상태 업데이트
     */
    fun updateStatus(newStatus: ReportStatus): FaultReport {
        return this.copy(reportStatus = newStatus)
    }

    /**
     * 담당자 배정
     */
    fun assignTo(userId: UUID, team: String? = null): FaultReport {
        return this.copy(
            assignedTo = userId,
            assignedTeam = team,
            reportStatus = if (reportStatus == ReportStatus.OPEN) ReportStatus.ASSIGNED else reportStatus
        )
    }

    /**
     * 접수 확인 처리
     */
    fun acknowledge(userId: UUID): FaultReport {
        return this.copy(
            acknowledgedAt = LocalDateTime.now(),
            acknowledgedBy = userId,
            reportStatus = ReportStatus.ACKNOWLEDGED
        )
    }

    /**
     * 작업 시작 처리
     */
    fun startWork(): FaultReport {
        return this.copy(
            workStartedAt = LocalDateTime.now(),
            reportStatus = ReportStatus.IN_PROGRESS,
            resolutionStatus = ResolutionStatus.IN_PROGRESS,
            firstResponseAt = firstResponseAt ?: LocalDateTime.now()
        )
    }

    /**
     * 해결 완료 처리
     */
    fun resolve(userId: UUID, method: String, description: String): FaultReport {
        return this.copy(
            resolvedAt = LocalDateTime.now(),
            resolvedBy = userId,
            resolutionMethod = method,
            resolutionDescription = description,
            reportStatus = ReportStatus.RESOLVED,
            resolutionStatus = ResolutionStatus.COMPLETED
        )
    }
}

/**
 * 신고자 유형
 */
enum class ReporterType(val description: String) {
    RESIDENT("거주자"),
    TENANT("임차인"),
    VISITOR("방문객"),
    STAFF("직원"),
    CONTRACTOR("협력업체"),
    SYSTEM("시스템"),
    ANONYMOUS("익명")
}

/**
 * 고장 유형
 */
enum class FaultType(val description: String) {
    ELECTRICAL("전기"),
    PLUMBING("배관"),
    HVAC("냉난방"),
    ELEVATOR("승강기"),
    FIRE_SAFETY("소방안전"),
    SECURITY("보안"),
    STRUCTURAL("구조물"),
    APPLIANCE("가전제품"),
    LIGHTING("조명"),
    COMMUNICATION("통신"),
    OTHER("기타")
}

/**
 * 고장 심각도
 */
enum class FaultSeverity(val description: String) {
    MINOR("경미"),
    MODERATE("보통"),
    MAJOR("심각"),
    CRITICAL("치명적"),
    CATASTROPHIC("재해급")
}

/**
 * 고장 긴급도
 */
enum class FaultUrgency(val description: String) {
    LOW("낮음"),
    NORMAL("보통"),
    HIGH("높음"),
    CRITICAL("치명적")
}

/**
 * 고장 우선순위
 */
enum class FaultPriority(val description: String) {
    LOW("낮음"),
    MEDIUM("보통"),
    HIGH("높음"),
    URGENT("긴급"),
    EMERGENCY("응급")
}

/**
 * 영향도 레벨
 */
enum class ImpactLevel(val description: String) {
    NONE("없음"),
    MINOR("경미"),
    MODERATE("보통"),
    MAJOR("심각"),
    CRITICAL("치명적")
}

/**
 * 신고 상태
 */
enum class ReportStatus(val description: String) {
    OPEN("접수"),
    ACKNOWLEDGED("확인됨"),
    ASSIGNED("배정됨"),
    IN_PROGRESS("진행중"),
    RESOLVED("해결됨"),
    CLOSED("종료됨"),
    CANCELLED("취소됨")
}

/**
 * 해결 상태
 */
enum class ResolutionStatus(val description: String) {
    PENDING("대기중"),
    INVESTIGATING("조사중"),
    PARTS_ORDERED("부품주문"),
    SCHEDULED("예약됨"),
    IN_PROGRESS("진행중"),
    COMPLETED("완료됨"),
    DEFERRED("연기됨"),
    CANCELLED("취소됨")
}