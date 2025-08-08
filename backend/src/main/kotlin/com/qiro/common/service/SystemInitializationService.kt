package com.qiro.common.service

import com.qiro.domain.migration.dto.*
import java.util.*

/**
 * 시스템 초기화 서비스 인터페이스
 */
interface SystemInitializationService {
    
    /**
     * 전체 시스템 초기화
     */
    fun initializeSystem(request: SystemInitializationRequest): SystemInitializationResult
    
    /**
     * 기본 공통 코드 생성
     */
    fun createDefaultCommonCodes(request: CommonCodeInitializationRequest): SystemInitializationResult
    
    /**
     * 기본 역할 및 권한 생성
     */
    fun createDefaultRoles(request: RoleInitializationRequest): SystemInitializationResult
    
    /**
     * 시스템 설정 초기화
     */
    fun initializeSystemSettings(request: SystemSettingsInitializationRequest): SystemInitializationResult
    
    /**
     * 기본 데이터 생성
     */
    fun createDefaultData(request: DefaultDataInitializationRequest): SystemInitializationResult
    
    /**
     * 초기화 상태 확인
     */
    fun getInitializationStatus(companyId: UUID): InitializationStatusDto
    
    /**
     * 초기화 재설정 (기존 데이터 삭제 후 재생성)
     */
    fun resetInitialization(companyId: UUID): SystemInitializationResult
    
    /**
     * 기본 공통 코드 그룹 정의 조회
     */
    fun getDefaultCodeGroupDefinitions(): List<DefaultCodeGroupDefinition>
    
    /**
     * 회사별 초기화 검증
     */
    fun validateInitialization(companyId: UUID): ValidationResult
}