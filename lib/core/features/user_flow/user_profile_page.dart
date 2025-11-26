import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F8),

      // AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "プロフィール",
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // 本文
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✨ 上の淡い青背景（ヘッダー）
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[200]!,
                    Colors.blue[100]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            // プロフィール画像
            Transform.translate(
              offset: const Offset(0, -50),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage("assets/user_icon.jpg"),
              ),
            ),

            const Text(
              "sample user",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {},
              child: const Text("編集"),
            ),

            const SizedBox(height: 10),

            // 🔹 あなたの活動
            _menuSection(
              title: "あなたの活動",
              items: [
                _menuItem(Icons.favorite_border, "お気に入り"),
                _menuItem(Icons.reviews, "投稿したレビュー"),
                _menuItem(Icons.card_membership, "スタンプカード"),
              ],
            ),

            const SizedBox(height: 20),

            // 🔹 設定
            _menuSection(
              title: "設定",
              items: [
                _menuItem(Icons.person, "アカウント設定"),
                _menuItem(Icons.notifications, "通知設定"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // セクション全体
  Widget _menuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  // アイテム1行
  Widget _menuItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
    );
  }
}
