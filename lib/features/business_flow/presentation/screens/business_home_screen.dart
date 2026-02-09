import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// モデルとプロフィール画面
import 'package:google_map_app/core/models/business_user_model.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/business_profile_screen.dart';

// 各画面への遷移用
import 'package:google_map_app/features/business_flow/presentation/screens/business_map_screen.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/template_management_screen.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/business_schedule_screen.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/business_review_management_screen.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final User? user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? '';

    if (uid.isEmpty) {
      return const Scaffold(body: Center(child: Text("ログイン情報が取得できません")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('businesses').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (!snapshot.data!.exists) return const Scaffold(body: Center(child: Text("事業者データが見つかりません")));

        final business = BusinessUserModel.fromFirestore(snapshot.data!);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // 背景上部 (オレンジ)
              Container(
                height: screenHeight * 0.38, // 少し高さを増やす
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFCC80), Color(0xFFFFAB40)], // グラデーション化
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)), // 下部を丸く
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    // ヘッダー (通知など)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 40), // バランス調整用
                          // 店舗名
                          Expanded(
                            child: Text(
                              business.adminName.isNotEmpty ? business.adminName : '名称未設定',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [Shadow(color: Colors.black12, offset: Offset(0, 1), blurRadius: 2)],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 通知アイコン
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),

                    // アバター (重なりデザイン)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => BusinessProfileScreen(adminId: uid)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: business.iconImage != null && business.iconImage!.isNotEmpty
                              ? NetworkImage(business.iconImage!)
                              : null,
                          child: (business.iconImage == null || business.iconImage!.isEmpty)
                              ? const Icon(Icons.store, size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 挨拶文 & 評価
                    Column(
                      children: [
                        Text(
                          'おつかれさまです！\n${business.ownerName} さん',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        // 評価表示 (追加)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                business.reviewCount > 0 ? business.avgRating.toStringAsFixed(1) : "-",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              ),
                              Text(
                                " (${business.reviewCount}件)",
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),

                    // メインボタンエリア (縦並び)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          _buildMainButton(
                            context: context,
                            label: 'マップで確認',
                            icon: Icons.map_outlined,
                            color: const Color(0xFFFFAB40), // メインオレンジ
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BusinessMapScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildMainButton(
                            context: context,
                            label: '予定を管理',
                            icon: Icons.calendar_month_outlined,
                            color: Colors.white,
                            textColor: Colors.black87,
                            borderColor: Colors.grey.shade300,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BusinessScheduleScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(flex: 2),

                    // フッターメニュー
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFooterButton(Icons.access_time_filled, label: "履歴", color: Colors.blue.shade300),
                          _buildFooterButton(
                            Icons.description, 
                            label: "テンプレ", 
                            color: Colors.green.shade300,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => TemplateManagementScreen(adminId: uid)),
                              );
                            },
                          ),
                          _buildFooterButton(
                            Icons.chat_bubble, 
                            label: "レビュー", 
                            color: Colors.orange.shade300,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BusinessReviewManagementScreen(adminId: uid)),
                              );
                            },
                          ),
                          _buildFooterButton(Icons.settings, label: "設定", color: Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // メインボタン (横長・丸み)
  Widget _buildMainButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: borderColor != null ? BorderSide(color: borderColor) : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
          ],
        ),
      ),
    );
  }

  // フッターボタン (アイコン＋ラベル)
  Widget _buildFooterButton(IconData icon, {String? label, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          if (label != null)
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}