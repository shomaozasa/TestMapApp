// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';

// import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';
// import 'package:google_map_app/map_user.dart'; // EventDetailScreen

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Google Maps Demo',
//       theme: ThemeData(
//         scaffoldBackgroundColor: Colors.white,
//         useMaterial3: true,
//       ),
//       home: const MapScreen(),
//     );
//   }
// }

// class MapScreen extends StatefulWidget {
//   const MapScreen({Key? key}) : super(key: key);

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   late GoogleMapController _mapController;
//   final Set<Marker> _markers = {};
//   Position? _currentPosition;
//   bool _isLoadingLocation = false;

//   static const CameraPosition _initialPosition = CameraPosition(
//     target: LatLng(35.6812, 139.7671),
//     zoom: 14,
//   );

//   int _markerIdCounter = 0;

//   @override
//   void initState() {
//     super.initState();
//     if (!kIsWeb) {
//       _getCurrentLocation();
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _mapController = controller;
//   }

//   Future<bool> _handleLocationPermission() async {
//     if (!await Geolocator.isLocationServiceEnabled()) {
//       _showSnackBar('位置情報サービスが無効です');
//       return false;
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _showSnackBar('位置情報の権限が拒否されました');
//         return false;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       _showSnackBar('位置情報の権限が永久に拒否されています');
//       return false;
//     }

//     return true;
//   }

//   Future<void> _getCurrentLocation() async {
//     setState(() => _isLoadingLocation = true);

//     try {
//       final hasPermission = await _handleLocationPermission();
//       if (!hasPermission) return;

//       final position = await Geolocator.getCurrentPosition();
//       _currentPosition = position;

//       _mapController.animateCamera(
//         CameraUpdate.newCameraPosition(
//           CameraPosition(
//             target: LatLng(position.latitude, position.longitude),
//             zoom: 15,
//           ),
//         ),
//       );
//     } catch (_) {
//       _showSnackBar('現在地の取得に失敗しました');
//     } finally {
//       setState(() => _isLoadingLocation = false);
//     }
//   }

//   void _addMarker(LatLng position) {
//     final markerId = MarkerId('marker_${_markerIdCounter++}');
//     setState(() {
//       _markers.add(
//         Marker(
//           markerId: markerId,
//           position: position,
//         ),
//       );
//     });
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           /// Google Map
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: _initialPosition,
//             markers: _markers,
//             onTap: _addMarker,
//             myLocationEnabled: true,
//             myLocationButtonEnabled: false,
//           ),

//           /// 🔍 検索バー（上部）
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Container(
//                 height: 48,
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: const [
//                     BoxShadow(color: Colors.black26, blurRadius: 6),
//                   ],
//                 ),
//                 child: const Row(
//                   children: [
//                     SizedBox(width: 16),
//                     Icon(Icons.search),
//                     SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         'イベント・店舗を検索',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     ),
//                     Padding(
//                       padding: EdgeInsets.only(right: 16),
//                       child: Icon(Icons.tune),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),

//           /// 🟦 白カード（スワイプ対応）
//           Positioned(
//             left: 0,
//             right: 0,
//             bottom: 90,
//             height: 130,
//             child: PageView.builder(
//               controller: PageController(viewportFraction: 0.9),
//               itemCount: 3,
//               itemBuilder: (context, index) {
//                 return GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => const EventDetailScreen(),
//                       ),
//                     );
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 8),
//                     child: Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: const [
//                           BoxShadow(color: Colors.black26, blurRadius: 8),
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           Container(
//                             width: 64,
//                             height: 64,
//                             decoration: BoxDecoration(
//                               color: Colors.orange[100],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Center(
//                               child: Text(
//                                 "🕒\nタイムセール",
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(fontSize: 11),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           const Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "今だけ！の極旨クレープ販売",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   "現在地から 40m",
//                                   style: TextStyle(color: Colors.grey),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),

//       /// ⬇ BottomBar
//       bottomNavigationBar: CustomBottomBar(
//         onMapTap: () {},
//       ),
//     );
//   }
// }
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_app/map_user.dart';

import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';

/// =======================
/// アプリ起点
/// =======================
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  final List<MapEvent> _events = [
    MapEvent(
      id: '1',
      title: '今だけ！の極旨クレープ販売',
      category: '飲食',
      distance: 40,
      position: const LatLng(35.6812, 139.7671),
    ),
  ];

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(35.6812, 139.7671),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🗺 GoogleMap
          GoogleMap(
            onMapCreated: (c) => _mapController = c,
            initialCameraPosition: _initialPosition,
            markers: _events
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

          /// 🟦 下のイベントカード
          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            height: 140,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final e = _events[index];
                return GestureDetector(
                  onTap: () {
                    _showEventDetailSheet(context);
                  },
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
            child: Center(
              child: Text(e.category),
            ),
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

  /// =======================
  /// イベント詳細 BottomSheet
  /// =======================
void _showEventDetailSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: EventDetailScreen(
              scrollController: controller,
            ),
          );
        },
      );
    },
  );
}
}

// /// =======================
// /// イベント詳細（Sheet用）
// /// =======================
// class EventDetailSheet extends StatelessWidget {
//   final ScrollController scrollController;

//   const EventDetailSheet({
//     super.key,
//     required this.scrollController,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CustomScrollView(
//       controller: scrollController,
//       slivers: [
//         /// スワイプバー
//         SliverToBoxAdapter(
//           child: Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(top: 12, bottom: 12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[400],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//         ),

//         /// 写真
//         SliverAppBar(
//           automaticallyImplyLeading: false,
//           expandedHeight: 240,
//           pinned: true,
//           backgroundColor: Colors.lightBlue,
//           flexibleSpace: FlexibleSpaceBar(
//             background: Image.network(
//               'https://via.placeholder.com/400x300',
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),

//         /// 内容
//         SliverToBoxAdapter(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   '今だけ！の極旨クレープ販売',
//                   style: TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Text('📍 天神イムズ前（40m）'),
//                 const SizedBox(height: 16),
//                 const Text(
//                   '焼きたてクレープを提供しています。\n'
//                   'チョコバナナが一番人気です！',
//                   style: TextStyle(height: 1.5),
//                 ),
//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
