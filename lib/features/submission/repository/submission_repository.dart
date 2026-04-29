import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';
import '../../../models/submission_model.dart';

class SubmissionRepository {
  final ApiClient _apiClient;

  SubmissionRepository(this._apiClient);

  Future<SubmissionResponse> submitData({
    required String type,
    required String deviceId,
    required Map<String, dynamic> payload,
  }) async {
    final payloadJson = jsonEncode(payload);

    debugPrint('=== SUBMISSION DEBUG ===');
    debugPrint('type: $type');
    debugPrint('device_id: $deviceId');
    debugPrint('payload: $payloadJson');
    debugPrint('=======================');

    try {
      final formData = FormData.fromMap({
        'type': type,
        'device_id': deviceId,
        'payload': payloadJson,
      });

      final response = await _apiClient.dio.post(
        '/polso-health/submissions',
        data: formData,
      );

      debugPrint('=== RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Data: ${response.data}');
      debugPrint('================');

      return SubmissionResponse.fromJson(response.data);
    } on DioException catch (e) {
      debugPrint('=== ERROR ===');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Data: ${e.response?.data}');
      debugPrint('=============');
      throw e.response?.data?['message'] ?? e.message ?? 'Submission failed';
    }
  }
}
