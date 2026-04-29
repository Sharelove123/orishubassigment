import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

class DashboardState {
  final bool isSyncing;
  final String? syncMessage;
  final bool lastSyncSuccess;
  final DateTime? lastSyncTime;

  DashboardState({
    this.isSyncing = false,
    this.syncMessage,
    this.lastSyncSuccess = false,
    this.lastSyncTime,
  });

  DashboardState copyWith({
    bool? isSyncing,
    String? syncMessage,
    bool? lastSyncSuccess,
    DateTime? lastSyncTime,
  }) {
    return DashboardState(
      isSyncing: isSyncing ?? this.isSyncing,
      syncMessage: syncMessage,
      lastSyncSuccess: lastSyncSuccess ?? this.lastSyncSuccess,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    _loadLastSyncTime();
    return DashboardState();
  }

  Future<void> _loadLastSyncTime() async {
    final storageService = ref.read(storageServiceProvider);
    final lastSync = await storageService.getLastSyncTimestamp();
    if (lastSync != null) {
      state = state.copyWith(lastSyncTime: lastSync, lastSyncSuccess: true);
    }
  }

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true, syncMessage: null);
    try {
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.performSync();
      state = state.copyWith(
        isSyncing: false,
        syncMessage: result.message,
        lastSyncSuccess: result.success,
        lastSyncTime: result.success ? DateTime.now() : state.lastSyncTime,
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncMessage: e.toString(),
        lastSyncSuccess: false,
      );
    }
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(() {
  return DashboardController();
});
