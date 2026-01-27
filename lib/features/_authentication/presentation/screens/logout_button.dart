import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_app/features/_authentication/presentation/screens/splash_screen.dart';

class LogoutButton extends StatelessWidget {
  final Color? iconColor;

  const LogoutButton({super.key, this.iconColor});

  Future<void> _handleLogout(BuildContext context) async {
    // 1. 確認ダイアログ
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしてログイン画面に戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ログアウト', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // 2. 実行
    if (shouldLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          // ログイン画面へ戻り、履歴を消去
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        debugPrint("ログアウトエラー: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログアウトに失敗しました')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      color: iconColor ?? Colors.black,
      tooltip: 'ログアウト',
      onPressed: () => _handleLogout(context),
    );
  }
}