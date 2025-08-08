package com.qiro.domain.accounting.repository

import com.qiro.domain.accounting.entity.IncomeType
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest
import org.springframework.test.context.ActiveProfiles
import java.util.*

/**
 * 수입 관리 Repository 통합 테스트
 */
@DataJpaTest
@ActiveProfiles("test")
class IncomeRepositoryIntegrationTest {

    @Autowired
    private lateinit var incomeTypeRepository: IncomeTypeRepository

    private val testCompanyId = UUID.randomUUID()

    @Test
    fun `수입 유형 저장 및 조회 테스트`() {
        // Given
        val incomeType = IncomeType(
            companyId = testCompanyId,
            typeCode = "MAINTENANCE_FEE",
            typeName = "관리비",
            description = "월별 관리비 수입",
            isRecurring = true,
            defaultAccountId = null
        )

        // When
        val savedIncomeType = incomeTypeRepository.save(incomeType)
        val foundIncomeType = incomeTypeRepository.findByCompanyIdAndTypeCode(
            testCompanyId, "MAINTENANCE_FEE"
        )

        // Then
        assert(savedIncomeType.incomeTypeId != null)
        assert(foundIncomeType != null)
        assert(foundIncomeType?.typeName == "관리비")
        assert(foundIncomeType?.isRecurring == true)
    }

    @Test
    fun `회사별 활성 수입 유형 조회 테스트`() {
        // Given
        val incomeTypes = listOf(
            IncomeType(
                companyId = testCompanyId,
                typeCode = "MAINTENANCE_FEE",
                typeName = "관리비",
                isRecurring = true,
                isActive = true
            ),
            IncomeType(
                companyId = testCompanyId,
                typeCode = "RENT",
                typeName = "임대료",
                isRecurring = true,
                isActive = true
            ),
            IncomeType(
                companyId = testCompanyId,
                typeCode = "PARKING_FEE",
                typeName = "주차비",
                isRecurring = true,
                isActive = false
            )
        )

        incomeTypeRepository.saveAll(incomeTypes)

        // When
        val activeIncomeTypes = incomeTypeRepository.findActiveIncomeTypes(testCompanyId)

        // Then
        assert(activeIncomeTypes.size == 2)
        assert(activeIncomeTypes.all { it.isActive })
    }

    @Test
    fun `정기 수입 유형 조회 테스트`() {
        // Given
        val incomeTypes = listOf(
            IncomeType(
                companyId = testCompanyId,
                typeCode = "MAINTENANCE_FEE",
                typeName = "관리비",
                isRecurring = true,
                isActive = true
            ),
            IncomeType(
                companyId = testCompanyId,
                typeCode = "DEPOSIT",
                typeName = "보증금",
                isRecurring = false,
                isActive = true
            )
        )

        incomeTypeRepository.saveAll(incomeTypes)

        // When
        val recurringIncomeTypes = incomeTypeRepository.findRecurringIncomeTypes(testCompanyId)

        // Then
        assert(recurringIncomeTypes.size == 1)
        assert(recurringIncomeTypes[0].typeCode == "MAINTENANCE_FEE")
        assert(recurringIncomeTypes[0].isRecurring)
    }

    @Test
    fun `수입 유형 코드 중복 확인 테스트`() {
        // Given
        val incomeType = IncomeType(
            companyId = testCompanyId,
            typeCode = "MAINTENANCE_FEE",
            typeName = "관리비",
            isRecurring = true
        )

        incomeTypeRepository.save(incomeType)

        // When
        val exists = incomeTypeRepository.existsByCompanyIdAndTypeCode(
            testCompanyId, "MAINTENANCE_FEE"
        )
        val notExists = incomeTypeRepository.existsByCompanyIdAndTypeCode(
            testCompanyId, "NON_EXISTENT"
        )

        // Then
        assert(exists)
        assert(!notExists)
    }
}