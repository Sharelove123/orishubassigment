import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api_client.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/submission/repository/submission_repository.dart';

final apiClientProvider = Provider((ref) => ApiClient());

final authRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

final submissionRepositoryProvider = Provider((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SubmissionRepository(apiClient);
});
