package com.qiro.domain.marketing.service

import java.time.LocalDate
import java.util.*

/**
 * 마케팅 서비스 인터페이스
 * 
 * 공실 마케팅, 임대 홍보, 고객 관리 등의 기능을 제공합니다.
 */
interface MarketingService {
    
    /**
     * 공실 마케팅 캠페인 생성
     */
    fun createVacancyMarketingCampaign(
        companyId: UUID,
        unitId: UUID,
        campaignName: String,
        targetAudience: String,
        marketingChannels: List<String>,
        budget: Double? = null,
        startDate: LocalDate,
        endDate: LocalDate
    ): Map<String, Any>
    
    /**
     * 마케팅 캠페인 성과 분석
     */
    fun analyzeCampaignPerformance(
        companyId: UUID,
        campaignId: UUID
    ): Map<String, Any>
    
    /**
     * 잠재 고객 관리
     */
    fun manageProspectiveCustomers(
        companyId: UUID,
        prospectData: Map<String, Any>
    ): Map<String, Any>
    
    /**
     * 시장 분석 보고서 생성
     */
    fun generateMarketAnalysisReport(
        companyId: UUID,
        analysisType: String,
        period: String
    ): Map<String, Any>
}