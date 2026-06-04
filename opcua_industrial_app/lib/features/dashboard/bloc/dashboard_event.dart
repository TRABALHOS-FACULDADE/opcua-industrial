import 'package:equatable/equatable.dart';
import '../../../data/models/lamp_state.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load: fetch status + lamps, subscribe WS.
class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

/// User flipped a single LED toggle.
class LampToggleRequested extends DashboardEvent {
  final int id;
  final bool newState;
  const LampToggleRequested({required this.id, required this.newState});
  @override
  List<Object?> get props => [id, newState];
}

/// "ALL ON" or "ALL OFF" button pressed.
class AllLampsToggleRequested extends DashboardEvent {
  final bool state;
  const AllLampsToggleRequested({required this.state});
  @override
  List<Object?> get props => [state];
}

/// Live update pushed by WebSocket.
class WsMessageReceived extends DashboardEvent {
  final List<LampState> lamps;
  const WsMessageReceived(this.lamps);
  @override
  List<Object?> get props => [lamps];
}

/// WS connection status changed.
class WsStatusChanged extends DashboardEvent {
  final bool connected;
  const WsStatusChanged({required this.connected});
  @override
  List<Object?> get props => [connected];
}

/// Pull-to-refresh or retry button.
class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}
