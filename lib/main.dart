import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
  
  // 初期位置（東京）
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

  // 位置情報の権限チェック
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('位置情報サービスが無効です。設定から有効にしてください。');
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
      _showSnackBar('位置情報の権限が永久に拒否されています。設定から許可してください。');
      return false;
    }

    return true;
  }

  // 現在地を取得
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // 現在地にカメラを移動
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );

      _showSnackBar('現在地を取得しました');
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showSnackBar('現在地の取得に失敗しました: $e');
    }
  }

  // 現在地にピンを設置
  void _addMarkerAtCurrentLocation() {
    if (_currentPosition == null) {
      _showSnackBar('先に現在地を取得してください');
      return;
    }

    _addMarker(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
    _showSnackBar('現在地にピンを設置しました');
  }

  void _addMarker(LatLng position) {
    final String markerId = 'marker_$_markerIdCounter';
    _markerIdCounter++;

    final Marker marker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(
        title: 'ピン $_markerIdCounter',
        snippet: '緯度: ${position.latitude.toStringAsFixed(4)}, 経度: ${position.longitude.toStringAsFixed(4)}',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    

    // モバイル・デスクトップの場合は通常の地図表示
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps ピン設置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearMarkers,
            tooltip: 'すべてのピンを削除',
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _initialPosition,
        markers: _markers,
        onTap: _addMarker,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'current_location',
            onPressed: _isLoadingLocation ? null : _getCurrentLocation,
            backgroundColor: _isLoadingLocation ? Colors.grey : Colors.blue,
            child: _isLoadingLocation
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.my_location),
            tooltip: '現在地を取得',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_marker_here',
            onPressed: _addMarkerAtCurrentLocation,
            backgroundColor: Colors.green,
            child: const Icon(Icons.add_location),
            tooltip: '現在地にピンを設置',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'zoom_in',
            onPressed: () {
              _mapController.animateCamera(CameraUpdate.zoomIn());
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'zoom_out',
            onPressed: () {
              _mapController.animateCamera(CameraUpdate.zoomOut());
            },
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'marker_count',
            onPressed: null,
            label: Text('ピン: ${_markers.length}'),
            icon: const Icon(Icons.location_on),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            child: Text(number, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}