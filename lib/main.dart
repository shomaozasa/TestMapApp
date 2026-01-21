import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_app/event.dart';
import 'package:google_map_app/core/features/user_flow/user_profile_page.dart';
import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapScreen(),
    );
  }
}

/// =======================
/// イベントモデル
/// =======================
class MapEvent {
  final String id;
  final String title;
  final String category;
  final double distance;
  final LatLng position;

  MapEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.distance,
    required this.position,
  });
}

/// =======================
/// Map画面
/// =======================
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['すべて', '飲食', '物販', 'イベント'];
  String _selectedCategory = 'すべて';

  final List<MapEvent> _events = [
    MapEvent(
      id: '1',
      title: '今だけ！の極旨クレープ販売',
      category: '飲食',
      distance: 40,
      position: const LatLng(35.6812, 139.7671),
    ),
  ];

  late List<MapEvent> _filteredEvents;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(35.6812, 139.7671),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _filteredEvents = List.from(_events);

    if (!kIsWeb) {
      _moveToCurrentLocation();
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(pos.latitude, pos.longitude),
        ),
      );
    } catch (_) {}
  }

  /// 🔍 検索＋カテゴリ絞り込み
  void _applyFilter() {
    setState(() {
      _filteredEvents = _events.where((e) {
        final keywordMatch =
            e.title.contains(_searchController.text);
        final categoryMatch =
            _selectedCategory == 'すべて' ||
                e.category == _selectedCategory;
        return keywordMatch && categoryMatch;
      }).toList();
    });
  }

  /// ⚙ 絞り込みBottomSheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'カテゴリで絞り込み',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  return ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                        _applyFilter();
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// 👤 プロフィール画面へ
  void _goToUserProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserProfilePage(),
      ),
    );
  }

  /// 📍 イベント詳細（UI改善版）
  void _showEventDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 1.0,
          expand: false,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28), // ← 角丸強化
                ),
              ),
              child: Column(
                children: [
                  /// 🔽 スワイプできることを示すバー
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  /// 📄 中身
                  Expanded(
                    child: EventDetailScreen(
                      scrollController: controller,
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🗺 Map
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: _initialPosition,
            markers: _filteredEvents
                .map(
                  (e) => Marker(
                    markerId: MarkerId(e.id),
                    position: e.position,
                  ),
                )
                .toSet(),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          /// 🔍 検索＋絞り込み
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _applyFilter(),
                      decoration: const InputDecoration(
                        hintText: 'イベントを検索',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.tune),
                    onPressed: _showFilterSheet,
                  ),
                ],
              ),
            ),
          ),

          /// 🟦 イベントカード
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            height: 140,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: _filteredEvents.length,
              itemBuilder: (context, index) {
                final e = _filteredEvents[index];
                return GestureDetector(
                  onTap: () => _showEventDetailSheet(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _eventCard(e),
                  ),
                );
              },
            ),
          ),

          /// ⬇ BottomBar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomBar(
              onMapTap: _moveToCurrentLocation,
              onProfileTap: () => _goToUserProfile(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(MapEvent e) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text(e.category)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '現在地から ${e.distance}m',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
