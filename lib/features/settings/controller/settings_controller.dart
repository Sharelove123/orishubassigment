import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/sync_service.dart';
import '../../../providers.dart';

class SettingsState {
  final bool healthGranted;
  final bool locationGranted;
  final bool cameraGranted;
  final bool microphoneGranted;

  SettingsState({
    this.healthGranted = false,
    this.locationGranted = false,
    this.cameraGranted = false,
    this.microphoneGranted = false,
  });
}

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _checkPermissions();
    return SettingsState();
  }

  Future<void> _checkPermissions() async {
    final healthService = ref.read(healthServiceProvider);
    final locationService = ref.read(locationServiceProvider);

    state = SettingsState(
      healthGranted: await healthService.hasPermissions(),
      locationGranted: await locationService.hasPermission(),
      cameraGranted: await Permission.camera.isGranted,
      microphoneGranted: await Permission.microphone.isGranted,
    );
  }

  Future<void> refreshPermissions() async {
    await _checkPermissions();
  }

  Future<void> logout() async {
    final storageService = ref.read(storageServiceProvider);
    await SyncService.cancelBackgroundSync();
    await storageService.clearAll();
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(() {
  return SettingsController();
});
