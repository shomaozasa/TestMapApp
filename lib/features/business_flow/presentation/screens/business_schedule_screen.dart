import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ID取得用

import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/business_map_screen.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/business_event_edit_screen.dart';

class BusinessScheduleScreen extends StatefulWidget {
  const BusinessScheduleScreen({super.key});

  @override
  State<BusinessScheduleScreen> createState() => _BusinessScheduleScreenState();
}

class _BusinessScheduleScreenState extends State<BusinessScheduleScreen> {
  // ログイン中のIDを取得
  String get _currentAdminId => FirebaseAuth.instance.currentUser?.uid ?? '';

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<EventModel>> _events = {};
  final FirestoreService _firestoreService = FirestoreService();

  // テーマカラー（オレンジ）
  static const Color themeColor = Colors.orange;
  static const Color gradientStart = Color(0xFFFFCC80); // 薄いオレンジ
  static const Color gradientEnd = Color(0xFFFFF3E0);   // さらに薄いオレンジ

  final Map<DateTime, String> _holidayMap = {
    DateTime(2025, 1, 1): '元日',
    DateTime(2025, 1, 13): '成人の日',
    DateTime(2025, 2, 11): '建国記念の日',
    DateTime(2025, 2, 23): '天皇誕生日',
    DateTime(2025, 2, 24): '振替休日',
    DateTime(2025, 3, 20): '春分の日',
    DateTime(2025, 4, 29): '昭和の日',
    DateTime(2025, 5, 3): '憲法記念日',
    DateTime(2025, 5, 4): 'みどりの日',
    DateTime(2025, 5, 5): 'こどもの日',
    DateTime(2025, 5, 6): '振替休日',
    DateTime(2025, 7, 21): '海の日',
    DateTime(2025, 8, 11): '山の日',
    DateTime(2025, 9, 15): '敬老の日',
    DateTime(2025, 9, 23): '秋分の日',
    DateTime(2025, 10, 13): 'スポーツの日',
    DateTime(2025, 11, 3): '文化の日',
    DateTime(2025, 11, 23): '勤労感謝の日',
    DateTime(2025, 11, 24): '振替休日',
    DateTime(2026, 1, 1): '元日',
    DateTime(2026, 1, 12): '成人の日',
  };

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('ja_JP'); 
  }

  // eventTime 文字列から日付を解析してグループ化
  Map<DateTime, List<EventModel>> _groupEventsByDate(List<EventModel> events) {
    Map<DateTime, List<EventModel>> data = {};
    for (var event in events) {
      DateTime eventDate;
      try {
        final parts = event.eventTime.split(' ');
        if (parts.isNotEmpty) {
          final datePart = parts[0]; 
          final ymd = datePart.split('/'); // 2026/01/20 -> [2026, 01, 20]
          if (ymd.length == 3) {
            eventDate = DateTime(int.parse(ymd[0]), int.parse(ymd[1]), int.parse(ymd[2]));
          } else {
            eventDate = event.createdAt.toDate();
          }
        } else {
           eventDate = event.createdAt.toDate();
        }
      } catch (e) {
        eventDate = event.createdAt.toDate();
      }

      final dayKey = DateTime(eventDate.year, eventDate.month, eventDate.day);

      if (data[dayKey] == null) {
        data[dayKey] = [];
      }
      data[dayKey]!.add(event);
    }
    return data;
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _events[dayKey] ?? [];
  }

  String? _getHolidayName(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _holidayMap[dayKey];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black87, // アイコン色
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
          child: StreamBuilder<List<EventModel>>(
            stream: _firestoreService.getFutureEventsStream(_currentAdminId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _events = _groupEventsByDate(snapshot.data!);
              }
              
              return Column(
                children: [
                  // --- ヘッダー ---
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_month_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          "Schedule",
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
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // 1. カレンダーカード
                              Container(
                                margin: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TableCalendar(
                                  locale: 'ja_JP',
                                  firstDay: DateTime.utc(2024, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  calendarFormat: _calendarFormat,
                                  sixWeekMonthsEnforced: true,
                                  shouldFillViewport: false,
                                  eventLoader: _getEventsForDay,
                                  rowHeight: 52, 
                                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                  onFormatChanged: (format) {
                                    if (_calendarFormat != format) setState(() => _calendarFormat = format);
                                  },
                                  onPageChanged: (focusedDay) {
                                    _focusedDay = focusedDay;
                                  },
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false, titleCentered: true,
                                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                    leftChevronIcon: Icon(Icons.chevron_left, color: themeColor),
                                    rightChevronIcon: Icon(Icons.chevron_right, color: themeColor),
                                  ),
                                  calendarStyle: CalendarStyle(
                                    todayDecoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                                    todayTextStyle: const TextStyle(color: themeColor, fontWeight: FontWeight.bold),
                                    selectedDecoration: const BoxDecoration(color: themeColor, shape: BoxShape.circle),
                                    markerDecoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                    markersMaxCount: 1,
                                  ),
                                  calendarBuilders: CalendarBuilders(
                                    dowBuilder: (context, day) {
                                      final text = ['月', '火', '水', '木', '金', '土', '日'][day.weekday - 1];
                                      if (day.weekday == DateTime.sunday) return Center(child: Text(text, style: const TextStyle(color: Colors.red)));
                                      if (day.weekday == DateTime.saturday) return Center(child: Text(text, style: const TextStyle(color: Colors.blue)));
                                      return Center(child: Text(text, style: const TextStyle(color: Colors.black54)));
                                    },
                                    defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day),
                                    todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isToday: true),
                                    selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, isSelected: true),
                                    outsideBuilder: (context, day, focusedDay) => null,
                                  ),
                                ),
                              ),

                              // 2. 選択日のイベントリスト
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      "${_selectedDay?.month ?? _focusedDay.month}月${_selectedDay?.day ?? _focusedDay.day}日の予定",
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEventList(),
                                    const SizedBox(height: 80), // FABのスペース確保
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final targetDate = _selectedDay ?? DateTime.now();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessMapScreen(
                initialDate: targetDate,
              ),
            ),
          );
        },
        label: const Text('イベント登録', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add_location_alt_outlined),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    final holidayName = _getHolidayName(day);
    final isHoliday = holidayName != null;
    final isSunday = day.weekday == DateTime.sunday;
    final isSaturday = day.weekday == DateTime.saturday;
    
    Color? backgroundColor; 
    BoxBorder? border;
    
    if (isSelected) { backgroundColor = themeColor; } 
    else if (isToday) { backgroundColor = Colors.white; border = Border.all(color: themeColor, width: 2); } 
    else if (isHoliday || isSunday) { backgroundColor = Colors.red.shade50; } 
    else if (isSaturday) { backgroundColor = Colors.blue.shade50; }
    
    Color textColor = Colors.black87;
    if (isSelected) { textColor = Colors.white; } else if (isHoliday || isSunday) { textColor = Colors.red; } else if (isSaturday) { textColor = Colors.blue; }
    
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(10), border: border),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
          if (isHoliday) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.3) : Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
              child: Text(holidayName, style: TextStyle(color: isSelected ? Colors.white : Colors.red.shade900, fontSize: 8, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay ?? _focusedDay);
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text("予定はありません", style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true, // ScrollView内なので必須
      physics: const NeverScrollableScrollPhysics(), // 親のスクロールに任せる
      itemCount: events.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16), 
            onTap: () => _showDetailModal(event),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: event.eventImage.isNotEmpty 
                      ? Image.network(event.eventImage, width: 80, height: 80, fit: BoxFit.cover) 
                      : Container(width: 80, height: 80, color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(event.categoryId, style: const TextStyle(fontSize: 10, color: themeColor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 4),
                        Text(event.eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(event.eventTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // モーダル (デザイン微調整)
  void _showDetailModal(EventModel event) {
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85, // 少し高く
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 画像エリア
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: event.eventImage.isNotEmpty
                          ? Image.network(event.eventImage, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // タイトルと評価 (あれば)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.categoryId,
                              style: const TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          // 平均評価表示（もし値があれば）
                          if (event.reviewCount > 0)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(event.avgRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(" (${event.reviewCount})", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        event.eventName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildDetailRow(Icons.access_time_filled, "日時", event.eventTime),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.location_on, "場所", event.address),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Divider(),
                      ),
                      
                      const Text("詳細情報", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        event.description.isNotEmpty ? event.description : "詳細情報はありません。",
                        style: const TextStyle(height: 1.6, color: Colors.black87, fontSize: 15),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 編集・削除ボタン
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BusinessEventEditScreen(event: event),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("編集"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _confirmDelete(event);
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                label: const Text("削除", style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade200),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black54, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('削除の確認', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('この予定を削除してもよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteEvent(event.id);
            },
            child: const Text('削除する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}