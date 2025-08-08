package com.qiro.common.controller

import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.service.DataIntegrityService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.*

/**
 * 데이터 무결성 관리 컨트롤러
 */
@RestController
@RequestMapping("/api/migration/data-integrity")
@Tag(name = "Data Integrity", description = "데이터 무결성 관리 API")
class DataIntegrityController(
    private val dataIntegrityService: DataIntegrityService
) {

    @PostMapping("/validate/business-registration")
    @Operation(summary = "사업자등록번호 검증", description = "사업자등록번호의 형식과 체크섬을 검증합니다.")
    fun validateBusinessRegistrationNumber(
        @RequestBody request: Map<String, String>
    ): ResponseEntity<ServiceResponse<BusinessRegistrationValidationResult>> {
        val businessRegistrationNumber = request["businessRegistrationNumber"] 
            ?: return ResponseEntity.badRequest().body(
                ServiceResponse(
                    success = false,
                    data = null,
                    message = "사업자등록번호가 필요합니다."
                )
            )

        val result = dataIntegrityService.validateBusinessRegistrationNumber(businessRegistrationNumber)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = result.isValid,
                data = result,
                message = if (result.isValid) "검증 성공" else result.errorMessage
            )
        )
    }

    @PostMapping("/validate/building-data")
    @Operation(summary = "건물 데이터 검증", description = "건물 정보의 유효성을 검증합니다.")
    fun validateBuildingData(
        @RequestBody buildingData: BuildingDataDto
    ): ResponseEntity<ServiceResponse<ValidationResult>> {
        val result = dataIntegrityService.validateBuildingData(buildingData)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = result.isValid,
                data = result,
                message = if (result.isValid) "검증 성공" else "검증 실패"
            )
        )
    }

    @GetMapping("/codes/{groupCode}/{codeValue}")
    @Operation(summary = "공통 코드명 조회", description = "그룹 코드와 코드 값으로 코드명을 조회합니다.")
    fun getCodeName(
        @PathVariable groupCode: String,
        @PathVariable codeValue: String,
        @Parameter(description = "회사 ID (선택사항)")
        @RequestParam(required = false) companyId: UUID?
    ): ResponseEntity<ServiceResponse<String>> {
        val codeName = dataIntegrityService.getCodeName(groupCode, codeValue, companyId)
        
        return if (codeName != null) {
            ResponseEntity.ok(
                ServiceResponse(
                    success = true,
                    data = codeName,
                    message = "조회 성공"
                )
            )
        } else {
            ResponseEntity.ok(
                ServiceResponse(
                    success = false,
                    data = null,
                    message = "해당 코드를 찾을 수 없습니다."
                )
            )
        }
    }

    @GetMapping("/codes/{groupCode}")
    @Operation(summary = "그룹별 공통 코드 목록 조회", description = "특정 그룹의 모든 공통 코드를 조회합니다.")
    fun getCodesByGroup(
        @PathVariable groupCode: String,
        @Parameter(description = "회사 ID (선택사항)")
        @RequestParam(required = false) companyId: UUID?
    ): ResponseEntity<ServiceResponse<List<CommonCodeDto>>> {
        val codes = dataIntegrityService.getCodesByGroup(groupCode, companyId)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = true,
                data = codes,
                message = "조회 성공"
            )
        )
    }

    @PostMapping("/codes")
    @Operation(summary = "공통 코드 생성", description = "새로운 공통 코드를 생성합니다.")
    fun createCommonCode(
        @RequestBody commonCodeDto: CommonCodeDto
    ): ResponseEntity<ServiceResponse<CommonCodeDto>> {
        val createdCode = dataIntegrityService.createCommonCode(commonCodeDto)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = true,
                data = createdCode,
                message = "공통 코드가 생성되었습니다."
            )
        )
    }

    @PutMapping("/codes/{id}")
    @Operation(summary = "공통 코드 수정", description = "기존 공통 코드를 수정합니다.")
    fun updateCommonCode(
        @PathVariable id: UUID,
        @RequestBody commonCodeDto: CommonCodeDto
    ): ResponseEntity<ServiceResponse<CommonCodeDto>> {
        val updatedCode = dataIntegrityService.updateCommonCode(id, commonCodeDto)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = true,
                data = updatedCode,
                message = "공통 코드가 수정되었습니다."
            )
        )
    }

    @DeleteMapping("/codes/{id}")
    @Operation(summary = "공통 코드 삭제", description = "공통 코드를 비활성화합니다.")
    fun deleteCommonCode(
        @PathVariable id: UUID
    ): ResponseEntity<ServiceResponse<Boolean>> {
        val result = dataIntegrityService.deleteCommonCode(id)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = result,
                data = result,
                message = if (result) "공통 코드가 삭제되었습니다." else "공통 코드 삭제에 실패했습니다."
            )
        )
    }

    @GetMapping("/codes")
    @Operation(summary = "전체 공통 코드 그룹 조회", description = "모든 공통 코드 그룹과 코드를 조회합니다.")
    fun getAllCodeGroups(
        @Parameter(description = "회사 ID (선택사항)")
        @RequestParam(required = false) companyId: UUID?
    ): ResponseEntity<ServiceResponse<List<CommonCodeGroupDto>>> {
        val codeGroups = dataIntegrityService.getAllCodeGroups(companyId)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = true,
                data = codeGroups,
                message = "조회 성공"
            )
        )
    }

    @PostMapping("/validate/integrity/{companyId}")
    @Operation(summary = "데이터 무결성 전체 검증", description = "회사의 전체 데이터 무결성을 검증합니다.")
    fun validateDataIntegrity(
        @PathVariable companyId: UUID
    ): ResponseEntity<ServiceResponse<ValidationResult>> {
        val result = dataIntegrityService.validateDataIntegrity(companyId)
        
        return ResponseEntity.ok(
            ServiceResponse(
                success = result.isValid,
                data = result,
                message = if (result.isValid) "데이터 무결성 검증 성공" else "데이터 무결성 검증 실패"
            )
        )
    }
}