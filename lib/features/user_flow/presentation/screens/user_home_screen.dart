import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/models/business_user_model.dart';

import 'package:google_map_app/features/user_flow/presentation/screens/favorite_list_screen.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/business_public_profile_screen.dart';

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

  EventModel? _selectedEvent;
  
  // StreamはinitStateで一度だけ初期化
  late Stream<List<EventModel>> _eventsStream;
  late Stream<List<EventModel>> _favoritesStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.getEventsStream();
    
    // ★ 修正: ログイン状態を確認してからストリームを取得する (エラー回避の安全策)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _favoritesStream = _firestoreService.getFavoritesStream();
    } else {
      // ログインしていない場合は空のリストを流す
      _favoritesStream = Stream.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントマップ（利用者）'),
        automaticallyImplyLeading: false,
      ),
      // StreamBuilderを一番外側に配置し、マップとカードの両方にデータを渡す
      body: StreamBuilder<List<EventModel>>(
        stream: _eventsStream,
        builder: (context, eventSnapshot) {
          final List<EventModel> events = eventSnapshot.data ?? [];

          return StreamBuilder<List<EventModel>>(
            stream: _favoritesStream,
            builder: (context, favSnapshot) {
              // お気に入りIDリストを作成
              final Set<String> bookmarkedIds = favSnapshot.hasData
                  ? favSnapshot.data!.map((e) => e.id).toSet()
                  : {};

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

              return Stack(
                children: [
                  // --- 1. Google Map ---
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kTenjin,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted) {
                        _controller.complete(controller);
                      }
                    },
                    onTap: (_) {
                      if (_selectedEvent != null) {
                        setState(() {
                          _selectedEvent = null;
                        });
                      }
                    },
                    markers: markers,
                    padding: EdgeInsets.only(
                      bottom: _selectedEvent != null ? 280 : 100,
                    ),
                  ),

                  // --- 2. イベント詳細カード (ポップアップ) ---
                  if (_selectedEvent != null)
                    Positioned(
                      bottom: 120,
                      left: 20,
                      right: 20,
                      // ここに bookmarkedIds を渡して、ハートの状態を正しく表示する
                      child: _buildEventCard(_selectedEvent!, bookmarkedIds),
                    ),

                  // --- 3. ボトムバー ---
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: _buildCustomBottomBar(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// マップ上に表示するイベント詳細カード
  Widget _buildEventCard(EventModel event, Set<String> bookmarkedIds) {
    final isBookmarked = bookmarkedIds.contains(event.id);

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
                // --- 左側：イベント画像 ---
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
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
                                  color: Colors.grey),
                            ),
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
                        // カテゴリ
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
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // イベント名
                        Text(
                          event.eventName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        // 日時
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.eventTime,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // 事業者情報と詳細リンク
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 事業者情報 (FutureBuilderで取得)
                            Expanded(
                              child: FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('businesses')
                                    .doc(event.adminId)
                                    .get(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return const SizedBox.shrink();
                                  }
                                  final business =
                                      BusinessUserModel.fromFirestore(
                                          snapshot.data!);
                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage:
                                            (business.iconImage != null &&
                                                    business.iconImage!
                                                        .isNotEmpty)
                                                ? NetworkImage(
                                                    business.iconImage!)
                                                : null,
                                        child: (business.iconImage == null ||
                                                business.iconImage!.isEmpty)
                                            ? const Icon(Icons.store,
                                                size: 12, color: Colors.grey)
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          business.adminName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            
                            // 詳細リンク
                            const Text(
                              '詳細 >',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // ハートボタン
            Positioned(
              top: 5,
              right: 5,
              child: IconButton(
                icon: Icon(
                  isBookmarked ? Icons.favorite : Icons.favorite_border,
                  color: isBookmarked ? Colors.red : Colors.grey,
                ),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await _firestoreService.toggleFavorite(event);
                  }
                },
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
          stream: _favoritesStream,
          builder: (context, snapshot) {
            Set<String> currentBookmarks = {};
            if (snapshot.hasData) {
              currentBookmarks = snapshot.data!.map((e) => e.id).toSet();
            }
            final isBookmarked = currentBookmarks.contains(event.id);

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ヘッダー画像
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
                              ? Image.network(event.eventImage,
                                  fit: BoxFit.cover)
                              : const Center(
                                  child: Icon(Icons.image,
                                      size: 50, color: Colors.grey)),
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
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                await _firestoreService.toggleFavorite(event);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 詳細情報
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
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.eventName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),

                          // 主催者リンク
                          const SizedBox(height: 24),
                          const Text("主催者",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          const SizedBox(height: 8),
                          _buildBusinessLink(event.adminId),

                          const SizedBox(height: 24),
                          _buildInfoRow(
                              Icons.access_time, '日時', event.eventTime),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            '場所',
                            event.address.isNotEmpty ? event.address : '住所情報なし',
                          ),
                          const Divider(height: 40),
                          Text(
                            '詳細情報',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.description.isNotEmpty
                                ? event.description
                                : '詳細情報はありません。',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.5),
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
      },
    );
  }

  // 事業者プロフィールリンク
  Widget _buildBusinessLink(String adminId) {
    if (adminId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('businesses')
          .doc(adminId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ListTile(
            leading: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white)),
            title: Text("主催者情報なし"),
          );
        }

        final business = BusinessUserModel.fromFirestore(snapshot.data!);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BusinessPublicProfileScreen(adminId: adminId),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (business.iconImage != null &&
                          business.iconImage!.isNotEmpty)
                      ? NetworkImage(business.iconImage!)
                      : null,
                  child: (business.iconImage == null ||
                          business.iconImage!.isEmpty)
                      ? const Icon(Icons.store, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.adminName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'プロフィールを見る >',
                        style: TextStyle(
                            color: Colors.blue.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8F6).withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
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
            isActive: true,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const FavoriteListScreen()),
              );
            },
          ),
          _buildCircleButton(icon: null, onPressed: () {}),
          _buildCircleButton(
            icon: Icons.person_outline,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('利用者プロフィールは準備中です')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(
      {IconData? icon,
      required VoidCallback onPressed,
      bool isActive = false}) {
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