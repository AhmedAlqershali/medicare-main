import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import 'role_login_screen_state.dart';

class RoleLoginScreen extends StatefulWidget {
  const RoleLoginScreen({super.key, required this.role});

  final AccountRole role;

  @override
  State<RoleLoginScreen> createState() => RoleLoginScreenState();
}
