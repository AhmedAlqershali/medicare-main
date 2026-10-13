import 'package:flutter/material.dart';

import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_clinic_repository.dart';
import '../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../core/firestore/repositories/firestore_patient_repository.dart';
import '../../core/auth/models/patient.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'add_patient_screen.dart';
import 'models/doctor_patient.dart';

part 'doctor_patients_screen_doctor_patients_screen_state.dart';
part 'doctor_patients_screen_patient_card.dart';
part 'doctor_patients_screen_doctor_patient_details_screen.dart';
part 'doctor_patients_screen_info_row.dart';
part 'doctor_patients_screen_history_row.dart';


class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}
