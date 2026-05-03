# Heart Rate & Weight Data Troubleshooting Guide

## Issue
Heart rate and weight metrics are showing "—" (no data) on the dashboard.

## Root Causes & Solutions

### 1. **Health Connect Permissions Not Granted**
**Symptoms**: All health data shows as empty
**Solution**:
```
1. Open the app on Android device
2. Go to Settings → Search for "Health Connect"
3. Open Health Connect app
4. Go to Permissions
5. Grant "Polso Health" app access to:
   - Heart rate
   - Weight
   - Steps
   - Calories
   - Sleep
```

### 2. **No Data Exists in Health Connect**
**Symptoms**: Permissions granted but still no data
**Solution**:
```
1. Ensure you have a compatible health app installed:
   - Google Fit
   - Samsung Health
   - Oura Ring app
   - Other Health Connect compatible apps
2. Record heart rate/weight data in that app
3. These apps will sync data to Health Connect
4. Refresh the Polso Health app (pull-to-refresh or restart)
```

### 3. **Health Connect Not Installed**
**Symptoms**: App shows error or installs Health Connect
**Solution**:
```
1. The app will automatically prompt to install Health Connect
2. Let it install (redirects to Play Store)
3. After installation, restart the Polso Health app
4. Grant permissions when prompted
```

## Debugging with Logs

The app now includes enhanced logging. To see debug output:

### Using Android Studio
1. Open Android Studio
2. Connect device via USB
3. Run app with: `flutter run -v`
4. Watch console for `[HealthService]` logs

### Key Log Patterns

**✅ Successful Permission Grant**:
```
[HealthService] Configured successfully
[HealthService] Health Connect SDK status: sdkAvailable
[HealthService] Authorization result: true
```

**✅ Data Successfully Fetched**:
```
[HealthService] Requesting heart_rate data from 2026-05-03 12:00:00.000 to 2026-05-03 18:32:47.123Z
[HealthService] heart_rate: Got 5 points
[HealthService] heart_rate sample: HEART_RATE = 72 bpm
```

**❌ Permission Issues**:
```
[HealthService] No permissions - requesting authorization
[HealthService] Authorization denied - requesting again after delay
```

**❌ No Data Found**:
```
[HealthService] ⚠️ WARNING: No heart_rate data found!
[HealthService] ⚠️ WARNING: No weight data found!
```

## Data Freshness

- **Heart Rate**: Fetches latest readings from last 24 hours
- **Weight**: Fetches latest reading from last 365 days
- **Steps**: Aggregates data from today (midnight to now)
- **Sleep**: Fetches from last 7 days

The app auto-refreshes data every 30 seconds.

## Manual Refresh Options

1. **Pull-to-Refresh**: Swipe down on the health overview cards
2. **Refresh Button**: Tap the refresh icon in the app bar
3. **Sync Now Button**: Tap "Sync Now" button to sync to server + refresh local data

## Technical Details

### Files Modified
- `lib/services/health_service.dart` - Enhanced with better logging and retry logic
- `lib/features/dashboard/controller/dashboard_controller.dart` - Improved null-safety
- `android/app/src/main/AndroidManifest.xml` - Permissions already configured

### Permission Types Required
```
android.permission.health.READ_HEART_RATE
android.permission.health.READ_WEIGHT
android.permission.health.READ_STEPS
android.permission.health.READ_ACTIVE_CALORIES_BURNED
android.permission.health.READ_TOTAL_CALORIES_BURNED
android.permission.health.READ_SLEEP
android.permission.health.READ_HEALTH_DATA_HISTORY
```

## Common Scenarios

### Scenario 1: Just Installed App
```
1. Open app
2. Login
3. When viewing Dashboard, permission prompt appears
4. Grant all health permissions
5. Data should appear within 10 seconds
```

### Scenario 2: Data Was Showing, Then Stopped
```
Possible causes:
- Health Connect app was uninstalled/disabled
- Permissions were revoked in Settings
- No new data recorded in last 24 hours (heart rate)
- No new weight data recorded in last 365 days

Solution: Check permissions, re-record data, refresh app
```

### Scenario 3: Only Some Metrics Missing
```
If only WEIGHT or HEART_RATE missing but STEPS shows:
- Heart rate data must come from wearable or health app
- Weight data must be manually entered or from scale integration
- Ensure those data types have permission grants in Health Connect
```

## Still Not Working?

1. **Restart app completely** - Force close and reopen
2. **Check device logs** - Run `flutter run -v` to see detailed output
3. **Uninstall/Reinstall** - Clear app data and reinstall
4. **Check Android version** - Health Connect requires Android 10+
5. **Verify Health Connect** - Make sure Health Connect app itself works
