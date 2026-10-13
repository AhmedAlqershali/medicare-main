  import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/medicare_widgets.dart';

class AppNotificationSettingsScreen extends StatefulWidget {
  const AppNotificationSettingsScreen({super.key});

  @override
  State<AppNotificationSettingsScreen> createState() => _AppNotificationSettingsScreenState();
}

class _AppNotificationSettingsScreenState extends State<AppNotificationSettingsScreen> {
  AuthorizationStatus _permission = AuthorizationStatus.denied;
  bool _requesting = false;

  bool get _hasPermission =>
      _permission == AuthorizationStatus.authorized ||
      _permission == AuthorizationStatus.provisional;

  @override
  void initState() {
    super.initState();
    _loadPermission();
  }

  Future<void> _loadPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final status = settings.authorizationStatus;
    if (mounted) setState(() => _permission = status);
  }

  Future<void> _requestPermission() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    final status = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      sound: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );
    if (mounted) {
      setState(() {
        _permission = status.authorizationStatus;
        _requesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإشعارات')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
            children: [
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notifications_active_outlined, color: AppColors.primary, size: 30),
                      const SizedBox(height: AppSpacing.md),
                      Text('إشعارات التطبيق', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text('تفعيل الإشعارات يتيح للمشروع إرسال تنبيهات المواعيد والرسائل الجديدة.', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _requesting ? null : _requestPermission,
                        icon: Icon(_requesting ? Icons.hourglass_empty_rounded : Icons.notifications_active_outlined),
                        label: Text(_requesting ? 'جارٍ الطلب...' : 'تفعيل الإشعارات'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(_hasPermission ? Icons.check_circle_outline : Icons.warning_amber_outlined, color: _hasPermission ? AppColors.success : AppColors.warning),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _hasPermission ? 'الإشعارات مفعّلة.' : 'الإشعارات غير مفعّلة.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
