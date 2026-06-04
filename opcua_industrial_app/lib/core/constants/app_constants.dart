abstract final class AppConstants {
  // Default server connection values.
  //
  // IMPORTANT — 127.0.0.1 does NOT work from a mobile device/emulator:
  //   Android emulator  → use 10.0.2.2  (maps to host machine localhost)
  //   iOS simulator     → use 127.0.0.1  (shares network stack with Mac)
  //   Physical device   → use the PC's LAN IP (e.g. 192.168.x.x)
  //                       Run `ipconfig` (Windows) to find it.
  static const String defaultHost = '10.0.2.2'; // Android emulator default
  static const int defaultPort = 8080;

  // SharedPreferences keys
  static const String prefHost = 'server_host';
  static const String prefPort = 'server_port';

  // API paths
  static const String pathStatus = '/api/status';
  static const String pathLamps = '/api/lamps';
  static String pathLampOn(int id) => '/api/lamps/$id/on';
  static String pathLampOff(int id) => '/api/lamps/$id/off';

  // WebSocket path
  static String wsPath(String host, int port) => 'ws://$host:$port/ws/lamps';

  // Number of lamps — must match backend lampCount
  static const int lampCount = 8;

  // WS reconnect backoff
  static const Duration wsInitialBackoff = Duration(seconds: 1);
  static const Duration wsMaxBackoff = Duration(seconds: 30);
}
