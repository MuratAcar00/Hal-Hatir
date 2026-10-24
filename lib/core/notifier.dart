import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'models.dart';

/// System notifications for alert stages. Android only; no-op elsewhere
/// (web/desktop use the in-app banner).
class AlertNotifier {
  static const _id = 1;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  AlertState _shown = AlertState.normal;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Initializes and asks for POST_NOTIFICATIONS (Android 13+).
  Future<void> init() async {
    if (!_supported) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Bildirim başlatılamadı: $e');
    }
  }

  /// Shows one notification per stage; clears it back at normal.
  Future<void> update(AlertState state, String? explanation) async {
    if (state == _shown) return;
    _shown = state;
    if (!_ready) return;
    try {
      if (state == AlertState.normal) {
        await _plugin.cancel(id: _id);
        return;
      }
      final title = switch (state) {
        AlertState.softCheck => 'İyi misiniz?',
        AlertState.familyAlert => 'Yakınınız cevap vermedi',
        _ => 'Hâlâ cevap yok',
      };
      await _plugin.show(
        id: _id,
        title: title,
        body: explanation == null ? null : 'Neden uyardı? $explanation',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'alerts',
            'Uyarılar',
            channelDescription: 'Rutin sapması ve uzun sessizlik uyarıları',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(''),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Bildirim gösterilemedi: $e');
    }
  }
}
