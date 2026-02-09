import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_map_app/core/models/review_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';

class BusinessReviewManagementScreen extends StatefulWidget {
  final String adminId;

  const BusinessReviewManagementScreen({super.key, required this.adminId});

  @override
  State<BusinessReviewManagementScreen> createState() => _BusinessReviewManagementScreenState();
}

class _BusinessReviewManagementScreenState extends State<BusinessReviewManagementScreen> {
  final FirestoreService firestoreService = FirestoreService();

  // --- 状態変数 ---
  bool _isAscending = false; // 日付順序 (false: 新しい順/降順, true: 古い順/昇順)
  String _filterType = 'all'; // 絞り込み ('all', 'replied', 'unreplied')

  // テーマカラー（オレンジ）
  static const Color themeColor = Colors.orange;
  static const Color gradientStart = Color(0xFFFFCC80); // 薄いオレンジ
  static const Color gradientEnd = Color(0xFFFFF3E0);   // さらに薄いオレンジ

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white, // アイコン白
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- ヘッダー ---
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.rate_review_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Reviews",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),

              // --- コンテンツエリア ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5), // コンテンツ背景
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: Column(
                      children: [
                        // 1. フィルタ & ソートエリア (白背景)
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          child: Column(
                            children: [
                              // 絞り込みチップ
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildFilterChip('すべて', 'all'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('未返信', 'unreplied'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('返信済', 'replied'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // ソートボタン
                              InkWell(
                                onTap: () => setState(() => _isAscending = !_isAscending),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isAscending ? "古い順 (昇順)" : "新しい順 (降順)",
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // 2. リスト表示
                        Expanded(
                          child: StreamBuilder<List<ReviewModel>>(
                            stream: firestoreService.getBusinessReviewsStream(widget.adminId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(child: Text("エラーが発生しました: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                              }

                              List<ReviewModel> reviews = snapshot.data ?? [];

                              // 絞り込み
                              if (_filterType == 'unreplied') {
                                reviews = reviews.where((r) => r.replyComment == null || r.replyComment!.isEmpty).toList();
                              } else if (_filterType == 'replied') {
                                reviews = reviews.where((r) => r.replyComment != null && r.replyComment!.isNotEmpty).toList();
                              }

                              // ソート
                              reviews.sort((a, b) {
                                final compare = a.createdAt.compareTo(b.createdAt);
                                return _isAscending ? compare : -compare;
                              });

                              if (reviews.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.mark_chat_read_outlined, size: 60, color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        "該当するレビューはありません",
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                itemCount: reviews.length,
                                itemBuilder: (context, index) {
                                  final review = reviews[index];
                                  return _BusinessReviewCard(review: review);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // フィルタチップ
  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _filterType == value;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => _filterType = value);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? themeColor : Colors.grey.shade300),
          boxShadow: [
            if (!isSelected)
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BusinessReviewCard extends StatefulWidget {
  final ReviewModel review;

  const _BusinessReviewCard({required this.review});

  @override
  State<_BusinessReviewCard> createState() => _BusinessReviewCardState();
}

class _BusinessReviewCardState extends State<_BusinessReviewCard> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showReplyDialog(BuildContext context, {String? initialText}) {
    final TextEditingController controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(initialText == null ? '返信を作成' : '返信を編集', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'お客様への感謝の気持ちや\nご意見への回答を入力してください',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                
                await _firestoreService.replyToReview(
                  businessId: widget.review.businessId,
                  reviewId: widget.review.id,
                  reply: controller.text.trim(),
                );
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('返信を保存しました')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('送信'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteReply(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('返信を削除'),
        content: const Text('この返信を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteReviewReply(
                businessId: widget.review.businessId,
                reviewId: widget.review.id,
              );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('返信を削除しました')),
                );
              }
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy/MM/dd').format(widget.review.createdAt);
    
    String title = "";
    String content = widget.review.comment;
    if (widget.review.comment.contains("\n\n")) {
      final parts = widget.review.comment.split("\n\n");
      title = parts[0];
      content = parts.sublist(1).join("\n\n");
    }

    final bool hasReply = widget.review.replyComment != null && widget.review.replyComment!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // イベントタグと日付
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.review.eventName,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),

          // ユーザー情報
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(widget.review.userId).get(),
            builder: (context, snapshot) {
              String userName = "匿名ユーザー";
              String? userIcon;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                userName = data['user_name'] ?? "匿名ユーザー";
                userIcon = data['icon_image'];
              }
              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: userIcon != null && userIcon.isNotEmpty ? NetworkImage(userIcon) : null,
                    backgroundColor: Colors.grey.shade200,
                    child: (userIcon == null || userIcon.isEmpty) ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  Row(
                    children: List.generate(5, (index) => Icon(Icons.star, size: 16, color: index < widget.review.rating ? Colors.amber : Colors.grey.shade300)),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 16),

          // レビュー本文
          if (title.isNotEmpty) ...[
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
          ],
          Text(content, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),

          const SizedBox(height: 24),

          // --- 返信エリア ---
          if (hasReply) ...[
            // 返信済み
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), // 非常に薄いオレンジ
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.reply, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text("返信済み", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange)),
                        ],
                      ),
                      // メニュー
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showReplyDialog(context, initialText: widget.review.replyComment);
                            } else if (value == 'delete') {
                              _confirmDeleteReply(context);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('編集')),
                            const PopupMenuItem(value: 'delete', child: Text('削除', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.review.replyComment!, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
                ],
              ),
            ),
          ] else ...[
            // 未返信ボタン
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => _showReplyDialog(context),
                icon: const Icon(Icons.reply, size: 18),
                label: const Text("返信を作成する"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}