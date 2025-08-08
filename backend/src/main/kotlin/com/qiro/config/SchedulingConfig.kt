package com.qiro.config

import org.springframework.context.annotation.Configuration
import org.springframework.scheduling.annotation.EnableAsync
import org.springframework.scheduling.annotation.EnableScheduling

/**
 * 스케줄링 설정
 * 알림 시스템의 주기적 작업을 위한 스케줄링을 활성화합니다.
 */
@Configuration
@EnableScheduling
@EnableAsync
class SchedulingConfig