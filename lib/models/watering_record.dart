class WateringRecord {
  final String id;
  final String plantId;
  final DateTime timestamp;
  final String? note;

  WateringRecord({
    required this.id,
    required this.plantId,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory WateringRecord.fromJson(Map<String, dynamic> json) {
    return WateringRecord(
      id: json['id'] ?? '',
      plantId: json['plantId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      note: json['note'],
    );
  }
}

