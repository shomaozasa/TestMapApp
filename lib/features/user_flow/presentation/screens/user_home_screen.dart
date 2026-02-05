import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/models/business_user_model.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/business_public_profile_screen.dart';
import 'package:google_map_app/features/user_flow/presentation/widgets/map_circle_helper.dart';
import 'package:google_map_app/core/constants/event_status.dart';
import 'package:google_map_app/core/utils/map_utils.dart';
import 'package:google_map_app/core/service/fcm_service.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/review_post_screen.dart';

// ★追加: コントロールパネルをインポート
import 'package:google_map_app/features/user_flow/presentation/widgets/user_control_panel.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final FirestoreService _firestoreService = FirestoreService();
  final FcmService _fcmService = FcmService();

  static const LatLng _kFallbackLocation = LatLng(33.590354, 130.401719);
  LatLng? _currentPosition;
  late AnimationController _sonarController;

  late Stream<List<EventModel>> _eventsStream;
  
  // 選択中のイベント（nullならカード非表示）
  EventModel? _selectedEvent;

  // 検索条件
  String _searchKeyword = "";
  String _searchCategory = "すべて";
  DateTime? _searchDate;
  double _searchDistance = 1.0;

  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _eventsStream = _firestoreService.getEventsStream();
    _initializeLocation();
    _fcmService.initialize();

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
        setState(() {
          _currentPosition = newLatLng;
          _hasSearched = true;
        });
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

    LatLng southwest = LatLng(
      center.latitude - radiusLat,
      center.longitude - radiusLng,
    );
    LatLng northeast = LatLng(
      center.latitude + radiusLat,
      center.longitude + radiusLng,
    );

    LatLngBounds bounds = LatLngBounds(
      southwest: southwest,
      northeast: northeast,
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _applySearch({
    required String keyword,
    required String category,
    required DateTime? date,
    required double distance,
  }) {
    final categoryMap = {
      'グルメ': 'Food', 'ライブ': 'Music', '体験': 'Shop', '展示': 'Art', 'すべて': 'すべて',
    };
    final String dbCategory = categoryMap[category] ?? 'Other';

    setState(() {
      _searchKeyword = keyword;
      _searchCategory = category;
      _searchDate = date;
      _searchDistance = distance;
      _hasSearched = true;

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

  Future<void> _openMapApp(double lat, double lng) async {
    Uri url;

    if (kIsWeb) {
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    } else if (Platform.isIOS) {
      url = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
    } else {
      url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Map Launch Error: $e');
    }
  }

  void _onMarkerTapped(EventModel event) {
    setState(() {
      _selectedEvent = event;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
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

            events.sort((a, b) {
              double distA = Geolocator.distanceBetween(
                _currentPosition!.latitude, _currentPosition!.longitude,
                a.location.latitude, a.location.longitude,
              );
              double distB = Geolocator.distanceBetween(
                _currentPosition!.latitude, _currentPosition!.longitude,
                b.location.latitude, b.location.longitude,
              );
              return distA.compareTo(distB);
            });
          }
          
          final Set<Marker> markers = events.map((event) {
            return Marker(
              markerId: MarkerId(event.id),
              position: LatLng(
                event.location.latitude,
                event.location.longitude,
              ),
              icon: MapUtils.getMarkerIconByStatus(event.status),
              onTap: () => _onMarkerTapped(event),
            );
          }).toSet();

          final Set<Circle> circles = {};
          if (_hasSearched && _currentPosition != null) {
            circles.add(
              Circle(
                circleId: const CircleId('fixed_search_range'),
                center: _currentPosition!,
                radius: _searchDistance * 1000,
                fillColor: Colors.blue.withOpacity(0.08),
                strokeColor: Colors.blue.withOpacity(0.2),
                strokeWidth: 2,
              ),
            );
          }

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
                    ).union(circles),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
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

              // ★ 修正: 共通コンポーネントを使用し、カスタム動作を渡す
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: UserControlPanel(
                  onClose: () => setState(() => _selectedEvent = null),
                  onSearch: _showSearchPanel,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color;
    switch (status) {
      case EventStatus.active:
        label = '営業中';
        color = Colors.green;
        break;
      case EventStatus.breakTime:
        label = '休憩中';
        color = Colors.orange;
        break;
      case EventStatus.finished:
        label = '終了';
        color = Colors.grey;
        break;
      default:
        label = '準備中';
        color = Colors.blue;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

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
                        child: const Icon(Icons.image),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          EventStatus.getLabel(event.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: event.status == EventStatus.active
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        const Text(
                          '詳細を見る >',
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 200,
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
                          _buildStatusBadge(event.status),
                          const SizedBox(height: 12),
                          Text(
                            event.eventName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildBusinessLinkWithFollow(event.adminId),
                          const SizedBox(height: 24),
                          _buildInfoRow(
                            Icons.access_time,
                            '日時',
                            event.eventTime,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 20, color: Colors.black54),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('場所', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                    Text(event.address, style: const TextStyle(fontSize: 15)),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openMapApp(event.latitude, event.longitude),
                                        icon: const Icon(Icons.directions, size: 18),
                                        label: const Text('ルート案内 (マップアプリ)'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade50,
                                          foregroundColor: Colors.blue.shade700,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 40),
                          const Text('詳細情報', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            event.description,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),

                          const SizedBox(height: 30),
                          const Divider(height: 40),
                          const Text('レビュー', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "まだレビューはありません",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewPostScreen(event: event),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.rate_review, size: 20),
                              label: const Text("レビューを書く"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade50,
                                foregroundColor: Colors.orange,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
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
      future: FirebaseFirestore.instance
          .collection('businesses')
          .doc(adminId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists)
          return const SizedBox.shrink();
        final business = BusinessUserModel.fromFirestore(snapshot.data!);
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessPublicProfileScreen(adminId: adminId),
            ),
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
                  backgroundImage: (business.iconImage?.isNotEmpty ?? false)
                      ? NetworkImage(business.iconImage!)
                      : null,
                  child: (business.iconImage?.isEmpty ?? true)
                      ? const Icon(Icons.store)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.adminName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'プロフィールを見る >',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<bool>(
                  stream: _firestoreService.isBusinessFollowedStream(adminId),
                  builder: (context, snapshot) {
                    final isFollowed = snapshot.data ?? false;
                    return ElevatedButton(
                      onPressed: () =>
                          _firestoreService.toggleFollowBusiness(adminId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowed
                            ? Colors.white
                            : Colors.orange,
                        foregroundColor: isFollowed
                            ? Colors.orange
                            : Colors.white,
                        side: const BorderSide(color: Colors.orange),
                        minimumSize: const Size(60, 32),
                      ),
                      child: Text(
                        isFollowed ? 'フォロー中' : 'フォロー',
                        style: const TextStyle(fontSize: 11),
                      ),
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
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(value, style: const TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    return null;
  }

  void _showSearchPanel() {
    String tempCategory = _searchCategory;
    double tempDistance = _searchDistance;
    DateTime? tempDate = _searchDate;
    final TextEditingController keywordController = TextEditingController(text: _searchKeyword);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPanelState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
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
                              tempDistance = 1.0;
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
                        if (date != null && mounted) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '距離範囲',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${tempDistance.toInt()} km 以内',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempDistance,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: '${tempDistance.toInt()} km',
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
}