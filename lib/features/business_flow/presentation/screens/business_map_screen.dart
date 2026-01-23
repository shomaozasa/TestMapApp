import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/service/storage_service.dart';
import 'package:google_map_app/core/models/template_model.dart';

class BusinessMapScreen extends StatefulWidget {
  final DateTime? initialDate;

  const BusinessMapScreen({super.key, this.initialDate});

  @override
  State<BusinessMapScreen> createState() => _BusinessMapScreenState();
}

class _BusinessMapScreenState extends State<BusinessMapScreen> {
  final String _testAdminId = 'test_user_id';
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // ★ 予備の初期位置（天神）
  static const LatLng _kFallbackLocation = LatLng(33.590354, 130.401719);

  // ★ 現在地保持用（最初はnull）
  LatLng? _currentPosition;

  Marker? _tappedMarker;
  LatLng? _tappedLatLng;

  // コントローラー
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final List<String> _categories = ['Food', 'Music', 'Shop', 'Art', 'Other'];
  String _selectedCategory = 'Food';

  // 画像関連
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  String? _templateImageUrl;

  final ImagePicker _picker = ImagePicker();

  // フラグ
  bool _isLoadingSheet = false;
  bool _isLoadingLocation = false;
  bool _isBottomSheetOpen = false;
  bool _isRegistrationSuccessful = false;
  bool _isTimeUndecided = false;

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // ★ 起動時に現在地取得を開始
    _initializeLocation();
  }

  /// ★ 位置情報の初期化とカメラ移動
  Future<void> _initializeLocation() async {
    try {
      Position position = await _determinePosition();
      final newLatLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = newLatLng;
        });
      }

      // マップコントローラーが準備できたらカメラを移動
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 15.0));
    } catch (e) {
      debugPrint('初期位置取得エラー: $e');
      // 失敗した場合は initialCameraPosition の fallback (天神) が使われる
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
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
            // ★ 現在地があればそこを、なければ天神を初期位置にする
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? _kFallbackLocation,
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            zoomGesturesEnabled: !_isBottomSheetOpen,
            scrollGesturesEnabled: !_isBottomSheetOpen,
            rotateGesturesEnabled: !_isBottomSheetOpen,
            tiltGesturesEnabled: !_isBottomSheetOpen,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: true, // 標準ボタンを表示（paddingでずらして調整）
            markers: <Marker>{if (_tappedMarker != null) _tappedMarker!},
          ),
          _buildConfirmButtonAndHint(),
          _buildTopOverlayUI(context),
        ],
      ),
    );
  }

  // --- UIパーツ ---

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
              onPressed: () => Navigator.of(context).pop(),
            ),
            _buildCircleButton(
              context: context,
              icon: Icons.menu,
              onPressed: () {},
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
    setState(() => _isLoadingLocation = true);
    LatLng? locationToRegister;

    if (_tappedLatLng != null) {
      locationToRegister = _tappedLatLng;
    } else {
      try {
        Position position = await _determinePosition();
        locationToRegister = LatLng(position.latitude, position.longitude);
        setState(() {
          _tappedLatLng = locationToRegister;
          _tappedMarker = Marker(
            markerId: const MarkerId('tapped_location'),
            position: locationToRegister!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          );
        });
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(locationToRegister, 16),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('現在地を取得できませんでした: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    setState(() => _isLoadingLocation = false);
    if (locationToRegister != null) {
      _showRegistrationSheet();
    }
  }

  // --- 登録シート表示ロジック ---
  void _showRegistrationSheet() async {
    setState(() {
      _isBottomSheetOpen = true;
      _isRegistrationSuccessful = false;
    });

    // フォームリセット
    _eventNameController.clear();
    _descriptionController.clear();
    _addressController.text = "";
    _pickedImage = null;
    _imageBytes = null;
    _templateImageUrl = null;
    _selectedCategory = _categories.first;
    _isLoadingSheet = false;

    final DateTime targetDate = widget.initialDate ?? DateTime.now();
    _dateController.text = _formatDate(targetDate);
    _isTimeUndecided = false;

    if (widget.initialDate != null) {
      _startTimeController.text = "12:00";
      _endTimeController.text = "13:00";
    } else {
      _startTimeController.text = _formatTimeOfDay(TimeOfDay.now());
      _endTimeController.clear();
    }

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '出店登録',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                _showTemplateSelector(setModalState),
                            icon: const Icon(Icons.note_add_outlined, size: 18),
                            label: const Text("テンプレ読込"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 画像エリア
                      Center(
                        child: InkWell(
                          onTap: () async {
                            final XFile? image = await _picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 70,
                            );
                            if (image != null) {
                              final Uint8List bytes = await image.readAsBytes();
                              setModalState(() {
                                _pickedImage = image;
                                _imageBytes = bytes;
                              });
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                              image: _imageBytes != null
                                  ? DecorationImage(
                                      image: MemoryImage(_imageBytes!),
                                      fit: BoxFit.cover,
                                    )
                                  : (_templateImageUrl != null &&
                                        _templateImageUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(_templateImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                (_imageBytes == null &&
                                    (_templateImageUrl == null ||
                                        _templateImageUrl!.isEmpty))
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'イベント画像を追加',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (_imageBytes != null ||
                          (_templateImageUrl != null &&
                              _templateImageUrl!.isNotEmpty))
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setModalState(() {
                                _pickedImage = null;
                                _imageBytes = null;
                                _templateImageUrl = null;
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text(
                              '画像を削除',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      TextField(
                        controller: _eventNameController,
                        decoration: const InputDecoration(
                          labelText: 'イベント名 (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'カテゴリ (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setModalState(() => _selectedCategory = v!),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: '開催日 (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime initD = widget.initialDate ?? DateTime.now();
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initD,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            locale: const Locale('ja'),
                          );
                          if (picked != null) {
                            setModalState(
                              () => _dateController.text = _formatDate(picked),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      CheckboxListTile(
                        title: const Text(
                          "時間は未定",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _isTimeUndecided,
                        onChanged: (v) =>
                            setModalState(() => _isTimeUndecided = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(height: 8),

                      Opacity(
                        opacity: _isTimeUndecided ? 0.5 : 1.0,
                        child: IgnorePointer(
                          ignoring: _isTimeUndecided,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _startTimeController,
                                  decoration: InputDecoration(
                                    labelText: '開始時刻',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.update),
                                      onPressed: () => setModalState(
                                        () => _startTimeController.text =
                                            _formatTimeOfDay(TimeOfDay.now()),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _endTimeController,
                                  decoration: const InputDecoration(
                                    labelText: '終了時刻',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: '場所・住所 (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'イベント詳細（任意）',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
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
                                color: Colors.white,
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

  void _showTemplateSelector(StateSetter setModalState) {
    final String targetAdminId = _testAdminId;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "テンプレートを選択",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<TemplateModel>>(
                  stream: _firestoreService.getTemplatesStream(targetAdminId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    final templates = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return ListTile(
                          title: Text(
                            template.templateName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(template.eventName),
                          onTap: () {
                            setModalState(() {
                              _eventNameController.text = template.eventName;
                              _descriptionController.text =
                                  template.description;
                              if (_categories.contains(template.categoryId))
                                _selectedCategory = template.categoryId;
                              _templateImageUrl = template.imagePath;
                              _pickedImage = null;
                              _imageBytes = null;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _submitEvent(StateSetter setModalState) async {
    final eventName = _eventNameController.text;
    final dateStr = _dateController.text;
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;
    final address = _addressController.text;

    if (eventName.isEmpty ||
        address.isEmpty ||
        _tappedLatLng == null ||
        dateStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('必須項目を入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setModalState(() => _isLoadingSheet = true);

    try {
      String imageUrl = "";
      if (_pickedImage != null) {
        imageUrl = await _storageService.uploadImage(
          _pickedImage!,
          'event_images',
        );
      } else if (_templateImageUrl != null) {
        imageUrl = _templateImageUrl!;
      }

      String eventTimeDisplay = _isTimeUndecided
          ? "$dateStr (時間未定)"
          : "$dateStr $startTime - $endTime";

      await _firestoreService.addEvent(
        eventName: eventName,
        eventTime: eventTimeDisplay,
        location: _tappedLatLng!,
        description: _descriptionController.text,
        adminId: _testAdminId,
        categoryId: _selectedCategory,
        address: address,
        eventImage: imageUrl,
      );

      _isRegistrationSuccessful = true;
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録失敗: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setModalState(() => _isLoadingSheet = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('ロケーションサービスが無効です。');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('権限が拒否されました。');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}
