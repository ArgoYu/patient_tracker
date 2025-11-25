import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import 'user_account.dart';

/// Exposes the current authenticated [UserAccount] to descendant widgets.
class AuthSessionScope extends InheritedNotifier<ValueListenable<UserAccount?>> {
  const AuthSessionScope({
    super.key,
    required ValueListenable<UserAccount?> notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  ValueListenable<UserAccount?> get accountListenable =>
      notifier as ValueListenable<UserAccount?>;

  UserAccount? get currentUserAccount => accountListenable.value;

  static AuthSessionScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthSessionScope>();
    if (scope == null) {
      throw FlutterError(
        'AuthSessionScope.of() called with a context that does not contain '
        'an AuthSessionScope.',
      );
    }
    return scope;
  }
}
