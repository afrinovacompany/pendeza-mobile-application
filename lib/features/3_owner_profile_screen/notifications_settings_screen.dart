import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/local_storage_service.dart';
import 'package:pendeza/app/services/service_locator.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  final _localStorage = sl<LocalStorageService>();

  // Notification preferences
  bool _bookingAlerts = true;
  bool _appointmentReminders = true;
  bool _clientMessages = true;
  bool _promotionUpdates = true;
  bool _paymentAlerts = true;
  bool _reviewNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Load saved preferences
    setState(() {
      _bookingAlerts = _localStorage.getBool('notif_booking_alerts') ?? true;
      _appointmentReminders =
          _localStorage.getBool('notif_appointment_reminders') ?? true;
      _clientMessages = _localStorage.getBool('notif_client_messages') ?? true;
      _promotionUpdates =
          _localStorage.getBool('notif_promotion_updates') ?? true;
      _paymentAlerts = _localStorage.getBool('notif_payment_alerts') ?? true;
      _reviewNotifications =
          _localStorage.getBool('notif_review_notifications') ?? true;
      _soundEnabled = _localStorage.getBool('notif_sound_enabled') ?? true;
      _vibrationEnabled =
          _localStorage.getBool('notif_vibration_enabled') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    await _localStorage.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications_settings.title'.tr()),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.padL),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: AppConstants.radiusL,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.bell_fill,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.padM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'notifications_settings.header_title'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'notifications_settings.header_subtitle'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.padXL),

            // Business Notifications Section
            _buildSectionTitle(
                theme, 'notifications_settings.business_section'.tr()),
            const SizedBox(height: AppConstants.padM),

            _NotificationToggle(
              icon: CupertinoIcons.calendar_badge_plus,
              title: 'notifications_settings.booking_alerts'.tr(),
              subtitle: 'notifications_settings.booking_alerts_desc'.tr(),
              value: _bookingAlerts,
              color: AppColors.primary,
              onChanged: (val) {
                setState(() => _bookingAlerts = val);
                _savePreference('notif_booking_alerts', val);
              },
            ),
            _NotificationToggle(
              icon: CupertinoIcons.clock_fill,
              title: 'notifications_settings.appointment_reminders'.tr(),
              subtitle: 'notifications_settings.appointment_reminders_desc'.tr(),
              value: _appointmentReminders,
              color: AppColors.accent,
              onChanged: (val) {
                setState(() => _appointmentReminders = val);
                _savePreference('notif_appointment_reminders', val);
              },
            ),
            _NotificationToggle(
              icon: CupertinoIcons.chat_bubble_2_fill,
              title: 'notifications_settings.client_messages'.tr(),
              subtitle: 'notifications_settings.client_messages_desc'.tr(),
              value: _clientMessages,
              color: AppColors.accent2,
              onChanged: (val) {
                setState(() => _clientMessages = val);
                _savePreference('notif_client_messages', val);
              },
            ),
            _NotificationToggle(
              icon: CupertinoIcons.creditcard_fill,
              title: 'notifications_settings.payment_alerts'.tr(),
              subtitle: 'notifications_settings.payment_alerts_desc'.tr(),
              value: _paymentAlerts,
              color: AppColors.success,
              onChanged: (val) {
                setState(() => _paymentAlerts = val);
                _savePreference('notif_payment_alerts', val);
              },
            ),
            _NotificationToggle(
              icon: CupertinoIcons.star_fill,
              title: 'notifications_settings.review_notifications'.tr(),
              subtitle: 'notifications_settings.review_notifications_desc'.tr(),
              value: _reviewNotifications,
              color: Colors.amber,
              onChanged: (val) {
                setState(() => _reviewNotifications = val);
                _savePreference('notif_review_notifications', val);
              },
            ),

            const SizedBox(height: AppConstants.padXL),

            // Marketing Notifications Section
            _buildSectionTitle(
                theme, 'notifications_settings.marketing_section'.tr()),
            const SizedBox(height: AppConstants.padM),

            _NotificationToggle(
              icon: CupertinoIcons.tag_fill,
              title: 'notifications_settings.promotion_updates'.tr(),
              subtitle: 'notifications_settings.promotion_updates_desc'.tr(),
              value: _promotionUpdates,
              color: Colors.purple,
              onChanged: (val) {
                setState(() => _promotionUpdates = val);
                _savePreference('notif_promotion_updates', val);
              },
            ),

            const SizedBox(height: AppConstants.padXL),

            // Sound & Vibration Section
            _buildSectionTitle(
                theme, 'notifications_settings.sound_section'.tr()),
            const SizedBox(height: AppConstants.padM),

            _NotificationToggle(
              icon: CupertinoIcons.speaker_3_fill,
              title: 'notifications_settings.sound'.tr(),
              subtitle: 'notifications_settings.sound_desc'.tr(),
              value: _soundEnabled,
              color: Colors.indigo,
              onChanged: (val) {
                setState(() => _soundEnabled = val);
                _savePreference('notif_sound_enabled', val);
              },
            ),
            _NotificationToggle(
              icon: CupertinoIcons.device_phone_portrait,
              title: 'notifications_settings.vibration'.tr(),
              subtitle: 'notifications_settings.vibration_desc'.tr(),
              value: _vibrationEnabled,
              color: Colors.teal,
              onChanged: (val) {
                setState(() => _vibrationEnabled = val);
                _savePreference('notif_vibration_enabled', val);
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.padS),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: color,
          ),
        ],
      ),
    );
  }
}
