package com.qiro.common.service

import com.qiro.domain.migration.dto.*
import java.util.*

/**
 * 데이터 무결성 서비스 인터페이스
 */
interface DataIntegrityService {
    
    /**
     * 사업자등록번호 검증
     */
    fun validateBusinessRegistrationNumber(businessRegistrationNumber: String): BusinessRegistrationValidationResult
    
    /**
     * 건물 데이터 검증
     */
    fun validateBuildingData(buildingData: BuildingDataDto): ValidationResult
    
    /**
     * 공통 코드명 조회
     */
    fun getCodeName(groupCode: String, codeValue: String, companyId: UUID? = null): String?
    
    /**
     * 그룹별 공통 코드 목록 조회
     */
    fun getCodesByGroup(groupCode: String, companyId: UUID? = null): List<CommonCodeDto>
    
    /**
     * 공통 코드 생성
     */
    fun createCommonCode(commonCodeDto: CommonCodeDto): CommonCodeDto
    
    /**
     * 공통 코드 수정
     */
    fun updateCommonCode(id: UUID, commonCodeDto: CommonCodeDto): CommonCodeDto
    
    /**
     * 공통 코드 삭제 (비활성화)
     */
    fun deleteCommonCode(id: UUID): Boolean
    
    /**
     * 전체 공통 코드 그룹 조회
     */
    fun getAllCodeGroups(companyId: UUID? = null): List<CommonCodeGroupDto>
    
    /**
     * 데이터 무결성 전체 검증
     */
    fun validateDataIntegrity(companyId: UUID): ValidationResult
    
    /**
     * 분개 전표 복식부기 원칙 검증
     */
    fun validateJournalEntryBalance(entryId: UUID): ValidationResult
    
    /**
     * 회계 기간 마감 전 데이터 검증
     */
    fun validateFinancialPeriodClosure(companyId: UUID, fiscalYear: Int, periodNumber: Int): ValidationResult
    
    /**
     * 계정과목 사용 여부 검증
     */
    fun validateAccountUsage(accountId: UUID): ValidationResult
}