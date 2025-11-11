import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AiService {
  AiService({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = 'https://YOUR-AI-SERVER-URL.run.app';

  final http.Client _httpClient;
  final String _baseUrl;

  /// AI 서버의 /diagnose 엔드포인트에 이미지를 업로드하고 결과를 반환합니다.
  /// - [imageFile] : 진단할 이미지 파일.
  /// - 타임아웃 : 60초.
  Future<DiagnosisResult> diagnose(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/diagnose');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: imageFile.uri.pathSegments.isNotEmpty
              ? imageFile.uri.pathSegments.last
              : 'diagnosis.jpg',
        ),
      );

    try {
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(const Duration(seconds: 60));

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        return DiagnosisResult.fromJson(json);
      } else {
        throw AiServiceException(
          'AI 서버 오류 (${response.statusCode})',
          responseBody: response.body,
        );
      }
    } on TimeoutException catch (e) {
      throw AiServiceException('AI 서버 응답 시간 초과', cause: e);
    } on SocketException catch (e) {
      throw AiServiceException('네트워크 연결을 확인하세요.', cause: e);
    } on FormatException catch (e) {
      throw AiServiceException('AI 서버 응답 파싱 실패', cause: e);
    } catch (e) {
      throw AiServiceException('알 수 없는 오류가 발생했습니다.', cause: e);
    }
  }
}

class DiagnosisResult {
  DiagnosisResult({
    required this.plantName,
    required this.plantNameKo,
    required this.disease,
    required this.diseaseKo,
    required this.isHealthy,
    required this.confidence,
    required this.recommendations,
  });

  final String plantName;
  final String plantNameKo;
  final String disease;
  final String diseaseKo;
  final bool isHealthy;
  final double confidence;
  final List<String> recommendations;

  factory DiagnosisResult.fromJson(Map<String, dynamic> json) {
    return DiagnosisResult(
      plantName: json['plantName'] as String? ?? '',
      plantNameKo: json['plantNameKo'] as String? ?? '',
      disease: json['disease'] as String? ?? '',
      diseaseKo: json['diseaseKo'] as String? ?? '',
      isHealthy: json['isHealthy'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plantName': plantName,
      'plantNameKo': plantNameKo,
      'disease': disease,
      'diseaseKo': diseaseKo,
      'isHealthy': isHealthy,
      'confidence': confidence,
      'recommendations': recommendations,
    };
  }
}

class AiServiceException implements Exception {
  AiServiceException(
    this.message, {
    this.cause,
    this.responseBody,
  });

  final String message;
  final Object? cause;
  final String? responseBody;

  @override
  String toString() {
    final buffer = StringBuffer('AiServiceException: $message');
    if (responseBody != null && responseBody!.isNotEmpty) {
      buffer.write('\nResponse: $responseBody');
    }
    if (cause != null) {
      buffer.write('\nCause: $cause');
    }
    return buffer.toString();
  }
}

