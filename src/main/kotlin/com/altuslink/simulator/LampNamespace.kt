package com.altuslink.simulator

import org.eclipse.milo.opcua.sdk.core.AccessLevel
import org.eclipse.milo.opcua.sdk.core.Reference
import org.eclipse.milo.opcua.sdk.server.OpcUaServer
import org.eclipse.milo.opcua.sdk.server.api.DataItem
import org.eclipse.milo.opcua.sdk.server.api.ManagedNamespaceWithLifecycle
import org.eclipse.milo.opcua.sdk.server.api.MonitoredItem
import org.eclipse.milo.opcua.sdk.server.nodes.UaFolderNode
import org.eclipse.milo.opcua.sdk.server.nodes.UaVariableNode
import org.eclipse.milo.opcua.sdk.server.util.SubscriptionModel
import org.eclipse.milo.opcua.stack.core.Identifiers
import org.eclipse.milo.opcua.stack.core.types.builtin.*
import org.slf4j.LoggerFactory
import kotlin.random.Random

/**
 * Eclipse Milo namespace that exposes Boolean lamp nodes.
 *
 * Node structure (namespace index typically 2):
 *   Objects/
 *     Lamps/              (FolderNode)
 *       Lamp1             (VariableNode — Boolean, R/W)
 *       ...
 *       Lamp{lampCount}
 *
 * Namespace URI: urn:altuslink:simulator:lamps
 *
 * Registration: instantiate and call startup().
 * ManagedNamespaceWithLifecycle handles self-registration into the server's
 * namespace table and address space manager automatically via super().
 */
class LampNamespace(
    server: OpcUaServer,
    private val lampCount: Int
) : ManagedNamespaceWithLifecycle(server, NAMESPACE_URI) {

    private val logger = LoggerFactory.getLogger(LampNamespace::class.java)

    companion object {
        const val NAMESPACE_URI = "urn:altuslink:simulator:lamps"
    }

    private val subscriptionModel = SubscriptionModel(server, this)

    init {
        lifecycleManager.addLifecycle(subscriptionModel)
        lifecycleManager.addStartupTask { createNodes() }
    }

    private fun createNodes() {
        // ------------------------------------------------------------------
        // Lamps folder
        // ------------------------------------------------------------------
        val lampsFolder = UaFolderNode(
            getNodeContext(),
            newNodeId("Lamps"),
            newQualifiedName("Lamps"),
            LocalizedText.english("Lamps")
        )
        getNodeManager().addNode(lampsFolder)

        // Make the folder visible under Objects
        lampsFolder.addReference(
            Reference(
                lampsFolder.nodeId,
                Identifiers.Organizes,
                Identifiers.ObjectsFolder.expanded(),
                false
            )
        )

        // ------------------------------------------------------------------
        // One Boolean VariableNode per lamp
        // ------------------------------------------------------------------
        for (i in 1..lampCount) {
            val initialState = Random.nextBoolean()

            val lampNode = UaVariableNode.UaVariableNodeBuilder(getNodeContext())
                .setNodeId(newNodeId("Lamps/Lamp$i"))
                .setAccessLevel(AccessLevel.READ_WRITE)
                .setUserAccessLevel(AccessLevel.READ_WRITE)
                .setBrowseName(newQualifiedName("Lamp$i"))
                .setDisplayName(LocalizedText.english("Lamp $i"))
                .setDataType(Identifiers.Boolean)
                .setTypeDefinition(Identifiers.BaseDataVariableType)
                .build()

            lampNode.value = DataValue(Variant(initialState))

            getNodeManager().addNode(lampNode)
            lampsFolder.addOrganizes(lampNode)

            logger.debug(
                "Simulator node: ns={};s=Lamps/Lamp{} initial={}",
                namespaceIndex, i, initialState
            )
        }

        logger.info("LampNamespace: {} nodes ready in ns={}", lampCount, namespaceIndex)
    }

    // ------------------------------------------------------------------
    // Subscription model delegation — must use the single shared instance
    // ------------------------------------------------------------------

    override fun onDataItemsCreated(items: MutableList<DataItem>) =
        subscriptionModel.onDataItemsCreated(items)

    override fun onDataItemsModified(items: MutableList<DataItem>) =
        subscriptionModel.onDataItemsModified(items)

    override fun onDataItemsDeleted(items: MutableList<DataItem>) =
        subscriptionModel.onDataItemsDeleted(items)

    override fun onMonitoringModeChanged(items: MutableList<MonitoredItem>) =
        subscriptionModel.onMonitoringModeChanged(items)
}
