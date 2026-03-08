import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import '../models/turn_response.dart';

class ApiClient {
  final Dio _dio;
  static const String baseUrl = 'https://api.sahayak-ai.gov.in';

  ApiClient(this._dio);

  Future<TurnResponse> submitVoiceTurn(File audioFile) async {
    String fileName = basename(audioFile.path);
    FormData formData = FormData.fromMap({
      "audio": await MultipartFile.fromFile(audioFile.path, filename: fileName),
    });

    try {
      final response = await _dio.post('/voice/turn', data: formData);
      return TurnResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSessionHistory() async {
    try {
      final response = await _dio.get('/sessions/history');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      return []; // Return empty if failed for mock purposes
    }
  }
}
