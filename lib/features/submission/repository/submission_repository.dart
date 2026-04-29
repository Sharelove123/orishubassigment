import 'dart:convert';
import 'package:dio/dio.dart';
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
    try {
      final formData = FormData.fromMap({
        'type': type,
        'device_id': deviceId,
        'payload': jsonEncode(payload),
      });

      final response = await _apiClient.dio.post(
        '/polso-health/submissions',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      return SubmissionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Submission failed';
    }
  }
}
