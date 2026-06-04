import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/lamp_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final LampRepository _repository;

  SettingsBloc(this._repository) : super(const SettingsInitial()) {
    on<SettingsLoaded>(_onLoaded);
    on<SettingsSaved>(_onSaved);
  }

  void _onLoaded(SettingsLoaded event, Emitter<SettingsState> emit) {
    emit(SettingsReady(host: _repository.host, port: _repository.port));
  }

  Future<void> _onSaved(
    SettingsSaved event,
    Emitter<SettingsState> emit,
  ) async {
    await _repository.saveSettings(event.host, event.port);
    emit(SettingsReady(host: event.host, port: event.port, saved: true));
  }
}
