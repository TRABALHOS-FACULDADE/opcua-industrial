import 'package:equatable/equatable.dart';
import '../../../data/models/lamp_state.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final List<LampState> lamps;
  final bool plcConnected;
  final bool wsConnected;
  /// IDs of lamps currently awaiting a REST response (optimistic UI).
  final Set<int> pendingIds;

  const DashboardLoaded({
    required this.lamps,
    required this.plcConnected,
    this.wsConnected = false,
    this.pendingIds = const {},
  });

  DashboardLoaded copyWith({
    List<LampState>? lamps,
    bool? plcConnected,
    bool? wsConnected,
    Set<int>? pendingIds,
  }) =>
      DashboardLoaded(
        lamps: lamps ?? this.lamps,
        plcConnected: plcConnected ?? this.plcConnected,
        wsConnected: wsConnected ?? this.wsConnected,
        pendingIds: pendingIds ?? this.pendingIds,
      );

  @override
  List<Object?> get props => [lamps, plcConnected, wsConnected, pendingIds];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
