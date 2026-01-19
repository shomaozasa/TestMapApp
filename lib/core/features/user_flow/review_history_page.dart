import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';

class ReviewHistoryPage extends StatefulWidget {
  const ReviewHistoryPage({Key? key}) : super(key: key);

  @override
  State<ReviewHistoryPage> createState() => _ReviewHistoryPageState();
}

class _ReviewHistoryPageState extends State<ReviewHistoryPage> {
  int selectedTab = 0;

  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),

      body: Column(
        children: [
          // ===== 上部グラデーションヘッダー =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
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
                            hintText: "キーワード検索",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Icon(Icons.filter_alt, color: Colors.black54),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ===== タイトル（検索と表示条件の間）=====
          const SizedBox(height: 18),
          const Center(
            child: Text(
              "レビュー履歴",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ===== 下側コンテンツ =====
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
                    // 表示条件ラベル
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        "表示条件",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    // ===== タブ =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTabButton(0, "最近"),
                        _buildTabButton(1, "カテゴリ"),
                        _buildTabButton(2, "店舗"),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ===== 日付フィルター =====
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dateBox(
                          selectedStartDate == null
                              ? "----/--/--"
                              : _formatDate(selectedStartDate!),
                          () => _showDatePicker(context, true),
                        ),
                        const SizedBox(width: 10),
                        const Text("〜"),
                        const SizedBox(width: 10),
                        _dateBox(
                          selectedEndDate == null
                              ? "----/--/--"
                              : _formatDate(selectedEndDate!),
                          () => _showDatePicker(context, false),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(),

                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        "レビュー一覧",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    // ===== レビューリスト =====
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _reviewCard(),
                        _reviewCard(),
                        _reviewCard(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CustomBottomBar(
        onMapTap: () => Navigator.pop(context),
      ),
    );
  }

  // ===== タブボタン =====
  Widget _buildTabButton(int index, String label) {
    final isSelected = index == selectedTab;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.lightBlue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.lightBlue[900] : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===== 日付フォーマット =====
  String _formatDate(DateTime d) {
    return "${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}";
  }

  // ===== 日付ボックス =====
  Widget _dateBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  // ===== スクロール式日付ピッカー =====
  void _showDatePicker(BuildContext context, bool isStart) {
    DateTime now = DateTime.now();
    int year = now.year;

    List<int> years = List.generate(10, (i) => year - 5 + i);
    List<int> months = List.generate(12, (i) => i + 1);
    List<int> days = List.generate(31, (i) => i + 1);

    int selectedYear = now.year;
    int selectedMonth = now.month;
    int selectedDay = now.day;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SizedBox(
          height: 260,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: const Text("キャンセル"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: const Text("OK"),
                    onPressed: () {
                      setState(() {
                        final picked =
                            DateTime(selectedYear, selectedMonth, selectedDay);
                        isStart
                            ? selectedStartDate = picked
                            : selectedEndDate = picked;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    _picker(years, (i) => selectedYear = years[i], "年"),
                    _picker(months, (i) => selectedMonth = months[i], "月"),
                    _picker(days, (i) => selectedDay = days[i], "日"),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _picker(List<int> list, Function(int) onChanged, String suffix) {
    return Expanded(
      child: CupertinoPicker(
        itemExtent: 32,
        onSelectedItemChanged: onChanged,
        children: list.map((e) => Center(child: Text("$e $suffix"))).toList(),
      ),
    );
  }

  // ===== レビューカード =====
  Widget _reviewCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("2025/10/06", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("★★★★★", style: TextStyle(color: Colors.orange)),
            ],
          ),
          SizedBox(height: 6),
          Text("店舗名", style: TextStyle(fontSize: 13, color: Colors.grey)),
          SizedBox(height: 10),
          Text(
            "レビュー内容\nレビュー内容\nレビュー内容",
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
