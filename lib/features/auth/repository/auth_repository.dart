import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../models/auth_model.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        '/polso-health/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }
}
