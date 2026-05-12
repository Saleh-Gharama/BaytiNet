class UsageData {
  final int? id;
  final int timestamp; // Unix timestamp in milliseconds
  final int usageBytes;
  final String ssid;

  UsageData({
    this.id,
    required this.timestamp,
    required this.usageBytes,
    this.ssid = 'Unknown',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'usageBytes': usageBytes,
      'ssid': ssid,
    };
  }

  factory UsageData.fromMap(Map<String, dynamic> map) {
    return UsageData(
      id: map['id'],
      timestamp: map['timestamp'],
      usageBytes: map['usageBytes'],
      ssid: map['ssid'] ?? 'Unknown',
    );
  }
}
