import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class NotificationsPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;

  const NotificationsPage({super.key, required this.items, required this.loading});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<Map<String, dynamic>> _localItems;
  final Set<String> _dismissed = {};
  String? _hoveredId;

  @override
  void initState() {
    super.initState();
    _localItems = widget.items.where((it) => !_dismissed.contains(it['id']?.toString() ?? '')).toList();
  }

  @override
  void didUpdateWidget(covariant NotificationsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh local items but keep dismissed items removed
    _localItems = widget.items.where((it) => !_dismissed.contains(it['id']?.toString() ?? '')).toList();
  }

  String _formatTimestamp(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp) dt = ts.toDate();
      else if (ts is int) {
        if (ts > 1000000000000) dt = DateTime.fromMillisecondsSinceEpoch(ts);
        else dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      } else if (ts is String) dt = DateTime.parse(ts);
      else return '';
      return DateFormat('dd MMM yyyy HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> _dismissItem(Map<String, dynamic> it) async {
    final id = (it['id'] ?? '').toString();
    if (id.isEmpty) return;

    // If this is a generated product notification, try to delete any matching Firestore notifications by productId
    if (id.startsWith('product_')) {
      final productId = id.replaceFirst('product_', '');
      try {
        final q1 = await FirebaseFirestore.instance.collection('notifications').where('productId', isEqualTo: productId).get();
        final q2 = await FirebaseFirestore.instance.collection('notifications').where('product_id', isEqualTo: productId).get();
        final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        docs.addAll(q1.docs);
        docs.addAll(q2.docs);
        if (docs.isNotEmpty) {
          for (final d in docs) {
            try {
              await FirebaseFirestore.instance.collection('notifications').doc(d.id).delete();
            } catch (_) {}
          }
        }
      } catch (_) {}

      // Always remove locally
      setState(() {
        _dismissed.add(id);
        _localItems.removeWhere((e) => (e['id'] ?? '') == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi dihapus')));
      return;
    }

    // Otherwise attempt to delete the Firestore notification document
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(id).delete();
      // mark dismissed to prevent widget updates from re-adding
      setState(() {
        _dismissed.add(id);
        _localItems.removeWhere((e) => (e['id'] ?? '') == id);
      });
      // debug log
      // ignore: avoid_print
      print('Deleted notification doc: $id');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi dihapus')));
    } catch (e) {
      // ignore: avoid_print
      print('Failed to delete notification $id: $e');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus notifikasi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.loading;
    final items = _localItems;

    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.red[700]),
            const SizedBox(height: 16),
            Text('Memuat notifikasi...', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('Belum ada notifikasi', style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey[50],
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final it = items[i];
          final title = it['title']?.toString() ?? 'Notifikasi';
          final body = it['body']?.toString() ?? '';
          final ts = it['timestamp'];
          final time = _formatTimestamp(ts);

          return Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/expired');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red[100]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red[200]?.withOpacity(0.15) ?? Colors.transparent,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  color: Colors.red[700],
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.red[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (time.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          time,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'KADALUARSA',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                body,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Spacer(),
                              Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 4),
                              Text(
                                'Lihat Produk',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _hoveredId = (it['id'] ?? '').toString()),
                    onExit: (_) => setState(() => _hoveredId = null),
                    child: InkResponse(
                      onTap: () => _dismissItem(it),
                      radius: 20,
                      containedInkWell: true,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: (_hoveredId == (it['id'] ?? '').toString()) ? Colors.grey.withOpacity(0.18) : Colors.grey.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18, color: (_hoveredId == (it['id'] ?? '').toString()) ? Colors.black87 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
