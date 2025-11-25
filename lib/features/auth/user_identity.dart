/// Utility helpers for deriving stable user identifiers in the mock backend.
class UserIdentity {
  const UserIdentity._();

  static String idForEmail(String email) =>
      'user-${email.trim().toLowerCase().hashCode}';
}
