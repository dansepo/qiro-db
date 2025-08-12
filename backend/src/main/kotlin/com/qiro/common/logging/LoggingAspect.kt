package com.qiro.common.logging

import org.aspectj.lang.JoinPoint
import org.aspectj.lang.ProceedingJoinPoint
import org.aspectj.lang.annotation.*
import org.slf4j.LoggerFactory
import org.slf4j.MDC
import org.springframework.stereotype.Component
import java.util.*

/**
 * 로깅 AOP
 */
@Aspect
@Component
class LoggingAspect {

    private val logger = LoggerFactory.getLogger(LoggingAspect::class.java)

    /**
     * Controller 메서드 실행 로깅
     */
    @Around("execution(* com.qiro.domain.*.controller.*.*(..))")
    fun logControllerMethods(joinPoint: ProceedingJoinPoint): Any? {
        val traceId = UUID.randomUUID().toString()
        MDC.put("traceId", traceId)
        
        val className = joinPoint.signature.declaringTypeName
        val methodName = joinPoint.signature.name
        val args = joinPoint.args
        
        logger.info("Controller method started: {}.{} with args: {}", className, methodName, args)
        
        val startTime = System.currentTimeMillis()
        
        return try {
            val result = joinPoint.proceed()
            val endTime = System.currentTimeMillis()
            val duration = endTime - startTime
            
            logger.info("Controller method completed: {}.{} in {}ms", className, methodName, duration)
            result
        } catch (e: Exception) {
            val endTime = System.currentTimeMillis()
            val duration = endTime - startTime
            
            logger.error("Controller method failed: {}.{} in {}ms with error: {}", 
                className, methodName, duration, e.message, e)
            throw e
        } finally {
            MDC.remove("traceId")
        }
    }

    /**
     * Service 메서드 실행 로깅
     */
    @Around("execution(* com.qiro.domain.*.service.*.*(..))")
    fun logServiceMethods(joinPoint: ProceedingJoinPoint): Any? {
        val className = joinPoint.signature.declaringTypeName
        val methodName = joinPoint.signature.name
        
        logger.debug("Service method started: {}.{}", className, methodName)
        
        val startTime = System.currentTimeMillis()
        
        return try {
            val result = joinPoint.proceed()
            val endTime = System.currentTimeMillis()
            val duration = endTime - startTime
            
            logger.debug("Service method completed: {}.{} in {}ms", className, methodName, duration)
            result
        } catch (e: Exception) {
            val endTime = System.currentTimeMillis()
            val duration = endTime - startTime
            
            logger.error("Service method failed: {}.{} in {}ms with error: {}", 
                className, methodName, duration, e.message, e)
            throw e
        }
    }

    /**
     * Repository 메서드 실행 로깅
     */
    @Around("execution(* com.qiro.domain.*.repository.*.*(..))")
    fun logRepositoryMethods(joinPoint: ProceedingJoinPoint): Any? {
        val className = joinPoint.signature.declaringTypeName
        val methodName = joinPoint.signature.name
        
        logger.trace("Repository method started: {}.{}", className, methodName)
        
        val startTime = System.currentTimeMillis()
        
        return try {
            val result = joinPoint.proceed()
            val endTime = System.currentTimeMillis()
            val duration = endTime - startTime
            
            if (duration > 1000) { // 1초 이상 걸린 쿼리 로깅
                logger.warn("Slow repository method: {}.{} took {}ms", className, methodName, duration)
            } else {
                logger.trace("Repository method completed: {}.{} in {}ms", className, methodName, duration)
            }
            
            result
        } catch (e: Exception) {
            val endTime = System.currentTimeMillis()
            val duration = endTime - startTime
            
            logger.error("Repository method failed: {}.{} in {}ms with error: {}", 
                className, methodName, duration, e.message, e)
            throw e
        }
    }

    /**
     * 비즈니스 예외 로깅
     */
    @AfterThrowing(pointcut = "execution(* com.qiro.domain.*.service.*.*(..))", throwing = "ex")
    fun logBusinessExceptions(joinPoint: JoinPoint, ex: Exception) {
        val className = joinPoint.signature.declaringTypeName
        val methodName = joinPoint.signature.name
        
        when (ex) {
            is com.qiro.common.exception.BusinessException -> {
                logger.warn("Business exception in {}.{}: [{}] {}", 
                    className, methodName, ex.errorCode, ex.message)
            }
            else -> {
                logger.error("Unexpected exception in {}.{}: {}", 
                    className, methodName, ex.message, ex)
            }
        }
    }
}

/**
 * 구조화된 로깅을 위한 유틸리티
 */
object StructuredLogger {
    
    private val logger = LoggerFactory.getLogger(StructuredLogger::class.java)
    
    /**
     * 비즈니스 이벤트 로깅
     */
    fun logBusinessEvent(
        eventType: String,
        entityType: String,
        entityId: String,
        userId: String? = null,
        companyId: String? = null,
        details: Map<String, Any> = emptyMap()
    ) {
        MDC.put("eventType", eventType)
        MDC.put("entityType", entityType)
        MDC.put("entityId", entityId)
        userId?.let { MDC.put("userId", it) }
        companyId?.let { MDC.put("companyId", it) }
        
        try {
            logger.info("Business event: {} {} {} - {}", eventType, entityType, entityId, details)
        } finally {
            MDC.remove("eventType")
            MDC.remove("entityType")
            MDC.remove("entityId")
            MDC.remove("userId")
            MDC.remove("companyId")
        }
    }
    
    /**
     * 보안 이벤트 로깅
     */
    fun logSecurityEvent(
        eventType: String,
        userId: String? = null,
        ipAddress: String? = null,
        userAgent: String? = null,
        success: Boolean,
        details: String? = null
    ) {
        MDC.put("securityEvent", eventType)
        MDC.put("success", success.toString())
        userId?.let { MDC.put("userId", it) }
        ipAddress?.let { MDC.put("ipAddress", it) }
        userAgent?.let { MDC.put("userAgent", it) }
        
        try {
            if (success) {
                logger.info("Security event: {} - {}", eventType, details ?: "Success")
            } else {
                logger.warn("Security event: {} - {}", eventType, details ?: "Failed")
            }
        } finally {
            MDC.remove("securityEvent")
            MDC.remove("success")
            MDC.remove("userId")
            MDC.remove("ipAddress")
            MDC.remove("userAgent")
        }
    }
    
    /**
     * 성능 이벤트 로깅
     */
    fun logPerformanceEvent(
        operation: String,
        duration: Long,
        threshold: Long = 1000,
        details: Map<String, Any> = emptyMap()
    ) {
        MDC.put("operation", operation)
        MDC.put("duration", duration.toString())
        
        try {
            if (duration > threshold) {
                logger.warn("Slow operation: {} took {}ms - {}", operation, duration, details)
            } else {
                logger.debug("Performance: {} completed in {}ms", operation, duration)
            }
        } finally {
            MDC.remove("operation")
            MDC.remove("duration")
        }
    }
}