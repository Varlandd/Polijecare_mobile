/// Model pengguna (sesuai `App\Models\User` & response `NewLoginController.php`).
class AppUser {
  final int id;
  final String name;
  final String email;
  final String role; // 'operator' (Super Admin), 'konselor' (Satgas), 'user', 'admin'
  final String? nim;
  final String? semester;
  final String? phone;
  final String? gender;
  final String? unit;
  final String? prodi;
  final String? bio;
  final String? profilePhoto;
  final String? avatar;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.nim,
    this.semester,
    this.phone,
    this.gender,
    this.unit,
    this.prodi,
    this.bio,
    this.profilePhoto,
    this.avatar,
  });

  String get normalizedRole => role.trim().toLowerCase();

  /// Sesuai `User::isSuperAdmin()` & `User::isOperator()` di Laravel.
  bool get isSuperAdmin =>
      normalizedRole == 'operator' || normalizedRole == 'admin';

  bool get isOperator => normalizedRole == 'operator';

  /// Sesuai `User::isSatgas()` di Laravel.
  bool get isSatgas => normalizedRole == 'konselor';

  /// Sesuai `User::isStudent()` di Laravel.
  bool get isStudent => normalizedRole == 'user';

  /// Nama depan (digunakan pada sapaan dashboard & sidebar web).
  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Admin';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  /// Inisial huruf pertama untuk avatar sidebar.
  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    return trimmed[0].toUpperCase();
  }

  /// Label role sesuai `Sidebar.jsx` di web.
  String get roleLabel {
    switch (normalizedRole) {
      case 'operator':
      case 'admin':
        return 'Super Admin';
      case 'konselor':
        return 'Satgas (Petugas)';
      case 'user':
      default:
        return 'User';
    }
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      nim: json['nim']?.toString(),
      semester: json['semester']?.toString(),
      phone: json['phone']?.toString(),
      gender: json['gender']?.toString(),
      unit: json['unit']?.toString(),
      prodi: json['prodi']?.toString(),
      bio: json['bio']?.toString(),
      profilePhoto: json['profile_photo']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'nim': nim,
      'semester': semester,
      'phone': phone,
      'gender': gender,
      'unit': unit,
      'prodi': prodi,
      'bio': bio,
      'profile_photo': profilePhoto,
      'avatar': avatar,
    };
  }
}

