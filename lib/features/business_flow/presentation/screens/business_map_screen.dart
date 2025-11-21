import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:geolocator/geolocator.dart';

class BusinessMapScreen extends StatefulWidget {
  const BusinessMapScreen({super.key});

  @override
  State<BusinessMapScreen> createState() => _BusinessMapScreenState();
}

class _BusinessMapScreenState extends State<BusinessMapScreen> {
  // --- マップ・UIの状態管理 ---
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Marker? _tappedMarker;
  LatLng? _tappedLatLng;

  // --- フォームの状態管理 ---
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _eventImageController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoadingSheet = false; // シート内の「OK」ボタン用
  bool _isLoadingLocation = false; // 「はじめる」ボタンの現在地取得用

  // --- 画面フローの状態管理 ---
  bool _isBottomSheetOpen = false;
  bool _isRegistrationSuccessful = false;

  // --- サービス ---
  final FirestoreService _firestoreService = FirestoreService();

  // --- マップ初期位置 ---
  static const CameraPosition _kTenjin = CameraPosition(
    target: LatLng(33.590354, 130.401719),
    zoom: 15.0,
  );

  @override
  void dispose() {
    _eventNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _eventImageController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ★ 1. 上部UIの推定高さを計算 (ステータスバー + ボタン)
    // (説明文がなくなるため高さを調整)
    final double topPadding = MediaQuery.of(context).padding.top + 70.0;
    // ★ 1. 下部UIの推定高さを計算 (ボタン + 注意書き + 余白)
    final double bottomPadding = 120.0; // 少し高さを増やす

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kTenjin,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },

            // ★ 1. UIが重なるため、地図の操作領域を調整
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),

            // ボトムシートが開いている間、地図の操作を無効化
            zoomGesturesEnabled: !_isBottomSheetOpen,
            scrollGesturesEnabled: !_isBottomSheetOpen,
            rotateGesturesEnabled: !_isBottomSheetOpen,
            tiltGesturesEnabled: !_isBottomSheetOpen,

            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: <Marker>{if (_tappedMarker != null) _tappedMarker!},
          ),

          // ★ 2. 下部のUI (ボタン + 注意書き)
          _buildConfirmButtonAndHint(),

          // ★ 3. 上部のUI (ボタンのみ)
          _buildTopOverlayUI(context),
        ],
      ),
    );
  }

  /// ★ 3. トップオーバーレイUI (説明文を削除)
  Widget _buildTopOverlayUI(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- 左：戻るボタン ---
            _buildCircleButton(
              context: context,
              icon: Icons.arrow_back,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // --- 右：ハンバーガーメニュー ---
            _buildCircleButton(
              context: context,
              icon: Icons.menu,
              onPressed: () {
                // TODO: ハンバーガーメニューが押されたときの動作
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('メニューボタンが押されました')));
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ★ 7. 丸いボタンのUIを生成するヘルパーメソッド
  Widget _buildCircleButton({
    // ... 既存コード ...
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      // ... 既存コード ...
      elevation: 4.0,
      shape: const CircleBorder(),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        // ... 既存コード ...
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }

  // (マップタップ時)
  void _onMapTapped(LatLng latLng) {
    // ... 既存コード ...
    if (_isBottomSheetOpen) {
      FocusScope.of(context).unfocus();
      return;
    }
    setState(() {
      // ... 既存コード ...
      _tappedLatLng = latLng;
      _tappedMarker = Marker(
        markerId: const MarkerId('tapped_location'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  /// ★ 2. 下部のUI (ボタン + 注意書き) に名前変更
  Widget _buildConfirmButtonAndHint() {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      // ★ 2. Columnで「注意書き」と「ボタン」を縦に並べる
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- 注意書き ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5), // 半透明の黒
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '場所をタップ、または「現在地ではじめる」',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8), // 注意書きとボタンの間隔
          // --- はじめるボタン ---
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              minimumSize: const Size(double.infinity, 50), // ボタンの幅を最大に
            ),
            onPressed: (_isLoadingLocation || _isBottomSheetOpen)
                ? null
                : _onStartNowPressed,
            child: _isLoadingLocation
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : Text(_tappedLatLng == null ? '現在地ではじめる' : 'ここ(選択した場所)ではじめる'),
          ),
        ],
      ),
    );
  }

  // (_onStartNowPressed, _showRegistrationSheet, _setEndTime, _parseTimeOfDay, _formatTimeOfDay, _submitEvent, _determinePosition は変更ありません)
  void _onStartNowPressed() async {
    // ... 既存コード ...
    setState(() {
      _isLoadingLocation = true;
    });

    LatLng? locationToRegister;
    // ... 既存コード ...
    if (_tappedLatLng != null) {
      locationToRegister = _tappedLatLng;
    } else {
      try {
        Position position = await _determinePosition();
        // ... 既存コード ...
        locationToRegister = LatLng(position.latitude, position.longitude);

        setState(() {
          _tappedLatLng = locationToRegister;
          // ... 既存コード ...
          _tappedMarker = Marker(
            markerId: const MarkerId('tapped_location'),
            position: locationToRegister!,
            // ... 既存コード ...
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          );
        });

        final GoogleMapController controller = await _controller.future;
        // ... 既存コード ...
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(locationToRegister, 16),
        );
      } catch (e) {
        // ... 既存コード ...
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // ... 既存コード ...
              content: Text('現在地を取得できませんでした: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    setState(() {
      // ... 既存コード ...
      _isLoadingLocation = false;
    });

    if (locationToRegister != null) {
      // ... 既存コード ...
      _showRegistrationSheet();
    }
  }

  void _showRegistrationSheet() async {
    // ... 既存コード ...
    setState(() {
      _isBottomSheetOpen = true;
      _isRegistrationSuccessful = false;
    });

    _eventNameController.clear();
    // ... 既存コード ...
    _endTimeController.clear();
    _eventImageController.clear();
    _addressController.clear();
    _descriptionController.clear();
    _isLoadingSheet = false;

    _startTimeController.text = _formatTimeOfDay(TimeOfDay.now());

    try {
      await showModalBottomSheet(
        // ... 既存コード ...
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        // ... 既存コード ...
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          // ... 既存コード ...
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                // ... 既存コード ...
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    // ... 既存コード ...
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // ... 既存コード ...
                        '出店登録',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      // ... 既存コード ...
                      const SizedBox(height: 8),
                      Text(
                        '${_tappedLatLng?.latitude.toStringAsFixed(5)}, ${_tappedLatLng?.longitude.toStringAsFixed(5)}',
                        // ... 既存コード ...
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        // ... 既存コード ...
                        controller: _eventNameController,
                        decoration: const InputDecoration(
                          labelText: 'イベント名 (必須)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        // ... 既存コード ...
                        children: [
                          Expanded(
                            child: TextField(
                              // ... 既存コード ...
                              controller: _startTimeController,
                              decoration: InputDecoration(
                                labelText: '開始時刻',
                                border: const OutlineInputBorder(),
                                // ... 既存コード ...
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.update),
                                  tooltip: '現在時刻にリセット',
                                  onPressed: () {
                                    // ... 既存コード ...
                                    setModalState(() {
                                      _startTimeController.text =
                                          _formatTimeOfDay(TimeOfDay.now());
                                    });
                                  },
                                ),
                              ),
                              readOnly: false,
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              // ... 既存コード ...
                              controller: _endTimeController,
                              decoration: const InputDecoration(
                                labelText: '終了時刻 (必須)',
                                hintText: '例: 17:00',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: false,
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Row(
                        // ... 既存コード ...
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            '終了時刻を簡単入力: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          OutlinedButton(
                            // ... 既存コード ...
                            onPressed: () => _setEndTime(setModalState, 1),
                            child: const Text('+1h'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton(
                            // ... 既存コード ...
                            onPressed: () => _setEndTime(setModalState, 2),
                            child: const Text('+2h'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton(
                            // ... 既存コード ...
                            onPressed: () => _setEndTime(setModalState, 3),
                            child: const Text('+3h'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        // ... 既存コード ...
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'イベント詳細（任意）',
                          hintText: 'セールの情報やメニューなど...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        // ... 既存コード ...
                        controller: _eventImageController,
                        decoration: const InputDecoration(
                          labelText: '画像',
                          hintText: '画像入れるところ',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        // ... 既存コード ...
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: '住所',
                          hintText: '開催場所を入力',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),

                      const SizedBox(height: 20),
                      ElevatedButton(
                        // ... 既存コード ...
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isLoadingSheet
                            ? null
                            : () => _submitEvent(setModalState),
                        child: _isLoadingSheet
                            ? const CircularProgressIndicator(
                                // ... 既存コード ...
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                            : const Text('OK (登録)'),
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
    } finally {
      // ... 既存コード ...
      setState(() {
        _isBottomSheetOpen = false;
        if (!_isRegistrationSuccessful) {
          // ... 既存コード ...
          _tappedMarker = null;
          _tappedLatLng = null;
        }
      });
    }
  }

  void _setEndTime(StateSetter setModalState, int hoursToAdd) {
    // ... 既存コード ...
    final TimeOfDay startTime = _parseTimeOfDay(_startTimeController.text);
    final TimeOfDay endTime = startTime.replacing(
      // ... 既存コード ...
      hour: (startTime.hour + hoursToAdd) % 24,
    );
    setModalState(() {
      // ... 既存コード ...
      _endTimeController.text = _formatTimeOfDay(endTime);
    });
    FocusScope.of(context).unfocus();
  }

  TimeOfDay _parseTimeOfDay(String formattedTime) {
    // ... 既存コード ...
    try {
      final parts = formattedTime.split(':');
      if (parts.length == 2) {
        // ... 既存コード ...
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null &&
            minute != null &&
            hour >= 0 &&
            hour <= 23 &&
            minute >= 0 &&
            minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // ... 既存コード ...
    }
    return TimeOfDay.now();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    // ... 既存コード ...
    final String minute = time.minute.toString().padLeft(2, '0');
    final String hour = time.hour.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _submitEvent(StateSetter setModalState) async {
    // ... 既存コード ...
    final eventName = _eventNameController.text;
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;
    final eventImage = _eventImageController.text;
    final address = _addressController.text;
    final description = _descriptionController.text;

    if (eventName.isEmpty ||
        // ... 既存コード ...
        startTime.isEmpty ||
        endTime.isEmpty ||
        _tappedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        // ... 既存コード ...
        const SnackBar(
          content: Text('すべての必須項目を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setModalState(() {
      // ... 既存コード ...
      _isLoadingSheet = true;
    });

    try {
      // ... 既存コード ...
      final eventTime = '$startTime - $endTime';

      await _firestoreService.addEvent(
        // ... 既存コード ...
        eventName: eventName,
        eventTime: eventTime,
        eventImage: eventImage,
        location: _tappedLatLng!,
        address: address,
        description: description,
      );

      _isRegistrationSuccessful = true;
      // ... 既存コード ...
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        // ... 既存コード ...
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('イベントを登録しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // ... 既存コード ...
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // ... 既存コード ...
      if (mounted) {
        setModalState(() {
          _isLoadingSheet = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    // ... 既存コード ...
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // ... 既存コード ...
    if (!serviceEnabled) {
      return Future.error('ロケーションサービスが無効です。');
    }

    permission = await Geolocator.checkPermission();
    // ... 既存コード ...
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // ... 既存コード ...
        return Future.error('ロケーションの権限が拒否されました。');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // ... 既存コード ...
      return Future.error('ロケーションの権限が永久に拒否されています。設定から変更してください。');
    }

    return await Geolocator.getCurrentPosition(
      // ... 既存コード ...
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
