import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebaseオプション
import 'firebase_options.dart';

// ★ 切り出したスプラッシュ画面をインポート
import 'features/_authentication/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // ステータスバーなどの表示設定
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // FirebaseAuthの言語設定（メールテンプレート等）
  FirebaseAuth.instance.setLanguageCode('ja');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Map App',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      
      // --- 日本語化設定 ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'), // 日本語
      ],
      locale: const Locale('ja'), // アプリ全体を日本語に固定
      // --------------------

      // ★ ホームをスプラッシュ画面に設定
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}