import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gclub_push_notification_web/model/audience/audience.dart';
import 'package:get/get.dart';
import 'dart:html' as html;
import 'package:get_storage/get_storage.dart';
import '../model/audience/segment.dart';
import '../services/onesignal_service.dart';

enum PlatformTarget { ios, android, both }

class NotificationController extends GetxController {
  final GetStorage _storage = GetStorage();
  final _secureStorage = FlutterSecureStorage();

  // Form fields
  final title = 'Test'.obs;
  final content = 'Test from Web'.obs;
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
  final restApiKey = ''.obs;
  final obscureKey = true.obs;

  // Form key
  final formKeyForKeys = GlobalKey<FormState>();
  final formKeyForContents = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    loadCredentials();
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

      Get.snackbar(
        'Success',
        'API credentials saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      log('Error saving credentials: $e');
      Get.snackbar(
        'Error',
        'Failed to save credentials: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  void loadCredentials() {
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
      }

      if (savedRestApiKey != null && savedRestApiKey.isNotEmpty) {
        restApiKey.value = savedRestApiKey;
      }

      // Only show notification if both values are loaded
      if (savedAppId != null &&
          savedAppId.isNotEmpty &&
          savedRestApiKey != null &&
          savedRestApiKey.isNotEmpty) {
        log('Credentials loaded successfully');
        Get.snackbar(
          'Success',
          'API credentials loaded',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
          duration: const Duration(seconds: 2),
        );
      } else {
        log('No credentials found in localStorage');
      }
    } catch (e) {
      log('Error loading credentials: $e');
    }
  }

  // void loadCredentials() async {
  //   try {
  //     // Try to load from secure storage first
  //     final savedAppId = await _secureStorage.read(key: 'onesignal_app_id');
  //     final savedRestApiKey =
  //         await _secureStorage.read(key: 'onesignal_rest_api_key');
  //     log(savedAppId.toString());

  //     // If secure storage failed, try regular storage
  //     if (savedAppId == null || savedRestApiKey == null) {
  //       final regularAppId = _storage.read('onesignal_app_id');
  //       final regularRestApiKey = _storage.read('onesignal_rest_api_key');

  //       if (regularAppId != null) appId.value = regularAppId;
  //       if (regularRestApiKey != null) restApiKey.value = regularRestApiKey;
  //     } else {
  //       appId.value = savedAppId;
  //       restApiKey.value = savedRestApiKey;
  //     }
  //   } catch (e) {
  //     log('Error loading credentials: $e');
  //   }
  // }

  // void saveCredentials() async {
  //   try {
  //     // Try to save to secure storage
  //     await _secureStorage.write(key: 'onesignal_app_id', value: appId.value);
  //     await _secureStorage.write(
  //         key: 'onesignal_rest_api_key', value: restApiKey.value);

  //     // Also save to regular storage as fallback
  //     _storage.write('onesignal_app_id', appId.value);
  //     _storage.write('onesignal_rest_api_key', restApiKey.value);

  //     Get.snackbar(
  //       'Success',
  //       'API credentials saved securely',
  //       snackPosition: SnackPosition.TOP,
  //       backgroundColor: Colors.green.withOpacity(0.1),
  //       colorText: Colors.green,
  //       duration: const Duration(seconds: 2),
  //     );
  //   } catch (e) {
  //     // If secure storage fails, fall back to regular storage
  //     _storage.write('onesignal_app_id', appId.value);
  //     _storage.write('onesignal_rest_api_key', restApiKey.value);

  //     Get.snackbar(
  //       'Note',
  //       'API credentials saved (non-secure mode)',
  //       snackPosition: SnackPosition.TOP,
  //       backgroundColor: Colors.orange.withOpacity(0.1),
  //       colorText: Colors.orange[800],
  //     );
  //   }
  // }

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
      }
    } catch (e) {
      errorMessage.value = 'Error fetching segments: ${e.toString()}';
    } finally {
      isLoadingSegments.value = false;
    }
  }

  Future<bool> sendNotification() async {
    if (title.value.isEmpty || content.value.isEmpty) {
      errorMessage.value = 'Title and content are required';
      return false;
    }

    if (appId.value.isEmpty || restApiKey.value.isEmpty) {
      errorMessage.value = 'OneSignal API credentials are required';
      return false;
    }

    // Check if a segment is selected
    // if (selectedSegmentIds.isEmpty) {
    //   errorMessage.value = 'Please select a specific segment';
    //   return false;
    // }

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
        // resetForm();
      } else {
        errorMessage.value = 'Failed to send: ${result['message']}';
      }

      return result['success'] ?? false;
    } catch (e) {
      isSending.value = false;
      errorMessage.value = 'Error: ${e.toString()}';
      return false;
    }
  }

  // Add this to your NotificationController class
  void sendTestNotification() async {
    if (title.value.isEmpty || content.value.isEmpty) {
      errorMessage.value = 'Title and content are required';
      return;
    }

    if (appId.value.isEmpty || restApiKey.value.isEmpty) {
      errorMessage.value = 'OneSignal API credentials are required';
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
      } else {
        errorMessage.value = 'Failed to send test: ${result['message']}';
      }

      return;
    } catch (e) {
      isSending.value = false;
      errorMessage.value = 'Error: ${e.toString()}';
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