import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ★ ID取得用に推奨

import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/features/business_flow/presentation/screens/business_map_screen.dart';
// ★ 追加: 編集画面をインポート
import 'package:google_map_app/features/business_flow/presentation/screens/business_event_edit_screen.dart';

class BusinessScheduleScreen extends StatefulWidget {
  const BusinessScheduleScreen({super.key});

  @override
  State<BusinessScheduleScreen> createState() => _BusinessScheduleScreenState();
}

class _BusinessScheduleScreenState extends State<BusinessScheduleScreen> {
  // ログイン中のIDを取得 (テスト用IDではなく実IDを使用)
  String get _currentAdminId => FirebaseAuth.instance.currentUser?.uid ?? '';

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  Map<DateTime, List<EventModel>> _events = {};
  final FirestoreService _firestoreService = FirestoreService();

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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('予定管理', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _firestoreService.getFutureEventsStream(_currentAdminId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _events = _groupEventsByDate(snapshot.data!);
          }
          
          return Column(
            children: [
               Container(
                height: 420,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
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
                    titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.orange),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.orange),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                    todayTextStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    selectedDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
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
              Expanded(
                child: Container(
                  color: Colors.grey.shade100, 
                  child: _buildEventList(),
                ),
              ),
            ],
          );
        },
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
        label: const Text('イベント登録'),
        icon: const Icon(Icons.add_location_alt_outlined),
        backgroundColor: Colors.orange,
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
    
    if (isSelected) { backgroundColor = Colors.orange; } 
    else if (isToday) { backgroundColor = Colors.white; border = Border.all(color: Colors.orange, width: 2); } 
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
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.event_note, size: 60, color: Colors.grey.shade300), const SizedBox(height: 16), Text("予定はありません", style: TextStyle(color: Colors.grey.shade500, fontSize: 16))]));
    }
    return ListView.builder(
      itemCount: events.length, padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          elevation: 0, margin: const EdgeInsets.only(bottom: 12), color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12), onTap: () => _showDetailModal(event),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: event.eventImage.isNotEmpty ? Image.network(event.eventImage, width: 70, height: 70, fit: BoxFit.cover) : Container(width: 70, height: 70, color: Colors.grey.shade100, child: const Icon(Icons.image, color: Colors.grey))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.eventName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.orange), const SizedBox(width: 4), Text(event.eventTime, style: const TextStyle(fontSize: 13, color: Colors.black54))]), if (event.description.isNotEmpty) ...[const SizedBox(height: 4), Text(event.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))]])),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ★ 修正: モーダルに編集ボタンを追加
  void _showDetailModal(EventModel event) {
     showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      height: 250,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade100),
                            ),
                            child: Text(
                              event.categoryId,
                              style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.eventName,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                      
                      // ★ 修正: 編集・削除ボタンを横並びに配置
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // 編集画面へ遷移
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
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context); // モーダルを閉じてから削除確認へ
                                  _confirmDelete(event);
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                label: const Text("削除", style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade200),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black54, size: 20),
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
        title: const Text('削除の確認'),
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