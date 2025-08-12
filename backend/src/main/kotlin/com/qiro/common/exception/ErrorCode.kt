package com.qiro.common.exception

/**
 * 에러 코드
 */
enum class ErrorCode(val code: String, val message: String) {
    // 일반 에러
    INTERNAL_SERVER_ERROR("E001", "내부 서버 오류가 발생했습니다."),
    INVALID_REQUEST("E002", "잘못된 요청입니다."),
    UNAUTHORIZED("E003", "인증이 필요합니다."),
    FORBIDDEN("E004", "접근 권한이 없습니다."),
    NOT_FOUND("E005", "요청한 리소스를 찾을 수 없습니다."),
    
    // 비즈니스 규칙 에러
    BUSINESS_RULE_NOT_FOUND("BR001", "비즈니스 규칙을 찾을 수 없습니다."),
    BUSINESS_RULE_ALREADY_EXISTS("BR002", "이미 존재하는 비즈니스 규칙입니다."),
    BUSINESS_RULE_EXECUTION_FAILED("BR003", "비즈니스 규칙 실행에 실패했습니다."),
    
    // 검증 에러
    VALIDATION_FAILED("V001", "검증에 실패했습니다."),
    INVALID_DATA_FORMAT("V002", "잘못된 데이터 형식입니다."),
    
    // 작업지시서 에러
    WORK_ORDER_NOT_FOUND("WO001", "작업지시서를 찾을 수 없습니다."),
    WORK_ORDER_CANNOT_BE_MODIFIED("WO002", "작업지시서를 수정할 수 없습니다."),
    WORK_ORDER_ALREADY_ASSIGNED("WO003", "이미 할당된 작업지시서입니다."),
    WORK_ORDER_ALREADY_PROCESSED("WO004", "이미 처리된 작업지시서입니다."),
    WORK_ORDER_NOT_IN_PROGRESS("WO005", "진행 중인 작업지시서가 아닙니다."),
    WORK_ORDER_NOT_PAUSED("WO006", "일시정지된 작업지시서가 아닙니다."),
    WORK_ORDER_CANNOT_BE_CANCELLED("WO007", "작업지시서를 취소할 수 없습니다."),
    INVALID_STATUS_TRANSITION("WO008", "잘못된 상태 전환입니다."),
    
    // 사용자 에러
    USER_NOT_FOUND("U001", "사용자를 찾을 수 없습니다."),
    COMPANY_NOT_FOUND("C001", "회사를 찾을 수 없습니다."),
    
    // 데이터 무결성 에러
    DUPLICATE_VALUE("DI001", "중복된 값입니다."),
    REFERENCE_INTEGRITY("DI002", "참조 무결성 위반입니다."),
    BUSINESS_RULE_VIOLATION("DI003", "비즈니스 규칙 위반입니다."),
    
    // 계정과목 에러
    INVALID_ACCOUNT_CODE("AC001", "잘못된 계정과목 코드입니다."),
    PARENT_ACCOUNT_NOT_FOUND("AC002", "상위 계정과목을 찾을 수 없습니다."),
    INVALID_PARENT_ACCOUNT("AC003", "잘못된 상위 계정과목입니다."),
    SYSTEM_ACCOUNT_NOT_MODIFIABLE("AC004", "시스템 계정과목은 수정할 수 없습니다."),
    CIRCULAR_REFERENCE_DETECTED("AC005", "순환 참조가 감지되었습니다."),
    SYSTEM_ACCOUNT_NOT_DELETABLE("AC006", "시스템 계정과목은 삭제할 수 없습니다."),
    ACCOUNT_HAS_CHILD_ACCOUNTS("AC007", "하위 계정과목이 있어 삭제할 수 없습니다."),
    ACCOUNT_HAS_ACTIVE_TRANSACTIONS("AC008", "활성 거래가 있어 삭제할 수 없습니다."),
    ACCOUNT_CODE_NOT_FOUND("AC009", "계정과목을 찾을 수 없습니다."),
    
    // 일반 에러
    ENTITY_NOT_FOUND("E006", "엔티티를 찾을 수 없습니다."),
    ACCESS_DENIED("E007", "접근이 거부되었습니다."),
    BUSINESS_ERROR("E008", "비즈니스 오류가 발생했습니다.")
}