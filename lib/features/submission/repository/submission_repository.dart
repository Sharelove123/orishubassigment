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
      // Send as raw JSON body with Content-Type: application/json
      final response = await _apiClient.dio.post(
        '/polso-health/submissions',
        data: {
          'type': type,
          'device_id': deviceId,
          'payload': payload,
        },
        options: Options(
          contentType: 'application/json',
        ),
      );
      return SubmissionResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data?['message'] ?? e.message ?? 'Submission failed';
    }
  }
}
