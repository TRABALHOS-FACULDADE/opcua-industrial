import 'package:equatable/equatable.dart';

class LampState extends Equatable {
  final int id;
  final bool isOn;

  const LampState({required this.id, required this.isOn});

  LampState copyWith({bool? isOn}) =>
      LampState(id: id, isOn: isOn ?? this.isOn);

  /// Parses the backend map  { "1": true, "2": false, ... }
  static List<LampState> listFromJson(Map<String, dynamic> lampsMap) {
    return lampsMap.entries
        .map((e) => LampState(id: int.parse(e.key), isOn: e.value as bool))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  List<Object?> get props => [id, isOn];
}
