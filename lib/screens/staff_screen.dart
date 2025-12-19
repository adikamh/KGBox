// lib/screens/staff_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import '../models/user_model.dart';

class StaffScreen {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> addStaff({
    required String username,
    required String displayName,
    required String email,
    required String password,
    required String ownerId,
    required String ownerCompanyName,
  }) async {
    try {
      final usernameQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .get();
      
      if (usernameQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Username sudah digunakan'
        };
      }
      
      // 2. Validasi email unik
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();
      
      if (emailQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email sudah digunakan'
        };
      }
      
      // 3. Buat user di Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 4. Simpan data user di Firestore
      final newUser = User(
        id: userCredential.user!.uid,
        username: username.toLowerCase(),
        displayName: displayName,
        email: email.toLowerCase(),
        role: UserRole.staff,
        companyName: ownerCompanyName,
        ownerId: ownerId,
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(newUser.id)
          .set(newUser.toMap());
      
      return {
        'success': true,
        'message': 'Staff berhasil ditambahkan',
        'user': newUser,
      };
      
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _getAuthErrorMessage(e.code),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Edit staff
  Future<Map<String, dynamic>> editStaff({
    required String staffId,
    required String displayName,
    required String email,
    required bool isActive,
  }) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(staffId)
          .get();
      
      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'Staff tidak ditemukan'
        };
      }
      
      final userData = userDoc.data()!;
      
      // Validasi email unik (kecuali untuk email sendiri)
      if (email.toLowerCase() != userData['email']) {
        final emailQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .get();
        
        if (emailQuery.docs.isNotEmpty) {
          return {
            'success': false,
            'message': 'Email sudah digunakan'
          };
        }
      }
      
      // Update data di Firestore
      await _firestore
          .collection('users')
          .doc(staffId)
          .update({
            'displayName': displayName,
            'email': email.toLowerCase(),
            'isActive': isActive,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      
      return {
        'success': true,
        'message': 'Data staff berhasil diperbarui'
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Hapus staff
  Future<Map<String, dynamic>> deleteStaff(String staffId) async {
    try {
      // Cek apakah staff memiliki data terkait
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: staffId)
          .limit(1)
          .get();
      
      if (transactionsQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Staff tidak dapat dihapus karena memiliki riwayat transaksi'
        };
      }
      
      // Hapus dari Firestore
      await _firestore
          .collection('users')
          .doc(staffId)
          .delete();
      
      return {
        'success': true,
        'message': 'Staff berhasil dihapus'
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Reset password staff
  Future<Map<String, dynamic>> resetStaffPassword({
    required String staffId,
    required String newPassword,
  }) async {
    try {
      // Mendapatkan email staff dari Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(staffId)
          .get();
      
      if (!userDoc.exists) {
        return {
          'success': false,
          'message': 'Staff tidak ditemukan'
        };
      }
      
      final userData = userDoc.data()!;
      final email = userData['email'];
      
      // Di production, gunakan Firebase Functions untuk reset password
      // Ini implementasi sederhana
      try {
        await _auth.sendPasswordResetEmail(email: email);
        return {
          'success': true,
          'message': 'Permintaan reset password berhasil'
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Gagal reset password: $e'
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Get semua staff berdasarkan ownerId
  Stream<List<User>> getStaffStream(String ownerId) {
    // Remove server-side orderBy to avoid requiring a composite index.
    // We still filter server-side and sort client-side by `createdAt`.
    return _firestore
        .collection('users')
        .where('ownerId', isEqualTo: ownerId)
        .where('role', isEqualTo: UserRole.staff.name)
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return users;
        });
  }
  
  // Get staff by ID
  Future<User?> getStaffById(String staffId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(staffId)
          .get();
      
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error get staff by ID: $e');
      return null;
    }
  }
  
  // Helper method untuk error auth
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'operation-not-allowed':
        return 'Operasi tidak diizinkan';
      case 'weak-password':
        return 'Password terlalu lemah';
      default:
        return 'Terjadi kesalahan autentikasi';
    }
  }
  
  // Validasi form input
  Map<String, String?> validateStaffForm({
    required String username,
    required String displayName,
    required String email,
    required String password,
  }) {
    final errors = <String, String?>{};
    
    if (username.isEmpty) {
      errors['username'] = 'Username wajib diisi';
    } else if (username.length < 3) {
      errors['username'] = 'Username minimal 3 karakter';
    } else if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      errors['username'] = 'Username hanya boleh huruf, angka, dan underscore';
    }
    
    if (displayName.isEmpty) {
      errors['displayName'] = 'Nama lengkap wajib diisi';
    } else if (displayName.length < 2) {
      errors['displayName'] = 'Nama lengkap minimal 2 karakter';
    }
    
    if (email.isEmpty) {
      errors['email'] = 'Email wajib diisi';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      errors['email'] = 'Format email tidak valid';
    }
    
    if (password.isEmpty) {
      errors['password'] = 'Password wajib diisi';
    } else if (password.length < 6) {
      errors['password'] = 'Password minimal 6 karakter';
    }
    
    return errors;
  }
}