import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../controllers/notification_controller.dart';

class OneSignalService {
  final String appId;
  final String restApiKey;

  // Replace with your Cloudflare Worker URL
  final String proxyUrl = "https://onesignal-proxy.itsupport-50b.workers.dev";

  OneSignalService(this.appId, this.restApiKey);

  Future<Map<String, dynamic>> fetchSegments() async {
    try {
      final response = await http.post(
        Uri.parse('$proxyUrl/fetchSegments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'appId': appId, 'restApiKey': restApiKey}),
      );
      log(jsonEncode({'appId': appId, 'restApiKey': restApiKey}));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Server returned ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> sendNotification(
      Map<String, dynamic> notificationData) async {
    try {
      // Convert enum to string
      String platformString;
      switch (notificationData['platform']) {
        case PlatformTarget.ios:
          platformString = 'ios';
          break;
        case PlatformTarget.android:
          platformString = 'android';
          break;
        case PlatformTarget.both:
        default:
          platformString = 'both';
          break;
      }

      // Prepare payload for proxy
      final proxyPayload = {
        'appId': appId,
        'restApiKey': restApiKey,
        'notificationData': {
          // Original text with emojis for OneSignal (OneSignal supports emojis)
          'title': notificationData['title'],
          'content': notificationData['content'],
          // Encoded versions for your database storage
          'titleEncoded': notificationData['titleEncoded'],
          'contentEncoded': notificationData['contentEncoded'],
          'imageUrl': notificationData['imageUrl'],
          'platform': platformString,
          'audienceSegmentId': notificationData['audienceSegmentId'],
        }
      };

      final response = await http.post(
        Uri.parse('$proxyUrl/sendNotification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(proxyPayload),
      );

      log('Request payload: ${jsonEncode(proxyPayload)}');
      log('Response: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Server returned ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}

// class OneSignalService {
//   final String appId;
//   final String restApiKey;
//   final String notificationsUrl = 'https://onesignal.com/api/v1/notifications';
//   final String segmentsUrl =
//       'https://cors-anywhere.herokuapp.com/https://api.onesignal.com/apps';

//   OneSignalService(this.appId, this.restApiKey);
//   Future<Map<String, dynamic>> fetchSegments() async {
//     try {
//       final response = await http.get(
//         Uri.parse(
//             'https://cors-anywhere.herokuapp.com/https://api.onesignal.com/apps/$appId/segments?offset=0&limit=300'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'Authorization': 'Basic $restApiKey',
//         },
//       );

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         final responseData = jsonDecode(response.body);
//         return {
//           'success': true,
//           'data': responseData,
//         };
//       } else {
//         return {
//           'success': false,
//           'message': 'Server returned ${response.statusCode}: ${response.body}',
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'message': e.toString(),
//       };
//     }
//   }
//   // Future<Map<String, dynamic>> fetchSegments() async {
//   //   try {
//   //     final response = await http.get(
//   //       Uri.parse('$segmentsUrl/$appId/segments'),
//   //       headers: {
//   //         'accept': 'application/json',
//   //         'Authorization': restApiKey,
//   //       },
//   //     );
//   //     // log(url.toString());
//   //     log(json.encode(response));

//   //     if (response.statusCode >= 200 && response.statusCode < 300) {
//   //       final responseData = jsonDecode(response.body);
//   //       return {
//   //         'success': true,
//   //         'data': responseData, // Return the entire response
//   //       };
//   //     } else {
//   //       return {
//   //         'success': false,
//   //         'message': 'Server returned ${response.statusCode}: ${response.body}',
//   //       };
//   //     }
//   //   } catch (e) {
//   //     return {
//   //       'success': false,
//   //       'message': e.toString(),
//   //     };
//   //   }
//   // }

//   Future<Map<String, dynamic>> sendNotification(
//       Map<String, dynamic> notificationData) async {
//     try {
//       // Extract data
//       final String title = notificationData['title'];
//       final String content = notificationData['content'];
//       final String? imageUrl = notificationData['imageUrl'];
//       final platform = notificationData['platform'];
//       final audienceSegmentId = notificationData['audienceSegmentId'];

//       // Build request body
//       Map<String, dynamic> body = {
//         'app_id': appId,
//         'headings': {'en': title},
//         'contents': {'en': content},
//       };

//       // Add image if provided
//       if (imageUrl != null && imageUrl.isNotEmpty) {
//         body['big_picture'] = imageUrl;
//         body['ios_attachments'] = {'id': imageUrl};
//         body['chrome_web_image'] =
//             imageUrl; // Note: using chrome_web_image for web push
//       }

//       // Set platform targeting
//       switch (platform) {
//         case PlatformTarget.ios:
//           body['isIos'] = true;
//           break;
//         case PlatformTarget.android:
//           body['isAndroid'] = true;
//           break;
//         case PlatformTarget.both:
//           body['isIos'] = true;
//           body['isAndroid'] = true;
//           break;
//       }

//       // Set segment targeting
//       if (audienceSegmentId != null && audienceSegmentId.isNotEmpty) {
//         body['included_segments'] = audienceSegmentId;
//       } else {
//         body['included_segments'] = ['Test Users']; // Default to test users
//       }
//       log(jsonEncode(body));
//       // Send request
//       final response = await http.post(
//         Uri.parse('$notificationsUrl?c=push'),
//         headers: {
//           'Accept': 'application/json',
//           'Content-Type': 'application/json',
//           'Authorization': 'Key $restApiKey',
//         },
//         body: jsonEncode(body),
//       );

//       if (response.statusCode >= 200 && response.statusCode < 300) {
//         final responseData = jsonDecode(response.body);
//         return {
//           'success': true,
//           'data': responseData,
//         };
//       } else {
//         return {
//           'success': false,
//           'message': 'Server returned ${response.statusCode}: ${response.body}',
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'message': e.toString(),
//       };
//     }
//   }
// }
