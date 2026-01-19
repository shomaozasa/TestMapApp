import 'package:flutter/material.dart';
import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';

class FavoriteListPage extends StatefulWidget {
  const FavoriteListPage({Key? key}) : super(key: key);

  @override
  State<FavoriteListPage> createState() => _FavoriteListPageState();
}

class _FavoriteListPageState extends State<FavoriteListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F8),

      body: Column(
        children: [
          // =========================
          // 🔹 上部グラデーションヘッダー
          // =========================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[200]!,
                  Colors.blue[100]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // ===== ← 戻るボタン =====
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.black87,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),

                const SizedBox(height: 6),

                // 検索バー
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
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "お気に入りを検索",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Icon(Icons.favorite, color: Colors.pinkAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // 🔹 タイトル
          // =========================
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                "お気に入り一覧",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // =========================
          // 🔹 下側コンテンツ
          // =========================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        "お気に入り店舗",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _favoriteCard(),
                        _favoriteCard(),
                        _favoriteCard(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // =========================
      // 🔹 下部ナビゲーション
      // =========================
      bottomNavigationBar: CustomBottomBar(
        onMapTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  // ===================================================
  // 🔹 お気に入りカード（イベント詳細UI寄せ）
  // ===================================================
  Widget _favoriteCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左：画像
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.image,
              color: Colors.white70,
              size: 36,
            ),
          ),

          const SizedBox(width: 14),

          // 右：情報
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 店舗名 + お気に入り
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Expanded(
                      child: Text(
                        "今だけ！の極旨クレープ販売",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.favorite,
                      color: Colors.pinkAccent,
                      size: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 評価
                Row(
                  children: const [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    Icon(Icons.star_border, size: 16, color: Colors.amber),
                    SizedBox(width: 6),
                    Text(
                      "4.0",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // メモ
                const Text(
                  "焼きたてで美味しかったので再訪したい店舗です。",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // 距離・カテゴリ
                Row(
                  children: const [
                    Icon(Icons.location_on,
                        size: 14, color: Colors.redAccent),
                    SizedBox(width: 2),
                    Text(
                      "40m",
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.category,
                        size: 14, color: Colors.blue),
                    SizedBox(width: 2),
                    Text(
                      "飲食",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
