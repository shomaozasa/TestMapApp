import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart'; 

// ★ 1. lib/firebase_options.dart をインポートします
// (このファイルが、今貼っていただいた設定ファイルです)
import 'firebase_options.dart';

void main() async {
  // Flutterの初期化を保証
  WidgetsFlutterBinding.ensureInitialized();

  // ★ 2. Firebase.initializeApp() に "options" を渡します
  // これでAndroid/iOS/Webのすべてで正しいプロジェクトが指定されます
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // アプリ本体(MyApp)を起動
  runApp(const MyApp());
}