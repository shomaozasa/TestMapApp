import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  static const LatLng _kFallbackLocation = LatLng(33.590354, 130.401719);
  LatLng? _currentPosition;

  EventModel? _selectedEvent;
  late Stream<List<EventModel>> _eventsStream;
  late Stream<List<EventModel>> _favoritesStream;

  String _searchKeyword = "";
  String _searchCategory = "すべて";
  DateTime? _searchDate;
  double _searchDistance = 5.0;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.getEventsStream();
    final user = FirebaseAuth.instance.currentUser;
    _favoritesStream = user != null
        ? _firestoreService.getFavoritesStream()
        : Stream.value([]);
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newLatLng = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _currentPosition = newLatLng);
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 14.5));
    } catch (e) {
      debugPrint('Location Error: $e');
    }
  }

  void _applySearch({
    required String keyword,
    required String category,
    required DateTime? date,
    required double distance,
  }) {
    // 日本語からDB用の英語に変換するマップ
    final categoryMap = {
      'グルメ': 'Food',
      'ライブ': 'Music',
      '体験': 'Shop', // または対応する英語
      '展示': 'Art',
      'すべて': 'すべて',
    };

    // 変換後のカテゴリ（マップにない場合は Other にする）
    final String dbCategory = categoryMap[category] ?? 'Other';

    setState(() {
      _searchKeyword = keyword;
      _searchCategory = category; // UI表示用には日本語を保持
      _searchDate = date;
      _searchDistance = distance;

      // FirestoreServiceには英語の dbCategory を渡す
      _eventsStream = _firestoreService.getEventsStream(
        keyword: _searchKeyword,
        category: dbCategory, // ここを英語にする
        selectedDate: _searchDate,
      );
    });
  }

  void _showSearchPanel() {
    String tempCategory = _searchCategory;
    double tempDistance = _searchDistance;
    DateTime? tempDate = _searchDate;
    final TextEditingController keywordController = TextEditingController(
      text: _searchKeyword,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPanelState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '検索・絞り込み',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setPanelState(() {
                              keywordController.clear();
                              tempCategory = 'すべて';
                              tempDistance = 5.0;
                              tempDate = null;
                            });
                          },
                          child: const Text(
                            'リセット',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: keywordController,
                      decoration: InputDecoration(
                        hintText: 'キーワードを入力...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '日時以降',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      title: Text(
                        tempDate == null
                            ? '指定なし'
                            : DateFormat('yyyy/MM/dd HH:mm').format(tempDate!),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setPanelState(() {
                              tempDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    const Divider(),
                    Text(
                      '距離: ${tempDistance.toInt()} km 以内',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Slider(
                      value: tempDistance,
                      min: 1,
                      max: 50,
                      divisions: 10,
                      onChanged: (val) =>
                          setPanelState(() => tempDistance = val),
                    ),
                    const Text(
                      'カテゴリ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['すべて', 'グルメ', '体験', '展示', 'ライブ'].map((cat) {
                        return ChoiceChip(
                          label: Text(cat),
                          selected: tempCategory == cat,
                          onSelected: (val) =>
                              setPanelState(() => tempCategory = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          _applySearch(
                            keyword: keywordController.text,
                            category: tempCategory,
                            date: tempDate,
                            distance: tempDistance,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'この条件で検索',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('イベントマップ（利用者）'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: _eventsStream,
        builder: (context, eventSnapshot) {
          List<EventModel> events = eventSnapshot.data ?? [];
          if (_currentPosition != null) {
            events = events.where((e) {
              double dist = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                e.location.latitude,
                e.location.longitude,
              );
              return dist <= (_searchDistance * 1000);
            }).toList();
          }

          return StreamBuilder<List<EventModel>>(
            stream: _favoritesStream,
            builder: (context, favSnapshot) {
              final Set<String> bookmarkedIds = favSnapshot.hasData
                  ? favSnapshot.data!.map((e) => e.id).toSet()
                  : {};
              final Set<Marker> markers = events.map((event) {
                return Marker(
                  markerId: MarkerId(event.id),
                  position: LatLng(
                    event.location.latitude,
                    event.location.longitude,
                  ),
                  onTap: () => setState(() => _selectedEvent = event),
                );
              }).toSet();

              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition ?? _kFallbackLocation,
                      zoom: 14.5,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted)
                        _controller.complete(controller);
                    },
                    onTap: (_) => setState(() => _selectedEvent = null),
                    markers: markers,
                    padding: EdgeInsets.only(
                      bottom: _selectedEvent != null ? 280 : 100,
                    ),
                  ),
                  if (_selectedEvent != null)
                    Positioned(
                      bottom: 120,
                      left: 20,
                      right: 20,
                      child: _buildEventCard(_selectedEvent!, bookmarkedIds),
                    ),
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

  Widget _buildEventCard(EventModel event, Set<String> bookmarkedIds) {
    final isBookmarked = bookmarkedIds.contains(event.id);
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                        : Container(color: Colors.grey.shade200),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.eventTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          '詳細 >',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
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

  // ★ 詳細表示メソッド（戻るボタンとお気に入りボタンを追加）
  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  if (event.eventImage.isNotEmpty)
                    Image.network(
                      event.eventImage,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  Padding(
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
                        _buildBusinessLink(event.adminId),
                        const Divider(height: 40),
                        const Text(
                          '詳細内容',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- 戻るボタン ---
            Positioned(
              top: 20,
              left: 20,
              child: FloatingActionButton.small(
                heroTag: 'backBtnDetail',
                backgroundColor: Colors.white,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
            // --- イイネボタン (IDセットで判定) ---
            Positioned(
              top: 20,
              right: 20,
              child: StreamBuilder<Set<String>>(
                stream: _firestoreService.getFavoriteIdsStream(), // ★IDのセットを取得
                builder: (context, snapshot) {
                  final favoriteIds = snapshot.data ?? {};
                  // セットの中にこのイベントIDが含まれているかチェック
                  final bool isFav = favoriteIds.contains(event.id);

                  return FloatingActionButton.small(
                    heroTag: 'favBtnDetail',
                    backgroundColor: Colors.white,
                    onPressed: () async {
                      await _firestoreService.toggleFavorite(event);
                    },
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessLink(String adminId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('businesses')
          .doc(adminId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox.shrink();
        final business = BusinessUserModel.fromFirestore(snapshot.data!);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: (business.iconImage != null)
                ? NetworkImage(business.iconImage!)
                : null,
          ),
          title: Text(business.adminName),
          subtitle: const Text('主催者プロフィールを見る >'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessPublicProfileScreen(adminId: adminId),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomBottomBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8F6).withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteListScreen()),
            ),
          ),
          _buildCircleButton(icon: Icons.search, onPressed: _showSearchPanel),
          _buildCircleButton(icon: Icons.person_outline, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildCircleButton({IconData? icon, required VoidCallback onPressed}) {
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
