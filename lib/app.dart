import 'package:flutter/material.dart';

// ★ 1. 新しい役割選択画面をインポートします
// (ディレクトリ構成に合わせて、_authentication フォルダからインポート)
import 'package:google_map_app/features/_authentication/presentation/screens/signup_selection_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'イベントマップ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // ★ 2. 起動画面を RoleSelectionScreen に変更
      home: const SignUpSelectionScreen(),
    );
  }
}