package com.qiro.common.service

import com.qiro.domain.migration.common.AbstractBaseService
import com.qiro.domain.migration.dto.ServiceResponse
import com.qiro.domain.migration.exception.ProcedureMigrationException
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * 번호 생성 서비스
 * 각종 번호 생성 로직을 백엔드 서비스로 구현 (14개 번호 생성 프로시저 이관)
 */
@Service
class NumberGenerationService(
    private val jdbcTemplate: JdbcTemplate
) : AbstractBaseService() {

    // 번호 생성 시퀀스 캐시 (동시성 제어)
    private val sequenceCache = ConcurrentHashMap<String, Long>()

    /**
     * 회계 번호 생성
     * @param companyId 회사 ID
     * @param accountType 회계 유형 (INCOME, EXPENSE, ASSET, LIABILITY)
     * @return 생성된 회계 번호
     */
    @Transactional
    fun generateAccountingNumber(companyId: UUID, accountType: String): ServiceResponse<String> {
        return measureAndExecute("generateAccountingNumber") {
            try {
                val prefix = when (accountType.uppercase()) {
                    "INCOME" -> "INC"
                    "EXPENSE" -> "EXP"
                    "ASSET" -> "AST"
                    "LIABILITY" -> "LIB"
                    else -> "ACC"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"))
                val sequence = getNextSequence("accounting_${companyId}_${accountType}_$dateStr")
                val accountingNumber = "$prefix-$dateStr-${String.format("%06d", sequence)}"

                ServiceResponse.success(
                    data = accountingNumber,
                    message = "회계 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating accounting number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "회계 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 공지사항 번호 생성
     * @param companyId 회사 ID
     * @param noticeType 공지 유형 (GENERAL, URGENT, MAINTENANCE)
     * @return 생성된 공지사항 번호
     */
    @Transactional
    fun generateNoticeNumber(companyId: UUID, noticeType: String): ServiceResponse<String> {
        return measureAndExecute("generateNoticeNumber") {
            try {
                val prefix = when (noticeType.uppercase()) {
                    "GENERAL" -> "NOT"
                    "URGENT" -> "URG"
                    "MAINTENANCE" -> "MNT"
                    else -> "NOT"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"))
                val sequence = getNextSequence("notice_${companyId}_${noticeType}_$dateStr")
                val noticeNumber = "$prefix-$dateStr-${String.format("%04d", sequence)}"

                ServiceResponse.success(
                    data = noticeNumber,
                    message = "공지사항 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating notice number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "공지사항 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 예약 번호 생성
     * @param companyId 회사 ID
     * @param facilityType 시설 유형 (MEETING_ROOM, PARKING, COMMON_AREA)
     * @return 생성된 예약 번호
     */
    @Transactional
    fun generateReservationNumber(companyId: UUID, facilityType: String): ServiceResponse<String> {
        return measureAndExecute("generateReservationNumber") {
            try {
                val prefix = when (facilityType.uppercase()) {
                    "MEETING_ROOM" -> "MTG"
                    "PARKING" -> "PRK"
                    "COMMON_AREA" -> "CMN"
                    else -> "RSV"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"))
                val sequence = getNextSequence("reservation_${companyId}_${facilityType}_$dateStr")
                val reservationNumber = "$prefix-$dateStr-${String.format("%03d", sequence)}"

                ServiceResponse.success(
                    data = reservationNumber,
                    message = "예약 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating reservation number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "예약 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 작업 지시서 번호 생성
     * @param companyId 회사 ID
     * @param workType 작업 유형 (MAINTENANCE, REPAIR, INSPECTION)
     * @return 생성된 작업 지시서 번호
     */
    @Transactional
    fun generateWorkOrderNumber(companyId: UUID, workType: String): ServiceResponse<String> {
        return measureAndExecute("generateWorkOrderNumber") {
            try {
                val prefix = when (workType.uppercase()) {
                    "MAINTENANCE" -> "MNT"
                    "REPAIR" -> "RPR"
                    "INSPECTION" -> "INS"
                    else -> "WRK"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"))
                val sequence = getNextSequence("work_order_${companyId}_${workType}_$dateStr")
                val workOrderNumber = "$prefix-$dateStr-${String.format("%05d", sequence)}"

                ServiceResponse.success(
                    data = workOrderNumber,
                    message = "작업 지시서 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating work order number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "작업 지시서 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 고장 신고 번호 생성
     * @param companyId 회사 ID
     * @param priority 우선순위 (HIGH, MEDIUM, LOW)
     * @return 생성된 고장 신고 번호
     */
    @Transactional
    fun generateFaultReportNumber(companyId: UUID, priority: String): ServiceResponse<String> {
        return measureAndExecute("generateFaultReportNumber") {
            try {
                val prefix = when (priority.uppercase()) {
                    "HIGH" -> "FH"
                    "MEDIUM" -> "FM"
                    "LOW" -> "FL"
                    else -> "FR"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"))
                val sequence = getNextSequence("fault_report_${companyId}_${priority}_$dateStr")
                val faultReportNumber = "$prefix-$dateStr-${String.format("%04d", sequence)}"

                ServiceResponse.success(
                    data = faultReportNumber,
                    message = "고장 신고 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating fault report number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "고장 신고 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 계약서 번호 생성
     * @param companyId 회사 ID
     * @param contractType 계약 유형 (LEASE, SERVICE, MAINTENANCE)
     * @return 생성된 계약서 번호
     */
    @Transactional
    fun generateContractNumber(companyId: UUID, contractType: String): ServiceResponse<String> {
        return measureAndExecute("generateContractNumber") {
            try {
                val prefix = when (contractType.uppercase()) {
                    "LEASE" -> "LSE"
                    "SERVICE" -> "SVC"
                    "MAINTENANCE" -> "MTC"
                    else -> "CTR"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy"))
                val sequence = getNextSequence("contract_${companyId}_${contractType}_$dateStr")
                val contractNumber = "$prefix-$dateStr-${String.format("%06d", sequence)}"

                ServiceResponse.success(
                    data = contractNumber,
                    message = "계약서 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating contract number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "계약서 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 청구서 번호 생성
     * @param companyId 회사 ID
     * @param billType 청구서 유형 (MONTHLY, UTILITY, MAINTENANCE)
     * @return 생성된 청구서 번호
     */
    @Transactional
    fun generateBillNumber(companyId: UUID, billType: String): ServiceResponse<String> {
        return measureAndExecute("generateBillNumber") {
            try {
                val prefix = when (billType.uppercase()) {
                    "MONTHLY" -> "MON"
                    "UTILITY" -> "UTL"
                    "MAINTENANCE" -> "MNT"
                    else -> "BIL"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"))
                val sequence = getNextSequence("bill_${companyId}_${billType}_$dateStr")
                val billNumber = "$prefix-$dateStr-${String.format("%06d", sequence)}"

                ServiceResponse.success(
                    data = billNumber,
                    message = "청구서 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating bill number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "청구서 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 영수증 번호 생성
     * @param companyId 회사 ID
     * @param paymentMethod 결제 방법 (CASH, CARD, TRANSFER)
     * @return 생성된 영수증 번호
     */
    @Transactional
    fun generateReceiptNumber(companyId: UUID, paymentMethod: String): ServiceResponse<String> {
        return measureAndExecute("generateReceiptNumber") {
            try {
                val prefix = when (paymentMethod.uppercase()) {
                    "CASH" -> "CSH"
                    "CARD" -> "CRD"
                    "TRANSFER" -> "TRF"
                    else -> "RCP"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"))
                val sequence = getNextSequence("receipt_${companyId}_${paymentMethod}_$dateStr")
                val receiptNumber = "$prefix-$dateStr-${String.format("%05d", sequence)}"

                ServiceResponse.success(
                    data = receiptNumber,
                    message = "영수증 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating receipt number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "영수증 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 자산 번호 생성
     * @param companyId 회사 ID
     * @param assetCategory 자산 분류 (EQUIPMENT, FURNITURE, VEHICLE)
     * @return 생성된 자산 번호
     */
    @Transactional
    fun generateAssetNumber(companyId: UUID, assetCategory: String): ServiceResponse<String> {
        return measureAndExecute("generateAssetNumber") {
            try {
                val prefix = when (assetCategory.uppercase()) {
                    "EQUIPMENT" -> "EQP"
                    "FURNITURE" -> "FUR"
                    "VEHICLE" -> "VHC"
                    else -> "AST"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy"))
                val sequence = getNextSequence("asset_${companyId}_${assetCategory}_$dateStr")
                val assetNumber = "$prefix-$dateStr-${String.format("%05d", sequence)}"

                ServiceResponse.success(
                    data = assetNumber,
                    message = "자산 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating asset number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "자산 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 사용자 ID 생성
     * @param companyId 회사 ID
     * @param userType 사용자 유형 (ADMIN, MANAGER, TENANT)
     * @return 생성된 사용자 ID
     */
    @Transactional
    fun generateUserId(companyId: UUID, userType: String): ServiceResponse<String> {
        return measureAndExecute("generateUserId") {
            try {
                val prefix = when (userType.uppercase()) {
                    "ADMIN" -> "ADM"
                    "MANAGER" -> "MGR"
                    "TENANT" -> "TNT"
                    else -> "USR"
                }
                
                val companyPrefix = companyId.toString().substring(0, 4).uppercase()
                val sequence = getNextSequence("user_${companyId}_${userType}")
                val userId = "$prefix$companyPrefix${String.format("%04d", sequence)}"

                ServiceResponse.success(
                    data = userId,
                    message = "사용자 ID가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating user ID", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "사용자 ID 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 건물 코드 생성
     * @param companyId 회사 ID
     * @param buildingType 건물 유형 (OFFICE, RESIDENTIAL, COMMERCIAL)
     * @return 생성된 건물 코드
     */
    @Transactional
    fun generateBuildingCode(companyId: UUID, buildingType: String): ServiceResponse<String> {
        return measureAndExecute("generateBuildingCode") {
            try {
                val prefix = when (buildingType.uppercase()) {
                    "OFFICE" -> "OFF"
                    "RESIDENTIAL" -> "RES"
                    "COMMERCIAL" -> "COM"
                    else -> "BLD"
                }
                
                val sequence = getNextSequence("building_${companyId}_${buildingType}")
                val buildingCode = "$prefix-${String.format("%03d", sequence)}"

                ServiceResponse.success(
                    data = buildingCode,
                    message = "건물 코드가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating building code", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "건물 코드 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 호실 번호 생성
     * @param companyId 회사 ID
     * @param buildingId 건물 ID
     * @param floor 층수
     * @return 생성된 호실 번호
     */
    @Transactional
    fun generateUnitNumber(companyId: UUID, buildingId: UUID, floor: Int): ServiceResponse<String> {
        return measureAndExecute("generateUnitNumber") {
            try {
                val floorStr = String.format("%02d", floor)
                val sequence = getNextSequence("unit_${companyId}_${buildingId}_$floor")
                val unitNumber = "$floorStr${String.format("%02d", sequence)}"

                ServiceResponse.success(
                    data = unitNumber,
                    message = "호실 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating unit number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "호실 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 문서 번호 생성
     * @param companyId 회사 ID
     * @param documentType 문서 유형 (CONTRACT, REPORT, MANUAL)
     * @return 생성된 문서 번호
     */
    @Transactional
    fun generateDocumentNumber(companyId: UUID, documentType: String): ServiceResponse<String> {
        return measureAndExecute("generateDocumentNumber") {
            try {
                val prefix = when (documentType.uppercase()) {
                    "CONTRACT" -> "CTR"
                    "REPORT" -> "RPT"
                    "MANUAL" -> "MAN"
                    else -> "DOC"
                }
                
                val dateStr = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMM"))
                val sequence = getNextSequence("document_${companyId}_${documentType}_$dateStr")
                val documentNumber = "$prefix-$dateStr-${String.format("%04d", sequence)}"

                ServiceResponse.success(
                    data = documentNumber,
                    message = "문서 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating document number", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "문서 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 배치 번호 생성 (여러 번호를 한 번에 생성)
     * @param companyId 회사 ID
     * @param numberType 번호 유형
     * @param count 생성할 개수
     * @param additionalParams 추가 파라미터
     * @return 생성된 번호 목록
     */
    @Transactional
    fun generateBatchNumbers(
        companyId: UUID, 
        numberType: String, 
        count: Int, 
        additionalParams: Map<String, Any> = emptyMap()
    ): ServiceResponse<List<String>> {
        return measureAndExecute("generateBatchNumbers") {
            try {
                if (count <= 0 || count > 1000) {
                    return@measureAndExecute ServiceResponse.failure<List<String>>(
                        error = "생성할 번호 개수는 1~1000 사이여야 합니다"
                    )
                }

                val generatedNumbers = mutableListOf<String>()

                for (i in 1..count) {
                    val numberResult = when (numberType.uppercase()) {
                        "ACCOUNTING" -> generateAccountingNumber(companyId, additionalParams["accountType"] as? String ?: "GENERAL")
                        "NOTICE" -> generateNoticeNumber(companyId, additionalParams["noticeType"] as? String ?: "GENERAL")
                        "RESERVATION" -> generateReservationNumber(companyId, additionalParams["facilityType"] as? String ?: "GENERAL")
                        "WORK_ORDER" -> generateWorkOrderNumber(companyId, additionalParams["workType"] as? String ?: "GENERAL")
                        "FAULT_REPORT" -> generateFaultReportNumber(companyId, additionalParams["priority"] as? String ?: "MEDIUM")
                        "CONTRACT" -> generateContractNumber(companyId, additionalParams["contractType"] as? String ?: "GENERAL")
                        "BILL" -> generateBillNumber(companyId, additionalParams["billType"] as? String ?: "GENERAL")
                        "RECEIPT" -> generateReceiptNumber(companyId, additionalParams["paymentMethod"] as? String ?: "GENERAL")
                        "ASSET" -> generateAssetNumber(companyId, additionalParams["assetCategory"] as? String ?: "GENERAL")
                        "USER" -> generateUserId(companyId, additionalParams["userType"] as? String ?: "GENERAL")
                        "BUILDING" -> generateBuildingCode(companyId, additionalParams["buildingType"] as? String ?: "GENERAL")
                        "UNIT" -> generateUnitNumber(companyId, 
                            additionalParams["buildingId"] as? UUID ?: UUID.randomUUID(),
                            additionalParams["floor"] as? Int ?: 1)
                        "DOCUMENT" -> generateDocumentNumber(companyId, additionalParams["documentType"] as? String ?: "GENERAL")
                        else -> ServiceResponse.failure<String>("지원하지 않는 번호 유형입니다: $numberType")
                    }

                    if (numberResult.success && numberResult.data != null) {
                        generatedNumbers.add(numberResult.data)
                    } else {
                        logger.warn("Failed to generate number for type $numberType: ${numberResult.message}")
                    }
                }

                ServiceResponse.success(
                    data = generatedNumbers,
                    message = "${generatedNumbers.size}개의 ${numberType} 번호가 성공적으로 생성되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error generating batch numbers", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "배치 번호 생성 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    /**
     * 시퀀스 초기화
     * @param sequenceKey 시퀀스 키
     * @return 초기화 결과
     */
    @Transactional
    fun resetSequence(sequenceKey: String): ServiceResponse<Boolean> {
        return measureAndExecute("resetSequence") {
            try {
                sequenceCache.remove(sequenceKey)
                
                // 데이터베이스에서도 시퀀스 정보 삭제
                jdbcTemplate.update(
                    "DELETE FROM bms.number_sequences WHERE sequence_key = ?",
                    sequenceKey
                )

                ServiceResponse.success(
                    data = true,
                    message = "시퀀스가 성공적으로 초기화되었습니다"
                )

            } catch (e: Exception) {
                logger.error("Error resetting sequence", e)
                throw ProcedureMigrationException.DataIntegrityException(
                    "시퀀스 초기화 중 오류가 발생했습니다: ${e.message}"
                )
            }
        }
    }

    // Private helper methods

    @Synchronized
    private fun getNextSequence(sequenceKey: String): Long {
        return try {
            // 캐시에서 먼저 확인
            val cachedValue = sequenceCache[sequenceKey]
            if (cachedValue != null) {
                val nextValue = cachedValue + 1
                sequenceCache[sequenceKey] = nextValue
                return nextValue
            }

            // 데이터베이스에서 현재 시퀀스 값 조회
            val currentValue = try {
                jdbcTemplate.queryForObject(
                    "SELECT current_value FROM bms.number_sequences WHERE sequence_key = ?",
                    Long::class.java,
                    sequenceKey
                ) ?: 0L
            } catch (e: Exception) {
                0L
            }

            val nextValue = currentValue + 1

            // 데이터베이스에 업데이트 또는 삽입
            val updateCount = jdbcTemplate.update(
                "UPDATE bms.number_sequences SET current_value = ?, updated_at = NOW() WHERE sequence_key = ?",
                nextValue,
                sequenceKey
            )

            if (updateCount == 0) {
                // 새로운 시퀀스 생성
                jdbcTemplate.update(
                    """
                    INSERT INTO bms.number_sequences (sequence_key, current_value, created_at, updated_at) 
                    VALUES (?, ?, NOW(), NOW())
                    """.trimIndent(),
                    sequenceKey,
                    nextValue
                )
            }

            // 캐시에 저장
            sequenceCache[sequenceKey] = nextValue
            nextValue

        } catch (e: Exception) {
            logger.error("Error getting next sequence for key: $sequenceKey", e)
            // 오류 발생 시 현재 시간 기반 시퀀스 생성
            System.currentTimeMillis() % 100000
        }
    }

    /**
     * 번호 중복 검사
     * @param tableName 테이블명
     * @param columnName 컬럼명
     * @param numberValue 검사할 번호
     * @return 중복 여부
     */
    private fun checkNumberDuplicate(tableName: String, columnName: String, numberValue: String): Boolean {
        return try {
            val count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM bms.$tableName WHERE $columnName = ?",
                Int::class.java,
                numberValue
            ) ?: 0
            count > 0
        } catch (e: Exception) {
            logger.warn("Error checking number duplicate: ${e.message}")
            false
        }
    }
}