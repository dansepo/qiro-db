package com.qiro.common.security

/**
 * 현재 인증된 사용자 정보를 주입받기 위한 어노테이션
 */
@Target(AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
annotation class CurrentUser