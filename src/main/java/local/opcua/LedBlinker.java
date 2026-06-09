package local.opcua;

import java.util.concurrent.TimeUnit;

import org.apache.plc4x.java.api.PlcConnection;
import org.apache.plc4x.java.api.PlcDriverManager;
import org.apache.plc4x.java.api.messages.PlcWriteRequest;
import org.apache.plc4x.java.api.messages.PlcWriteResponse;
import org.apache.plc4x.java.api.types.PlcResponseCode;

public final class LedBlinker {

    private static final String CONNECTION_STRING =
        "opcua:tcp://192.168.15.1:4840?discovery=false";

    private LedBlinker() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length == 0 || args[0].isBlank()) {
            System.err.println(
                "Missing led1 NodeId. Run salve.py to find it, then pass it here."
            );
            System.err.println(
                "Example: mvn compile exec:java -Dexec.args='ns=3;s=Device.led1;BOOL'"
            );
            return;
        }

        String nodeId = args[0];
        String ledAddress = nodeId.endsWith(";BOOL") ? nodeId : nodeId + ";BOOL";

        try (PlcConnection connection = PlcDriverManager.getDefault()
                .getConnectionManager()
                .getConnection(CONNECTION_STRING)) {

            if (!connection.getMetadata().isWriteSupported()) {
                throw new IllegalStateException("This OPC UA connection does not support writes.");
            }

            System.out.println("Connected. Toggling " + ledAddress);
            boolean state = true;

            while (!Thread.currentThread().isInterrupted()) {
                PlcWriteRequest request = connection.writeRequestBuilder()
                    .addTagAddress("led1", ledAddress, state)
                    .build();

                PlcWriteResponse response = request.execute().get(5, TimeUnit.SECONDS);
                PlcResponseCode responseCode = response.getResponseCode("led1");

                if (responseCode != PlcResponseCode.OK) {
                    throw new IllegalStateException(
                        "Write to " + ledAddress + " failed: " + responseCode
                        + ". Verify the exact NodeId and write permission."
                    );
                }

                System.out.println("led1 = " + state);
                state = !state;

                try {
                    Thread.sleep(2000);
                } catch (InterruptedException exception) {
                    Thread.currentThread().interrupt();
                }
            }
        }
    }
}
