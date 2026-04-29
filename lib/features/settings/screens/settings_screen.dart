import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controller/settings_controller.dart';
import '../../../core/theme.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: Text('PERMISSIONS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey[500])),
            ),
            const SizedBox(height: 16),
            _buildPermissionRow(
              index: 0,
              icon: Icons.favorite_border,
              title: 'Health Data',
              granted: state.healthGranted,
            ),
            _buildPermissionRow(
              index: 1,
              icon: Icons.location_on_outlined,
              title: 'Location',
              granted: state.locationGranted,
            ),
            _buildPermissionRow(
              index: 2,
              icon: Icons.camera_alt_outlined,
              title: 'Camera',
              granted: state.cameraGranted,
            ),
            _buildPermissionRow(
              index: 3,
              icon: Icons.mic_none,
              title: 'Microphone',
              granted: state.microphoneGranted,
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: TextButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Open System Settings'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
              ),
            ),
            const SizedBox(height: 40),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Text('ACCOUNT',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey[500])),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(settingsControllerProvider.notifier)
                        .logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Logout',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Text('Polso Health v1.0.0',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow({
    required int index,
    required IconData icon,
    required String title,
    required bool granted,
  }) {
    return FadeInLeft(
      delay: Duration(milliseconds: 100 + index * 100),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.darkNavy, size: 22),
            const SizedBox(width: 14),
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w500))),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: granted
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                granted ? 'Granted' : 'Denied',
                style: TextStyle(
                    color: granted ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
