import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:gclub_push_notification_web/model/audience/audience.dart';
import 'package:gclub_push_notification_web/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:html' as html;
import '../model/audience/segment.dart';
import '../services/onesignal_service.dart';

enum PlatformTarget { ios, android, both }

class NotificationController extends GetxController {
  // final GetStorage _storage = GetStorage();
  // final _secureStorage = FlutterSecureStorage();
  final version = ''.obs;
  // Form fields
  final title = ''.obs;
  final content = ''.obs;
  final imageUrl = Rxn<String>();
  final platform = PlatformTarget.both.obs;
  // final audience = AudienceTarget.testers.obs;
  // final audienceSegmentId = Rxn<String>();
  final isSending = false.obs;
  final isLoadingSegments = false.obs;
  final errorMessage = Rxn<String>();
  final successMessage = Rxn<String>();
  final audience = Rxn<Audience>();
  final selectedSegmentIds = <String>[].obs;
  final segments = <Segment>[].obs;

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
    await _getAppVersion();
    await loadCredentials();
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
      // Directly use localStorage
      final localStorage = html.window.localStorage;

      // Save the credentials
      localStorage['onesignal_app_id'] = appId.value;
      localStorage['onesignal_rest_api_key'] = restApiKey.value;

      // Verify they were saved
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
      // Directly use localStorage
      final localStorage = html.window.localStorage;

      // Print all keys in localStorage for debugging
      log('All localStorage keys:');
      localStorage.forEach((key, value) {
        log('$key: $value');
      });

      // Get the saved credentials
      final savedAppId = localStorage['onesignal_app_id'];
      final savedRestApiKey = localStorage['onesignal_rest_api_key'];

      log('Retrieved from localStorage:');
      log('App ID: $savedAppId');
      log('REST API Key: $savedRestApiKey');

      // Update the controller values if found
      if (savedAppId != null && savedAppId.isNotEmpty) {
        appId.value = savedAppId;
        appIdController.text = savedAppId;
      }

      if (savedRestApiKey != null && savedRestApiKey.isNotEmpty) {
        restApiKey.value = savedRestApiKey;
        apiKeyController.text = savedRestApiKey;
      }

      // Only show notification if both values are loaded
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
      } else {
        log('No credentials found in localStorage');
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
  }

  void setContent(String value) {
    content.value = value;
  }

  void setImageUrl(String? value) {
    imageUrl.value = value;
  }

  void setPlatform(PlatformTarget value) {
    platform.value = value;
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

    // Check if a segment is selected
    if (selectedSegmentIds.isEmpty) {
      errorMessage.value = 'Please select a specific segment';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'Please select a specific segment',
          backgroundColor: Colors.red);
      return false;
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
        'audienceSegmentId': selectedSegmentIds,
      };
      log(notificationData.toString());
      final result = await service.sendNotification(notificationData);
      isSending.value = false;

      if (result['success']) {
        successMessage.value = 'Notification sent successfully!';
        CustomSnackbar.show(
            title: "Success!!",
            message: 'Notification sent successfully!',
            backgroundColor: Colors.green);
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

  // Add this to your NotificationController class
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
        'audienceSegmentId': ['Test Users'], // Force to test users only
      };

      final result = await service.sendNotification(notificationData);
      isSending.value = false;

      if (result['success']) {
        successMessage.value = 'Test notification sent successfully!';
        CustomSnackbar.show(
            title: "Success!!",
            message: 'Test notification sent successfully!',
            backgroundColor: Colors.red);
      } else {
        errorMessage.value = 'Failed to send test: ${result['message']}';
        CustomSnackbar.show(
            title: "Error!!",
            message: 'Failed to send test: ${result['message']}',
            backgroundColor: Colors.red);
      }

      return;
    } catch (e) {
      isSending.value = false;
      errorMessage.value = 'Error: ${e.toString()}';
      CustomSnackbar.show(
          title: "Error!!",
          message: 'Error: ${e.toString()}',
          backgroundColor: Colors.red);
      return;
    }
  }

  void resetForm() {
    title.value = '';
    content.value = '';
    imageUrl.value = null;
    platform.value = PlatformTarget.both;
    // audience.value = AudienceTarget.testers;
    clearMessages();
  }
}

 
// App ID: edb2b960-fcf2-499d-9eb0-72c3ec87c05b

// API Key: os_v2_app_5wzlsyh46jez3hvqolb6zb6alphp53qiyatene5qadfo4bznsemp5fzuikw4preljjzru44t4a2rjpuvj4xoblbnq267xdpgcoomucq