package com.qiro.domain.workorder.entity

import com.qiro.common.entity.BaseEntity
import com.qiro.domain.company.entity.Company
import jakarta.persistence.*
import java.math.BigDecimal
import java.util.*

/**
 * 작업 지시서 템플릿 엔티티
 * 표준화된 작업 지시서 템플릿 관리
 */
@Entity
@Table(
    name = "work_order_templates",
    schema = "bms",
    uniqueConstraints = [
        UniqueConstraint(
            name = "uk_work_templates_code",
            columnNames = ["company_id", "template_code"]
        )
    ],
    indexes = [
        Index(name = "idx_work_templates_company_id", columnList = "company_id"),
        Index(name = "idx_work_templates_code", columnList = "template_code"),
        Index(name = "idx_work_templates_category", columnList = "work_category"),
        Index(name = "idx_work_templates_type", columnList = "work_type"),
        Index(name = "idx_work_templates_active", columnList = "is_active")
    ]
)
class WorkOrderTemplate : BaseEntity() {
    
    @Id
    @Column(name = "template_id")
    val templateId: UUID = UUID.randomUUID()
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "company_id", nullable = false)
    lateinit var company: Company
    
    @Column(name = "template_code", nullable = false, length = 20)
    lateinit var templateCode: String
    
    @Column(name = "template_name", nullable = false, length = 100)
    lateinit var templateName: String
    
    @Column(name = "template_description", columnDefinition = "TEXT")
    var templateDescription: String? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_category", nullable = false, length = 30)
    lateinit var workCategory: WorkCategory
    
    @Enumerated(EnumType.STRING)
    @Column(name = "work_type", nullable = false, length = 30)
    lateinit var workType: WorkType
    
    @Column(name = "fault_type", length = 30)
    var faultType: String? = null
    
    @Enumerated(EnumType.STRING)
    @Column(name = "default_priority", length = 20)
    var defaultPriority: WorkPriority = WorkPriority.MEDIUM
    
    @Column(name = "estimated_duration_hours", precision = 8, scale = 2)
    var estimatedDurationHours: BigDecimal = BigDecimal.ZERO
    
    @Enumerated(EnumType.STRING)
    @Column(name = "required_skill_level", length = 20)
    var requiredSkillLevel: SkillLevel = SkillLevel.BASIC
    
    @Column(name = "requires_specialist")
    var requiresSpecialist: Boolean = false
    
    @Column(name = "requires_contractor")
    var requiresContractor: Boolean = false
    
    @Column(name = "safety_requirements", columnDefinition = "JSONB")
    var safetyRequirements: String? = null
    
    @Column(name = "required_tools", columnDefinition = "JSONB")
    var requiredTools: String? = null
    
    @Column(name = "required_materials", columnDefinition = "JSONB")
    var requiredMaterials: String? = null
    
    @Column(name = "work_instructions", columnDefinition = "TEXT")
    var workInstructions: String? = null
    
    @Column(name = "safety_precautions", columnDefinition = "TEXT")
    var safetyPrecautions: String? = null
    
    @Column(name = "quality_checkpoints", columnDefinition = "JSONB")
    var qualityCheckpoints: String? = null
    
    @Column(name = "is_active")
    var isActive: Boolean = true
    
    @OneToMany(mappedBy = "template", fetch = FetchType.LAZY)
    val workOrders: MutableList<WorkOrder> = mutableListOf()
    
    /**
     * 템플릿 활성화/비활성화
     */
    fun toggleActive() {
        this.isActive = !this.isActive
    }
    
    /**
     * 템플릿으로부터 작업 지시서 생성
     */
    fun createWorkOrder(): WorkOrder {
        return WorkOrder().apply {
            template = this@WorkOrderTemplate
            workCategory = this@WorkOrderTemplate.workCategory
            workType = this@WorkOrderTemplate.workType
            workPriority = this@WorkOrderTemplate.defaultPriority
            estimatedDurationHours = this@WorkOrderTemplate.estimatedDurationHours
            workDescription = this@WorkOrderTemplate.workInstructions ?: ""
        }
    }
    
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is WorkOrderTemplate) return false
        return templateId == other.templateId
    }
    
    override fun hashCode(): Int {
        return templateId.hashCode()
    }
    
    override fun toString(): String {
        return "WorkOrderTemplate(templateId=$templateId, templateCode='$templateCode', templateName='$templateName')"
    }
}

/**
 * 기술 수준
 */
enum class SkillLevel(
    val displayName: String,
    val description: String
) {
    BASIC("기초", "기본적인 기술 수준"),
    INTERMEDIATE("중급", "중급 기술 수준"),
    ADVANCED("고급", "고급 기술 수준"),
    EXPERT("전문가", "전문가 수준"),
    SPECIALIST("특수기술자", "특수 기술 전문가");
    
    companion object {
        fun fromDisplayName(displayName: String): SkillLevel? {
            return values().find { it.displayName == displayName }
        }
    }
}