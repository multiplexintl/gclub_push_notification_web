import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:image_picker_web/image_picker_web.dart';
import '../controllers/notification_controller.dart';
import '../utils/image_utils.dart';
import 'custom_snackbar.dart';

class NotificationForm extends StatelessWidget {
  const NotificationForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side - Form
          Expanded(
            flex: 3,
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.only(right: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Configuration Section
                    _buildApiConfigSection(controller),

                    const Divider(height: 32),

                    // Platform and Audience Selection
                    _buildTargetingSection(controller),

                    const Divider(height: 32),

                    // Notification Content with Emoji Support
                    _buildNotificationContentSection(controller),

                    const SizedBox(height: 24),

                    // Status Messages
                    _buildStatusMessages(controller),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(controller, context),
                  ],
                ),
              ),
            ),
          ),

          // Right side - Preview
          Expanded(
            flex: 2,
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.only(left: 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Preview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    _buildNotificationPreview(controller),

                    const Divider(height: 32),

                    // Test Before Sending
                    _buildTestSection(controller),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiConfigSection(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: controller.formKeyForKeys,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'OneSignal API Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.appIdController,
              decoration: InputDecoration(
                labelText: 'OneSignal App ID',
                hintText: 'Enter your OneSignal App ID',
                labelStyle: TextStyle(color: Colors.black),
                prefixIcon:
                    const Icon(Icons.app_registration, color: Colors.black),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'App ID is required';
                }
                return null;
              },
              onChanged: (value) => controller.appId.value = value,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.apiKeyController,
              obscureText: controller.obscureKey.value,
              decoration: InputDecoration(
                labelText: 'REST API Key',
                hintText: 'Enter your OneSignal REST API Key',
                prefixIcon: const Icon(Icons.key),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: IconButton(
                  icon: Icon(controller.obscureKey.value
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => controller.toggleObscureKey(),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'REST API Key is required';
                }
                return null;
              },
              onChanged: (value) => controller.restApiKey.value = value,
            ),
            const SizedBox(height: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save API Credentials'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () {
                    if (controller.formKeyForKeys.currentState!.validate()) {
                      controller.saveCredentials();
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Load Credentials'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onPressed: () => controller.loadCredentials(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetingSection(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Targeting Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Platform Selection
          const Text(
            'Target Platform:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Obx(() => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Radio<PlatformTarget>(
                      value: PlatformTarget.both,
                      groupValue: controller.platform.value,
                      onChanged: (value) => controller.setPlatform(value!),
                    ),
                    const Text('Both'),
                    const SizedBox(width: 24),
                    Radio<PlatformTarget>(
                      value: PlatformTarget.ios,
                      groupValue: controller.platform.value,
                      onChanged: (value) => controller.setPlatform(value!),
                    ),
                    const Text('iOS Only'),
                    const SizedBox(width: 24),
                    Radio<PlatformTarget>(
                      value: PlatformTarget.android,
                      groupValue: controller.platform.value,
                      onChanged: (value) => controller.setPlatform(value!),
                    ),
                    const Text('Android Only'),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // Audience Selection (keeping your existing implementation)
          const Text(
            'Target Audience:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (controller.audience.value == null) {
              return ElevatedButton.icon(
                icon: controller.isLoadingSegments.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                label: Text(controller.isLoadingSegments.value
                    ? 'Loading audience data...'
                    : 'Fetch audience segments'),
                onPressed: controller.isLoadingSegments.value
                    ? null
                    : () => controller.fetchSegments(),
              );
            } else {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Available segments (${controller.segments.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: controller.isLoadingSegments.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh),
                          onPressed: controller.isLoadingSegments.value
                              ? null
                              : () => controller.fetchSegments(),
                          tooltip: 'Refresh segments',
                        ),
                      ],
                    ),
                    const Divider(),
                    if (controller.segments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No segments found. Try refreshing or check your API credentials.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    SizedBox(
                      height: controller.segments.isEmpty ? 0 : 200,
                      child: ListView(
                        shrinkWrap: true,
                        children: controller.segments.map((segment) {
                          return Obx(() => CheckboxListTile(
                                title: Text(
                                  segment.name ?? 'Unnamed segment',
                                  style: TextStyle(
                                    fontWeight: controller.selectedSegmentIds
                                            .contains(segment.name)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  segment.isActive == true
                                      ? 'Active'
                                      : 'Inactive',
                                  style: TextStyle(
                                    color: segment.isActive == true
                                        ? Colors.green[700]
                                        : Colors.red[700],
                                  ),
                                ),
                                value: controller.selectedSegmentIds
                                    .contains(segment.name),
                                onChanged: segment.isActive == true
                                    ? (bool? value) {
                                        if (segment.name != null) {
                                          controller.toggleSegmentSelection(
                                              segment.name!);
                                        }
                                      }
                                    : null,
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                tileColor: controller.selectedSegmentIds
                                        .contains(segment.name)
                                    ? Colors.blue.withOpacity(0.1)
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ));
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: controller.selectedSegmentIds.isNotEmpty
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: controller.selectedSegmentIds.isNotEmpty
                              ? Text(
                                  'Selected: ${controller.selectedSegmentIds.length} segment(s)',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  'No segments selected',
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        )),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationContentSection(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: controller.formKeyForContents,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notification Content',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Title with Emoji Support
            const Text(
              'Notification Title:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.titleController,
                    textDirection:
                        TextDirection.ltr, // Auto-detects RTL for Arabic
                    decoration: InputDecoration(
                      labelText: 'Title with emojis & Arabic',
                      hintText: 'Enter notification title 😀 مرحبا',
                      prefixIcon: const Icon(Icons.title),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                    maxLines: 2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Content with Emoji Support
            const Text(
              'Notification Content:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.contentController,
                    maxLines: 4,
                    textDirection:
                        TextDirection.ltr, // Auto-detects RTL for Arabic
                    decoration: InputDecoration(
                      labelText: 'Content with emojis & Arabic',
                      hintText: 'Enter notification message 🎉 أهلاً وسهلاً',
                      prefixIcon: const Icon(Icons.message),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Content is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Image Selection (keeping your existing implementation)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notification Image (Optional):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Select Image'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          final media = await ImagePickerWeb.getImageInfo;
                          if (media != null && media.data != null) {
                            // Determine the MIME type based on the image type
                            String mimeType = 'image/jpeg'; // Default mime type
                            if (media.fileName != null) {
                              final extension =
                                  media.fileName!.split('.').last.toLowerCase();
                              if (extension == 'png') {
                                mimeType = 'image/png';
                              } else if (extension == 'gif') {
                                mimeType = 'image/gif';
                              } else if (extension == 'webp') {
                                mimeType = 'image/webp';
                              }
                            }
                            final base64Data = base64Encode(media.data!);
                            final imageData =
                                'data:$mimeType;base64,$base64Data';
                            controller.setImageUrl(imageData);
                          }
                        } catch (e) {
                          CustomSnackbar.show(
                            title: 'Error',
                            message: 'Failed to pick image: $e',
                            backgroundColor: Colors.red,
                          );
                        }
                      },
                      // onPressed: () async {
                      //   try {
                      //     final media = await ImagePickerWeb.getImageInfo;
                      //     if (media?.data != null) {
                      //       final encodedImage = ImageUtils.encodeImageToBase64(
                      //           media!.data!,
                      //           fileName: media.fileName);

                      //       if (encodedImage != null) {
                      //         controller.setImageUrl(encodedImage);
                      //       } else {
                      //         // Handle encoding failure
                      //         CustomSnackbar.show(
                      //             title: 'Error',
                      //             message: 'Failed to process image');
                      //       }
                      //     }
                      //   } catch (e) {
                      //     CustomSnackbar.show(
                      //       title: 'Error',
                      //       message: 'Failed to pick image: $e',
                      //       backgroundColor: Colors.red,
                      //     );
                      //   }
                      // },
                    ),
                    const SizedBox(width: 12),
                    Obx(() => controller.imageUrl.value != null
                        ? ElevatedButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('Remove Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onPressed: () => controller.setImageUrl(null),
                          )
                        : const SizedBox.shrink()),
                  ],
                ),
                const SizedBox(height: 12),

                // Image Preview (keeping your existing implementation)
                Obx(() {
                  if (controller.imageUrl.value != null) {
                    try {
                      final dataUri = controller.imageUrl.value!;
                      final base64String = dataUri.split(',')[1];
                      final imageBytes = base64Decode(base64String);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Image Preview:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    } catch (e) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Image selected but preview not available',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.imageUrl.value!.length > 50
                                  ? '${controller.imageUrl.value!.substring(0, 50)}...'
                                  : controller.imageUrl.value!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessages(NotificationController controller) {
    return Obx(() {
      if (controller.errorMessage.value != null ||
          controller.successMessage.value != null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: controller.errorMessage.value != null
                  ? Colors.red.shade200
                  : Colors.green.shade200,
            ),
            borderRadius: BorderRadius.circular(8),
            color: controller.errorMessage.value != null
                ? Colors.red.withOpacity(0.1)
                : Colors.green.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Icon(
                controller.errorMessage.value != null
                    ? Icons.error
                    : Icons.check_circle,
                color: controller.errorMessage.value != null
                    ? Colors.red
                    : Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.errorMessage.value ??
                      controller.successMessage.value ??
                      '',
                  style: TextStyle(
                    color: controller.errorMessage.value != null
                        ? Colors.red
                        : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => controller.clearMessages(),
                color: controller.errorMessage.value != null
                    ? Colors.red
                    : Colors.green,
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildActionButtons(
      NotificationController controller, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(() => ElevatedButton.icon(
                icon: controller.isSending.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  controller.isSending.value
                      ? 'Sending...'
                      : 'Send Notification',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: controller.isSending.value
                    ? null
                    : () {
                        if (controller.formKeyForContents.currentState!
                            .validate()) {
                          if (controller.selectedSegmentIds.isEmpty) {
                            CustomSnackbar.show(
                              title: 'Warning',
                              message:
                                  'No segments selected. Please select at least one segment.',
                              backgroundColor: Colors.orange,
                            );
                            return;
                          }

                          // Show confirmation dialog
                          Get.dialog(
                            AlertDialog(
                              title: const Text('Confirm'),
                              content: Text(
                                'Send notification to ${controller.selectedSegmentIds.length} segment(s)?',
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Get.back(),
                                ),
                                ElevatedButton(
                                  child: const Text('Send'),
                                  onPressed: () {
                                    Get.back();
                                    controller.sendNotification();
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      },
              )),
        ),
        const SizedBox(width: 16),
        TextButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Form'),
          onPressed: () {
            controller.resetForm();
            controller.formKeyForContents.currentState?.reset();
          },
        ),
      ],
    );
  }

  Widget _buildNotificationPreview(NotificationController controller) {
    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App bar with app name
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Your App',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'now',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Image if available
            if (controller.imageUrl.value != null)
              Builder(
                builder: (context) {
                  try {
                    final dataUri = controller.imageUrl.value!;
                    if (dataUri.startsWith('data:image')) {
                      final base64String = dataUri.split(',')[1];
                      final imageBytes = base64Decode(base64String);

                      return SizedBox(
                        width: double.infinity,
                        height: 120,
                        child: Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return Container(
                        width: double.infinity,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    return Container(
                      width: double.infinity,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    );
                  }
                },
              ),

            // Title and content with emojis
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.title.value.isEmpty
                        ? 'Notification Title'
                        : controller.title.value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.content.value.isEmpty
                        ? 'Notification content will appear here.'
                        : controller.content.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTestSection(NotificationController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
        color: Colors.blue.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Before Sending',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send a test notification to verify content and appearance before sending to all subscribers.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.science, color: Colors.white),
              label: Text(controller.isSending.value
                  ? 'Sending...'
                  : 'Send to Test Users Only'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (controller.formKeyForContents.currentState!.validate()) {
                  // Show test notification details dialog
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Send Test Notification'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test notification will be sent with the following details:',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Title:', controller.title.value),
                          _buildInfoRow('Content:', controller.content.value),
                          _buildInfoRow(
                            'Platform:',
                            controller.platform.value
                                .toString()
                                .split('.')
                                .last,
                          ),
                          _buildInfoRow(
                            'Image:',
                            controller.imageUrl.value != null
                                ? 'Included'
                                : 'None',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Only users in the "Test Users" segment will receive this notification.',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Get.back(),
                        ),
                        ElevatedButton(
                          child: const Text('Send Test'),
                          onPressed: () {
                            Get.back();
                            controller.sendTestNotification();
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
