import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_map_app/core/models/review_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';

class BusinessReviewManagementScreen extends StatelessWidget {
  final String adminId;

  const BusinessReviewManagementScreen({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('レビュー管理', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: firestoreService.getBusinessReviewsStream(adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("エラーが発生しました: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("まだレビューは届いていません", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final reviews = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _BusinessReviewCard(review: review); // adminIdはreviewモデル内に持っているので不要
            },
          );
        },
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

  // 返信ダイアログを表示
  void _showReplyDialog(BuildContext context, {String? initialText}) {
    final TextEditingController controller = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(initialText == null ? '返信を作成' : '返信を編集'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'お客様への返信を入力してください',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
              child: const Text('送信'),
            ),
          ],
        );
      },
    );
  }

  // 削除確認ダイアログ
  void _confirmDeleteReply(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('返信を削除'),
        content: const Text('この返信を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
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
    final dateStr = DateFormat('yyyy/MM/dd HH:mm').format(widget.review.createdAt);
    
    String title = "";
    String content = widget.review.comment;
    if (widget.review.comment.contains("\n\n")) {
      final parts = widget.review.comment.split("\n\n");
      title = parts[0];
      content = parts.sublist(1).join("\n\n");
    }

    // 返信済みかどうか
    final bool hasReply = widget.review.replyComment != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // ヘッダー
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100),
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
              Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),

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
                    radius: 14,
                    backgroundImage: userIcon != null && userIcon.isNotEmpty ? NetworkImage(userIcon) : null,
                    backgroundColor: Colors.grey.shade300,
                    child: (userIcon == null || userIcon.isEmpty) ? const Icon(Icons.person, size: 18, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 8),
                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Row(
                    children: List.generate(5, (index) => Icon(Icons.star, size: 16, color: index < widget.review.rating ? Colors.amber : Colors.grey.shade300)),
                  ),
                ],
              );
            },
          ),
          const Divider(height: 24, color: Colors.grey),

          // レビュー本文
          if (title.isNotEmpty) ...[
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
          ],
          Text(content, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),

          const SizedBox(height: 20),

          // --- 返信エリア ---
          if (hasReply) ...[
            // 返信済みの場合の表示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("店舗からの返信", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
                      // 編集・削除メニュー
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(widget.review.replyComment!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
          ] else ...[
            // 未返信の場合のボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReplyDialog(context),
                icon: const Icon(Icons.reply, size: 18),
                label: const Text("返信する"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}