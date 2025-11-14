import 'package:flutter/material.dart';
import 'features/user_flow/presentation/user_home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventMap (仮)', // アプリのタイトル
      debugShowCheckedModeBanner: false, // デバッグ時に右上に表示される "DEBUG" バナーを非表示にする

      // --- アプリ全体のデザインテーマ ---
      theme: ThemeData(
        // アプリ全体の基本となるカラースキーム
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple, // この色を元に自動で配色が生成される
          brightness: Brightness.light, // 明るいテーマ
        ),
        // マテリアル3デザインを有効化
        useMaterial3: true,

        // (例) フォント設定（もし指定する場合）
        // fontFamily: 'NotoSansJP',

        // (例) AppBar（上部のバー）の共通スタイル
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // 背景色
          foregroundColor: Colors.black, // タイトルやアイコンの色
          elevation: 0, // 影をなくす
          centerTitle: true, // タイトルを中央寄せ
        ),
      ),

      // --- 最初に表示する画面 ---
      // 本来は「認証状態」などをチェックして、
      // 利用者画面に行くか、事業者ログイン画面に行くか分岐させますが、
      // ここでは仮に「利用者ホーム画面」を直接指定しています。
      home: const UserHomeScreen(),

      // --- (将来的な拡張：名前付きルート) ---
      // アプリが大きくなってきたら、ここで画面遷移のルールを定義できます。
      // routes: {
      //   '/': (context) => const UserHomeScreen(),
      //   '/business/login': (context) => const BusinessLoginScreen(),
      //   '/business/home': (context) => const BusinessHomeScreen(),
      // },
    );
  }
}