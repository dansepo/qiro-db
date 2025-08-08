package com.qiro.domain.validation.repository

import com.qiro.domain.validation.dto.BusinessRuleType
import com.qiro.domain.validation.entity.BusinessRule
import com.qiro.domain.validation.entity.DataIntegrityLog
import com.qiro.domain.validation.entity.RuleExecutionLog
import com.qiro.domain.validation.entity.ValidationConfig
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 비즈니스 규칙 리포지토리
 */
@Repository
interface BusinessRuleRepository : JpaRepository<BusinessRule, UUID> {
    
    /**
     * 규칙 코드로 조회
     */
    fun findByRuleCode(ruleCode: String): BusinessRule?
    
    /**
     * 회사별 활성 규칙 조회
     */
    fun findByCompanyIdAndIsActiveTrue(companyId: UUID): List<BusinessRule>
    
    /**
     * 엔티티 타입별 활성 규칙 조회 (우선순위 순)
     */
    fun findByCompanyIdAndEntityTypeAndIsActiveTrueOrderByPriorityAsc(
        companyId: UUID,
        entityType: String
    ): List<BusinessRule>
    
    /**
     * 규칙 타입별 조회
     */
    fun findByCompanyIdAndRuleTypeAndIsActiveTrue(
        companyId: UUID,
        ruleType: BusinessRuleType
    ): List<BusinessRule>
    
    /**
     * 회사별 규칙 검색
     */
    @Query("""
        SELECT br FROM BusinessRule br 
        WHERE br.companyId = :companyId 
        AND (:ruleType IS NULL OR br.ruleType = :ruleType)
        AND (:entityType IS NULL OR br.entityType = :entityType)
        AND (:isActive IS NULL OR br.isActive = :isActive)
        AND (:keyword IS NULL OR 
             LOWER(br.ruleName) LIKE LOWER(CONCAT('%', :keyword, '%')) OR
             LOWER(br.description) LIKE LOWER(CONCAT('%', :keyword, '%')))
        ORDER BY br.priority ASC, br.createdAt DESC
    """)
    fun searchBusinessRules(
        @Param("companyId") companyId: UUID,
        @Param("ruleType") ruleType: BusinessRuleType?,
        @Param("entityType") entityType: String?,
        @Param("isActive") isActive: Boolean?,
        @Param("keyword") keyword: String?,
        pageable: Pageable
    ): Page<BusinessRule>
    
    /**
     * 우선순위 범위 내 규칙 조회
     */
    @Query("""
        SELECT br FROM BusinessRule br 
        WHERE br.companyId = :companyId 
        AND br.entityType = :entityType
        AND br.isActive = true
        AND br.priority BETWEEN :minPriority AND :maxPriority
        ORDER BY br.priority ASC
    """)
    fun findByPriorityRange(
        @Param("companyId") companyId: UUID,
        @Param("entityType") entityType: String,
        @Param("minPriority") minPriority: Int,
        @Param("maxPriority") maxPriority: Int
    ): List<BusinessRule>
}

/**
 * 검증 설정 리포지토리
 */
@Repository
interface ValidationConfigRepository : JpaRepository<ValidationConfig, UUID> {
    
    /**
     * 엔티티 타입별 활성 검증 설정 조회
     */
    fun findByCompanyIdAndEntityTypeAndIsActiveTrue(
        companyId: UUID,
        entityType: String
    ): List<ValidationConfig>
    
    /**
     * 특정 필드의 검증 설정 조회
     */
    fun findByCompanyIdAndEntityTypeAndFieldAndIsActiveTrue(
        companyId: UUID,
        entityType: String,
        field: String
    ): List<ValidationConfig>
    
    /**
     * 검증 타입별 설정 조회
     */
    fun findByCompanyIdAndValidationTypeAndIsActiveTrue(
        companyId: UUID,
        validationType: String
    ): List<ValidationConfig>
    
    /**
     * 필수 필드 검증 설정 조회
     */
    fun findByCompanyIdAndEntityTypeAndIsRequiredTrueAndIsActiveTrue(
        companyId: UUID,
        entityType: String
    ): List<ValidationConfig>
}

/**
 * 규칙 실행 로그 리포지토리
 */
@Repository
interface RuleExecutionLogRepository : JpaRepository<RuleExecutionLog, UUID> {
    
    /**
     * 규칙별 실행 로그 조회
     */
    fun findByRuleIdOrderByExecutedAtDesc(ruleId: UUID): List<RuleExecutionLog>
    
    /**
     * 엔티티별 실행 로그 조회
     */
    fun findByEntityTypeAndEntityIdOrderByExecutedAtDesc(
        entityType: String,
        entityId: UUID
    ): List<RuleExecutionLog>
    
    /**
     * 회사별 실행 로그 조회 (페이징)
     */
    fun findByCompanyIdOrderByExecutedAtDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<RuleExecutionLog>
    
    /**
     * 실행 실패 로그 조회
     */
    fun findByCompanyIdAndSuccessFalseOrderByExecutedAtDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<RuleExecutionLog>
    
    /**
     * 기간별 실행 통계
     */
    @Query("""
        SELECT 
            DATE(rel.executedAt) as date,
            COUNT(*) as totalExecutions,
            SUM(CASE WHEN rel.success = true THEN 1 ELSE 0 END) as successfulExecutions,
            SUM(CASE WHEN rel.success = false THEN 1 ELSE 0 END) as failedExecutions,
            AVG(rel.executionTime) as avgExecutionTime
        FROM RuleExecutionLog rel 
        WHERE rel.companyId = :companyId 
        AND rel.executedAt BETWEEN :startDate AND :endDate
        GROUP BY DATE(rel.executedAt)
        ORDER BY DATE(rel.executedAt) DESC
    """)
    fun getExecutionStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Map<String, Any>>
    
    /**
     * 규칙별 실행 통계
     */
    @Query("""
        SELECT 
            rel.ruleId,
            rel.ruleName,
            COUNT(*) as totalExecutions,
            SUM(CASE WHEN rel.success = true THEN 1 ELSE 0 END) as successfulExecutions,
            AVG(rel.executionTime) as avgExecutionTime,
            MAX(rel.executedAt) as lastExecuted
        FROM RuleExecutionLog rel 
        WHERE rel.companyId = :companyId 
        AND rel.executedAt BETWEEN :startDate AND :endDate
        GROUP BY rel.ruleId, rel.ruleName
        ORDER BY totalExecutions DESC
    """)
    fun getRuleExecutionStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Map<String, Any>>
}

/**
 * 데이터 무결성 로그 리포지토리
 */
@Repository
interface DataIntegrityLogRepository : JpaRepository<DataIntegrityLog, UUID> {
    
    /**
     * 엔티티 타입별 무결성 로그 조회
     */
    fun findByCompanyIdAndEntityTypeOrderByCheckedAtDesc(
        companyId: UUID,
        entityType: String
    ): List<DataIntegrityLog>
    
    /**
     * 회사별 최근 무결성 검사 결과 조회
     */
    fun findByCompanyIdOrderByCheckedAtDesc(
        companyId: UUID,
        pageable: Pageable
    ): Page<DataIntegrityLog>
    
    /**
     * 문제가 있는 무결성 검사 결과 조회
     */
    fun findByCompanyIdAndInvalidRecordsGreaterThanOrderByCheckedAtDesc(
        companyId: UUID,
        invalidRecords: Long,
        pageable: Pageable
    ): Page<DataIntegrityLog>
    
    /**
     * 기간별 무결성 검사 통계
     */
    @Query("""
        SELECT 
            dil.entityType,
            COUNT(*) as totalChecks,
            SUM(dil.totalRecords) as totalRecords,
            SUM(dil.validRecords) as totalValidRecords,
            SUM(dil.invalidRecords) as totalInvalidRecords,
            AVG(dil.duration) as avgDuration,
            MAX(dil.checkedAt) as lastChecked
        FROM DataIntegrityLog dil 
        WHERE dil.companyId = :companyId 
        AND dil.checkedAt BETWEEN :startDate AND :endDate
        GROUP BY dil.entityType
        ORDER BY totalInvalidRecords DESC
    """)
    fun getIntegrityStatistics(
        @Param("companyId") companyId: UUID,
        @Param("startDate") startDate: LocalDateTime,
        @Param("endDate") endDate: LocalDateTime
    ): List<Map<String, Any>>
    
    /**
     * 엔티티별 최신 무결성 검사 결과
     */
    @Query("""
        SELECT dil FROM DataIntegrityLog dil 
        WHERE dil.companyId = :companyId 
        AND dil.entityType = :entityType
        AND dil.checkedAt = (
            SELECT MAX(dil2.checkedAt) 
            FROM DataIntegrityLog dil2 
            WHERE dil2.companyId = :companyId 
            AND dil2.entityType = :entityType
        )
    """)
    fun findLatestByEntityType(
        @Param("companyId") companyId: UUID,
        @Param("entityType") entityType: String
    ): DataIntegrityLog?
}