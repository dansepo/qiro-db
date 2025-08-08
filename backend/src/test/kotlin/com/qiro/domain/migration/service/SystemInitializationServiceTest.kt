package com.qiro.domain.migration.service

import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.CodeGroup
import com.qiro.domain.migration.entity.CommonCode
import com.qiro.domain.migration.repository.CodeGroupRepository
import com.qiro.domain.migration.repository.CommonCodeRepository
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldHaveSize
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import java.time.LocalDateTime
import java.util.*

/**
 * SystemInitializationService 단위 테스트
 */
class SystemInitializationServiceTest : BehaviorSpec({

    val codeGroupRepository = mockk<CodeGroupRepository>()
    val commonCodeRepository = mockk<CommonCodeRepository>()
    val auditService = mockk<AuditService>()
    val systemInitializationService = SystemInitializationServiceImpl(
        codeGroupRepository, commonCodeRepository, auditService
    )

    given("전체 시스템 초기화") {
        `when`("모든 컴포넌트를 초기화할 때") {
            val companyId = UUID.randomUUID()
            val request = SystemInitializationRequest(
                companyId = companyId,
                initializeCommonCodes = true,
                initializeRoles = true,
                initializeSettings = true,
                initializeDefaultData = true
            )
            
            // Mock 설정
            every { codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(any(), any()) } returns Optional.empty()
            every { codeGroupRepository.save(any()) } returns mockk<CodeGroup> {
                every { id } returns UUID.randomUUID()
            }
            every { commonCodeRepository.existsByGroupIdAndCodeValueAndCompanyId(any(), any(), any()) } returns false
            every { commonCodeRepository.save(any()) } returns mockk()
            every { auditService.logSystemEvent(any(), any(), any(), any(), any()) } returns mockk()
            
            then("모든 컴포넌트가 초기화되어야 한다") {
                val result = systemInitializationService.initializeSystem(request)
                
                result.success shouldBe true
                result.companyId shouldBe companyId
                result.initializedComponents shouldContain "COMMON_CODES"
                result.initializedComponents shouldContain "ROLES"
                result.initializedComponents shouldContain "SYSTEM_SETTINGS"
                result.initializedComponents shouldContain "DEFAULT_DATA"
                result.errors shouldHaveSize 0
                result.initializationTime shouldNotBe null
                
                verify { auditService.logSystemEvent(any(), any(), any(), any(), any()) }
            }
        }
    }

    given("기본 공통 코드 생성") {
        `when`("기본 공통 코드를 생성할 때") {
            val companyId = UUID.randomUUID()
            val request = CommonCodeInitializationRequest(
                companyId = companyId,
                codeGroups = listOf("BUILDING_TYPE"),
                overwriteExisting = false
            )
            
            val mockCodeGroup = CodeGroup(
                id = UUID.randomUUID(),
                companyId = companyId,
                groupCode = "BUILDING_TYPE",
                groupName = "건물 유형",
                groupDescription = "건물의 유형을 분류하는 코드",
                displayOrder = 0,
                isSystemCode = true,
                isActive = true
            )
            
            every { 
                codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, "BUILDING_TYPE") 
            } returns Optional.empty()
            every { codeGroupRepository.save(any()) } returns mockCodeGroup
            every { commonCodeRepository.existsByGroupIdAndCodeValueAndCompanyId(any(), any(), any()) } returns false
            every { commonCodeRepository.save(any()) } returns mockk()
            
            then("공통 코드가 생성되어야 한다") {
                val result = systemInitializationService.createDefaultCommonCodes(request)
                
                result.success shouldBe true
                result.companyId shouldBe companyId
                result.initializedComponents shouldContain "CODE_GROUP_BUILDING_TYPE"
                result.errors shouldHaveSize 0
                
                verify { codeGroupRepository.save(any()) }
                verify(atLeast = 1) { commonCodeRepository.save(any()) }
            }
        }

        `when`("기존 공통 코드가 있고 덮어쓰기를 하지 않을 때") {
            val companyId = UUID.randomUUID()
            val request = CommonCodeInitializationRequest(
                companyId = companyId,
                codeGroups = listOf("BUILDING_TYPE"),
                overwriteExisting = false
            )
            
            val existingCodeGroup = CodeGroup(
                id = UUID.randomUUID(),
                companyId = companyId,
                groupCode = "BUILDING_TYPE",
                groupName = "건물 유형",
                groupDescription = "건물의 유형을 분류하는 코드",
                displayOrder = 0,
                isSystemCode = true,
                isActive = true
            )
            
            every { 
                codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, "BUILDING_TYPE") 
            } returns Optional.of(existingCodeGroup)
            every { commonCodeRepository.existsByGroupIdAndCodeValueAndCompanyId(any(), any(), any()) } returns true
            
            then("기존 코드를 유지해야 한다") {
                val result = systemInitializationService.createDefaultCommonCodes(request)
                
                result.success shouldBe true
                result.companyId shouldBe companyId
                result.initializedComponents shouldContain "CODE_GROUP_BUILDING_TYPE"
                
                verify(exactly = 0) { codeGroupRepository.save(any()) }
                verify(exactly = 0) { commonCodeRepository.save(any()) }
            }
        }
    }

    given("기본 역할 생성") {
        `when`("기본 역할을 생성할 때") {
            val companyId = UUID.randomUUID()
            val request = RoleInitializationRequest(
                companyId = companyId,
                createDefaultRoles = true,
                createDefaultPermissions = true
            )
            
            then("기본 역할이 생성되어야 한다") {
                val result = systemInitializationService.createDefaultRoles(request)
                
                result.success shouldBe true
                result.companyId shouldBe companyId
                result.initializedComponents shouldContain "DEFAULT_ROLES"
                result.initializedComponents shouldContain "DEFAULT_PERMISSIONS"
                result.errors shouldHaveSize 0
            }
        }
    }

    given("시스템 설정 초기화") {
        `when`("시스템 설정을 초기화할 때") {
            val companyId = UUID.randomUUID()
            val request = SystemSettingsInitializationRequest(
                companyId = companyId,
                settingCategories = emptyList(),
                useDefaultValues = true
            )
            
            then("시스템 설정이 초기화되어야 한다") {
                val result = systemInitializationService.initializeSystemSettings(request)
                
                result.success shouldBe true
                result.companyId shouldBe companyId
                result.initializedComponents shouldContain "SYSTEM_SETTINGS"
                result.errors shouldHaveSize 0
            }
        }
    }

    given("기본 데이터 생성") {
        `when`("기본 데이터를 생성할 때") {
            val companyId = UUID.randomUUID()
            val request = DefaultDataInitializationRequest(
                companyId = companyId,
                dataTypes = emptyList(),
                includeTestData = true
            )
            
            then("기본 데이터가 생성되어야 한다") {
                val result = systemInitializationService.createDefaultData(request)
                
                result.success shouldBe true
                result.companyId shouldBe companyId
                result.initializedComponents shouldContain "DEFAULT_DATA"
                result.initializedComponents shouldContain "TEST_DATA"
                result.errors shouldHaveSize 0
            }
        }
    }

    given("초기화 상태 확인") {
        `when`("회사의 초기화 상태를 확인할 때") {
            val companyId = UUID.randomUUID()
            
            every { 
                codeGroupRepository.findByCompanyIdAndIsActiveTrueOrderByDisplayOrderAscGroupNameAsc(companyId) 
            } returns listOf(mockk())
            
            then("초기화 상태가 반환되어야 한다") {
                val result = systemInitializationService.getInitializationStatus(companyId)
                
                result.companyId shouldBe companyId
                result.isInitialized shouldBe true
                result.initializedComponents["COMMON_CODES"] shouldBe true
                result.initializedComponents["ROLES"] shouldBe true
                result.initializedComponents["SYSTEM_SETTINGS"] shouldBe true
                result.initializedComponents["DEFAULT_DATA"] shouldBe true
                result.initializationVersion shouldBe "1.0.0"
                
                verify { codeGroupRepository.findByCompanyIdAndIsActiveTrueOrderByDisplayOrderAscGroupNameAsc(companyId) }
            }
        }
    }

    given("기본 공통 코드 그룹 정의 조회") {
        `when`("기본 공통 코드 그룹 정의를 조회할 때") {
            then("정의된 그룹들이 반환되어야 한다") {
                val result = systemInitializationService.getDefaultCodeGroupDefinitions()
                
                result shouldHaveSize 4
                result.map { it.groupCode } shouldContain "BUILDING_TYPE"
                result.map { it.groupCode } shouldContain "CONTRACT_STATUS"
                result.map { it.groupCode } shouldContain "PAYMENT_METHOD"
                result.map { it.groupCode } shouldContain "USER_ROLE"
                
                val buildingTypeGroup = result.find { it.groupCode == "BUILDING_TYPE" }
                buildingTypeGroup shouldNotBe null
                buildingTypeGroup!!.codes shouldHaveSize 4
                buildingTypeGroup.codes.map { it.codeValue } shouldContain "OFFICE"
                buildingTypeGroup.codes.map { it.codeValue } shouldContain "APARTMENT"
            }
        }
    }

    given("초기화 검증") {
        `when`("필수 공통 코드 그룹이 모두 존재할 때") {
            val companyId = UUID.randomUUID()
            
            every { 
                codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, any()) 
            } returns Optional.of(mockk())
            
            then("검증이 성공해야 한다") {
                val result = systemInitializationService.validateInitialization(companyId)
                
                result.isValid shouldBe true
                result.errors shouldHaveSize 0
                
                verify(exactly = 4) { 
                    codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, any()) 
                }
            }
        }

        `when`("필수 공통 코드 그룹이 누락되었을 때") {
            val companyId = UUID.randomUUID()
            
            every { 
                codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, "BUILDING_TYPE") 
            } returns Optional.empty()
            every { 
                codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, "CONTRACT_STATUS") 
            } returns Optional.of(mockk())
            every { 
                codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, "PAYMENT_METHOD") 
            } returns Optional.of(mockk())
            every { 
                codeGroupRepository.findByCompanyIdAndGroupCodeAndIsActiveTrue(companyId, "USER_ROLE") 
            } returns Optional.of(mockk())
            
            then("검증이 실패해야 한다") {
                val result = systemInitializationService.validateInitialization(companyId)
                
                result.isValid shouldBe false
                result.errors shouldHaveSize 1
                result.errors shouldContain "필수 공통 코드 그룹이 없습니다: BUILDING_TYPE"
            }
        }
    }
})