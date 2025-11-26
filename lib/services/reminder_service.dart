import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:enforcer_auto_fine/services/textbee_service.dart';
import 'package:enforcer_auto_fine/pages/violation/models/report_model.dart';
import 'package:intl/intl.dart';

/// Service to send automated SMS reminders 3 days before due date
class ReminderService {
  /// Check and send reminders for violations due in 3 days
  static Future<void> checkAndSendReminders() async {
    try {
      final db = FirebaseFirestore.instance;
      final now = DateTime.now();
      
      // Calculate the target date (3 days from now)
      final threeDaysFromNow = DateTime(
        now.year,
        now.month,
        now.day + 3,
      );
      
      // Calculate the start and end of the target day
      final startOfDay = DateTime(
        threeDaysFromNow.year,
        threeDaysFromNow.month,
        threeDaysFromNow.day,
      );
      final endOfDay = DateTime(
        threeDaysFromNow.year,
        threeDaysFromNow.month,
        threeDaysFromNow.day,
        23,
        59,
        59,
      );

      // Query violations with due date in 3 days and status not paid
      final querySnapshot = await db
          .collection('reports')
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dueDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('paymentStatus', isEqualTo: 'Pending')
          .get();

      print('Found ${querySnapshot.docs.length} violations due in 3 days');

      // Send reminder for each violation
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final report = ReportModel.fromJson(data);
          
          // Check if reminder was already sent
          final reminderSent = data['reminderSent'] as bool? ?? false;
          
          if (!reminderSent && report.dueDate != null) {
            await _sendReminderSms(report, doc.id);
            
            // Mark reminder as sent in Firestore
            await doc.reference.update({'reminderSent': true});
            
            print('Reminder sent for tracking number: ${report.trackingNumber}');
          }
        } catch (e) {
          print('Error processing reminder for doc ${doc.id}: $e');
        }
      }
      
      print('Reminder check completed');
    } catch (e) {
      print('Error in checkAndSendReminders: $e');
    }
  }

  /// Send reminder SMS to violator
  static Future<void> _sendReminderSms(ReportModel report, String docId) async {
    if (report.phoneNumber.isEmpty || report.dueDate == null) {
      print('Cannot send reminder: missing phone or due date');
      return;
    }

    final formattedDueDate = DateFormat('MMMM d, yyyy').format(report.dueDate!);
    final trackingNum = report.trackingNumber ?? 'N/A';
    
    // Calculate total fine amount
    double totalFine = 0.0;
    for (var violation in report.violations) {
      totalFine += violation.price;
    }

    final message = '''
AutoFine Reminder

Hi ${report.fullname},

This is a reminder that your traffic violation fine is due in 3 DAYS.

Tracking Number: $trackingNum
Due Date: $formattedDueDate
Amount: ₱${totalFine.toStringAsFixed(2)}

⚠️ IMPORTANT: Failure to pay by the due date will result in DOUBLE the fine amount.

Please settle your payment before the deadline to avoid penalties.

Thank you.
''';

    await TextBeeService.sendSms(report.phoneNumber, message);
  }

  /// Manual trigger to send a single reminder (for testing)
  static Future<void> sendSingleReminder(String trackingNumber) async {
    try {
      final db = FirebaseFirestore.instance;
      
      final querySnapshot = await db
          .collection('reports')
          .where('trackingNumber', isEqualTo: trackingNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No violation found with tracking number: $trackingNumber');
        return;
      }

      final doc = querySnapshot.docs.first;
      final report = ReportModel.fromJson(doc.data());
      
      await _sendReminderSms(report, doc.id);
      await doc.reference.update({'reminderSent': true});
      
      print('Manual reminder sent successfully');
    } catch (e) {
      print('Error sending manual reminder: $e');
    }
  }
}
