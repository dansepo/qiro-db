package com.qiro.common.validation

/**
 * 검증 메시지 상수
 */
object ValidationMessages {
    
    // 공통 메시지
    const val NOT_NULL = "필수 입력 항목입니다."
    const val NOT_BLANK = "빈 값일 수 없습니다."
    const val NOT_EMPTY = "비어있을 수 없습니다."
    
    // 크기 관련
    const val SIZE_BETWEEN = "길이는 {min}자 이상 {max}자 이하여야 합니다."
    const val MIN_SIZE = "최소 {value}자 이상이어야 합니다."
    const val MAX_SIZE = "최대 {value}자 이하여야 합니다."
    
    // 숫자 관련
    const val POSITIVE = "양수여야 합니다."
    const val POSITIVE_OR_ZERO = "0 이상이어야 합니다."
    const val MIN_VALUE = "최소값은 {value}입니다."
    const val MAX_VALUE = "최대값은 {value}입니다."
    const val DECIMAL_MIN = "최소값은 {value}입니다."
    const val DECIMAL_MAX = "최대값은 {value}입니다."
    
    // 날짜 관련
    const val FUTURE = "미래 날짜여야 합니다."
    const val FUTURE_OR_PRESENT = "현재 또는 미래 날짜여야 합니다."
    const val PAST = "과거 날짜여야 합니다."
    const val PAST_OR_PRESENT = "현재 또는 과거 날짜여야 합니다."
    
    // 이메일
    const val EMAIL = "올바른 이메일 형식이 아닙니다."
    
    // 패턴
    const val PATTERN = "올바른 형식이 아닙니다."
    
    // 커스텀 검증
    const val KOREAN_PHONE_NUMBER = "올바른 한국 휴대폰 번호 형식이 아닙니다. (예: 010-1234-5678)"
    const val BUSINESS_REGISTRATION_NUMBER = "올바른 사업자등록번호 형식이 아닙니다. (예: 123-45-67890)"
    const val UNIT_NUMBER = "올바른 세대 번호 형식이 아닙니다. (예: 101, 1201A)"
    const val DATE_RANGE = "시작일이 종료일보다 늦을 수 없습니다."
    
    // 도메인 특화 메시지
    object Building {
        const val NAME_REQUIRED = "건물명은 필수입니다."
        const val NAME_SIZE = "건물명은 2자 이상 100자 이하여야 합니다."
        const val ADDRESS_REQUIRED = "주소는 필수입니다."
        const val TOTAL_UNITS_POSITIVE = "총 세대수는 양수여야 합니다."
    }
    
    object Unit {
        const val UNIT_NUMBER_REQUIRED = "세대 번호는 필수입니다."
        const val UNIT_NUMBER_FORMAT = "세대 번호 형식이 올바르지 않습니다."
        const val AREA_POSITIVE = "면적은 양수여야 합니다."
        const val ROOM_COUNT_POSITIVE = "방 개수는 양수여야 합니다."
    }
    
    object Invoice {
        const val DUE_DATE_FUTURE = "납기일은 현재 날짜 이후여야 합니다."
        const val AMOUNT_POSITIVE = "금액은 양수여야 합니다."
        const val INVOICE_NUMBER_REQUIRED = "고지서 번호는 필수입니다."
    }
    
    object Payment {
        const val PAYMENT_AMOUNT_POSITIVE = "결제 금액은 양수여야 합니다."
        const val PAYMENT_METHOD_REQUIRED = "결제 방법은 필수입니다."
        const val PAYER_NAME_REQUIRED = "납부자명은 필수입니다."
    }
    
    object Maintenance {
        const val TITLE_REQUIRED = "제목은 필수입니다."
        const val DESCRIPTION_REQUIRED = "설명은 필수입니다."
        const val PRIORITY_REQUIRED = "우선순위는 필수입니다."
        const val SCHEDULED_DATE_FUTURE = "예정일은 현재 날짜 이후여야 합니다."
    }
    
    object User {
        const val USERNAME_REQUIRED = "사용자명은 필수입니다."
        const val USERNAME_SIZE = "사용자명은 3자 이상 50자 이하여야 합니다."
        const val EMAIL_REQUIRED = "이메일은 필수입니다."
        const val PASSWORD_REQUIRED = "비밀번호는 필수입니다."
        const val PASSWORD_SIZE = "비밀번호는 8자 이상 100자 이하여야 합니다."
        const val PHONE_FORMAT = "올바른 전화번호 형식이 아닙니다."
    }
}