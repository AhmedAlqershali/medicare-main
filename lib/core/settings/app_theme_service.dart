import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../firestore/firestore_service.dart';
import '../theme/app_theme.dart';
class AppThemeService {
  AppThemeService(this._service);

  final FirestoreService _service;

  Future<AppThemeMode> loadThemeMode(String? uid) async {
    if (uid == null || uid.isEmpty) return AppThemeMode.system;

    try {
      final snapshot = await _service.userDocument(uid).get();
      final savedMode = snapshot.data()?['themeMode'];
      return AppThemeMode.fromValue(savedMode is String ? savedMode : null);
    } catch (error, stackTrace) {
      debugPrint('Unable to load saved theme mode: $error\n$stackTrace');
      return AppThemeMode.system;
    }
  }

  Future<void> saveThemeMode(String? uid, AppThemeMode mode) async {
    if (uid == null || uid.isEmpty) {
      throw StateError('A signed-in user is required to save the theme mode.');
    }
    await _service.userDocument(uid).set({'themeMode': mode.value}, SetOptions(merge: true));
  }
}
