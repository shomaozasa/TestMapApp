import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/models/event_model.dart';
// ★ 作成したお気に入り画面をインポート (パスは環境に合わせて調整してください)
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

  static const CameraPosition _kTenjin = CameraPosition(
    target: LatLng(33.590354, 130.401719),
    zoom: 14.5,
  );

  // 選択中のイベントを保持する変数
  EventModel? _selectedEvent;
  
  // マップ用イベントリスト
  List<EventModel> _mapEvents = [];
  // お気に入りIDリスト
  Set<String> _bookmarkedIds = {};

  // ★ 画面更新でリロードされないようStreamを保持
  late Stream<List<EventModel>> _eventsStream;
  late Stream<List<EventModel>> _favoritesStream;

  @override
  void initState() {
    super.initState();
    // 初期化時に一度だけStreamを取得
    _eventsStream = _firestoreService.getEventsStream();
    _favoritesStream = _firestoreService.getFavoritesStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントマップ（利用者）'),
      ),
      body: Stack(
        children: [
          // --- 1. Google Map & データ取得 ---
          StreamBuilder<List<EventModel>>(
            stream: _eventsStream,
            builder: (context, eventSnapshot) {
              if (eventSnapshot.hasData) {
                _mapEvents = eventSnapshot.data!;
              }

              // お気に入り情報を監視して重ねる
              return StreamBuilder<List<EventModel>>(
                stream: _favoritesStream,
                builder: (context, favSnapshot) {
                  if (favSnapshot.hasData) {
                    _bookmarkedIds = favSnapshot.data!.map((e) => e.id).toSet();
                  }

                  final Set<Marker> markers = _mapEvents.map((event) {
                    return Marker(
                      markerId: MarkerId(event.id),
                      position: LatLng(
                          event.location.latitude, event.location.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueRed),
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
                    // マップ背景タップで選択解除
                    onTap: (_) {
                      if (_selectedEvent != null) {
                        setState(() {
                          _selectedEvent = null;
                        });
                      }
                    },
                    markers: markers,
                    // カードやボトムバー用パディング
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
              bottom: 120, // ボトムバーの上に表示
              left: 20,
              right: 20,
              child: _buildEventCard(_selectedEvent!),
            ),

          // --- 3. カスタムボトムバー (常に表示) ---
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

  /// ★ マップ上に表示するイベント詳細カード (お気に入りボタン付き)
  Widget _buildEventCard(EventModel event) {
    final isBookmarked = _bookmarkedIds.contains(event.id);

    return GestureDetector(
      onTap: () {
        _showEventDetails(event);
      },
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
                // --- 左側：画像 ---
                ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: SizedBox(
                    width: 120,
                    height: double.infinity,
                    child: event.eventImage.isNotEmpty
                        ? Image.network(
                            event.eventImage,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, _) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.grey)),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image,
                                size: 40, color: Colors.grey),
                          ),
                  ),
                ),

                // --- 右側：情報 ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 40, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            event.categoryId.isNotEmpty
                                ? event.categoryId
                                : '未分類',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.eventName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Text(
                              event.eventTime,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
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
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ★ ハートボタン
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: Icon(
                  isBookmarked ? Icons.favorite : Icons.favorite_border,
                  color: isBookmarked ? Colors.red : Colors.grey,
                ),
                onPressed: () async {
                  await _firestoreService.toggleFavorite(event);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ★ 詳細ボトムシート (お気に入りボタン追加)
  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // シート内でもお気に入り状態を更新するため StreamBuilder を使用
        return StreamBuilder<List<EventModel>>(
          stream: _firestoreService.getFavoritesStream(),
          builder: (context, snapshot) {
            Set<String> currentBookmarks = {};
            if (snapshot.hasData) {
              currentBookmarks = snapshot.data!.map((e) => e.id).toSet();
            }
            final isBookmarked = currentBookmarks.contains(event.id);

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
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: event.eventImage.isNotEmpty
                              ? Image.network(event.eventImage, fit: BoxFit.cover)
                              : const Center(
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey)),
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
                      // ★ お気に入りボタン
                      Positioned(
                        top: 10,
                        left: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(
                            icon: Icon(
                              isBookmarked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isBookmarked ? Colors.red : Colors.grey,
                            ),
                            onPressed: () async {
                              await _firestoreService.toggleFavorite(event);
                            },
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              event.categoryId.isNotEmpty
                                  ? event.categoryId
                                  : '未分類',
                              style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(event.eventName,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          _buildInfoRow(
                              Icons.access_time, '日時', event.eventTime),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                              Icons.location_on_outlined,
                              '場所',
                              event.address.isNotEmpty
                                  ? event.address
                                  : '住所情報なし'),
                          const Divider(height: 40),
                          Text('詳細情報',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                              event.description.isNotEmpty
                                  ? event.description
                                  : '詳細情報はありません。',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(height: 1.5)),
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
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 16, color: Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  // ★ デザインされたボトムバー
  Widget _buildCustomBottomBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8F6).withOpacity(0.95), // 水色
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
          // 閉じる
          _buildCircleButton(
            icon: Icons.close,
            onPressed: () => setState(() => _selectedEvent = null),
          ),
          // お気に入り一覧へ遷移
          _buildCircleButton(
            icon: Icons.star_border,
            isActive: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoriteListScreen(),
                ),
              );
            },
          ),
          // ホーム (ダミー)
          _buildCircleButton(
            icon: null,
            onPressed: () {},
          ),
          // マイページ (ダミー)
          _buildCircleButton(
            icon: Icons.person_outline,
            onPressed: () {
              // マイページ処理
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    IconData? icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: icon != null
            ? Icon(icon, color: Colors.grey.shade700, size: 28)
            : null,
      ),
    );
  }
}