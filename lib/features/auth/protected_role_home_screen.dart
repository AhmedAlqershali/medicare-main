import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import '../../core/routing/auth_navigation.dart';
import '../doctor/doctor_home_screen.dart';
import '../organization/organization_home_screen.dart';
import '../patient/patient_home_screen.dart';
import 'data/repositories/auth_repository_impl.dart';

class ProtectedRoleHomeScreen extends StatelessWidget {
  const ProtectedRoleHomeScreen({super.key, required this.role});

  final AccountRole role;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = AuthRepositoryImpl.instance.isAuthenticated;
    final currentRole = AuthRepositoryImpl.instance.currentRole;
    if (!isAuthenticated || currentRole != role) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) AuthNavigation.openSignedOutFlow(context);
      });
      return const SizedBox.shrink();
    }
    return switch (role) {
      AccountRole.patient => const PatientHomeScreen(),
      AccountRole.doctor => const DoctorHomeScreen(),
      AccountRole.organization => const OrganizationHomeScreen(),
    };
  }
}
