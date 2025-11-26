# SMS Reminder Feature

## Summary
Automated SMS reminder system that notifies violators 3 days before their payment due date to prevent overdue penalties.

## Features Implemented

### 1. ReminderService (`lib/services/reminder_service.dart`)
Core service that handles SMS reminder logic:

- **checkAndSendReminders()** - Main method that:
  - Queries Firebase for violations due in exactly 3 days
  - Filters for unpaid violations (paymentStatus = "Pending")
  - Checks if reminder was already sent
  - Sends personalized SMS via TextBee
  - Marks violation as `reminderSent: true` to prevent duplicates

- **sendSingleReminder(trackingNumber)** - Manual test method:
  - Sends reminder to a specific tracking number
  - Useful for testing

### 2. Admin Tools Page (`lib/pages/admin_tools/index.dart`)
User interface for enforcers to manually trigger reminders:

- **Send Due Date Reminders** button - Triggers `checkAndSendReminders()`
- **Test Reminder** field - Send to specific tracking number
- Real-time feedback with success/error messages
- Loading indicators during processing

### 3. SMS Message Template
```
AutoFine Reminder

Hi [Violator Name],

This is a reminder that your traffic violation fine is due in 3 DAYS.

Tracking Number: [Tracking Number]
Due Date: [Date]
Amount: ₱[Total Fine]

⚠️ IMPORTANT: Failure to pay by the due date will result in DOUBLE the fine amount.

Please settle your payment before the deadline to avoid penalties.

Thank you.
```

## How It Works

### Workflow
1. **Admin triggers reminder check** - Daily at 9 AM (or whenever triggered)
2. **Service queries Firebase** - Finds violations with:
   - `dueDate` = 3 days from today
   - `paymentStatus` = "Pending"
   - `reminderSent` != true
3. **Sends SMS** - Uses TextBee API with personalized message
4. **Updates database** - Sets `reminderSent: true` on each violation
5. **Logs results** - Console output shows number of reminders sent

### Database Schema
The service automatically adds a `reminderSent` field to violation reports:

```json
{
  "trackingNumber": "TRK123456",
  "fullname": "Juan Dela Cruz",
  "phoneNumber": "09171234567",
  "dueDate": "2024-01-18T00:00:00.000Z",
  "paymentStatus": "Pending",
  "reminderSent": true,  // Added by ReminderService
  "violations": [...],
  "age": "35",
  "birthdate": "1989-05-15T00:00:00.000Z",
  "placeOfViolation": "MacArthur Highway",
  "isConfiscated": false
}
```

## Access the Feature

### For Enforcers
1. Open the app
2. Tap the **menu icon** (☰) in the top-left
3. Select **"Admin Tools"**
4. Tap **"Send Due Date Reminders"**
5. Wait for confirmation message

### For Testing
1. Go to Admin Tools page
2. Enter a tracking number in the **Test Reminder** field
3. Press Enter or tap outside the field
4. Check the violator's phone for the SMS

## Usage Recommendations

### Daily Schedule
- **Best time**: 9:00 AM local time
- **Frequency**: Once per day
- **Responsibility**: Assign an enforcer or admin to trigger daily

### Automation Options (Future Enhancement)

#### Option 1: Firebase Cloud Functions (Requires Blaze Plan)
```javascript
// Firebase Function to run daily at 9 AM
exports.sendDailyReminders = functions.pubsub
  .schedule('0 9 * * *')
  .timeZone('Asia/Manila')
  .onRun(async (context) => {
    // Call your Flutter backend or use Admin SDK
    await admin.firestore()...
  });
```

#### Option 2: Cron Service (Free)
- Use services like cron-job.org or EasyCron
- Create API endpoint that calls `ReminderService.checkAndSendReminders()`
- Schedule to run daily at 9 AM

#### Option 3: Android WorkManager
```dart
// In main.dart
Workmanager().initialize(callbackDispatcher);
Workmanager().registerPeriodicTask(
  "daily-reminder",
  "checkReminders",
  frequency: Duration(hours: 24),
);
```

## Cost Considerations

### TextBee SMS Costs
- Each SMS consumes credits from your TextBee account
- Monitor usage in TextBee dashboard
- Typical cost: ₱0.50 - ₱1.00 per SMS (check current rates)

### Estimating Monthly Cost
- Average violations per day: **X**
- Percentage unpaid after 3 days: **Y%**
- Daily reminders: **X × Y%**
- Monthly reminders: **X × Y% × 30**
- Monthly cost: **X × Y% × 30 × ₱0.75**

Example: 50 violations/day, 60% unpaid → 30 reminders/day → ~900/month → ₱675/month

## Troubleshooting

### Reminders Not Sending
1. **Check internet connection** - Service requires online access
2. **Verify TextBee credits** - Ensure account has sufficient balance
3. **Check phone numbers** - Must be valid Philippine mobile numbers
4. **Check due dates** - Only violations due in exactly 3 days will trigger
5. **Look at console logs** - Error messages appear in debug console

### Duplicate Reminders
- The service prevents duplicates using `reminderSent` flag
- If you need to resend, manually update Firestore: set `reminderSent: false`

### Wrong Due Date
- Ensure device/server timezone is correct
- Due date calculation uses local time

## Security & Privacy

### Data Access
- Only enforcers can access Admin Tools page
- Driver role cannot see this feature
- Requires authentication to execute

### Phone Number Privacy
- Phone numbers are only used for SMS notifications
- Not shared with third parties (except TextBee for delivery)
- Stored securely in Firebase Firestore

## Future Enhancements

1. **Multi-day reminders**
   - 7 days before due date
   - 1 day before due date
   - Day after overdue

2. **Email notifications**
   - Alternative to SMS for cost savings
   - Include payment link in email

3. **Smart scheduling**
   - Skip reminders for violations already paid
   - Adjust timing based on payment patterns

4. **Analytics dashboard**
   - Track reminder open rates
   - Monitor payment conversion after reminder
   - Cost analysis per reminder

5. **Template customization**
   - Allow enforcers to edit message templates
   - Support multiple languages

## Related Documentation
- [REMINDER_SERVICE_SETUP.md](./REMINDER_SERVICE_SETUP.md) - Technical setup guide
- [OVERDUE_PENALTY_FEATURE.md](./OVERDUE_PENALTY_FEATURE.md) - Overdue penalty system
- [PAYMONGO_INTEGRATION.md](./PAYMONGO_INTEGRATION.md) - Payment processing

## Contact
For issues or questions about the SMS reminder feature, contact the development team or check the console logs for detailed error messages.
