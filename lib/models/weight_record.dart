class WeightRecord {
  final String id;
  final String profileId;
  final double weightKg;
  final int timestamp;

  const WeightRecord({
    required this.id,
    required this.profileId,
    required this.weightKg,
    required this.timestamp,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'weightKg': weightKg,
        'timestamp': timestamp,
      };

  factory WeightRecord.fromJson(Map<String, dynamic> json) => WeightRecord(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        weightKg: (json['weightKg'] as num).toDouble(),
        timestamp: json['timestamp'] as int,
      );
}
