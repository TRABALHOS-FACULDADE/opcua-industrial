package com.altuslink.plugins

import com.altuslink.model.WsLampsMessage
import com.altuslink.plc.PlcService
import io.ktor.server.application.*
import io.ktor.server.routing.*
import io.ktor.server.websocket.*
import io.ktor.websocket.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.ClosedReceiveChannelException
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import org.slf4j.LoggerFactory
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration.Companion.seconds
import kotlin.time.toJavaDuration

private val logger = LoggerFactory.getLogger("com.altuslink.plugins.Sockets")

/**
 * Shared session registry — all active WebSocket clients.
 * A single background coroutine polls the PLC and broadcasts to all sessions.
 */
private val sessions = ConcurrentHashMap<DefaultWebSocketSession, Unit>()

fun Application.configureSockets(
    plcService: PlcService,
    pollingIntervalMs: Long
) {
    install(WebSockets) {
        pingPeriod = 15.seconds.toJavaDuration()
        timeout = 15.seconds.toJavaDuration()
        maxFrameSize = Long.MAX_VALUE
        masking = false
    }

    // -------------------------------------------------------------------------
    // Shared poller — one coroutine, broadcasts to all connected clients.
    // Prevents hammering the PLC with N simultaneous requests for N clients.
    // -------------------------------------------------------------------------
    val pollerJob = launch(Dispatchers.IO) {
        var lastState: Map<String, Boolean> = emptyMap()

        while (isActive) {
            try {
                val currentState = plcService.readAllLamps()

                // Only broadcast when there's at least one client and state changed
                if (sessions.isNotEmpty() && currentState != lastState) {
                    lastState = currentState
                    val message = Json.encodeToString(
                        WsLampsMessage(
                            lamps = currentState,
                            timestamp = Instant.now().toString()
                        )
                    )
                    broadcastToAll(message)
                }
            } catch (e: CancellationException) {
                throw e // Let coroutine cancellation propagate normally
            } catch (e: Exception) {
                logger.error("Poller error: {}", e.message)
            }

            delay(pollingIntervalMs)
        }
    }

    // Cancel the poller when the application stops
    environment.monitor.subscribe(ApplicationStopped) {
        pollerJob.cancel()
        logger.info("WebSocket poller stopped")
    }

    // -------------------------------------------------------------------------
    // WebSocket endpoint
    // -------------------------------------------------------------------------
    routing {
        webSocket("/ws/lamps") {
            logger.info("WebSocket client connected: {}", call.request.local.remoteHost)
            sessions[this] = Unit

            try {
                // Send current state immediately on connect
                val initial = plcService.readAllLamps()
                val initMessage = Json.encodeToString(
                    WsLampsMessage(
                        lamps = initial,
                        timestamp = Instant.now().toString()
                    )
                )
                send(Frame.Text(initMessage))

                // Keep the connection alive until client disconnects
                for (frame in incoming) {
                    // We don't expect messages from the Flutter client —
                    // this loop just keeps the coroutine suspended and handles
                    // incoming pings/close frames automatically.
                    when (frame) {
                        is Frame.Close -> {
                            logger.info("WebSocket client sent close frame")
                            break
                        }
                        else -> { /* ignore */ }
                    }
                }
            } catch (e: ClosedReceiveChannelException) {
                logger.info("WebSocket client disconnected (channel closed)")
            } catch (e: CancellationException) {
                logger.info("WebSocket session cancelled")
            } catch (e: Exception) {
                logger.warn("WebSocket error: {}", e.message)
            } finally {
                sessions.remove(this)
                logger.info("WebSocket session removed — active sessions: {}", sessions.size)
            }
        }
    }
}

// -------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------

private suspend fun broadcastToAll(message: String) {
    val deadSessions = mutableListOf<DefaultWebSocketSession>()

    for (session in sessions.keys) {
        try {
            session.send(Frame.Text(message))
        } catch (e: Exception) {
            logger.warn("Failed to send to session, marking for removal: {}", e.message)
            deadSessions.add(session)
        }
    }

    // Clean up any sessions that failed to receive
    for (dead in deadSessions) {
        sessions.remove(dead)
        try {
            dead.close(CloseReason(CloseReason.Codes.GOING_AWAY, "Send failed"))
        } catch (_: Exception) {}
    }
}
