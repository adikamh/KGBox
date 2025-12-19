import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      // Log removed for production; return false on error
      return false;
    }
  }
  
  // Validasi format username
  static bool isValidUsername(String username) {
    // Hanya huruf, angka, underscore, titik
    final regex = RegExp(r'^[a-zA-Z0-9._]+$');
    return regex.hasMatch(username) && 
           username.length >= 3 && 
           username.length <= 20;
  }
  
  // Cek apakah username adalah email
  static bool isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }
  
  // Saran username alternatif
  static List<String> suggestUsernames(String baseUsername) {
    final suggestions = <String>[];
    final now = DateTime.now();
    
    suggestions.add('${baseUsername}_${now.millisecondsSinceEpoch.toString().substring(8)}');
    suggestions.add('$baseUsername${now.day}${now.month}');
    suggestions.add('$baseUsername${now.hour}${now.minute}');
    
    return suggestions;
  }
}