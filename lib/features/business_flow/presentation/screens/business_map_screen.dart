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
import 'package:google_map_app/core/models/event_model.dart';
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

  static const LatLng _kFallbackLocation = LatLng(33.590354, 130.401719);
  LatLng? _currentPosition;

  Marker? _tappedMarker;
  LatLng? _tappedLatLng;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  final List<String> _categories = ['Food', 'Music', 'Shop', 'Art', 'Other'];
  String _selectedCategory = 'Food';

  XFile? _pickedImage;
  Uint8List? _imageBytes;
  String? _templateImageUrl;

  final ImagePicker _picker = ImagePicker();

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
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      Position position = await _determinePosition();
      final newLatLng = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _currentPosition = newLatLng);
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 15.0));
    } catch (e) {
      debugPrint('初期位置取得エラー: $e');
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

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
    StateSetter setModalState,
  ) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null) {
      setModalState(() => controller.text = _formatTimeOfDay(picked));
    }
  }

  void _addHoursToEndTime(int hours, StateSetter setModalState) {
    if (_startTimeController.text.isEmpty) return;
    try {
      final parts = _startTimeController.text.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      int newHour = (hour + hours) % 24;
      setModalState(
        () => _endTimeController.text =
            '${newHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('時刻計算エラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 70.0;
    const double bottomPadding = 120.0;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? _kFallbackLocation,
              zoom: 15.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: <Marker>{if (_tappedMarker != null) _tappedMarker!},
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '場所をタップ、または「現在地ではじめる」',
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
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: (_isLoadingLocation || _isBottomSheetOpen)
                ? null
                : _onStartNowPressed,
            child: _isLoadingLocation
                ? const CircularProgressIndicator(color: Colors.white)
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('現在地取得失敗: $e'), backgroundColor: Colors.red),
          );
      }
    }
    setState(() => _isLoadingLocation = false);
    if (locationToRegister != null) _showRegistrationSheet();
  }

  void _showRegistrationSheet() async {
    setState(() {
      _isBottomSheetOpen = true;
      _isRegistrationSuccessful = false;
    });

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
                                            _templateImageUrl!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              _templateImageUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
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
                                        '画像を追加',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  )
                                : null,
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
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: '開催日 (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: targetDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            locale: const Locale('ja'),
                          );
                          if (picked != null)
                            setModalState(
                              () => _dateController.text = _formatDate(picked),
                            );
                        },
                      ),
                      CheckboxListTile(
                        title: const Text(
                          "時間は未定",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _isTimeUndecided,
                        // ★ ここを setModalState に修正しました
                        onChanged: (v) =>
                            setModalState(() => _isTimeUndecided = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      Opacity(
                        opacity: _isTimeUndecided ? 0.5 : 1.0,
                        child: IgnorePointer(
                          ignoring: _isTimeUndecided,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _startTimeController,
                                      readOnly: true,
                                      onTap: () => _selectTime(
                                        context,
                                        _startTimeController,
                                        setModalState,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: '開始時刻',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.access_time),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _endTimeController,
                                      readOnly: true,
                                      onTap: () => _selectTime(
                                        context,
                                        _endTimeController,
                                        setModalState,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: '終了時刻',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(
                                          Icons.access_time_filled,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    "クイック終了設定: ",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  _quickTimeBtn("+1h", 1, setModalState),
                                  const SizedBox(width: 6),
                                  _quickTimeBtn("+2h", 2, setModalState),
                                  const SizedBox(width: 6),
                                  _quickTimeBtn("+3h", 3, setModalState),
                                ],
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
                          labelText: '詳細（任意）',
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

  Widget _quickTimeBtn(String label, int h, StateSetter setModalState) {
    return InkWell(
      onTap: () => _addHoursToEndTime(h, setModalState),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.orange.shade800,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showTemplateSelector(StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
                stream: _firestoreService.getTemplatesStream(_testAdminId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final templates = snapshot.data!;
                  return ListView.builder(
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final t = templates[index];
                      return ListTile(
                        title: Text(
                          t.templateName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(t.eventName),
                        onTap: () {
                          setModalState(() {
                            _eventNameController.text = t.eventName;
                            _descriptionController.text = t.description;
                            if (_categories.contains(t.categoryId))
                              _selectedCategory = t.categoryId;
                            _templateImageUrl = t.imagePath;
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
      ),
    );
  }

  void _submitEvent(StateSetter setModalState) async {
    if (_eventNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _tappedLatLng == null) {
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
      String imageUrl = _templateImageUrl ?? "";
      if (_pickedImage != null)
        imageUrl = await _storageService.uploadImage(
          _pickedImage!,
          'event_images',
        );
      String timeStr = _isTimeUndecided
          ? "${_dateController.text} (未定)"
          : "${_dateController.text} ${_startTimeController.text} - ${_endTimeController.text}";
      await _firestoreService.addEvent(
        eventName: _eventNameController.text,
        eventTime: timeStr,
        location: _tappedLatLng!,
        description: _descriptionController.text,
        adminId: _testAdminId,
        categoryId: _selectedCategory,
        address: _addressController.text,
        eventImage: imageUrl,
      );
      _isRegistrationSuccessful = true;
      if (mounted) Navigator.pop(context);
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('ロケーションサービス無効');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('権限拒否');
    }
    return await Geolocator.getCurrentPosition();
  }
}
