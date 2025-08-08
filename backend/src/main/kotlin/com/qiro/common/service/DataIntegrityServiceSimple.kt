package com.qiro.common.service

import com.qiro.domain.migration.common.BaseService
import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.exception.ProcedureMigrationException
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

/**
 * 데이터 무결성 서비스 간단 구현 (테스트용)
 */
@Service
@Transactional
class DataIntegrityServiceSimple : DataIntegrityService, BaseService {

    private val logger = LoggerFactory.getLogger(DataIntegrityServiceSimple::class.java)

    /**
     * 사업자등록번호 검증
     */
    override fun validateBusinessRegistrationNumber(businessRegistrationNumber: String): BusinessRegistrationValidationResult {
        logOperation("validateBusinessRegistrationNumber", businessRegistrationNumber)
        
        try {
            val cleanBrn = businessRegistrationNumber.replace("-", "").trim()
            
            // 형식 검증
            if (!isValidFormat(cleanBrn)) {
                return BusinessRegistrationValidationResult(
                    isValid = false,
                    businessRegistrationNumber = businessRegistrationNumber,
                    errorMessage = "사업자등록번호 형식이 올바르지 않습니다.",
                    format = false
                )
            }
            
            // 체크섬 검증
            val checksumValid = validateChecksum(cleanBrn)
            
            return BusinessRegistrationValidationResult(
                isValid = checksumValid,
                businessRegistrationNumber = businessRegistrationNumber,
                errorMessage = if (checksumValid) null else "사업자등록번호 체크섬이 올바르지 않습니다.",
                format = true,
                checksum = checksumValid
            )
            
        } catch (e: Exception) {
            logger.error("사업자등록번호 검증 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.ValidationException("사업자등록번호 검증 실패: ${e.message}")
        }
    }

    /**
     * 건물 데이터 검증
     */
    override fun validateBuildingData(buildingData: BuildingDataDto): ValidationResult {
        logOperation("validateBuildingData", buildingData)
        
        val errors = mutableListOf<String>()
        
        try {
            // 건물명 검증
            if (buildingData.buildingName.isBlank()) {
                errors.add("건물명은 필수입니다.")
            } else if (buildingData.buildingName.length > 100) {
                errors.add("건물명은 100자를 초과할 수 없습니다.")
            }
            
            // 주소 검증
            if (buildingData.address.isBlank()) {
                errors.add("주소는 필수입니다.")
            } else if (buildingData.address.length > 500) {
                errors.add("주소는 500자를 초과할 수 없습니다.")
            }
            
            // 층수 검증
            if (buildingData.totalFloors <= 0) {
                errors.add("총 층수는 1층 이상이어야 합니다.")
            } else if (buildingData.totalFloors > 200) {
                errors.add("총 층수는 200층을 초과할 수 없습니다.")
            }
            
            // 세대수 검증
            if (buildingData.totalUnits <= 0) {
                errors.add("총 세대수는 1세대 이상이어야 합니다.")
            } else if (buildingData.totalUnits > 10000) {
                errors.add("총 세대수는 10,000세대를 초과할 수 없습니다.")
            }
            
            return ValidationResult(
                isValid = errors.isEmpty(),
                errors = errors
            )
            
        } catch (e: Exception) {
            logger.error("건물 데이터 검증 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.ValidationException("건물 데이터 검증 실패: ${e.message}")
        }
    }

    /**
     * 공통 코드명 조회 (간단 구현)
     */
    override fun getCodeName(groupCode: String, codeValue: String, companyId: UUID?): String? {
        logOperation("getCodeName", mapOf("groupCode" to groupCode, "codeValue" to codeValue, "companyId" to companyId))
        
        // 테스트용 하드코딩된 값들
        return when (groupCode) {
            "BUILDING_TYPE" -> when (codeValue) {
                "OFFICE" -> "오피스"
                "APARTMENT" -> "아파트"
                "COMMERCIAL" -> "상업시설"
                else -> null
            }
            "CONTRACT_STATUS" -> when (codeValue) {
                "ACTIVE" -> "활성"
                "INACTIVE" -> "비활성"
                "TERMINATED" -> "종료"
                else -> null
            }
            else -> null
        }
    }

    /**
     * 그룹별 공통 코드 목록 조회 (간단 구현)
     */
    override fun getCodesByGroup(groupCode: String, companyId: UUID?): List<CommonCodeDto> {
        logOperation("getCodesByGroup", mapOf("groupCode" to groupCode, "companyId" to companyId))
        
        val testCompanyId = companyId ?: UUID.randomUUID()
        val testGroupId = UUID.randomUUID()
        
        return when (groupCode) {
            "BUILDING_TYPE" -> listOf(
                CommonCodeDto(
                    id = UUID.randomUUID(),
                    companyId = testCompanyId,
                    groupId = testGroupId,
                    groupCode = groupCode,
                    codeValue = "OFFICE",
                    codeName = "오피스",
                    displayOrder = 1
                ),
                CommonCodeDto(
                    id = UUID.randomUUID(),
                    companyId = testCompanyId,
                    groupId = testGroupId,
                    groupCode = groupCode,
                    codeValue = "APARTMENT",
                    codeName = "아파트",
                    displayOrder = 2
                )
            )
            else -> emptyList()
        }
    }

    /**
     * 공통 코드 생성 (간단 구현)
     */
    override fun createCommonCode(commonCodeDto: CommonCodeDto): CommonCodeDto {
        logOperation("createCommonCode", commonCodeDto)
        
        return commonCodeDto.copy(id = UUID.randomUUID())
    }

    /**
     * 공통 코드 수정 (간단 구현)
     */
    override fun updateCommonCode(id: UUID, commonCodeDto: CommonCodeDto): CommonCodeDto {
        logOperation("updateCommonCode", mapOf("id" to id, "data" to commonCodeDto))
        
        return commonCodeDto.copy(id = id)
    }

    /**
     * 공통 코드 삭제 (간단 구현)
     */
    override fun deleteCommonCode(id: UUID): Boolean {
        logOperation("deleteCommonCode", id)
        
        return true
    }

    /**
     * 전체 공통 코드 그룹 조회 (간단 구현)
     */
    override fun getAllCodeGroups(companyId: UUID?): List<CommonCodeGroupDto> {
        logOperation("getAllCodeGroups", companyId)
        
        return listOf(
            CommonCodeGroupDto(
                groupCode = "BUILDING_TYPE",
                groupName = "건물 유형",
                codes = getCodesByGroup("BUILDING_TYPE", companyId)
            )
        )
    }

    /**
     * 데이터 무결성 전체 검증 (간단 구현)
     */
    override fun validateDataIntegrity(companyId: UUID): ValidationResult {
        logOperation("validateDataIntegrity", companyId)
        
        return ValidationResult(isValid = true)
    }

    /**
     * 사업자등록번호 형식 검증
     */
    private fun isValidFormat(brn: String): Boolean {
        return brn.matches(Regex("^\\d{10}$"))
    }

    /**
     * 사업자등록번호 체크섬 검증
     */
    private fun validateChecksum(brn: String): Boolean {
        if (brn.length != 10) return false
        
        val weights = intArrayOf(1, 3, 7, 1, 3, 7, 1, 3, 5)
        var sum = 0
        
        for (i in 0..8) {
            sum += Character.getNumericValue(brn[i]) * weights[i]
        }
        
        val remainder = sum % 10
        val checkDigit = if (remainder == 0) 0 else 10 - remainder
        
        return checkDigit == Character.getNumericValue(brn[9])
    }

    override fun validateInput(input: Any): ValidationResult {
        return ValidationResult(isValid = true)
    }

    override fun logOperation(operation: String, result: Any) {
        logger.info("DataIntegrityServiceSimple.$operation executed with result: $result")
    }
}