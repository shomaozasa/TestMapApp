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
            return _buildGoogleMap(Set<Marker>()); // データがなくても地図は表示
          }

          final List<EventModel> events = snapshot.data!;
          
          // ★ 1. イベントリストからマーカーセットを生成
          //    (onTapコールバックで詳細シートを開くように変更)
          final Set<Marker> markers = events.map((event) {
            return Marker(
              markerId: MarkerId(event.id),
              position: LatLng(event.location.latitude, event.location.longitude),
              infoWindow: InfoWindow(
                title: event.eventName,
                snippet: 'タップして詳細を見る', // スニペットを変更
                // ★ 2. InfoWindow自体がタップされたら詳細シートを表示
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

  /// GoogleMapウィジェットを構築する
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

  /// ★ 3. イベント詳細をボトムシートで表示するメソッド (新設)
  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 高さに合わせて調整
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConstrainedBox(
          // 最大高さを画面の60%に制限
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- イベント名 ---
                  Text(
                    event.eventName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- 開催時間 ---
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.black54, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        event.eventTime,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- 緯度経度 (デバッグ用などに) ---
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.black54, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${event.location.latitude.toStringAsFixed(5)}, ${event.location.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // --- イベント詳細 ---
                  Text(
                    '詳細情報',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    // ★ 4. description を表示 (空の場合はメッセージ)
                    event.description.isNotEmpty
                        ? event.description
                        : '詳細情報はありません。',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}