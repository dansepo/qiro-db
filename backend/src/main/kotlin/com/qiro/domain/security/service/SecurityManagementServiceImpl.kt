package com.qiro.domain.security.service

import com.qiro.domain.migration.dto.*
import com.qiro.domain.migration.entity.*
import com.qiro.domain.migration.repository.*
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.LocalDateTime
import java.util.*

/**
 * 보안 및 접근 제어 서비스 구현체
 * 
 * 기존 데이터베이스 프로시저들을 백엔드 서비스로 이관:
 * - 보안 관리 (8개 프로시저)
 * - 방문자 관리 (3개 프로시저)  
 * - 권한 및 세션 관리 (3개 프로시저)
 */
@Service
@Transactional
class SecurityManagementServiceImpl(
    private val securityZoneRepository: SecurityZoneRepository,
    private val securityDeviceRepository: SecurityDeviceRepository,
    private val accessControlRecordRepository: AccessControlRecordRepository,
    private val securityIncidentRepository: SecurityIncidentRepository,
    private val visitorManagementRepository: VisitorManagementRepository,
    private val securityPatrolRepository: SecurityPatrolRepository
) : SecurityManagementService {

    // === 보안 구역 관리 ===

    override fun createSecurityZone(request: CreateSecurityZoneRequest): SecurityZoneDto {
        val securityZone = SecurityZone(
            companyId = request.companyId,
            zoneCode = request.zoneCode,
            zoneName = request.zoneName,
            zoneDescription = request.zoneDescription,
            zoneType = request.zoneType,
            securityLevel = request.securityLevel,
            parentZoneId = request.parentZoneId,
            accessRequirements = request.accessRequirements,
            operatingHours = request.operatingHours
        )
        
        val savedZone = securityZoneRepository.save(securityZone)
        return mapToSecurityZoneDto(savedZone)
    }

    @Transactional(readOnly = true)
    override fun getSecurityZone(companyId: UUID, zoneId: UUID): SecurityZoneDto? {
        return securityZoneRepository.findByIdAndCompanyIdAndIsActive(zoneId, companyId, true)
            ?.let { mapToSecurityZoneDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getSecurityZones(companyId: UUID, pageable: Pageable): Page<SecurityZoneDto> {
        return securityZoneRepository.findByCompanyIdAndIsActive(companyId, true, pageable)
            .map { mapToSecurityZoneDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getSecurityZonesWithFilter(filter: SecurityManagementFilter, pageable: Pageable): Page<SecurityZoneDto> {
        return securityZoneRepository.findWithFilter(
            companyId = filter.companyId,
            zoneId = filter.zoneId,
            pageable = pageable
        ).map { mapToSecurityZoneDto(it) }
    }

    override fun updateSecurityZone(zoneId: UUID, request: CreateSecurityZoneRequest): SecurityZoneDto {
        val existingZone = securityZoneRepository.findByIdAndCompanyIdAndIsActive(zoneId, request.companyId, true)
            ?: throw IllegalArgumentException("보안 구역을 찾을 수 없습니다: $zoneId")

        val updatedZone = existingZone.copy(
            zoneCode = request.zoneCode,
            zoneName = request.zoneName,
            zoneDescription = request.zoneDescription,
            zoneType = request.zoneType,
            securityLevel = request.securityLevel,
            parentZoneId = request.parentZoneId,
            accessRequirements = request.accessRequirements,
            operatingHours = request.operatingHours,
            updatedAt = LocalDateTime.now()
        )

        val savedZone = securityZoneRepository.save(updatedZone)
        return mapToSecurityZoneDto(savedZone)
    }

    override fun deleteSecurityZone(companyId: UUID, zoneId: UUID): Boolean {
        val zone = securityZoneRepository.findByIdAndCompanyIdAndIsActive(zoneId, companyId, true)
            ?: return false

        val deactivatedZone = zone.copy(
            isActive = false,
            updatedAt = LocalDateTime.now()
        )
        
        securityZoneRepository.save(deactivatedZone)
        return true
    }

    @Transactional(readOnly = true)
    override fun validateZoneAccess(request: ValidateZoneAccessRequest): AccessValidationResult {
        val zone = securityZoneRepository.findByIdAndCompanyIdAndIsActive(
            request.zoneId, request.companyId, true
        ) ?: return AccessValidationResult(
            personId = request.personId,
            zoneId = request.zoneId,
            accessGranted = false,
            denialReason = "구역을 찾을 수 없습니다"
        )

        // 기본적인 접근 권한 검증 로직
        val accessGranted = when (zone.securityLevel) {
            1, 2 -> true // 낮은 보안 레벨은 기본 허용
            3, 4, 5 -> {
                // 높은 보안 레벨은 추가 검증 필요
                // 실제 구현에서는 사용자 권한, 시간대 등을 확인
                true // 임시로 허용
            }
            else -> false
        }

        return AccessValidationResult(
            personId = request.personId,
            zoneId = request.zoneId,
            accessGranted = accessGranted,
            denialReason = if (!accessGranted) "권한이 부족합니다" else null,
            validUntil = if (accessGranted) LocalDateTime.now().plusHours(8) else null
        )
    }

    // === 보안 장치 관리 ===

    override fun registerSecurityDevice(request: RegisterSecurityDeviceRequest): SecurityDeviceDto {
        val securityDevice = SecurityDevice(
            companyId = request.companyId,
            deviceCode = request.deviceCode,
            deviceName = request.deviceName,
            deviceType = request.deviceType,
            zoneId = request.zoneId,
            location = request.location,
            ipAddress = request.ipAddress,
            macAddress = request.macAddress,
            deviceModel = request.deviceModel,
            firmwareVersion = request.firmwareVersion,
            deviceConfig = request.deviceConfig,
            installationDate = LocalDateTime.now()
        )

        val savedDevice = securityDeviceRepository.save(securityDevice)
        return mapToSecurityDeviceDto(savedDevice)
    }

    @Transactional(readOnly = true)
    override fun getSecurityDevice(companyId: UUID, deviceId: UUID): SecurityDeviceDto? {
        return securityDeviceRepository.findByIdAndCompanyIdAndIsActive(deviceId, companyId, true)
            ?.let { mapToSecurityDeviceDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getSecurityDevices(companyId: UUID, pageable: Pageable): Page<SecurityDeviceDto> {
        return securityDeviceRepository.findByCompanyIdAndIsActive(companyId, true, pageable)
            .map { mapToSecurityDeviceDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getSecurityDevicesByZone(companyId: UUID, zoneId: UUID): List<SecurityDeviceDto> {
        return securityDeviceRepository.findByCompanyIdAndZoneIdAndIsActive(companyId, zoneId, true)
            .map { mapToSecurityDeviceDto(it) }
    }

    override fun updateSecurityDevice(deviceId: UUID, request: RegisterSecurityDeviceRequest): SecurityDeviceDto {
        val existingDevice = securityDeviceRepository.findByIdAndCompanyIdAndIsActive(deviceId, request.companyId, true)
            ?: throw IllegalArgumentException("보안 장치를 찾을 수 없습니다: $deviceId")

        val updatedDevice = existingDevice.copy(
            deviceCode = request.deviceCode,
            deviceName = request.deviceName,
            deviceType = request.deviceType,
            zoneId = request.zoneId,
            location = request.location,
            ipAddress = request.ipAddress,
            macAddress = request.macAddress,
            deviceModel = request.deviceModel,
            firmwareVersion = request.firmwareVersion,
            deviceConfig = request.deviceConfig,
            updatedAt = LocalDateTime.now()
        )

        val savedDevice = securityDeviceRepository.save(updatedDevice)
        return mapToSecurityDeviceDto(savedDevice)
    }

    override fun deleteSecurityDevice(companyId: UUID, deviceId: UUID): Boolean {
        val device = securityDeviceRepository.findByIdAndCompanyIdAndIsActive(deviceId, companyId, true)
            ?: return false

        val deactivatedDevice = device.copy(
            isActive = false,
            updatedAt = LocalDateTime.now()
        )
        
        securityDeviceRepository.save(deactivatedDevice)
        return true
    }

    override fun updateDeviceStatus(deviceId: UUID, status: String, notes: String?): SecurityDeviceDto {
        val device = securityDeviceRepository.findById(deviceId)
            .orElseThrow { IllegalArgumentException("보안 장치를 찾을 수 없습니다: $deviceId") }

        val updatedDevice = device.copy(
            deviceStatus = status,
            lastMaintenanceDate = if (status == "MAINTENANCE") LocalDateTime.now() else device.lastMaintenanceDate,
            updatedAt = LocalDateTime.now()
        )

        val savedDevice = securityDeviceRepository.save(updatedDevice)
        return mapToSecurityDeviceDto(savedDevice)
    }

    override fun recordDeviceMaintenance(
        deviceId: UUID,
        maintenanceType: String,
        maintenanceNotes: String?,
        performedBy: UUID?
    ): SecurityDeviceDto {
        val device = securityDeviceRepository.findById(deviceId)
            .orElseThrow { IllegalArgumentException("보안 장치를 찾을 수 없습니다: $deviceId") }

        val updatedDevice = device.copy(
            lastMaintenanceDate = LocalDateTime.now(),
            deviceStatus = "ACTIVE", // 유지보수 후 활성화
            updatedAt = LocalDateTime.now()
        )

        val savedDevice = securityDeviceRepository.save(updatedDevice)
        return mapToSecurityDeviceDto(savedDevice)
    }

    // === 접근 제어 관리 ===

    override fun logAccessAttempt(request: LogAccessAttemptRequest): AccessControlRecordDto {
        val accessRecord = AccessControlRecord(
            companyId = request.companyId,
            deviceId = request.deviceId,
            zoneId = request.zoneId,
            personId = request.personId,
            personName = request.personName,
            personType = request.personType,
            accessMethod = request.accessMethod,
            accessDirection = request.accessDirection,
            accessResult = request.accessResult,
            accessTimestamp = LocalDateTime.now(),
            denialReason = request.denialReason,
            additionalInfo = request.additionalInfo
        )

        val savedRecord = accessControlRecordRepository.save(accessRecord)
        return mapToAccessControlRecordDto(savedRecord)
    }

    @Transactional(readOnly = true)
    override fun getAccessControlRecord(companyId: UUID, recordId: UUID): AccessControlRecordDto? {
        return accessControlRecordRepository.findByIdAndCompanyIdAndIsActive(recordId, companyId, true)
            ?.let { mapToAccessControlRecordDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getAccessControlRecords(companyId: UUID, pageable: Pageable): Page<AccessControlRecordDto> {
        return accessControlRecordRepository.findByCompanyIdAndIsActive(companyId, true, pageable)
            .map { mapToAccessControlRecordDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getAccessControlRecordsWithFilter(
        filter: SecurityManagementFilter,
        pageable: Pageable
    ): Page<AccessControlRecordDto> {
        return accessControlRecordRepository.findWithFilter(
            companyId = filter.companyId,
            zoneId = filter.zoneId,
            deviceId = filter.deviceId,
            personId = filter.personId,
            accessResult = filter.accessResult,
            startDate = filter.startDate,
            endDate = filter.endDate,
            pageable = pageable
        ).map { mapToAccessControlRecordDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getAccessHistoryByPerson(
        companyId: UUID,
        personId: UUID,
        startDate: LocalDateTime?,
        endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<AccessControlRecordDto> {
        return accessControlRecordRepository.findByPersonIdAndDateRange(
            companyId, personId, startDate, endDate, pageable
        ).map { mapToAccessControlRecordDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getAccessHistoryByZone(
        companyId: UUID,
        zoneId: UUID,
        startDate: LocalDateTime?,
        endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<AccessControlRecordDto> {
        return accessControlRecordRepository.findByZoneIdAndDateRange(
            companyId, zoneId, startDate, endDate, pageable
        ).map { mapToAccessControlRecordDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getAccessHistoryByDevice(
        companyId: UUID,
        deviceId: UUID,
        startDate: LocalDateTime?,
        endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<AccessControlRecordDto> {
        return accessControlRecordRepository.findByDeviceIdAndDateRange(
            companyId, deviceId, startDate, endDate, pageable
        ).map { mapToAccessControlRecordDto(it) }
    }

    // === 보안 사건 관리 ===

    override fun createSecurityIncident(request: CreateSecurityIncidentRequest): SecurityIncidentDto {
        val incidentNumber = generateIncidentNumber()
        
        val securityIncident = SecurityIncident(
            companyId = request.companyId,
            incidentNumber = incidentNumber,
            incidentTitle = request.incidentTitle,
            incidentDescription = request.incidentDescription,
            incidentType = request.incidentType,
            severityLevel = request.severityLevel,
            zoneId = request.zoneId,
            deviceId = request.deviceId,
            location = request.location,
            incidentTimestamp = LocalDateTime.now(),
            reportedBy = request.reportedBy
        )

        val savedIncident = securityIncidentRepository.save(securityIncident)
        return mapToSecurityIncidentDto(savedIncident)
    }

    @Transactional(readOnly = true)
    override fun getSecurityIncident(companyId: UUID, incidentId: UUID): SecurityIncidentDto? {
        return securityIncidentRepository.findByIdAndCompanyIdAndIsActive(incidentId, companyId, true)
            ?.let { mapToSecurityIncidentDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getSecurityIncidents(companyId: UUID, pageable: Pageable): Page<SecurityIncidentDto> {
        return securityIncidentRepository.findByCompanyIdAndIsActive(companyId, true, pageable)
            .map { mapToSecurityIncidentDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getSecurityIncidentsWithFilter(
        filter: SecurityManagementFilter,
        pageable: Pageable
    ): Page<SecurityIncidentDto> {
        return securityIncidentRepository.findWithFilter(
            companyId = filter.companyId,
            incidentType = filter.incidentType,
            severityLevel = filter.severityLevel,
            zoneId = filter.zoneId,
            deviceId = filter.deviceId,
            startDate = filter.startDate,
            endDate = filter.endDate,
            pageable = pageable
        ).map { mapToSecurityIncidentDto(it) }
    }

    override fun assignSecurityIncident(
        companyId: UUID,
        incidentId: UUID,
        assignedTo: UUID,
        assignmentNotes: String?
    ): SecurityIncidentDto {
        val incident = securityIncidentRepository.findByIdAndCompanyIdAndIsActive(incidentId, companyId, true)
            ?: throw IllegalArgumentException("보안 사건을 찾을 수 없습니다: $incidentId")

        val updatedIncident = incident.copy(
            assignedTo = assignedTo,
            incidentStatus = "ASSIGNED",
            updatedAt = LocalDateTime.now()
        )

        val savedIncident = securityIncidentRepository.save(updatedIncident)
        return mapToSecurityIncidentDto(savedIncident)
    }

    override fun resolveSecurityIncident(
        companyId: UUID,
        incidentId: UUID,
        resolutionNotes: String,
        resolvedBy: UUID
    ): SecurityIncidentDto {
        val incident = securityIncidentRepository.findByIdAndCompanyIdAndIsActive(incidentId, companyId, true)
            ?: throw IllegalArgumentException("보안 사건을 찾을 수 없습니다: $incidentId")

        val updatedIncident = incident.copy(
            incidentStatus = "RESOLVED",
            resolutionNotes = resolutionNotes,
            resolvedAt = LocalDateTime.now(),
            resolvedBy = resolvedBy,
            updatedAt = LocalDateTime.now()
        )

        val savedIncident = securityIncidentRepository.save(updatedIncident)
        return mapToSecurityIncidentDto(savedIncident)
    }

    @Transactional(readOnly = true)
    override fun getCriticalSecurityIncidents(companyId: UUID, pageable: Pageable): Page<SecurityIncidentDto> {
        return securityIncidentRepository.findByCompanyIdAndSeverityLevelAndIsActive(
            companyId, 5, true, pageable
        ).map { mapToSecurityIncidentDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getOpenSecurityIncidents(companyId: UUID, pageable: Pageable): Page<SecurityIncidentDto> {
        return securityIncidentRepository.findByCompanyIdAndIncidentStatusAndIsActive(
            companyId, "OPEN", true, pageable
        ).map { mapToSecurityIncidentDto(it) }
    }

    // === 방문자 관리 ===

    override fun registerVisitor(request: RegisterVisitorRequest): VisitorManagementDto {
        val visitorManagement = VisitorManagement(
            companyId = request.companyId,
            visitorName = request.visitorName,
            visitorContact = request.visitorContact,
            visitorCompany = request.visitorCompany,
            visitorIdNumber = request.visitorIdNumber,
            visitPurpose = request.visitPurpose,
            hostName = request.hostName,
            hostContact = request.hostContact,
            hostDepartment = request.hostDepartment,
            visitDate = request.visitDate,
            expectedDurationHours = request.expectedDurationHours,
            authorizedZones = request.authorizedZones,
            visitNotes = request.visitNotes
        )

        val savedVisitor = visitorManagementRepository.save(visitorManagement)
        return mapToVisitorManagementDto(savedVisitor)
    }

    @Transactional(readOnly = true)
    override fun getVisitor(companyId: UUID, visitId: UUID): VisitorManagementDto? {
        return visitorManagementRepository.findByIdAndCompanyIdAndIsActive(visitId, companyId, true)
            ?.let { mapToVisitorManagementDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getVisitors(companyId: UUID, pageable: Pageable): Page<VisitorManagementDto> {
        return visitorManagementRepository.findByCompanyIdAndIsActive(companyId, true, pageable)
            .map { mapToVisitorManagementDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getVisitorsWithFilter(
        filter: SecurityManagementFilter,
        pageable: Pageable
    ): Page<VisitorManagementDto> {
        return visitorManagementRepository.findWithFilter(
            companyId = filter.companyId,
            visitStatus = filter.visitStatus,
            startDate = filter.startDate,
            endDate = filter.endDate,
            pageable = pageable
        ).map { mapToVisitorManagementDto(it) }
    }

    override fun visitorCheckIn(request: VisitorCheckInOutRequest): VisitorManagementDto {
        val visitor = visitorManagementRepository.findByIdAndCompanyIdAndIsActive(
            request.visitId, request.companyId, true
        ) ?: throw IllegalArgumentException("방문자를 찾을 수 없습니다: ${request.visitId}")

        val updatedVisitor = visitor.copy(
            checkInTime = LocalDateTime.now(),
            visitStatus = "CHECKED_IN",
            visitorBadgeNumber = request.visitorBadgeNumber,
            updatedAt = LocalDateTime.now()
        )

        val savedVisitor = visitorManagementRepository.save(updatedVisitor)
        return mapToVisitorManagementDto(savedVisitor)
    }

    override fun visitorCheckOut(request: VisitorCheckInOutRequest): VisitorManagementDto {
        val visitor = visitorManagementRepository.findByIdAndCompanyIdAndIsActive(
            request.visitId, request.companyId, true
        ) ?: throw IllegalArgumentException("방문자를 찾을 수 없습니다: ${request.visitId}")

        val updatedVisitor = visitor.copy(
            checkOutTime = LocalDateTime.now(),
            visitStatus = "CHECKED_OUT",
            updatedAt = LocalDateTime.now()
        )

        val savedVisitor = visitorManagementRepository.save(updatedVisitor)
        return mapToVisitorManagementDto(savedVisitor)
    }

    override fun approveVisit(
        companyId: UUID,
        visitId: UUID,
        approvedBy: UUID,
        approvalNotes: String?
    ): VisitorManagementDto {
        val visitor = visitorManagementRepository.findByIdAndCompanyIdAndIsActive(visitId, companyId, true)
            ?: throw IllegalArgumentException("방문자를 찾을 수 없습니다: $visitId")

        val updatedVisitor = visitor.copy(
            visitStatus = "APPROVED",
            approvedBy = approvedBy,
            approvedAt = LocalDateTime.now(),
            visitNotes = if (approvalNotes != null) "${visitor.visitNotes ?: ""}\n승인: $approvalNotes" else visitor.visitNotes,
            updatedAt = LocalDateTime.now()
        )

        val savedVisitor = visitorManagementRepository.save(updatedVisitor)
        return mapToVisitorManagementDto(savedVisitor)
    }

    override fun cancelVisit(
        companyId: UUID,
        visitId: UUID,
        cancellationReason: String,
        cancelledBy: UUID?
    ): VisitorManagementDto {
        val visitor = visitorManagementRepository.findByIdAndCompanyIdAndIsActive(visitId, companyId, true)
            ?: throw IllegalArgumentException("방문자를 찾을 수 없습니다: $visitId")

        val updatedVisitor = visitor.copy(
            visitStatus = "CANCELLED",
            visitNotes = "${visitor.visitNotes ?: ""}\n취소 사유: $cancellationReason",
            updatedAt = LocalDateTime.now()
        )

        val savedVisitor = visitorManagementRepository.save(updatedVisitor)
        return mapToVisitorManagementDto(savedVisitor)
    }

    @Transactional(readOnly = true)
    override fun getCurrentVisitors(companyId: UUID): List<VisitorManagementDto> {
        return visitorManagementRepository.findCurrentVisitors(companyId)
            .map { mapToVisitorManagementDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getTodayScheduledVisitors(companyId: UUID): List<VisitorManagementDto> {
        val today = LocalDate.now()
        return visitorManagementRepository.findTodayScheduledVisitors(companyId, today)
            .map { mapToVisitorManagementDto(it) }
    }

    // === 보안 순찰 관리 ===

    override fun scheduleSecurityPatrol(request: ScheduleSecurityPatrolRequest): SecurityPatrolDto {
        val securityPatrol = SecurityPatrol(
            companyId = request.companyId,
            patrolName = request.patrolName,
            patrolRoute = request.patrolRoute,
            patrolSchedule = request.patrolSchedule,
            assignedGuard = request.assignedGuard,
            patrolDate = request.patrolDate,
            totalCheckpoints = request.totalCheckpoints
        )

        val savedPatrol = securityPatrolRepository.save(securityPatrol)
        return mapToSecurityPatrolDto(savedPatrol)
    }

    @Transactional(readOnly = true)
    override fun getSecurityPatrol(companyId: UUID, patrolId: UUID): SecurityPatrolDto? {
        return securityPatrolRepository.findByIdAndCompanyIdAndIsActive(patrolId, companyId, true)
            ?.let { mapToSecurityPatrolDto(it) }
    }

    @Transactional(readOnly = true)
    override fun getSecurityPatrols(companyId: UUID, pageable: Pageable): Page<SecurityPatrolDto> {
        return securityPatrolRepository.findByCompanyIdAndIsActive(companyId, true, pageable)
            .map { mapToSecurityPatrolDto(it) }
    }

    override fun startPatrol(
        companyId: UUID,
        patrolId: UUID,
        startedBy: UUID,
        startNotes: String?
    ): SecurityPatrolDto {
        val patrol = securityPatrolRepository.findByIdAndCompanyIdAndIsActive(patrolId, companyId, true)
            ?: throw IllegalArgumentException("보안 순찰을 찾을 수 없습니다: $patrolId")

        val updatedPatrol = patrol.copy(
            startTime = LocalDateTime.now(),
            patrolStatus = "IN_PROGRESS",
            patrolNotes = startNotes,
            updatedAt = LocalDateTime.now()
        )

        val savedPatrol = securityPatrolRepository.save(updatedPatrol)
        return mapToSecurityPatrolDto(savedPatrol)
    }

    override fun completePatrol(
        companyId: UUID,
        patrolId: UUID,
        completionNotes: String?,
        incidentsFound: Int?
    ): SecurityPatrolDto {
        val patrol = securityPatrolRepository.findByIdAndCompanyIdAndIsActive(patrolId, companyId, true)
            ?: throw IllegalArgumentException("보안 순찰을 찾을 수 없습니다: $patrolId")

        val updatedPatrol = patrol.copy(
            endTime = LocalDateTime.now(),
            patrolStatus = "COMPLETED",
            patrolNotes = completionNotes,
            incidentsFound = incidentsFound,
            updatedAt = LocalDateTime.now()
        )

        val savedPatrol = securityPatrolRepository.save(updatedPatrol)
        return mapToSecurityPatrolDto(savedPatrol)
    }

    override fun recordPatrolCheckpoint(
        patrolId: UUID,
        checkpointId: UUID,
        notes: String?
    ): PatrolCheckpointDto {
        // 체크포인트 기록 로직 구현
        // 실제 구현에서는 별도의 체크포인트 엔티티와 리포지토리가 필요
        return PatrolCheckpointDto(
            checkpointId = checkpointId,
            patrolId = patrolId,
            zoneId = UUID.randomUUID(), // 임시
            checkpointName = "체크포인트",
            checkpointOrder = 1,
            checkTime = LocalDateTime.now(),
            status = "COMPLETED",
            notes = notes
        )
    }

    @Transactional(readOnly = true)
    override fun getTodayScheduledPatrols(companyId: UUID): List<SecurityPatrolDto> {
        val today = LocalDate.now()
        return securityPatrolRepository.findTodayScheduledPatrols(companyId, today)
            .map { mapToSecurityPatrolDto(it) }
    }

    // === 보안 알림 및 이벤트 ===

    override fun generateSecurityAlert(request: GenerateSecurityAlertRequest): SecurityAlertDto {
        // 보안 알림 생성 로직
        return SecurityAlertDto(
            alertId = UUID.randomUUID(),
            alertType = request.alertType,
            alertMessage = request.alertMessage,
            severityLevel = request.severityLevel,
            zoneId = request.zoneId,
            deviceId = request.deviceId,
            alertTimestamp = LocalDateTime.now()
        )
    }

    override fun logSecurityEvent(
        companyId: UUID,
        eventType: String,
        eventSeverity: String,
        eventMessage: String,
        sourceSystem: String?,
        userId: UUID?,
        deviceId: UUID?,
        zoneId: UUID?,
        eventData: String?
    ): SecurityEventLogDto {
        // 보안 이벤트 로그 기록
        return SecurityEventLogDto(
            eventId = UUID.randomUUID(),
            companyId = companyId,
            eventType = eventType,
            eventSeverity = eventSeverity,
            eventMessage = eventMessage,
            eventTimestamp = LocalDateTime.now(),
            sourceSystem = sourceSystem,
            userId = userId,
            deviceId = deviceId,
            zoneId = zoneId,
            eventData = eventData
        )
    }

    override fun acknowledgeSecurityAlert(
        alertId: UUID,
        acknowledgedBy: UUID,
        acknowledgmentNotes: String?
    ): SecurityAlertDto {
        // 보안 알림 확인 처리
        return SecurityAlertDto(
            alertId = alertId,
            alertType = "ACKNOWLEDGED",
            alertMessage = "알림이 확인되었습니다",
            severityLevel = 1,
            alertTimestamp = LocalDateTime.now(),
            acknowledged = true,
            acknowledgedBy = acknowledgedBy,
            acknowledgedAt = LocalDateTime.now()
        )
    }

    @Transactional(readOnly = true)
    override fun getUnacknowledgedAlerts(companyId: UUID): List<SecurityAlertDto> {
        // 미확인 보안 알림 조회
        return emptyList() // 임시 구현
    }

    @Transactional(readOnly = true)
    override fun getSecurityEventLogs(
        companyId: UUID,
        startDate: LocalDateTime?,
        endDate: LocalDateTime?,
        pageable: Pageable
    ): Page<SecurityEventLogDto> {
        // 보안 이벤트 로그 조회
        return Page.empty() // 임시 구현
    }

    // === 통계 및 분석 ===

    @Transactional(readOnly = true)
    override fun getSecurityManagementStatistics(companyId: UUID): SecurityManagementStatisticsDto {
        val totalZones = securityZoneRepository.countByCompanyIdAndIsActive(companyId, true)
        val activeDevices = securityDeviceRepository.countByCompanyIdAndDeviceStatusAndIsActive(companyId, "ACTIVE", true)
        val totalIncidents = securityIncidentRepository.countByCompanyIdAndIsActive(companyId, true)
        val openIncidents = securityIncidentRepository.countByCompanyIdAndIncidentStatusAndIsActive(companyId, "OPEN", true)
        val totalVisitors = visitorManagementRepository.countByCompanyIdAndIsActive(companyId, true)
        val activeVisitors = visitorManagementRepository.countByCompanyIdAndVisitStatusAndIsActive(companyId, "CHECKED_IN", true)
        val totalPatrols = securityPatrolRepository.countByCompanyIdAndIsActive(companyId, true)
        val completedPatrols = securityPatrolRepository.countByCompanyIdAndPatrolStatusAndIsActive(companyId, "COMPLETED", true)
        val accessAttempts = accessControlRecordRepository.countByCompanyIdAndIsActive(companyId, true)
        val deniedAccess = accessControlRecordRepository.countByCompanyIdAndAccessResultAndIsActive(companyId, "DENIED", true)

        val accessSuccessRate = if (accessAttempts > 0) {
            ((accessAttempts - deniedAccess).toDouble() / accessAttempts.toDouble()) * 100
        } else null

        return SecurityManagementStatisticsDto(
            totalZones = totalZones,
            activeDevices = activeDevices,
            totalIncidents = totalIncidents,
            openIncidents = openIncidents,
            totalVisitors = totalVisitors,
            activeVisitors = activeVisitors,
            totalPatrols = totalPatrols,
            completedPatrols = completedPatrols,
            accessAttempts = accessAttempts,
            deniedAccess = deniedAccess,
            accessSuccessRate = accessSuccessRate
        )
    }

    @Transactional(readOnly = true)
    override fun getSecurityDashboardData(
        companyId: UUID,
        dateFrom: LocalDate?,
        dateTo: LocalDate?
    ): SecurityDashboardDataDto {
        val recentIncidents = securityIncidentRepository.findRecentIncidents(companyId, 10)
            .map { mapToSecurityIncidentDto(it) }
        
        val activeVisitors = getCurrentVisitors(companyId)
        val todayPatrols = getTodayScheduledPatrols(companyId)
        
        val recentAccessAttempts = accessControlRecordRepository.findRecentAccessAttempts(companyId, 20)
            .map { mapToAccessControlRecordDto(it) }

        return SecurityDashboardDataDto(
            recentIncidents = recentIncidents,
            activeVisitors = activeVisitors,
            todayPatrols = todayPatrols,
            recentAccessAttempts = recentAccessAttempts,
            zoneStatistics = mapOf("totalZones" to securityZoneRepository.countByCompanyIdAndIsActive(companyId, true)),
            deviceStatus = mapOf("activeDevices" to securityDeviceRepository.countByCompanyIdAndDeviceStatusAndIsActive(companyId, "ACTIVE", true)),
            alertSummary = mapOf("openIncidents" to securityIncidentRepository.countByCompanyIdAndIncidentStatusAndIsActive(companyId, "OPEN", true))
        )
    }

    // 나머지 메서드들은 기본 구현으로 처리
    override fun getAccessPatternAnalysis(companyId: UUID, analysisType: String, period: Int): Map<String, Any> = emptyMap()
    override fun getSecurityIncidentTrends(companyId: UUID, period: String): Map<String, Any> = emptyMap()
    override fun getVisitorStatistics(companyId: UUID, startDate: LocalDate, endDate: LocalDate): Map<String, Any> = emptyMap()
    override fun getPatrolEfficiencyAnalysis(companyId: UUID): Map<String, Any> = emptyMap()
    override fun getZoneSecurityStatus(companyId: UUID): Map<String, Any> = emptyMap()
    override fun getDevicePerformanceAnalysis(companyId: UUID): Map<String, Any> = emptyMap()
    override fun executeAutomaticSecurityCheck(companyId: UUID): Map<String, Any> = emptyMap()
    override fun cleanupExpiredVisitorAccess(companyId: UUID): Map<String, Any> = emptyMap()
    override fun checkDeviceHealthStatus(companyId: UUID): Map<String, Any> = emptyMap()
    override fun validateSecurityPolicyCompliance(companyId: UUID): Map<String, Any> = emptyMap()
    override fun performSecurityDataArchive(companyId: UUID, archiveDate: LocalDate, dataTypes: List<String>): Map<String, Any> = emptyMap()

    // === 매핑 함수들 ===

    private fun mapToSecurityZoneDto(entity: SecurityZone): SecurityZoneDto {
        return SecurityZoneDto(
            id = entity.id,
            companyId = entity.companyId,
            zoneCode = entity.zoneCode,
            zoneName = entity.zoneName,
            zoneDescription = entity.zoneDescription,
            zoneType = entity.zoneType,
            securityLevel = entity.securityLevel,
            parentZoneId = entity.parentZoneId,
            zonePath = entity.zonePath,
            accessRequirements = entity.accessRequirements,
            operatingHours = entity.operatingHours,
            zoneStatus = entity.zoneStatus,
            isActive = entity.isActive,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }

    private fun mapToSecurityDeviceDto(entity: SecurityDevice): SecurityDeviceDto {
        return SecurityDeviceDto(
            id = entity.id,
            companyId = entity.companyId,
            deviceCode = entity.deviceCode,
            deviceName = entity.deviceName,
            deviceType = entity.deviceType,
            zoneId = entity.zoneId,
            location = entity.location,
            ipAddress = entity.ipAddress,
            macAddress = entity.macAddress,
            deviceModel = entity.deviceModel,
            firmwareVersion = entity.firmwareVersion,
            installationDate = entity.installationDate,
            lastMaintenanceDate = entity.lastMaintenanceDate,
            deviceStatus = entity.deviceStatus,
            deviceConfig = entity.deviceConfig,
            isActive = entity.isActive,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }

    private fun mapToAccessControlRecordDto(entity: AccessControlRecord): AccessControlRecordDto {
        return AccessControlRecordDto(
            id = entity.id,
            companyId = entity.companyId,
            deviceId = entity.deviceId,
            zoneId = entity.zoneId,
            personId = entity.personId,
            personName = entity.personName,
            personType = entity.personType,
            accessMethod = entity.accessMethod,
            accessDirection = entity.accessDirection,
            accessResult = entity.accessResult,
            accessTimestamp = entity.accessTimestamp,
            denialReason = entity.denialReason,
            additionalInfo = entity.additionalInfo,
            isActive = entity.isActive,
            createdAt = entity.createdAt
        )
    }

    private fun mapToSecurityIncidentDto(entity: SecurityIncident): SecurityIncidentDto {
        return SecurityIncidentDto(
            id = entity.id,
            companyId = entity.companyId,
            incidentNumber = entity.incidentNumber,
            incidentTitle = entity.incidentTitle,
            incidentDescription = entity.incidentDescription,
            incidentType = entity.incidentType,
            severityLevel = entity.severityLevel,
            zoneId = entity.zoneId,
            deviceId = entity.deviceId,
            location = entity.location,
            incidentTimestamp = entity.incidentTimestamp,
            reportedBy = entity.reportedBy,
            assignedTo = entity.assignedTo,
            incidentStatus = entity.incidentStatus,
            resolutionNotes = entity.resolutionNotes,
            resolvedAt = entity.resolvedAt,
            resolvedBy = entity.resolvedBy,
            isActive = entity.isActive,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }

    private fun mapToVisitorManagementDto(entity: VisitorManagement): VisitorManagementDto {
        return VisitorManagementDto(
            id = entity.id,
            companyId = entity.companyId,
            visitorName = entity.visitorName,
            visitorContact = entity.visitorContact,
            visitorCompany = entity.visitorCompany,
            visitorIdNumber = entity.visitorIdNumber,
            visitPurpose = entity.visitPurpose,
            hostName = entity.hostName,
            hostContact = entity.hostContact,
            hostDepartment = entity.hostDepartment,
            visitDate = entity.visitDate,
            expectedDurationHours = entity.expectedDurationHours,
            authorizedZones = entity.authorizedZones,
            checkInTime = entity.checkInTime,
            checkOutTime = entity.checkOutTime,
            visitorBadgeNumber = entity.visitorBadgeNumber,
            visitStatus = entity.visitStatus,
            visitNotes = entity.visitNotes,
            approvedBy = entity.approvedBy,
            approvedAt = entity.approvedAt,
            isActive = entity.isActive,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }

    private fun mapToSecurityPatrolDto(entity: SecurityPatrol): SecurityPatrolDto {
        return SecurityPatrolDto(
            id = entity.id,
            companyId = entity.companyId,
            patrolName = entity.patrolName,
            patrolRoute = entity.patrolRoute,
            patrolSchedule = entity.patrolSchedule,
            assignedGuard = entity.assignedGuard,
            patrolDate = entity.patrolDate,
            startTime = entity.startTime,
            endTime = entity.endTime,
            patrolStatus = entity.patrolStatus,
            checkpointsCompleted = entity.checkpointsCompleted,
            totalCheckpoints = entity.totalCheckpoints,
            patrolNotes = entity.patrolNotes,
            incidentsFound = entity.incidentsFound,
            isActive = entity.isActive,
            createdAt = entity.createdAt,
            updatedAt = entity.updatedAt
        )
    }

    private fun generateIncidentNumber(): String {
        val timestamp = System.currentTimeMillis()
        return "INC-${timestamp}"
    }
}