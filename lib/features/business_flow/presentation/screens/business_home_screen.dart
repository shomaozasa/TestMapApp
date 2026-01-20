import 'package:flutter/material.dart';
// 各画面への遷移用インポート
import 'package:google_map_app/features/business_flow/presentation/screens/business_map_screen.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/template_management_screen.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/business_schedule_screen.dart'; // ★追加: 予定画面

class BusinessHomeScreen extends StatelessWidget {
  // ★ テスト用の管理者ID (他の画面と共通の test_user_id)
  final String currentAdminId = 'test_user_id'; 

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
          Container(
            height: screenHeight * 0.35, 
            color: const Color(0xFFFFB74D), // 薄いオレンジ
          ),

          // --- メインコンテンツ ---
          SafeArea(
            child: Column(
              children: [
                // 1. ヘッダー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
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
                  padding: const EdgeInsets.all(3),
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

                // 5. メインボタン群 (中央)
                
                // [マップ] ボタン
                _buildMainButton(
                  context: context,
                  label: 'マップ',
                  icon: Icons.map_outlined,
                  isPrimary: true, // オレンジ色
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessMapScreen(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),

                // [予定] ボタン
                _buildMainButton(
                  context: context,
                  label: '予定',
                  icon: Icons.calendar_today_outlined,
                  isPrimary: false, // 白色
                  onPressed: () {
                    // ★ 修正: カレンダー画面へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BusinessScheduleScreen(),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // 6. 下部メニュー (フッター)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  color: const Color(0xFFFFB74D),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // 左端: 時計アイコン
                      _buildFooterButton(Icons.access_time),
                      
                      // ★ 左から2番目: テンプレート管理へ遷移
                      _buildFooterButton(
                        Icons.description_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TemplateManagementScreen(
                                adminId: currentAdminId,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // 右側: チャット・設定 (機能未実装)
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

  /// メインのアクションボタン
  Widget _buildMainButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 240,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// フッターのアイコンボタン (onTap引数付き)
  Widget _buildFooterButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
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
        child: Icon(icon, color: Colors.black54, size: 26),
      ),
    );
  }
}