import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/auth/auth_navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'data/repositories/patient_profile_repository_impl.dart';
import 'domain/entities/patient_profile.dart';
import 'models/patient_profile.dart';

part 'patient_profile_screens_patient_profile_screen_state.dart';
part 'patient_profile_screens_edit_patient_profile_screen.dart';
part 'patient_profile_screens_edit_patient_profile_screen_state.dart';
part 'patient_profile_screens_patient_settings_screen.dart';
part 'patient_profile_screens_change_password_screen.dart';
part 'patient_profile_screens_change_password_screen_state.dart';
part 'patient_profile_screens_language_screen.dart';
part 'patient_profile_screens_language_screen_state.dart';
part 'patient_profile_screens_notification_settings_screen.dart';
part 'patient_profile_screens_notification_settings_screen_state.dart';
part 'patient_profile_screens_appearance_screen.dart';
part 'patient_profile_screens_appearance_screen_state.dart';
part 'patient_profile_screens_support_screen.dart';
part 'patient_profile_screens_about_medicare_screen.dart';
part 'patient_profile_screens_profile_header.dart';
part 'patient_profile_screens_info_card.dart';
part 'patient_profile_screens_navigation_tile.dart';
part 'patient_profile_screens_settings_section_title.dart';
part 'patient_profile_screens_choice_screen.dart';
part 'patient_profile_screens_selection_tile.dart';
part 'patient_profile_screens_brand_mark.dart';


class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}
