import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★追加
import 'package:google_map_app/core/models/review_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';

// ★追加
import 'package:google_map_app/features/user_flow/presentation/screens/favorite_list_screen.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/user_profile_screen.dart';

class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({super.key});

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text("レビュー履歴", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      // ★ 変更: Stackにする
      body: Stack(
        children: [
          Column(
            children: [
              // フィルタボタンエリア
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFilterButton('最近', isSelected: true),
                    const SizedBox(width: 12),
                    _buildFilterButton('カテゴリ'),
                    const SizedBox(width: 12),
                    _buildFilterButton('店舗'),
                  ],
                ),
              ),
              
              // 日付指定エリア
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDateBox("2025/10/06"),
                    const Text("~", style: TextStyle(fontSize: 20, color: Colors.grey)),
                    _buildDateBox("-/-/-"),
                  ],
                ),
              ),
              
              const SizedBox(height: 10),

              // リスト表示
              Expanded(
                child: StreamBuilder<List<ReviewModel>>(
                  stream: _firestoreService.getUserReviewsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("エラー: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("まだレビュー履歴はありません", style: TextStyle(color: Colors.grey)));
                    }

                    final reviews = snapshot.data!;

                    return ListView.builder(
                      // ★ 下部にパネル分の余白を追加
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return _buildReviewCard(review);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // ★ 追加: コントロールパネル
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildCustomBottomBar(),
          ),
        ],
      ),
    );
  }

  // ★ 追加: コントロールパネルのビルドメソッド
  Widget _buildCustomBottomBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8F6).withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            icon: Icons.close,
            onPressed: () => Navigator.pop(context),
          ),
          _buildCircleButton(
            icon: Icons.store_mall_directory_outlined,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteListScreen()),
            ),
          ),
          _buildCircleButton(
            icon: Icons.person_outline,
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // すでにプロフィール画面から来ている場合は戻るだけでも良いが、統一してPushする
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.uid)),
                );
              }
            },
          ),
          _buildCircleButton(
            icon: Icons.search,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('マップ画面で検索してください')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({IconData? icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.grey.shade700, size: 28),
      ),
    );
  }

  Widget _buildFilterButton(String label, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black87 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final dateStr = DateFormat('yyyy/MM/dd').format(review.createdAt);

    String title = "";
    String content = review.comment;
    
    if (review.comment.contains("\n\n")) {
      final parts = review.comment.split("\n\n");
      title = parts[0];
      content = parts.sublist(1).join("\n\n");
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            review.shopName.isNotEmpty ? review.shopName : "店舗名不明",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 24, color: Colors.grey),

          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
          ],

          Text(
            content,
            style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}