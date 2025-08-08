package com.qiro.domain.migration.service

import com.qiro.domain.migration.dto.BuildingDataDto
import com.qiro.domain.migration.dto.CommonCodeDto
import com.qiro.domain.migration.entity.CommonCode
import com.qiro.domain.migration.repository.CommonCodeRepository
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.collections.shouldHaveSize
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional
import java.util.*

/**
 * DataIntegrityService 통합 테스트
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class DataIntegrityServiceIntegrationTest(
    private val dataIntegrityService: DataIntegrityService,
    private val commonCodeRepository: CommonCodeRepository,
    private val jdbcTemplate: JdbcTemplate
) : BehaviorSpec({

    given("프로시저와 서비스 결과 비교") {
        `when`("사업자등록번호 검증을 비교할 때") {
            val testBrn = "1234567890"
            
            then("프로시저와 서비스 결과가 동일해야 한다") {
                // 기존 프로시저 실행 (존재하는 경우)
                val procedureExists = try {
                    jdbcTemplate.queryForObject(
                        "SELECT EXISTS(SELECT 1 FROM information_schema.routines WHERE routine_name = 'validate_business_registration_number' AND routine_schema = 'bms')",
                        Boolean::class.java
                    ) ?: false
                } catch (e: Exception) {
                    false
                }
                
                if (procedureExists) {
                    val procedureResult = try {
                        jdbcTemplate.queryForObject(
                            "SELECT bms.validate_business_registration_number(?)",
                            Boolean::class.java,
                            testBrn
                        ) ?: false
                    } catch (e: Exception) {
                        false
                    }
                    
                    // 새로운 서비스 실행
                    val serviceResult = dataIntegrityService.validateBusinessRegistrationNumber(testBrn)
                    
                    // 결과 비교
                    serviceResult.isValid shouldBe procedureResult
                }
            }
        }
    }

    given("공통 코드 CRUD 통합 테스트") {
        `when`("공통 코드를 생성, 조회, 수정, 삭제할 때") {
            val companyId = UUID.randomUUID()
            
            then("전체 CRUD 작업이 정상적으로 동작해야 한다") {
                // 1. 생성
                val createDto = CommonCodeDto(
                    groupCode = "TEST_GROUP",
                    codeValue = "TEST_CODE",
                    codeName = "테스트 코드",
                    codeDescription = "테스트용 코드입니다",
                    sortOrder = 1,
                    companyId = companyId
                )
                
                val created = dataIntegrityService.createCommonCode(createDto)
                created.id shouldNotBe null
                created.codeName shouldBe "테스트 코드"
                
                // 2. 조회
                val codeName = dataIntegrityService.getCodeName("TEST_GROUP", "TEST_CODE", companyId)
                codeName shouldBe "테스트 코드"
                
                val codesByGroup = dataIntegrityService.getCodesByGroup("TEST_GROUP", companyId)
                codesByGroup shouldHaveSize 1
                codesByGroup[0].codeName shouldBe "테스트 코드"
                
                // 3. 수정
                val updateDto = createDto.copy(codeName = "수정된 테스트 코드")
                val updated = dataIntegrityService.updateCommonCode(created.id!!, updateDto)
                updated.codeName shouldBe "수정된 테스트 코드"
                
                // 4. 삭제 (비활성화)
                val deleted = dataIntegrityService.deleteCommonCode(created.id!!)
                deleted shouldBe true
                
                // 삭제 후 조회 시 null 반환 확인
                val deletedCodeName = dataIntegrityService.getCodeName("TEST_GROUP", "TEST_CODE", companyId)
                deletedCodeName shouldBe null
            }
        }
    }

    given("건물 데이터 검증 통합 테스트") {
        `when`("실제 공통 코드와 함께 건물 데이터를 검증할 때") {
            val companyId = UUID.randomUUID()
            
            // 테스트용 건물 유형 코드 생성
            val buildingTypeCode = CommonCode(
                groupCode = "BUILDING_TYPE",
                codeValue = "OFFICE",
                codeName = "오피스",
                companyId = companyId
            )
            commonCodeRepository.save(buildingTypeCode)
            
            then("실제 데이터베이스와 연동하여 검증이 동작해야 한다") {
                val validBuildingData = BuildingDataDto(
                    buildingName = "테스트 오피스 빌딩",
                    buildingType = "OFFICE",
                    address = "서울시 강남구 테헤란로 123",
                    totalFloors = 20,
                    totalUnits = 100,
                    companyId = companyId
                )
                
                val result = dataIntegrityService.validateBuildingData(validBuildingData)
                result.isValid shouldBe true
                
                // 잘못된 건물 유형으로 테스트
                val invalidBuildingData = validBuildingData.copy(buildingType = "INVALID_TYPE")
                val invalidResult = dataIntegrityService.validateBuildingData(invalidBuildingData)
                invalidResult.isValid shouldBe false
            }
        }
    }

    given("데이터 무결성 전체 검증 통합 테스트") {
        `when`("실제 데이터베이스에서 무결성을 검증할 때") {
            val companyId = UUID.randomUUID()
            
            // 필수 공통 코드 그룹 생성
            val requiredCodes = listOf(
                CommonCode(groupCode = "BUILDING_TYPE", codeValue = "OFFICE", codeName = "오피스", companyId = companyId),
                CommonCode(groupCode = "CONTRACT_STATUS", codeValue = "ACTIVE", codeName = "활성", companyId = companyId),
                CommonCode(groupCode = "PAYMENT_METHOD", codeValue = "BANK", codeName = "계좌이체", companyId = companyId),
                CommonCode(groupCode = "USER_ROLE", codeValue = "ADMIN", codeName = "관리자", companyId = companyId)
            )
            
            commonCodeRepository.saveAll(requiredCodes)
            
            then("모든 필수 코드가 존재하면 검증이 성공해야 한다") {
                val result = dataIntegrityService.validateDataIntegrity(companyId)
                result.isValid shouldBe true
            }
        }
    }

    given("캐시 동작 테스트") {
        `when`("동일한 공통 코드를 여러 번 조회할 때") {
            val companyId = UUID.randomUUID()
            
            // 테스트용 공통 코드 생성
            val testCode = CommonCode(
                groupCode = "CACHE_TEST",
                codeValue = "TEST",
                codeName = "캐시 테스트",
                companyId = companyId
            )
            commonCodeRepository.save(testCode)
            
            then("캐시가 적용되어 성능이 향상되어야 한다") {
                // 첫 번째 조회 (캐시 미스)
                val startTime1 = System.currentTimeMillis()
                val result1 = dataIntegrityService.getCodeName("CACHE_TEST", "TEST", companyId)
                val endTime1 = System.currentTimeMillis()
                
                // 두 번째 조회 (캐시 히트)
                val startTime2 = System.currentTimeMillis()
                val result2 = dataIntegrityService.getCodeName("CACHE_TEST", "TEST", companyId)
                val endTime2 = System.currentTimeMillis()
                
                // 결과는 동일해야 함
                result1 shouldBe result2
                result1 shouldBe "캐시 테스트"
                
                // 두 번째 조회가 더 빨라야 함 (캐시 효과)
                val time1 = endTime1 - startTime1
                val time2 = endTime2 - startTime2
                
                // 캐시 효과 확인 (두 번째 조회가 첫 번째보다 빠르거나 같아야 함)
                time2 <= time1 shouldBe true
            }
        }
    }
})