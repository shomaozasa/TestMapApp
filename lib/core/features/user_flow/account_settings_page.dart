import 'package:flutter/material.dart';
import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';
import 'package:google_map_app/core/features/user_flow/change_password_page.dart';
import 'package:google_map_app/core/features/user_flow/change_email_page.dart';
import 'package:google_map_app/core/features/user_flow/two_factor_auth_page.dart';
import 'package:google_map_app/core/features/user_flow/delete_account_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({Key? key}) : super(key: key);

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String _userName = "sample user";
  bool _twoFactorEnabled = false;

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
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
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
                    _sectionTitle("アカウント情報"),

                    _menuTile(
                      icon: Icons.badge,
                      title: "ユーザー名",
                      subtitle: _userName,
                      onTap: () => _showEditUsernameDialog(),
                    ),

                    _menuTile(
                      icon: Icons.email,
                      title: "メールアドレス",
                      subtitle: "sample@email.com",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangeEmailPage(),
                          ),
                        );
                      },
                    ),

                    _menuTile(
                      icon: Icons.lock,
                      title: "パスワード変更",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    _sectionTitle("セキュリティ"),

                    _menuTile(
                      icon: Icons.security,
                      title: "二段階認証",
                      subtitle: _twoFactorEnabled ? "有効" : "未設定",
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TwoFactorAuthPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    _sectionTitle("その他"),

                    _dangerTile(
                      icon: Icons.logout,
                      title: "ログアウト",
                      onTap: _showLogoutDialog,
                    ),

                    _dangerTile(
                      icon: Icons.delete_forever,
                      title: "アカウント削除",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeleteAccountPage(),
                          ),
                        );
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

  // ===== セクションタイトル =====
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  // ===== 通常メニュー =====
  Widget _menuTile({
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
  Widget _dangerTile({
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

  // ===== ユーザー名編集 =====
  void _showEditUsernameDialog() {
    final controller = TextEditingController(text: _userName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ユーザー名を変更"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "新しいユーザー名",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _userName = controller.text;
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ユーザー名を変更しました")),
              );
            },
            child: const Text("保存"),
          ),
        ],
      ),
    );
  }

  // ===== 二段階認証切り替え =====
  void _toggleTwoFactor() {
    setState(() {
      _twoFactorEnabled = !_twoFactorEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _twoFactorEnabled
              ? "二段階認証を有効にしました"
              : "二段階認証を無効にしました",
        ),
      ),
    );
  }

  // ===== ログアウト =====
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("ログアウト"),
        content: const Text("本当にログアウトしますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              // ログアウト処理
            },
            child: const Text("ログアウト"),
          ),
        ],
      ),
    );
  }
}
