import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/models/account_role.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';
import 'role_login_screen.dart';

export 'auth_widgets.dart';

part 'auth_screens_splash_screen_state.dart';
part 'auth_screens_onboarding_screen.dart';
part 'auth_screens_onboarding_screen_state.dart';
part 'auth_screens_user_type_screen.dart';
part 'auth_screens_user_type_screen_state.dart';
part 'auth_screens_doctor_placeholder_screen.dart';
part 'auth_screens_brand_mark.dart';
part 'auth_screens_onboarding_data.dart';
part 'auth_screens_onboarding_page.dart';
part 'auth_screens_account_type_card.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
