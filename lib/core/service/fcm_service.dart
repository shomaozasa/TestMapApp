import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_map_app/core/service/firestore_service.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// 初期化処理 (ホーム画面で呼ぶ)
  Future<void> initialize() async {
    // 1. 通知の許可をリクエスト (iOS/Android 13+でダイアログが出ます)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('通知の許可が得られました');
      
      // 2. 現在のトークンを取得
      // ※ Web版でエラーが出る場合は vapidKey が必要ですが、まずはモバイル向けに実装します
      try {
        String? token = await _firebaseMessaging.getToken();
        final user = FirebaseAuth.instance.currentUser;

        if (token != null && user != null) {
          // 3. Firestoreに保存 (ログイン中のユーザーIDと紐付け)
          await _firestoreService.saveUserToken(user.uid, token);
        }
        
        // トークンが更新された場合も保存し直す
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          if (user != null) {
            _firestoreService.saveUserToken(user.uid, newToken);
          }
        });
      } catch (e) {
        debugPrint('FCMトークン取得エラー: $e');
      }

    } else {
      debugPrint('通知の許可が拒否されました');
    }

    // アプリが「開いている時」に通知が来た場合のハンドリング
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('フォアグラウンド通知受信: ${message.notification?.title}');
    });
  }
}