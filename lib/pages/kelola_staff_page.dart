// lib/pages/kelola_staff_page.dart
import 'package:flutter/material.dart';
import '../screens/staff_screen.dart';
import '../models/user_model.dart';
import 'tambah_staff_page.dart';
import 'edit_staff_page.dart';

class KelolaStaffPage extends StatefulWidget {
  final String ownerId;
  final String ownerCompanyName;
  final User currentUser;

  const KelolaStaffPage({
    super.key,
    required this.ownerId,
    required this.ownerCompanyName,
    required this.currentUser,
  });

  @override
  State<KelolaStaffPage> createState() => _KelolaStaffPageState();
}

class _KelolaStaffPageState extends State<KelolaStaffPage> {
  final StaffScreen _staffScreen = StaffScreen();
  final TextEditingController _searchController = TextEditingController();
  // ignore: unused_field
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 41, 101, 192),
        elevation: 0.6,
        title: const Text('Kelola Staff', style: TextStyle(color: Colors.black87)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDatePill(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildInfoCard(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: _buildSearchField(),
              ),
              const SizedBox(height: 12),
              // Staff list + summary handled inside StreamBuilder
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: _buildStaffList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePill() {
    // date display removed per request; return empty widget
    return const SizedBox.shrink();
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.business, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.ownerCompanyName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const Text('Kelola staff perusahaan Anda di sini', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _navigateToTambahStaff,
              icon: Icon(
                Icons.person_add_alt_1,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                'Tambah Staff',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2965C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                side: BorderSide.none,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minimumSize: const Size(0, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari staff...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (value) => setState(() {}),
    );
  }

  Widget _buildStaffList() {
    return StreamBuilder<List<User>>(
      stream: _staffScreen.getStaffStream(widget.ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final staffList = snapshot.data ?? [];
        final total = staffList.length;
        final activeCount = staffList.where((s) => s.isActive).length;
        final inactiveCount = total - activeCount;
        final searchQuery = _searchController.text.toLowerCase();
        
        final filteredStaff = searchQuery.isEmpty
            ? staffList
            : staffList.where((staff) {
                return staff.displayName.toLowerCase().contains(searchQuery) ||
                       staff.username.toLowerCase().contains(searchQuery) ||
                       staff.email.toLowerCase().contains(searchQuery);
              }).toList();

        if (filteredStaff.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2965C0), Color(0xFF3EA343)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('$total', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Aktif: $activeCount', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Nonaktif: $inactiveCount', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView.builder(
                  padding: const EdgeInsets.all(0),
                  itemCount: filteredStaff.length,
                  itemBuilder: (context, index) {
                    final staff = filteredStaff[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildStaffCard(staff),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaffCard(User staff) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: staff.isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade300,
                  child: Icon(
                    Icons.person,
                    color: staff.isActive ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: staff.isActive ? Colors.black : Colors.grey,
                        ),
                      ),
                      Text(
                        '@${staff.username}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(
                            staff.isActive ? Icons.block : Icons.check_circle,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(staff.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset, size: 20),
                          SizedBox(width: 8),
                          Text('Reset Password'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) => _handleMenuAction(value, staff),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Staff details
            Padding(
              padding: const EdgeInsets.only(left: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          staff.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bergabung: ${_formatDate(staff.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: staff.isActive
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          staff.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: staff.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada staff',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan staff pertama Anda',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToTambahStaff,
            icon: const Icon(Icons.person_add),
            label: const Text('Tambah Staff'),
          ),
        ],
      ),
    );
  }

  void _navigateToTambahStaff() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TambahStaffPage(
          ownerId: widget.ownerId,
          ownerCompanyName: widget.ownerCompanyName,
        ),
      ),
    ).then((value) {
      if (value == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _handleMenuAction(String action, User staff) async {
    switch (action) {
      case 'edit':
        await _navigateToEditStaff(staff);
        break;
      case 'status':
        await _toggleStaffStatus(staff);
        break;
      case 'reset_password':
        await _showResetPasswordDialog(staff);
        break;
      case 'delete':
        await _showDeleteConfirmation(staff);
        break;
    }
  }

  Future<void> _navigateToEditStaff(User staff) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStaffPage(staff: staff),
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data staff berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleStaffStatus(User staff) async {
    setState(() {
      _isLoading = true;
    });

    final newStatus = !staff.isActive;
    final result = await _staffScreen.editStaff(
      staffId: staff.id,
      displayName: staff.displayName,
      email: staff.email,
      isActive: newStatus,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showResetPasswordDialog(User staff) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Reset password untuk ${staff.displayName}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password tidak cocok')),
                  );
                  return;
                }

                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password minimal 6 karakter')),
                  );
                  return;
                }

                final result = await _staffScreen.resetStaffPassword(
                  staffId: staff.id,
                  newPassword: passwordController.text,
                );

                if (result['success']) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    passwordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showDeleteConfirmation(User staff) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Staff'),
          content: Text(
            'Apakah Anda yakin ingin menghapus ${staff.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                Navigator.pop(context);
                await _deleteStaff(staff);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStaff(User staff) async {
    setState(() {
      _isLoading = true;
    });

    final result = await _staffScreen.deleteStaff(staff.id);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}