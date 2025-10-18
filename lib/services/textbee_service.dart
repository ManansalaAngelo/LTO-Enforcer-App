// lib/services/textbee_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// Your credentials have been added
const String _apiKey = "fa642183-e796-4ef8-8496-a7b858f91176";
const String _deviceId = "68f391426a418a16ecacfcde";

class TextBeeService {
  static Future<void> sendSms(String recipientNumber, String message) async {
    if (recipientNumber.isEmpty) {
      print("Recipient number is empty. Skipping SMS.");
      return;
    }

    final url = Uri.parse('https://api.textbee.dev/api/v1/gateway/devices/$_deviceId/send-sms');
    
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': _apiKey,
    };
    
    final payload = {
      'recipients': [recipientNumber],
      'message': message,
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('SMS sent successfully!');
      } else {
        print('Failed to send SMS. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending SMS: $e');
    }
  }
}