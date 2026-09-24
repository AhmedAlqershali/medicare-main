import 'package:flutter/material.dart';

import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_clinic_repository.dart';
import '../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'data/repositories/organization_clinics_repository_impl.dart';
import 'models/organization_clinic.dart';

part 'organization_clinics_screen_organization_clinics_screen_state.dart';
part 'organization_clinics_screen_clinic_card.dart';
part 'organization_clinics_screen_meta.dart';
part 'organization_clinics_screen_organization_clinic_details_screen.dart';
part 'organization_clinics_screen_organization_clinic_details_screen_state.dart';
part 'organization_clinics_screen_mini_stat.dart';
part 'organization_clinics_screen_organization_clinic_form_screen.dart';
part 'organization_clinics_screen_organization_clinic_form_screen_state.dart';


class OrganizationClinicsScreen extends StatefulWidget {
  const OrganizationClinicsScreen({super.key});

  @override
  State<OrganizationClinicsScreen> createState() => _OrganizationClinicsScreenState();
}
