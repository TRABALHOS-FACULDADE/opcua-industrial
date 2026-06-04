import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../datasources/lamp_rest_datasource.dart';
import '../datasources/lamp_ws_datasource.dart';
import '../models/lamp_state.dart';
import '../models/server_status.dart';
import '../../core/constants/app_constants.dart';

class LampRepository {
  late LampRestDatasource _rest;
  final LampWsDatasource _ws;
  final SharedPreferences _prefs;

  String _host;
  int _port;

  LampRepository({
    required SharedPreferences prefs,
    LampWsDatasource? wsDatasource,
  })  : _prefs = prefs,
        _host = prefs.getString(AppConstants.prefHost) ?? AppConstants.defaultHost,
        _port = prefs.getInt(AppConstants.prefPort) ?? AppConstants.defaultPort,
        _ws = wsDatasource ?? LampWsDatasource() {
    _rest = LampRestDatasource(_buildDio());
  }

  // -------------------------------------------------------------------------
  // Settings
  // -------------------------------------------------------------------------

  String get host => _host;
  int get port => _port;

  Future<void> saveSettings(String host, int port) async {
    await _prefs.setString(AppConstants.prefHost, host);
    await _prefs.setInt(AppConstants.prefPort, port);
    _host = host;
    _port = port;
    _rest = LampRestDatasource(_buildDio());
    reconnectWs();
  }

  // -------------------------------------------------------------------------
  // WebSocket
  // -------------------------------------------------------------------------

  Stream<List<LampState>> get lampStream => _ws.lampStream;
  Stream<WsConnectionStatus> get wsStatusStream => _ws.statusStream;
  WsConnectionStatus get wsStatus => _ws.status;

  void connectWs() => _ws.connect(_host, _port);
  void disconnectWs() => _ws.disconnect();
  void reconnectWs() {
    _ws.disconnect();
    _ws.connect(_host, _port);
  }

  // -------------------------------------------------------------------------
  // REST
  // -------------------------------------------------------------------------

  Future<ServerStatus> getStatus() => _rest.getStatus();
  Future<List<LampState>> getAllLamps() => _rest.getAllLamps();
  Future<bool> setLamp(int id, bool state) => _rest.setLamp(id, state);

  Future<void> setAllLamps(bool state) async {
    await Future.wait([
      for (var i = 1; i <= AppConstants.lampCount; i++) _rest.setLamp(i, state),
    ]);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Dio _buildDio() => Dio(
        BaseOptions(
          baseUrl: 'http://$_host:$_port',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  void dispose() => _ws.dispose();
}
