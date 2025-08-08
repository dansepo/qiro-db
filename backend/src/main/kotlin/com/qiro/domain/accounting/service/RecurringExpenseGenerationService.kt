package com.qiro.domain.accounting.service

import com.qiro.domain.accounting.dto.ExpenseRecordDto
import com.qiro.domain.accounting.entity.ExpenseRecord
import com.qiro.domain.accounting.entity.RecurringExpenseSchedule
import com.qiro.domain.accounting.repository.ExpenseRecordRepository
import com.qiro.domain.accounting.repository.RecurringExpenseScheduleRepository
import org.slf4j.LoggerFactory
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.util.*

/**
 * 정기 지출 생성 서비스
 * 관리비, 공과금 등의 정기적인 지출을 자동으로 생성
 */
@Service
@Transactional
class RecurringExpenseGenerationService(
    private val recurringExpenseScheduleRepository: RecurringExpenseScheduleRepository,
    private val expenseRecordRepository: ExpenseRecordRepository
) {
    private val logger = LoggerFactory.getLogger(RecurringExpenseGenerationService::class.java)
    private val systemUserId = UUID.fromString("00000000-0000-0000-0000-000000000000")

    /**
     * 정기 지출 자동 생성 (스케줄링)
     * 매일 오전 2시에 실행
     */
    @Scheduled(cron = "0 0 2 * * ?")
    fun generateScheduledExpenses() {
        logger.info("정기 지출 자동 생성 작업 시작")
        
        try {
            val generatedCount = generateRecurringExpensesForAllCompanies()
            logger.info("정기 지출 자동 생성 완료: {}건", generatedCount)
        } catch (e: Exception) {
            logger.error("정기 지출 자동 생성 중 오류 발생", e)
        }
    }

    /**
     * 모든 회사의 정기 지출 생성
     */
    fun generateRecurringExpensesForAllCompanies(generationDate: LocalDate = LocalDate.now()): Int {
        val allSchedules = recurringExpenseScheduleRepository.findAll()
        val companiesWithSchedules = allSchedules.map { it.companyId }.distinct()
        
        var totalGenerated = 0
        
        companiesWithSchedules.forEach { companyId ->
            try {
                val generated = generateRecurringExpensesForCompany(companyId, generationDate)
                totalGenerated += generated
                logger.debug("회사 {} 정기 지출 생성: {}건", companyId, generated)
            } catch (e: Exception) {
                logger.error("회사 {} 정기 지출 생성 중 오류 발생", companyId, e)
            }
        }
        
        return totalGenerated
    }

    /**
     * 특정 회사의 정기 지출 생성
     */
    fun generateRecurringExpensesForCompany(companyId: UUID, generationDate: LocalDate = LocalDate.now()): Int {
        val schedulesToGenerate = recurringExpenseScheduleRepository.findSchedulesToGenerate(companyId, generationDate)
        var generatedCount = 0

        schedulesToGenerate.forEach { schedule ->
            try {
                val expenseRecord = generateExpenseFromSchedule(schedule, generationDate)
                if (expenseRecord != null) {
                    generatedCount++
                    logger.debug("스케줄 {} 지출 생성 완료: {}", schedule.scheduleName, expenseRecord.expenseRecordId)
                }
            } catch (e: Exception) {
                logger.error("스케줄 {} 지출 생성 중 오류 발생: {}", schedule.scheduleName, e.message, e)
            }
        }

        return generatedCount
    }

    /**
     * 스케줄에서 지출 기록 생성
     */
    fun generateExpenseFromSchedule(
        schedule: RecurringExpenseSchedule,
        generationDate: LocalDate = LocalDate.now()
    ): ExpenseRecord? {
        // 생성 조건 확인
        if (!schedule.shouldGenerate(generationDate)) {
            logger.debug("스케줄 {} 생성 조건 미충족", schedule.scheduleName)
            return null
        }

        // 지급 기한 계산
        val dueDate = calculateDueDate(generationDate, schedule)

        // 승인 상태 결정
        val initialStatus = if (schedule.autoApprove) ExpenseRecord.Status.APPROVED else ExpenseRecord.Status.PENDING
        val initialApprovalStatus = if (schedule.autoApprove) ExpenseRecord.ApprovalStatus.APPROVED else ExpenseRecord.ApprovalStatus.PENDING

        // 지출 기록 생성
        val expenseRecord = ExpenseRecord(
            companyId = schedule.companyId,
            expenseType = schedule.expenseType,
            buildingId = schedule.buildingId,
            unitId = schedule.unitId,
            vendor = schedule.vendor,
            expenseDate = generationDate,
            dueDate = dueDate,
            amount = schedule.amount,
            totalAmount = schedule.amount,
            description = "${schedule.scheduleName} - ${generationDate.year}년 ${generationDate.monthValue}월",
            status = initialStatus,
            approvalStatus = initialApprovalStatus,
            approvedBy = if (schedule.autoApprove) systemUserId else null,
            approvedAt = if (schedule.autoApprove) java.time.LocalDateTime.now() else null,
            createdBy = systemUserId
        )

        val savedExpenseRecord = expenseRecordRepository.save(expenseRecord)

        // 스케줄 업데이트
        val updatedSchedule = schedule.updateAfterGeneration(generationDate)
        recurringExpenseScheduleRepository.save(updatedSchedule)

        return savedExpenseRecord
    }

    /**
     * 지급 기한 계산
     */
    private fun calculateDueDate(generationDate: LocalDate, schedule: RecurringExpenseSchedule): LocalDate {
        // 업체의 결제 조건이 있으면 사용, 없으면 기본값 사용
        val paymentTerms = schedule.vendor?.paymentTerms ?: 30
        
        return when (schedule.frequency) {
            RecurringExpenseSchedule.Frequency.MONTHLY -> generationDate.plusDays(paymentTerms.toLong())
            RecurringExpenseSchedule.Frequency.QUARTERLY -> generationDate.plusDays((paymentTerms + 15).toLong())
            RecurringExpenseSchedule.Frequency.SEMI_ANNUALLY -> generationDate.plusDays((paymentTerms + 30).toLong())
            RecurringExpenseSchedule.Frequency.ANNUALLY -> generationDate.plusDays((paymentTerms + 60).toLong())
        }
    }

    /**
     * 특정 스케줄의 지출 생성
     */
    fun generateExpenseForSchedule(
        scheduleId: UUID,
        generationDate: LocalDate = LocalDate.now()
    ): ExpenseRecordDto? {
        val schedule = recurringExpenseScheduleRepository.findById(scheduleId)
            .orElseThrow { IllegalArgumentException("존재하지 않는 스케줄입니다: $scheduleId") }

        val expenseRecord = generateExpenseFromSchedule(schedule, generationDate)
        return expenseRecord?.let { ExpenseRecordDto.from(it) }
    }

    /**
     * 스케줄 미리보기 (실제 생성하지 않고 생성될 지출 정보 반환)
     */
    @Transactional(readOnly = true)
    fun previewScheduleGeneration(
        scheduleId: UUID,
        generationDate: LocalDate = LocalDate.now()
    ): ScheduleGenerationPreview {
        val schedule = recurringExpenseScheduleRepository.findById(scheduleId)
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
            autoApprove = schedule.autoApprove,
            reason = if (!canGenerate) "생성 조건 미충족" else null
        )
    }

    /**
     * 회사의 생성 대상 스케줄 목록 조회
     */
    @Transactional(readOnly = true)
    fun getSchedulesToGenerate(companyId: UUID, generationDate: LocalDate = LocalDate.now()): List<RecurringExpenseSchedule> {
        return recurringExpenseScheduleRepository.findSchedulesToGenerate(companyId, generationDate)
    }

    /**
     * 만료된 스케줄 비활성화
     */
    fun deactivateExpiredSchedules(companyId: UUID, checkDate: LocalDate = LocalDate.now()): Int {
        val expiredSchedules = recurringExpenseScheduleRepository.findExpiredSchedules(companyId, checkDate)
        var deactivatedCount = 0

        expiredSchedules.forEach { schedule ->
            val deactivatedSchedule = schedule.deactivate()
            recurringExpenseScheduleRepository.save(deactivatedSchedule)
            deactivatedCount++
            logger.info("만료된 스케줄 비활성화: {}", schedule.scheduleName)
        }

        return deactivatedCount
    }

    /**
     * 곧 만료될 스케줄 조회
     */
    @Transactional(readOnly = true)
    fun getExpiringSchedules(companyId: UUID, days: Int = 30): List<RecurringExpenseSchedule> {
        val endDate = LocalDate.now().plusDays(days.toLong())
        return recurringExpenseScheduleRepository.findExpiringSchedules(companyId, LocalDate.now(), endDate)
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
    val amount: java.math.BigDecimal,
    val dueDate: LocalDate?,
    val nextGenerationDate: LocalDate?,
    val autoApprove: Boolean,
    val reason: String?
)