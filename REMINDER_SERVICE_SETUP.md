# SMS Reminder Service Setup

## Overview
The ReminderService automatically sends SMS reminders to violators 3 days before their payment due date using the TextBee API.

## Features
- ✅ Automatically checks for violations due in 3 days
- ✅ Sends personalized SMS reminders with tracking number, amount, and due date
- ✅ Prevents duplicate reminders using `reminderSent` flag
- ✅ Manual trigger option for testing
- ✅ Warns about double penalty for overdue payments

## How It Works

### Automatic Reminders
The service queries Firebase for all violations that:
1. Have a due date exactly 3 days from today
2. Have payment status = "Pending"
3. Haven't already received a reminder (reminderSent = false)

For each matching violation, it:
1. Sends an SMS using TextBee
2. Marks the violation as `reminderSent: true` to prevent duplicates
3. Logs the result

### SMS Message Template
```
AutoFine Reminder

Hi [Name],

This is a reminder that your traffic violation fine is due in 3 DAYS.

Tracking Number: [Tracking Number]
Due Date: [Due Date]
Amount: ₱[Amount]

⚠️ IMPORTANT: Failure to pay by the due date will result in DOUBLE the fine amount.

Please settle your payment before the deadline to avoid penalties.

Thank you.
```

## Setup Options

### Option 1: Manual Trigger (Recommended for Testing)
Add a button in the admin panel to manually trigger the reminder check:

```dart
import 'package:enforcer_auto_fine/services/reminder_service.dart';

// In your admin page
ElevatedButton(
  onPressed: () async {
    await ReminderService.checkAndSendReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder check completed')),
    );
  },
  child: Text('Send Due Date Reminders'),
)
```

### Option 2: Daily Scheduled Task
For automatic daily execution, you have several options:

#### A. Firebase Cloud Functions (Requires Firebase Blaze Plan)
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Initialize functions: `firebase init functions`
3. Create a scheduled function to call the reminder service
4. Deploy: `firebase deploy --only functions`

#### B. Third-Party Cron Service (Free Options)
1. **Cron-job.org** - Free service that can trigger an HTTP endpoint
2. **EasyCron** - Another free cron service
3. Create a simple API endpoint in your backend that calls `ReminderService.checkAndSendReminders()`
4. Configure the cron service to hit this endpoint daily

#### C. In-App Background Service (Android Only)
Use `workmanager` package to run the service in the background:

1. Add to pubspec.yaml:
```yaml
dependencies:
  workmanager: ^0.5.1
```

2. Initialize in main.dart:
```dart
import 'package:workmanager/workmanager.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await ReminderService.checkAndSendReminders();
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher);
  
  // Schedule daily reminder check at 9 AM
  Workmanager().registerPeriodicTask(
    "daily-reminder",
    "checkReminders",
    frequency: Duration(hours: 24),
    initialDelay: Duration(hours: 1),
  );
  
  runApp(MyApp());
}
```

## Testing

### Test Single Reminder
```dart
import 'package:enforcer_auto_fine/services/reminder_service.dart';

// Send reminder for specific tracking number
await ReminderService.sendSingleReminder('TRK123456');
```

### Test Full Check
```dart
// This will check all violations and send reminders where applicable
await ReminderService.checkAndSendReminders();
```

## Database Schema Update
The service automatically adds a `reminderSent` field to each violation report:

```json
{
  "trackingNumber": "TRK123456",
  "dueDate": "2024-01-15",
  "paymentStatus": "Pending",
  "reminderSent": true,  // Added by ReminderService
  // ... other fields
}
```

## Important Notes

1. **Cost Consideration**: Each SMS costs credits in your TextBee account. Monitor usage to avoid unexpected charges.

2. **Time Zone**: The service uses the device's local time zone. Ensure your server/device is set to the correct timezone.

3. **Network Dependency**: Requires internet connection to query Firebase and send SMS.

4. **Error Handling**: If SMS sending fails, the violation is NOT marked as reminderSent, so it will retry on the next run.

5. **Manual Reset**: To resend a reminder, update the Firestore document and set `reminderSent: false`.

## Recommended Implementation

For immediate use without additional infrastructure:

1. Add a manual trigger button in your enforcer admin dashboard
2. Assign someone to click it daily at a specific time (e.g., 9 AM)
3. Later upgrade to automated scheduling using Firebase Functions or cron service

This ensures reminders are sent while giving you control over when they run.
