import 'package:dio/dio.dart';
import '../services/storage_service.dart';
import 'constants.dart';

class ApiClient {
  final Dio dio;
  final StorageService _storageService;

  ApiClient({required StorageService storageService})
      : _storageService = storageService,
        dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.baseUrl,
            headers: {
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }
}
