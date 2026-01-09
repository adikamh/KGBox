import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kgbox/providers/auth_provider.dart';

class StokOwnerScreen extends StatefulWidget {
	const StokOwnerScreen({super.key});

	@override
	State<StokOwnerScreen> createState() => _StokOwnerScreenState();
}

class _StokOwnerScreenState extends State<StokOwnerScreen> {
	final FirebaseFirestore _firestore = FirebaseFirestore.instance;

	final TextEditingController _searchController = TextEditingController();
	String _searchQuery = '';
	String _statusFilter = 'Semua'; // Filter status: 'Semua', 'Terima', 'Tolak'

	String _formatDate(String? iso) {
		if (iso == null) return '-';
		try {
			final dt = DateTime.parse(iso);
			return DateFormat('dd MMM yyyy HH:mm').format(dt.toLocal());
		} catch (_) {
			return iso;
		}
	}

	Future<void> _updateStatus(String docId, String status) async {
		await _firestore.collection('stock_requests').doc(docId).update({
			'status': status,
			'updated_at': DateTime.now().toIso8601String(),
		});
		if (mounted) {
			ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status diubah: $status')));
		}
	}

	Future<void> _assignSupplier(String requestId) async {
		showDialog(
			context: context,
			builder: (context) {
				return Dialog(
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
					child: SizedBox(
						width: 420,
						height: 480,
						child: Column(
							children: [
								Padding(
									padding: const EdgeInsets.all(12.0),
									child: Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											const Text('Pilih Supplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
											IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
										],
									),
								),
								const Divider(height: 1),
								Expanded(
									child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
										stream: _firestore.collection('suppliers').snapshots(),
										builder: (context, snap) {
											if (snap.hasError) return const Center(child: Text('Gagal memuat supplier'));
											if (!snap.hasData) return const Center(child: CircularProgressIndicator());
											final docs = snap.data!.docs;
											if (docs.isEmpty) return const Center(child: Text('Belum ada supplier'));
											return ListView.separated(
												padding: const EdgeInsets.all(8),
												itemCount: docs.length,
												separatorBuilder: (_, __) => const Divider(height: 1),
												itemBuilder: (context, index) {
													final d = docs[index].data();
													final agent = (d['nama_agen'] ?? d['agent_name'] ?? d['name'])?.toString() ?? '';
													final company = (d['nama_perusahaan'] ?? d['company_name'] ?? d['company'])?.toString() ?? '';
													final contact = (d['contact'] ?? d['email'])?.toString() ?? '';

													final titleText = agent.isNotEmpty ? agent : (company.isNotEmpty ? company : docs[index].id);
													final subtitleParts = <String>[];
													if (company.isNotEmpty) subtitleParts.add(company);
													if (contact.isNotEmpty) subtitleParts.add(contact);
													final subtitleText = subtitleParts.isNotEmpty ? subtitleParts.join(' · ') : null;

													return ListTile(
														title: Text(titleText),
														subtitle: subtitleText == null ? null : Text(subtitleText),
														onTap: () async {
															await _firestore.collection('stock_requests').doc(requestId).update({
																'supplier_id': docs[index].id,
																'supplier_agent': agent,
																'supplier_company': company,
																'supplier_name': titleText,
																'updated_at': DateTime.now().toIso8601String(),
															});
															if (mounted) {
																ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier dipilih')));
															}

															Navigator.of(context).pop();
														},
													);
												},
											);
										},
									),
								),
							],
						),
					),
				);
			},
		);
	}

	Future<void> _handleStatusChange(QueryDocumentSnapshot<Map<String, dynamic>> doc, String value) async {
		final data = doc.data();
		final supplierId = data['supplier_id'] ?? '';

		// Require supplier selection before allowing any status change.
		if (supplierId == null || supplierId.toString().isEmpty) {
			// Prompt user to pick supplier first. After picking, apply the desired status.
			await _assignSupplierAndMaybeSetStatus(doc.id, value);
			return;
		}

		await _updateStatus(doc.id, value);
	}

	Future<void> _assignSupplierAndMaybeSetStatus(String requestId, String? targetStatus) async {
		await showDialog(
			context: context,
			builder: (context) {
				return Dialog(
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
					child: SizedBox(
						width: 420,
						height: 480,
						child: Column(
							children: [
								Padding(
									padding: const EdgeInsets.all(12.0),
									child: Row(
										mainAxisAlignment: MainAxisAlignment.spaceBetween,
										children: [
											const Text('Pilih Supplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
											IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
										],
									),
								),
								const Divider(height: 1),
								Expanded(
									child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
										stream: _firestore.collection('suppliers').snapshots(),
										builder: (context, snap) {
											if (snap.hasError) return const Center(child: Text('Gagal memuat supplier'));
											if (!snap.hasData) return const Center(child: CircularProgressIndicator());
											final docs = snap.data!.docs;
											if (docs.isEmpty) return const Center(child: Text('Belum ada supplier'));
											return ListView.separated(
												padding: const EdgeInsets.all(8),
												itemCount: docs.length,
												separatorBuilder: (_, __) => const Divider(height: 1),
												itemBuilder: (context, index) {
													final d = docs[index].data();
													final agent = (d['nama_agen'] ?? d['agent_name'] ?? d['name'])?.toString() ?? '';
													final company = (d['nama_perusahaan'] ?? d['company_name'] ?? d['company'])?.toString() ?? '';
													final contact = (d['contact'] ?? d['email'])?.toString() ?? '';

													final titleText = agent.isNotEmpty ? agent : (company.isNotEmpty ? company : docs[index].id);
													final subtitleParts = <String>[];
													if (company.isNotEmpty) subtitleParts.add(company);
													if (contact.isNotEmpty) subtitleParts.add(contact);
													final subtitleText = subtitleParts.isNotEmpty ? subtitleParts.join(' · ') : null;

													return ListTile(
														title: Text(titleText),
														subtitle: subtitleText == null ? null : Text(subtitleText),
														onTap: () async {
															final updateMap = {
																'supplier_id': docs[index].id,
																'supplier_agent': agent,
																'supplier_company': company,
																'supplier_name': titleText,
																'updated_at': DateTime.now().toIso8601String(),
															};
															if (targetStatus != null) updateMap['status'] = targetStatus;

															await _firestore.collection('stock_requests').doc(requestId).update(updateMap);
															if (mounted) {
																ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier dipilih')));
															}
															Navigator.of(context).pop();
														},
													);
												},
												);
											},
										),
									),
								],
							),
						),
					);
				},
			);
	}

	@override
	void dispose() {
		_searchController.dispose();
		super.dispose();
	}

	void _showDetailDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
		final data = doc.data();
		final product = data['product_name'] ?? '-';
		final staff = data['nama_staff'] ?? data['staff_id'] ?? '-';
		final company = data['nama_perusahaan'] ?? '-';
		final note = data['catatan'] ?? data['notes'] ?? '-';
		final created = _formatDate(data['created_at']?.toString() ?? data['tanggal_permintaan']?.toString());
		final supplier = (data['supplier_agent'] ?? data['supplier_name'] ?? '') + (data['supplier_company'] != null ? ' · ${data['supplier_company']}' : '');

		showDialog(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: Text('Detail Permintaan'),
					content: SingleChildScrollView(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Produk: $product'),
								const SizedBox(height: 8),
								Text('Diajukan oleh: $staff'),
								const SizedBox(height: 8),
								Text('Perusahaan: $company'),
								const SizedBox(height: 8),
								Text('Tanggal: $created'),
								const SizedBox(height: 12),
								const Text('Catatan:', style: TextStyle(fontWeight: FontWeight.bold)),
								const SizedBox(height: 6),
								Text(note.toString()),
								const SizedBox(height: 12),
								const Text('Supplier:', style: TextStyle(fontWeight: FontWeight.bold)),
								const SizedBox(height: 6),
								Text(supplier.toString().isNotEmpty ? supplier.toString() : '-'),
							],
						),
					),
					actions: [
						TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup')),
					],
				);
			},
		);
	}

	Future<void> _showAcceptDialog(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
		final data = doc.data();
		final note = data['catatan'] ?? data['notes'] ?? '-';
		String? selectedSupplierId;
		String? selectedSupplierAgent;
		String? selectedSupplierCompany;
		String supplierSearch = '';

		await showDialog(
			context: context,
			builder: (context) {
				return StatefulBuilder(builder: (context, setState) {
					return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            title: Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Terima Permintaan Stok',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      note.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pilih Supplier',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setState(() => supplierSearch = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Cari supplier...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 240,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore.collection('suppliers').snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Center(child: Text('Gagal memuat supplier'));
                        }
                        if (!snap.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        var docs = snap.data!.docs;
                        if (supplierSearch.isNotEmpty) {
                          docs = docs.where((d) {
                            final s = d.data();
                            final agent = (s['nama_agen'] ?? s['agent_name'] ?? s['name'])
                                    ?.toString()
                                    .toLowerCase() ??
                                '';
                            final company = (s['nama_perusahaan'] ?? s['company_name'] ?? s['company'])
                                    ?.toString()
                                    .toLowerCase() ??
                                '';
                            return agent.contains(supplierSearch) ||
                                company.contains(supplierSearch) ||
                                d.id.toLowerCase().contains(supplierSearch);
                          }).toList();
                        }

                        if (docs.isEmpty) {
                          return const Center(child: Text('Belum ada supplier'));
                        }

                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, i) {
                            final s = docs[i].data();
                            final agent = (s['nama_agen'] ?? s['agent_name'] ?? s['name'])?.toString() ?? '';
                            final company = (s['nama_perusahaan'] ?? s['company_name'] ?? s['company'])?.toString() ?? '';
                            final titleText = agent.isNotEmpty ? agent : (company.isNotEmpty ? company : docs[i].id);
                            final selected = selectedSupplierId == docs[i].id;

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  selectedSupplierId = docs[i].id;
                                  selectedSupplierAgent = agent;
                                  selectedSupplierCompany = company;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? Colors.green : Colors.grey.shade300,
                                    width: selected ? 2 : 1,
                                  ),
                                  color: selected ? Colors.green.shade50 : Colors.white,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            titleText,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          if (company.isNotEmpty)
                                            Text(
                                              company,
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const Icon(Icons.check_circle, color: Colors.green),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await _firestore.collection('stock_requests').doc(doc.id).update({
                    'status': 'Rejected',
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permintaan ditolak')),
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Tolak',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedSupplierId == null) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih supplier terlebih dahulu')),
                      );
                    }
                    return;
                  }
                  await _firestore.collection('stock_requests').doc(doc.id).update({
                    'supplier_id': selectedSupplierId,
                    'supplier_agent': selectedSupplierAgent ?? '',
                    'supplier_company': selectedSupplierCompany ?? '',
                    'status': 'Accepted',
                    'updated_at': DateTime.now().toIso8601String(),
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Permintaan diterima')),
                    );
                  }
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Terima',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
				});
			},
		);
	}

	@override
	Widget build(BuildContext context) {
		final auth = Provider.of<AuthProvider>(context, listen: false);
		final ownerId = auth.currentUser?.ownerId ?? auth.currentUser?.id ?? '';

		// Use a simple ordered query and filter client-side to avoid requiring a composite index
		final query = _firestore.collection('stock_requests').orderBy('created_at', descending: true);

		return Scaffold(
			appBar: AppBar(
				title: const Text('Permintaan Stok'),
				backgroundColor: Colors.blue.shade700,
				actions: [
					IconButton(
						icon: const Icon(Icons.refresh),
						onPressed: () {
							setState(() {});
							ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menyegarkan data...')));
						},
					),
				],
			),
			body: Column(
				children: [
					Padding(
						padding: const EdgeInsets.all(12.0),
						child: Column(
							children: [
								Row(
									children: [
										Expanded(
											child: TextField(
												controller: _searchController,
												decoration: InputDecoration(
													hintText: 'Cari produk, staff, atau ID permintaan',
													prefixIcon: const Icon(Icons.search),
													border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
												),
												onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
											),
										),
										const SizedBox(width: 8),
										IconButton(
											icon: const Icon(Icons.clear),
											onPressed: () {
												_searchController.clear();
												setState(() => _searchQuery = '');
											},
										),
									],
								),
								const SizedBox(height: 12),
								Row(
									children: [
										const Text('Filter:', style: TextStyle(fontWeight: FontWeight.w600)),
										const SizedBox(width: 12),
										Expanded(
											child: SingleChildScrollView(
												scrollDirection: Axis.horizontal,
												child: Row(
													children: [
														_FilterButton(
															onPressed: () => setState(() => _statusFilter = 'Semua'),
															isActive: _statusFilter == 'Semua',
															label: 'Semua',
														),
														const SizedBox(width: 8),
														_FilterButton(
															onPressed: () => setState(() => _statusFilter = 'Terima'),
															isActive: _statusFilter == 'Terima',
															label: 'Terima',
														),
														const SizedBox(width: 8),
														_FilterButton(
															onPressed: () => setState(() => _statusFilter = 'Tolak'),
															isActive: _statusFilter == 'Tolak',
															label: 'Tolak',
														),
														const SizedBox(width: 8),
														_FilterButton(
															onPressed: () => setState(() => _statusFilter = 'Pending'),
															isActive: _statusFilter == 'Pending',
															label: 'Menunggu',
														),
													],
												),
											),
										),
									],
								),
							],
						),
					),
					Expanded(
						child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
							stream: query.snapshots(),
							builder: (context, snapshot) {
								if (snapshot.hasError) return Center(child: Padding(
									padding: const EdgeInsets.all(12.0),
									child: Text('Gagal memuat data:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
								));
								if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
								var docs = snapshot.data!.docs;

								// if ownerId is provided, filter client-side to avoid composite index requirement
								if (ownerId.isNotEmpty) {
									docs = docs.where((d) {
										final ownerField = d.data()['ownerid'];
										return ownerField != null && ownerField.toString() == ownerId;
									}).toList();
								}

								// apply status filter
								if (_statusFilter != 'Semua') {
									docs = docs.where((d) {
										final data = d.data();
										final status = (data['status'] ?? '').toString().toLowerCase();
										if (_statusFilter == 'Terima') {
											return status == 'accepted' || status == 'approved';
										} else if (_statusFilter == 'Tolak') {
											return status == 'rejected';
										} else if (_statusFilter == 'Pending') {
											return status == 'pending';
										}
										return true;
									}).toList();
								}

								// apply search filter
								if (_searchQuery.isNotEmpty) {
									docs = docs.where((d) {
										final data = d.data();
										final product = (data['product_name'] ?? '').toString().toLowerCase();
										final staff = (data['nama_staff'] ?? data['staff_id'] ?? '').toString().toLowerCase();
										final pid = (data['permintaan_id'] ?? '').toString().toLowerCase();
										final company = (data['nama_perusahaan'] ?? '').toString().toLowerCase();
										return product.contains(_searchQuery) || staff.contains(_searchQuery) || pid.contains(_searchQuery) || company.contains(_searchQuery);
									}).toList();
								}

								if (docs.isEmpty) return const Center(child: Text('Belum ada permintaan stok'));

								return ListView.separated(
									padding: const EdgeInsets.all(12),
									itemCount: docs.length,
									separatorBuilder: (_, __) => const SizedBox(height: 12),
									itemBuilder: (context, index) {
										final doc = docs[index];
										final data = doc.data();
										final product = data['product_name'] ?? '-';
										final staff = data['nama_staff'] ?? data['staff_id'] ?? '-';
										final company = data['nama_perusahaan'] ?? '-';
										final note = data['catatan'] ?? data['notes'] ?? '-';
										final created = _formatDate(data['created_at']?.toString() ?? data['tanggal_permintaan']?.toString());
										final status = data['status'] ?? '-';
										final supplierAgent = data['supplier_agent'] ?? data['supplier_name'] ?? '';
										final supplierCompany = data['supplier_company'] ?? '';
										final supplier = supplierAgent.toString().isNotEmpty
												? supplierAgent.toString() + (supplierCompany.toString().isNotEmpty ? ' · ${supplierCompany.toString()}' : '')
												: (supplierCompany.toString().isNotEmpty ? supplierCompany.toString() : '-');

										Color statusColor = Colors.grey;
										if (status.toString().toLowerCase() == 'pending') statusColor = Colors.orange;
										if (status.toString().toLowerCase() == 'accepted' || status.toString().toLowerCase() == 'approved') statusColor = Colors.green;
										if (status.toString().toLowerCase() == 'rejected') statusColor = Colors.red;

										return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// ==== LEFT INFO ====
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Diajukan oleh: $staff',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    created,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// ==== RIGHT ACTION / STATUS ====
                            if (status.toString().toLowerCase() == 'accepted' ||
                              status.toString().toLowerCase() == 'approved')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                                  SizedBox(width: 6),
                                  Text(
                                    'Diterima',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (status.toString().toLowerCase() == 'rejected')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.cancel, size: 16, color: Colors.red),
                                  SizedBox(width: 6),
                                  Text(
                                    'Ditolak',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () => _showAcceptDialog(doc),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text(
                                'Terima?',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 25, 118, 194),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 2,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
									},
								);
							},
						),
					),
				],
			),
		);
	}
}

class _FilterButton extends StatelessWidget {
	final VoidCallback onPressed;
	final bool isActive;
	final String label;

	const _FilterButton({
		required this.onPressed,
		required this.isActive,
		required this.label,
	});

	@override
	Widget build(BuildContext context) {
		return ElevatedButton(
			onPressed: onPressed,
			style: ElevatedButton.styleFrom(
				backgroundColor: isActive ? Colors.blue : Colors.grey.shade300,
				foregroundColor: isActive ? Colors.white : Colors.black,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
			),
			child: Text(label),
		);
	}
}

