import 'package:flutter/material.dart';

import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import '../clinics/clinics_screens.dart';
import '../doctors/doctors_screens.dart';
import '../appointments/appointments_screens.dart';
import '../appointments/data/repositories/appointments_repository_impl.dart';
import '../appointments/domain/entities/appointment_entity.dart';
import 'patient_profile_screens.dart';
import '../clinics/data/repositories/clinics_repository_impl.dart';
import '../clinics/domain/entities/clinic_entity.dart';
import '../doctors/data/repositories/doctors_repository_impl.dart';
import '../doctors/domain/entities/doctor_entity.dart';
import 'widgets/patient_appointment_card.dart';

part 'patient_home_screen_patient_home_screen_state.dart';
part 'patient_home_screen_home_content.dart';
part 'patient_home_screen_home_header.dart';
part 'patient_home_screen_quick_actions.dart';
part 'patient_home_screen_quick_action.dart';
part 'patient_home_screen_doctors_section.dart';
part 'patient_home_screen_doctor_card.dart';
part 'patient_home_screen_clinics_section.dart';


class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}
