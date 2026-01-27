import 'dart:async';
import 'dart:math';
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
import 'package:google_map_app/features/user_flow/presentation/screens/user_profile_screen.dart';
import 'package:google_map_app/features/user_flow/presentation/widgets/map_circle_helper.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final FirestoreService _firestoreService = FirestoreService();

  static const LatLng _kFallbackLocation = LatLng(33.590354, 130.401719);
  LatLng? _currentPosition;

  EventModel? _selectedEvent;
  late Stream<List<EventModel>> _eventsStream;

  // 検索条件
  String _searchKeyword = "";
  String _searchCategory = "すべて";
  DateTime? _searchDate;
  double _searchDistance = 1.0; 

  // アニメーションコントローラー
  late AnimationController _sonarController;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.getEventsStream();
    _initializeLocation();

    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _sonarController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final newLatLng = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() => _currentPosition = newLatLng);
        _zoomToFitCircle(newLatLng, _searchDistance);
      }
    } catch (e) {
      debugPrint('Location Error: $e');
    }
  }

  Future<void> _zoomToFitCircle(LatLng center, double radiusKm) async {
    final GoogleMapController controller = await _controller.future;
    double radiusLat = radiusKm / 111.32;
    double radiusLng = radiusKm / (40075.0 * cos(center.latitude * pi / 180) / 360);

    LatLng southwest = LatLng(center.latitude - radiusLat, center.longitude - radiusLng);
    LatLng northeast = LatLng(center.latitude + radiusLat, center.longitude + radiusLng);

    LatLngBounds bounds = LatLngBounds(southwest: southwest, northeast: northeast);
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _applySearch({
    required String keyword,
    required String category,
    required DateTime? date,
    required double distance,
  }) {
    final categoryMap = {
      'グルメ': 'Food',
      'ライブ': 'Music',
      '体験': 'Shop',
      '展示': 'Art',
      'すべて': 'すべて',
    };

    final String dbCategory = categoryMap[category] ?? 'Other';

    setState(() {
      _searchKeyword = keyword;
      _searchCategory = category;
      _searchDate = date;
      _searchDistance = distance;

      _eventsStream = _firestoreService.getEventsStream(
        keyword: _searchKeyword,
        category: dbCategory,
        selectedDate: _searchDate,
      );
    });

    if (_currentPosition != null) {
      _zoomToFitCircle(_currentPosition!, distance);
    }
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
                        const Text('検索・絞り込み', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            setPanelState(() {
                              keywordController.clear();
                              tempCategory = 'すべて';
                              tempDistance = 1.0;
                              tempDate = null;
                            });
                          },
                          child: const Text('リセット', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: keywordController,
                      decoration: InputDecoration(
                        hintText: 'キーワードを入力...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('日時以降', style: TextStyle(fontWeight: FontWeight.bold)),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Colors.blue),
                      title: Text(
                        tempDate == null ? '指定なし' : DateFormat('yyyy/MM/dd HH:mm').format(tempDate!),
                      ),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setPanelState(() {
                              tempDate = DateTime(
                                date.year, date.month, date.day, time.hour, time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('距離範囲', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${tempDistance.toInt()} km 以内', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: tempDistance,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${tempDistance.toInt()} km',
                      onChanged: (val) => setPanelState(() => tempDistance = val),
                    ),
                    const Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['すべて', 'グルメ', '体験', '展示', 'ライブ'].map((cat) {
                        return ChoiceChip(
                          label: Text(cat),
                          selected: tempCategory == cat,
                          onSelected: (val) => setPanelState(() => tempCategory = cat),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                        child: const Text('この条件で検索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      // ★ 修正: AppBarを専用メソッドに委譲
      appBar: _buildAppBar(),
      
      // ★ 追加: ヘッダーがない場合、地図をステータスバーの裏まで広げる
      extendBodyBehindAppBar: true, 

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
              AnimatedBuilder(
                animation: _sonarController,
                builder: (context, child) {
                  return GoogleMap(
                    mapType: MapType.normal,
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
                    onTap: (_) => setState(() => _selectedEvent = null),
                    markers: markers,
                    circles: createSearchRadiusWithSonar(
                      center: _currentPosition,
                      radiusKm: _searchDistance,
                      animationValue: _sonarController.value,
                    ),
                    // ヘッダーが消えたので、上部のパディングは不要（もしくはステータスバー分だけ空ける）
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top, // ステータスバーと被らないように調整
                      bottom: _selectedEvent != null ? 280 : 100,
                    ),
                  );
                },
              ),
              if (_selectedEvent != null)
                Positioned(
                  bottom: 120,
                  left: 20,
                  right: 20,
                  child: _buildEventCard(_selectedEvent!),
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
      ),
    );
  }

  // ★ 追加: ヘッダー用メソッド（型枠）
  // 将来ヘッダーを表示したい場合は、ここのコメントアウトを外して修正するだけでOKです
  PreferredSizeWidget? _buildAppBar() {
    /*
    return AppBar(
      title: const Text('イベントマップ（利用者）'),
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white.withOpacity(0.9), // 半透明にする例
      elevation: 0,
    );
    */
    return null; // 現在は非表示（nullを返すとヘッダー領域が消滅します）
  }

  // --- 以下、既存のウィジェットメソッド（変更なし） ---

  Widget _buildEventCard(EventModel event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 120,
                height: double.infinity,
                child: event.eventImage.isNotEmpty
                    ? Image.network(event.eventImage, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, size: 40),
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.eventTime,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Spacer(),
                    const Align(
                      alignment: Alignment.centerRight,
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

  void _showEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: event.eventImage.isNotEmpty
                          ? Image.network(event.eventImage, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 50),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.eventName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 24),
                          _buildBusinessLinkWithFollow(event.adminId),
                          const SizedBox(height: 24),
                          _buildInfoRow(Icons.access_time, '日時', event.eventTime),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.location_on_outlined, '場所', event.address),
                          const Divider(height: 40),
                          const Text('詳細情報', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(event.description, style: const TextStyle(fontSize: 16, height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusinessLinkWithFollow(String adminId) {
    if (adminId.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('businesses').doc(adminId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        final business = BusinessUserModel.fromFirestore(snapshot.data!);
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BusinessPublicProfileScreen(adminId: adminId)),
          ),
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
                  backgroundImage: (business.iconImage?.isNotEmpty ?? false) ? NetworkImage(business.iconImage!) : null,
                  child: (business.iconImage?.isEmpty ?? true) ? const Icon(Icons.store) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business.adminName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('プロフィールを見る >', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                StreamBuilder<bool>(
                  stream: _firestoreService.isBusinessFollowedStream(adminId),
                  builder: (context, snapshot) {
                    final isFollowed = snapshot.data ?? false;
                    return ElevatedButton(
                      onPressed: () => _firestoreService.toggleFollowBusiness(adminId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowed ? Colors.white : Colors.orange,
                        foregroundColor: isFollowed ? Colors.orange : Colors.white,
                        side: const BorderSide(color: Colors.orange),
                        minimumSize: const Size(60, 32),
                      ),
                      child: Text(isFollowed ? 'フォロー中' : 'フォロー', style: const TextStyle(fontSize: 11)),
                    );
                  },
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
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text(value, style: const TextStyle(fontSize: 15)),
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
            icon: Icons.store_mall_directory_outlined,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteListScreen()),
            ),
          ),
          _buildCircleButton(icon: Icons.home, onPressed: () {}),
          _buildCircleButton(
            icon: Icons.person_outline,
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.uid)),
                );
              }
            },
          ),
          _buildCircleButton(icon: Icons.search, onPressed: _showSearchPanel),
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
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.grey.shade700, size: 28),
      ),
    );
  }
}