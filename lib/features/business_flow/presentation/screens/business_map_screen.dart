import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:geolocator/geolocator.dart';
// geocoding パッケージは削除

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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // カテゴリ選択用
  final List<String> _categories = ['Food', 'Music', 'Shop', 'Art', 'Other'];
  String _selectedCategory = 'Food'; 

  bool _isLoadingSheet = false; 
  bool _isLoadingLocation = false; 

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
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 70.0;
    final double bottomPadding = 120.0;

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
            padding: EdgeInsets.only(
              top: topPadding,
              bottom: bottomPadding,
            ),
            zoomGesturesEnabled: !_isBottomSheetOpen,
            scrollGesturesEnabled: !_isBottomSheetOpen,
            rotateGesturesEnabled: !_isBottomSheetOpen,
            tiltGesturesEnabled: !_isBottomSheetOpen,
            onTap: _onMapTapped,
            myLocationEnabled: true, 
            myLocationButtonEnabled: false, 
            markers: <Marker>{
              if (_tappedMarker != null) _tappedMarker!,
            },
          ),
          _buildConfirmButtonAndHint(),
          _buildTopOverlayUI(context),
        ],
      ),
    );
  }

  Widget _buildTopOverlayUI(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCircleButton(
              context: context,
              icon: Icons.arrow_back,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            _buildCircleButton(
              context: context,
              icon: Icons.menu,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('メニューボタンが押されました')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 4.0, 
      shape: const CircleBorder(), 
      color: Colors.white, 
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        icon: Icon(icon, color: Colors.black87),
        onPressed: onPressed,
      ),
    );
  }

  void _onMapTapped(LatLng latLng) {
    if (_isBottomSheetOpen) {
      FocusScope.of(context).unfocus(); 
      return;
    }
    setState(() {
      _tappedLatLng = latLng;
      _tappedMarker = Marker(
        markerId: const MarkerId('tapped_location'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
    // ★ 住所自動取得はなし (必要ならここで手動入力用のダイアログを出すなどのUXも考えられるが、今回はフォームで入力させる)
  }

  Widget _buildConfirmButtonAndHint() {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
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
          const SizedBox(height: 8),
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
              minimumSize: const Size(double.infinity, 50),
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
  
  void _onStartNowPressed() async {
    setState(() {
      _isLoadingLocation = true;
    });

    LatLng? locationToRegister;
    if (_tappedLatLng != null) {
      locationToRegister = _tappedLatLng;
    } 
    else {
      try {
        Position position = await _determinePosition();
        locationToRegister = LatLng(position.latitude, position.longitude);

        setState(() {
          _tappedLatLng = locationToRegister;
          _tappedMarker = Marker(
            markerId: const MarkerId('tapped_location'),
            position: locationToRegister!,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          );
        });
        
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(locationToRegister, 16));
        
      } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('現在地を取得できませんでした: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    setState(() {
      _isLoadingLocation = false;
    });

    if (locationToRegister != null) {
      _showRegistrationSheet();
    }
  }


  void _showRegistrationSheet() async {
    setState(() {
      _isBottomSheetOpen = true;
      _isRegistrationSuccessful = false;
    });

    _eventNameController.clear();
    _endTimeController.clear(); 
    _descriptionController.clear();
    // 住所欄は手入力用にクリア、もしくはデフォルト値を入れる
    _addressController.text = ""; 
    
    _selectedCategory = _categories.first;
    _isLoadingSheet = false; 
    _startTimeController.text = _formatTimeOfDay(TimeOfDay.now());

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 24,
                  right: 24,
                  top: 24,
                ),
                child: SingleChildScrollView( 
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '出店登録',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // --- 画像選択 (ダミーUI) ---
                      Center(
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('画像選択は未実装です')),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('イベント画像を追加', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- イベント名 ---
                      TextField(
                        controller: _eventNameController,
                        decoration: const InputDecoration(
                          labelText: 'イベント名 (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- カテゴリ選択 ---
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'カテゴリ (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setModalState(() {
                            _selectedCategory = newValue!;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // --- 住所入力 (手入力) ---
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: '場所・住所 (必須)',
                          hintText: '例: 天神中央公園',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // --- 時間入力 ---
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startTimeController, 
                              decoration: InputDecoration(
                                labelText: '開始時刻',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.update),
                                  tooltip: '現在時刻にリセット',
                                  onPressed: () {
                                    setModalState(() {
                                      _startTimeController.text = _formatTimeOfDay(TimeOfDay.now());
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

                      // --- 終了時刻アシスト ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('終了時刻を簡単入力: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          OutlinedButton(
                            onPressed: () => _setEndTime(setModalState, 1),
                            child: const Text('+1h'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton(
                            onPressed: () => _setEndTime(setModalState, 2),
                            child: const Text('+2h'),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton(
                            onPressed: () => _setEndTime(setModalState, 3),
                            child: const Text('+3h'),
                             style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),

                      // --- 詳細説明 ---
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'イベント詳細（任意）',
                          hintText: 'セールの情報やメニューなど...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3, 
                        keyboardType: TextInputType.multiline,
                      ),
                      
                      const SizedBox(height: 20),
                      ElevatedButton(
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
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
      setState(() {
        _isBottomSheetOpen = false;
        if (!_isRegistrationSuccessful) {
          _tappedMarker = null;
          _tappedLatLng = null;
        }
      });
    }
  }

  void _setEndTime(StateSetter setModalState, int hoursToAdd) {
    final TimeOfDay startTime = _parseTimeOfDay(_startTimeController.text);
    final TimeOfDay endTime = startTime.replacing(
      hour: (startTime.hour + hoursToAdd) % 24
    );
    setModalState(() {
      _endTimeController.text = _formatTimeOfDay(endTime);
    });
    FocusScope.of(context).unfocus();
  }

  TimeOfDay _parseTimeOfDay(String formattedTime) {
    try {
      final parts = formattedTime.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null && hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
    }
    return TimeOfDay.now(); 
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final String minute = time.minute.toString().padLeft(2, '0');
    final String hour = time.hour.toString().padLeft(2, '0'); 
    return '$hour:$minute';
  }

  void _submitEvent(StateSetter setModalState) async {
    final eventName = _eventNameController.text;
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text; 
    final description = _descriptionController.text;
    final address = _addressController.text;
    final category = _selectedCategory;

    if (eventName.isEmpty ||
        startTime.isEmpty ||
        endTime.isEmpty ||
        address.isEmpty || 
        _tappedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('すべての必須項目を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setModalState(() {
      _isLoadingSheet = true;
    });

    try {
      final eventTime = '$startTime - $endTime'; 

      await _firestoreService.addEvent(
        eventName: eventName,
        eventTime: eventTime,
        location: _tappedLatLng!,
        description: description,
        adminId: "dummy_admin_id", 
        categoryId: category, 
        address: address, 
        eventImage: "", // ダミー画像URL
      );

      _isRegistrationSuccessful = true;
      if (mounted) Navigator.of(context).pop(); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('イベントを登録しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('登録に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setModalState(() {
          _isLoadingSheet = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('ロケーションサービスが無効です。');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission(); 
      if (permission == LocationPermission.denied) {
        return Future.error('ロケーションの権限が拒否されました。');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('ロケーションの権限が永久に拒否されています。設定から変更してください。');
    } 

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, 
    );
  }
}