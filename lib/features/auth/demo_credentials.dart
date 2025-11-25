import 'user_account.dart';

/// Demo-only credentials used by the auth gate for testing and presentations.
const String demoEmail = '1234567@69.com';
const String demoPassword = '67';
const String demoVerificationCode = '000000';

const demoUserAccount = UserAccount(
  id: 'demo-argo',
  email: demoEmail,
  displayName: 'Argo',
);

bool isDemoAccount({
  required String email,
  required String password,
}) =>
    email == demoEmail && password == demoPassword;

bool isDemoEmail(String email) => email == demoEmail;
