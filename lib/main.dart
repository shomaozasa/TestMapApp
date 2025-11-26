import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_app/core/features/user_flow/custom_bottom_bar.dart';
import 'package:google_map_app/core/features/user_flow/user_profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps デモ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(35.6812, 139.7671),
    zoom: 12,
  );

  int _markerIdCounter = 0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _getCurrentLocation();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('位置情報サービスが無効です。');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('位置情報の権限が拒否されました。');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('位置情報の権限が永久に拒否されています。');
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      _showSnackBar('現在地の取得に失敗しました');
    }
  }

  void _addMarker(LatLng position) {
    final String markerId = 'marker_$_markerIdCounter';
    _markerIdCounter++;

    final Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _clearMarkers() {
    setState(() {
      _markers.clear();
      _markerIdCounter = 0;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        onTap: _addMarker,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
      ),
      bottomNavigationBar: CustomBottomBar(
        onMapTap: () {
          // 現在はマップ画面なので何もしない
        },
      ),
    );
  }
}
