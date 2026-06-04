import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/lamp_ws_datasource.dart';
import '../../../data/models/lamp_state.dart';
import '../../../data/repositories/lamp_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final LampRepository _repository;

  StreamSubscription<List<LampState>>? _wsSub;
  StreamSubscription<WsConnectionStatus>? _wsStatusSub;

  DashboardBloc(this._repository) : super(const DashboardInitial()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefresh);
    on<LampToggleRequested>(_onLampToggle);
    on<AllLampsToggleRequested>(_onAllLampsToggle);
    on<WsMessageReceived>(_onWsMessage);
    on<WsStatusChanged>(_onWsStatus);
  }

  // -------------------------------------------------------------------------

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    await _loadAndSubscribe(emit);
  }

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _loadAndSubscribe(emit);
  }

  Future<void> _loadAndSubscribe(Emitter<DashboardState> emit) async {
    try {
      final status = await _repository.getStatus();

      final lamps = status.plcConnected
          ? await _repository.getAllLamps()
          : _emptyLamps();

      emit(DashboardLoaded(
        lamps: lamps,
        plcConnected: status.plcConnected,
        wsConnected: false,
      ));

      _subscribeWs();
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  void _subscribeWs() {
    _wsSub?.cancel();
    _wsStatusSub?.cancel();

    _repository.connectWs();

    _wsSub = _repository.lampStream.listen((lamps) {
      add(WsMessageReceived(lamps));
    });

    _wsStatusSub = _repository.wsStatusStream.listen((status) {
      add(WsStatusChanged(
        connected: status == WsConnectionStatus.connected,
      ));
    });
  }

  // -------------------------------------------------------------------------

  Future<void> _onLampToggle(
    LampToggleRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    // Optimistic update
    final optimistic = current.lamps
        .map((l) => l.id == event.id ? l.copyWith(isOn: event.newState) : l)
        .toList();
    final pending = {...current.pendingIds, event.id};
    emit(current.copyWith(lamps: optimistic, pendingIds: pending));

    try {
      await _repository.setLamp(event.id, event.newState);
    } catch (_) {
      // Rollback on failure
      final rollback = optimistic
          .map((l) => l.id == event.id ? l.copyWith(isOn: !event.newState) : l)
          .toList();
      final newPending = {...pending}..remove(event.id);
      emit(current.copyWith(lamps: rollback, pendingIds: newPending));
      return;
    }

    final newPending = {...pending}..remove(event.id);
    emit((state as DashboardLoaded).copyWith(pendingIds: newPending));
  }

  Future<void> _onAllLampsToggle(
    AllLampsToggleRequested event,
    Emitter<DashboardState> emit,
  ) async {
    final current = state;
    if (current is! DashboardLoaded) return;

    // Optimistic: flip all
    final optimistic = current.lamps
        .map((l) => l.copyWith(isOn: event.state))
        .toList();
    final allPending = current.lamps.map((l) => l.id).toSet();
    emit(current.copyWith(lamps: optimistic, pendingIds: allPending));

    try {
      await _repository.setAllLamps(event.state);
    } catch (_) {
      // Rollback
      emit(current);
      return;
    }

    emit((state as DashboardLoaded).copyWith(pendingIds: {}));
  }

  void _onWsMessage(
    WsMessageReceived event,
    Emitter<DashboardState> emit,
  ) {
    final current = state;
    if (current is! DashboardLoaded) return;

    // Don't overwrite lamps that are still pending a REST response
    final merged = event.lamps.map((incoming) {
      if (current.pendingIds.contains(incoming.id)) {
        return current.lamps.firstWhere((l) => l.id == incoming.id,
            orElse: () => incoming);
      }
      return incoming;
    }).toList();

    emit(current.copyWith(lamps: merged, plcConnected: true));
  }

  void _onWsStatus(
    WsStatusChanged event,
    Emitter<DashboardState> emit,
  ) {
    final current = state;
    if (current is! DashboardLoaded) return;
    emit(current.copyWith(wsConnected: event.connected));
  }

  // -------------------------------------------------------------------------

  static List<LampState> _emptyLamps() => [
        for (var i = 1; i <= AppConstants.lampCount; i++)
          LampState(id: i, isOn: false),
      ];

  @override
  Future<void> close() {
    _wsSub?.cancel();
    _wsStatusSub?.cancel();
    _repository.disconnectWs();
    return super.close();
  }
}
