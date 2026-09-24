import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'appointments_screens.dart';
import 'models/appointment_booking_data.dart';

part 'appointment_booking_screens_appointment_booking_screen_state.dart';
part 'appointment_booking_screens_appointment_confirmation_screen.dart';
part 'appointment_booking_screens_doctor_summary.dart';
part 'appointment_booking_screens_date_option.dart';
part 'appointment_booking_screens_time_option.dart';
part 'appointment_booking_screens_appointment_type_option.dart';
part 'appointment_booking_screens_appointment_summary.dart';
part 'appointment_booking_screens_summary_line.dart';
part 'appointment_booking_screens_confirmation_row.dart';
part 'appointment_booking_screens_appointment_date.dart';


class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key, required this.bookingData});

  final AppointmentBookingData bookingData;

  @override
  State<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}
