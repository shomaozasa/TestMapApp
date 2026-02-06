import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_map_app/core/models/review_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';

// コントロールパネルをインポート
import 'package:google_map_app/features/user_flow/presentation/widgets/user_control_panel.dart';

class ReviewHistoryScreen extends StatefulWidget {
  const ReviewHistoryScreen({super.key});

  @override
  State<ReviewHistoryScreen> createState() => _ReviewHistoryScreenState();
}

class _ReviewHistoryScreenState extends State<ReviewHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // --- フィルタ・ソート用の状態変数 ---
  bool _isDescending = true; // true: 新しい順, false: 古い順
  String? _selectedShopName; // 店舗名でフィルタ (nullなら全店舗)
  int? _selectedMinRating;   // 星の数でフィルタ (nullなら全評価)

  // 削除確認
  Future<void> _confirmDelete(ReviewModel review) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('レビューの削除'),
          content: const Text('このレビューを削除してもよろしいですか？\nこの操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('削除する', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        await _firestoreService.deleteUserReview(
          businessId: review.businessId,
          reviewId: review.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('レビューを削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除失敗: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // 編集ダイアログ
  Future<void> _showEditDialog(ReviewModel review) async {
    int currentRating = review.rating;
    String initialTitle = "";
    String initialBody = review.comment;

    if (review.comment.contains("\n\n")) {
      final parts = review.comment.split("\n\n");
      initialTitle = parts[0];
      initialBody = parts.sublist(1).join("\n\n");
    }

    final TextEditingController titleController = TextEditingController(text: initialTitle);
    final TextEditingController bodyController = TextEditingController(text: initialBody);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('レビューの編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("評価", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 32,
                          onPressed: () => setState(() => currentRating = index + 1),
                          icon: Icon(
                            index < currentRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text("タイトル", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(hintText: 'タイトルを入力', isDense: true),
                    ),
                    const SizedBox(height: 16),
                    const Text("内容", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    TextField(
                      controller: bodyController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'レビュー内容を入力',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (bodyController.text.isEmpty) return;
                    final String fullComment = titleController.text.isNotEmpty
                        ? "${titleController.text}\n\n${bodyController.text}"
                        : bodyController.text;

                    await _firestoreService.updateUserReview(
                      businessId: review.businessId,
                      reviewId: review.id,
                      rating: currentRating,
                      comment: fullComment,
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('レビューを更新しました')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('更新'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- フィルタ選択用ダイアログ ---

  // 店舗選択
  void _showShopFilterDialog(List<String> shopNames) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("店舗で絞り込み", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("すべて表示"),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedShopName,
                  onChanged: (v) {
                    setState(() => _selectedShopName = v);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() => _selectedShopName = null);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: shopNames.length,
                  itemBuilder: (context, index) {
                    final name = shopNames[index];
                    return ListTile(
                      title: Text(name),
                      leading: Radio<String?>(
                        value: name,
                        groupValue: _selectedShopName,
                        onChanged: (v) {
                          setState(() => _selectedShopName = v);
                          Navigator.pop(context);
                        },
                      ),
                      onTap: () {
                        setState(() => _selectedShopName = name);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 星の数選択
  void _showRatingFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("評価で絞り込み", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("すべて表示"),
                leading: Radio<int?>(
                  value: null,
                  groupValue: _selectedMinRating,
                  onChanged: (v) {
                    setState(() => _selectedMinRating = v);
                    Navigator.pop(context);
                  },
                ),
              ),
              const Divider(),
              ...List.generate(5, (index) {
                final rating = 5 - index; // 5, 4, 3...
                return ListTile(
                  title: Row(children: [
                    Text("$rating "),
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const Text(" 以上"),
                  ]),
                  leading: Radio<int?>(
                    value: rating,
                    groupValue: _selectedMinRating,
                    onChanged: (v) {
                      setState(() => _selectedMinRating = v);
                      Navigator.pop(context);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

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
      body: Stack(
        children: [
          // Firestoreデータ取得
          StreamBuilder<List<ReviewModel>>(
            stream: _firestoreService.getUserReviewsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("エラー: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
              }

              // 元のリスト
              List<ReviewModel> reviews = snapshot.data ?? [];

              // --- フィルタリング処理 ---
              
              // 1. 店舗名フィルタ
              if (_selectedShopName != null) {
                reviews = reviews.where((r) => r.shopName == _selectedShopName).toList();
              }

              // 2. 星フィルタ
              if (_selectedMinRating != null) {
                reviews = reviews.where((r) => r.rating >= _selectedMinRating!).toList();
              }

              // 3. ソート (日付)
              reviews.sort((a, b) {
                return _isDescending
                    ? b.createdAt.compareTo(a.createdAt)
                    : a.createdAt.compareTo(b.createdAt);
              });

              // 店舗名リストの作成（フィルタダイアログ用）
              final allShopNames = (snapshot.data ?? [])
                  .map((r) => r.shopName)
                  .toSet()
                  .toList(); // 重複排除

              // 日付範囲の取得（表示用）
              String dateRange = "-/-/- ~ -/-/-";
              if (reviews.isNotEmpty) {
                // ソート済みなので先頭と末尾を使う
                final start = reviews.last.createdAt; // 古い方
                final end = reviews.first.createdAt;  // 新しい方
                // 表示順が逆（降順）の場合は入れ替え
                final firstDate = _isDescending ? start : end;
                final lastDate = _isDescending ? end : start;
                
                final fmt = DateFormat('yyyy/MM/dd');
                dateRange = "${fmt.format(firstDate)} ~ ${fmt.format(lastDate)}";
              }

              return Column(
                children: [
                  // フィルタボタンエリア
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 最近（ソート切り替え）
                        _buildFilterButton(
                          label: '最近',
                          icon: _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                          isSelected: true, // 常にアクティブ扱い
                          onTap: () {
                            setState(() => _isDescending = !_isDescending);
                          },
                        ),
                        const SizedBox(width: 12),
                        // 評価（カテゴリの代わり）
                        _buildFilterButton(
                          label: _selectedMinRating == null ? '評価' : '★$_selectedMinRating↑',
                          isSelected: _selectedMinRating != null,
                          onTap: _showRatingFilterDialog,
                        ),
                        const SizedBox(width: 12),
                        // 店舗
                        _buildFilterButton(
                          label: _selectedShopName ?? '店舗',
                          isSelected: _selectedShopName != null,
                          onTap: () => _showShopFilterDialog(allShopNames),
                        ),
                      ],
                    ),
                  ),
                  
                  // 日付指定エリア
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(dateRange, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  // リスト表示
                  Expanded(
                    child: reviews.isEmpty
                        ? const Center(child: Text("条件に一致するレビューはありません", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              final review = reviews[index];
                              return _buildReviewCard(review);
                            },
                          ),
                  ),
                ],
              );
            },
          ),

          // 共通コンポーネント
          const Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: UserControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    IconData? icon,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black87 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.black54),
            ],
          ],
        ),
      ),
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
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                  const SizedBox(height: 4),
                  
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.more_horiz, size: 24, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditDialog(review);
                      } else if (value == 'delete') {
                        _confirmDelete(review);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('編集'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
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

          if (review.replyComment != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("お店からの返信", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(height: 4),
                  Text(
                    review.replyComment!,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}