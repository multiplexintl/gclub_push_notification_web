import 'dart:convert';


import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://AuthtestAPI.mygraceclub.com/api';

  Future<Map<String, dynamic>> sendNotificationToApi(
      Map<String, dynamic> notificationData) async {
    try {
      // Example: Using http package for API call
      final response = await http.post(
        Uri.parse('$baseUrl/General/CreateNotification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(notificationData),
      );
   
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Notification sent to API'};
      } else {
        return {
          'success': false,
          'message': 'Failed to send notification to API: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error sending to API: $e'};
    }
  }
}
