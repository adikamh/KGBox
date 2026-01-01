import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/notifications_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startListening() async {
    String ownerId = '';
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      ownerId = user?.ownerId ?? user?.id ?? '';

      Query<Map<String, dynamic>> q = _firestore.collection('notifications').orderBy('timestamp', descending: true);
      if (ownerId.isNotEmpty) {
        // try ownerid then ownerId
        final q1 = _firestore.collection('notifications').where('ownerid', isEqualTo: ownerId).orderBy('timestamp', descending: true);
        final snap1 = await q1.limit(1).get();
        if (snap1.docs.isNotEmpty) {
          q = q1;
        } else {
          final q2 = _firestore.collection('notifications').where('ownerId', isEqualTo: ownerId).orderBy('timestamp', descending: true);
          final snap2 = await q2.limit(1).get();
          if (snap2.docs.isNotEmpty) q = q2;
        }
      }

      _sub = q.snapshots().listen((snap) {
        final List<Map<String, dynamic>> items = snap.docs.map((d) {
          final data = d.data();
          return {
            'id': d.id,
            'title': data['title'] ?? data['judul'] ?? 'Notifikasi',
            'body': data['body'] ?? data['pesan'] ?? data['message'] ?? '',
            'timestamp': data['timestamp'] ?? data['time'] ?? data['created_at'],
            'productId': data['productId'] ?? data['product_id'] ?? data['productIdRef'],
            'raw': data,
          };
        }).toList();
        setState(() {
          _items = items;
          _loading = false;
        });
        // If notifications collection is empty, try products fallback
        if (_items.isEmpty) {
          _loadExpiredFromProducts(ownerId);
        }
      }, onError: (e) {
        setState(() {
          _items = [];
          _loading = false;
        });
        // try fallback when listening errors
        _loadExpiredFromProducts(ownerId);
      });
    } catch (e) {
      setState(() {
        _items = [];
        _loading = false;
      });
      // try fallback when initial query fails (index/security/etc.)
      _loadExpiredFromProducts(ownerId);
    }
  }

  Future<void> _loadExpiredFromProducts(String ownerId) async {
    try {
      final now = DateTime.now();
      Query<Map<String, dynamic>> q = _firestore.collection('products');
      if (ownerId.isNotEmpty) {
        final q1 = _firestore.collection('products').where('ownerid', isEqualTo: ownerId);
        final snap1 = await q1.limit(1).get();
        if (snap1.docs.isNotEmpty) q = q1;
        else {
          final q2 = _firestore.collection('products').where('ownerId', isEqualTo: ownerId);
          final snap2 = await q2.limit(1).get();
          if (snap2.docs.isNotEmpty) q = q2;
        }
      }

      final snap = await q.get();
      final items = <Map<String, dynamic>>[];
      for (final d in snap.docs) {
        final data = d.data();
        // find expiry
        DateTime? expDate;
        final candidates = ['tanggal_expired', 'tanggal_expire', 'expiredDate', 'expired_at', 'expired_date', 'expired'];
        for (final f in candidates) {
          if (data.containsKey(f) && expDate == null) {
            final raw = data[f];
            if (raw is Timestamp) expDate = raw.toDate();
            else if (raw is int) expDate = raw > 1000000000000 ? DateTime.fromMillisecondsSinceEpoch(raw) : DateTime.fromMillisecondsSinceEpoch(raw * 1000);
            else if (raw is String) {
              try { expDate = DateTime.parse(raw); } catch (_) {}
            }
          }
        }
        if (expDate != null && expDate.isBefore(now)) {
          final name = data['nama_product'] ?? data['nama'] ?? 'Produk';
          // Ensure a notifications document exists for this product expiry so it can be deleted by the UI
          try {
            // check existing notification docs referencing this product
            final existing1 = await _firestore.collection('notifications').where('productId', isEqualTo: d.id).limit(1).get();
            final existing2 = await _firestore.collection('notifications').where('product_id', isEqualTo: d.id).limit(1).get();
            if (existing1.docs.isNotEmpty) {
              final doc = existing1.docs.first;
              items.add({
                'id': doc.id,
                'title': doc.data()['title'] ?? '$name kadaluarsa',
                'body': doc.data()['body'] ?? '$name telah kadaluarsa pada ${DateFormat('dd MMM yyyy').format(expDate)}',
                'timestamp': doc.data()['timestamp'] ?? expDate,
                'productId': d.id,
                'raw': doc.data(),
              });
            } else if (existing2.docs.isNotEmpty) {
              final doc = existing2.docs.first;
              items.add({
                'id': doc.id,
                'title': doc.data()['title'] ?? '$name kadaluarsa',
                'body': doc.data()['body'] ?? '$name telah kadaluarsa pada ${DateFormat('dd MMM yyyy').format(expDate)}',
                'timestamp': doc.data()['timestamp'] ?? expDate,
                'productId': d.id,
                'raw': doc.data(),
              });
            } else {
              // create a new notification doc so UI can delete it
              final newDoc = await _firestore.collection('notifications').add({
                'ownerid': ownerId,
                'productId': d.id,
                'title': '$name kadaluarsa',
                'body': '$name telah kadaluarsa pada ${DateFormat('dd MMM yyyy').format(expDate)}',
                'timestamp': expDate,
                'type': 'expired_product',
              });
              items.add({
                'id': newDoc.id,
                'title': '$name kadaluarsa',
                'body': '$name telah kadaluarsa pada ${DateFormat('dd MMM yyyy').format(expDate)}',
                'timestamp': expDate,
                'productId': d.id,
                'raw': {'productId': d.id},
              });
            }
          } catch (_) {
            // fallback to in-memory item if Firestore ops fail
            items.add({
              'id': 'product_${d.id}',
              'title': '$name kadaluarsa',
              'body': '$name telah kadaluarsa pada ${DateFormat('dd MMM yyyy').format(expDate)}',
              'timestamp': expDate,
              'productId': d.id,
              'raw': data,
            });
          }
        }
      }

      if (items.isNotEmpty) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: NotificationsPage(items: _items, loading: _loading),
    );
  }
}
