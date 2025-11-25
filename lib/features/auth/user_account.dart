import 'dart:convert';

/// Represents the authenticated account metadata shared across the app.
class UserAccount {
  const UserAccount({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
      };

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserAccount.fromJson(String source) {
    final map = jsonDecode(source);
    if (map is! Map<String, dynamic>) {
      throw FormatException('Invalid UserAccount JSON');
    }
    return UserAccount.fromMap(map);
  }

  static UserAccount? tryFromJson(String? source) {
    if (source == null) return null;
    try {
      return UserAccount.fromJson(source);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAccount &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName;
  }

  @override
  int get hashCode => Object.hash(id, email, displayName);
}
