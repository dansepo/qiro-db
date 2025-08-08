package com.qiro.domain.validation.entity

import com.qiro.domain.validation.dto.BusinessRuleType
import jakarta.persistence.*
import org.hibernate.annotations.CreationTimestamp
import org.hibernate.annotations.UpdateTimestamp
import java.time.LocalDateTime
import java.util.*

/**
 * 비즈니스 규칙 엔티티
 */
@Entity
@Table(
    name = "business_rules",
    schema = "bms",
    indexes = [
        Index(name = "idx_business_rule_code", columnList = "rule_code", unique = true),
        Index(name = "idx_business_rule_type", columnList = "rule_type"),
        Index(name = "idx_business_rule_entity_type", columnList = "entity_type"),
        Index(name = "idx_business_rule_active", columnList = "is_active"),
        Index(name = "idx_business_rule_priority", columnList = "priority")
    ]
)
data class BusinessRule(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "rule_id")
    val ruleId: UUID = UUID.randomUUID(),

    /**
     * 규칙 이름
     */
    @Column(name = "rule_name", nullable = false, length = 100)
    var ruleName: String,

    /**
     * 규칙 코드 (고유 식별자)
     */
    @Column(name = "rule_code", nullable = false, length = 50, unique = true)
    val ruleCode: String,

    /**
     * 규칙 설명
     */
    @Column(name = "description", columnDefinition = "TEXT")
    var description: String? = null,

    /**
     * 규칙 타입
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "rule_type", nullable = false, length = 20)
    var ruleType: BusinessRuleType,

    /**
     * 적용 대상 엔티티 타입
     */
    @Column(name = "entity_type", nullable = false, length = 50)
    var entityType: String,

    /**
     * 규칙 조건 (JSON 또는 표현식)
     */
    @Column(name = "condition", columnDefinition = "TEXT", nullable = false)
    var condition: String,

    /**
     * 규칙 액션 (JSON 또는 표현식)
     */
    @Column(name = "action", columnDefinition = "TEXT", nullable = false)
    var action: String,

    /**
     * 우선순위 (낮은 숫자가 높은 우선순위)
     */
    @Column(name = "priority", nullable = false)
    var priority: Int = 100,

    /**
     * 활성화 여부
     */
    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 생성일시
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    /**
     * 생성자 ID
     */
    @Column(name = "created_by", nullable = false)
    val createdBy: UUID,

    /**
     * 수정일시
     */
    @UpdateTimestamp
    @Column(name = "updated_at")
    var updatedAt: LocalDateTime? = null,

    /**
     * 수정자 ID
     */
    @Column(name = "updated_by")
    var updatedBy: UUID? = null
) {
    /**
     * 규칙 수정
     */
    fun update(
        ruleName: String? = null,
        description: String? = null,
        condition: String? = null,
        action: String? = null,
        priority: Int? = null,
        isActive: Boolean? = null,
        updatedBy: UUID
    ) {
        ruleName?.let { this.ruleName = it }
        description?.let { this.description = it }
        condition?.let { this.condition = it }
        action?.let { this.action = it }
        priority?.let { this.priority = it }
        isActive?.let { this.isActive = it }
        this.updatedBy = updatedBy
    }

    /**
     * 규칙 활성화
     */
    fun activate(updatedBy: UUID) {
        this.isActive = true
        this.updatedBy = updatedBy
    }

    /**
     * 규칙 비활성화
     */
    fun deactivate(updatedBy: UUID) {
        this.isActive = false
        this.updatedBy = updatedBy
    }
}

/**
 * 검증 설정 엔티티
 */
@Entity
@Table(
    name = "validation_configs",
    schema = "bms",
    indexes = [
        Index(name = "idx_validation_config_entity_field", columnList = "entity_type, field"),
        Index(name = "idx_validation_config_type", columnList = "validation_type"),
        Index(name = "idx_validation_config_active", columnList = "is_active")
    ]
)
data class ValidationConfig(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "config_id")
    val configId: UUID = UUID.randomUUID(),

    /**
     * 적용 대상 엔티티 타입
     */
    @Column(name = "entity_type", nullable = false, length = 50)
    val entityType: String,

    /**
     * 검증 대상 필드
     */
    @Column(name = "field", nullable = false, length = 50)
    val field: String,

    /**
     * 검증 타입
     */
    @Column(name = "validation_type", nullable = false, length = 30)
    val validationType: String,

    /**
     * 검증 설정 (JSON)
     */
    @Column(name = "configuration", columnDefinition = "JSONB")
    var configuration: String = "{}",

    /**
     * 필수 여부
     */
    @Column(name = "is_required", nullable = false)
    var isRequired: Boolean = false,

    /**
     * 오류 메시지
     */
    @Column(name = "error_message", length = 200)
    var errorMessage: String? = null,

    /**
     * 경고 메시지
     */
    @Column(name = "warning_message", length = 200)
    var warningMessage: String? = null,

    /**
     * 활성화 여부
     */
    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 생성일시
     */
    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    val createdAt: LocalDateTime = LocalDateTime.now(),

    /**
     * 생성자 ID
     */
    @Column(name = "created_by", nullable = false)
    val createdBy: UUID
)

/**
 * 규칙 실행 로그 엔티티
 */
@Entity
@Table(
    name = "rule_execution_logs",
    schema = "bms",
    indexes = [
        Index(name = "idx_rule_execution_rule_id", columnList = "rule_id"),
        Index(name = "idx_rule_execution_entity", columnList = "entity_type, entity_id"),
        Index(name = "idx_rule_execution_date", columnList = "executed_at"),
        Index(name = "idx_rule_execution_success", columnList = "success")
    ]
)
data class RuleExecutionLog(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "log_id")
    val logId: UUID = UUID.randomUUID(),

    /**
     * 실행된 규칙 ID
     */
    @Column(name = "rule_id", nullable = false)
    val ruleId: UUID,

    /**
     * 규칙 이름 (스냅샷)
     */
    @Column(name = "rule_name", nullable = false, length = 100)
    val ruleName: String,

    /**
     * 대상 엔티티 타입
     */
    @Column(name = "entity_type", nullable = false, length = 50)
    val entityType: String,

    /**
     * 대상 엔티티 ID
     */
    @Column(name = "entity_id", nullable = false)
    val entityId: UUID,

    /**
     * 실행 여부
     */
    @Column(name = "executed", nullable = false)
    val executed: Boolean,

    /**
     * 성공 여부
     */
    @Column(name = "success", nullable = false)
    val success: Boolean,

    /**
     * 실행 결과 (JSON)
     */
    @Column(name = "result", columnDefinition = "JSONB")
    val result: String? = null,

    /**
     * 오류 메시지
     */
    @Column(name = "error_message", columnDefinition = "TEXT")
    val errorMessage: String? = null,

    /**
     * 실행 시간 (밀리초)
     */
    @Column(name = "execution_time", nullable = false)
    val executionTime: Long,

    /**
     * 실행 사용자 ID
     */
    @Column(name = "executed_by", nullable = false)
    val executedBy: UUID,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 실행일시
     */
    @CreationTimestamp
    @Column(name = "executed_at", nullable = false)
    val executedAt: LocalDateTime = LocalDateTime.now()
)

/**
 * 데이터 무결성 검사 로그 엔티티
 */
@Entity
@Table(
    name = "data_integrity_logs",
    schema = "bms",
    indexes = [
        Index(name = "idx_data_integrity_entity_type", columnList = "entity_type"),
        Index(name = "idx_data_integrity_check_date", columnList = "checked_at"),
        Index(name = "idx_data_integrity_issues", columnList = "invalid_records")
    ]
)
data class DataIntegrityLog(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "check_id")
    val checkId: UUID = UUID.randomUUID(),

    /**
     * 검사 이름
     */
    @Column(name = "check_name", nullable = false, length = 100)
    val checkName: String,

    /**
     * 대상 엔티티 타입
     */
    @Column(name = "entity_type", nullable = false, length = 50)
    val entityType: String,

    /**
     * 전체 레코드 수
     */
    @Column(name = "total_records", nullable = false)
    val totalRecords: Long,

    /**
     * 유효한 레코드 수
     */
    @Column(name = "valid_records", nullable = false)
    val validRecords: Long,

    /**
     * 무효한 레코드 수
     */
    @Column(name = "invalid_records", nullable = false)
    val invalidRecords: Long,

    /**
     * 검사 결과 상세 (JSON)
     */
    @Column(name = "issues", columnDefinition = "JSONB")
    val issues: String = "[]",

    /**
     * 검사 소요 시간 (밀리초)
     */
    @Column(name = "duration", nullable = false)
    val duration: Long,

    /**
     * 검사 실행자 ID
     */
    @Column(name = "checked_by", nullable = false)
    val checkedBy: UUID,

    /**
     * 회사 ID
     */
    @Column(name = "company_id", nullable = false)
    val companyId: UUID,

    /**
     * 검사일시
     */
    @CreationTimestamp
    @Column(name = "checked_at", nullable = false)
    val checkedAt: LocalDateTime = LocalDateTime.now()
)