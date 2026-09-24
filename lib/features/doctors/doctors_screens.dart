import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'data/repositories/doctors_repository_impl.dart';
import 'domain/entities/doctor_entity.dart';
import 'models/doctor_model.dart';

part 'doctors_screens_doctors_list_screen_state.dart';
part 'doctors_screens_doctor_details_screen.dart';
part 'doctors_screens_doctor_details_screen_state.dart';
part 'doctors_screens_doctor_list_card.dart';
part 'doctors_screens_doctors_empty_state.dart';
part 'doctors_screens_info_line.dart';
part 'doctors_screens_service_chip.dart';
part 'doctors_screens_time_chip.dart';


class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}
