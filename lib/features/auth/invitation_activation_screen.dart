import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import 'invitation_activation_screen_state.dart';

class InvitationActivationScreen extends StatefulWidget {
  const InvitationActivationScreen({super.key, required this.role});

  final AccountRole role;

  @override
  State<InvitationActivationScreen> createState() => InvitationActivationScreenState();
}
