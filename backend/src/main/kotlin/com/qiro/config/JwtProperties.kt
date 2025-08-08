package com.qiro.config

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.bind.ConstructorBinding

@ConfigurationProperties(prefix = "spring.security.jwt")
data class JwtProperties @ConstructorBinding constructor(
    val secret: String,
    val accessTokenExpiration: Long,
    val refreshTokenExpiration: Long
)