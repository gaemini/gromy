class DiagnosisHistory {
  final String id;
  final String userId;
  final String imageUrl;
  final String disease;
  final double confidence;
  final List<String> recommendations;
  final String severity;
  final DateTime timestamp;

  DiagnosisHistory({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.disease,
    required this.confidence,
    required this.recommendations,
    required this.severity,
    required this.timestamp,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'disease': disease,
      'confidence': confidence,
      'recommendations': recommendations,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // JSON에서 객체 생성
  factory DiagnosisHistory.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistory(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      disease: json['disease'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      severity: json['severity'] ?? 'Unknown',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  // 신뢰도를 퍼센트로 표시
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}

