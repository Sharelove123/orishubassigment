class AppConstants {
  static const String baseUrl = 'https://orishub.com/api';
  static const String loginEndpoint = '/polso-health/login';
  static const String submissionEndpoint = '/polso-health/submissions';

  static const String tokenKey = 'auth_token';
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String deviceIdKey = 'device_id';

  static const String submissionType = 'polso health';
  static const String platform = 'android';
  static const String sourceName = 'health_connect';

  static const Duration syncInterval = Duration(hours: 24);
  static const String syncTaskName = 'polso_health_auto_sync';
}
