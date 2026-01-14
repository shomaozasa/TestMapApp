import 'package:flutter/material.dart';

class ReviewPostScreen extends StatefulWidget {
  const ReviewPostScreen({super.key});

  @override
  State<ReviewPostScreen> createState() => _ReviewPostScreenState();
}

class _ReviewPostScreenState extends State<ReviewPostScreen> {
  double _rating = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// ===== 上部グラデーション =====
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFD8ECFF),
                  Color(0xFFEAF4FF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'レビュー',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          /// ===== メインカード =====
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _shopInfoCard(),
                  const SizedBox(height: 16),
                  _commentFromShop(),
                  const SizedBox(height: 16),
                  _ratingSection(),
                  const SizedBox(height: 16),
                  _inputSection(),
                  const SizedBox(height: 24),
                  _actionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// 店舗情報
  /// ===============================
  Widget _shopInfoCard() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 画像
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 12),

        /// 情報
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('事業者名：〇〇カフェ'),
              Text('カテゴリ：飲食'),
              Text('詳細：イベント出店'),
            ],
          ),
        ),
      ],
    );
  }

  /// ===============================
  /// 事業者コメント
  /// ===============================
  Widget _commentFromShop() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'イベントにお越しいただきありがとうございました！\n'
        '評価とレビューをお願いします。',
        style: TextStyle(fontSize: 13),
      ),
    );
  }

  /// ===============================
  /// 星評価
  /// ===============================
  Widget _ratingSection() {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.orange,
                size: 28,
              ),
              onPressed: () {
                setState(() {
                  _rating = index + 1.0;
                });
              },
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          _rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// ===============================
  /// 入力欄
  /// ===============================
  Widget _inputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('レビュータイトル'),
        const SizedBox(height: 6),
        _inputBox(hint: 'タイトルを入力'),

        const SizedBox(height: 16),

        const Text('レビュー内容'),
        const SizedBox(height: 6),
        _inputBox(
          hint: 'レビュー内容を入力',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _inputBox({
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  /// ===============================
  /// ボタン
  /// ===============================
  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Skip',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            // 投稿処理
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5AB1FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 12,
            ),
          ),
          child: const Text(
            '投稿',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
