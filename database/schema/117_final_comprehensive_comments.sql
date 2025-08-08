-- =====================================================
-- 최종 포괄적 컬럼 한글 커멘트 스크립트
-- 주요 테이블들의 모든 컬럼에 한글 커멘트 추가
-- =====================================================

-- 청구서 템플릿 테이블 컬럼 커멘트 (실제 존재하는 컬럼들만)
COMMENT ON COLUMN bms.bill_templates.template_id IS '템플릿 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.bill_templates.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.bill_templates.template_name IS '템플릿명';
COMMENT ON COLUMN bms.bill_templates.template_type IS '템플릿 유형';
COMMENT ON COLUMN bms.bill_templates.is_default IS '기본 템플릿 여부';
COMMENT ON COLUMN bms.bill_templates.is_active IS '활성 상태';
COMMENT ON COLUMN bms.bill_templates.created_at IS '생성 일시';
COMMENT ON COLUMN bms.bill_templates.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.bill_templates.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.bill_templates.updated_by IS '수정자 사용자 ID';

-- 유지보수 계획 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.maintenance_plans.plan_id IS '계획 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.maintenance_plans.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.maintenance_plans.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.maintenance_plans.plan_name IS '계획명';
COMMENT ON COLUMN bms.maintenance_plans.plan_type IS '계획 유형';
COMMENT ON COLUMN bms.maintenance_plans.description IS '계획 설명';
COMMENT ON COLUMN bms.maintenance_plans.start_date IS '시작일';
COMMENT ON COLUMN bms.maintenance_plans.end_date IS '종료일';
COMMENT ON COLUMN bms.maintenance_plans.frequency IS '주기';
COMMENT ON COLUMN bms.maintenance_plans.priority IS '우선순위';
COMMENT ON COLUMN bms.maintenance_plans.estimated_cost IS '예상 비용';
COMMENT ON COLUMN bms.maintenance_plans.assigned_to IS '담당자 사용자 ID';
COMMENT ON COLUMN bms.maintenance_plans.status IS '계획 상태';
COMMENT ON COLUMN bms.maintenance_plans.is_active IS '활성 상태';
COMMENT ON COLUMN bms.maintenance_plans.created_at IS '생성 일시';
COMMENT ON COLUMN bms.maintenance_plans.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.maintenance_plans.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.maintenance_plans.updated_by IS '수정자 사용자 ID';

-- 공통 코드 테이블 컬럼 커멘트 (누락된 컬럼들)
COMMENT ON COLUMN bms.common_codes.parent_code_id IS '상위 코드 식별자 (UUID)';
COMMENT ON COLUMN bms.common_codes.code_level IS '코드 레벨';
COMMENT ON COLUMN bms.common_codes.display_order IS '표시 순서';
COMMENT ON COLUMN bms.common_codes.attributes IS '추가 속성 (JSON)';

-- 민원 첨부파일 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.complaint_attachments.attachment_id IS '첨부파일 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_attachments.complaint_id IS '민원 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_attachments.file_name IS '파일명';
COMMENT ON COLUMN bms.complaint_attachments.original_file_name IS '원본 파일명';
COMMENT ON COLUMN bms.complaint_attachments.file_path IS '파일 경로';
COMMENT ON COLUMN bms.complaint_attachments.file_size IS '파일 크기 (바이트)';
COMMENT ON COLUMN bms.complaint_attachments.mime_type IS 'MIME 타입';
COMMENT ON COLUMN bms.complaint_attachments.upload_date IS '업로드 일시';
COMMENT ON COLUMN bms.complaint_attachments.uploaded_by IS '업로드자 사용자 ID';
COMMENT ON COLUMN bms.complaint_attachments.is_deleted IS '삭제 여부';
COMMENT ON COLUMN bms.complaint_attachments.created_at IS '생성 일시';
COMMENT ON COLUMN bms.complaint_attachments.updated_at IS '수정 일시';

-- 민원 소통 기록 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.complaint_communications.communication_id IS '소통 기록 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_communications.complaint_id IS '민원 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_communications.communication_type IS '소통 유형 (PHONE, EMAIL, VISIT, INTERNAL)';
COMMENT ON COLUMN bms.complaint_communications.direction IS '방향 (INBOUND, OUTBOUND)';
COMMENT ON COLUMN bms.complaint_communications.subject IS '제목';
COMMENT ON COLUMN bms.complaint_communications.content IS '내용';
COMMENT ON COLUMN bms.complaint_communications.sender_name IS '발신자 이름';
COMMENT ON COLUMN bms.complaint_communications.sender_contact IS '발신자 연락처';
COMMENT ON COLUMN bms.complaint_communications.receiver_name IS '수신자 이름';
COMMENT ON COLUMN bms.complaint_communications.receiver_contact IS '수신자 연락처';
COMMENT ON COLUMN bms.complaint_communications.communication_date IS '소통 일시';
COMMENT ON COLUMN bms.complaint_communications.is_internal IS '내부 소통 여부';
COMMENT ON COLUMN bms.complaint_communications.created_at IS '생성 일시';
COMMENT ON COLUMN bms.complaint_communications.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.complaint_communications.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.complaint_communications.updated_by IS '수정자 사용자 ID';

-- 민원 처리 이력 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.complaint_status_history.history_id IS '이력 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_status_history.complaint_id IS '민원 식별자 (UUID)';
COMMENT ON COLUMN bms.complaint_status_history.previous_status IS '이전 상태';
COMMENT ON COLUMN bms.complaint_status_history.new_status IS '새로운 상태';
COMMENT ON COLUMN bms.complaint_status_history.status_change_reason IS '상태 변경 사유';
COMMENT ON COLUMN bms.complaint_status_history.changed_by IS '변경자 사용자 ID';
COMMENT ON COLUMN bms.complaint_status_history.changed_at IS '변경 일시';
COMMENT ON COLUMN bms.complaint_status_history.notes IS '비고';
COMMENT ON COLUMN bms.complaint_status_history.created_at IS '생성 일시';

-- 서비스 예약 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.service_bookings.booking_id IS '예약 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.service_bookings.service_id IS '서비스 식별자 (UUID)';
COMMENT ON COLUMN bms.service_bookings.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.service_bookings.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.service_bookings.unit_id IS '세대 식별자 (UUID)';
COMMENT ON COLUMN bms.service_bookings.booking_number IS '예약 번호';
COMMENT ON COLUMN bms.service_bookings.booker_name IS '예약자 이름';
COMMENT ON COLUMN bms.service_bookings.booker_phone IS '예약자 전화번호';
COMMENT ON COLUMN bms.service_bookings.booker_email IS '예약자 이메일';
COMMENT ON COLUMN bms.service_bookings.booking_date IS '예약일';
COMMENT ON COLUMN bms.service_bookings.booking_time IS '예약 시간';
COMMENT ON COLUMN bms.service_bookings.duration_minutes IS '이용 시간 (분)';
COMMENT ON COLUMN bms.service_bookings.participant_count IS '참가자 수';
COMMENT ON COLUMN bms.service_bookings.special_requests IS '특별 요청사항';
COMMENT ON COLUMN bms.service_bookings.booking_status IS '예약 상태';
COMMENT ON COLUMN bms.service_bookings.confirmation_date IS '확인일';
COMMENT ON COLUMN bms.service_bookings.cancellation_date IS '취소일';
COMMENT ON COLUMN bms.service_bookings.cancellation_reason IS '취소 사유';
COMMENT ON COLUMN bms.service_bookings.service_fee IS '서비스 요금';
COMMENT ON COLUMN bms.service_bookings.payment_status IS '결제 상태';
COMMENT ON COLUMN bms.service_bookings.payment_date IS '결제일';
COMMENT ON COLUMN bms.service_bookings.notes IS '비고';
COMMENT ON COLUMN bms.service_bookings.created_at IS '생성 일시';
COMMENT ON COLUMN bms.service_bookings.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.service_bookings.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.service_bookings.updated_by IS '수정자 사용자 ID';

-- 서비스 피드백 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.service_feedback.feedback_id IS '피드백 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.service_feedback.booking_id IS '예약 식별자 (UUID)';
COMMENT ON COLUMN bms.service_feedback.service_id IS '서비스 식별자 (UUID)';
COMMENT ON COLUMN bms.service_feedback.rating IS '평점 (1-5점)';
COMMENT ON COLUMN bms.service_feedback.feedback_text IS '피드백 내용';
COMMENT ON COLUMN bms.service_feedback.improvement_suggestions IS '개선 제안사항';
COMMENT ON COLUMN bms.service_feedback.would_recommend IS '추천 의향';
COMMENT ON COLUMN bms.service_feedback.feedback_date IS '피드백 일자';
COMMENT ON COLUMN bms.service_feedback.is_anonymous IS '익명 여부';
COMMENT ON COLUMN bms.service_feedback.created_at IS '생성 일시';
COMMENT ON COLUMN bms.service_feedback.updated_at IS '수정 일시';

-- 서비스 이용 통계 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.service_usage_statistics.stat_id IS '통계 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.service_usage_statistics.service_id IS '서비스 식별자 (UUID)';
COMMENT ON COLUMN bms.service_usage_statistics.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.service_usage_statistics.building_id IS '건물 식별자 (UUID)';
COMMENT ON COLUMN bms.service_usage_statistics.stat_period IS '통계 기간';
COMMENT ON COLUMN bms.service_usage_statistics.total_bookings IS '총 예약 수';
COMMENT ON COLUMN bms.service_usage_statistics.completed_bookings IS '완료된 예약 수';
COMMENT ON COLUMN bms.service_usage_statistics.cancelled_bookings IS '취소된 예약 수';
COMMENT ON COLUMN bms.service_usage_statistics.no_show_bookings IS '노쇼 예약 수';
COMMENT ON COLUMN bms.service_usage_statistics.total_participants IS '총 참가자 수';
COMMENT ON COLUMN bms.service_usage_statistics.total_revenue IS '총 수익';
COMMENT ON COLUMN bms.service_usage_statistics.average_rating IS '평균 평점';
COMMENT ON COLUMN bms.service_usage_statistics.utilization_rate IS '이용률 (%)';
COMMENT ON COLUMN bms.service_usage_statistics.peak_usage_time IS '최대 이용 시간대';
COMMENT ON COLUMN bms.service_usage_statistics.popular_days IS '인기 요일 (JSON)';
COMMENT ON COLUMN bms.service_usage_statistics.created_at IS '생성 일시';
COMMENT ON COLUMN bms.service_usage_statistics.updated_at IS '수정 일시';

-- 알림 테이블 컬럼 커멘트 (notifications)
COMMENT ON COLUMN bms.notifications.notification_id IS '알림 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.notifications.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.notifications.recipient_id IS '수신자 사용자 ID';
COMMENT ON COLUMN bms.notifications.notification_type IS '알림 유형';
COMMENT ON COLUMN bms.notifications.title IS '알림 제목';
COMMENT ON COLUMN bms.notifications.message IS '알림 메시지';
COMMENT ON COLUMN bms.notifications.priority IS '우선순위';
COMMENT ON COLUMN bms.notifications.delivery_method IS '전송 방법 (EMAIL, SMS, PUSH, IN_APP)';
COMMENT ON COLUMN bms.notifications.scheduled_at IS '예약 발송 일시';
COMMENT ON COLUMN bms.notifications.sent_at IS '발송 일시';
COMMENT ON COLUMN bms.notifications.delivery_status IS '전송 상태';
COMMENT ON COLUMN bms.notifications.read_at IS '읽은 일시';
COMMENT ON COLUMN bms.notifications.is_read IS '읽음 여부';
COMMENT ON COLUMN bms.notifications.related_entity_type IS '관련 엔티티 유형';
COMMENT ON COLUMN bms.notifications.related_entity_id IS '관련 엔티티 ID';
COMMENT ON COLUMN bms.notifications.action_url IS '액션 URL';
COMMENT ON COLUMN bms.notifications.metadata IS '메타데이터 (JSON)';
COMMENT ON COLUMN bms.notifications.expires_at IS '만료 일시';
COMMENT ON COLUMN bms.notifications.created_at IS '생성 일시';
COMMENT ON COLUMN bms.notifications.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.notifications.created_by IS '생성자 사용자 ID';

-- 건물 그룹 테이블 컬럼 커멘트
COMMENT ON COLUMN bms.building_groups.group_id IS '그룹 고유 식별자 (UUID)';
COMMENT ON COLUMN bms.building_groups.company_id IS '회사 식별자 (UUID)';
COMMENT ON COLUMN bms.building_groups.group_name IS '그룹명';
COMMENT ON COLUMN bms.building_groups.description IS '그룹 설명';
COMMENT ON COLUMN bms.building_groups.group_type IS '그룹 유형';
COMMENT ON COLUMN bms.building_groups.manager_id IS '관리자 사용자 ID';
COMMENT ON COLUMN bms.building_groups.is_active IS '활성 상태';
COMMENT ON COLUMN bms.building_groups.created_at IS '생성 일시';
COMMENT ON COLUMN bms.building_groups.updated_at IS '수정 일시';
COMMENT ON COLUMN bms.building_groups.created_by IS '생성자 사용자 ID';
COMMENT ON COLUMN bms.building_groups.updated_by IS '수정자 사용자 ID';