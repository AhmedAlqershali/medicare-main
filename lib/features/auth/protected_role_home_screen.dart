import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../core/routing/auth_navigation.dart';
import '../doctor/complete_doctor_profile_screen.dart';
import '../doctor/doctor_home_screen.dart';
import '../organization/organization_home_screen.dart';
import '../patient/complete_patient_profile_screen.dart';
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
        if (context.mounted) {
          AuthNavigation.openSignedOutFlow(context);
        }
      });

      return const SizedBox.shrink();
    }

    return switch (role) {
      AccountRole.patient => const _PatientEntryScreen(),
      AccountRole.doctor => const _DoctorEntryScreen(),
      AccountRole.organization => const OrganizationHomeScreen(),
    };
  }
}

class _PatientEntryScreen extends StatefulWidget {
  const _PatientEntryScreen();

  @override
  State<_PatientEntryScreen> createState() => _PatientEntryScreenState();
}

class _PatientEntryScreenState extends State<_PatientEntryScreen> {
  bool _loading = true;
  bool _profileComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkPatientProfile();
  }

  Future<void> _checkPatientProfile() async {
    try {
      final session = FirebaseAuthRepository.instance.session;

      final organizationId = session.organizationId;

      final patientId = session.patientId;

      if (organizationId == null || organizationId.isEmpty) {
        throw StateError('لا توجد مؤسسة مرتبطة بحساب المريض.');
      }

      if (patientId == null || patientId.isEmpty) {
        throw StateError('لا توجد هوية مريض مرتبطة بالحساب.');
      }

      final patient = await FirestorePatientRepository.instance
          .fetchPatientById(patientId, organizationId: organizationId);

      if (patient == null) {
        throw StateError('لم يتم العثور على سجل المريض.');
      }

      final isComplete =
          patient.phone?.trim().isNotEmpty == true &&
          patient.birthDate?.trim().isNotEmpty == true &&
          patient.gender?.trim().isNotEmpty == true;

      if (!mounted) return;

      setState(() {
        _profileComplete = isComplete;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _profileCompleted() {
    if (!mounted) return;

    setState(() {
      _profileComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });

                    _checkPatientProfile();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_profileComplete) {
      return CompletePatientProfileScreen(onCompleted: _profileCompleted);
    }

    return const PatientHomeScreen();
  }
}

class _DoctorEntryScreen extends StatefulWidget {
  const _DoctorEntryScreen();

  @override
  State<_DoctorEntryScreen> createState() => _DoctorEntryScreenState();
}

class _DoctorEntryScreenState extends State<_DoctorEntryScreen> {
  bool _loading = true;
  bool _profileComplete = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkDoctorProfile();
  }

  Future<void> _checkDoctorProfile() async {
    try {
      final session = FirebaseAuthRepository.instance.session;

      final organizationId = session.organizationId;

      final doctorId = session.doctorId;

      if (organizationId == null || organizationId.isEmpty) {
        throw StateError('لا توجد مؤسسة مرتبطة بحساب الطبيب.');
      }

      if (doctorId == null || doctorId.isEmpty) {
        throw StateError('لا توجد هوية طبيب مرتبطة بالحساب.');
      }

      final doctor = await FirestoreDoctorRepository.instance.fetchDoctorById(
        doctorId,
        organizationId: organizationId,
      );

      if (doctor == null) {
        throw StateError('لم يتم العثور على سجل الطبيب.');
      }

      final isComplete =
          doctor.phone.trim().isNotEmpty &&
          doctor.birthDate.trim().isNotEmpty &&
          doctor.gender.trim().isNotEmpty;

      if (!mounted) return;

      setState(() {
        _profileComplete = isComplete;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _profileCompleted() {
    if (!mounted) return;

    setState(() {
      _profileComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });

                    _checkDoctorProfile();
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_profileComplete) {
      return CompleteDoctorProfileScreen(onCompleted: _profileCompleted);
    }

    return const DoctorHomeScreen();
  }
}
