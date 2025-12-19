import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/username_service.dart';

class AuthProvider with ChangeNotifier {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UsernameService _usernameService = UsernameService();
  
  bool _isLoading = false;
  User? _currentUser;
  
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  bool get isOwner => _currentUser?.isOwner ?? false;
  bool get isStaff => _currentUser?.isStaff ?? false;
  
  // REGISTER OWNER
  Future<AuthResult> registerOwner({
    required String username,
    required String email,
    required String password,
    required String companyName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // 1. Validasi username
      if (!UsernameService.isValidUsername(username)) {
        return AuthResult(
          success: false,
          message: 'Username tidak valid (3-20 karakter, huruf/angka/_/.)',
        );
      }
      
      // 2. Check username uniqueness
      final isAvailable = await _usernameService.isUsernameAvailable(username);
      if (!isAvailable) {
        return AuthResult(
          success: false,
          message: 'Username "$username" sudah digunakan',
        );
      }
      
      // 3. Create Firebase Auth user
      final fb.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // 4. Create user document in Firestore dengan role owner
      final user = User(
        id: userCredential.user!.uid,
        username: username.toLowerCase(),
        displayName: username, // Display name = username
        email: email,
        role: UserRole.owner,
        companyName: companyName,
        ownerId: userCredential.user!.uid, // ownerId otomatis = uid pemilik
        isActive: true,
        createdAt: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toMap());
      
      // 5. Update user display name in Firebase Auth
      await userCredential.user!.updateDisplayName(username);
      
      _currentUser = user;
      
      return AuthResult(success: true);
      
    } on fb.FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan saat registrasi';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email sudah terdaftar';
          break;
        case 'weak-password':
          message = 'Password terlalu lemah (minimal 8 karakter)';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid';
          break;
        case 'operation-not-allowed':
          message = 'Registrasi email/password tidak diizinkan';
          break;
      }
      return AuthResult(success: false, message: message);
    } catch (e) {
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // LOGIN dengan username/email
  Future<AuthResult> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      String email;
      
      // Cek apakah input adalah email atau username
      if (UsernameService.isEmail(usernameOrEmail)) {
        email = usernameOrEmail;
      } else {
        // Jika username, cari email-nya di Firestore
        final userSnapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail.toLowerCase())
            .limit(1)
            .get();
        
        if (userSnapshot.docs.isEmpty) {
          return AuthResult(
            success: false,
            message: 'Username/email tidak ditemukan',
          );
        }
        
        email = userSnapshot.docs.first.data()['email'];
      }
      
      // Login dengan email & password
      final fb.UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Ambil data user dari Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      if (!userDoc.exists) {
        await _auth.signOut();
        return AuthResult(
          success: false,
          message: 'Data user tidak ditemukan',
        );
      }
      
      final user = User.fromMap(userDoc.data()!);
      
      // Cek apakah user active
      if (!user.isActive) {
        await _auth.signOut();
        return AuthResult(
          success: false,
          message: 'Akun dinonaktifkan. Hubungi owner.',
        );
      }
      
      // Update last login
      await _firestore
          .collection('users')
          .doc(user.id)
          .update({'lastLogin': DateTime.now().toIso8601String()});
      
      _currentUser = user;
      
      return AuthResult(success: true);
      
    } on fb.FirebaseAuthException catch (e) {
      String message = 'Gagal login';
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          message = 'Username/email atau password salah';
          break;
        case 'user-disabled':
          message = 'Akun dinonaktifkan';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan gagal. Coba lagi nanti.';
          break;
      }
      return AuthResult(success: false, message: message);
    } catch (e) {
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // FORGOT PASSWORD
  Future<AuthResult> forgotPassword(String usernameOrEmail) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      String email;
      
      if (UsernameService.isEmail(usernameOrEmail)) {
        email = usernameOrEmail;
      } else {
        // Cari email berdasarkan username
        final userSnapshot = await _firestore
            .collection('users')
            .where('username', isEqualTo: usernameOrEmail.toLowerCase())
            .limit(1)
            .get();
        
        if (userSnapshot.docs.isEmpty) {
          return AuthResult(
            success: false,
            message: 'Username/email tidak ditemukan',
          );
        }
        
        email = userSnapshot.docs.first.data()['email'];
      }
      
      await _auth.sendPasswordResetEmail(email: email);
      
      return AuthResult(
        success: true,
        message: 'Email reset password telah dikirim ke $email',
      );
      
    } on fb.FirebaseAuthException catch (e) {
      String message = 'Gagal mengirim email reset';
      if (e.code == 'user-not-found') {
        message = 'Email tidak ditemukan';
      }
      return AuthResult(success: false, message: message);
    } catch (e) {
      return AuthResult(success: false, message: 'Error: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
  
  // AUTO LOGIN (check session)
  Future<void> checkAuthStatus() async {
    final currentAuthUser = _auth.currentUser;
    
    if (currentAuthUser != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentAuthUser.uid)
          .get();
      
      if (userDoc.exists) {
        _currentUser = User.fromMap(userDoc.data()!);
        notifyListeners();
      }
    }
  }
}

class AuthResult {
  final bool success;
  final String? message;
  
  AuthResult({required this.success, this.message});
}