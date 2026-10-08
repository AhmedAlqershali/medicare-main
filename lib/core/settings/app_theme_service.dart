import 'package:flutter/material.dart';

import '../firestore/firestore_service.dart';
import '../theme/app_theme.dart';

class AppThemeService {
  AppThemeService(this._service);

  final FirestoreService _service;

  Future<ThemeMode> loadThemeMode(String? uid) async {
    if (uid == null || uid.isEmpty) return ThemeMode.system;

    try {
      final snapshot = await _service.userDocument(uid).get();
      return AppThemeMode.fromValue(snapshot.data()?['themeMode'] as String?).materialMode;
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(String? uid, AppThemeMode mode) async {
    if (uid == null || uid.isEmpty) return;
    await _service.userDocument(uid).update({'themeMode': mode.value});
  }
}
