import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants.dart';
import 'health_service.dart';
import 'location_service.dart';
import 'storage_service.dart';
import '../features/submission/repository/submission_repository.dart';
import '../core/api_client.dart';

class SyncService {
  final HealthService _healthService;
  final LocationService _locationService;
  final StorageService _storageService;
  final SubmissionRepository _submissionRepository;

  SyncService({
    required HealthService healthService,
    required LocationService locationService,
    required StorageService storageService,
    required SubmissionRepository submissionRepository,
  })  : _healthService = healthService,
        _locationService = locationService,
        _storageService = storageService,
        _submissionRepository = submissionRepository;

  /// Initialize background sync worker
  static Future<void> initializeBackgroundSync() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      AppConstants.syncTaskName,
      AppConstants.syncTaskName,
      frequency: AppConstants.syncInterval,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    debugPrint('Background sync registered');
  }

  /// Cancel background sync
  static Future<void> cancelBackgroundSync() async {
    await Workmanager().cancelByUniqueName(AppConstants.syncTaskName);
  }

  /// Perform a full sync (manual or background)
  Future<SyncResult> performSync() async {
    try {
      // Check network
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        return SyncResult(success: false, message: 'No internet connection');
      }

      // Get last sync time for incremental sync
      final lastSync = await _storageService.getLastSyncTimestamp();

      // Read health data (incremental)
      final healthData = await _healthService.fetchHealthData(since: lastSync);

      // Read location
      final locationData = await _locationService.getCurrentLocation();
      if (locationData != null) {
        healthData['location'] = [locationData];
      } else {
        healthData['location'] = [];
      }

      // Get device ID
      final deviceId = await _storageService.getDeviceId() ?? '123456';

      // Submit to API
      final result = await _submissionRepository.submitData(
        type: AppConstants.submissionType,
        deviceId: deviceId,
        payload: healthData,
      );

      // Save sync timestamp
      await _storageService.saveLastSyncTimestamp(DateTime.now());

      debugPrint('Sync completed: ${result.message}');
      return SyncResult(success: true, message: result.message);
    } catch (e) {
      debugPrint('Sync failed: $e');
      return SyncResult(success: false, message: e.toString());
    }
  }
}

class SyncResult {
  final bool success;
  final String message;

  SyncResult({required this.success, required this.message});
}

/// Top-level callback for WorkManager background execution
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint('Background sync task started: $task');
      final storageService = StorageService();
      final apiClient = ApiClient(storageService: storageService);
      final submissionRepo = SubmissionRepository(apiClient);
      final healthService = HealthService();
      final locationService = LocationService();

      final syncService = SyncService(
        healthService: healthService,
        locationService: locationService,
        storageService: storageService,
        submissionRepository: submissionRepo,
      );

      final result = await syncService.performSync();
      debugPrint('Background sync result: ${result.message}');
      return result.success;
    } catch (e) {
      debugPrint('Background sync error: $e');
      return false;
    }
  });
}
