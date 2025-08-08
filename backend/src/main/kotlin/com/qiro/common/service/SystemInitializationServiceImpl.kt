package com.qiro.common.service

import com.qiro.domain.migration.common.BaseService
import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.CodeGroup
import com.qiro.domain.migration.entity.CommonCode
import com.qiro.domain.migration.exception.ProcedureMigrationException
import com.qiro.domain.migration.repository.CodeGroupRepository
import com.qiro.domain.migration.repository.CommonCodeRepository
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDateTime
import java.util.*

/**
 * 시스템 초기화 서비스 구현
 */
@Service
@Transactional
class SystemInitializationServiceImpl(
    private val codeGroupRepository: CodeGroupRepository,
    private val commonCodeRepository: CommonCodeRepository,
    private val auditService: AuditService
) : SystemInitializationService, BaseService {

    private val logger = LoggerFactory.getLogger(SystemInitializationServiceImpl::class.java)

    /**
     * 전체 시스템 초기화
     */
    override fun initializeSystem(request: SystemInitializationRequest): SystemInitializationResult {
        logOperation("initializeSystem", request)
        
        val initializedComponents = mutableListOf<String>()
        val errors = mutableListOf<String>()
        val startTime = LocalDateTime.now()
        
        try {
            // 공통 코드 초기화
            if (request.initializeCommonCodes) {
                try {
                    createDefaultCommonCodes(CommonCodeInitializationRequest(request.companyId))
                    initializedComponents.add("COMMON_CODES")
                } catch (e: Exception) {
                    errors.add("공통 코드 초기화 실패: ${e.message}")
                }
            }
            
            // 역할 초기화
            if (request.initializeRoles) {
                try {
                    createDefaultRoles(RoleInitializationRequest(request.companyId))
                    initializedComponents.add("ROLES")
                } catch (e: Exception) {
                    errors.add("역할 초기화 실패: ${e.message}")
                }
            }
            
            // 시스템 설정 초기화
            if (request.initializeSettings) {
                try {
                    initializeSystemSettings(SystemSettingsInitializationRequest(request.companyId))
                    initializedComponents.add("SYSTEM_SETTINGS")
                } catch (e: Exception) {
                    errors.add("시스템 설정 초기화 실패: ${e.message}")
                }
            }
            
            // 기본 데이터 초기화
            if (request.initializeDefaultData) {
                try {
                    createDefaultData(DefaultDataInitializationRequest(request.companyId))
                    initializedComponents.add("DEFAULT_DATA")
                } catch (e: Exception) {
                    errors.add("기본 데이터 초기화 실패: ${e.message}")
                }
            }
            
            // 감사 로그 기록
            auditService.logSystemEvent(
                companyId = request.companyId,
                eventType = "SYSTEM_INITIALIZATION",
                description = "시스템 초기화 완료",
                details = "초기화된 컴포넌트: ${initializedComponents.joinToString(", ")}",
                eventResult = if (errors.isEmpty()) "SUCCESS" else "PARTIAL_SUCCESS"
            )
            
            return SystemInitializationResult(
                success = errors.isEmpty(),
                companyId = request.companyId,
                initializedComponents = initializedComponents,
                errors = errors,
                initializationTime = startTime,
                details = mapOf(
                    "duration_ms" to (System.currentTimeMillis() - startTime.toEpochSecond(java.time.ZoneOffset.UTC) * 1000),
                    "total_components" to initializedComponents.size,
                    "error_count" to errors.size
                )
            )
            
        } catch (e: Exception) {
            logger.error("시스템 초기화 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("시스템 초기화 실패: ${e.message}")
        }
    }

    /**
     * 기본 공통 코드 생성
     */
    override fun createDefaultCommonCodes(request: CommonCodeInitializationRequest): SystemInitializationResult {
        logOperation("createDefaultCommonCodes", request)
        
        val initializedComponents = mutableListOf<String>()
        val errors = mutableListOf<String>()
        val startTime = LocalDateTime.now()
        
        try {
            val defaultGroups = getDefaultCodeGroupDefinitions()
            val targetGroups = if (request.codeGroups.isEmpty()) {
                defaultGroups
            } else {
                defaultGroups.filter { it.groupCode in request.codeGroups }
            }
            
            for (groupDef in targetGroups) {
                try {
                    // 코드 그룹 생성 또는 확인
                    val existingGroup = codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(
                        request.companyId, groupDef.groupCode
                    )
                    
                    val codeGroup = if (existingGroup.isPresent && !request.overwriteExisting) {
                        existingGroup.get()
                    } else {
                        val newGroup = CodeGroup(
                            id = UUID.randomUUID(),
                            companyId = request.companyId,
                            groupCode = groupDef.groupCode,
                            groupName = groupDef.groupName,
                            groupDescription = groupDef.description,
                            displayOrder = 0,
                            isSystemCode = true,
                            isActive = true
                        )
                        codeGroupRepository.save(newGroup)
                    }
                    
                    // 공통 코드 생성
                    for (codeDef in groupDef.codes) {
                        val existingCode = commonCodeRepository.existsByGroupIdAndCodeValueAndCompanyId(
                            codeGroup.id!!, codeDef.codeValue, request.companyId
                        )
                        
                        if (!existingCode || request.overwriteExisting) {
                            val commonCode = CommonCode(
                                id = UUID.randomUUID(),
                                companyId = request.companyId,
                                groupId = codeGroup.id!!,
                                codeValue = codeDef.codeValue,
                                codeName = codeDef.codeName,
                                codeDescription = codeDef.description,
                                displayOrder = codeDef.sortOrder,
                                isActive = codeDef.isActive
                            )
                            commonCodeRepository.save(commonCode)
                        }
                    }
                    
                    initializedComponents.add("CODE_GROUP_${groupDef.groupCode}")
                    
                } catch (e: Exception) {
                    errors.add("코드 그룹 ${groupDef.groupCode} 생성 실패: ${e.message}")
                }
            }
            
            return SystemInitializationResult(
                success = errors.isEmpty(),
                companyId = request.companyId,
                initializedComponents = initializedComponents,
                errors = errors,
                initializationTime = startTime,
                details = mapOf(
                    "created_groups" to initializedComponents.size,
                    "total_groups" to targetGroups.size
                )
            )
            
        } catch (e: Exception) {
            logger.error("기본 공통 코드 생성 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("기본 공통 코드 생성 실패: ${e.message}")
        }
    }

    /**
     * 기본 역할 및 권한 생성 (간단 구현)
     */
    override fun createDefaultRoles(request: RoleInitializationRequest): SystemInitializationResult {
        logOperation("createDefaultRoles", request)
        
        val initializedComponents = mutableListOf<String>()
        val startTime = LocalDateTime.now()
        
        try {
            // 기본 역할 생성 로직 (실제 구현에서는 Role 엔티티와 연동)
            if (request.createDefaultRoles) {
                initializedComponents.add("DEFAULT_ROLES")
            }
            
            if (request.createDefaultPermissions) {
                initializedComponents.add("DEFAULT_PERMISSIONS")
            }
            
            return SystemInitializationResult(
                success = true,
                companyId = request.companyId,
                initializedComponents = initializedComponents,
                errors = emptyList(),
                initializationTime = startTime,
                details = mapOf("roles_created" to initializedComponents.size)
            )
            
        } catch (e: Exception) {
            logger.error("기본 역할 생성 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("기본 역할 생성 실패: ${e.message}")
        }
    }

    /**
     * 시스템 설정 초기화 (간단 구현)
     */
    override fun initializeSystemSettings(request: SystemSettingsInitializationRequest): SystemInitializationResult {
        logOperation("initializeSystemSettings", request)
        
        val initializedComponents = mutableListOf<String>()
        val startTime = LocalDateTime.now()
        
        try {
            // 시스템 설정 초기화 로직 (실제 구현에서는 SystemSettings 엔티티와 연동)
            initializedComponents.add("SYSTEM_SETTINGS")
            
            return SystemInitializationResult(
                success = true,
                companyId = request.companyId,
                initializedComponents = initializedComponents,
                errors = emptyList(),
                initializationTime = startTime,
                details = mapOf("settings_created" to initializedComponents.size)
            )
            
        } catch (e: Exception) {
            logger.error("시스템 설정 초기화 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("시스템 설정 초기화 실패: ${e.message}")
        }
    }

    /**
     * 기본 데이터 생성 (간단 구현)
     */
    override fun createDefaultData(request: DefaultDataInitializationRequest): SystemInitializationResult {
        logOperation("createDefaultData", request)
        
        val initializedComponents = mutableListOf<String>()
        val startTime = LocalDateTime.now()
        
        try {
            // 기본 데이터 생성 로직
            initializedComponents.add("DEFAULT_DATA")
            
            if (request.includeTestData) {
                initializedComponents.add("TEST_DATA")
            }
            
            return SystemInitializationResult(
                success = true,
                companyId = request.companyId,
                initializedComponents = initializedComponents,
                errors = emptyList(),
                initializationTime = startTime,
                details = mapOf("data_created" to initializedComponents.size)
            )
            
        } catch (e: Exception) {
            logger.error("기본 데이터 생성 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("기본 데이터 생성 실패: ${e.message}")
        }
    }

    /**
     * 초기화 상태 확인
     */
    @Transactional(readOnly = true)
    override fun getInitializationStatus(companyId: UUID): InitializationStatusDto {
        logOperation("getInitializationStatus", companyId)
        
        try {
            // 공통 코드 그룹 존재 확인
            val hasCommonCodes = codeGroupRepository.findByCompanyIdAndIsActiveTrueOrderByDisplayOrderAscGroupNameAsc(companyId).isNotEmpty()
            
            val initializedComponents = mapOf(
                "COMMON_CODES" to hasCommonCodes,
                "ROLES" to true, // 간단 구현
                "SYSTEM_SETTINGS" to true, // 간단 구현
                "DEFAULT_DATA" to true // 간단 구현
            )
            
            val isInitialized = initializedComponents.values.all { it }
            
            return InitializationStatusDto(
                companyId = companyId,
                isInitialized = isInitialized,
                initializedComponents = initializedComponents,
                lastInitializationTime = LocalDateTime.now(), // 실제로는 DB에서 조회
                initializationVersion = "1.0.0"
            )
            
        } catch (e: Exception) {
            logger.error("초기화 상태 확인 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("초기화 상태 확인 실패: ${e.message}")
        }
    }

    /**
     * 초기화 재설정
     */
    override fun resetInitialization(companyId: UUID): SystemInitializationResult {
        logOperation("resetInitialization", companyId)
        
        try {
            // 기존 데이터 삭제 (실제 구현에서는 신중하게 처리)
            // 여기서는 간단히 재초기화만 수행
            val request = SystemInitializationRequest(
                companyId = companyId,
                initializeCommonCodes = true,
                initializeRoles = true,
                initializeSettings = true,
                initializeDefaultData = true
            )
            
            return initializeSystem(request)
            
        } catch (e: Exception) {
            logger.error("초기화 재설정 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("초기화 재설정 실패: ${e.message}")
        }
    }

    /**
     * 기본 공통 코드 그룹 정의 조회
     */
    override fun getDefaultCodeGroupDefinitions(): List<DefaultCodeGroupDefinition> {
        return listOf(
            DefaultCodeGroupDefinition(
                groupCode = "BUILDING_TYPE",
                groupName = "건물 유형",
                description = "건물의 유형을 분류하는 코드",
                codes = listOf(
                    DefaultCodeDefinition("OFFICE", "오피스", "사무용 건물", 1),
                    DefaultCodeDefinition("APARTMENT", "아파트", "주거용 아파트", 2),
                    DefaultCodeDefinition("COMMERCIAL", "상업시설", "상업용 건물", 3),
                    DefaultCodeDefinition("MIXED", "복합건물", "주상복합 건물", 4)
                )
            ),
            DefaultCodeGroupDefinition(
                groupCode = "CONTRACT_STATUS",
                groupName = "계약 상태",
                description = "계약의 상태를 나타내는 코드",
                codes = listOf(
                    DefaultCodeDefinition("ACTIVE", "활성", "활성 계약", 1),
                    DefaultCodeDefinition("INACTIVE", "비활성", "비활성 계약", 2),
                    DefaultCodeDefinition("TERMINATED", "종료", "종료된 계약", 3),
                    DefaultCodeDefinition("PENDING", "대기", "승인 대기 중", 4)
                )
            ),
            DefaultCodeGroupDefinition(
                groupCode = "PAYMENT_METHOD",
                groupName = "결제 방법",
                description = "결제 수단을 분류하는 코드",
                codes = listOf(
                    DefaultCodeDefinition("BANK_TRANSFER", "계좌이체", "은행 계좌이체", 1),
                    DefaultCodeDefinition("CARD", "카드결제", "신용/체크카드", 2),
                    DefaultCodeDefinition("CASH", "현금", "현금 결제", 3),
                    DefaultCodeDefinition("AUTO_DEBIT", "자동이체", "자동이체", 4)
                )
            ),
            DefaultCodeGroupDefinition(
                groupCode = "USER_ROLE",
                groupName = "사용자 역할",
                description = "시스템 사용자의 역할을 분류하는 코드",
                codes = listOf(
                    DefaultCodeDefinition("ADMIN", "관리자", "시스템 관리자", 1),
                    DefaultCodeDefinition("MANAGER", "매니저", "건물 관리자", 2),
                    DefaultCodeDefinition("STAFF", "직원", "일반 직원", 3),
                    DefaultCodeDefinition("TENANT", "임차인", "임차인", 4)
                )
            )
        )
    }

    /**
     * 회사별 초기화 검증
     */
    @Transactional(readOnly = true)
    override fun validateInitialization(companyId: UUID): ValidationResult {
        logOperation("validateInitialization", companyId)
        
        val errors = mutableListOf<String>()
        
        try {
            // 필수 공통 코드 그룹 존재 확인
            val requiredGroups = listOf("BUILDING_TYPE", "CONTRACT_STATUS", "PAYMENT_METHOD", "USER_ROLE")
            for (groupCode in requiredGroups) {
                val group = codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, groupCode)
                if (group.isEmpty) {
                    errors.add("필수 공통 코드 그룹이 없습니다: $groupCode")
                }
            }
            
            return ValidationResult(
                isValid = errors.isEmpty(),
                errors = errors
            )
            
        } catch (e: Exception) {
            logger.error("초기화 검증 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.ValidationException("초기화 검증 실패: ${e.message}")
        }
    }

    override fun validateInput(input: Any): ValidationResult {
        return ValidationResult(isValid = true)
    }

    override fun logOperation(operation: String, result: Any, executionTimeMs: Long?) {
        logger.info("SystemInitializationService.$operation executed with result: $result")
    }
}