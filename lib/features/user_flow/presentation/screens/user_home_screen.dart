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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントマップ（利用者）'),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _firestoreService.getEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildGoogleMap(Set<Marker>()); 
          }

          final List<EventModel> events = snapshot.data!;
          
          // イベントリストからマーカーセットを生成
          final Set<Marker> markers = events.map((event) {
            return Marker(
              markerId: MarkerId(event.id),
              position: LatLng(event.location.latitude, event.location.longitude),
              // カテゴリによってピンの色を変えることも可能（今回は赤で統一）
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: event.eventName,
                snippet: 'タップして詳細を見る', // ここに画像は出せないのでテキストのみ
                onTap: () {
                  _showEventDetails(event);
                },
              ),
            );
          }).toSet();

          return _buildGoogleMap(markers);
        },
      ),
    );
  }

  Widget _buildGoogleMap(Set<Marker> markers) {
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
      markers: markers,
    );
  }

  /// ★ イベント詳細をリッチに表示するボトムシート
  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 画面の高さに合わせて拡張可能に
      backgroundColor: Colors.transparent, // 背景を透明にして角丸を見せる
      builder: (context) {
        return Container(
          // 画面の高さの75%まで広げる
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. ヘッダー画像エリア ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      // 画像URLがある場合は表示、なければアイコン
                      child: event.eventImage.isNotEmpty
                          ? Image.network(
                              event.eventImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    Text('No Image', style: TextStyle(color: Colors.grey)),
                                  ],
                                );
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.image, size: 40, color: Colors.grey),
                                Text('No Image', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                    ),
                  ),
                  // 閉じるボタン
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

              // --- 2. 詳細情報エリア (スクロール可能) ---
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
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // イベント名
                      Text(
                        event.eventName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),
                      
                      // 開催時間
                      _buildInfoRow(Icons.access_time, '日時', event.eventTime),
                      const SizedBox(height: 16),

                      // 住所 (新規追加)
                      _buildInfoRow(Icons.location_on_outlined, '場所', 
                        event.address.isNotEmpty ? event.address : '住所情報なし'
                      ),
                      
                      const Divider(height: 40),

                      // 詳細説明
                      Text(
                        '詳細情報',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description.isNotEmpty
                            ? event.description
                            : '詳細情報はありません。',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      
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

  /// 情報行を作成するヘルパーメソッド
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
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}