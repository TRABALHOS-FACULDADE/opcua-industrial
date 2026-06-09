package com.altuslink.plc

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.apache.plc4x.java.api.messages.PlcReadResponse
import org.apache.plc4x.java.api.messages.PlcWriteResponse
import org.apache.plc4x.java.api.types.PlcResponseCode
import org.slf4j.LoggerFactory
import java.util.concurrent.TimeUnit

/**
 * High-level PLC operations using the PLC4X builder pattern.
 *
 * All PLC calls run on Dispatchers.IO — never blocks the main thread.
 *
 * OPC UA address format: ns={namespace};s={nodeId}
 * Example: ns=2;s=Lamps/Lamp1
 *
 * NOTE: Node IDs are placeholders until confirmed against the Altus PLC Kit
 * address space (inspect with UaExpert or similar OPC UA browser).
 */
class PlcService(
    private val nodePattern: String,
    private val configuredAddresses: List<String>,
    private val lampCount: Int
) {

    private val logger = LoggerFactory.getLogger(PlcService::class.java)

    /** Returns the configured OPC UA NodeId for a lamp index (1-based). */
    fun lampAddress(id: Int): String =
        configuredAddresses.getOrNull(id - 1)
            ?: nodePattern.replace("{id}", id.toString())

    /** Returns lamp IDs 1..lampCount */
    fun lampIds(): List<Int> = (1..lampCount).toList()

    // -------------------------------------------------------------------------
    // Read operations
    // -------------------------------------------------------------------------

    /**
     * Reads all lamp states in a single bulk PLC request.
     *
     * Returns a map of lampId (as String key) -> Boolean state.
     * On PLC failure returns an empty map and logs the error.
     */
    suspend fun readAllLamps(): Map<String, Boolean> = withContext(Dispatchers.IO) {
        val conn = PlcConnectionManager.getConnection()
            ?: return@withContext emptyMap<String, Boolean>().also {
                logger.warn("readAllLamps: no PLC connection available")
            }

        try {
            val builder = conn.readRequestBuilder()
            for (id in lampIds()) {
                val address = lampAddress(id)
                logger.debug("Reading lamp{} from {}", id, address)
                builder.addTagAddress("lamp$id", address)
            }
            val request = builder.build()
            val response: PlcReadResponse = request.execute().get(5000, TimeUnit.MILLISECONDS)

            buildMap {
                for (id in lampIds()) {
                    val alias = "lamp$id"
                    if (response.getResponseCode(alias) == PlcResponseCode.OK) {
                        put(id.toString(), response.getBoolean(alias))
                    } else {
                        logger.warn(
                            "readAllLamps: bad response code for {} — {}",
                            alias, response.getResponseCode(alias)
                        )
                        put(id.toString(), false)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("readAllLamps failed: {}", e.message)
            emptyMap()
        }
    }

    /**
     * Reads the state of a single lamp.
     * Returns null if the lamp ID is out of range or on PLC error.
     */
    suspend fun readLamp(id: Int): Boolean? = withContext(Dispatchers.IO) {
        if (id !in 1..lampCount) {
            logger.warn("readLamp: lamp id {} out of range (1..{})", id, lampCount)
            return@withContext null
        }

        val conn = PlcConnectionManager.getConnection()
            ?: return@withContext null.also {
                logger.warn("readLamp: no PLC connection available")
            }

        try {
            val address = lampAddress(id)
            val request = conn.readRequestBuilder()
                .addTagAddress("lamp$id", address)
                .build()
            val response: PlcReadResponse = request.execute().get(5000, TimeUnit.MILLISECONDS)

            if (response.getResponseCode("lamp$id") == PlcResponseCode.OK) {
                response.getBoolean("lamp$id")
            } else {
                logger.warn("readLamp {}: response code {}", id, response.getResponseCode("lamp$id"))
                null
            }
        } catch (e: Exception) {
            logger.error("readLamp {} failed: {}", id, e.message)
            null
        }
    }

    // -------------------------------------------------------------------------
    // Write operations
    // -------------------------------------------------------------------------

    /**
     * Writes a BOOL value to a lamp node.
     *
     * Returns true on success, false on any error.
     */
    suspend fun writeLamp(id: Int, state: Boolean): Boolean = withContext(Dispatchers.IO) {
        if (id !in 1..lampCount) {
            logger.warn("writeLamp: lamp id {} out of range (1..{})", id, lampCount)
            return@withContext false
        }

        val conn = PlcConnectionManager.getConnection()
            ?: return@withContext false.also {
                logger.warn("writeLamp: no PLC connection available")
            }

        try {
            val address = lampAddress(id)
            val request = conn.writeRequestBuilder()
                .addTagAddress("lamp$id", address, state)
                .build()
            val response: PlcWriteResponse = request.execute().get(5000, TimeUnit.MILLISECONDS)

            val code = response.getResponseCode("lamp$id")
            if (code == PlcResponseCode.OK) {
                logger.debug("writeLamp {}: set to {} — OK", id, state)
                true
            } else {
                logger.error("writeLamp {}: response code {}", id, code)
                false
            }
        } catch (e: Exception) {
            logger.error("writeLamp {} = {} failed: {}", id, state, e.message)
            false
        }
    }

    /** Convenience helpers */
    suspend fun turnOn(id: Int) = writeLamp(id, true)
    suspend fun turnOff(id: Int) = writeLamp(id, false)
}
