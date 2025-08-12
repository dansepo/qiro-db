package com.qiro.common.validation

import jakarta.validation.Constraint
import jakarta.validation.ConstraintValidator
import jakarta.validation.ConstraintValidatorContext
import jakarta.validation.Payload
import java.time.LocalDate
import kotlin.reflect.KClass

/**
 * 한국 휴대폰 번호 검증 어노테이션
 */
@Target(AnnotationTarget.FIELD, AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
@Constraint(validatedBy = [KoreanPhoneNumberValidator::class])
@MustBeDocumented
annotation class KoreanPhoneNumber(
    val message: String = "올바른 한국 휴대폰 번호 형식이 아닙니다.",
    val groups: Array<KClass<*>> = [],
    val payload: Array<KClass<out Payload>> = []
)

class KoreanPhoneNumberValidator : ConstraintValidator<KoreanPhoneNumber, String?> {
    private val phonePattern = Regex("^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$")
    
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        return value == null || phonePattern.matches(value)
    }
}

/**
 * 사업자등록번호 검증 어노테이션
 */
@Target(AnnotationTarget.FIELD, AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
@Constraint(validatedBy = [BusinessRegistrationNumberValidator::class])
@MustBeDocumented
annotation class BusinessRegistrationNumber(
    val message: String = "올바른 사업자등록번호 형식이 아닙니다.",
    val groups: Array<KClass<*>> = [],
    val payload: Array<KClass<out Payload>> = []
)

class BusinessRegistrationNumberValidator : ConstraintValidator<BusinessRegistrationNumber, String?> {
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        if (value == null) return true
        
        val cleanNumber = value.replace("-", "")
        if (cleanNumber.length != 10 || !cleanNumber.all { it.isDigit() }) {
            return false
        }
        
        // 사업자등록번호 체크섬 검증
        val checkSum = intArrayOf(1, 3, 7, 1, 3, 7, 1, 3, 5)
        var sum = 0
        
        for (i in 0..8) {
            sum += cleanNumber[i].digitToInt() * checkSum[i]
        }
        
        sum += (cleanNumber[8].digitToInt() * 5) / 10
        val remainder = sum % 10
        val checkDigit = if (remainder == 0) 0 else 10 - remainder
        
        return checkDigit == cleanNumber[9].digitToInt()
    }
}

/**
 * 날짜 범위 검증 어노테이션
 */
@Target(AnnotationTarget.CLASS, AnnotationTarget.TYPE)
@Retention(AnnotationRetention.RUNTIME)
@Constraint(validatedBy = [DateRangeValidator::class])
@MustBeDocumented
annotation class DateRange(
    val message: String = "시작일이 종료일보다 늦을 수 없습니다.",
    val startField: String,
    val endField: String,
    val groups: Array<KClass<*>> = [],
    val payload: Array<KClass<out Payload>> = []
)

class DateRangeValidator : ConstraintValidator<DateRange, Any> {
    private lateinit var startField: String
    private lateinit var endField: String
    
    override fun initialize(constraintAnnotation: DateRange) {
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
 * 양수 검증 어노테이션
 */
@Target(AnnotationTarget.FIELD, AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
@Constraint(validatedBy = [PositiveNumberValidator::class])
@MustBeDocumented
annotation class PositiveNumber(
    val message: String = "양수여야 합니다.",
    val groups: Array<KClass<*>> = [],
    val payload: Array<KClass<out Payload>> = []
)

class PositiveNumberValidator : ConstraintValidator<PositiveNumber, Number?> {
    override fun isValid(value: Number?, context: ConstraintValidatorContext?): Boolean {
        return value == null || value.toDouble() > 0
    }
}

/**
 * 세대 번호 검증 어노테이션
 */
@Target(AnnotationTarget.FIELD, AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
@Constraint(validatedBy = [UnitNumberValidator::class])
@MustBeDocumented
annotation class UnitNumber(
    val message: String = "올바른 세대 번호 형식이 아닙니다.",
    val groups: Array<KClass<*>> = [],
    val payload: Array<KClass<out Payload>> = []
)

class UnitNumberValidator : ConstraintValidator<UnitNumber, String?> {
    private val unitPattern = Regex("^[0-9]{3,4}[A-Z]?$")
    
    override fun isValid(value: String?, context: ConstraintValidatorContext?): Boolean {
        return value == null || unitPattern.matches(value)
    }
}