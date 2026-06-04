import 'package:dio/dio.dart';
import '../models/api_response.dart';
import '../models/lamp_state.dart';
import '../models/server_status.dart';

class PlcNotConnectedException implements Exception {
  const PlcNotConnectedException();
  @override
  String toString() => 'PLC not connected';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  @override
  String toString() => 'Network error: $message';
}

class LampRestDatasource {
  final Dio _dio;

  LampRestDatasource(this._dio);

  Future<ServerStatus> getStatus() async {
    try {
      final response = await _dio.get('/api/status');
      final api = ApiResponse<ServerStatus>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ServerStatus.fromJson(data as Map<String, dynamic>),
      );
      if (!api.isSuccess || api.data == null) {
        throw NetworkException(api.error ?? 'Unknown error from /api/status');
      }
      return api.data!;
    } on DioException catch (e) {
      throw NetworkException(e.message ?? e.type.name);
    }
  }

  Future<List<LampState>> getAllLamps() async {
    try {
      final response = await _dio.get('/api/lamps');
      final json = response.data as Map<String, dynamic>;

      if (response.statusCode == 503) {
        throw const PlcNotConnectedException();
      }

      final api = ApiResponse<List<LampState>>.fromJson(json, (data) {
        final d = data as Map<String, dynamic>;
        return LampState.listFromJson(d['lamps'] as Map<String, dynamic>);
      });

      if (!api.isSuccess || api.data == null) {
        if (api.error?.toLowerCase().contains('not connected') == true) {
          throw const PlcNotConnectedException();
        }
        throw NetworkException(api.error ?? 'Failed to fetch lamps');
      }
      return api.data!;
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) throw const PlcNotConnectedException();
      throw NetworkException(e.message ?? e.type.name);
    }
  }

  Future<bool> setLamp(int id, bool state) async {
    final path = state ? '/api/lamps/$id/on' : '/api/lamps/$id/off';
    try {
      final response = await _dio.post(path);
      final json = response.data as Map<String, dynamic>;

      if (response.statusCode == 503) throw const PlcNotConnectedException();

      final api = ApiResponse<dynamic>.fromJson(json, null);
      return api.isSuccess;
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) throw const PlcNotConnectedException();
      throw NetworkException(e.message ?? e.type.name);
    }
  }
}
