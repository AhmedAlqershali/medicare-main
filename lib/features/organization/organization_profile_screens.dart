import 'package:flutter/material.dart';

import '../../core/auth/auth_navigation.dart';
import '../../core/auth/models/organization.dart';
import '../../core/auth/services/firebase_auth_repository.dart';
import '../../core/firestore/repositories/firestore_organization_repository.dart';
import '../../core/firestore/repositories/firestore_clinic_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/medicare_widgets.dart';

part 'organization_profile_screens_organization_profile_screen_state.dart';
part 'organization_profile_screens_organization_profile.dart';
part 'organization_profile_screens_info_tile.dart';
part 'organization_profile_screens_setting_tile.dart';
part 'organization_profile_screens_organization_profile_form_screen.dart';
part 'organization_profile_screens_organization_profile_form_screen_state.dart';


class OrganizationProfileScreen extends StatefulWidget {
  const OrganizationProfileScreen({super.key});

  @override
  State<OrganizationProfileScreen> createState() => _OrganizationProfileScreenState();
}
