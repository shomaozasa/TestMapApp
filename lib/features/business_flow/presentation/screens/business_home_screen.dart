import 'package:flutter/material.dart';
// 遷移先のマップ画面をインポート
import 'package:google_map_app/features/business_flow/presentation/screens/business_map_screen.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面全体の高さ
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- 背景 (上部) ---
          // グラデーションを廃止し、単色のオレンジ背景に
          Container(
            height: screenHeight * 0.35, // 画面上部35%くらい
            color: const Color(0xFFFFB74D), // 薄いオレンジ (Orange 300)
          ),

          // --- メインコンテンツ ---
          SafeArea(
            child: Column(
              children: [
                // 1. ヘッダー (店舗名と通知アイコン)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24), // 中央寄せのためのスペーサー
                      const Text(
                        'sample cafe',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Icon(Icons.notifications_none, color: Colors.black54, size: 28),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2. アバター画像
                Container(
                  padding: const EdgeInsets.all(3), // 白い枠線の太さ
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.grey,
                    // 画像がないためアイコンで代用
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 16),

                // 3. 挨拶文
                const Text(
                  'おつかれさまです！\n〇〇〇 さん',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 30),

                const SizedBox(height: 40),

                // 5. メインボタン (マップ・予定)
                _buildMainButton(
                  context: context,
                  label: 'マップ',
                  icon: Icons.map_outlined,
                  isPrimary: true, // オレンジ色
                  onPressed: () {
                    // マップ画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessMapScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),

                _buildMainButton(
                  context: context,
                  label: '予定',
                  icon: Icons.calendar_today_outlined,
                  isPrimary: false, // 白色
                  onPressed: () {
                    // 未実装のアラート
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('予定機能は現在開発中です')),
                    );
                  },
                ),

                const Spacer(),

                // 6. 下部メニュー (フッター)
                // 背景 (下部) - グラデーションなし
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  color: const Color(0xFFFFB74D), // オレンジ (上部と同じ色)
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFooterButton(Icons.access_time),
                      _buildFooterButton(Icons.description_outlined),
                      _buildFooterButton(Icons.chat_bubble_outline),
                      _buildFooterButton(Icons.settings_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// メインのアクションボタン (マップ・予定)
  Widget _buildMainButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 240, // ボタンの幅
      height: 64, // ボタンの高さ
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFFFAB40) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          elevation: 0, // 影はContainerでつけるので0
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// フッターのアイコンボタン
  Widget _buildFooterButton(IconData icon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black54, size: 28),
    );
  }
}