package com.altuslink

import com.altuslink.plc.PlcConnectionManager
import com.altuslink.plc.PlcService
import com.altuslink.plugins.configureRouting
import com.altuslink.plugins.configureSockets
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.netty.*
import io.ktor.server.plugins.callloging.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.plugins.cors.routing.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import org.slf4j.event.Level

private val logger = LoggerFactory.getLogger("com.altuslink.Application")

fun main(args: Array<String>): Unit = EngineMain.main(args)

fun Application.module() {
    // -------------------------------------------------------------------------
    // Read configuration
    // -------------------------------------------------------------------------
    val plcHost = environment.config.propertyOrNull("plc.host")?.getString() ?: "127.0.0.1"
    val plcPort = environment.config.propertyOrNull("plc.port")?.getString()?.toIntOrNull() ?: 4840
    val plcUsername = environment.config.propertyOrNull("plc.username")?.getString() ?: ""
    val plcPassword = environment.config.propertyOrNull("plc.password")?.getString() ?: ""
    val plcSecurityPolicy = environment.config.propertyOrNull("plc.securityPolicy")?.getString() ?: "Basic256Sha256"
    val plcMessageSecurity = environment.config.propertyOrNull("plc.messageSecurity")?.getString() ?: "SIGN_ENCRYPT"
    val plcKeyStoreFile = environment.config.propertyOrNull("plc.keyStoreFile")?.getString()?.takeIf { it.isNotBlank() }
    val plcKeyStorePassword = environment.config.propertyOrNull("plc.keyStorePassword")?.getString()?.takeIf { it.isNotBlank() }
    val nodePattern = environment.config.propertyOrNull("plc.nodePattern")?.getString()
        ?: "ns=4;s=|var|XP340.Application.OPCUA.led{id}"
    val nodeAddresses = environment.config.propertyOrNull("plc.nodeAddresses")
        ?.getString()
        ?.split(",")
        ?.map(String::trim)
        ?.filter(String::isNotEmpty)
        .orEmpty()
    val lampCount = environment.config.propertyOrNull("plc.lampCount")?.getString()?.toIntOrNull() ?: 8
    val pollingIntervalMs = environment.config.propertyOrNull("polling.intervalMs")?.getString()?.toLongOrNull() ?: 1000L

    val plcService = PlcService(
        nodePattern = nodePattern,
        configuredAddresses = nodeAddresses,
        lampCount = lampCount
    )
    logger.info(
        "Configured OPC UA lamp addresses: {}",
        plcService.lampIds().joinToString { id -> "lamp$id=${plcService.lampAddress(id)}" }
    )

    // -------------------------------------------------------------------------
    // Install Ktor plugins
    // -------------------------------------------------------------------------
    install(CORS) {
        // Allow any host — this backend is internal/lab use only.
        // Tighten to specific origins in production.
        anyHost()
        allowHeader(HttpHeaders.ContentType)
        allowHeader(HttpHeaders.Authorization)
        allowMethod(HttpMethod.Get)
        allowMethod(HttpMethod.Post)
        allowMethod(HttpMethod.Options)
    }

    install(CallLogging) {
        level = Level.INFO
    }

    install(ContentNegotiation) {
        json(Json {
            prettyPrint = false
            isLenient = true
            ignoreUnknownKeys = true
        })
    }

    // -------------------------------------------------------------------------
    // Connect to PLC asynchronously so the server starts immediately
    // even if the PLC is unreachable
    // -------------------------------------------------------------------------
    launch(Dispatchers.IO) {
        PlcConnectionManager.connect(
            host = plcHost,
            port = plcPort,
            username = plcUsername,
            password = plcPassword,
            securityPolicy = plcSecurityPolicy,
            messageSecurity = plcMessageSecurity,
            keyStoreFile = plcKeyStoreFile,
            keyStorePassword = plcKeyStorePassword
        )
    }

    // -------------------------------------------------------------------------
    // Graceful shutdown — close PLC connection when Ktor stops
    // -------------------------------------------------------------------------
    environment.monitor.subscribe(ApplicationStopped) {
        logger.info("Application stopping — disconnecting from PLC")
        PlcConnectionManager.disconnect()
    }

    // -------------------------------------------------------------------------
    // Routes and WebSocket
    // -------------------------------------------------------------------------
    configureSockets(plcService = plcService, pollingIntervalMs = pollingIntervalMs)
    configureRouting(plcService = plcService, plcHost = plcHost, plcPort = plcPort)
}
