package com.qiro.common.exception

/**
 * 비즈니스 예외 코드 정의
 */
enum class ErrorCode(
    val code: String,
    val message: String,
    val httpStatus: Int = 400
) {
    // 공통 에러
    INVALID_INPUT("COMMON_001", "잘못된 입력값입니다", 400),
    UNAUTHORIZED("COMMON_002", "인증이 필요합니다", 401),
    FORBIDDEN("COMMON_003", "접근 권한이 없습니다", 403),
    NOT_FOUND("COMMON_004", "요청한 리소스를 찾을 수 없습니다", 404),
    INTERNAL_SERVER_ERROR("COMMON_005", "서버 내부 오류가 발생했습니다", 500),

    // 회사 관련 에러
    COMPANY_NOT_FOUND("COMPANY_001", "회사를 찾을 수 없습니다", 404),
    COMPANY_ALREADY_EXISTS("COMPANY_002", "이미 존재하는 회사입니다", 409),

    // 사용자 관련 에러
    USER_NOT_FOUND("USER_001", "사용자를 찾을 수 없습니다", 404),
    USER_ALREADY_EXISTS("USER_002", "이미 존재하는 사용자입니다", 409),
    INVALID_CREDENTIALS("USER_003", "잘못된 인증 정보입니다", 401),

    // 건물 관련 에러
    BUILDING_NOT_FOUND("BUILDING_001", "건물을 찾을 수 없습니다", 404),
    BUILDING_ALREADY_EXISTS("BUILDING_002", "이미 존재하는 건물입니다", 409),

    // 세대 관련 에러
    UNIT_NOT_FOUND("UNIT_001", "세대를 찾을 수 없습니다", 404),
    UNIT_ALREADY_EXISTS("UNIT_002", "이미 존재하는 세대입니다", 409),
    UNIT_ALREADY_OCCUPIED("UNIT_003", "이미 임대 중인 세대입니다", 409),

    // 임차인 관련 에러
    TENANT_NOT_FOUND("TENANT_001", "임차인을 찾을 수 없습니다", 404),
    TENANT_ALREADY_EXISTS("TENANT_002", "이미 존재하는 임차인입니다", 409),

    // 임대인 관련 에러
    LESSOR_NOT_FOUND("LESSOR_001", "임대인을 찾을 수 없습니다", 404),
    LESSOR_ALREADY_EXISTS("LESSOR_002", "이미 존재하는 임대인입니다", 409),

    // 계약 관련 에러
    CONTRACT_NOT_FOUND("CONTRACT_001", "계약을 찾을 수 없습니다", 404),
    CONTRACT_ALREADY_EXISTS("CONTRACT_002", "이미 존재하는 계약입니다", 409),
    CONTRACT_NUMBER_ALREADY_EXISTS("CONTRACT_003", "이미 존재하는 계약번호입니다", 409),
    CONTRACT_ALREADY_SIGNED("CONTRACT_004", "이미 서명된 계약입니다", 409),
    CONTRACT_NOT_SIGNED("CONTRACT_005", "서명되지 않은 계약입니다", 400),
    CONTRACT_NOT_ACTIVE("CONTRACT_006", "활성 상태가 아닌 계약입니다", 400),
    CONTRACT_CANNOT_BE_MODIFIED("CONTRACT_007", "수정할 수 없는 계약입니다", 400),
    CONTRACT_CANNOT_BE_DELETED("CONTRACT_008", "삭제할 수 없는 계약입니다", 400),
    INVALID_CONTRACT_PERIOD("CONTRACT_009", "잘못된 계약 기간입니다", 400),

    // 청구서 관련 에러
    BILLING_NOT_FOUND("BILLING_001", "청구서를 찾을 수 없습니다", 404),
    BILLING_ALREADY_EXISTS("BILLING_002", "이미 존재하는 청구서입니다", 409),
    BILLING_ALREADY_PAID("BILLING_003", "이미 결제된 청구서입니다", 409),
    BILLING_CANNOT_BE_MODIFIED("BILLING_004", "수정할 수 없는 청구서입니다", 400),
    BILLING_CANNOT_BE_DELETED("BILLING_005", "삭제할 수 없는 청구서입니다", 400),
    PAYMENT_AMOUNT_EXCEEDS_UNPAID("BILLING_006", "결제 금액이 미납 금액을 초과합니다", 400),

    // 권한 관련 에러
    INSUFFICIENT_PERMISSION("PERMISSION_001", "권한이 부족합니다", 403),
    ROLE_NOT_FOUND("PERMISSION_002", "역할을 찾을 수 없습니다", 404),

    // 파일 관련 에러
    FILE_NOT_FOUND("FILE_001", "파일을 찾을 수 없습니다", 404),
    FILE_UPLOAD_FAILED("FILE_002", "파일 업로드에 실패했습니다", 500),
    INVALID_FILE_FORMAT("FILE_003", "지원하지 않는 파일 형식입니다", 400),
    FILE_SIZE_EXCEEDED("FILE_004", "파일 크기가 제한을 초과했습니다", 400),

    // 알림 관련 에러
    NOTIFICATION_NOT_FOUND("NOTIFICATION_001", "알림을 찾을 수 없습니다", 404),
    NOTIFICATION_SETTING_NOT_FOUND("NOTIFICATION_002", "알림 설정을 찾을 수 없습니다", 404),
    TEMPLATE_NOT_FOUND("NOTIFICATION_003", "알림 템플릿을 찾을 수 없습니다", 404),
    NOTIFICATION_SEND_FAILED("NOTIFICATION_004", "알림 발송에 실패했습니다", 500),
    INVALID_NOTIFICATION_CHANNEL("NOTIFICATION_005", "지원하지 않는 알림 채널입니다", 400),
    NOTIFICATION_LIMIT_EXCEEDED("NOTIFICATION_006", "알림 발송 제한을 초과했습니다", 429),
    INVALID_TEMPLATE_FORMAT("NOTIFICATION_007", "잘못된 템플릿 형식입니다", 400),
    RECIPIENT_NOT_FOUND("NOTIFICATION_008", "수신자를 찾을 수 없습니다", 404),

    // 계정과목 관련 에러
    ACCOUNT_CODE_NOT_FOUND("ACCOUNT_001", "계정과목을 찾을 수 없습니다", 404),
    DUPLICATE_ACCOUNT_CODE("ACCOUNT_002", "이미 존재하는 계정과목 코드입니다", 409),
    INVALID_ACCOUNT_CODE("ACCOUNT_003", "잘못된 계정과목 코드 형식입니다", 400),
    PARENT_ACCOUNT_NOT_FOUND("ACCOUNT_004", "상위 계정과목을 찾을 수 없습니다", 404),
    INVALID_PARENT_ACCOUNT("ACCOUNT_005", "잘못된 상위 계정과목입니다", 400),
    CIRCULAR_REFERENCE_DETECTED("ACCOUNT_006", "순환 참조가 감지되었습니다", 400),
    SYSTEM_ACCOUNT_NOT_MODIFIABLE("ACCOUNT_007", "시스템 계정과목은 수정할 수 없습니다", 400),
    SYSTEM_ACCOUNT_NOT_DELETABLE("ACCOUNT_008", "시스템 계정과목은 삭제할 수 없습니다", 400),
    ACCOUNT_HAS_CHILD_ACCOUNTS("ACCOUNT_009", "하위 계정과목이 있어 삭제할 수 없습니다", 400),
    ACCOUNT_HAS_ACTIVE_TRANSACTIONS("ACCOUNT_010", "활성 거래가 있어 삭제할 수 없습니다", 400)
}