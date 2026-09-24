import 'package:flutter/material.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/medicare_entry_screen.dart';
import '../../features/auth/protected_role_home_screen.dart';
import '../auth/models/account_role.dart';

class AuthNavigation {
  const AuthNavigation._();

  static void openRoleHome(BuildContext context, AccountRole role) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => ProtectedRoleHomeScreen(role: role)),
      (_) => false,
    );
  }

  static void openSignedOutFlow(BuildContext context) {
    AuthRepositoryImpl.instance.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MedicareEntryScreen()),
      (_) => false,
    );
  }
}
