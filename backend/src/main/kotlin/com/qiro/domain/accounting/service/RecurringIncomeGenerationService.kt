package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.IncomeRecordDto
import com.qiro.domain.accounting.entity.IncomeRecord
import com.qiro.domain.accounting.entity.Receivable
import com.qiro.domain.accounting.entity.RecurringIncomeSchedule
import com.qiro.domain.accounting.repository.IncomeRecordRepository
import com.qiro.domain.accounting.repository.ReceivableRepository
import com.qiro.domain.accounting.repository.RecurringIncomeScheduleRepository
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.util.*

/**
 * 정기 수입 생성 서비스
 * 관리비, 임대료 등의 정기적인 수입을 자동으로 생성
 */
@Service
@Transactional
class RecurringIncomeGenerationService(
    private val recurringIncomeScheduleRepository: RecurringIncomeScheduleRepository,
    private val incomeRecordRepository: IncomeRecordRepository,
    private val receivableRepository: ReceivableRepository
) {
    private val logger = LoggerFactory.getLogger(RecurringIncomeGenerationService::class.java)
    private val systemUserId = UUID.fromString("00000000-0000-0000-0000-000000000000")

    /**
     * 정기 수입 자동 생성 (스케줄링)
     * 매일 오전 1시에 실행
     */
    @Scheduled(cron = "0 0 1 * * ?")
    fun generateScheduledIncome() {
        logger.info("정기 수입 자동 생성 작업 시작")
        
        try {
            val generatedCount = generateRecurringIncomeForAllCompanies()
            logger.info("정기 수입 자동 생성 완료: {}건", generatedCount)
        } catch (e: Exception) {
            logger.error("정기 수입 자동 생성 중 오류 발생", e)
        }
    }

    /**
     * 모든 회사의 정기 수입 생성
     */
    fun generateRecurringIncomeForAllCompanies(generationDate: LocalDate = LocalDate.now()): Int {
        val allSchedules = recurringIncomeScheduleRepository.findAll()
        val companiesWithSchedules = allSchedules.map { it.companyId }.distinct()
        
        var totalGenerated = 0
        
        companiesWithSchedules.forEach { companyId ->
            try {
                val generated = generateRecurringIncomeForCompany(companyId, generationDate)
                totalGenerated += generated
                logger.debug("회사 {} 정기 수입 생성: {}건", companyId, generated)
            } catch (e: Exception) {
                logger.error("회사 {} 정기 수입 생성 중 오류 발생", companyId, e)
            }
        }
        
        return totalGenerated
    }

    /**
     * 특정 회사의 정기 수입 생성
     */
    fun generateRecurringIncomeForCompany(companyId: UUID, generationDate: LocalDate = LocalDate.now()): Int {
        val schedulesToGenerate = recurringIncomeScheduleRepository.findSchedulesToGenerate(companyId, generationDate)
        var generatedCount = 0

        schedulesToGenerate.forEach { schedule ->
            try {
                val incomeRecord = generateIncomeFromSchedule(schedule, generationDate)
                if (incomeRecord != null) {
                    generatedCount++
                    logger.debug("스케줄 {} 수입 생성 완료: {}", schedule.scheduleName, incomeRecord.incomeRecordId)
                }
            } catch (e: Exception) {
                logger.error("스케줄 {} 수입 생성 중 오류 발생: {}", schedule.scheduleName, e.message, e)
            }
        }

        return generatedCount
    }

    /**
     * 스케줄에서 수입 기록 생성
     */
    fun generateIncomeFromSchedule(
        schedule: RecurringIncomeSchedule,
        generationDate: LocalDate = LocalDate.now()
    ): IncomeRecord? {
        // 생성 조건 확인
        if (!schedule.shouldGenerate(generationDate)) {
            logger.debug("스케줄 {} 생성 조건 미충족", schedule.scheduleName)
            return null
        }

        // 수입 기록 생성
        val incomeRecord = IncomeRecord(
            companyId = schedule.companyId,
            incomeType = schedule.incomeType,
            buildingId = schedule.buildingId,
            unitId = schedule.unitId,
            contractId = schedule.contractId,
            tenantId = schedule.tenantId,
            incomeDate = generationDate,
            dueDate = calculateDueDate(generationDate, schedule),
            amount = schedule.amount,
            totalAmount = schedule.amount,
            description = "${schedule.scheduleName} - ${generationDate.year}년 ${generationDate.monthValue}월",
            status = IncomeRecord.Status.PENDING,
            createdBy = systemUserId
        )

        val savedIncomeRecord = incomeRecordRepository.save(incomeRecord)

        // 미수금 생성
        val dueDate = calculateDueDate(generationDate, schedule)
        createReceivableForIncomeRecord(savedIncomeRecord, dueDate)

        // 스케줄 업데이트
        val updatedSchedule = schedule.updateAfterGeneration(generationDate)
        recurringIncomeScheduleRepository.save(updatedSchedule)

        return savedIncomeRecord
    }

    /**
     * 납부 기한 계산
     */
    private fun calculateDueDate(generationDate: LocalDate, schedule: RecurringIncomeSchedule): LocalDate {
        return when (schedule.frequency) {
            RecurringIncomeSchedule.Frequency.MONTHLY -> generationDate.plusDays(30)
            RecurringIncomeSchedule.Frequency.QUARTERLY -> generationDate.plusDays(45)
            RecurringIncomeSchedule.Frequency.SEMI_ANNUALLY -> generationDate.plusDays(60)
            RecurringIncomeSchedule.Frequency.ANNUALLY -> generationDate.plusDays(90)
        }
    }

    /**
     * 수입 기록에 대한 미수금 생성
     */
    private fun createReceivableForIncomeRecord(incomeRecord: IncomeRecord, dueDate: LocalDate): Receivable {
        val receivable = Receivable(
            companyId = incomeRecord.companyId,
            incomeRecord = incomeRecord,
            buildingId = incomeRecord.buildingId,
            unitId = incomeRecord.unitId,
            tenantId = incomeRecord.tenantId,
            originalAmount = incomeRecord.totalAmount,
            outstandingAmount = incomeRecord.totalAmount,
            totalOutstanding = incomeRecord.totalAmount,
            dueDate = dueDate,
            status = Receivable.Status.OUTSTANDING
        )

        return receivableRepository.save(receivable)
    }

    /**
     * 특정 스케줄의 수입 생성
     */
    fun generateIncomeForSchedule(
        scheduleId: UUID,
        generationDate: LocalDate = LocalDate.now()
    ): IncomeRecordDto? {
        val schedule = recurringIncomeScheduleRepository.findById(scheduleId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 스케줄입니다: $scheduleId") }

        val incomeRecord = generateIncomeFromSchedule(schedule, generationDate)
        return incomeRecord?.let { IncomeRecordDto.from(it) }
    }

    /**
     * 스케줄 미리보기 (실제 생성하지 않고 생성될 수입 정보 반환)
     */
    @Transactional(readOnly = true)
    fun previewScheduleGeneration(
        scheduleId: UUID,
        generationDate: LocalDate = LocalDate.now()
    ): ScheduleGenerationPreview {
        val schedule = recurringIncomeScheduleRepository.findById(scheduleId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 스케줄입니다: $scheduleId") }

        val canGenerate = schedule.shouldGenerate(generationDate)
        val dueDate = if (canGenerate) calculateDueDate(generationDate, schedule) else null
        val nextGenerationDate = if (canGenerate) schedule.calculateNextGenerationDate() else null

        return ScheduleGenerationPreview(
            scheduleId = scheduleId,
            scheduleName = schedule.scheduleName,
            canGenerate = canGenerate,
            generationDate = generationDate,
            amount = schedule.amount,
            dueDate = dueDate,
            nextGenerationDate = nextGenerationDate,
            reason = if (!canGenerate) "생성 조건 미충족" else null
        )
    }

    /**
     * 회사의 생성 대상 스케줄 목록 조회
     */
    @Transactional(readOnly = true)
    fun getSchedulesToGenerate(companyId: UUID, generationDate: LocalDate = LocalDate.now()): List<RecurringIncomeSchedule> {
        return recurringIncomeScheduleRepository.findSchedulesToGenerate(companyId, generationDate)
    }

    /**
     * 만료된 스케줄 비활성화
     */
    fun deactivateExpiredSchedules(companyId: UUID, checkDate: LocalDate = LocalDate.now()): Int {
        val expiredSchedules = recurringIncomeScheduleRepository.findExpiredSchedules(companyId, checkDate)
        var deactivatedCount = 0

        expiredSchedules.forEach { schedule ->
            val deactivatedSchedule = schedule.deactivate()
            recurringIncomeScheduleRepository.save(deactivatedSchedule)
            deactivatedCount++
            logger.info("만료된 스케줄 비활성화: {}", schedule.scheduleName)
        }

        return deactivatedCount
    }
}

/**
 * 스케줄 생성 미리보기 정보
 */
data class ScheduleGenerationPreview(
    val scheduleId: UUID,
    val scheduleName: String,
    val canGenerate: Boolean,
    val generationDate: LocalDate,
    val amount: BigDecimal,
    val dueDate: LocalDate?,
    val nextGenerationDate: LocalDate?,
    val reason: String?
)