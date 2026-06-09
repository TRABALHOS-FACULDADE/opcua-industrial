package com.altuslink.routes

import com.altuslink.model.ApiResponse
import com.altuslink.model.StatusData
import com.altuslink.plc.PlcConnectionManager
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.statusRoutes(plcHost: String, plcPort: Int) {

    get("/api/status") {
        val data = StatusData(
            server = "running",
            plcConnected = PlcConnectionManager.isConnected(),
            plcHost = plcHost,
            plcPort = plcPort
        )
        call.respond(HttpStatusCode.OK, ApiResponse.ok(data))
    }
}
