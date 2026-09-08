class WifiSession {
  final int? id;
  final String ssid;
  final String? bssid;
  final int startTime;
  final int? endTime;
  final int bytesUsed;
  final bool isSynced;

  WifiSession({
    this.id,
    required this.ssid,
    this.bssid,
    required this.startTime,
    this.endTime,
    this.bytesUsed = 0,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ssid': ssid,
      'bssid': bssid,
      'start_time': startTime,
      'end_time': endTime,
      'bytes_used': bytesUsed,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory WifiSession.fromMap(Map<String, dynamic> map) {
    return WifiSession(
      id: map['id'] as int?,
      ssid: map['ssid'] as String? ?? 'Unknown',
      bssid: map['bssid'] as String?,
      startTime: map['start_time'] as int,
      endTime: map['end_time'] as int?,
      bytesUsed: (map['bytes_used'] as int?) ?? 0,
      isSynced: (map['is_synced'] as int?) == 1,
    );
  }

  WifiSession copyWith({
    int? id,
    String? ssid,
    String? bssid,
    int? startTime,
    int? endTime,
    int? bytesUsed,
    bool? isSynced,
  }) {
    return WifiSession(
      id: id ?? this.id,
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      bytesUsed: bytesUsed ?? this.bytesUsed,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
