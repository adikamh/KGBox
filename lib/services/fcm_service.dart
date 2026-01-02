import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../services/notifications_service.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

// Top-level background handler required by `firebase_messaging`.
// This must be a top-level function (not a class method) so the background
// isolate can invoke it.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  try {
    await NotificationService.instance.init();
    final title = message.notification?.title ?? message.data['title'] ?? '';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    if (title.isNotEmpty || body.isNotEmpty) {
      await NotificationService.instance.showNotification(6000, title, body);
    }
  } catch (e) {
    debugPrint('background handler error: $e');
  }
}

class FCMService {
  FCMService._internal();
  static final FCMService instance = FCMService._internal();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  Future<void> initMessaging(BuildContext context) async {
    try {
      // register background handler early
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await NotificationService.instance.init();

      // request permission
      NotificationSettings settings = await _fm.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // get token
        final token = await _fm.getToken();
        if (token != null) await _saveTokenToFirestore(context, token);

        // foreground handler
        FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
          final title = msg.notification?.title ?? '';
          final body = msg.notification?.body ?? '';
          if (title.isNotEmpty || body.isNotEmpty) {
            NotificationService.instance.showNotification(5000, title, body);
          }
        });

        // handle token refresh
        _fm.onTokenRefresh.listen((t) async {
          await _saveTokenToFirestore(context, t);
        });
      }
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }

  Future<void> _saveTokenToFirestore(BuildContext context, String token) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      final ref = FirebaseFirestore.instance.collection('device_tokens').doc(token);
      await ref.set({
        'token': token,
        'ownerid': ownerId,
        'platform': Theme.of(context).platform.toString(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // subscribe to owner topic for convenience
      if (ownerId.isNotEmpty) {
        await _fm.subscribeToTopic('owner_$ownerId');
      }
    } catch (e) {
      debugPrint('save token error: $e');
    }
  }
}
