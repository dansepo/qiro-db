package com.qiro.domain.facility.service

import java.time.LocalDateTime
import java.util.*

/**
 * 예약 서비스 인터페이스
 * 
 * 공용시설 예약, 회의실 예약 등의 기능을 제공합니다.
 */
interface ReservationService {
    
    /**
     * 시설 예약
     */
    fun createFacilityReservation(
        companyId: UUID,
        facilityId: UUID,
        userId: UUID,
        startTime: LocalDateTime,
        endTime: LocalDateTime,
        purpose: String,
        participants: Int = 1
    ): Map<String, Any>
    
    /**
     * 예약 취소
     */
    fun cancelReservation(
        companyId: UUID,
        reservationId: UUID,
        cancellationReason: String? = null
    ): Map<String, Any>
    
    /**
     * 예약 가능 시간 조회
     */
    fun getAvailableTimeSlots(
        companyId: UUID,
        facilityId: UUID,
        date: LocalDateTime
    ): List<Map<String, Any>>
    
    /**
     * 사용자 예약 내역 조회
     */
    fun getUserReservations(
        companyId: UUID,
        userId: UUID,
        status: String? = null
    ): List<Map<String, Any>>
}