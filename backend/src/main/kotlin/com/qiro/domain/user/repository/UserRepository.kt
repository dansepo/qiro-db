package com.qiro.domain.user.repository

import com.qiro.domain.user.entity.User
import com.qiro.domain.user.entity.UserStatus
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface UserRepository : JpaRepository<User, UUID> {

    fun findByUsername(username: String): Optional<User>

    fun findByEmail(email: String): Optional<User>
    
    fun findByUsernameAndUserStatus(username: String, userStatus: UserStatus): Optional<User>

    fun findByCompanyIdAndUserStatus(companyId: UUID, userStatus: UserStatus, pageable: Pageable): Page<User>

    fun existsByUsername(username: String): Boolean

    fun existsByEmail(email: String): Boolean

    fun existsByUsernameAndIdNot(username: String, id: UUID): Boolean

    fun existsByEmailAndIdNot(email: String, id: UUID): Boolean

    @Query(
        value = """            SELECT * FROM users u
            WHERE u.company_id = :companyId
            AND u.user_status = :#{#userStatus.name()}
            AND (
                u.username ILIKE CONCAT('%', :search, '%') OR
                u.full_name ILIKE CONCAT('%', :search, '%') OR
                u.email ILIKE CONCAT('%', :search, '%')
            )
        """,
        countQuery = """            SELECT count(u.id) FROM users u
            WHERE u.company_id = :companyId
            AND u.user_status = :#{#userStatus.name()}
            AND (
                u.username ILIKE CONCAT('%', :search, '%') OR
                u.full_name ILIKE CONCAT('%', :search, '%') OR
                u.email ILIKE CONCAT('%', :search, '%')
            )
        """,
        nativeQuery = true
    )
    fun findByCompanyIdAndUserStatusAndSearch(
        @Param("companyId") companyId: UUID,
        @Param("userStatus") userStatus: UserStatus,
        @Param("search") search: String,
        pageable: Pageable
    ): Page<User>

    fun countByCompanyIdAndUserStatus(companyId: UUID, userStatus: UserStatus): Long
}