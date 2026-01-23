import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // 現在地取得に必要
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/favorite_list_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final FirestoreService _firestoreService = FirestoreService();

  // ★ 予備の初期位置（天神）
  static const LatLng _kFallbackLocation = LatLng(33.590354, 130.401719);

  // ★ 現在地を保持する変数
  LatLng? _currentPosition;

  // 選択中のイベント
  EventModel? _selectedEvent;
  // お気に入りIDリスト
  Set<String> _bookmarkedIds = {};

  late Stream<List<EventModel>> _eventsStream;
  late Stream<List<EventModel>> _favoritesStream;

  @override
  void initState() {
    super.initState();
    // Streamの初期化
    _eventsStream = _firestoreService.getEventsStream();
    _favoritesStream = _firestoreService.getFavoritesStream();

    // ★ 起動時に現在地取得を開始
    _initializeLocation();
  }

  /// ★ 現在地取得とカメラ移動のロジック
  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      // 現在地を取得
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = newLatLng;
        });
      }

      // マップコントローラー準備完了後にカメラを移動
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 14.5));
    } catch (e) {
      debugPrint('Location Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントマップ（利用者）'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // --- 1. Google Map & データ取得 ---
          StreamBuilder<List<EventModel>>(
            stream: _eventsStream,
            builder: (context, eventSnapshot) {
              final List<EventModel> events = eventSnapshot.data ?? [];

              // マーカーの作成
              final Set<Marker> markers = events.map((event) {
                return Marker(
                  markerId: MarkerId(event.id),
                  position: LatLng(
                    event.location.latitude,
                    event.location.longitude,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                  onTap: () {
                    setState(() {
                      _selectedEvent = event;
                    });
                  },
                );
              }).toSet();

              return StreamBuilder<List<EventModel>>(
                stream: _favoritesStream,
                builder: (context, favSnapshot) {
                  if (favSnapshot.hasData) {
                    _bookmarkedIds = favSnapshot.data!.map((e) => e.id).toSet();
                  }

                  return GoogleMap(
                    mapType: MapType.normal,
                    // ★ 現在地があればそこを、なければ天神を初期位置にする
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition ?? _kFallbackLocation,
                      zoom: 14.5,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    onTap: (_) {
                      if (_selectedEvent != null) {
                        setState(() => _selectedEvent = null);
                      }
                    },
                    markers: markers,
                    padding: EdgeInsets.only(
                      bottom: _selectedEvent != null ? 280 : 100,
                    ),
                  );
                },
              );
            },
          ),

          // --- 2. イベント詳細カード (オーバーレイ) ---
          if (_selectedEvent != null)
            Positioned(
              bottom: 120,
              left: 20,
              right: 20,
              child: _buildEventCard(_selectedEvent!),
            ),

          // --- 3. カスタムボトムバー ---
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildCustomBottomBar(),
          ),
        ],
      ),
    );
  }

  /// イベント詳細カード
  Widget _buildEventCard(EventModel event) {
    final isBookmarked = _bookmarkedIds.contains(event.id);

    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        height: 140,
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
        child: Stack(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                  child: SizedBox(
                    width: 120,
                    height: double.infinity,
                    child: event.eventImage.isNotEmpty
                        ? Image.network(event.eventImage, fit: BoxFit.cover)
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.eventName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.eventTime,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '詳細を見る >',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: Icon(
                  isBookmarked ? Icons.favorite : Icons.favorite_border,
                  color: isBookmarked ? Colors.red : Colors.grey,
                ),
                onPressed: () => _firestoreService.toggleFavorite(event),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 詳細ボトムシート
  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StreamBuilder<List<EventModel>>(
          stream: _firestoreService.getFavoritesStream(),
          builder: (context, snapshot) {
            final isBookmarked =
                snapshot.hasData && snapshot.data!.any((e) => e.id == event.id);

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: event.eventImage.isNotEmpty
                              ? Image.network(
                                  event.eventImage,
                                  fit: BoxFit.cover,
                                )
                              : Container(color: Colors.grey.shade200),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              isBookmarked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isBookmarked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () =>
                                _firestoreService.toggleFavorite(event),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            Icons.access_time,
                            '日時',
                            event.eventTime,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.location_on,
                            '場所',
                            event.address,
                          ),
                          const Divider(height: 40),
                          const Text(
                            '詳細情報',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  /// ボトムバー
  Widget _buildCustomBottomBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8F6).withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            icon: Icons.close,
            onPressed: () => setState(() => _selectedEvent = null),
          ),
          _buildCircleButton(
            icon: Icons.star_border,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteListScreen(),
                ),
              );
            },
          ),
          _buildCircleButton(icon: Icons.home, onPressed: () {}),
          _buildCircleButton(icon: Icons.person_outline, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 28),
      ),
    );
  }
}
