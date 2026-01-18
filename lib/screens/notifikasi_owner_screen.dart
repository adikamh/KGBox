import 'package:flutter/material.dart';
import 'package:KGbox/services/notification_owner_service.dart';

class NotifikasiOwnerScreenController {
  final NotificationOwnerService _service = NotificationOwnerService();

  /// Fetch all notifications for owner
  Future<List<Map<String, dynamic>>> fetchNotifications(String ownerId) async {
    return await _service.fetchNotifications(ownerId);
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String ownerId) async {
    await _service.markAllAsRead(ownerId);
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _service.deleteNotification(notificationId);
  }

  /// Count unread notifications
  Future<int> countUnreadNotifications(String ownerId) async {
    return await _service.countUnreadNotifications(ownerId);
  }

  /// Get stream of notifications in real-time
  Stream<List<Map<String, dynamic>>> streamNotifications(String ownerId) {
    return _service.streamNotifications(ownerId);
  }

  /// Get notification icon based on type
  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'expired_product':
        return Icons.warning_rounded;
      case 'low_stock':
        return Icons.inventory_2_rounded;
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'delivery':
        return Icons.local_shipping_rounded;
      case 'stock_request':
        return Icons.request_page_rounded;
      case 'report_submission':
        return Icons.description_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  /// Get notification color based on type
  Color getNotificationColor(String type) {
    switch (type) {
      case 'expired_product':
        return Colors.red.shade600;
      case 'low_stock':
        return Colors.orange.shade600;
      case 'order':
        return Colors.blue.shade600;
      case 'delivery':
        return Colors.green.shade600;
      case 'stock_request':
        return Colors.blue.shade600;
      case 'report_submission':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Format timestamp to readable format
  String formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
