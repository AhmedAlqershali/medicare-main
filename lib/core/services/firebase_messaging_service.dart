import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firestore/firestore_service.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM] Background message handled by native Android service: '
    '${message.notification?.title ?? message.data['title']} from ${message.messageId}',
  );
}

class FirebaseMessagingService {
  FirebaseMessagingService._({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  final StreamController<RemoteMessage> _messageController =
      StreamController<RemoteMessage>.broadcast(sync: true);
  final StreamController<RemoteMessage> _openedMessageController =
      StreamController<RemoteMessage>.broadcast(sync: true);
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  Stream<RemoteMessage> get messages => _messageController.stream;
  Stream<RemoteMessage> get openedMessages => _openedMessageController.stream;

  Future<void> initialize() async {
    if (_initialized || _auth.currentUser == null) return;
    _initialized = true;

    final permission = await _messaging.requestPermission(
      alert: true,
      sound: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
    );
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notification permission was denied.');
    }

    _messageSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _openedMessageSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_openedMessageController.add);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _tokenRefreshSubscription =
        FirebaseMessaging.onTokenRefresh.listen((token) {
      unawaited(ensureTokenForUser(token));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _openedMessageController.add(initialMessage);
    }

    await ensureTokenForCurrentUser();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _messageController.add(message);
  }

  Future<void> ensureTokenForCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await ensureTokenForUser(token);
  }

  Future<void> ensureTokenForUser(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty || token.isEmpty) return;

    await _firestoreService.userDocument(uid).update({
      'fcmTokens': FieldValue.arrayUnion([token]),
    });
  }

  Future<void> removeCurrentTokenForUser(String uid) async {
    if (uid.isEmpty) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _firestoreService.userDocument(uid).update({
      'fcmTokens': FieldValue.arrayRemove([token]),
    });
  }

  void reset() {
    _messageSubscription?.cancel();
    _openedMessageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
    _messageSubscription = null;
    _openedMessageSubscription = null;
    _tokenRefreshSubscription = null;
    _initialized = false;
  }

  Future<void> dispose() async {
    reset();
    await _messageController.close();
    await _openedMessageController.close();
  }
}
