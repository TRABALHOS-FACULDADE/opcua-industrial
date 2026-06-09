package com.altuslink.model

import kotlinx.serialization.Serializable

@Serializable
data class ApiResponse<T>(
    val success: Boolean,
    val data: T? = null,
    val error: String? = null
) {
    companion object {
        fun <T> ok(data: T) = ApiResponse(success = true, data = data, error = null)
        fun <T> fail(message: String) = ApiResponse<T>(success = false, data = null, error = message)
    }
}

@Serializable
data class StatusData(
    val server: String,
    val plcConnected: Boolean,
    val plcHost: String,
    val plcPort: Int
)

@Serializable
data class LampsData(
    val lamps: Map<String, Boolean>
)

@Serializable
data class LampCommandData(
    val lampId: Int,
    val state: Boolean
)

@Serializable
data class WsLampsMessage(
    val lamps: Map<String, Boolean>,
    val timestamp: String
)
