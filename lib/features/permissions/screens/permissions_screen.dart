import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../controller/permissions_controller.dart';
import '../../../core/theme.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(permissionsControllerProvider.notifier).checkAllPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(permissionsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              FadeInDown(
                child: Text(
                  'Permissions',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkNavy,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInDown(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'We need your consent to access the following data sources.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionTile(
                      index: 0,
                      icon: Icons.favorite_border,
                      title: 'Health Data',
                      subtitle:
                          'Read steps, heart rate, calories, weight, and sleep from Health Connect.',
                      granted: state.healthGranted,
                      required: true,
                      onRequest: () => ref
                          .read(permissionsControllerProvider.notifier)
                          .requestHealth(),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      index: 1,
                      icon: Icons.location_on_outlined,
                      title: 'Location (GPS)',
                      subtitle:
                          'Capture GPS coordinates for contextual data tagging.',
                      granted: state.locationGranted,
                      required: true,
                      onRequest: () => ref
                          .read(permissionsControllerProvider.notifier)
                          .requestLocation(),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      index: 2,
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera',
                      subtitle:
                          'Used only when you trigger a scan or upload.',
                      granted: state.cameraGranted,
                      required: false,
                      onRequest: () => ref
                          .read(permissionsControllerProvider.notifier)
                          .requestCamera(),
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      index: 3,
                      icon: Icons.mic_none,
                      title: 'Microphone',
                      subtitle:
                          'Used for voice input if needed. No background recording.',
                      granted: state.microphoneGranted,
                      required: false,
                      onRequest: () => ref
                          .read(permissionsControllerProvider.notifier)
                          .requestMicrophone(),
                    ),
                  ],
                ),
              ),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: ElevatedButton(
                  onPressed: state.allRequiredGranted
                      ? () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const DashboardScreen()),
                          );
                        }
                      : null,
                  child: Text(
                    state.allRequiredGranted
                        ? 'Continue to Dashboard'
                        : 'Grant Required Permissions',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool granted,
    required bool required,
    required VoidCallback onRequest,
  }) {
    return FadeInLeft(
      delay: Duration(milliseconds: 300 + index * 150),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: granted ? Colors.green.withValues(alpha: 0.05) : AppTheme.lightGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: granted ? Colors.green.withValues(alpha: 0.3) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: granted
                    ? Colors.green.withValues(alpha: 0.1)
                    : AppTheme.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: granted ? Colors.green : AppTheme.primaryTeal,
                  size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      if (required) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Required',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(width: 8),
            granted
                ? const Icon(Icons.check_circle, color: Colors.green, size: 28)
                : TextButton(
                    onPressed: onRequest,
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Allow', style: TextStyle(fontSize: 13)),
                  ),
          ],
        ),
      ),
    );
  }
}
