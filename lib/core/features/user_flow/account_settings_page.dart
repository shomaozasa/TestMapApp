import 'package:flutter/material.dart';
import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),

      body: Column(
        children: [
          
          // ===== 上部グラデーションヘッダー =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFB3E5FC),
                  Color(0xFFE1F5FE),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ===== ← 戻るボタン =====
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.black87,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 8),

                // （今は空だけど、将来使えるコンテナ）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ===== タイトル =====
          const Center(
            child: Text(
              "アカウント設定",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== 設定カード =====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        "アカウント情報",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),

                    _menuTile(
                      context,
                      icon: Icons.badge,
                      title: "ユーザー名",
                      subtitle: "sample user",
                      onTap: () {
                        // ユーザー名編集
                      },
                    ),

                    _menuTile(
                      context,
                      icon: Icons.email,
                      title: "メールアドレス",
                      subtitle: "sample@email.com",
                      onTap: () {
                        // メール変更
                      },
                    ),

                    _menuTile(
                      context,
                      icon: Icons.lock,
                      title: "パスワード変更",
                      onTap: () {
                        // パスワード変更
                      },
                    ),

                    const SizedBox(height: 16),

                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        "セキュリティ",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),

                    _menuTile(
                      context,
                      icon: Icons.security,
                      title: "二段階認証",
                      subtitle: "未設定",
                      onTap: () {
                        // 2FA設定
                      },
                    ),

                    const SizedBox(height: 16),

                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        "その他",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),

                    _dangerTile(
                      context,
                      icon: Icons.logout,
                      title: "ログアウト",
                      onTap: () {
                        // ログアウト処理
                      },
                    ),

                    _dangerTile(
                      context,
                      icon: Icons.delete_forever,
                      title: "アカウント削除",
                      onTap: () {
                        // 退会処理
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CustomBottomBar(
        onMapTap: () => Navigator.pop(context),
      ),
    );
  }

  // ===== 通常メニュー =====
  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }

  // ===== 危険操作 =====
  Widget _dangerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.red),
          title: Text(
            title,
            style: const TextStyle(color: Colors.red),
          ),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
