package com.qiro.domain.building.controller

import com.qiro.common.dto.ApiResponse
import com.qiro.common.dto.PagedResponse
import com.qiro.domain.building.dto.*
import com.qiro.domain.building.service.BuildingService
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
@RequestMapping("/v1/buildings")
@Tag(name = "Building Management", description = "건물 관리 API")
class BuildingController(
    private val buildingService: BuildingService
) {
    
    @GetMapping
    @Operation(summary = "건물 목록 조회", description = "페이징과 검색을 지원하는 건물 목록을 조회합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun getBuildings(
        @Parameter(description = "페이지 번호 (0부터 시작)")
        @RequestParam(defaultValue = "0") page: Int,
        
        @Parameter(description = "페이지 크기")
        @RequestParam(defaultValue = "20") size: Int,
        
        @Parameter(description = "정렬 기준 (예: buildingName,asc)")
        @RequestParam(defaultValue = "buildingName") sort: String,
        
        @Parameter(description = "검색어 (건물명, 주소)")
        @RequestParam(required = false) search: String?
    ): ResponseEntity<ApiResponse<PagedResponse<BuildingSummaryDto>>> {
        val sortDirection = if (sort.contains(",desc")) Sort.Direction.DESC else Sort.Direction.ASC
        val sortProperty = sort.split(",")[0]
        val pageable = PageRequest.of(page, size, Sort.by(sortDirection, sortProperty))
        
        val buildings = buildingService.getBuildings(pageable, search)
        return ResponseEntity.ok(ApiResponse.success(buildings))
    }
    
    @GetMapping("/{id}")
    @Operation(summary = "건물 상세 조회", description = "특정 건물의 상세 정보를 조회합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun getBuildingById(
        @Parameter(description = "건물 ID")
        @PathVariable id: UUID
    ): ResponseEntity<ApiResponse<BuildingDto>> {
        val building = buildingService.getBuildingById(id)
        return ResponseEntity.ok(ApiResponse.success(building))
    }
    
    @PostMapping
    @Operation(summary = "건물 생성", description = "새로운 건물을 생성합니다")
    @PreAuthorize("hasAuthority('building:write') or hasAuthority('*')")
    fun createBuilding(
        @Valid @RequestBody request: CreateBuildingRequest
    ): ResponseEntity<ApiResponse<BuildingDto>> {
        val building = buildingService.createBuilding(request)
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(building, "건물이 성공적으로 생성되었습니다"))
    }
    
    @PutMapping("/{id}")
    @Operation(summary = "건물 수정", description = "기존 건물 정보를 수정합니다")
    @PreAuthorize("hasAuthority('building:write') or hasAuthority('*')")
    fun updateBuilding(
        @Parameter(description = "건물 ID")
        @PathVariable id: UUID,
        
        @Valid @RequestBody request: UpdateBuildingRequest
    ): ResponseEntity<ApiResponse<BuildingDto>> {
        val building = buildingService.updateBuilding(id, request)
        return ResponseEntity.ok(ApiResponse.success(building, "건물 정보가 성공적으로 수정되었습니다"))
    }
    
    @DeleteMapping("/{id}")
    @Operation(summary = "건물 삭제", description = "건물을 삭제합니다 (소프트 삭제)")
    @PreAuthorize("hasAuthority('building:write') or hasAuthority('*')")
    fun deleteBuilding(
        @Parameter(description = "건물 ID")
        @PathVariable id: UUID
    ): ResponseEntity<ApiResponse<String>> {
        buildingService.deleteBuilding(id)
        return ResponseEntity.ok(ApiResponse.success("건물이 성공적으로 삭제되었습니다"))
    }
    
    @GetMapping("/statistics")
    @Operation(summary = "건물 통계 조회", description = "건물별 통계 정보를 조회합니다")
    @PreAuthorize("hasAuthority('building:read') or hasAuthority('*')")
    fun getBuildingsWithStatistics(
        @Parameter(description = "페이지 번호 (0부터 시작)")
        @RequestParam(defaultValue = "0") page: Int,
        
        @Parameter(description = "페이지 크기")
        @RequestParam(defaultValue = "20") size: Int
    ): ResponseEntity<ApiResponse<PagedResponse<BuildingStatsDto>>> {
        val pageable = PageRequest.of(page, size, Sort.by("buildingName"))
        val statistics = buildingService.getBuildingsWithStatistics(pageable)
        return ResponseEntity.ok(ApiResponse.success(statistics))
    }
}