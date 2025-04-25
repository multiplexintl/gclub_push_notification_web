import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../widgets/notification_form.dart';
import '../widgets/responsive_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notification Sender'),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('About'),
                  content: const Text(
                      'This app allows sending push notifications through OneSignal without accessing the OneSignal dashboard.\n\n'
                      'Enter your API keys once and they\'ll be securely stored for future use.'),
                  actions: [
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.blue[800],
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '© 2025 Grace Club Push Notification Sender',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            Obx(() => Text(
                  'Version ${controller.version.value}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )),
          ],
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: context.width - 200,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: NotificationForm(),
        ),
      ),
    );
  }
}
