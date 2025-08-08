package com.qiro.domain.migration.service

import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.FacilityAsset
import com.qiro.domain.migration.entity.FaultReport
import com.qiro.domain.migration.entity.WorkOrder
import com.qiro.domain.migration.exception.ProcedureMigrationException
import com.qiro.domain.migration.repository.FacilityAssetRepository
import com.qiro.domain.migration.repository.FaultReportRepository
import com.qiro.domain.migration.repository.WorkOrderRepository
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.BehaviorSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.mockk.*
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * FacilityService 단위 테스트
 */
class FacilityServiceTest : BehaviorSpec({

    val facilityAssetRepository = mockk<FacilityAssetRepository>()
    val workOrderRepository = mockk<WorkOrderRepository>()
    val faultReportRepository = mockk<FaultReportRepository>()
    
    val facilityService = FacilityServiceImpl(
        facilityAssetRepository,
        workOrderRepository,
        faultReportRepository
    )

    val testCompanyId = UUID.randomUUID()
    val testAssetId = UUID.randomUUID()
    val testWorkOrderId = UUID.randomUUID()
    val testFaultReportId = UUID.randomUUID()

    beforeEach {
        clearAllMocks()
    }

    given("시설 자산 관리") {
        `when`("새로운 시설 자산을 생성할 때") {
            then("유효한 입력으로 자산이 성공적으로 생성되어야 한다") {
                // Given
                val request = CreateFacilityAssetRequest(
                    companyId = testCompanyId,
                    assetCode = "TEST-001",
                    assetName = "테스트 자산",
                    assetType = "EQUIPMENT"
                )
                
                val savedAsset = FacilityAsset(
                    id = testAssetId,
                    companyId = testCompanyId,
                    assetCode = "TEST-001",
                    assetName = "테스트 자산",
                    assetType = "EQUIPMENT",
                    assetStatus = "ACTIVE",
                    isActive = true
                )

                every { facilityAssetRepository.existsByCompanyIdAndAssetCodeAndIsActiveTrue(testCompanyId, "TEST-001") } returns false
                every { facilityAssetRepository.save(any<FacilityAsset>()) } returns savedAsset

                // When
                val result = facilityService.createFacilityAsset(request)

                // Then
                result.assetCode shouldBe "TEST-001"
                result.assetName shouldBe "테스트 자산"
                result.assetType shouldBe "EQUIPMENT"
                result.companyId shouldBe testCompanyId
                
                verify { facilityAssetRepository.save(any<FacilityAsset>()) }
            }

            then("중복된 자산 코드로 생성 시 예외가 발생해야 한다") {
                // Given
                val request = CreateFacilityAssetRequest(
                    companyId = testCompanyId,
                    assetCode = "DUPLICATE-001",
                    assetName = "중복 자산",
                    assetType = "EQUIPMENT"
                )

                every { facilityAssetRepository.existsByCompanyIdAndAssetCodeAndIsActiveTrue(testCompanyId, "DUPLICATE-001") } returns true

                // When & Then
                shouldThrow<ProcedureMigrationException.DataIntegrityException> {
                    facilityService.createFacilityAsset(request)
                }
            }

            then("필수 필드가 누락된 경우 예외가 발생해야 한다") {
                // Given
                val request = CreateFacilityAssetRequest(
                    companyId = testCompanyId,
                    assetCode = "", // 빈 값
                    assetName = "테스트 자산",
                    assetType = "EQUIPMENT"
                )

                // When & Then
                shouldThrow<ProcedureMigrationException.ValidationException> {
                    facilityService.createFacilityAsset(request)
                }
            }
        }

        `when`("시설 자산을 조회할 때") {
            then("존재하는 자산을 성공적으로 조회해야 한다") {
                // Given
                val asset = FacilityAsset(
                    id = testAssetId,
                    companyId = testCompanyId,
                    assetCode = "TEST-001",
                    assetName = "테스트 자산",
                    assetType = "EQUIPMENT",
                    isActive = true
                )

                every { facilityAssetRepository.findById(testAssetId) } returns Optional.of(asset)

                // When
                val result = facilityService.getFacilityAsset(testCompanyId, testAssetId)

                // Then
                result shouldNotBe null
                result?.id shouldBe testAssetId
                result?.assetCode shouldBe "TEST-001"
            }

            then("존재하지 않는 자산 조회 시 null을 반환해야 한다") {
                // Given
                every { facilityAssetRepository.findById(testAssetId) } returns Optional.empty()

                // When
                val result = facilityService.getFacilityAsset(testCompanyId, testAssetId)

                // Then
                result shouldBe null
            }
        }
    }

    given("작업 지시서 관리") {
        `when`("새로운 작업 지시서를 생성할 때") {
            then("유효한 입력으로 작업 지시서가 성공적으로 생성되어야 한다") {
                // Given
                val request = CreateWorkOrderRequest(
                    companyId = testCompanyId,
                    title = "테스트 작업",
                    workType = "MAINTENANCE",
                    priority = "HIGH"
                )

                val savedWorkOrder = WorkOrder(
                    id = testWorkOrderId,
                    companyId = testCompanyId,
                    workOrderNumber = "WO-TEST-001",
                    title = "테스트 작업",
                    workType = "MAINTENANCE",
                    priority = "HIGH",
                    workStatus = "PENDING",
                    isActive = true
                )

                every { workOrderRepository.save(any<WorkOrder>()) } returns savedWorkOrder

                // When
                val result = facilityService.createWorkOrder(request)

                // Then
                result.title shouldBe "테스트 작업"
                result.workType shouldBe "MAINTENANCE"
                result.priority shouldBe "HIGH"
                result.workStatus shouldBe "PENDING"
                
                verify { workOrderRepository.save(any<WorkOrder>()) }
            }

            then("필수 필드가 누락된 경우 예외가 발생해야 한다") {
                // Given
                val request = CreateWorkOrderRequest(
                    companyId = testCompanyId,
                    title = "", // 빈 값
                    workType = "MAINTENANCE"
                )

                // When & Then
                shouldThrow<ProcedureMigrationException.ValidationException> {
                    facilityService.createWorkOrder(request)
                }
            }
        }

        `when`("작업 지시서 상태를 업데이트할 때") {
            then("유효한 상태로 업데이트가 성공해야 한다") {
                // Given
                val workOrder = WorkOrder(
                    id = testWorkOrderId,
                    companyId = testCompanyId,
                    workOrderNumber = "WO-TEST-001",
                    title = "테스트 작업",
                    workType = "MAINTENANCE",
                    workStatus = "PENDING",
                    isActive = true
                )

                val request = UpdateWorkOrderStatusRequest(
                    workStatus = "IN_PROGRESS",
                    actualStartTime = LocalDateTime.now()
                )

                val updatedWorkOrder = workOrder.copy(
                    workStatus = "IN_PROGRESS",
                    actualStartTime = request.actualStartTime
                )

                every { workOrderRepository.findById(testWorkOrderId) } returns Optional.of(workOrder)
                every { workOrderRepository.save(any<WorkOrder>()) } returns updatedWorkOrder

                // When
                val result = facilityService.updateWorkOrderStatus(testWorkOrderId, request)

                // Then
                result.workStatus shouldBe "IN_PROGRESS"
                result.actualStartTime shouldBe request.actualStartTime
                
                verify { workOrderRepository.save(any<WorkOrder>()) }
            }
        }

        `when`("작업 지시서를 완료할 때") {
            then("완료 처리가 성공해야 한다") {
                // Given
                val workOrder = WorkOrder(
                    id = testWorkOrderId,
                    companyId = testCompanyId,
                    workOrderNumber = "WO-TEST-001",
                    title = "테스트 작업",
                    workType = "MAINTENANCE",
                    workStatus = "IN_PROGRESS",
                    isActive = true
                )

                val completionNotes = "작업 완료"
                val actualHours = 2.5

                every { workOrderRepository.findById(testWorkOrderId) } returns Optional.of(workOrder)
                every { workOrderRepository.save(any<WorkOrder>()) } returns workOrder.copy(
                    workStatus = "COMPLETED",
                    completionNotes = completionNotes,
                    actualHours = actualHours
                )

                // When
                val result = facilityService.completeWorkOrder(testCompanyId, testWorkOrderId, completionNotes, actualHours)

                // Then
                result.workStatus shouldBe "COMPLETED"
                result.completionNotes shouldBe completionNotes
                result.actualHours shouldBe actualHours
                
                verify { workOrderRepository.save(any<WorkOrder>()) }
            }
        }
    }

    given("고장 신고 관리") {
        `when`("새로운 고장 신고를 생성할 때") {
            then("유효한 입력으로 고장 신고가 성공적으로 생성되어야 한다") {
                // Given
                val request = CreateFaultReportRequest(
                    companyId = testCompanyId,
                    title = "테스트 고장 신고",
                    faultType = "ELECTRICAL",
                    faultSeverity = "HIGH"
                )

                val savedFaultReport = FaultReport(
                    id = testFaultReportId,
                    companyId = testCompanyId,
                    reportNumber = "FR-TEST-001",
                    title = "테스트 고장 신고",
                    faultType = "ELECTRICAL",
                    faultSeverity = "HIGH",
                    reportStatus = "REPORTED",
                    reportedAt = LocalDateTime.now(),
                    isActive = true
                )

                every { faultReportRepository.save(any<FaultReport>()) } returns savedFaultReport

                // When
                val result = facilityService.createFaultReport(request)

                // Then
                result.title shouldBe "테스트 고장 신고"
                result.faultType shouldBe "ELECTRICAL"
                result.faultSeverity shouldBe "HIGH"
                result.reportStatus shouldBe "REPORTED"
                
                verify { faultReportRepository.save(any<FaultReport>()) }
            }
        }

        `when`("고장 신고를 할당할 때") {
            then("기술자에게 성공적으로 할당되어야 한다") {
                // Given
                val technicianId = UUID.randomUUID()
                val faultReport = FaultReport(
                    id = testFaultReportId,
                    companyId = testCompanyId,
                    reportNumber = "FR-TEST-001",
                    title = "테스트 고장 신고",
                    faultType = "ELECTRICAL",
                    reportStatus = "REPORTED",
                    reportedAt = LocalDateTime.now(),
                    isActive = true
                )

                val assignedFaultReport = faultReport.copy(
                    assignedTechnician = technicianId,
                    reportStatus = "ASSIGNED"
                )

                every { faultReportRepository.findById(testFaultReportId) } returns Optional.of(faultReport)
                every { faultReportRepository.save(any<FaultReport>()) } returns assignedFaultReport

                // When
                val result = facilityService.assignFaultReport(testCompanyId, testFaultReportId, technicianId)

                // Then
                result.assignedTechnician shouldBe technicianId
                result.reportStatus shouldBe "ASSIGNED"
                result.acknowledgedAt shouldNotBe null
                
                verify { faultReportRepository.save(any<FaultReport>()) }
            }
        }

        `when`("고장 신고를 해결할 때") {
            then("해결 처리가 성공해야 한다") {
                // Given
                val faultReport = FaultReport(
                    id = testFaultReportId,
                    companyId = testCompanyId,
                    reportNumber = "FR-TEST-001",
                    title = "테스트 고장 신고",
                    faultType = "ELECTRICAL",
                    reportStatus = "ASSIGNED",
                    reportedAt = LocalDateTime.now(),
                    isActive = true
                )

                val resolutionNotes = "문제 해결 완료"

                every { faultReportRepository.findById(testFaultReportId) } returns Optional.of(faultReport)
                every { faultReportRepository.save(any<FaultReport>()) } returns faultReport.copy(
                    reportStatus = "RESOLVED",
                    resolutionNotes = resolutionNotes,
                    resolvedAt = LocalDateTime.now()
                )

                // When
                val result = facilityService.resolveFaultReport(testCompanyId, testFaultReportId, resolutionNotes)

                // Then
                result.reportStatus shouldBe "RESOLVED"
                result.resolutionNotes shouldBe resolutionNotes
                result.resolvedAt shouldNotBe null
                
                verify { faultReportRepository.save(any<FaultReport>()) }
            }
        }
    }

    given("통계 및 분석") {
        `when`("시설 관리 통계를 조회할 때") {
            then("정확한 통계 정보를 반환해야 한다") {
                // Given
                every { facilityAssetRepository.countActiveAssetsByCompanyId(testCompanyId) } returns 10L
                every { facilityAssetRepository.countAssetsByStatus(testCompanyId) } returns listOf(
                    arrayOf("ACTIVE", 8L),
                    arrayOf("MAINTENANCE", 2L)
                )
                every { workOrderRepository.countActiveWorkOrdersByCompanyId(testCompanyId) } returns 15L
                every { workOrderRepository.countWorkOrdersByStatus(testCompanyId) } returns listOf(
                    arrayOf("PENDING", 5L),
                    arrayOf("IN_PROGRESS", 3L),
                    arrayOf("COMPLETED", 7L)
                )
                every { faultReportRepository.countActiveFaultReportsByCompanyId(testCompanyId) } returns 8L
                every { faultReportRepository.countFaultReportsByStatus(testCompanyId) } returns listOf(
                    arrayOf("REPORTED", 2L),
                    arrayOf("ASSIGNED", 3L),
                    arrayOf("RESOLVED", 3L)
                )
                every { faultReportRepository.getAverageResolutionTimeInHours(testCompanyId) } returns 24.5

                // When
                val result = facilityService.getFacilityManagementStatistics(testCompanyId)

                // Then
                result.totalAssets shouldBe 10L
                result.totalWorkOrders shouldBe 15L
                result.pendingWorkOrders shouldBe 5L
                result.inProgressWorkOrders shouldBe 3L
                result.completedWorkOrders shouldBe 7L
                result.totalFaultReports shouldBe 8L
                result.openFaultReports shouldBe 5L // REPORTED + ASSIGNED
                result.resolvedFaultReports shouldBe 3L
                result.averageResolutionTime shouldBe 24.5
            }
        }
    }

    given("고장 신고에서 작업 지시서 생성") {
        `when`("유효한 고장 신고에서 작업 지시서를 생성할 때") {
            then("작업 지시서가 성공적으로 생성되어야 한다") {
                // Given
                val faultReport = FaultReport(
                    id = testFaultReportId,
                    companyId = testCompanyId,
                    reportNumber = "FR-TEST-001",
                    title = "전기 고장",
                    description = "전기 시설 고장",
                    faultType = "ELECTRICAL",
                    faultSeverity = "CRITICAL",
                    reportStatus = "REPORTED",
                    reportedAt = LocalDateTime.now(),
                    isActive = true
                )

                val assignedTo = UUID.randomUUID()
                val workType = "REPAIR"
                val estimatedHours = 4.0

                every { faultReportRepository.findById(testFaultReportId) } returns Optional.of(faultReport)
                every { workOrderRepository.save(any<WorkOrder>()) } returns WorkOrder(
                    id = testWorkOrderId,
                    companyId = testCompanyId,
                    workOrderNumber = "WO-TEST-001",
                    title = "고장 수리: 전기 고장",
                    description = "전기 시설 고장",
                    workType = workType,
                    priority = "HIGH", // CRITICAL -> HIGH 매핑
                    workStatus = "PENDING",
                    assignedTo = assignedTo,
                    faultReportId = testFaultReportId,
                    estimatedHours = estimatedHours,
                    isActive = true
                )

                // When
                val result = facilityService.createWorkOrderFromFaultReport(
                    testCompanyId, testFaultReportId, workType, assignedTo, estimatedHours
                )

                // Then
                result.title shouldBe "고장 수리: 전기 고장"
                result.workType shouldBe workType
                result.priority shouldBe "HIGH"
                result.assignedTo shouldBe assignedTo
                result.faultReportId shouldBe testFaultReportId
                result.estimatedHours shouldBe estimatedHours
                
                verify { workOrderRepository.save(any<WorkOrder>()) }
            }
        }
    }

    given("페이징 조회") {
        `when`("시설 자산 목록을 페이징으로 조회할 때") {
            then("페이징된 결과를 반환해야 한다") {
                // Given
                val pageable = PageRequest.of(0, 10)
                val assets = listOf(
                    FacilityAsset(
                        id = UUID.randomUUID(),
                        companyId = testCompanyId,
                        assetCode = "TEST-001",
                        assetName = "테스트 자산 1",
                        assetType = "EQUIPMENT",
                        isActive = true
                    ),
                    FacilityAsset(
                        id = UUID.randomUUID(),
                        companyId = testCompanyId,
                        assetCode = "TEST-002",
                        assetName = "테스트 자산 2",
                        assetType = "EQUIPMENT",
                        isActive = true
                    )
                )
                val page = PageImpl(assets, pageable, assets.size.toLong())

                every { facilityAssetRepository.findByCompanyIdAndIsActiveTrueOrderByAssetNameAsc(testCompanyId, pageable) } returns page

                // When
                val result = facilityService.getFacilityAssets(testCompanyId, pageable)

                // Then
                result.content.size shouldBe 2
                result.totalElements shouldBe 2L
                result.content[0].assetCode shouldBe "TEST-001"
                result.content[1].assetCode shouldBe "TEST-002"
            }
        }
    }
})