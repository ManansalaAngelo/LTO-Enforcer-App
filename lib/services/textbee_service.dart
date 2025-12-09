// lib/services/textbee_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

// Your credentials have been added
const String _apiKey = "28eca3e1-dd02-4be2-af8f-b68bba84c9f0";
const String _deviceId = "6932779fd3fdd9bd6c81cc77";

class TextBeeService {
  /// Formats phone number to include +63 country code if needed
  static String _formatPhoneNumber(String phoneNumber) {
    // Remove all spaces, dashes, and parentheses
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If it starts with 0, replace with +63
    if (cleaned.startsWith('0')) {
      cleaned = '+63${cleaned.substring(1)}';
    }
    // If it starts with 63 but not +63, add the +
    else if (cleaned.startsWith('63') && !cleaned.startsWith('+63')) {
      cleaned = '+$cleaned';
    }
    // If it doesn't start with + and is 10 digits, assume PH number
    else if (!cleaned.startsWith('+') && cleaned.length == 10) {
      cleaned = '+63$cleaned';
    }
    // If it doesn't have country code and is 9-10 digits, add +63
    else if (!cleaned.startsWith('+') &&
        (cleaned.length == 9 || cleaned.length == 10)) {
      cleaned = '+63$cleaned';
    }

    return cleaned;
  }

  static Future<bool> sendSms(String recipientNumber, String message) async {
    if (recipientNumber.isEmpty) {
      print("❌ Recipient number is empty. Skipping SMS.");
      return false;
    }

    // Format the phone number properly
    final formattedNumber = _formatPhoneNumber(recipientNumber);
    print("📞 Formatted number: $recipientNumber → $formattedNumber");

    final url = Uri.parse(
      'https://api.textbee.dev/api/v1/gateway/devices/$_deviceId/sendSMS',
    );

    final headers = {'Content-Type': 'application/json', 'x-api-key': _apiKey};

    final payload = {
      'recipients': [formattedNumber],
      'message': message,
    };

    print("📤 Sending SMS request to TextBee API...");
    print("📍 URL: $url");
    print("📋 Payload: ${jsonEncode(payload)}");

    try {
      final response = await http
          .post(url, headers: headers, body: jsonEncode(payload))
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout after 30 seconds');
            },
          );

      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          print('✅ SMS sent successfully!');
          print('📊 Response data: $responseData');
          return true;
        } catch (e) {
          print('✅ SMS sent successfully (non-JSON response)');
          return true;
        }
      } else if (response.statusCode == 401) {
        print('❌ Authentication failed. Check API key.');
        print('Response: ${response.body}');
        return false;
      } else if (response.statusCode == 404) {
        print('❌ Device not found. Check device ID.');
        print('Response: ${response.body}');
        return false;
      } else if (response.statusCode == 400) {
        print('❌ Bad request. Check phone number format and message.');
        print('Response: ${response.body}');
        return false;
      } else {
        print('❌ Failed to send SMS. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending SMS: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }
}
