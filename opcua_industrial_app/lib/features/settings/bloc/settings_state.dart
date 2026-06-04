import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsReady extends SettingsState {
  final String host;
  final int port;
  final bool saved;

  const SettingsReady({
    required this.host,
    required this.port,
    this.saved = false,
  });

  SettingsReady copyWith({String? host, int? port, bool? saved}) =>
      SettingsReady(
        host: host ?? this.host,
        port: port ?? this.port,
        saved: saved ?? this.saved,
      );

  @override
  List<Object?> get props => [host, port, saved];
}
