import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers.dart';

class DashboardState {
  final bool isSyncing;
  final String? syncMessage;
  final bool lastSyncSuccess;
  final DateTime? lastSyncTime;

  // Live health data
  final String steps;
  final String heartRate;
  final String calories;
  final String weight;
  final String sleep;
  final bool isLoadingData;

  DashboardState({
    this.isSyncing = false,
    this.syncMessage,
    this.lastSyncSuccess = false,
    this.lastSyncTime,
    this.steps = '—',
    this.heartRate = '—',
    this.calories = '—',
    this.weight = '—',
    this.sleep = '—',
    this.isLoadingData = false,
  });

  DashboardState copyWith({
    bool? isSyncing,
    String? syncMessage,
    bool? lastSyncSuccess,
    DateTime? lastSyncTime,
    String? steps,
    String? heartRate,
    String? calories,
    String? weight,
    String? sleep,
    bool? isLoadingData,
  }) {
    return DashboardState(
      isSyncing: isSyncing ?? this.isSyncing,
      syncMessage: syncMessage,
      lastSyncSuccess: lastSyncSuccess ?? this.lastSyncSuccess,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
      calories: calories ?? this.calories,
      weight: weight ?? this.weight,
      sleep: sleep ?? this.sleep,
      isLoadingData: isLoadingData ?? this.isLoadingData,
    );
  }
}

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    _loadLastSyncTime();
    _loadHealthData();
    return DashboardState();
  }

  Future<void> _loadLastSyncTime() async {
    final storageService = ref.read(storageServiceProvider);
    final lastSync = await storageService.getLastSyncTimestamp();
    if (lastSync != null) {
      state = state.copyWith(lastSyncTime: lastSync, lastSyncSuccess: true);
    }
  }

  Future<void> _loadHealthData() async {
    state = state.copyWith(isLoadingData: true);
    try {
      final healthService = ref.read(healthServiceProvider);
      final data = await healthService.fetchHealthData();

      // Extract values from the formatted payload
      final stepsList = data['steps'] as List;
      final caloriesList = data['calories'] as List;
      final weightList = data['weight'] as List;
      final heartRateList = data['heart_rate'] as List;
      final sleepList = data['sleep'] as List;

      state = state.copyWith(
        steps: stepsList.isNotEmpty ? stepsList[0]['value'] : '0',
        calories: caloriesList.isNotEmpty ? caloriesList[0]['value'] : '0',
        weight: weightList.isNotEmpty ? '${weightList[0]['value']} kg' : '—',
        heartRate: heartRateList.isNotEmpty
            ? '${heartRateList.last['value']} bpm'
            : '—',
        sleep: sleepList.isNotEmpty ? '${sleepList[0]['value']} min' : '—',
        isLoadingData: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingData: false);
    }
  }

  Future<void> refreshData() async {
    await _loadHealthData();
  }

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true, syncMessage: null);
    try {
      final syncService = ref.read(syncServiceProvider);
      final result = await syncService.performSync();

      // Reload health data after sync
      await _loadHealthData();

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
