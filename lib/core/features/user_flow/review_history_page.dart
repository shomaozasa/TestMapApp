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
      backgroundColor: const Color(0xFFF3F0F8),

      body: Column(
        children: [
          // 🔹 上部グラデーションヘッダー
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
                bottom: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

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
                      SizedBox(width: 5),
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

          // タイトル
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Center(
              child: Text(
                "レビュー履歴",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),


          // 🔹 下側コンテンツ
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    // ラベル
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

                    // ● タブ選択（最近 / カテゴリ / 店舗）
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTabButton(0, "最近"),
                        _buildTabButton(1, "カテゴリ"),
                        _buildTabButton(2, "店舗"),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ● 日付フィルター
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

                    const SizedBox(height: 16),

                    const Divider(height: 24),

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

                    // ● レビューリスト
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
        onMapTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  // タブボタン
  Widget _buildTabButton(int index, String label) {
    bool isSelected = index == selectedTab;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 日付フォーマット
  String _formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return "${d.year}/$mm/$dd";
  }

  // 日付ボックス
  Widget _dateBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  // カスタムスクロール
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
              // 上部ボタン
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Row(
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
                          if (isStart) {
                            selectedStartDate = picked;
                          } else {
                            selectedEndDate = picked;
                          }
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  children: [
                    // 年
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: years.indexOf(selectedYear),
                        ),
                        onSelectedItemChanged: (i) {
                          selectedYear = years[i];
                        },
                        children: years
                            .map((y) => Center(child: Text("$y 年")))
                            .toList(),
                      ),
                    ),
                    // 月
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedMonth - 1,
                        ),
                        onSelectedItemChanged: (i) {
                          selectedMonth = months[i];
                        },
                        children: months
                            .map((m) => Center(child: Text("$m 月")))
                            .toList(),
                      ),
                    ),
                    // 日
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedDay - 1,
                        ),
                        onSelectedItemChanged: (i) {
                          selectedDay = days[i];
                        },
                        children: days
                            .map((d) => Center(child: Text("$d 日")))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // レビューカード
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
        children: [
          // 上：日付 + 星
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "2025/10/06",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "★★★★★",
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "店舗名",
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 10),
          const Text(
            "レビュー内容\nレビュー内容\nレビュー内容",
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
