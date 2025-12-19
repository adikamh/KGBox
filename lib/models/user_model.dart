enum UserRole { owner, staff }

class User {
  String id; // Firebase Auth UID
  String username; // UNIK - untuk login & identifier
  String displayName; // Nama lengkap untuk display
  String email;
  UserRole role;
  
  // Hanya untuk owner
  String? companyName;
  String? ownerId; // Untuk staff: referensi ke ownernya
  
  // Untuk semua user
  bool isActive;
  DateTime createdAt;
  DateTime? lastLogin;
  
  User({
    required this.id,
    required this.username,
    required this.displayName,
    required this.email,
    required this.role,
    this.companyName,
    this.ownerId,
    this.isActive = true,
    required this.createdAt,
    this.lastLogin,
  });
  
  // Helper methods
  bool get isOwner => role == UserRole.owner;
  bool get isStaff => role == UserRole.staff;
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username.toLowerCase(), // Simpan lowercase
      'displayName': displayName,
      'email': email,
      'role': role.name, // 'owner' atau 'staff'
      'companyName': companyName,
      'ownerId': ownerId, // null untuk owner, isi untuk staff
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }
  
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      displayName: map['displayName'],
      email: map['email'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.staff,
      ),
      companyName: map['companyName'],
      ownerId: map['ownerId'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null 
          ? DateTime.parse(map['lastLogin'])
          : null,
    );
  }
}