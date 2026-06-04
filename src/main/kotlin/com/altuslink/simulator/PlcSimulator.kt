package com.altuslink.simulator

import org.eclipse.milo.opcua.sdk.server.OpcUaServer
import org.eclipse.milo.opcua.sdk.server.api.config.OpcUaServerConfig
import org.eclipse.milo.opcua.sdk.server.identity.AnonymousIdentityValidator
import org.eclipse.milo.opcua.stack.core.security.SecurityPolicy
import org.eclipse.milo.opcua.stack.core.types.builtin.LocalizedText
import org.eclipse.milo.opcua.stack.core.types.enumerated.MessageSecurityMode
import org.eclipse.milo.opcua.stack.server.EndpointConfiguration
import org.slf4j.LoggerFactory

/**
 * Standalone OPC UA server simulator built on Eclipse Milo.
 *
 * Purpose: allows Flutter development and integration testing
 * without physical Altus PLC hardware.
 *
 * Exposes 8 Boolean nodes in namespace ns=2:
 *   ns=2;s=Lamps/Lamp1 … ns=2;s=Lamps/Lamp8
 *
 * Security: NONE (no TLS, anonymous login) — development only.
 * When connecting the Ktor backend to this simulator, set in application.conf:
 *   plc.securityPolicy = "NONE"
 *   plc.username = ""
 *   plc.password = ""
 *
 * Usage:
 *   PlcSimulator.start()
 *   // ... run backend against it ...
 *   PlcSimulator.stop()
 *
 * Or run standalone via the main() function at the bottom of this file.
 */
object PlcSimulator {

    private val logger = LoggerFactory.getLogger(PlcSimulator::class.java)

    const val BIND_ADDRESS = "0.0.0.0"
    const val PORT = 4840
    const val LAMP_COUNT = 8

    @Volatile private var server: OpcUaServer? = null
    @Volatile private var namespace: LampNamespace? = null

    fun start() {
        if (server != null) {
            logger.warn("Simulator already running")
            return
        }

        logger.info("Starting OPC UA simulator on port {}", PORT)

        val endpoint = EndpointConfiguration.newBuilder()
            .setBindAddress(BIND_ADDRESS)
            .setBindPort(PORT)
            .setHostname("127.0.0.1")
            .setPath("/")
            .setSecurityPolicy(SecurityPolicy.None)
            .setSecurityMode(MessageSecurityMode.None)
            .build()

        val config = OpcUaServerConfig.builder()
            .setApplicationName(LocalizedText.english("AltusLink PLC Simulator"))
            .setApplicationUri("urn:altuslink:simulator")
            .setEndpoints(setOf(endpoint))
            .setIdentityValidator(AnonymousIdentityValidator.INSTANCE)
            .build()

        val opcUaServer = OpcUaServer(config)

        // Register the lamp namespace — ManagedNamespaceWithLifecycle handles
        // self-registration into the server's namespace table via super()
        val ns = LampNamespace(opcUaServer, LAMP_COUNT)
        ns.startup()

        opcUaServer.startup().get()

        server = opcUaServer
        namespace = ns

        logger.info(
            "OPC UA simulator running — {} lamps available at ns=2;s=Lamps/Lamp1..Lamp{}",
            LAMP_COUNT, LAMP_COUNT
        )
        logger.info("Connect with: opcua:tcp://127.0.0.1:{}?discovery=false", PORT)
    }

    fun stop() {
        namespace?.shutdown()
        namespace = null
        server?.shutdown()?.get()
        server = null
        logger.info("OPC UA simulator stopped")
    }

    fun isRunning(): Boolean = server != null
}

/** Runs the simulator as a standalone process. */
fun main() {
    PlcSimulator.start()
    println("\nSimulator running on opc.tcp://127.0.0.1:${PlcSimulator.PORT}")
    println("Press ENTER to stop.\n")
    readLine()
    PlcSimulator.stop()
}
