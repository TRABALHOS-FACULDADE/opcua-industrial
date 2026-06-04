# OpcuaIndustrial

Ktor backend (Kotlin) that bridges a Flutter mobile app to an Altus PLC Kit via OPC UA (Apache PLC4X 0.13.0).

```
Flutter App  <->  Ktor (port 8080)  <->  PLC4X OPC UA  <->  Altus PLC Kit
```

---

## Prerequisites

| Tool | Version |
|------|---------|
| JDK  | 17+     |
| Gradle | 8.x (wrapper included — use `gradlew.bat`) |

---

## Configuration

Edit `src/main/resources/application.conf` before running.

### Simulator (no hardware — development)

```hocon
plc {
  host = "127.0.0.1"
  port = 4840
  nodePrefix = "ns=2;s="
  username = ""
  password = ""
  securityPolicy = "NONE"
  messageSecurity = "NONE"
  lampCount = 8
}
```

### Real Altus PLC Kit

```hocon
plc {
  host = "192.168.x.x"       # IP of the PLC on your network
  port = 4840
  nodePrefix = "ns=2;s="    # Update ns index and path after inspecting with UaExpert
  username = "admin"         # OPC UA credentials configured on the PLC
  password = "yourpassword"
  securityPolicy = "Basic256Sha256"
  messageSecurity = "SIGN_ENCRYPT"
  lampCount = 8

  # Optional — provide your own PKCS12 client certificate.
  # If omitted, PLC4X auto-generates one; you must then trust it
  # manually in the PLC server management UI on the first connection.
  # keyStoreFile = "certs/client.p12"
  # keyStorePassword = "changeit"
}
```

All values can be overridden with environment variables:

| Env var | Config key |
|---------|-----------|
| `PLC_HOST` | `plc.host` |
| `PLC_PORT` | `plc.port` |
| `PLC_USERNAME` | `plc.username` |
| `PLC_PASSWORD` | `plc.password` |
| `PLC_SECURITY_POLICY` | `plc.securityPolicy` |
| `PLC_MESSAGE_SECURITY` | `plc.messageSecurity` |
| `PLC_LAMP_COUNT` | `plc.lampCount` |
| `POLLING_INTERVAL_MS` | `polling.intervalMs` |
| `PORT` | `ktor.deployment.port` |

---

## How to run

### 1. Start the simulator (no hardware needed)

In a first terminal:

```bat
gradlew.bat run -PmainClass=com.altuslink.simulator.PlcSimulatorMainKt
```

> Make sure `plc.securityPolicy = "NONE"` is set in `application.conf`.

### 2. Start the backend

In a second terminal:

```bat
gradlew.bat run
```

The server starts on `http://localhost:8080`.

---

## REST API

All responses follow the structure:

```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

### GET /api/status

```bat
curl http://localhost:8080/api/status
```

```json
{
  "success": true,
  "data": {
    "server": "running",
    "plcConnected": true,
    "plcHost": "127.0.0.1",
    "plcPort": 4840
  },
  "error": null
}
```

### GET /api/lamps

```bat
curl http://localhost:8080/api/lamps
```

```json
{
  "success": true,
  "data": {
    "lamps": {
      "1": true,
      "2": false,
      "3": true,
      "4": false,
      "5": true,
      "6": false,
      "7": true,
      "8": false
    }
  },
  "error": null
}
```

### POST /api/lamps/{id}/on

```bat
curl -X POST http://localhost:8080/api/lamps/1/on
```

```json
{
  "success": true,
  "data": { "lampId": 1, "state": true },
  "error": null
}
```

### POST /api/lamps/{id}/off

```bat
curl -X POST http://localhost:8080/api/lamps/3/off
```

```json
{
  "success": true,
  "data": { "lampId": 3, "state": false },
  "error": null
}
```

---

## WebSocket

Connect to `ws://localhost:8080/ws/lamps`.

### Test with wscat

```bat
npx wscat -c ws://localhost:8080/ws/lamps
```

On connect you receive the current state immediately, then updates whenever any lamp changes:

```json
{
  "lamps": {
    "1": true,
    "2": false,
    "3": true,
    "4": false,
    "5": true,
    "6": false,
    "7": true,
    "8": false
  },
  "timestamp": "2026-06-04T13:00:00.000Z"
}
```

Messages are sent only when the state changes (not every polling tick).

---

## Build

```bat
gradlew.bat build
```

---

## OPC UA Node IDs

> **Placeholder addresses — update before connecting to real hardware.**

The current default addresses follow the pattern:

```
ns=2;s=Lamps/Lamp1
ns=2;s=Lamps/Lamp2
...
ns=2;s=Lamps/Lamp8
```

To find the actual node IDs of the Altus PLC Kit:
1. Connect the PLC to your network
2. Open [UaExpert](https://www.unified-automation.com/products/development-tools/uaexpert.html) (free)
3. Browse the address space under `Objects`
4. Note the namespace index and node identifiers for the lamp outputs
5. Update `plc.nodePrefix` in `application.conf` accordingly

---

## Project structure

```
src/main/kotlin/com/altuslink/
├── Application.kt               Entry point, plugin wiring, config reading
├── model/
│   └── ApiResponse.kt           Shared JSON response types
├── plc/
│   ├── PlcConnectionManager.kt  Singleton OPC UA connection lifecycle
│   └── PlcService.kt            PLC read/write operations (PLC4X builder pattern)
├── plugins/
│   ├── Routing.kt               Route registration
│   └── Sockets.kt               WebSocket + shared PLC poller
├── routes/
│   ├── LampRoutes.kt            GET /api/lamps, POST /api/lamps/{id}/on|off
│   └── StatusRoutes.kt          GET /api/status
└── simulator/
    ├── LampNamespace.kt         Eclipse Milo OPC UA namespace with 8 lamp nodes
    └── PlcSimulator.kt          Simulator server entry point
```
