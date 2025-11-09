import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AiService {
  // AI API 엔드포인트 설정
  // 개발: 로컬 서버 또는 테스트 서버
  // 프로덕션: 실제 배포된 AI 서버
  static const String _baseUrl = 'https://your-ai-api-server.com/api/v1';
  // 로컬 테스트용: 'http://localhost:8000/api/v1'
  // 또는: 'http://10.0.2.2:8000/api/v1' (Android 에뮬레이터용)
  
  static const Duration _timeout = Duration(seconds: 30);

  // AI 진단 API 호출
  Future<DiagnosisResult?> diagnosePlant(String imageUrl) async {
    try {
      print('🤖 Calling AI diagnosis API...');
      
      final response = await http
          .post(
            Uri.parse('$_baseUrl/diagnose'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'imageUrl': imageUrl,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ AI diagnosis successful');
        return DiagnosisResult.fromJson(jsonData);
      } else {
        print('❌ AI diagnosis failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ AI Service Error: $e');
      return null;
    }
  }

  // 이미지 파일로 직접 진단 (Multipart)
  Future<DiagnosisResult?> diagnosePlantWithFile(File imageFile) async {
    try {
      print('🤖 Calling AI diagnosis API with file...');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/diagnose'),
      );

      // 이미지 파일 추가
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // 요청 전송
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('✅ AI diagnosis successful');
        return DiagnosisResult.fromJson(jsonData);
      } else {
        print('❌ AI diagnosis failed: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ AI Service Error: $e');
      return null;
    }
  }

  // 서버 상태 확인
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ AI Server healthy: ${data['status']}');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ AI Server health check failed: $e');
      return false;
    }
  }

  // 더미 진단 결과 생성 (AI 서버가 없을 때 테스트용)
  Future<DiagnosisResult> getDummyDiagnosis() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final dummyResults = [
      DiagnosisResult(
        disease: 'Nutrient Deficiency',
        confidence: 0.85,
        recommendations: [
          'Add liquid fertilizer weekly',
          'Increase sunlight exposure',
        ],
        severity: 'Medium',
      ),
      DiagnosisResult(
        disease: 'Leaf Spot Disease',
        confidence: 0.78,
        recommendations: [
          'Remove affected leaves',
          'Apply fungicide spray',
          'Reduce watering frequency',
        ],
        severity: 'High',
      ),
      DiagnosisResult(
        disease: 'Healthy Plant',
        confidence: 0.92,
        recommendations: [
          'Continue current care routine',
          'Monitor for changes',
        ],
        severity: 'None',
      ),
    ];

    // 랜덤으로 하나 선택
    return dummyResults[DateTime.now().millisecond % dummyResults.length];
  }
}

// 진단 결과 모델
class DiagnosisResult {
  final String disease;
  final double confidence;
  final List<String> recommendations;
  final String severity;

  DiagnosisResult({
    required this.disease,
    required this.confidence,
    required this.recommendations,
    required this.severity,
  });

  // JSON에서 객체 생성
  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      disease: json['disease'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      severity: json['severity'] ?? 'Unknown',
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'disease': disease,
      'confidence': confidence,
      'recommendations': recommendations,
      'severity': severity,
    };
  }

  // 신뢰도를 퍼센트로 표시
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}

