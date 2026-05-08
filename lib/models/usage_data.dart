class UsageData {
  final int? id;
  final int timestamp; // Unix timestamp in milliseconds
  final int usageBytes;

  UsageData({this.id, required this.timestamp, required this.usageBytes});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'usageBytes': usageBytes,
    };
  }

  factory UsageData.fromMap(Map<String, dynamic> map) {
    return UsageData(
      id: map['id'],
      timestamp: map['timestamp'],
      usageBytes: map['usageBytes'],
    );
  }
}
