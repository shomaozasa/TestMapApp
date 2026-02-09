import 'package:flutter/material.dart';
// 利用者ホーム画面 (スキップ用)
import 'package:google_map_app/features/user_flow/presentation/screens/user_home_screen.dart';
// 分割した各サインアップ画面
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

  // 選択確認ダイアログ (より親しみやすいデザイン)
  void _showConfirmationDialog(BuildContext context, String userType) {
    final isBusiness = userType == '事業者';
    final themeColor = isBusiness ? Colors.orange : Colors.blue;
    final icon = isBusiness ? Icons.store_mall_directory_rounded : Icons.person_rounded;

    showDialog(
      context: context,
      barrierDismissible: true, // 背景タップで閉じられるように
      builder: (context) => Dialog(
        // ★ 変更点: 角丸を大きくして「コロン」とした形に
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // アイコン (アクセントカラーの円背景)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: themeColor),
              ),
              const SizedBox(height: 24),
              
              // タイトル
              Text(
                '$userTypeで登録',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              
              // 説明文
              Text(
                '$userTypeとしてアカウントを作成します。\nよろしいですか？',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // ボタンエリア (横並び・ピル型ボタン)
              Row(
                children: [
                  // 戻るボタン
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        foregroundColor: Colors.grey,
                      ),
                      child: const Text('戻る', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // すすむボタン
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // ダイアログを閉じる
                        
                        // 選択に応じて画面遷移
                        if (isBusiness) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BusinessUserSignupScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserSignupScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: themeColor.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('すすむ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 共通のグラデーション
    const gradientColors = [
      Color(0xFF90CAF9), // Light Blue
      Color(0xFFFFCC80), // Light Orange
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.3),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // タイトルエリア
                const Text(
                  'アカウント作成',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '利用スタイルを選択してください',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const Spacer(flex: 2),

                // 選択ボタン (丸ボタン)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 事業者ボタン
                    _buildCircularButton(
                      context,
                      title: '事業者',
                      icon: Icons.store_mall_directory_rounded,
                      color: Colors.orange,
                      description: 'お店の情報を\n発信したい方',
                      onTap: () => _showConfirmationDialog(context, '事業者'),
                    ),
                    
                    // 利用者ボタン
                    _buildCircularButton(
                      context,
                      title: '利用者',
                      icon: Icons.person_rounded,
                      color: Colors.blue,
                      description: 'お店やイベントを\n探したい方',
                      onTap: () => _showConfirmationDialog(context, '利用者'),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // スキップボタン
                TextButton(
                  onPressed: () => _skipRegister(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '登録せずに利用する (スキップ)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                    ],
                  ),
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 丸い選択ボタンのウィジェット
  Widget _buildCircularButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String description,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 丸いボタン本体
        Material(
          color: Colors.white.withOpacity(0.95),
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: color.withOpacity(0.4),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: color.withOpacity(0.2),
            child: Container(
              width: 140, // ボタンのサイズ
              height: 140,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 36, color: color),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 説明テキスト
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.4,
            shadows: [
              Shadow(color: Colors.black12, offset: Offset(0, 1), blurRadius: 2),
            ],
          ),
        ),
      ],
    );
  }
}