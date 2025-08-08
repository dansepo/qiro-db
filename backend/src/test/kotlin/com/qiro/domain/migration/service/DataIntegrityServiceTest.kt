package com.qiro.domain.migration.service

import com.qiro.domain.migration.dto.BuildingDataDto
import com.qiro.domain.migration.dto.CommonCodeDto
import com.qiro.domain.migration.entity.CommonCode
import com.qiro.domain.migration.exception.ProcedureMigrationException
import com.qiro.domain.migration.repository.CommonCodeRepository
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.string.shouldContain
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import java.util.*

/**
 * DataIntegrityService 단위 테스트
 */
class DataIntegrityServiceTest : BehaviorSpec({

    val commonCodeRepository = mockk<CommonCodeRepository>()
    val dataIntegrityService = DataIntegrityServiceImpl(commonCodeRepository)

    given("사업자등록번호 검증") {
        `when`("유효한 사업자등록번호를 입력할 때") {
            val validBrn = "123-45-67890"
            
            then("검증이 성공해야 한다") {
                val result = dataIntegrityService.validateBusinessRegistrationNumber(validBrn)
                result.isValid shouldBe true
                result.format shouldBe true
                result.errorMessage shouldBe null
            }
        }

        `when`("잘못된 형식의 사업자등록번호를 입력할 때") {
            val invalidBrn = "123-45-678"
            
            then("형식 검증이 실패해야 한다") {
                val result = dataIntegrityService.validateBusinessRegistrationNumber(invalidBrn)
                result.isValid shouldBe false
                result.format shouldBe false
                result.errorMessage shouldContain "형식이 올바르지 않습니다"
            }
        }

        `when`("체크섬이 잘못된 사업자등록번호를 입력할 때") {
            val invalidChecksumBrn = "1234567899"
            
            then("체크섬 검증이 실패해야 한다") {
                val result = dataIntegrityService.validateBusinessRegistrationNumber(invalidChecksumBrn)
                result.isValid shouldBe false
                result.format shouldBe true
                result.checksum shouldBe false
                result.errorMessage shouldContain "체크섬이 올바르지 않습니다"
            }
        }
    }

    given("건물 데이터 검증") {
        val companyId = UUID.randomUUID()
        
        `when`("유효한 건물 데이터를 입력할 때") {
            val validBuildingData = BuildingDataDto(
                buildingName = "테스트 빌딩",
                buildingType = "OFFICE",
                address = "서울시 강남구 테헤란로 123",
                totalFloors = 10,
                totalUnits = 50,
                companyId = companyId
            )
            
            every { 
                commonCodeRepository.findByGroupCodeAndCodeValue("BUILDING_TYPE", "OFFICE", companyId) 
            } returns Optional.of(
                CommonCode(
                    id = UUID.randomUUID(),
                    groupCode = "BUILDING_TYPE",
                    codeValue = "OFFICE",
                    codeName = "오피스"
                )
            )
            
            then("검증이 성공해야 한다") {
                val result = dataIntegrityService.validateBuildingData(validBuildingData)
                result.isValid shouldBe true
                result.errors.shouldBeEmpty()
            }
        }

        `when`("잘못된 건물 데이터를 입력할 때") {
            val invalidBuildingData = BuildingDataDto(
                buildingName = "",
                buildingType = "INVALID_TYPE",
                address = "",
                totalFloors = 0,
                totalUnits = 0,
                companyId = companyId
            )
            
            every { 
                commonCodeRepository.findByGroupCodeAndCodeValue("BUILDING_TYPE", "INVALID_TYPE", companyId) 
            } returns Optional.empty()
            
            then("검증이 실패해야 한다") {
                val result = dataIntegrityService.validateBuildingData(invalidBuildingData)
                result.isValid shouldBe false
                result.errors shouldHaveSize 5
                result.errors shouldContain "건물명은 필수입니다."
                result.errors shouldContain "유효하지 않은 건물 유형입니다: INVALID_TYPE"
                result.errors shouldContain "주소는 필수입니다."
                result.errors shouldContain "총 층수는 1층 이상이어야 합니다."
                result.errors shouldContain "총 세대수는 1세대 이상이어야 합니다."
            }
        }
    }

    given("공통 코드명 조회") {
        val companyId = UUID.randomUUID()
        
        `when`("존재하는 공통 코드를 조회할 때") {
            val commonCode = CommonCode(
                id = UUID.randomUUID(),
                groupCode = "BUILDING_TYPE",
                codeValue = "OFFICE",
                codeName = "오피스"
            )
            
            every { 
                commonCodeRepository.findByGroupCodeAndCodeValue("BUILDING_TYPE", "OFFICE", companyId) 
            } returns Optional.of(commonCode)
            
            then("코드명이 반환되어야 한다") {
                val result = dataIntegrityService.getCodeName("BUILDING_TYPE", "OFFICE", companyId)
                result shouldBe "오피스"
            }
        }

        `when`("존재하지 않는 공통 코드를 조회할 때") {
            every { 
                commonCodeRepository.findByGroupCodeAndCodeValue("BUILDING_TYPE", "NONEXISTENT", companyId) 
            } returns Optional.empty()
            
            then("null이 반환되어야 한다") {
                val result = dataIntegrityService.getCodeName("BUILDING_TYPE", "NONEXISTENT", companyId)
                result shouldBe null
            }
        }
    }

    given("그룹별 공통 코드 목록 조회") {
        val companyId = UUID.randomUUID()
        
        `when`("존재하는 그룹 코드로 조회할 때") {
            val commonCodes = listOf(
                CommonCode(
                    id = UUID.randomUUID(),
                    groupCode = "BUILDING_TYPE",
                    codeValue = "OFFICE",
                    codeName = "오피스",
                    sortOrder = 1
                ),
                CommonCode(
                    id = UUID.randomUUID(),
                    groupCode = "BUILDING_TYPE",
                    codeValue = "APARTMENT",
                    codeName = "아파트",
                    sortOrder = 2
                )
            )
            
            every { 
                commonCodeRepository.findByGroupCode("BUILDING_TYPE", companyId) 
            } returns commonCodes
            
            then("코드 목록이 반환되어야 한다") {
                val result = dataIntegrityService.getCodesByGroup("BUILDING_TYPE", companyId)
                result shouldHaveSize 2
                result[0].codeName shouldBe "오피스"
                result[1].codeName shouldBe "아파트"
            }
        }
    }

    given("공통 코드 생성") {
        `when`("유효한 공통 코드를 생성할 때") {
            val commonCodeDto = CommonCodeDto(
                groupCode = "TEST_GROUP",
                codeValue = "TEST_CODE",
                codeName = "테스트 코드",
                companyId = UUID.randomUUID()
            )
            
            val savedCommonCode = CommonCode(
                id = UUID.randomUUID(),
                groupCode = commonCodeDto.groupCode,
                codeValue = commonCodeDto.codeValue,
                codeName = commonCodeDto.codeName,
                companyId = commonCodeDto.companyId
            )
            
            every { 
                commonCodeRepository.existsByGroupCodeAndCodeValueAndCompanyId(
                    commonCodeDto.groupCode, 
                    commonCodeDto.codeValue, 
                    commonCodeDto.companyId
                ) 
            } returns false
            
            every { commonCodeRepository.save(any()) } returns savedCommonCode
            
            then("공통 코드가 생성되어야 한다") {
                val result = dataIntegrityService.createCommonCode(commonCodeDto)
                result.id shouldNotBe null
                result.codeName shouldBe "테스트 코드"
                
                verify { commonCodeRepository.save(any()) }
            }
        }

        `when`("중복된 공통 코드를 생성하려고 할 때") {
            val commonCodeDto = CommonCodeDto(
                groupCode = "TEST_GROUP",
                codeValue = "DUPLICATE_CODE",
                codeName = "중복 코드",
                companyId = UUID.randomUUID()
            )
            
            every { 
                commonCodeRepository.existsByGroupCodeAndCodeValueAndCompanyId(
                    commonCodeDto.groupCode, 
                    commonCodeDto.codeValue, 
                    commonCodeDto.companyId
                ) 
            } returns true
            
            then("예외가 발생해야 한다") {
                shouldThrow<ProcedureMigrationException.ValidationException> {
                    dataIntegrityService.createCommonCode(commonCodeDto)
                }
            }
        }
    }

    given("데이터 무결성 전체 검증") {
        val companyId = UUID.randomUUID()
        
        `when`("필수 공통 코드 그룹이 모두 존재할 때") {
            every { commonCodeRepository.findByGroupCode("BUILDING_TYPE", companyId) } returns listOf(mockk())
            every { commonCodeRepository.findByGroupCode("CONTRACT_STATUS", companyId) } returns listOf(mockk())
            every { commonCodeRepository.findByGroupCode("PAYMENT_METHOD", companyId) } returns listOf(mockk())
            every { commonCodeRepository.findByGroupCode("USER_ROLE", companyId) } returns listOf(mockk())
            
            then("검증이 성공해야 한다") {
                val result = dataIntegrityService.validateDataIntegrity(companyId)
                result.isValid shouldBe true
                result.errors.shouldBeEmpty()
            }
        }

        `when`("필수 공통 코드 그룹이 누락되었을 때") {
            every { commonCodeRepository.findByGroupCode("BUILDING_TYPE", companyId) } returns emptyList()
            every { commonCodeRepository.findByGroupCode("CONTRACT_STATUS", companyId) } returns listOf(mockk())
            every { commonCodeRepository.findByGroupCode("PAYMENT_METHOD", companyId) } returns emptyList()
            every { commonCodeRepository.findByGroupCode("USER_ROLE", companyId) } returns listOf(mockk())
            
            then("검증이 실패해야 한다") {
                val result = dataIntegrityService.validateDataIntegrity(companyId)
                result.isValid shouldBe false
                result.errors shouldHaveSize 2
                result.errors shouldContain "필수 공통 코드 그룹이 없습니다: BUILDING_TYPE"
                result.errors shouldContain "필수 공통 코드 그룹이 없습니다: PAYMENT_METHOD"
            }
        }
    }
})