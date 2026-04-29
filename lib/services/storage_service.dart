import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    await _storage.write(
      key: AppConstants.lastSyncKey,
      value: timestamp.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    final value = await _storage.read(key: AppConstants.lastSyncKey);
    if (value != null) {
      return DateTime.parse(value);
    }
    return null;
  }

  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: AppConstants.deviceIdKey, value: deviceId);
  }

  Future<String?> getDeviceId() async {
    return await _storage.read(key: AppConstants.deviceIdKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
