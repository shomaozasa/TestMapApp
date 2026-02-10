import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebaseオプション
import 'firebase_options.dart';

// モデル
import 'core/models/user_model.dart';
import 'core/models/business_user_model.dart';

// 通知サービス
import 'core/service/notification_service.dart'; // ★追加

// 各画面のインポート
import 'features/_authentication/presentation/screens/splash_screen.dart';
import 'features/_authentication/presentation/screens/login_screen.dart';
import 'features/user_flow/presentation/screens/user_home_screen.dart';
import 'features/business_flow/presentation/screens/business_home_screen.dart';

// ★追加: 画面遷移用のキーをグローバルに定義
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ★追加: 通知サービスの初期化
  await NotificationService.initialize(navigatorKey);

  // ステータスバーなどの表示設定
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // FirebaseAuthの言語設定
  FirebaseAuth.instance.setLanguageCode('ja');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Map App',
      // ★追加: 画面遷移キーをセット
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja')],
      locale: const Locale('ja'),
      
      // 起動画面を SplashScreen に固定
      home: const SplashScreen(),
      
      debugShowCheckedModeBanner: false,
    );
  }
}

// ---------------------------------------------------------
// AuthNavigationWrapper (必要であれば利用)
// ---------------------------------------------------------
class AuthNavigationWrapper extends StatefulWidget {
  const AuthNavigationWrapper({super.key});

  @override
  State<AuthNavigationWrapper> createState() => _AuthNavigationWrapperState();
}

class _AuthNavigationWrapperState extends State<AuthNavigationWrapper> {
  String? _cachedUserType;
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (!authSnapshot.hasData) {
          _cachedUserType = null;
          return const LoginScreen();
        }

        final uid = authSnapshot.data!.uid;

        if (_lastUid == uid && _cachedUserType != null) {
          return _getHomeScreen(_cachedUserType!);
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _checkUserType(uid),
          builder: (context, typeSnapshot) {
            if (typeSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final data = typeSnapshot.data;
            if (data == null || data['type'] == 'none') {
              return const LoginScreen();
            }

            _cachedUserType = data['type'];
            _lastUid = uid;

            return _getHomeScreen(_cachedUserType!);
          },
        );
      },
    );
  }

  Widget _getHomeScreen(String type) {
    return type == 'business'
        ? const BusinessHomeScreen()
        : const UserHomeScreen();
  }

  Future<Map<String, dynamic>> _checkUserType(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists) {
      return {'type': 'user', 'model': UserModel.fromFirestore(userDoc)};
    }

    final businessDoc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(uid)
        .get();
    if (businessDoc.exists) {
      return {
        'type': 'business',
        'model': BusinessUserModel.fromFirestore(businessDoc),
      };
    }

    return {'type': 'none'};
  }
}