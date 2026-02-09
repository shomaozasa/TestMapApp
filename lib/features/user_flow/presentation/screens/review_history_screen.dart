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

  // テーマカラー
  static const Color themeColor = Color(0xFF4A90E2);
  static const Color gradientStart = Color(0xFF64B5F6); // 少し濃いめの青（ヘッダー用）
  static const Color gradientEnd = Color(0xFF42A5F5);   // 鮮やかな青

  // 削除確認
  Future<void> _confirmDelete(ReviewModel review) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('レビューの削除', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('このレビューを削除してもよろしいですか？\nこの操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('削除する'),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('レビューの編集', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("評価", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 36,
                          onPressed: () => setState(() => currentRating = index + 1),
                          icon: Icon(
                            index < currentRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'タイトル',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'レビュー内容',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
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

  void _showShopFilterDialog(List<String> shopNames) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("店舗で絞り込み", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("すべて表示"),
                leading: Radio<String?>(
                  value: null,
                  groupValue: _selectedShopName,
                  activeColor: themeColor,
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
                        activeColor: themeColor,
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

  void _showRatingFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("評価で絞り込み", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("すべて表示"),
                leading: Radio<int?>(
                  value: null,
                  groupValue: _selectedMinRating,
                  activeColor: themeColor,
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
                    activeColor: themeColor,
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
      // 背景色（グラデーションの下地）
      backgroundColor: gradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 透明にしてグラデーションを見せる
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // アイコンは白
        // タイトルはここではなくbodyのヘッダー部分に配置してデザイン性を高める
      ),
      body: Column(
        children: [
          // --- ヘッダーエリア (タイトル) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, top: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.history_edu_rounded, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  "My Reviews",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontFamily: 'Roboto', // 英字フォント指定（あれば）
                  ),
                ),
              ],
            ),
          ),

          // --- コンテンツエリア (白い角丸シート) ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.grey, // 下地(実際には白カードが見える)
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: Container(
                  color: const Color(0xFFF5F5F5), // コンテンツ背景色
                  child: Stack(
                    children: [
                      StreamBuilder<List<ReviewModel>>(
                        stream: _firestoreService.getUserReviewsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text("エラー: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                          }

                          // データ処理
                          List<ReviewModel> reviews = snapshot.data ?? [];

                          if (_selectedShopName != null) {
                            reviews = reviews.where((r) => r.shopName == _selectedShopName).toList();
                          }
                          if (_selectedMinRating != null) {
                            reviews = reviews.where((r) => r.rating >= _selectedMinRating!).toList();
                          }

                          reviews.sort((a, b) {
                            return _isDescending
                                ? b.createdAt.compareTo(a.createdAt)
                                : a.createdAt.compareTo(b.createdAt);
                          });

                          final allShopNames = (snapshot.data ?? [])
                              .map((r) => r.shopName)
                              .toSet()
                              .toList();

                          String dateRange = "-/-/- ~ -/-/-";
                          if (reviews.isNotEmpty) {
                            final start = reviews.last.createdAt;
                            final end = reviews.first.createdAt;
                            final firstDate = _isDescending ? start : end;
                            final lastDate = _isDescending ? end : start;
                            final fmt = DateFormat('yyyy/MM/dd');
                            dateRange = "${fmt.format(firstDate)} ~ ${fmt.format(lastDate)}";
                          }

                          return Column(
                            children: [
                              // --- フィルタ & 情報エリア ---
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                child: Column(
                                  children: [
                                    // 期間表示カード
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(dateRange, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // フィルタボタン群
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildFilterChip(
                                          label: '最近',
                                          icon: _isDescending ? Icons.arrow_downward : Icons.arrow_upward,
                                          isSelected: true,
                                          onTap: () {
                                            setState(() => _isDescending = !_isDescending);
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          label: _selectedMinRating == null ? '評価' : '★$_selectedMinRating↑',
                                          isSelected: _selectedMinRating != null,
                                          onTap: _showRatingFilterDialog,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildFilterChip(
                                          label: _selectedShopName ?? '店舗',
                                          isSelected: _selectedShopName != null,
                                          onTap: () => _showShopFilterDialog(allShopNames),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // --- リスト表示 ---
                              Expanded(
                                child: reviews.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.rate_review_outlined, size: 60, color: Colors.grey.shade300),
                                            const SizedBox(height: 16),
                                            Text(
                                              "レビューはありません",
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 120),
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

                      // 共通コンポーネント (UserControlPanel)
                      const Positioned(
                        bottom: 30,
                        left: 20,
                        right: 20,
                        child: UserControlPanel(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // フィルタチップ (ボタン)
  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
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

  // レビューカード
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.store, size: 16, color: Colors.orange.shade400),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            review.shopName.isNotEmpty ? review.shopName : "店舗名不明",
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 36),
                      child: Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
              
              // 評価・メニュー部分
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 16),
                      ),
                    ],
                  ),
                  
                  // メニューボタン
                  SizedBox(
                    height: 30,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz, size: 20, color: Colors.grey),
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
            style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
          ),

          // 返信エリア
          if (review.replyComment != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1), // 非常に薄いオレンジ
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.reply, size: 16, color: Colors.orange),
                      SizedBox(width: 8),
                      Text("お店からの返信", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review.replyComment!,
                    style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
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