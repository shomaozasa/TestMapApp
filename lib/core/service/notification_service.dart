import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 初期化処理 (main.dart で呼び出す)
  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    // 1. 通知の許可をリクエスト (iOS用)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      return;
    }

    // 2. フォアグラウンド（アプリ起動中）でも通知バナーを表示する設定
    // (これがないと、アプリを開いている間は通知音が鳴らない場合があります)
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. アプリ起動中に通知を受け取った時の処理
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // 必要ならここでスナックバーなどを出す処理を追加可能
      }
    });

    // 4. バックグラウンド状態で通知をタップしてアプリを開いた時の処理
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessage(message, navigatorKey);
    });

    // 5. アプリが完全に終了している状態で通知をタップして開いた時の処理
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, navigatorKey);
    }
  }

  /// 通知タップ時の画面遷移ロジック
  static void _handleMessage(RemoteMessage message, GlobalKey<NavigatorState> navigatorKey) {
    // Cloud Functions で送ったデータ (data payload) を確認
    // data: { click_action: "FLUTTER_NOTIFICATION_CLICK", type: "new_event", eventId: ..., businessId: ... }
    
    final data = message.data;
    if (data['type'] == 'new_event') {
      // 本来はここで詳細画面へ遷移させます
      // 例: navigatorKey.currentState?.push(...)
      debugPrint("イベント通知がタップされました: ${data['eventId']}");
      
      // とりあえずダイアログなどを出すか、ホームへ遷移させる実装にするのが一般的です
      // ※詳細画面の実装状況に合わせてここは調整します
    }
  }
}