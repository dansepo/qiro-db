package com.qiro.common.dto

import org.springframework.data.domain.Page

data class PagedResponse<T>(
    val content: List<T>,
    val page: Int,
    val size: Int,
    val totalElements: Long,
    val totalPages: Int,
    val first: Boolean,
    val last: Boolean,
    val numberOfElements: Int,
    val empty: Boolean
) {
    companion object {
        fun <T> of(page: Page<T>): PagedResponse<T> {
            return PagedResponse(
                content = page.content,
                page = page.number,
                size = page.size,
                totalElements = page.totalElements,
                totalPages = page.totalPages,
                first = page.isFirst,
                last = page.isLast,
                numberOfElements = page.numberOfElements,
                empty = page.isEmpty
            )
        }
        
        fun <T, R> of(page: Page<T>, mapper: (T) -> R): PagedResponse<R> {
            return PagedResponse(
                content = page.content.map(mapper),
                page = page.number,
                size = page.size,
                totalElements = page.totalElements,
                totalPages = page.totalPages,
                first = page.isFirst,
                last = page.isLast,
                numberOfElements = page.numberOfElements,
                empty = page.isEmpty
            )
        }
    }
}