import 'package:flutter/material.dart';

import '../../core/auth/models/organization.dart';
import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../core/firestore/repositories/firestore_organization_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'data/repositories/organization_clinics_repository_impl.dart';
import 'data/repositories/organization_doctors_repository_impl.dart';
import 'models/organization_clinic.dart';
import 'models/organization_doctor.dart';
import 'organization_clinics_screen.dart';
import 'organization_doctors_screen.dart';
import 'organization_profile_screens.dart';

part 'organization_home_screen_organization_home_screen_state.dart';
part 'organization_home_screen_organization_dashboard.dart';
part 'organization_home_screen_summary_grid.dart';
part 'organization_home_screen_summary_card.dart';
part 'organization_home_screen_clinic_preview_card.dart';
part 'organization_home_screen_doctor_preview_card.dart';


class OrganizationHomeScreen extends StatefulWidget {
  const OrganizationHomeScreen({super.key});

  @override
  State<OrganizationHomeScreen> createState() => _OrganizationHomeScreenState();
}
