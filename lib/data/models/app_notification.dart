// lib/data/models/app_notification.dart

/// Simple notification data model displayed in the notification center.
class AppNotification {
  AppNotification(this.title, this.body, this.time);

  final String title;
  final String body;
  final DateTime time;
}
