import asyncio
from asyncua import Client

# Define your server endpoint URL
SERVER_URL = "opc.tcp://192.168.15.1:4840"


async def browse_node(node, depth=0, max_depth=10):
    """Recursively print nodes below the given OPC UA node."""
    try:
        display_name = await node.read_display_name()
        node_class = await node.read_node_class()
        print(
            f"{'  ' * depth}"
            f"{display_name.Text} | {node.nodeid} | {node_class.name}"
        )

        if depth >= max_depth:
            return

        for child in await node.get_children():
            await browse_node(child, depth + 1, max_depth)
    except Exception as exc:
        print(f"{'  ' * depth}Could not browse {node.nodeid}: {exc}")


async def find_node_by_name(node, target_name):
    """Find the first descendant whose browse or display name matches."""
    try:
        browse_name = await node.read_browse_name()
        display_name = await node.read_display_name()

        if (
            browse_name.Name.casefold() == target_name.casefold()
            or display_name.Text.casefold() == target_name.casefold()
        ):
            return node

        for child in await node.get_children():
            found = await find_node_by_name(child, target_name)
            if found is not None:
                return found
    except Exception:
        pass

    return None


async def main():
    # Use context manager to automatically handle connection and cleanup
    async with Client(url=SERVER_URL) as client:
        print("Connected to OPC UA Server!")

        led1 = await find_node_by_name(client.nodes.objects, "led1")
        if led1 is None:
            print("Node 'led1' was not found.")
        else:
            print(f"Found led1 NodeId: {led1.nodeid.to_string()}")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nStopped.")
