import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoaded extends SettingsEvent {
  const SettingsLoaded();
}

class SettingsSaved extends SettingsEvent {
  final String host;
  final int port;
  const SettingsSaved({required this.host, required this.port});
  @override
  List<Object?> get props => [host, port];
}
