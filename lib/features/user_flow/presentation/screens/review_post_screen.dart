import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★追加
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';

// ★追加: 遷移先画面
import 'package:google_map_app/features/user_flow/presentation/screens/favorite_list_screen.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/user_profile_screen.dart';

class ReviewPostScreen extends StatefulWidget {
  final EventModel event;

  const ReviewPostScreen({super.key, required this.event});

  @override
  State<ReviewPostScreen> createState() => _ReviewPostScreenState();
}

class _ReviewPostScreenState extends State<ReviewPostScreen> {
  int _rating = 5;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _submitReview() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レビュー内容を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String fullComment = _titleController.text.isNotEmpty
          ? "${_titleController.text}\n\n${_commentController.text}"
          : _commentController.text;

      await _firestoreService.addReview(
        businessId: widget.event.adminId,
        eventId: widget.event.id,
        eventName: widget.event.eventName,
        rating: _rating,
        comment: fullComment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('レビューを投稿しました！')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("レビュー", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // ★ 変更: Stackでラップしてコントロールパネルを重ねる
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  // ★ 下部にパネル分の余白(120px)を追加
                  padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 事業者・イベント情報エリア
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                              image: widget.event.eventImage.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(widget.event.eventImage),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("イベント名:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(widget.event.eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                const Text("詳細:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  widget.event.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("事業者からのコメント", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "イベントにお越しいただきありがとうございました！\n評価とレビューをお願いします♪",
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      const SizedBox(height: 30),

                      // 星評価
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (index) {
                              return IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 40,
                                onPressed: () => setState(() => _rating = index + 1),
                                icon: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // 入力フォーム
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("レビュータイトル", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.blue)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.blue)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text("レビュー内容", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _commentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // フッターボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Skip", style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: _submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text("投稿", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                  ),
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
            onPressed: () => Navigator.pop(context), // 閉じる = 前の画面へ
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
              // ここではマップ検索はできないので、メッセージを出すか何もしない
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
}