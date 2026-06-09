package com.altuslink.plugins

import com.altuslink.plc.PlcService
import com.altuslink.routes.lampRoutes
import com.altuslink.routes.statusRoutes
import io.ktor.server.application.*
import io.ktor.server.routing.*

fun Application.configureRouting(
    plcService: PlcService,
    plcHost: String,
    plcPort: Int
) {
    routing {
        statusRoutes(plcHost = plcHost, plcPort = plcPort)
        lampRoutes(plcService = plcService)
    }
}
