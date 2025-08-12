package com.qiro.security

import org.springframework.security.core.annotation.AuthenticationPrincipal

/**
 * 현재 사용자 정보 주입 어노테이션
 */
@Target(AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
@AuthenticationPrincipal
annotation class CurrentUser