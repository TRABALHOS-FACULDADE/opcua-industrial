import 'package:equatable/equatable.dart';

class ServerStatus extends Equatable {
  final String server;
  final bool plcConnected;
  final String plcHost;
  final int plcPort;

  const ServerStatus({
    required this.server,
    required this.plcConnected,
    required this.plcHost,
    required this.plcPort,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      server: json['server'] as String,
      plcConnected: json['plcConnected'] as bool,
      plcHost: json['plcHost'] as String,
      plcPort: json['plcPort'] as int,
    );
  }

  @override
  List<Object?> get props => [server, plcConnected, plcHost, plcPort];
}
