import 'package:enforcer_auto_fine/services/reminder_service.dart';
import 'package:enforcer_auto_fine/shared/app_theme/colors.dart';
import 'package:enforcer_auto_fine/shared/app_theme/fonts.dart';
import 'package:enforcer_auto_fine/shared/components/app_bar/index.dart';
import 'package:enforcer_auto_fine/shared/decorations/app_bg.dart';
import 'package:flutter/material.dart';

class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  bool _isSendingReminders = false;
  String _lastResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassmorphismAppBar(
        title: Text('Admin Tools'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: appBg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMS Reminder Tools',
                  style: TextStyle(
                    fontSize: FontSizes().h3,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Manually trigger automated reminders for violations due in 3 days',
                  style: TextStyle(
                    fontSize: FontSizes().body,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 24),
                
                // Send Reminders Button
                Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.notifications_active,
                      color: MainColor().primary,
                      size: 32,
                    ),
                    title: Text(
                      'Send Due Date Reminders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: FontSizes().h4,
                      ),
                    ),
                    subtitle: Text(
                      'Check all violations and send SMS reminders for those due in 3 days',
                      style: TextStyle(fontSize: FontSizes().caption),
                    ),
                    trailing: _isSendingReminders
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.send),
                    onTap: _isSendingReminders ? null : _sendReminders,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Test Single Reminder Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Test Reminder',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: FontSizes().h4,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Send a test reminder to a specific tracking number',
                          style: TextStyle(fontSize: FontSizes().caption),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Tracking Number',
                            hintText: 'Enter tracking number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.tag),
                          ),
                          onSubmitted: _sendTestReminder,
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                // Results Display
                if (_lastResult.isNotEmpty)
                  Card(
                    color: _lastResult.contains('Error')
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(
                            _lastResult.contains('Error')
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: _lastResult.contains('Error')
                                ? Colors.red
                                : Colors.green,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _lastResult,
                              style: TextStyle(
                                color: _lastResult.contains('Error')
                                    ? Colors.red.shade900
                                    : Colors.green.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                Spacer(),
                
                // Info Card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tip: Run this daily at 9 AM to send reminders to all violators whose due date is 3 days away.',
                            style: TextStyle(
                              fontSize: FontSizes().caption,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendReminders() async {
    setState(() {
      _isSendingReminders = true;
      _lastResult = '';
    });

    try {
      await ReminderService.checkAndSendReminders();
      
      setState(() {
        _lastResult = 'Reminder check completed successfully! Check console for details.';
        _isSendingReminders = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminders sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
        _isSendingReminders = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending reminders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTestReminder(String trackingNumber) async {
    if (trackingNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a tracking number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _lastResult = '';
    });

    try {
      await ReminderService.sendSingleReminder(trackingNumber.trim());
      
      setState(() {
        _lastResult = 'Test reminder sent to tracking number: $trackingNumber';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test reminder sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _lastResult = 'Error sending test reminder: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
