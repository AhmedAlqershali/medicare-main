import 'package:flutter/material.dart';

import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../core/firestore/repositories/firestore_organization_repository.dart';
import '../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'data/repositories/doctor_appointments_repository_impl.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_profile_screens.dart';
import 'models/doctor_appointment.dart';

part 'doctor_home_screen_doctor_home_screen_state.dart';
part 'doctor_home_screen_doctor_dashboard.dart';
part 'doctor_home_screen_overview_grid.dart';
part 'doctor_home_screen_overview_card.dart';
part 'doctor_home_screen_dashboard_appointment_card.dart';
part 'doctor_home_screen_quick_actions.dart';
part 'doctor_home_screen_action.dart';


class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}
