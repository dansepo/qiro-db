package com.qiro.common.service

import com.qiro.domain.migration.common.BaseService
import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.CommonCode
import com.qiro.domain.migration.exception.ProcedureMigrationException
import com.qiro.domain.migration.repository.CommonCodeRepository
import org.slf4j.LoggerFactory
import org.springframework.cache.annotation.Cacheable
import org.springframework.cache.annotation.CacheEvict
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.util.*

/**
 * 데이터 무결성 서비스 구현
 */
@Service
@Transactional
class DataIntegrityServiceImpl(
    private val commonCodeRepository: CommonCodeRepository
) : DataIntegrityService, BaseService {

    private val logger = LoggerFactory.getLogger(DataIntegrityServiceImpl::class.java)

    /**
     * 사업자등록번호 검증
     * 기존 validate_business_registration_number 프로시저 기능 이관
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
     * 기존 validate_building_data 프로시저 기능 이관
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
            
            // 건물 유형 검증
            val buildingTypeCode = getCodeName("BUILDING_TYPE", buildingData.buildingType, buildingData.companyId)
            if (buildingTypeCode == null) {
                errors.add("유효하지 않은 건물 유형입니다: ${buildingData.buildingType}")
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
     * 공통 코드명 조회
     * 기존 get_code_name 프로시저 기능 이관
     */
    @Cacheable("commonCodeNames", key = "#groupCode + '_' + #codeValue + '_' + (#companyId ?: 'null')")
    override fun getCodeName(groupCode: String, codeValue: String, companyId: UUID?): String? {
        logOperation("getCodeName", mapOf("groupCode" to groupCode, "codeValue" to codeValue, "companyId" to companyId))
        
        return try {
            commonCodeRepository.findByGroupCodeAndCodeValue(groupCode, codeValue, companyId)
                .map { it.codeName }
                .orElse(null)
        } catch (e: Exception) {
            logger.error("공통 코드명 조회 중 오류 발생: ${e.message}", e)
            null
        }
    }

    /**
     * 그룹별 공통 코드 목록 조회
     * 기존 get_codes_by_group 프로시저 기능 이관
     */
    @Cacheable("commonCodesByGroup", key = "#groupCode + '_' + (#companyId ?: 'null')")
    override fun getCodesByGroup(groupCode: String, companyId: UUID?): List<CommonCodeDto> {
        logOperation("getCodesByGroup", mapOf("groupCode" to groupCode, "companyId" to companyId))
        
        return try {
            commonCodeRepository.findByGroupCode(groupCode, companyId)
                .map { it.toDto() }
        } catch (e: Exception) {
            logger.error("공통 코드 목록 조회 중 오류 발생: ${e.message}", e)
            emptyList()
        }
    }

    /**
     * 공통 코드 생성
     */
    @CacheEvict(value = ["commonCodeNames", "commonCodesByGroup"], allEntries = true)
    override fun createCommonCode(commonCodeDto: CommonCodeDto): CommonCodeDto {
        logOperation("createCommonCode", commonCodeDto)
        
        try {
            // 중복 체크
            if (commonCodeRepository.existsByGroupCodeAndCodeValueAndCompanyId(
                    commonCodeDto.groupCode, 
                    commonCodeDto.codeValue, 
                    commonCodeDto.companyId
                )) {
                throw ProcedureMigrationException.ValidationException(
                    "이미 존재하는 공통 코드입니다: ${commonCodeDto.groupCode}.${commonCodeDto.codeValue}"
                )
            }
            
            val commonCode = CommonCode(
                groupCode = commonCodeDto.groupCode,
                codeValue = commonCodeDto.codeValue,
                codeName = commonCodeDto.codeName,
                codeDescription = commonCodeDto.codeDescription,
                sortOrder = commonCodeDto.sortOrder,
                isActive = commonCodeDto.isActive,
                companyId = commonCodeDto.companyId
            )
            
            return commonCodeRepository.save(commonCode).toDto()
            
        } catch (e: Exception) {
            logger.error("공통 코드 생성 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("공통 코드 생성 실패: ${e.message}")
        }
    }

    /**
     * 공통 코드 수정
     */
    @CacheEvict(value = ["commonCodeNames", "commonCodesByGroup"], allEntries = true)
    override fun updateCommonCode(id: UUID, commonCodeDto: CommonCodeDto): CommonCodeDto {
        logOperation("updateCommonCode", mapOf("id" to id, "data" to commonCodeDto))
        
        try {
            val existingCode = commonCodeRepository.findById(id)
                .orElseThrow { ProcedureMigrationException.ValidationException("존재하지 않는 공통 코드입니다: $id") }
            
            val updatedCode = existingCode.copy(
                codeName = commonCodeDto.codeName,
                codeDescription = commonCodeDto.codeDescription,
                sortOrder = commonCodeDto.sortOrder,
                isActive = commonCodeDto.isActive
            )
            
            return commonCodeRepository.save(updatedCode).toDto()
            
        } catch (e: Exception) {
            logger.error("공통 코드 수정 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.DataIntegrityException("공통 코드 수정 실패: ${e.message}")
        }
    }

    /**
     * 공통 코드 삭제 (비활성화)
     */
    @CacheEvict(value = ["commonCodeNames", "commonCodesByGroup"], allEntries = true)
    override fun deleteCommonCode(id: UUID): Boolean {
        logOperation("deleteCommonCode", id)
        
        return try {
            val existingCode = commonCodeRepository.findById(id)
                .orElseThrow { ProcedureMigrationException.ValidationException("존재하지 않는 공통 코드입니다: $id") }
            
            val deactivatedCode = existingCode.copy(isActive = false)
            commonCodeRepository.save(deactivatedCode)
            true
            
        } catch (e: Exception) {
            logger.error("공통 코드 삭제 중 오류 발생: ${e.message}", e)
            false
        }
    }

    /**
     * 전체 공통 코드 그룹 조회
     */
    override fun getAllCodeGroups(companyId: UUID?): List<CommonCodeGroupDto> {
        logOperation("getAllCodeGroups", companyId)
        
        return try {
            val groupCodes = commonCodeRepository.findDistinctGroupCodes(companyId)
            groupCodes.map { groupCode ->
                val codes = getCodesByGroup(groupCode, companyId)
                CommonCodeGroupDto(
                    groupCode = groupCode,
                    groupName = getCodeName("CODE_GROUP", groupCode, companyId) ?: groupCode,
                    codes = codes
                )
            }
        } catch (e: Exception) {
            logger.error("공통 코드 그룹 조회 중 오류 발생: ${e.message}", e)
            emptyList()
        }
    }

    /**
     * 데이터 무결성 전체 검증
     */
    override fun validateDataIntegrity(companyId: UUID): ValidationResult {
        logOperation("validateDataIntegrity", companyId)
        
        val errors = mutableListOf<String>()
        
        try {
            // 필수 공통 코드 그룹 존재 확인
            val requiredGroups = listOf("BUILDING_TYPE", "CONTRACT_STATUS", "PAYMENT_METHOD", "USER_ROLE")
            requiredGroups.forEach { groupCode ->
                val codes = getCodesByGroup(groupCode, companyId)
                if (codes.isEmpty()) {
                    errors.add("필수 공통 코드 그룹이 없습니다: $groupCode")
                }
            }
            
            return ValidationResult(
                isValid = errors.isEmpty(),
                errors = errors
            )
            
        } catch (e: Exception) {
            logger.error("데이터 무결성 검증 중 오류 발생: ${e.message}", e)
            throw ProcedureMigrationException.ValidationException("데이터 무결성 검증 실패: ${e.message}")
        }
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
        logger.info("DataIntegrityService.$operation executed with result: $result")
    }
}

/**
 * CommonCode 엔티티를 DTO로 변환하는 확장 함수
 */
private fun CommonCode.toDto(): CommonCodeDto {
    return CommonCodeDto(
        id = this.id,
        groupCode = this.groupCode,
        codeValue = this.codeValue,
        codeName = this.codeName,
        codeDescription = this.codeDescription,
        sortOrder = this.sortOrder,
        isActive = this.isActive,
        companyId = this.companyId,
        createdAt = this.createdAt,
        updatedAt = this.updatedAt
    )
}