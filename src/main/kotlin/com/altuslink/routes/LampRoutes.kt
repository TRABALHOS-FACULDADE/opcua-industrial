package com.altuslink.routes

import com.altuslink.model.ApiResponse
import com.altuslink.model.LampCommandData
import com.altuslink.model.LampsData
import com.altuslink.plc.PlcConnectionManager
import com.altuslink.plc.PlcService
import io.ktor.http.*
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.lampRoutes(plcService: PlcService) {

    // GET /api/lamps — returns current state of all lamps
    get("/api/lamps") {
        if (!PlcConnectionManager.isConnected()) {
            call.respond(
                HttpStatusCode.ServiceUnavailable,
                ApiResponse.fail<LampsData>("PLC not connected")
            )
            return@get
        }

        val states = plcService.readAllLamps()
        if (states.isEmpty() && plcService.lampIds().isNotEmpty()) {
            call.respond(
                HttpStatusCode.ServiceUnavailable,
                ApiResponse.fail<LampsData>("Failed to read lamp states from PLC")
            )
            return@get
        }

        call.respond(HttpStatusCode.OK, ApiResponse.ok(LampsData(lamps = states)))
    }

    // POST /api/lamps/{id}/on — turn lamp ON
    post("/api/lamps/{id}/on") {
        handleLampCommand(call, plcService, targetState = true)
    }

    // POST /api/lamps/{id}/off — turn lamp OFF
    post("/api/lamps/{id}/off") {
        handleLampCommand(call, plcService, targetState = false)
    }
}

private suspend fun handleLampCommand(
    call: ApplicationCall,
    plcService: PlcService,
    targetState: Boolean
) {
    val idParam = call.parameters["id"]
    val id = idParam?.toIntOrNull()

    if (id == null) {
        call.respond(
            HttpStatusCode.BadRequest,
            ApiResponse.fail<LampCommandData>("Invalid lamp id: '$idParam'")
        )
        return
    }

    if (id !in 1..plcService.lampIds().size) {
        call.respond(
            HttpStatusCode.NotFound,
            ApiResponse.fail<LampCommandData>("Lamp $id not found (valid range: 1..${plcService.lampIds().size})")
        )
        return
    }

    if (!PlcConnectionManager.isConnected()) {
        call.respond(
            HttpStatusCode.ServiceUnavailable,
            ApiResponse.fail<LampCommandData>("PLC not connected")
        )
        return
    }

    val success = plcService.writeLamp(id, targetState)
    if (success) {
        call.respond(
            HttpStatusCode.OK,
            ApiResponse.ok(LampCommandData(lampId = id, state = targetState))
        )
    } else {
        call.respond(
            HttpStatusCode.InternalServerError,
            ApiResponse.fail<LampCommandData>("Failed to write lamp $id state to PLC")
        )
    }
}
