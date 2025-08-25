import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gclub_push_notification_web/model/audience/audience.dart';
import 'package:gclub_push_notification_web/services/api_service.dart';
import 'package:gclub_push_notification_web/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:html' as html;
import '../model/audience/segment.dart';
import '../services/onesignal_service.dart';

enum PlatformTarget { ios, android, both }
enum TargetingMode { segments, externalIds }

class NotificationController extends GetxController {
  final version = ''.obs;

  // Form fields
  final title = ''.obs;
  final content = ''.obs;
  final imageUrl = Rxn<String>();
  final platform = PlatformTarget.both.obs;
  final isSending = false.obs;
  final isLoadingSegments = false.obs;
  final errorMessage = Rxn<String>();
  final successMessage = Rxn<String>();
  final audience = Rxn<Audience>();
  final selectedSegmentIds = <String>[].obs;
  final segments = <Segment>[].obs;

  // New targeting mode properties
  final targetingMode = TargetingMode.segments.obs;
  final externalIds = ''.obs;
  final TextEditingController externalIdsController = TextEditingController();

  // Text controllers for form fields
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  // API Credentials
  final appId = ''.obs;
  final TextEditingController appIdController = TextEditingController();
  final restApiKey = ''.obs;
  final TextEditingController apiKeyController = TextEditingController();
  final obscureKey = true.obs;

  // Form key
  final formKeyForKeys = GlobalKey<FormState>();
  final formKeyForContents = GlobalKey<FormState>();

  @override
  void onInit() async {
    super.onInit();

    // Listen to text changes
    titleController.addListener(() {
      title.value = titleController.text;
    });

    contentController.addListener(() {
      content.value = contentController.text;
    });

    externalIdsController.addListener(() {
      externalIds.value = externalIdsController.text;
    });

    await _getAppVersion();
    await loadCredentials();
  }

  @override
  void onClose() {
    titleController.dispose();
    contentController.dispose();
    externalIdsController.dispose();
    super.onClose();
  }

  // Base64 encoding/decoding functions for all languages and emojis
  String encodeTextForDatabase(String text) {
    // Use base64 encoding - works with Arabic, emojis, and all languages
    final List<int> bytes = utf8.encode(text);
    return base64Encode(bytes);
  }

  String decodeTextFromDatabase(String encodedText) {
    // Decode base64 back to original text
    try {
      final List<int> bytes = base64Decode(encodedText);
      return utf8.decode(bytes);
    } catch (e) {
      log('Error decoding text: $e');
      return encodedText; // Return as-is if decoding fails
    }
  }

  Future<void> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version.value = 'v${packageInfo.version}';
    } catch (e) {
      version.value = 'Unknown';
      log('Error getting app version: $e');
    }
  }

  void saveCredentials() {
    try {
      final localStorage = html.window.localStorage;
      localStorage['onesignal_app_id'] = appId.value;
      localStorage['onesignal_rest_api_key'] = restApiKey.value;

      log('Saved credentials to localStorage:');
      log('App ID: ${localStorage['onesignal_app_id']}');
      log('REST API Key: ${localStorage['onesignal_rest_api_key']}');
      CustomSnackbar.show(
        title: 'Success',
        message: 'API credentials saved',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      log('Error saving credentials: $e');
      CustomSnackbar.show(
        title: 'Error',
        message: 'Failed to save credentials: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> loadCredentials() async {
    log('Attempting to load credentials...');
    try {
      final localStorage = html.window.localStorage;

      final savedAppId = localStorage['onesignal_app_id'];
      final savedRestApiKey = localStorage['onesignal_rest_api_key'];

      if (savedAppId != null && savedAppId.isNotEmpty) {
        appId.value = savedAppId;
        appIdController.text = savedAppId;
      }

      if (savedRestApiKey != null && savedRestApiKey.isNotEmpty) {
        restApiKey.value = savedRestApiKey;
        apiKeyController.text = savedRestApiKey;
      }

      if (savedAppId != null &&
          savedAppId.isNotEmpty &&
          savedRestApiKey != null &&
          savedRestApiKey.isNotEmpty) {
        log('Credentials loaded successfully');
        CustomSnackbar.show(
          title: 'Success',
          message: 'API credentials loaded',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      log('Error loading credentials: $e');
    }
  }

  void toggleObscureKey() {
    obscureKey.value = !obscureKey.value;
  }

  void setTitle(String value) {
    title.value = value;
    titleController.text = value;
  }

  void setContent(String value) {
    content.value = value;
    contentController.text = value;
  }

  void setImageUrl(String? value) {
    imageUrl.value = value;
  }

  void setPlatform(PlatformTarget value) {
    platform.value = value;
  }

  void setTargetingMode(TargetingMode mode) {
    targetingMode.value = mode;
    // Clear previous selections when switching modes
    if (mode == TargetingMode.segments) {
      externalIds.value = '';
      externalIdsController.clear();
    } else {
      selectedSegmentIds.clear();
    }
  }

  void setExternalIds(String ids) {
    externalIds.value = ids;
    externalIdsController.text = ids;
  }

  void clearMessages() {
    errorMessage.value = null;
    successMessage.value = null;
  }

  void toggleSegmentSelection(String segmentId) {
    if (selectedSegmentIds.contains(segmentId)) {
      selectedSegmentIds.remove(segmentId);
    } else {
      selectedSegmentIds.add(segmentId);
    }
  }

  // Parse and validate external IDs
  List<String> getParsedExternalIds() {
    if (externalIds.value.isEmpty) return [];
    
    return externalIds.value
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  bool isValidTargeting() {
    if (targetingMode.value == TargetingMode.segments) {
      return selectedSegmentIds.isNotEmpty;
    } else {
      return getParsedExternalIds().isNotEmpty;
    }
  }

  String getTargetingDescription() {
    if (targetingMode.value == TargetingMode.segments) {
      return '${selectedSegmentIds.length} segment(s)';
    } else {
      return '${getParsedExternalIds().length} user(s)';
    }
  }

  // Load notification data from database (with emoji decoding)
  void loadNotificationFromDatabase(Map<String, dynamic> notificationData) {
    // Decode emojis when loading from database
    final decodedTitle =
        decodeTextFromDatabase(notificationData['title'] ?? '');
    final decodedContent =
        decodeTextFromDatabase(notificationData['content'] ?? '');

    setTitle(decodedTitle);
    setContent(decodedContent);

    if (notificationData['imageUrl'] != null) {
      setImageUrl(notificationData['imageUrl']);
    }

    // Set platform if provided
    if (notificationData['platform'] != null) {
      switch (notificationData['platform'].toString().toLowerCase()) {
        case 'ios':
          setPlatform(PlatformTarget.ios);
          break;
        case 'android':
          setPlatform(PlatformTarget.android);
          break;
        default:
          setPlatform(PlatformTarget.both);
      }
    }
  }

  Future<void> fetchSegments() async {
    if (appId.value.isEmpty || restApiKey.value.isEmpty) {
      errorMessage.value =
          'OneSignal API credentials are required to fetch segments';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'OneSignal API credentials are required to fetch segments',
          backgroundColor: Colors.red);
      return;
    }

    isLoadingSegments.value = true;
    segments.clear();
    audience.value = null;
    selectedSegmentIds.clear();

    try {
      final service = OneSignalService(appId.value, restApiKey.value);
      final result = await service.fetchSegments();

      if (result['success']) {
        audience.value = Audience.fromJson(result['data']);
        if (audience.value?.segments != null) {
          segments.value = audience.value!.segments!;
        }
      } else {
        errorMessage.value = 'Failed to fetch segments: ${result['message']}';
        CustomSnackbar.show(
            title: "Error!!",
            message: 'Failed to fetch segments: ${result['message']}',
            backgroundColor: Colors.red);
      }
    } catch (e) {
      errorMessage.value = 'Error fetching segments: ${e.toString()}';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'Error fetching segments: ${e.toString()}',
          backgroundColor: Colors.red);
    } finally {
      isLoadingSegments.value = false;
    }
  }

  Future<bool> sendNotification() async {
    if (title.value.isEmpty || content.value.isEmpty) {
      errorMessage.value = 'Title and content are required';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'Title and content are required',
          backgroundColor: Colors.red);
      return false;
    }

    if (appId.value.isEmpty || restApiKey.value.isEmpty) {
      errorMessage.value = 'OneSignal API credentials are required';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'OneSignal API credentials are required',
          backgroundColor: Colors.red);
      return false;
    }

    if (!isValidTargeting()) {
      String message = targetingMode.value == TargetingMode.segments
          ? 'Please select at least one segment'
          : 'Please enter at least one external user ID';
      errorMessage.value = message;
      CustomSnackbar.show(
          title: "Error!!",
          message: message,
          backgroundColor: Colors.red);
      return false;
    }

    isSending.value = true;
    clearMessages();

    try {
      final service = OneSignalService(appId.value, restApiKey.value);

      final Map<String, dynamic> notificationData = {
        // Original text with emojis for OneSignal (OneSignal supports emojis)
        'title': title.value,
        'content': content.value,
        'imageUrl': imageUrl.value,
        'platform': platform.value,
        'targetingMode': targetingMode.value,
        'audienceSegmentId': targetingMode.value == TargetingMode.segments 
            ? selectedSegmentIds 
            : null,
        'externalUserIds': targetingMode.value == TargetingMode.externalIds 
            ? getParsedExternalIds() 
            : null,
      };

      log('Notification data: $notificationData');
      final result = await service.sendNotification(notificationData);
      isSending.value = false;

      if (result['success']) {
        successMessage.value = 'Notification sent successfully!';
        CustomSnackbar.show(
            title: "Success!!",
            message: 'Notification sent successfully!',
            backgroundColor: Colors.green);
        sendToAPI(isTestNotification: false);
        resetForm();
      } else {
        errorMessage.value = 'Failed to send: ${result['message']}';
        CustomSnackbar.show(
            title: "Error!!",
            message: 'Failed to send: ${result['message']}',
            backgroundColor: Colors.red);
      }

      return result['success'] ?? false;
    } catch (e) {
      isSending.value = false;
      errorMessage.value = 'Error: ${e.toString()}';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'Error: ${e.toString()}',
          backgroundColor: Colors.red);
      return false;
    }
  }

  void sendTestNotification() async {
    if (title.value.isEmpty || content.value.isEmpty) {
      errorMessage.value = 'Title and content are required';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'Title and content are required',
          backgroundColor: Colors.red);
      return;
    }

    if (appId.value.isEmpty || restApiKey.value.isEmpty) {
      errorMessage.value = 'OneSignal API credentials are required';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'OneSignal API credentials are required',
          backgroundColor: Colors.red);
      return;
    }

    isSending.value = true;
    clearMessages();

    try {
      final service = OneSignalService(appId.value, restApiKey.value);

      final Map<String, dynamic> notificationData = {
        'title': title.value,
        'content': content.value,
        'imageUrl': imageUrl.value,
        'platform': platform.value,
        'targetingMode': TargetingMode.segments, // Always use segments for test
        'audienceSegmentId': ['Test Users'],
        'externalUserIds': null,
      };

      final result = await service.sendNotification(notificationData);
      isSending.value = false;

      if (result['success']) {
        successMessage.value = 'Test notification sent successfully!';
        CustomSnackbar.show(
            title: "Success!!",
            message: 'Test notification sent successfully!',
            backgroundColor: Colors.green);
        sendToAPI(isTestNotification: true);
      } else {
        errorMessage.value = 'Failed to send test: ${result['message']}';
        CustomSnackbar.show(
            title: "Error!!",
            message: 'Failed to send test: ${result['message']}',
            backgroundColor: Colors.red);
      }
    } catch (e) {
      isSending.value = false;
      errorMessage.value = 'Error: ${e.toString()}';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'Error: ${e.toString()}',
          backgroundColor: Colors.red);
    }
  }

  Future<void> sendToAPI({required bool isTestNotification}) async {
    try {
      if (title.value.isEmpty || content.value.isEmpty) {}
      final Map<String, dynamic> notificationData = {
        'Title': encodeTextForDatabase(title.value),
        'Description': encodeTextForDatabase(content.value),
        'Images': "${imageUrl.value}",
      };
      log(json.encode(notificationData));
      final service = ApiService();
      final result = await service.sendNotificationToApi(notificationData);
      if (result['success']) {
        successMessage.value = 'Notification saved successfully!';
      } else {
        errorMessage.value = 'Failed to save: ${result['message']}';
      }
    } catch (e) {
      log(e.toString());
    }
  }

  void resetForm() {
    title.value = '';
    content.value = '';
    titleController.clear();
    contentController.clear();
    imageUrl.value = null;
    platform.value = PlatformTarget.both;
    targetingMode.value = TargetingMode.segments;
    selectedSegmentIds.clear();
    externalIds.value = '';
    externalIdsController.clear();
    clearMessages();
  }
}

// import 'dart:developer';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:gclub_push_notification_web/model/audience/audience.dart';
// import 'package:gclub_push_notification_web/services/api_service.dart';
// import 'package:gclub_push_notification_web/widgets/custom_snackbar.dart';
// import 'package:get/get.dart';
// import 'package:package_info_plus/package_info_plus.dart';
// import 'dart:html' as html;
// import '../model/audience/segment.dart';
// import '../services/onesignal_service.dart';

// enum PlatformTarget { ios, android, both }

// class NotificationController extends GetxController {
//   final version = ''.obs;

//   // Form fields
//   final title = ''.obs;
//   final content = ''.obs;
//   final imageUrl = Rxn<String>();
//   final platform = PlatformTarget.both.obs;
//   final isSending = false.obs;
//   final isLoadingSegments = false.obs;
//   final errorMessage = Rxn<String>();
//   final successMessage = Rxn<String>();
//   final audience = Rxn<Audience>();
//   final selectedSegmentIds = <String>[].obs;
//   final segments = <Segment>[].obs;

//   // Text controllers for form fields
//   final titleController = TextEditingController();
//   final contentController = TextEditingController();

//   // API Credentials
//   final appId = ''.obs;
//   final TextEditingController appIdController = TextEditingController();
//   final restApiKey = ''.obs;
//   final TextEditingController apiKeyController = TextEditingController();
//   final obscureKey = true.obs;

//   // Form key
//   final formKeyForKeys = GlobalKey<FormState>();
//   final formKeyForContents = GlobalKey<FormState>();

//   @override
//   void onInit() async {
//     super.onInit();

//     // Listen to text changes
//     titleController.addListener(() {
//       title.value = titleController.text;
//     });

//     contentController.addListener(() {
//       content.value = contentController.text;
//     });

//     await _getAppVersion();
//     await loadCredentials();
//   }

//   @override
//   void onClose() {
//     titleController.dispose();
//     contentController.dispose();
//     super.onClose();
//   }

//   // Base64 encoding/decoding functions for all languages and emojis
//   String encodeTextForDatabase(String text) {
//     // Use base64 encoding - works with Arabic, emojis, and all languages
//     final List<int> bytes = utf8.encode(text);
//     return base64Encode(bytes);
//   }

//   String decodeTextFromDatabase(String encodedText) {
//     // Decode base64 back to original text
//     try {
//       final List<int> bytes = base64Decode(encodedText);
//       return utf8.decode(bytes);
//     } catch (e) {
//       log('Error decoding text: $e');
//       return encodedText; // Return as-is if decoding fails
//     }
//   }

//   Future<void> _getAppVersion() async {
//     try {
//       final packageInfo = await PackageInfo.fromPlatform();
//       version.value = 'v${packageInfo.version}';
//     } catch (e) {
//       version.value = 'Unknown';
//       log('Error getting app version: $e');
//     }
//   }

//   void saveCredentials() {
//     try {
//       final localStorage = html.window.localStorage;
//       localStorage['onesignal_app_id'] = appId.value;
//       localStorage['onesignal_rest_api_key'] = restApiKey.value;

//       log('Saved credentials to localStorage:');
//       log('App ID: ${localStorage['onesignal_app_id']}');
//       log('REST API Key: ${localStorage['onesignal_rest_api_key']}');
//       CustomSnackbar.show(
//         title: 'Success',
//         message: 'API credentials saved',
//         backgroundColor: Colors.green,
//       );
//     } catch (e) {
//       log('Error saving credentials: $e');
//       CustomSnackbar.show(
//         title: 'Error',
//         message: 'Failed to save credentials: $e',
//         backgroundColor: Colors.red,
//       );
//     }
//   }

//   Future<void> loadCredentials() async {
//     log('Attempting to load credentials...');
//     try {
//       final localStorage = html.window.localStorage;

//       final savedAppId = localStorage['onesignal_app_id'];
//       final savedRestApiKey = localStorage['onesignal_rest_api_key'];

//       if (savedAppId != null && savedAppId.isNotEmpty) {
//         appId.value = savedAppId;
//         appIdController.text = savedAppId;
//       }

//       if (savedRestApiKey != null && savedRestApiKey.isNotEmpty) {
//         restApiKey.value = savedRestApiKey;
//         apiKeyController.text = savedRestApiKey;
//       }

//       if (savedAppId != null &&
//           savedAppId.isNotEmpty &&
//           savedRestApiKey != null &&
//           savedRestApiKey.isNotEmpty) {
//         log('Credentials loaded successfully');
//         CustomSnackbar.show(
//           title: 'Success',
//           message: 'API credentials loaded',
//           backgroundColor: Colors.green,
//         );
//       }
//     } catch (e) {
//       log('Error loading credentials: $e');
//     }
//   }

//   void toggleObscureKey() {
//     obscureKey.value = !obscureKey.value;
//   }

//   void setTitle(String value) {
//     title.value = value;
//     titleController.text = value;
//   }

//   void setContent(String value) {
//     content.value = value;
//     contentController.text = value;
//   }

//   void setImageUrl(String? value) {
//     imageUrl.value = value;
//   }

//   void setPlatform(PlatformTarget value) {
//     platform.value = value;
//   }

//   void clearMessages() {
//     errorMessage.value = null;
//     successMessage.value = null;
//   }

//   void toggleSegmentSelection(String segmentId) {
//     if (selectedSegmentIds.contains(segmentId)) {
//       selectedSegmentIds.remove(segmentId);
//     } else {
//       selectedSegmentIds.add(segmentId);
//     }
//   }

//   // Load notification data from database (with emoji decoding)
//   void loadNotificationFromDatabase(Map<String, dynamic> notificationData) {
//     // Decode emojis when loading from database
//     final decodedTitle =
//         decodeTextFromDatabase(notificationData['title'] ?? '');
//     final decodedContent =
//         decodeTextFromDatabase(notificationData['content'] ?? '');

//     setTitle(decodedTitle);
//     setContent(decodedContent);

//     if (notificationData['imageUrl'] != null) {
//       setImageUrl(notificationData['imageUrl']);
//     }

//     // Set platform if provided
//     if (notificationData['platform'] != null) {
//       switch (notificationData['platform'].toString().toLowerCase()) {
//         case 'ios':
//           setPlatform(PlatformTarget.ios);
//           break;
//         case 'android':
//           setPlatform(PlatformTarget.android);
//           break;
//         default:
//           setPlatform(PlatformTarget.both);
//       }
//     }
//   }

//   Future<void> fetchSegments() async {
//     if (appId.value.isEmpty || restApiKey.value.isEmpty) {
//       errorMessage.value =
//           'OneSignal API credentials are required to fetch segments';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'OneSignal API credentials are required to fetch segments',
//           backgroundColor: Colors.red);
//       return;
//     }

//     isLoadingSegments.value = true;
//     segments.clear();
//     audience.value = null;
//     selectedSegmentIds.clear();

//     try {
//       final service = OneSignalService(appId.value, restApiKey.value);
//       final result = await service.fetchSegments();

//       if (result['success']) {
//         audience.value = Audience.fromJson(result['data']);
//         if (audience.value?.segments != null) {
//           segments.value = audience.value!.segments!;
//         }
//       } else {
//         errorMessage.value = 'Failed to fetch segments: ${result['message']}';
//         CustomSnackbar.show(
//             title: "Error!!",
//             message: 'Failed to fetch segments: ${result['message']}',
//             backgroundColor: Colors.red);
//       }
//     } catch (e) {
//       errorMessage.value = 'Error fetching segments: ${e.toString()}';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'Error fetching segments: ${e.toString()}',
//           backgroundColor: Colors.red);
//     } finally {
//       isLoadingSegments.value = false;
//     }
//   }

//   Future<bool> sendNotification() async {
//     if (title.value.isEmpty || content.value.isEmpty) {
//       errorMessage.value = 'Title and content are required';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'Title and content are required',
//           backgroundColor: Colors.red);
//       return false;
//     }

//     if (appId.value.isEmpty || restApiKey.value.isEmpty) {
//       errorMessage.value = 'OneSignal API credentials are required';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'OneSignal API credentials are required',
//           backgroundColor: Colors.red);
//       return false;
//     }

//     if (selectedSegmentIds.isEmpty) {
//       errorMessage.value = 'Please select a specific segment';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'Please select a specific segment',
//           backgroundColor: Colors.red);
//       return false;
//     }

//     isSending.value = true;
//     clearMessages();

//     try {
//       final service = OneSignalService(appId.value, restApiKey.value);

//       final Map<String, dynamic> notificationData = {
//         // Original text with emojis for OneSignal (OneSignal supports emojis)
//         'title': title.value,
//         'content': content.value,
//         // Encoded text for database storage
//         // 'titleEncoded': encodeTextForDatabase(title.value),
//         // 'contentEncoded': encodeTextForDatabase(content.value),
//         'imageUrl': imageUrl.value,
//         'platform': platform.value,
//         'audienceSegmentId': selectedSegmentIds,
//       };

//       log('Notification data: $notificationData');
//       final result = await service.sendNotification(notificationData);
//       isSending.value = false;

//       if (result['success']) {
//         successMessage.value = 'Notification sent successfully!';
//         CustomSnackbar.show(
//             title: "Success!!",
//             message: 'Notification sent successfully!',
//             backgroundColor: Colors.green);
//         sendToAPI(isTestNotification: false);
//         resetForm();
//       } else {
//         errorMessage.value = 'Failed to send: ${result['message']}';
//         CustomSnackbar.show(
//             title: "Error!!",
//             message: 'Failed to send: ${result['message']}',
//             backgroundColor: Colors.red);
//       }

//       return result['success'] ?? false;
//     } catch (e) {
//       isSending.value = false;
//       errorMessage.value = 'Error: ${e.toString()}';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'Error: ${e.toString()}',
//           backgroundColor: Colors.red);
//       return false;
//     }
//   }

//   void sendTestNotification() async {
//     if (title.value.isEmpty || content.value.isEmpty) {
//       errorMessage.value = 'Title and content are required';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'Title and content are required',
//           backgroundColor: Colors.red);
//       return;
//     }

//     if (appId.value.isEmpty || restApiKey.value.isEmpty) {
//       errorMessage.value = 'OneSignal API credentials are required';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'OneSignal API credentials are required',
//           backgroundColor: Colors.red);
//       return;
//     }

//     isSending.value = true;
//     clearMessages();

//     try {
//       final service = OneSignalService(appId.value, restApiKey.value);

//       final Map<String, dynamic> notificationData = {
//         'title': title.value,
//         'content': content.value,
//         'imageUrl': imageUrl.value,
//         'platform': platform.value,
//         'audienceSegmentId': ['Test Users'],
//       };

//       final result = await service.sendNotification(notificationData);
//       isSending.value = false;

//       if (result['success']) {
//         successMessage.value = 'Test notification sent successfully!';
//         CustomSnackbar.show(
//             title: "Success!!",
//             message: 'Test notification sent successfully!',
//             backgroundColor: Colors.green);
//         sendToAPI(isTestNotification: true);
//       } else {
//         errorMessage.value = 'Failed to send test: ${result['message']}';
//         CustomSnackbar.show(
//             title: "Error!!",
//             message: 'Failed to send test: ${result['message']}',
//             backgroundColor: Colors.red);
//       }
//     } catch (e) {
//       isSending.value = false;
//       errorMessage.value = 'Error: ${e.toString()}';
//       CustomSnackbar.show(
//           title: "Error!!",
//           message: 'Error: ${e.toString()}',
//           backgroundColor: Colors.red);
//     }
//   }

//   Future<void> sendToAPI({required bool isTestNotification}) async {
//     try {
//       if (title.value.isEmpty || content.value.isEmpty) {}
//       final Map<String, dynamic> notificationData = {
//         'Title': encodeTextForDatabase(title.value),
//         'Description': encodeTextForDatabase(content.value),
//         'Images': "${imageUrl.value}",
//       };
//       log(json.encode(notificationData));
//       final service = ApiService();
//       final result = await service.sendNotificationToApi(notificationData);
//       if (result['success']) {
//         successMessage.value = 'Notification saved successfully!';
//       } else {
//         errorMessage.value = 'Failed to save: ${result['message']}';
//       }
//     } catch (e) {
//       log(e.toString());
//     }
//   }

//   void resetForm() {
//     title.value = '';
//     content.value = '';
//     titleController.clear();
//     contentController.clear();
//     imageUrl.value = null;
//     platform.value = PlatformTarget.both;
//     clearMessages();
//   }
// }
