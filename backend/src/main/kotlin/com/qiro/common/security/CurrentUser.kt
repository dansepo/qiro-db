package com.qiro.common.security

/**
 * 현재 사용자 정보 어노테이션
 */
@Target(AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
annotation class CurrentUser