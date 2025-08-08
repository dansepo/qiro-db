package com.qiro.domain.validation.service

import com.qiro.domain.validation.dto.*
import com.qiro.domain.validation.entity.DataIntegrityLog
import com.qiro.domain.validation.repository.DataIntegrityLogRepository
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 데이터 무결성 서비스
 */
@Service
@Transactional(readOnly = true)
class DataIntegrityService(
    private val jdbcTemplate: JdbcTemplate,
    private val dataIntegrityLogRepository: DataIntegrityLogRepository
) {

    /**
     * 데이터 무결성 검사
     */
    @Transactional
    fun checkIntegrity(
        entityType: String,
        companyId: UUID,
        userId: UUID
    ): DataIntegrityCheckResultDto {
        val startTime = System.currentTimeMillis()
        val checkId = UUID.randomUUID()
        val issues = mutableListOf<DataIntegrityIssueDto>()

        try {
            val totalRecords = getTotalRecords(entityType, companyId)
            var validRecords = 0L
            var invalidRecords = 0L

            // 1. 필수 필드 검사
            val missingRequiredFields = checkMissingRequiredFields(entityType, companyId)
            issues.addAll(missingRequiredFields)
            invalidRecords += missingRequiredFields.size

            // 2. 데이터 형식 검사
            val formatIssues = checkDataFormat(entityType, companyId)
            issues.addAll(formatIssues)
            invalidRecords += formatIssues.size

            // 3. 중복 데이터 검사
            val duplicateIssues = checkDuplicateData(entityType, companyId)
            issues.addAll(duplicateIssues)
            invalidRecords += duplicateIssues.size

            // 4. 참조 무결성 검사
            val referenceIssues = checkReferenceIntegrity(entityType, companyId)
            issues.addAll(referenceIssues)
            invalidRecords += referenceIssues.size

            // 5. 비즈니스 규칙 위반 검사
            val businessRuleIssues = checkBusinessRuleViolations(entityType, companyId)
            issues.addAll(businessRuleIssues)
            invalidRecords += businessRuleIssues.size

            // 6. 고아 레코드 검사
            val orphanedRecords = checkOrphanedRecords(entityType, companyId)
            issues.addAll(orphanedRecords)
            invalidRecords += orphanedRecords.size

            validRecords = totalRecords - invalidRecords

            val duration = System.currentTimeMillis() - startTime

            // 검사 결과 로그 저장
            val log = DataIntegrityLog(
                checkId = checkId,
                checkName = "${entityType} 데이터 무결성 검사",
                entityType = entityType,
                totalRecords = totalRecords,
                validRecords = validRecords,
                invalidRecords = invalidRecords,
                issues = convertIssuesToJson(issues),
                duration = duration,
                checkedBy = userId,
                companyId = companyId
            )
            dataIntegrityLogRepository.save(log)

            return DataIntegrityCheckResultDto(
                checkId = checkId,
                checkName = "${entityType} 데이터 무결성 검사",
                entityType = entityType,
                totalRecords = totalRecords,
                validRecords = validRecords,
                invalidRecords = invalidRecords,
                issues = issues,
                duration = duration
            )

        } catch (e: Exception) {
            throw RuntimeException("데이터 무결성 검사 중 오류가 발생했습니다: ${e.message}", e)
        }
    }

    /**
     * 전체 레코드 수 조회
     */
    private fun getTotalRecords(entityType: String, companyId: UUID): Long {
        val tableName = getTableName(entityType)
        val sql = "SELECT COUNT(*) FROM bms.$tableName WHERE company_id = ?"
        return jdbcTemplate.queryForObject(sql, Long::class.java, companyId) ?: 0L
    }

    /**
     * 필수 필드 누락 검사
     */
    private fun checkMissingRequiredFields(entityType: String, companyId: UUID): List<DataIntegrityIssueDto> {
        val issues = mutableListOf<DataIntegrityIssueDto>()
        val tableName = getTableName(entityType)
        val requiredFields = getRequiredFields(entityType)

        requiredFields.forEach { field ->
            val sql = """
                SELECT ${getPrimaryKeyField(entityType)} as id 
                FROM bms.$tableName 
                WHERE company_id = ? AND ($field IS NULL OR $field = '')
            """
            
            val records = jdbcTemplate.queryForList(sql, companyId)
            records.forEach { record ->
                issues.add(
                    DataIntegrityIssueDto(
                        issueId = UUID.randomUUID(),
                        issueType = DataIntegrityIssueType.MISSING_REQUIRED_FIELD,
                        entityId = UUID.fromString(record["id"].toString()),
                        field = field,
                        description = "필수 필드 '$field'가 누락되었습니다",
                        currentValue = null,
                        expectedValue = "NOT NULL",
                        severity = ValidationSeverity.ERROR,
                        canAutoFix = false,
                        suggestedFix = "필수 필드에 적절한 값을 입력하세요"
                    )
                )
            }
        }

        return issues
    }

    /**
     * 데이터 형식 검사
     */
    private fun checkDataFormat(entityType: String, companyId: UUID): List<DataIntegrityIssueDto> {
        val issues = mutableListOf<DataIntegrityIssueDto>()
        val tableName = getTableName(entityType)

        when (entityType) {
            "FACILITY" -> {
                // 자산 번호 형식 검사
                val sql = """
                    SELECT facility_id as id, asset_number 
                    FROM bms.$tableName 
                    WHERE company_id = ? 
                    AND asset_number IS NOT NULL 
                    AND asset_number !~ '^[A-Z]{2,3}-\d{4,6}-\d{2}$'
                """
                
                val records = jdbcTemplate.queryForList(sql, companyId)
                records.forEach { record ->
                    issues.add(
                        DataIntegrityIssueDto(
                            issueId = UUID.randomUUID(),
                            issueType = DataIntegrityIssueType.INVALID_FORMAT,
                            entityId = UUID.fromString(record["id"].toString()),
                            field = "asset_number",
                            description = "자산 번호 형식이 올바르지 않습니다",
                            currentValue = record["asset_number"],
                            expectedValue = "XX-XXXXXX-XX 형식",
                            severity = ValidationSeverity.ERROR,
                            canAutoFix = false,
                            suggestedFix = "올바른 자산 번호 형식으로 수정하세요"
                        )
                    )
                }
            }
            "COMPANY" -> {
                // 사업자등록번호 형식 검사
                val sql = """
                    SELECT company_id as id, business_registration_number 
                    FROM bms.$tableName 
                    WHERE company_id = ? 
                    AND business_registration_number IS NOT NULL 
                    AND LENGTH(REPLACE(business_registration_number, '-', '')) != 10
                """
                
                val records = jdbcTemplate.queryForList(sql, companyId)
                records.forEach { record ->
                    issues.add(
                        DataIntegrityIssueDto(
                            issueId = UUID.randomUUID(),
                            issueType = DataIntegrityIssueType.INVALID_FORMAT,
                            entityId = UUID.fromString(record["id"].toString()),
                            field = "business_registration_number",
                            description = "사업자등록번호 형식이 올바르지 않습니다",
                            currentValue = record["business_registration_number"],
                            expectedValue = "10자리 숫자",
                            severity = ValidationSeverity.ERROR,
                            canAutoFix = false,
                            suggestedFix = "올바른 사업자등록번호로 수정하세요"
                        )
                    )
                }
            }
        }

        return issues
    }

    /**
     * 중복 데이터 검사
     */
    private fun checkDuplicateData(entityType: String, companyId: UUID): List<DataIntegrityIssueDto> {
        val issues = mutableListOf<DataIntegrityIssueDto>()
        val tableName = getTableName(entityType)
        val uniqueFields = getUniqueFields(entityType)

        uniqueFields.forEach { field ->
            val sql = """
                SELECT $field, COUNT(*) as count, 
                       STRING_AGG(${getPrimaryKeyField(entityType)}::text, ',') as ids
                FROM bms.$tableName 
                WHERE company_id = ? AND $field IS NOT NULL
                GROUP BY $field 
                HAVING COUNT(*) > 1
            """
            
            val records = jdbcTemplate.queryForList(sql, companyId)
            records.forEach { record ->
                val duplicateIds = record["ids"].toString().split(",")
                duplicateIds.forEach { id ->
                    issues.add(
                        DataIntegrityIssueDto(
                            issueId = UUID.randomUUID(),
                            issueType = DataIntegrityIssueType.DUPLICATE_VALUE,
                            entityId = UUID.fromString(id),
                            field = field,
                            description = "중복된 값이 발견되었습니다: ${record[field]}",
                            currentValue = record[field],
                            expectedValue = "고유한 값",
                            severity = ValidationSeverity.ERROR,
                            canAutoFix = false,
                            suggestedFix = "중복된 값을 고유한 값으로 변경하세요"
                        )
                    )
                }
            }
        }

        return issues
    }

    /**
     * 참조 무결성 검사
     */
    private fun checkReferenceIntegrity(entityType: String, companyId: UUID): List<DataIntegrityIssueDto> {
        val issues = mutableListOf<DataIntegrityIssueDto>()
        val tableName = getTableName(entityType)
        val foreignKeys = getForeignKeys(entityType)

        foreignKeys.forEach { (field, referencedTable, referencedField) ->
            val sql = """
                SELECT t1.${getPrimaryKeyField(entityType)} as id, t1.$field
                FROM bms.$tableName t1
                LEFT JOIN bms.$referencedTable t2 ON t1.$field = t2.$referencedField
                WHERE t1.company_id = ? 
                AND t1.$field IS NOT NULL 
                AND t2.$referencedField IS NULL
            """
            
            val records = jdbcTemplate.queryForList(sql, companyId)
            records.forEach { record ->
                issues.add(
                    DataIntegrityIssueDto(
                        issueId = UUID.randomUUID(),
                        issueType = DataIntegrityIssueType.REFERENCE_INTEGRITY,
                        entityId = UUID.fromString(record["id"].toString()),
                        field = field,
                        description = "참조하는 데이터가 존재하지 않습니다",
                        currentValue = record[field],
                        expectedValue = "유효한 참조 값",
                        severity = ValidationSeverity.ERROR,
                        canAutoFix = false,
                        suggestedFix = "존재하는 참조 값으로 수정하거나 참조 데이터를 생성하세요"
                    )
                )
            }
        }

        return issues
    }

    /**
     * 비즈니스 규칙 위반 검사
     */
    private fun checkBusinessRuleViolations(entityType: String, companyId: UUID): List<DataIntegrityIssueDto> {
        val issues = mutableListOf<DataIntegrityIssueDto>()
        val tableName = getTableName(entityType)

        when (entityType) {
            "WORK_ORDER" -> {
                // 작업지시서: 시작일이 종료일보다 늦은 경우
                val sql = """
                    SELECT work_order_id as id, start_date, end_date
                    FROM bms.$tableName 
                    WHERE company_id = ? 
                    AND start_date IS NOT NULL 
                    AND end_date IS NOT NULL 
                    AND start_date > end_date
                """
                
                val records = jdbcTemplate.queryForList(sql, companyId)
                records.forEach { record ->
                    issues.add(
                        DataIntegrityIssueDto(
                            issueId = UUID.randomUUID(),
                            issueType = DataIntegrityIssueType.BUSINESS_RULE_VIOLATION,
                            entityId = UUID.fromString(record["id"].toString()),
                            field = "start_date,end_date",
                            description = "시작일이 종료일보다 늦습니다",
                            currentValue = "시작일: ${record["start_date"]}, 종료일: ${record["end_date"]}",
                            expectedValue = "시작일 <= 종료일",
                            severity = ValidationSeverity.ERROR,
                            canAutoFix = false,
                            suggestedFix = "시작일과 종료일을 올바르게 설정하세요"
                        )
                    )
                }
            }
            "BUDGET_MANAGEMENT" -> {
                // 예산: 사용 금액이 할당 금액을 초과하는 경우
                val sql = """
                    SELECT budget_id as id, allocated_amount, used_amount
                    FROM bms.$tableName 
                    WHERE company_id = ? 
                    AND allocated_amount IS NOT NULL 
                    AND used_amount IS NOT NULL 
                    AND used_amount > allocated_amount
                """
                
                val records = jdbcTemplate.queryForList(sql, companyId)
                records.forEach { record ->
                    issues.add(
                        DataIntegrityIssueDto(
                            issueId = UUID.randomUUID(),
                            issueType = DataIntegrityIssueType.BUSINESS_RULE_VIOLATION,
                            entityId = UUID.fromString(record["id"].toString()),
                            field = "used_amount",
                            description = "사용 금액이 할당 금액을 초과했습니다",
                            currentValue = record["used_amount"],
                            expectedValue = "할당 금액 이하",
                            severity = ValidationSeverity.WARNING,
                            canAutoFix = false,
                            suggestedFix = "예산을 추가 할당하거나 사용 금액을 조정하세요"
                        )
                    )
                }
            }
        }

        return issues
    }

    /**
     * 고아 레코드 검사
     */
    private fun checkOrphanedRecords(entityType: String, companyId: UUID): List<DataIntegrityIssueDto> {
        val issues = mutableListOf<DataIntegrityIssueDto>()
        
        // 회사가 삭제된 경우의 고아 레코드 검사
        if (entityType != "COMPANY") {
            val tableName = getTableName(entityType)
            val sql = """
                SELECT t1.${getPrimaryKeyField(entityType)} as id
                FROM bms.$tableName t1
                LEFT JOIN bms.companies c ON t1.company_id = c.company_id
                WHERE t1.company_id = ? AND c.company_id IS NULL
            """
            
            val records = jdbcTemplate.queryForList(sql, companyId)
            records.forEach { record ->
                issues.add(
                    DataIntegrityIssueDto(
                        issueId = UUID.randomUUID(),
                        issueType = DataIntegrityIssueType.ORPHANED_RECORD,
                        entityId = UUID.fromString(record["id"].toString()),
                        field = "company_id",
                        description = "참조하는 회사가 존재하지 않습니다",
                        currentValue = companyId,
                        expectedValue = "유효한 회사 ID",
                        severity = ValidationSeverity.CRITICAL,
                        canAutoFix = false,
                        suggestedFix = "유효한 회사로 이전하거나 레코드를 삭제하세요"
                    )
                )
            }
        }

        return issues
    }

    /**
     * 이슈를 JSON으로 변환
     */
    private fun convertIssuesToJson(issues: List<DataIntegrityIssueDto>): String {
        // 실제로는 Jackson ObjectMapper 사용
        return "[]" // 임시
    }

    /**
     * 엔티티 타입에 따른 테이블명 반환
     */
    private fun getTableName(entityType: String): String {
        return when (entityType) {
            "COMPANY" -> "companies"
            "FACILITY" -> "facilities"
            "WORK_ORDER" -> "work_orders"
            "MAINTENANCE_PLAN" -> "maintenance_plans"
            "BUDGET_MANAGEMENT" -> "budget_management"
            "COST_TRACKING" -> "cost_tracking"
            "USER" -> "users"
            "ROLE" -> "roles"
            else -> entityType.lowercase()
        }
    }

    /**
     * 엔티티 타입에 따른 기본키 필드명 반환
     */
    private fun getPrimaryKeyField(entityType: String): String {
        return when (entityType) {
            "COMPANY" -> "company_id"
            "FACILITY" -> "facility_id"
            "WORK_ORDER" -> "work_order_id"
            "MAINTENANCE_PLAN" -> "plan_id"
            "BUDGET_MANAGEMENT" -> "budget_id"
            "COST_TRACKING" -> "cost_id"
            "USER" -> "user_id"
            "ROLE" -> "role_id"
            else -> "${entityType.lowercase()}_id"
        }
    }

    /**
     * 엔티티 타입에 따른 필수 필드 목록 반환
     */
    private fun getRequiredFields(entityType: String): List<String> {
        return when (entityType) {
            "COMPANY" -> listOf("company_name", "business_registration_number")
            "FACILITY" -> listOf("facility_name", "facility_type", "location")
            "WORK_ORDER" -> listOf("title", "work_type", "priority", "status")
            "USER" -> listOf("username", "email", "role_id")
            else -> emptyList()
        }
    }

    /**
     * 엔티티 타입에 따른 고유 필드 목록 반환
     */
    private fun getUniqueFields(entityType: String): List<String> {
        return when (entityType) {
            "COMPANY" -> listOf("business_registration_number")
            "FACILITY" -> listOf("asset_number")
            "USER" -> listOf("username", "email")
            else -> emptyList()
        }
    }

    /**
     * 엔티티 타입에 따른 외래키 정보 반환
     */
    private fun getForeignKeys(entityType: String): List<Triple<String, String, String>> {
        return when (entityType) {
            "FACILITY" -> listOf(
                Triple("company_id", "companies", "company_id"),
                Triple("created_by", "users", "user_id")
            )
            "WORK_ORDER" -> listOf(
                Triple("company_id", "companies", "company_id"),
                Triple("facility_id", "facilities", "facility_id"),
                Triple("assigned_to", "users", "user_id"),
                Triple("created_by", "users", "user_id")
            )
            "USER" -> listOf(
                Triple("company_id", "companies", "company_id"),
                Triple("role_id", "roles", "role_id")
            )
            else -> emptyList()
        }
    }

    /**
     * 사업자등록번호 검증
     */
    fun validateBusinessRegistrationNumber(businessNumber: String): Boolean {
        if (businessNumber.length != 10) return false
        
        val digits = businessNumber.map { it.digitToIntOrNull() ?: return false }
        val checkDigit = digits[9]
        
        val weights = listOf(1, 3, 7, 1, 3, 7, 1, 3, 5)
        val sum = digits.take(9).zip(weights).sumOf { (digit, weight) -> digit * weight }
        val calculatedCheckDigit = (10 - (sum % 10)) % 10
        
        return checkDigit == calculatedCheckDigit
    }

    /**
     * 연체료 계산
     */
    fun calculateLateFee(
        principalAmount: java.math.BigDecimal,
        overdueDays: Int,
        annualRate: java.math.BigDecimal,
        gracePeriodDays: Int
    ): java.math.BigDecimal {
        if (overdueDays <= gracePeriodDays) {
            return java.math.BigDecimal.ZERO
        }
        
        val actualOverdueDays = overdueDays - gracePeriodDays
        val dailyRate = annualRate.divide(java.math.BigDecimal("365"), 10, java.math.RoundingMode.HALF_UP)
        val lateFee = principalAmount
            .multiply(dailyRate)
            .multiply(java.math.BigDecimal(actualOverdueDays))
            .divide(java.math.BigDecimal("100"), 0, java.math.RoundingMode.HALF_UP)
        
        return lateFee
    }

    /**
     * 날짜 범위 검증
     */
    fun validateDateRange(startDate: java.time.LocalDate, endDate: java.time.LocalDate) {
        if (startDate.isAfter(endDate)) {
            throw IllegalArgumentException("시작일이 종료일보다 늦을 수 없습니다")
        }
    }

    /**
     * 양수 금액 검증
     */
    fun validatePositiveAmount(amount: java.math.BigDecimal, fieldName: String) {
        if (amount <= java.math.BigDecimal.ZERO) {
            throw IllegalArgumentException("$fieldName 은(는) 양수여야 합니다")
        }
    }

    /**
     * 이메일 형식 검증
     */
    fun validateEmailFormat(email: String): Boolean {
        val emailRegex = "^[A-Za-z0-9+_.-]+@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})$".toRegex()
        return emailRegex.matches(email)
    }

    /**
     * 전화번호 형식 검증
     */
    fun validatePhoneNumber(phoneNumber: String): Boolean {
        val phoneRegex = "^01[0-9]-\\d{4}-\\d{4}$".toRegex()
        return phoneRegex.matches(phoneNumber)
    }
}