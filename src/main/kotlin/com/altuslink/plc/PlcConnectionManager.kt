package com.altuslink.plc

import org.apache.plc4x.java.api.PlcConnection
import org.apache.plc4x.java.DefaultPlcDriverManager
import org.slf4j.LoggerFactory
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Singleton that owns the single PlcConnection to the OPC UA server.
 *
 * The server still starts if the PLC is unreachable — all methods return
 * meaningful errors in that case instead of crashing.
 */
object PlcConnectionManager {

    private val logger = LoggerFactory.getLogger(PlcConnectionManager::class.java)

    @Volatile
    private var connection: PlcConnection? = null

    @Volatile
    private var configuredHost: String = "127.0.0.1"

    @Volatile
    private var configuredPort: Int = 4840

    private val connected = AtomicBoolean(false)

    /**
     * Establishes the OPC UA connection.
     *
     * Connection string format (PLC4X official spec):
     *   opcua:tcp://{host}:{port}?{options}
     *
     * Security is enabled by default (Basic256Sha256 + SIGN_ENCRYPT).
     * Pass securityPolicy = "NONE" when using the local simulator.
     */
    fun connect(
        host: String,
        port: Int,
        username: String,
        password: String,
        securityPolicy: String,
        messageSecurity: String,
        keyStoreFile: String?,
        keyStorePassword: String?
    ) {
        configuredHost = host
        configuredPort = port

        val url = buildConnectionString(
            host, port, username, password,
            securityPolicy, messageSecurity,
            keyStoreFile, keyStorePassword
        )

        logger.info("Connecting to OPC UA server at opcua:tcp://{}:{} (security={})", host, port, securityPolicy)

        try {
            val conn = DefaultPlcDriverManager().getConnection(url)
            connection = conn
            connected.set(true)
            logger.info("OPC UA connection established successfully")
        } catch (e: Exception) {
            connected.set(false)
            connection = null
            logger.error("Failed to connect to OPC UA server: {}", e.message)
            // Do NOT rethrow — server must start even without PLC
        }
    }

    fun getConnection(): PlcConnection? = connection

    fun isConnected(): Boolean = connected.get() && connection?.isConnected == true

    fun disconnect() {
        try {
            connection?.close()
            logger.info("OPC UA connection closed")
        } catch (e: Exception) {
            logger.warn("Error closing OPC UA connection: {}", e.message)
        } finally {
            connection = null
            connected.set(false)
        }
    }

    fun getHost(): String = configuredHost
    fun getPort(): Int = configuredPort

    // -------------------------------------------------------------------------

    private fun buildConnectionString(
        host: String,
        port: Int,
        username: String,
        password: String,
        securityPolicy: String,
        messageSecurity: String,
        keyStoreFile: String?,
        keyStorePassword: String?
    ): String {
        val params = mutableListOf<String>()

        // Discovery is disabled — most PLCs advertise wrong external IPs (per PLC4X docs)
        params.add("discovery=false")

        if (username.isNotBlank()) {
            params.add("username=${encodeParam(username)}")
            params.add("password=${encodeParam(password)}")
        }

        if (securityPolicy.uppercase() != "NONE") {
            params.add("security-policy=$securityPolicy")
            params.add("message-security=$messageSecurity")
        }

        if (!keyStoreFile.isNullOrBlank()) {
            params.add("key-store-file=${encodeParam(keyStoreFile)}")
            params.add("key-store-type=pkcs12")
            if (!keyStorePassword.isNullOrBlank()) {
                params.add("key-store-password=${encodeParam(keyStorePassword)}")
            }
        }

        val query = params.joinToString("&")
        return "opcua:tcp://$host:$port?$query"
    }

    /** Minimal URL encoding for connection string parameters. */
    private fun encodeParam(value: String): String =
        value.replace("&", "%26").replace("=", "%3D").replace(" ", "%20")
}
