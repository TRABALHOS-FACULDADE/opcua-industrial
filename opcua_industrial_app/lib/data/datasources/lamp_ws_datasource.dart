import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/lamp_state.dart';
import '../models/ws_lamps_message.dart';
import '../../core/constants/app_constants.dart';

enum WsConnectionStatus { disconnected, connecting, connected }

class LampWsDatasource {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final _stateController =
      StreamController<List<LampState>>.broadcast();
  final _statusController =
      StreamController<WsConnectionStatus>.broadcast();

  Stream<List<LampState>> get lampStream => _stateController.stream;
  Stream<WsConnectionStatus> get statusStream => _statusController.stream;

  WsConnectionStatus _status = WsConnectionStatus.disconnected;
  WsConnectionStatus get status => _status;

  bool _disposed = false;
  Timer? _reconnectTimer;
  Duration _backoff = AppConstants.wsInitialBackoff;
  String _host = AppConstants.defaultHost;
  int _port = AppConstants.defaultPort;

  void connect(String host, int port) {
    _host = host;
    _port = port;
    _backoff = AppConstants.wsInitialBackoff;
    _reconnectTimer?.cancel();
    _doConnect();
  }

  void _doConnect() {
    if (_disposed) return;

    _updateStatus(WsConnectionStatus.connecting);

    final uri = Uri.parse(AppConstants.wsPath(_host, _port));

    try {
      _channel = WebSocketChannel.connect(uri);
      _updateStatus(WsConnectionStatus.connected);
      _backoff = AppConstants.wsInitialBackoff; // reset on success

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final msg = WsLampsMessage.fromJson(json);
      final states = LampState.listFromJson(msg.lamps);
      if (!_stateController.isClosed) _stateController.add(states);
    } catch (_) {
      // Malformed message — ignore
    }
  }

  void _onError(dynamic error) {
    _updateStatus(WsConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    _updateStatus(WsConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_backoff, () {
      _backoff = Duration(
        seconds: (_backoff.inSeconds * 2).clamp(
          AppConstants.wsInitialBackoff.inSeconds,
          AppConstants.wsMaxBackoff.inSeconds,
        ),
      );
      _doConnect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
    _updateStatus(WsConnectionStatus.disconnected);
  }

  void _updateStatus(WsConnectionStatus s) {
    _status = s;
    if (!_statusController.isClosed) _statusController.add(s);
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _stateController.close();
    _statusController.close();
  }
}
