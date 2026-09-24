import 'package:flutter/material.dart';

import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'data/repositories/doctor_appointments_repository_impl.dart';
import 'models/doctor_appointment.dart';

part 'doctor_appointments_screen_doctor_appointments_screen_state.dart';
part 'doctor_appointments_screen_filter_tabs.dart';
part 'doctor_appointments_screen_doctor_appointment_card.dart';
part 'doctor_appointments_screen_meta.dart';
part 'doctor_appointments_screen_doctor_appointment_details_screen.dart';
part 'doctor_appointments_screen_doctor_appointment_details_screen_state.dart';
part 'doctor_appointments_screen_detail_row.dart';
part 'doctor_appointments_screen_doctor_patient_preview_screen.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}
