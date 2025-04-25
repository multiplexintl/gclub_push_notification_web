class NotificationModel {
  final String title;
  final String content;
  final String? imageUrl;
  final PlatformTarget platform;

  NotificationModel({
    required this.title,
    required this.content,
    this.imageUrl,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'platform': platform.toString(),
    };
  }
}

enum PlatformTarget { ios, android, both }
