import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_app/core/services/user_firestore_service.dart';

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init({
    required UserFirestoreService users,
    required Future<String?> Function() currentUid,
  }) async {
    await _messaging.setAutoInitEnabled(true);
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }
    final token = await _messaging.getToken();
    final uid = await currentUid();
    if (uid != null && token != null) {
      await users.updateFcmToken(uid, token);
    }
    _messaging.onTokenRefresh.listen((t) async {
      final u = await currentUid();
      if (u != null) await users.updateFcmToken(u, t);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      debugPrint('FCM foreground: ${m.notification?.title} ${m.notification?.body}');
    });
  }
}
