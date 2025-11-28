import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/models/event_model.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final FirestoreService _firestoreService = FirestoreService();

  static const CameraPosition _kTenjin = CameraPosition(
    target: LatLng(33.590354, 130.401719),
    zoom: 14.5,
  );

  // ★ 選択中のイベントを保持する変数
  EventModel? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントマップ（利用者）'),
      ),
      body: Stack(
        children: [
          // --- 1. Google Map ---
          StreamBuilder<List<EventModel>>(
            stream: _firestoreService.getEventsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // エラーや空データの処理は簡略化
              final List<EventModel> events = snapshot.data ?? [];
              
              final Set<Marker> markers = events.map((event) {
                return Marker(
                  markerId: MarkerId(event.id),
                  position: LatLng(event.location.latitude, event.location.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                  // ★ InfoWindowは使わず、onTapで状態を更新
                  onTap: () {
                    setState(() {
                      _selectedEvent = event;
                    });
                  },
                );
              }).toSet();

              return GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kTenjin,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  if (!_controller.isCompleted) {
                    _controller.complete(controller);
                  }
                },
                // マップの背景をタップしたら選択解除
                onTap: (_) {
                  if (_selectedEvent != null) {
                    setState(() {
                      _selectedEvent = null;
                    });
                  }
                },
                markers: markers,
                // カードが表示されている時は、Googleロゴなどが隠れないようパディング
                padding: EdgeInsets.only(
                  bottom: _selectedEvent != null ? 260 : 0, 
                ),
              );
            },
          ),

          // --- 2. イベント詳細カード (オーバーレイ) ---
          if (_selectedEvent != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildEventCard(_selectedEvent!),
            ),
        ],
      ),
    );
  }

  /// ★ マップ上に表示するイベント詳細カード
  Widget _buildEventCard(EventModel event) {
    return GestureDetector(
      onTap: () {
        // カード全体をタップしたら、詳細ボトムシートを開く
        _showEventDetails(event);
      },
      child: Container(
        height: 140, // カードの高さ
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // --- 左側：画像 ---
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 120,
                height: double.infinity,
                child: event.eventImage.isNotEmpty
                    ? Image.network(
                        event.eventImage,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, _) => 
                            Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            
            // --- 右側：情報 ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // カテゴリ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.categoryId.isNotEmpty ? event.categoryId : '未分類',
                        style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // イベント名
                    Text(
                      event.eventName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // 時間
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text(
                          event.eventTime,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // 詳細を見るリンク
                    const Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '詳細を見る >',
                        style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ★ 詳細ボトムシート (前回と同じ)
  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // (ヘッダー画像)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: event.eventImage.isNotEmpty
                          ? Image.network(event.eventImage, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
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
              // (詳細情報)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // カテゴリチップ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50, 
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          event.categoryId.isNotEmpty ? event.categoryId : '未分類',
                          style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(event.eventName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.access_time, '日時', event.eventTime),
                      const SizedBox(height: 16),
                      _buildInfoRow(Icons.location_on_outlined, '場所', event.address.isNotEmpty ? event.address : '住所情報なし'),
                      const Divider(height: 40),
                      Text('詳細情報', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(event.description.isNotEmpty ? event.description : '詳細情報はありません。', style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)),
                      const SizedBox(height: 40),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black54, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}