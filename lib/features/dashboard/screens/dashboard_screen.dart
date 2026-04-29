import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../controller/dashboard_controller.dart';
import '../../../core/theme.dart';
import '../../settings/screens/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Polso Health',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(dashboardControllerProvider.notifier).refreshData(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Status Banner
            FadeInDown(
              child: _buildSyncBanner(context, state),
            ),
            const SizedBox(height: 32),

            // Loading indicator
            if (state.isLoadingData)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),

            // Health Data Cards
            Text('HEALTH OVERVIEW',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.grey[500])),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: FadeInLeft(
                        delay: const Duration(milliseconds: 200),
                        child: _buildMetricCard(
                            'Steps', state.steps, Icons.directions_run,
                            AppTheme.primaryTeal))),
                const SizedBox(width: 12),
                Expanded(
                    child: FadeInRight(
                        delay: const Duration(milliseconds: 200),
                        child: _buildMetricCard(
                            'Heart Rate', state.heartRate, Icons.favorite,
                            Colors.redAccent))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: FadeInLeft(
                        delay: const Duration(milliseconds: 400),
                        child: _buildMetricCard(
                            'Calories', state.calories,
                            Icons.local_fire_department,
                            Colors.orange))),
                const SizedBox(width: 12),
                Expanded(
                    child: FadeInRight(
                        delay: const Duration(milliseconds: 400),
                        child: _buildMetricCard(
                            'Weight', state.weight,
                            Icons.monitor_weight_outlined,
                            Colors.blueAccent))),
              ],
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _buildMetricCard(
                  'Sleep', state.sleep, Icons.bedtime_outlined,
                  Colors.deepPurple),
            ),
            const SizedBox(height: 40),

            // Status Message
            if (state.syncMessage != null)
              FadeInUp(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: state.lastSyncSuccess
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: state.lastSyncSuccess
                            ? Colors.green[200]!
                            : Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          state.lastSyncSuccess
                              ? Icons.check_circle
                              : Icons.error,
                          color: state.lastSyncSuccess
                              ? Colors.green
                              : Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(state.syncMessage!,
                              style: TextStyle(
                                  color: state.lastSyncSuccess
                                      ? Colors.green[800]
                                      : Colors.red[800],
                                  fontWeight: FontWeight.w500))),
                    ],
                  ),
                ),
              ),

            // Sync Now Button
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: ElevatedButton.icon(
                onPressed: state.isSyncing
                    ? null
                    : () => ref
                        .read(dashboardControllerProvider.notifier)
                        .syncNow(),
                icon: state.isSyncing
                    ? const SizedBox.shrink()
                    : const Icon(Icons.sync),
                label: state.isSyncing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Sync Now'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBanner(BuildContext context, DashboardState state) {
    final lastSync = state.lastSyncTime;
    final formattedTime = lastSync != null
        ? DateFormat('MMM d, yyyy • HH:mm').format(lastSync)
        : 'Never';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryTeal,
            AppTheme.primaryTeal.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
                state.isSyncing ? Icons.sync : Icons.cloud_done_outlined,
                color: Colors.white,
                size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    state.isSyncing
                        ? 'Syncing...'
                        : state.lastSyncSuccess
                            ? 'Synced'
                            : 'Ready to Sync',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Last sync: $formattedTime',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
