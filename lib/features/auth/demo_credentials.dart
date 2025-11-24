/// Demo-only credentials used by the auth gate for testing and presentations.
const String demoAuthEmail = '1234567@69.com';
const String demoAuthPassword = '67';
const String demoVerificationCode = '000000';

bool isDemoAccount({
  required String email,
  required String password,
}) =>
    email == demoAuthEmail && password == demoAuthPassword;

bool isDemoEmail(String email) => email == demoAuthEmail;
