import 'package:flutter/material.dart';

import '../../core/auth/auth_navigation.dart';
import '../../core/auth/models/doctor.dart';
import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_doctor_repository.dart';
import '../../core/firestore/repositories/firestore_appointment_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';

part 'doctor_profile_screens_doctor_profile_screen_state.dart';
part 'doctor_profile_screens_doctor_profile.dart';
part 'doctor_profile_screens_info_tile.dart';
part 'doctor_profile_screens_setting_tile.dart';
part 'doctor_profile_screens_doctor_edit_profile_screen.dart';
part 'doctor_profile_screens_doctor_edit_profile_screen_state.dart';
part 'doctor_profile_screens_doctor_schedule_screen.dart';
part 'doctor_profile_screens_doctor_schedule_screen_state.dart';
part 'doctor_profile_screens_schedule_slot.dart';
part 'doctor_profile_screens_legend.dart';


class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}
