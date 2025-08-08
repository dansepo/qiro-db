package com.qiro.domain.validation.validator

import com.qiro.domain.validation.annotation.*
import jakarta.validation.ConstraintValidator
import jakarta.validation.ConstraintValidatorContext
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit
import java.util.regex.Pattern

/**
 * 자산 번호 검증기
 */
@Component
class AssetNumberValidator : ConstraintValidator<ValidAssetNumber, String> {
    private val assetNumberPattern = Pattern.compile("^[A-Z]{2,3}-\\d{4,6}-\\d{2}$")
    
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        if (value.isNullOrBlank()) return true // @NotNull과 함께 사용
        return assetNumberPattern.matcher(value).matches()
    }
}

/**
 * 한국 전화번호 검증기
 */
@Component
class KoreanPhoneValidator : ConstraintValidator<ValidKoreanPhone, String> {
    private val phonePatterns = listOf(
        Pattern.compile("^010-\\d{4}-\\d{4}$"),           // 010-1234-5678
        Pattern.compile("^02-\\d{3,4}-\\d{4}$"),         // 02-123-4567, 02-1234-5678
        Pattern.compile("^0[3-6]\\d-\\d{3,4}-\\d{4}$"),  // 031-123-4567
        Pattern.compile("^070-\\d{4}-\\d{4}$"),          // 070-1234-5678
        Pattern.compile("^1[5-9]\\d{2}-\\d{4}$")         // 1588-1234
    )
    
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        if (value.isNullOrBlank()) return true
        return phonePatterns.any { it.matcher(value).matches() }
    }
}

/**
 * 사업자등록번호 검증기
 */
@Component
class BusinessRegistrationNumberValidator : ConstraintValidator<ValidBusinessRegistrationNumber, String> {
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        if (value.isNullOrBlank()) return true
        
        val cleanValue = value.replace("-", "")
        if (cleanValue.length != 10 || !cleanValue.all { it.isDigit() }) {
            return false
        }
        
        // 사업자등록번호 체크섬 검증
        val weights = intArrayOf(1, 3, 7, 1, 3, 7, 1, 3, 5)
        var sum = 0
        for (i in 0..8) {
            sum += cleanValue[i].digitToInt() * weights[i]
        }
        sum += (cleanValue[8].digitToInt() * 5) / 10
        val checkDigit = (10 - (sum % 10)) % 10
        
        return checkDigit == cleanValue[9].digitToInt()
    }
}

/**
 * 날짜 범위 검증기
 */
@Component
class DateRangeValidator : ConstraintValidator<ValidDateRange, Any> {
    private lateinit var startField: String
    private lateinit var endField: String
    
    override fun initialize(constraintAnnotation: ValidDateRange) {
        startField = constraintAnnotation.startField
        endField = constraintAnnotation.endField
    }
    
    override fun isValid(value: Any?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        
        try {
            val startDate = getFieldValue(value, startField) as? LocalDate
            val endDate = getFieldValue(value, endField) as? LocalDate
            
            if (startDate == null || endDate == null) return true
            
            return !startDate.isAfter(endDate)
        } catch (e: Exception) {
            return false
        }
    }
    
    private fun getFieldValue(obj: Any, fieldName: String): Any? {
        val field = obj.javaClass.getDeclaredField(fieldName)
        field.isAccessible = true
        return field.get(obj)
    }
}

/**
 * 작업 시간 검증기
 */
@Component
class WorkTimeValidator : ConstraintValidator<ValidWorkTime, Any> {
    private lateinit var startTimeField: String
    private lateinit var endTimeField: String
    private var maxHours: Int = 24
    
    override fun initialize(constraintAnnotation: ValidWorkTime) {
        startTimeField = constraintAnnotation.startTimeField
        endTimeField = constraintAnnotation.endTimeField
        maxHours = constraintAnnotation.maxHours
    }
    
    override fun isValid(value: Any?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        
        try {
            val startTime = getFieldValue(value, startTimeField) as? LocalDateTime
            val endTime = getFieldValue(value, endTimeField) as? LocalDateTime
            
            if (startTime == null || endTime == null) return true
            if (startTime.isAfter(endTime)) return false
            
            val hours = ChronoUnit.HOURS.between(startTime, endTime)
            return hours <= maxHours
        } catch (e: Exception) {
            return false
        }
    }
    
    private fun getFieldValue(obj: Any, fieldName: String): Any? {
        val field = obj.javaClass.getDeclaredField(fieldName)
        field.isAccessible = true
        return field.get(obj)
    }
}

/**
 * 예산 금액 검증기
 */
@Component
class BudgetAmountValidator : ConstraintValidator<ValidBudgetAmount, BigDecimal> {
    private lateinit var min: BigDecimal
    private lateinit var max: BigDecimal
    private lateinit var currency: String
    
    override fun initialize(constraintAnnotation: ValidBudgetAmount) {
        min = BigDecimal(constraintAnnotation.min)
        max = BigDecimal(constraintAnnotation.max)
        currency = constraintAnnotation.currency
    }
    
    override fun isValid(value: BigDecimal?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        return value >= min && value <= max
    }
}

/**
 * 우선순위 검증기
 */
@Component
class PriorityValidator : ConstraintValidator<ValidPriority, String> {
    private lateinit var allowedValues: Set<String>
    
    override fun initialize(constraintAnnotation: ValidPriority) {
        allowedValues = constraintAnnotation.allowedValues.toSet()
    }
    
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        if (value.isNullOrBlank()) return true
        return allowedValues.contains(value.uppercase())
    }
}

/**
 * 시설물 위치 검증기
 */
@Component
class FacilityLocationValidator : ConstraintValidator<ValidFacilityLocation, String> {
    private lateinit var pattern: Pattern
    private var maxLength: Int = 200
    
    override fun initialize(constraintAnnotation: ValidFacilityLocation) {
        pattern = Pattern.compile(constraintAnnotation.pattern)
        maxLength = constraintAnnotation.maxLength
    }
    
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        if (value.isNullOrBlank()) return true
        if (value.length > maxLength) return false
        return pattern.matcher(value).matches()
    }
}

/**
 * 정비 주기 검증기
 */
@Component
class MaintenanceCycleValidator : ConstraintValidator<ValidMaintenanceCycle, Any> {
    private lateinit var frequencyField: String
    private lateinit var unitField: String
    private var minDays: Int = 1
    private var maxDays: Int = 3650
    
    override fun initialize(constraintAnnotation: ValidMaintenanceCycle) {
        frequencyField = constraintAnnotation.frequencyField
        unitField = constraintAnnotation.unitField
        minDays = constraintAnnotation.minDays
        maxDays = constraintAnnotation.maxDays
    }
    
    override fun isValid(value: Any?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        
        try {
            val frequency = getFieldValue(value, frequencyField) as? Int ?: return true
            val unit = getFieldValue(value, unitField) as? String ?: return true
            
            val totalDays = when (unit.uppercase()) {
                "DAY", "DAYS" -> frequency
                "WEEK", "WEEKS" -> frequency * 7
                "MONTH", "MONTHS" -> frequency * 30
                "YEAR", "YEARS" -> frequency * 365
                else -> return false
            }
            
            return totalDays in minDays..maxDays
        } catch (e: Exception) {
            return false
        }
    }
    
    private fun getFieldValue(obj: Any, fieldName: String): Any? {
        val field = obj.javaClass.getDeclaredField(fieldName)
        field.isAccessible = true
        return field.get(obj)
    }
}

/**
 * 파일 크기 검증기
 */
@Component
class FileSizeValidator : ConstraintValidator<ValidFileSize, ByteArray> {
    private var maxSizeInBytes: Long = 0
    
    override fun initialize(constraintAnnotation: ValidFileSize) {
        maxSizeInBytes = constraintAnnotation.maxSizeInMB * 1024L * 1024L
    }
    
    override fun isValid(value: ByteArray?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        return value.size <= maxSizeInBytes
    }
}

/**
 * 파일 확장자 검증기
 */
@Component
class FileExtensionValidator : ConstraintValidator<ValidFileExtension, String> {
    private lateinit var allowedExtensions: Set<String>
    
    override fun initialize(constraintAnnotation: ValidFileExtension) {
        allowedExtensions = constraintAnnotation.allowedExtensions.map { it.lowercase() }.toSet()
    }
    
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        if (value.isNullOrBlank()) return true
        val extension = value.substringAfterLast('.', "").lowercase()
        return allowedExtensions.contains(extension)
    }
}

/**
 * 조건부 필수 필드 검증기
 */
@Component
class ConditionalRequiredValidator : ConstraintValidator<ConditionalRequired, Any> {
    private lateinit var conditionalField: String
    private lateinit var conditionalValue: String
    private lateinit var requiredField: String
    
    override fun initialize(constraintAnnotation: ConditionalRequired) {
        conditionalField = constraintAnnotation.conditionalField
        conditionalValue = constraintAnnotation.conditionalValue
        requiredField = constraintAnnotation.requiredField
    }
    
    override fun isValid(value: Any?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        
        try {
            val conditionValue = getFieldValue(value, conditionalField)?.toString()
            val requiredValue = getFieldValue(value, requiredField)
            
            if (conditionValue == conditionalValue) {
                return requiredValue != null && requiredValue.toString().isNotBlank()
            }
            
            return true
        } catch (e: Exception) {
            return false
        }
    }
    
    private fun getFieldValue(obj: Any, fieldName: String): Any? {
        val field = obj.javaClass.getDeclaredField(fieldName)
        field.isAccessible = true
        return field.get(obj)
    }
}

/**
 * 중복 값 검증기
 */
@Component
class UniqueValueValidator : ConstraintValidator<UniqueValue, Any> {
    // 실제 구현에서는 Repository를 주입받아 사용
    override fun isValid(value: Any?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        // TODO: Repository를 통한 중복 검사 구현
        return true
    }
}

/**
 * 참조 무결성 검증기
 */
@Component
class ReferenceIntegrityValidator : ConstraintValidator<ValidReference, Any> {
    // 실제 구현에서는 Repository를 주입받아 사용
    override fun isValid(value: Any?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        // TODO: Repository를 통한 참조 무결성 검사 구현
        return true
    }
}

/**
 * 비즈니스 규칙 검증기
 */
@Component
class BusinessRuleValidator : ConstraintValidator<ValidBusinessRule, Any> {
    // 실제 구현에서는 BusinessRuleService를 주입받아 사용
    override fun isValid(value: Any?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        // TODO: 비즈니스 규칙 엔진을 통한 검증 구현
        return true
    }
}