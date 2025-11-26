# SMS Reminder Quick Start Guide

## What This Does
Automatically sends SMS reminders to violators 3 days before their payment due date, warning them about the upcoming deadline and double penalty if they don't pay on time.

## How to Use (Simple Steps)

### For Enforcers:
1. **Open the app** and log in as enforcer
2. **Open the menu** (tap the ☰ icon in the top-left)
3. **Tap "Admin Tools"**
4. **Tap "Send Due Date Reminders"** button
5. **Wait for confirmation** message

That's it! The system will:
- Find all violations due in exactly 3 days
- Check if they're still unpaid
- Send SMS reminders to those violators
- Mark them so they don't get duplicate reminders

## When to Run
**Recommended**: Every day at 9:00 AM

Assign one enforcer to be responsible for running this daily.

## What the SMS Says
```
AutoFine Reminder

Hi [Name],

This is a reminder that your traffic violation fine is due in 3 DAYS.

Tracking Number: ABC123
Due Date: January 15, 2024
Amount: ₱500.00

⚠️ IMPORTANT: Failure to pay by the due date will result in DOUBLE the fine amount.

Please settle your payment before the deadline to avoid penalties.

Thank you.
```

## Testing
Want to test it first?

1. Go to Admin Tools
2. Find the "Test Reminder" section
3. Type a tracking number (e.g., TRK123456)
4. Press Enter
5. Check if the violator receives the SMS

## Important Notes
- ✅ Only sends to unpaid violations
- ✅ Prevents duplicate reminders
- ✅ Only sends to violations due in exactly 3 days
- ⚠️ Each SMS costs credits from TextBee account
- ⚠️ Make sure TextBee account has enough credits

## Cost
Approximately ₱0.50 - ₱1.00 per SMS sent. 

If you send 30 reminders per day = ~₱675/month

## Troubleshooting
**"No reminders sent"**
- Check if any violations are due in exactly 3 days
- Verify violators have valid phone numbers
- Ensure TextBee account has credits

**"Error sending reminders"**
- Check internet connection
- Verify TextBee API key is valid
- Contact technical support

## Need More Details?
See the full documentation:
- `SMS_REMINDER_FEATURE.md` - Complete user guide
- `REMINDER_SERVICE_SETUP.md` - Technical setup
- `IMPLEMENTATION_SUMMARY_SMS_REMINDERS.md` - Developer notes

## Questions?
Contact your system administrator or check the console logs for detailed information about each reminder sent.
