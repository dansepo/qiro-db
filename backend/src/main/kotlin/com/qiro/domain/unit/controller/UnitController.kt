package com.qiro.domain.unit.controller

import com.qiro.common.dto.ApiResponse
import com.qiro.common.dto.PagedResponse
import com.qiro.domain.unit.dto.*
import com.qiro.domain.unit.service.UnitService
import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.Parameter
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Sort
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.security.access.prepost.PreAuthorize
import org.springframework.web.bind.annotation.*
import java.util.*

@RestController
@RequestMapping("/v1/units")
@Tag(name = "Unit Management", description = "세대 관리 API")
class UnitController(
    private val unitService: UnitService
) {
    
    @GetMapping("/buildings/{buildingId}")
    @Operation(summary = "건물별 세대 목록 조회", description = "특정 건물의 세대 목록을 조회합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun getUnitsByBuilding(
        @Parameter(description = "건물 ID")
        @PathVariable buildingId: UUID,
        
        @Parameter(description = "페이지 번호 (0부터 시작)")
        @RequestParam(defaultValue = "0") page: Int,
        
        @Parameter(description = "페이지 크기")
        @RequestParam(defaultValue = "20") size: Int,
        
        @Parameter(description = "정렬 기준 (예: floor,asc)")
        @RequestParam(defaultValue = "floor,unitNumber") sort: String,
        
        @Parameter(description = "검색어 (세대번호, 층수)")
        @RequestParam(required = false) search: String?
    ): ResponseEntity<ApiResponse<PagedResponse<UnitSummaryDto>>> {
        val sortFields = sort.split(",")
        val sortDirection = if (sortFields.size > 1 && sortFields[1] == "desc") {
            Sort.Direction.DESC
        } else {
            Sort.Direction.ASC
        }
        val pageable = PageRequest.of(page, size, Sort.by(sortDirection, sortFields[0]))
        
        val units = unitService.getUnitsByBuilding(buildingId, pageable, search)
        return ResponseEntity.ok(ApiResponse.success(units))
    }
    
    @GetMapping("/{id}")
    @Operation(summary = "세대 상세 조회", description = "특정 세대의 상세 정보를 조회합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun getUnitById(
        @Parameter(description = "세대 ID")
        @PathVariable id: UUID
    ): ResponseEntity<ApiResponse<UnitDto>> {
        val unit = unitService.getUnitById(id)
        return ResponseEntity.ok(ApiResponse.success(unit))
    }
    
    @PostMapping
    @Operation(summary = "세대 생성", description = "새로운 세대를 생성합니다")
    @PreAuthorize("hasAuthority('building:write') or hasAuthority('*')")
    fun createUnit(
        @Valid @RequestBody request: CreateUnitRequest
    ): ResponseEntity<ApiResponse<UnitDto>> {
        val unit = unitService.createUnit(request)
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(unit, "세대가 성공적으로 생성되었습니다"))
    }
    
    @PutMapping("/{id}")
    @Operation(summary = "세대 수정", description = "기존 세대 정보를 수정합니다")
    @PreAuthorize("hasAuthority('building:write') or hasAuthority('*')")
    fun updateUnit(
        @Parameter(description = "세대 ID")
        @PathVariable id: UUID,
        
        @Valid @RequestBody request: UpdateUnitRequest
    ): ResponseEntity<ApiResponse<UnitDto>> {
        val unit = unitService.updateUnit(id, request)
        return ResponseEntity.ok(ApiResponse.success(unit, "세대 정보가 성공적으로 수정되었습니다"))
    }
    
    @PatchMapping("/{id}/status")
    @Operation(summary = "세대 상태 변경", description = "세대의 상태를 변경합니다 (입주, 퇴거, 정비중 등)")
    @PreAuthorize("hasAuthority('building:write') or hasAuthority('*')")
    fun updateUnitStatus(
        @Parameter(description = "세대 ID")
        @PathVariable id: UUID,
        
        @Valid @RequestBody request: UpdateUnitStatusRequest
    ): ResponseEntity<ApiResponse<UnitDto>> {
        val unit = unitService.updateUnitStatus(id, request)
        return ResponseEntity.ok(ApiResponse.success(unit, "세대 상태가 성공적으로 변경되었습니다"))
    }
    
    @DeleteMapping("/{id}")
    @Operation(summary = "세대 삭제", description = "세대를 삭제합니다")
    @PreAuthorize("hasAuthority('building:write') or hasAuthority('*')")
    fun deleteUnit(
        @Parameter(description = "세대 ID")
        @PathVariable id: UUID
    ): ResponseEntity<ApiResponse<String>> {
        unitService.deleteUnit(id)
        return ResponseEntity.ok(ApiResponse.success("세대가 성공적으로 삭제되었습니다"))
    }
    
    @GetMapping("/search/available")
    @Operation(summary = "임대 가능 세대 검색", description = "조건에 맞는 임대 가능한 세대를 검색합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun searchAvailableUnits(
        @ModelAttribute searchRequest: UnitSearchRequest,
        
        @Parameter(description = "페이지 번호 (0부터 시작)")
        @RequestParam(defaultValue = "0") page: Int,
        
        @Parameter(description = "페이지 크기")
        @RequestParam(defaultValue = "20") size: Int,
        
        @Parameter(description = "정렬 기준")
        @RequestParam(defaultValue = "monthlyRent") sort: String
    ): ResponseEntity<ApiResponse<PagedResponse<UnitSummaryDto>>> {
        val sortDirection = if (sort.contains(",desc")) Sort.Direction.DESC else Sort.Direction.ASC
        val sortProperty = sort.split(",")[0]
        val pageable = PageRequest.of(page, size, Sort.by(sortDirection, sortProperty))
        
        val units = unitService.searchAvailableUnits(searchRequest, pageable)
        return ResponseEntity.ok(ApiResponse.success(units))
    }
    
    @GetMapping("/buildings/{buildingId}/statistics/status")
    @Operation(summary = "건물별 세대 상태 통계", description = "특정 건물의 세대 상태별 통계를 조회합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun getUnitStatusStatistics(
        @Parameter(description = "건물 ID")
        @PathVariable buildingId: UUID
    ): ResponseEntity<ApiResponse<List<UnitStatusStatsDto>>> {
        val statistics = unitService.getUnitStatusStatistics(buildingId)
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }
    
    @GetMapping("/buildings/{buildingId}/statistics/type")
    @Operation(summary = "건물별 세대 유형 통계", description = "특정 건물의 세대 유형별 통계를 조회합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun getUnitTypeStatistics(
        @Parameter(description = "건물 ID")
        @PathVariable buildingId: UUID
    ): ResponseEntity<ApiResponse<List<UnitTypeStatsDto>>> {
        val statistics = unitService.getUnitTypeStatistics(buildingId)
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }
}