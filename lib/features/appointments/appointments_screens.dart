import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import '../clinics/clinics_screens.dart';
import '../clinics/data/repositories/clinics_repository_impl.dart';
import '../clinics/models/clinic_model.dart';
import '../doctors/doctors_screens.dart';
import 'data/repositories/appointments_repository_impl.dart';
import 'domain/entities/appointment_entity.dart';
import 'models/appointment_model.dart';
import 'models/appointment_status.dart';

part 'appointments_screens_appointments_screen_state.dart';
part 'appointments_screens_appointment_tabs.dart';
part 'appointments_screens_appointment_card.dart';
part 'appointments_screens_appointment_meta.dart';
part 'appointments_screens_appointment_details_screen.dart';
part 'appointments_screens_appointment_details_screen_state.dart';
part 'appointments_screens_detail_row.dart';
part 'appointments_screens_empty_appointments.dart';


class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}
