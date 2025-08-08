package com.qiro.domain.migration.service

import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.FacilityAsset
import com.qiro.domain.migration.entity.FaultReport
import com.qiro.domain.migration.entity.WorkOrder
import com.qiro.domain.migration.repository.FacilityAssetRepository
import com.qiro.domain.migration.repository.FaultReportRepository
import com.qiro.domain.migration.repository.WorkOrderRepository
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.data.domain.PageRequest
import org.springframework.test.context.ActiveProfiles
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * FacilityService 통합 테스트
 */
@SpringBootTest
@ActiveProfiles("test")
@Transactional
class FacilityServiceIntegrationTest(
    private val facilityService: FacilityService,
    private val facilityAssetRepository: FacilityAssetRepository,
    private val workOrderRepository: WorkOrderRepository,
    private val faultReportRepository: FaultReportRepository
) : BehaviorSpec({

    val testCompanyId = UUID.randomUUID()

    beforeEach {
        // 테스트 데이터 정리
        facilityAssetRepository.deleteAll()
        workOrderRepository.deleteAll()
        faultReportRepository.deleteAll()
    }

    given("시설 자산 관리 통합 테스트") {
        `when`("시설 자산 전체 라이프사이클을 테스트할 때") {
            then("생성, 조회, 수정, 삭제가 모두 정상 동작해야 한다") {
                // 1. 시설 자산 생성
                val createRequest = CreateFacilityAssetRequest(
                    companyId = testCompanyId,
                    assetCode = "INTEGRATION-001",
                    assetName = "통합테스트 자산",
                    assetType = "EQUIPMENT",
                    assetCategory = "HVAC",
                    location = "1층 기계실",
                    manufacturer = "테스트 제조사",
                    modelNumber = "MODEL-001",
                    serialNumber = "SN-001",
                    installationDate = LocalDate.now().minusYears(1),
                    warrantyExpiryDate = LocalDate.now().plusYears(2)
                )

                val createdAsset = facilityService.createFacilityAsset(createRequest)
                createdAsset.assetCode shouldBe "INTEGRATION-001"
                createdAsset.assetName shouldBe "통합테스트 자산"
                createdAsset.id shouldNotBe null

                // 2. 시설 자산 조회
                val retrievedAsset = facilityService.getFacilityAsset(testCompanyId, createdAsset.id!!)
                retrievedAsset shouldNotBe null
                retrievedAsset!!.assetCode shouldBe "INTEGRATION-001"
                retrievedAsset.manufacturer shouldBe "테스트 제조사"

                // 3. 시설 자산 수정
                val updateRequest = createRequest.copy(
                    assetName = "수정된 통합테스트 자산",
                    location = "2층 기계실"
                )

                val updatedAsset = facilityService.updateFacilityAsset(createdAsset.id!!, updateRequest)
                updatedAsset.assetName shouldBe "수정된 통합테스트 자산"
                updatedAsset.location shouldBe "2층 기계실"

                // 4. 시설 자산 삭제 (비활성화)
                val deleteResult = facilityService.deleteFacilityAsset(testCompanyId, createdAsset.id!!)
                deleteResult shouldBe true

                // 5. 삭제된 자산 조회 시 null 반환 확인
                val deletedAsset = facilityService.getFacilityAsset(testCompanyId, createdAsset.id!!)
                deletedAsset shouldBe null
            }
        }

        `when`("보증 만료 예정 자산을 조회할 때") {
            then("지정된 기간 내 만료 예정 자산만 반환해야 한다") {
                // 테스트 자산들 생성
                val asset1 = facilityService.createFacilityAsset(
                    CreateFacilityAssetRequest(
                        companyId = testCompanyId,
                        assetCode = "WARRANTY-001",
                        assetName = "보증 만료 임박 자산",
                        assetType = "EQUIPMENT",
                        warrantyExpiryDate = LocalDate.now().plusDays(30) // 30일 후 만료
                    )
                )

                val asset2 = facilityService.createFacilityAsset(
                    CreateFacilityAssetRequest(
                        companyId = testCompanyId,
                        assetCode = "WARRANTY-002",
                        assetName = "보증 여유 자산",
                        assetType = "EQUIPMENT",
                        warrantyExpiryDate = LocalDate.now().plusYears(1) // 1년 후 만료
                    )
                )

                // 60일 이내 만료 예정 자산 조회
                val startDate = LocalDate.now()
                val endDate = LocalDate.now().plusDays(60)
                val pageable = PageRequest.of(0, 10)

                val expiringAssets = facilityService.getAssetsWithExpiringWarranty(
                    testCompanyId, startDate, endDate, pageable
                )

                // 30일 후 만료되는 자산만 조회되어야 함
                expiringAssets.content.size shouldBe 1
                expiringAssets.content[0].assetCode shouldBe "WARRANTY-001"
            }
        }
    }

    given("작업 지시서 관리 통합 테스트") {
        `when`("작업 지시서 전체 워크플로우를 테스트할 때") {
            then("생성부터 완료까지 정상 처리되어야 한다") {
                // 1. 작업 지시서 생성
                val createRequest = CreateWorkOrderRequest(
                    companyId = testCompanyId,
                    title = "통합테스트 작업",
                    description = "통합테스트용 작업 지시서",
                    workType = "MAINTENANCE",
                    priority = "HIGH",
                    estimatedHours = 4.0,
                    scheduledStartTime = LocalDateTime.now().plusHours(1),
                    scheduledEndTime = LocalDateTime.now().plusHours(5)
                )

                val createdWorkOrder = facilityService.createWorkOrder(createRequest)
                createdWorkOrder.title shouldBe "통합테스트 작업"
                createdWorkOrder.workStatus shouldBe "PENDING"
                createdWorkOrder.workOrderNumber shouldNotBe null

                // 2. 작업 지시서 할당
                val assigneeId = UUID.randomUUID()
                val assignedWorkOrder = facilityService.assignWorkOrder(
                    testCompanyId, createdWorkOrder.id!!, assigneeId
                )
                assignedWorkOrder.assignedTo shouldBe assigneeId

                // 3. 작업 상태를 진행 중으로 변경
                val statusUpdateRequest = UpdateWorkOrderStatusRequest(
                    workStatus = "IN_PROGRESS",
                    actualStartTime = LocalDateTime.now()
                )
                val inProgressWorkOrder = facilityService.updateWorkOrderStatus(
                    createdWorkOrder.id!!, statusUpdateRequest
                )
                inProgressWorkOrder.workStatus shouldBe "IN_PROGRESS"
                inProgressWorkOrder.actualStartTime shouldNotBe null

                // 4. 작업 완료
                val completedWorkOrder = facilityService.completeWorkOrder(
                    testCompanyId, createdWorkOrder.id!!, "작업 완료", 3.5
                )
                completedWorkOrder.workStatus shouldBe "COMPLETED"
                completedWorkOrder.completionNotes shouldBe "작업 완료"
                completedWorkOrder.actualHours shouldBe 3.5
                completedWorkOrder.actualEndTime shouldNotBe null
            }
        }

        `when`("지연된 작업 지시서를 조회할 때") {
            then("예정 시간을 초과한 작업만 반환해야 한다") {
                // 지연된 작업 지시서 생성
                val overdueWorkOrder = facilityService.createWorkOrder(
                    CreateWorkOrderRequest(
                        companyId = testCompanyId,
                        title = "지연된 작업",
                        workType = "REPAIR",
                        scheduledEndTime = LocalDateTime.now().minusHours(2) // 2시간 전에 완료 예정이었음
                    )
                )

                // 정상 작업 지시서 생성
                val normalWorkOrder = facilityService.createWorkOrder(
                    CreateWorkOrderRequest(
                        companyId = testCompanyId,
                        title = "정상 작업",
                        workType = "MAINTENANCE",
                        scheduledEndTime = LocalDateTime.now().plusHours(2) // 2시간 후 완료 예정
                    )
                )

                val pageable = PageRequest.of(0, 10)
                val overdueWorkOrders = facilityService.getOverdueWorkOrders(testCompanyId, pageable)

                // 지연된 작업만 조회되어야 함
                overdueWorkOrders.content.size shouldBe 1
                overdueWorkOrders.content[0].title shouldBe "지연된 작업"
            }
        }
    }

    given("고장 신고 관리 통합 테스트") {
        `when`("고장 신고 전체 프로세스를 테스트할 때") {
            then("신고부터 해결까지 정상 처리되어야 한다") {
                // 1. 고장 신고 생성
                val createRequest = CreateFaultReportRequest(
                    companyId = testCompanyId,
                    title = "통합테스트 고장 신고",
                    description = "에어컨 고장",
                    faultType = "HVAC",
                    faultSeverity = "HIGH",
                    location = "3층 사무실",
                    reporterName = "홍길동",
                    reporterContact = "010-1234-5678"
                )

                val createdFaultReport = facilityService.createFaultReport(createRequest)
                createdFaultReport.title shouldBe "통합테스트 고장 신고"
                createdFaultReport.reportStatus shouldBe "REPORTED"
                createdFaultReport.reportNumber shouldNotBe null

                // 2. 고장 신고 할당
                val technicianId = UUID.randomUUID()
                val assignedFaultReport = facilityService.assignFaultReport(
                    testCompanyId, createdFaultReport.id!!, technicianId
                )
                assignedFaultReport.assignedTechnician shouldBe technicianId
                assignedFaultReport.reportStatus shouldBe "ASSIGNED"
                assignedFaultReport.acknowledgedAt shouldNotBe null

                // 3. 고장 신고 해결
                val resolvedFaultReport = facilityService.resolveFaultReport(
                    testCompanyId, createdFaultReport.id!!, "에어컨 수리 완료"
                )
                resolvedFaultReport.reportStatus shouldBe "RESOLVED"
                resolvedFaultReport.resolutionNotes shouldBe "에어컨 수리 완료"
                resolvedFaultReport.resolvedAt shouldNotBe null
            }
        }

        `when`("긴급 고장 신고를 조회할 때") {
            then("긴급도가 높은 미해결 신고만 반환해야 한다") {
                // 긴급 고장 신고 생성
                val criticalFaultReport = facilityService.createFaultReport(
                    CreateFaultReportRequest(
                        companyId = testCompanyId,
                        title = "긴급 고장",
                        faultType = "ELECTRICAL",
                        faultSeverity = "CRITICAL"
                    )
                )

                // 일반 고장 신고 생성
                val normalFaultReport = facilityService.createFaultReport(
                    CreateFaultReportRequest(
                        companyId = testCompanyId,
                        title = "일반 고장",
                        faultType = "PLUMBING",
                        faultSeverity = "MEDIUM"
                    )
                )

                val pageable = PageRequest.of(0, 10)
                val criticalReports = facilityService.getCriticalFaultReports(testCompanyId, pageable)

                // 긴급 신고만 조회되어야 함
                criticalReports.content.size shouldBe 1
                criticalReports.content[0].title shouldBe "긴급 고장"
                criticalReports.content[0].faultSeverity shouldBe "CRITICAL"
            }
        }
    }

    given("고장 신고에서 작업 지시서 생성 통합 테스트") {
        `when`("고장 신고를 기반으로 작업 지시서를 생성할 때") {
            then("고장 신고 정보가 작업 지시서에 정확히 반영되어야 한다") {
                // 1. 고장 신고 생성
                val faultReport = facilityService.createFaultReport(
                    CreateFaultReportRequest(
                        companyId = testCompanyId,
                        title = "전기 시설 고장",
                        description = "전기 패널 이상",
                        faultType = "ELECTRICAL",
                        faultSeverity = "CRITICAL",
                        location = "지하 1층 전기실"
                    )
                )

                // 2. 고장 신고에서 작업 지시서 생성
                val assigneeId = UUID.randomUUID()
                val workOrder = facilityService.createWorkOrderFromFaultReport(
                    testCompanyId, faultReport.id!!, "REPAIR", assigneeId, 6.0
                )

                // 3. 작업 지시서 검증
                workOrder.title shouldBe "고장 수리: 전기 시설 고장"
                workOrder.description shouldBe "전기 패널 이상"
                workOrder.workType shouldBe "REPAIR"
                workOrder.priority shouldBe "HIGH" // CRITICAL -> HIGH 매핑
                workOrder.assignedTo shouldBe assigneeId
                workOrder.faultReportId shouldBe faultReport.id
                workOrder.estimatedHours shouldBe 6.0
                workOrder.location shouldBe "지하 1층 전기실"

                // 4. 데이터베이스에서 직접 확인
                val savedWorkOrder = workOrderRepository.findById(workOrder.id!!).get()
                savedWorkOrder.faultReportId shouldBe faultReport.id
                savedWorkOrder.workType shouldBe "REPAIR"
            }
        }
    }

    given("통계 및 분석 통합 테스트") {
        `when`("시설 관리 통계를 조회할 때") {
            then("실제 데이터를 기반으로 정확한 통계를 반환해야 한다") {
                // 테스트 데이터 생성
                // 시설 자산 2개 생성
                repeat(2) { index ->
                    facilityService.createFacilityAsset(
                        CreateFacilityAssetRequest(
                            companyId = testCompanyId,
                            assetCode = "STAT-ASSET-${index + 1}",
                            assetName = "통계 테스트 자산 ${index + 1}",
                            assetType = "EQUIPMENT"
                        )
                    )
                }

                // 작업 지시서 3개 생성 (다양한 상태)
                val workOrder1 = facilityService.createWorkOrder(
                    CreateWorkOrderRequest(
                        companyId = testCompanyId,
                        title = "대기 중인 작업",
                        workType = "MAINTENANCE"
                    )
                )

                val workOrder2 = facilityService.createWorkOrder(
                    CreateWorkOrderRequest(
                        companyId = testCompanyId,
                        title = "진행 중인 작업",
                        workType = "REPAIR"
                    )
                )
                facilityService.updateWorkOrderStatus(
                    workOrder2.id!!,
                    UpdateWorkOrderStatusRequest(workStatus = "IN_PROGRESS")
                )

                val workOrder3 = facilityService.createWorkOrder(
                    CreateWorkOrderRequest(
                        companyId = testCompanyId,
                        title = "완료된 작업",
                        workType = "INSPECTION"
                    )
                )
                facilityService.completeWorkOrder(testCompanyId, workOrder3.id!!, "완료", 2.0)

                // 고장 신고 2개 생성 (1개는 해결, 1개는 미해결)
                val faultReport1 = facilityService.createFaultReport(
                    CreateFaultReportRequest(
                        companyId = testCompanyId,
                        title = "해결된 고장",
                        faultType = "ELECTRICAL"
                    )
                )
                facilityService.resolveFaultReport(testCompanyId, faultReport1.id!!, "해결 완료")

                val faultReport2 = facilityService.createFaultReport(
                    CreateFaultReportRequest(
                        companyId = testCompanyId,
                        title = "미해결 고장",
                        faultType = "PLUMBING"
                    )
                )

                // 통계 조회
                val statistics = facilityService.getFacilityManagementStatistics(testCompanyId)

                // 통계 검증
                statistics.totalAssets shouldBe 2L
                statistics.totalWorkOrders shouldBe 3L
                statistics.pendingWorkOrders shouldBe 1L
                statistics.inProgressWorkOrders shouldBe 1L
                statistics.completedWorkOrders shouldBe 1L
                statistics.totalFaultReports shouldBe 2L
                statistics.openFaultReports shouldBe 1L // 미해결 고장
                statistics.resolvedFaultReports shouldBe 1L // 해결된 고장
            }
        }
    }

    given("필터링 및 검색 통합 테스트") {
        `when`("다양한 조건으로 필터링할 때") {
            then("조건에 맞는 결과만 반환해야 한다") {
                // 테스트 데이터 생성
                val buildingId1 = UUID.randomUUID()
                val buildingId2 = UUID.randomUUID()

                // 건물별로 자산 생성
                facilityService.createFacilityAsset(
                    CreateFacilityAssetRequest(
                        companyId = testCompanyId,
                        buildingId = buildingId1,
                        assetCode = "FILTER-001",
                        assetName = "건물1 자산",
                        assetType = "HVAC"
                    )
                )

                facilityService.createFacilityAsset(
                    CreateFacilityAssetRequest(
                        companyId = testCompanyId,
                        buildingId = buildingId2,
                        assetCode = "FILTER-002",
                        assetName = "건물2 자산",
                        assetType = "ELECTRICAL"
                    )
                )

                // 건물1 자산만 필터링
                val filter = FacilityManagementFilter(
                    companyId = testCompanyId,
                    buildingId = buildingId1,
                    assetType = "HVAC"
                )

                val pageable = PageRequest.of(0, 10)
                val filteredAssets = facilityService.getFacilityAssetsWithFilter(filter, pageable)

                // 건물1의 HVAC 자산만 조회되어야 함
                filteredAssets.content.size shouldBe 1
                filteredAssets.content[0].assetCode shouldBe "FILTER-001"
                filteredAssets.content[0].buildingId shouldBe buildingId1
                filteredAssets.content[0].assetType shouldBe "HVAC"
            }
        }
    }
})