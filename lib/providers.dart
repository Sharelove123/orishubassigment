import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api_client.dart';
import 'services/storage_service.dart';
import 'services/health_service.dart';
import 'services/location_service.dart';
import 'services/sync_service.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/submission/repository/submission_repository.dart';

// Services
final storageServiceProvider = Provider((ref) => StorageService());
final healthServiceProvider = Provider((ref) => HealthService());
final locationServiceProvider = Provider((ref) => LocationService());

// API
final apiClientProvider = Provider((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return ApiClient(storageService: storageService);
});

// Repositories
final authRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final submissionRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubmissionRepository(apiClient);
});

// Sync
final syncServiceProvider = Provider((ref) {
  return SyncService(
    healthService: ref.watch(healthServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    storageService: ref.watch(storageServiceProvider),
    submissionRepository: ref.watch(submissionRepositoryProvider),
  );
});
