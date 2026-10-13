import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../navigation/push_notification_navigation.dart';
import '../http_service.dart';
import '../session/session_storage.dart';
import 'push_token_repository.dart';

class PushNotificationService {
  static const _registeredTokenKey = 'fretado_registered_fcm_token';
  static const _permissionRequestedKey =
      'fretado_notification_permission_requested';
  static const _channelId = 'fretado_updates';

  static final PushNotificationService instance = PushNotificationService._();

  final SessionStorage _session = SessionStorage.instance;
  FirebaseMessaging? _messagingInstance;
  FlutterLocalNotificationsPlugin? _localNotificationsInstance;

  Map<String, dynamic>? _pendingNavigation;
  final Set<String> _foregroundEventIds = <String>{};
  bool _initialized = false;
  bool _syncing = false;
  bool _navigationScheduled = false;

  PushNotificationService._();

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  FirebaseMessaging get _messaging =>
      _messagingInstance ??= FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin get _localNotifications =>
      _localNotificationsInstance ??= FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (_initialized || !_isAndroid) return;
    _initialized = true;

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _queueNavigation(
            Map<String, dynamic>.from(jsonDecode(payload) as Map),
          );
        } catch (_) {
          // Ignore malformed local payloads.
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      'Atualizacoes do Fretado',
      description: 'Corridas, ofertas, cancelamentos e mensagens.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    final localLaunchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    final localLaunchPayload =
        localLaunchDetails?.notificationResponse?.payload;
    if (localLaunchDetails?.didNotificationLaunchApp == true &&
        localLaunchPayload != null &&
        localLaunchPayload.isNotEmpty) {
      try {
        _pendingNavigation = Map<String, dynamic>.from(
          jsonDecode(localLaunchPayload) as Map,
        );
      } catch (_) {
        // Ignore malformed local launch payloads.
      }
    }

    FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _queueNavigation(message.data),
    );
    _messaging.onTokenRefresh.listen(
      _handleTokenRefresh,
    );
    _session.addListener(_handleSessionChanged);

    await _session.loadSavedSession();
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _pendingNavigation = Map<String, dynamic>.from(initialMessage.data);
    }

    unawaited(syncAuthenticatedSession());
    _tryOpenPendingNavigation();
  }

  Future<void> syncAuthenticatedSession() async {
    if (!_isAndroid || _syncing) return;
    _syncing = true;
    try {
      if (!_session.hasValidAccessToken || _session.currentUserId == null) {
        return;
      }

      final preferences = await SharedPreferences.getInstance();
      final alreadyRequested =
          preferences.getBool(_permissionRequestedKey) ?? false;
      NotificationSettings settings;
      if (!alreadyRequested) {
        settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await preferences.setBool(_permissionRequestedKey, true);
      } else {
        settings = await _messaging.getNotificationSettings();
      }
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      final previousToken = preferences.getString(_registeredTokenKey);
      final repository = PushTokenRepository(HttpService());
      try {
        if (previousToken == null || previousToken.isEmpty) {
          await repository.register(token);
        } else if (previousToken != token) {
          await repository.update(oldToken: previousToken, newToken: token);
        } else {
          await repository.register(token);
        }
        await preferences.setString(_registeredTokenKey, token);
      } finally {
        repository.dispose();
      }
    } catch (_) {
      // Token synchronization is best effort and must not block authentication.
    } finally {
      _syncing = false;
    }
  }

  Future<void> unregisterForLogout() async {
    if (!_isAndroid) return;
    final preferences = await SharedPreferences.getInstance();
    final registeredToken = preferences.getString(_registeredTokenKey);
    if (registeredToken != null &&
        registeredToken.isNotEmpty &&
        _session.hasValidAccessToken) {
      try {
        final repository = PushTokenRepository(HttpService());
        try {
          await repository.remove(registeredToken);
        } finally {
          repository.dispose();
        }
      } catch (_) {
        // The local Firebase token is still invalidated below.
      }
    }
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // Logout must continue even if Firebase is unavailable.
    }
    await preferences.remove(_registeredTokenKey);
    _pendingNavigation = null;
    _foregroundEventIds.clear();
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    if (!_session.hasValidAccessToken || newToken.isEmpty) return;
    PushTokenRepository? repository;
    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      final preferences = await SharedPreferences.getInstance();
      final oldToken = preferences.getString(_registeredTokenKey);
      repository = PushTokenRepository(HttpService());
      await repository.update(
        oldToken: oldToken,
        newToken: newToken,
      );
      await preferences.setString(_registeredTokenKey, newToken);
    } catch (_) {
      // A later session synchronization retries registration.
    } finally {
      repository?.dispose();
    }
  }

  void _handleSessionChanged() {
    if (_session.hasValidAccessToken && _session.currentUserId != null) {
      unawaited(syncAuthenticatedSession());
      _tryOpenPendingNavigation();
      return;
    }
    unawaited(_clearTokenAfterSessionLoss());
  }

  Future<void> _clearTokenAfterSessionLoss() async {
    if (!_isAndroid) return;
    try {
      await _messaging.deleteToken();
    } catch (_) {
      // A stale backend token is removed after the next definitive FCM error.
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_registeredTokenKey);
    _pendingNavigation = null;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    final eventId = '${data['event_id'] ?? message.messageId ?? ''}';
    if (eventId.isEmpty || !_foregroundEventIds.add(eventId)) return;

    final notification = message.notification;
    final title = notification?.title ?? 'Fretado';
    final body = notification?.body ?? 'Voce recebeu uma nova atualizacao.';
    await _localNotifications.show(
      eventId.hashCode & 0x7fffffff,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Atualizacoes do Fretado',
          channelDescription: 'Corridas, ofertas, cancelamentos e mensagens.',
          importance: Importance.high,
          priority: Priority.high,
          tag: eventId,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _queueNavigation(Map<String, dynamic> data) {
    _pendingNavigation = Map<String, dynamic>.from(data);
    _tryOpenPendingNavigation();
  }

  void _tryOpenPendingNavigation() {
    if (_pendingNavigation == null || _navigationScheduled) return;
    _navigationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      final pending = _pendingNavigation;
      if (pending != null && openPushNotification(pending)) {
        _pendingNavigation = null;
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}
