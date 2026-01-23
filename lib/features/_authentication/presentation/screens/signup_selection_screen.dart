import 'package:flutter/material.dart';
// ★ 利用者ホーム画面 (スキップ用)
import 'package:google_map_app/features/user_flow/presentation/screens/user_home_screen.dart';
// ★ 分割した各サインアップ画面
import 'package:google_map_app/features/_authentication/presentation/screens/user_auth/user_signup_screen.dart';
import 'package:google_map_app/features/_authentication/presentation/screens/business_user_auth/business_user_signup_screen.dart';

class SignUpSelectionScreen extends StatelessWidget {
  const SignUpSelectionScreen({super.key});

  // 登録をスキップして利用者ホームへ
  Future<void> _skipRegister(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserHomeScreen()),
    );
  }

  // 選択確認ダイアログ
  void _showConfirmationDialog(BuildContext context, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$userTypeで登録を始めます'),
        content: const Text('よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              
              // 選択に応じて画面遷移
              if (userType == '利用者') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserSignupScreen(),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusinessUserSignupScreen(),
                  ),
                );
              }
            },
            child: const Text('はい'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント登録')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'どちらで始めますか？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            
            // 選択ボタンの行
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUserTypeButton(context, '事業者', Colors.orange),
                _buildUserTypeButton(context, '利用者', Colors.blue),
              ],
            ),
            
            const SizedBox(height: 50),
            
            // スキップボタン
            ElevatedButton(
              onPressed: () => _skipRegister(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black87,
              ),
              child: const Text('登録をスキップ (利用者として開始)'),
            ),
          ],
        ),
      ),
    );
  }

  // 丸ボタン＋ラベルの共通ウィジェット
  Widget _buildUserTypeButton(
    BuildContext context,
    String userType,
    Color color,
  ) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showConfirmationDialog(context, userType),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: Text(
                  userType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}