import 'package:flutter/material.dart';
import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {

  // ※ 将来的にAPIと連携する想定のローカル状態
  bool pushNotification = true;
  bool reviewNotification = true;
  bool favoriteNotification = false;
  bool campaignNotification = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),

      body: SafeArea(
        child: Column(
          children: [
            // ===== 上部グラデーションヘッダー =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                    tooltip: '戻る',
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.black87,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const SizedBox(height: 8),

                  // 将来：検索やフィルタを置く想定のプレースホルダー
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
                "通知設定",
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
                          "通知の種類",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ),

                      _switchTile(
                        title: "プッシュ通知",
                        subtitle: "重要なお知らせを受け取ります",
                        value: pushNotification,
                        onChanged: (v) =>
                            setState(() => pushNotification = v),
                      ),

                      _switchTile(
                        title: "レビュー通知",
                        subtitle: "レビューへの返信を通知",
                        value: reviewNotification,
                        onChanged: (v) =>
                            setState(() => reviewNotification = v),
                      ),

                      _switchTile(
                        title: "お気に入り更新",
                        subtitle: "お気に入り店舗の更新情報",
                        value: favoriteNotification,
                        onChanged: (v) =>
                            setState(() => favoriteNotification = v),
                      ),

                      _switchTile(
                        title: "キャンペーン情報",
                        subtitle: "セール・イベント情報",
                        value: campaignNotification,
                        onChanged: (v) =>
                            setState(() => campaignNotification = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomBar(
        onMapTap: () => Navigator.pop(context),
      ),
    );
  }

  // ===== Switchタイル =====
  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      children: [
        SwitchListTile(
          dense: true,
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
          activeColor: Colors.lightBlue,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
