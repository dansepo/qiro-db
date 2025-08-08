package com.qiro.domain.user.entity

import com.qiro.common.entity.TenantAwareEntity
import jakarta.persistence.*
import jakarta.validation.constraints.Email
import jakarta.validation.constraints.Size
import java.time.LocalDateTime

@Entity
@Table(name = "users")
class User(
    @field:Size(min = 4, max = 50)
    @Column(name = "username", nullable = false, length = 50, unique = true)
    var username: String,

    @Column(name = "password", nullable = false, length = 255)
    var password: String,

    @field:Email
    @field:Size(max = 255)
    @Column(name = "email", nullable = false, length = 255, unique = true)
    var email: String,

    @field:Size(max = 100)
    @Column(name = "full_name", nullable = false, length = 100)
    var fullName: String,

    @Column(name = "phone_number", length = 20)
    var phoneNumber: String? = null,

    @Enumerated(EnumType.STRING)
    @Column(name = "user_role", nullable = false, length = 20)
    var userRole: UserRole,

    @Enumerated(EnumType.STRING)
    @Column(name = "user_status", nullable = false, length = 20)
    var userStatus: UserStatus = UserStatus.ACTIVE,

    @Column(name = "last_login_at")
    var lastLoginAt: LocalDateTime? = null,

    @Column(name = "login_failure_count", nullable = false)
    var loginFailureCount: Int = 0,

    @Column(name = "account_locked_until")
    var accountLockedUntil: LocalDateTime? = null,

    @Column(name = "password_changed_at")
    var passwordChangedAt: LocalDateTime? = null,

    @Column(name = "must_change_password", nullable = false)
    var mustChangePassword: Boolean = false,

    @Column(name = "email_verified", nullable = false)
    var emailVerified: Boolean = false,

    @Column(name = "two_factor_enabled", nullable = false)
    var twoFactorEnabled: Boolean = false,

    @Column(name = "profile_image_url", length = 500)
    var profileImageUrl: String? = null,

    @Column(name = "department", length = 100)
    var department: String? = null,

    @Column(name = "position", length = 100)
    var position: String? = null,

    @Column(name = "notes", columnDefinition = "TEXT")
    var notes: String? = null
) : TenantAwareEntity() {

    companion object {
        private const val MAX_LOGIN_ATTEMPTS = 5
        private const val LOCK_DURATION_MINUTES = 30L
    }

    fun updateProfile(
        fullName: String,
        email: String,
        phoneNumber: String?,
        department: String?,
        position: String?,
        profileImageUrl: String?
    ) {
        this.fullName = fullName
        this.email = email
        this.phoneNumber = phoneNumber
        this.department = department
        this.position = position
        this.profileImageUrl = profileImageUrl
    }

    fun changePassword(newPassword: String) {
        this.password = newPassword
        this.passwordChangedAt = LocalDateTime.now()
        this.mustChangePassword = false
        unlock() // 비밀번호 변경 시 계정 잠금 해제
    }

    fun recordSuccessfulLogin() {
        this.lastLoginAt = LocalDateTime.now()
        unlock()
    }

    fun recordFailedLogin() {
        this.loginFailureCount++
        if (loginFailureCount >= MAX_LOGIN_ATTEMPTS) {
            this.accountLockedUntil = LocalDateTime.now().plusMinutes(LOCK_DURATION_MINUTES)
            this.userStatus = UserStatus.LOCKED
        }
    }

    fun isAccountLocked(): Boolean {
        return userStatus == UserStatus.LOCKED && accountLockedUntil?.isAfter(LocalDateTime.now()) == true
    }

    fun unlock() {
        this.accountLockedUntil = null
        this.loginFailureCount = 0
        if (this.userStatus == UserStatus.LOCKED) {
            this.userStatus = UserStatus.ACTIVE
        }
    }

    fun activate() {
        this.userStatus = UserStatus.ACTIVE
    }

    fun deactivate() {
        this.userStatus = UserStatus.INACTIVE
    }

    fun suspend() {
        this.userStatus = UserStatus.SUSPENDED
    }

    fun verifyEmail() {
        this.emailVerified = true
    }

    fun enableTwoFactor() {
        this.twoFactorEnabled = true
    }

    fun disableTwoFactor() {
        this.twoFactorEnabled = false
    }
}

enum class UserRole(val displayName: String, val permissions: List<String>) {
    SUPER_ADMIN("슈퍼 관리자", listOf("*")),
    COMPANY_ADMIN("회사 관리자", listOf("company:*", "building:*", "user:*")),
    BUILDING_MANAGER("건물 관리자", listOf("building:read", "building:write", "tenant:*", "maintenance:*")),
    ACCOUNTANT("회계 담당자", listOf("billing:*", "payment:*", "report:read")),
    MAINTENANCE_STAFF("유지보수 담당자", listOf("maintenance:*", "facility:*")),
    VIEWER("조회자", listOf("*.read"))
}

enum class UserStatus(val displayName: String) {
    ACTIVE("활성"),
    INACTIVE("비활성"),
    SUSPENDED("정지"),
    LOCKED("잠금"),
    PENDING_VERIFICATION("인증 대기")
}