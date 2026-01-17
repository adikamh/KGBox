import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationOwnerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all notifications for a specific owner
  Future<List<Map<String, dynamic>>> fetchNotifications(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('ownerid', isEqualTo: ownerId)
          .get();

      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'body': data['body'] ?? '',
          'type': data['type'] ?? 'info',
          'productId': data['productId'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'ownerid': data['ownerid'] ?? '',
          'isRead': data['isRead'] ?? false,
        };
      }).toList();

      // Sort by timestamp descending
      notifications.sort((a, b) {
        final aTime = a['timestamp'] as DateTime;
        final bTime = b['timestamp'] as DateTime;
        return bTime.compareTo(aTime);
      });

      return notifications;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Mark all notifications as read for an owner
  Future<void> markAllAsRead(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('ownerid', isEqualTo: ownerId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  /// Count unread notifications for an owner
  Future<int> countUnreadNotifications(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('ownerid', isEqualTo: ownerId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get device token for an owner
  Future<String?> getDeviceToken(String ownerId) async {
    try {
      final snapshot = await _firestore
          .collection('device_token')
          .where('ownerid', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['token'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stream notifications in real-time
  Stream<List<Map<String, dynamic>>> streamNotifications(String ownerId) {
    return _firestore
        .collection('notifications')
        .where('ownerid', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'body': data['body'] ?? '',
          'type': data['type'] ?? 'info',
          'productId': data['productId'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'ownerid': data['ownerid'] ?? '',
          'isRead': data['isRead'] ?? false,
        };
      }).toList();

      // Sort by timestamp descending
      notifications.sort((a, b) {
        final aTime = a['timestamp'] as DateTime;
        final bTime = b['timestamp'] as DateTime;
        return bTime.compareTo(aTime);
      });

      return notifications;
    });
  }
}
