class WsLampsMessage {
  final Map<String, bool> lamps;
  final String timestamp;

  const WsLampsMessage({required this.lamps, required this.timestamp});

  factory WsLampsMessage.fromJson(Map<String, dynamic> json) {
    final rawLamps = json['lamps'] as Map<String, dynamic>;
    return WsLampsMessage(
      lamps: rawLamps.map((k, v) => MapEntry(k, v as bool)),
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}
