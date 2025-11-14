import 'dart:async'; // 非同期処理のため
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // Google Mapを操作するためのコントローラー
  final Completer<GoogleMapController> _controller = Completer();

  // 地図の初期表示位置（福岡・天神駅あたり）
  static const CameraPosition _kFukuokaTenjin = CameraPosition(
    target: LatLng(33.590, 130.401), // 緯度・経度
    zoom: 14.5, // ズームレベル
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントマップ（利用者）'),
      ),
      body: GoogleMap(
        // 地図の種類 (normal, satellite, terrain, hybrid)
        mapType: MapType.normal,
        // 初期表示されるカメラ位置
        initialCameraPosition: _kFukuokaTenjin,
        // マップが作成されたらコントローラーを保存
        onMapCreated: (GoogleMapController controller) {
          if (!_controller.isCompleted) {
              _controller.complete(controller);
          }
        },
        // TODO: ここにFirestoreから取得したマーカー(ピン)を追加していく
        markers: {
          // 例：ダミーのマーカー
          Marker(
            markerId: const MarkerId('dummy_event_1'),
            position: const LatLng(33.590, 130.401),
            infoWindow: const InfoWindow(
              title: 'ダミーイベント',
              snippet: 'これはテスト用のピンです',
            ),
          ),
        },
      ),
    );
  }
}