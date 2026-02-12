import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
// 住所取得用パッケージ
import 'package:geocoding/geocoding.dart';

import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/service/storage_service.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/models/template_model.dart';
import 'package:google_map_app/core/constants/event_status.dart';
import 'package:google_map_app/core/utils/map_utils.dart';
import 'package:google_map_app/features/user_flow/presentation/widgets/map_circle_helper.dart';

class BusinessMapScreen extends StatefulWidget {
  final DateTime? initialDate;

  const BusinessMapScreen({super.key, this.initialDate});

  @override
  State<BusinessMapScreen> createState() => _BusinessMapScreenState();
}

class _BusinessMapScreenState extends State<BusinessMapScreen>
    with TickerProviderStateMixin {
  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const LatLng _kFallbackLocation = LatLng(33.590354, 130.401719);
  LatLng? _currentPosition;

  Marker? _newRegistrationMarker;
  LatLng? _tappedLatLng;

  // コントローラー類
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

  // 通知・自動処理制御用セット
  final Set<String> _notifiedStartIds = {};
  final Set<String> _notifiedEndIds = {};
  final Set<String> _autoFinishedIds = {};

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  late Stream<List<EventModel>> _myEventsStream;
  late AnimationController _sonarController;

  // 定期チェック用タイマー
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _myEventsStream = _firestoreService.getFutureEventsStream(_currentUserId);

    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // 1分ごとにイベントの状態をチェック
    _statusCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // UI更新のためにSetStateを呼ぶ
      });
    });
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _eventNameController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    _sonarController.dispose();
    super.dispose();
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

  // --- 住所自動取得メソッド (修正済み) ---
  Future<void> _updateAddressFromLatLng(LatLng latLng) async {
    try {
      // エラーの原因となっていた localeIdentifier を削除
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // 住所の構成要素を結合
        String address =
            "${place.administrativeArea ?? ''}${place.locality ?? ''}${place.subLocality ?? ''}${place.thoroughfare ?? ''}${place.subThoroughfare ?? ''}";

        if (mounted) {
          setState(() {
            _addressController.text = address;
          });
        }
      }
    } catch (e) {
      debugPrint("住所取得エラー: $e");
      // エラー時は何もしない（ユーザーの手動入力を待つ）
    }
  }

  // --- ヘルパーメソッド ---

  String _formatDate(DateTime date) {
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 時間範囲チェック (文字列解析)
  Map<String, DateTime?> _parseEventTime(String eventTimeStr) {
    if (eventTimeStr.contains("(未定)")) return {'start': null, 'end': null};
    try {
      final parts = eventTimeStr.split(' - ');
      if (parts.length != 2) return {'start': null, 'end': null};

      final startFullStr = parts[0];
      final endTimeStr = parts[1];

      final format = DateFormat('yyyy/MM/dd HH:mm');
      final startDateTime = format.parse(startFullStr);

      final dateStr = startFullStr.split(' ')[0];
      final endDateTime = format.parse('$dateStr $endTimeStr');

      return {'start': startDateTime, 'end': endDateTime};
    } catch (e) {
      return {'start': null, 'end': null};
    }
  }

  bool _isWithinEventTime(String eventTimeStr) {
    final times = _parseEventTime(eventTimeStr);
    if (times['start'] == null || times['end'] == null)
      return true; // 未定ならとりあえず営業可能とする
    final now = DateTime.now();
    return now.isAfter(times['start']!) && now.isBefore(times['end']!);
  }

  // イベントの開始・終了監視ロジック
  void _monitorEvents(List<EventModel> events) {
    final now = DateTime.now();

    for (var event in events) {
      final times = _parseEventTime(event.eventTime);
      final start = times['start'];
      final end = times['end'];

      if (start == null || end == null) continue;

      // 1. 開始時間のチェック
      if (event.status == EventStatus.scheduled &&
          now.isAfter(start) &&
          now.isBefore(end)) {
        if (!_notifiedStartIds.contains(event.id)) {
          _notifiedStartIds.add(event.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showStartDialog(event);
          });
        }
      }

      // 2. 終了時間のチェック
      if ((event.status == EventStatus.active ||
              event.status == EventStatus.breakTime) &&
          now.isAfter(end)) {
        if (now.isAfter(end.add(const Duration(minutes: 30)))) {
          if (!_autoFinishedIds.contains(event.id)) {
            _autoFinishedIds.add(event.id);

            _firestoreService
                .updateEventStatus(event.id, EventStatus.finished)
                .then((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('「${event.eventName}」は終了時刻から30分経過したため自動終了しました'),
                    backgroundColor: Colors.grey,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }
        } else if (!_notifiedEndIds.contains(event.id)) {
          _notifiedEndIds.add(event.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showEndDialog(event);
          });
        }
      }
    }
  }

  // 開始確認ダイアログ
  void _showStartDialog(EventModel event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("イベント開始時刻です"),
          content:
              Text("「${event.eventName}」の開始時刻になりました。\nステータスを「営業中」に変更しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("あとで"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                Navigator.pop(context);
                await _firestoreService.updateEventStatus(
                    event.id, EventStatus.active);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('営業を開始しました！')),
                  );
                }
              },
              child: const Text("開始する (営業中へ)",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // 終了確認ダイアログ
  void _showEndDialog(EventModel event) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("イベント終了時刻です"),
          content: Text("「${event.eventName}」の終了時刻を過ぎました。\nステータスを「終了」に変更しますか？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("延長する"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: () async {
                Navigator.pop(context);
                await _firestoreService.updateEventStatus(
                    event.id, EventStatus.finished);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('イベントを終了しました')),
                  );
                }
              },
              child: const Text("終了する", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- UI構築 ---

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 70.0;
    const double bottomPadding = 120.0;

    return StreamBuilder<List<EventModel>>(
      stream: _myEventsStream,
      builder: (context, snapshot) {
        final myEvents = snapshot.data ?? [];

        _monitorEvents(myEvents);

        final Set<Marker> markers = {};

        for (var event in myEvents) {
          markers.add(
            Marker(
              markerId: MarkerId(event.id),
              position: event.location,
              icon: MapUtils.getMarkerIconByStatus(event.status),
              onTap: () => _onMarkerTapped(event),
            ),
          );
        }

        if (_newRegistrationMarker != null) {
          markers.add(_newRegistrationMarker!);
        }

        return Scaffold(
          body: Stack(
            children: [
              AnimatedBuilder(
                animation: _sonarController,
                builder: (context, child) {
                  final Set<Circle> activeSonars = {};

                  for (var event in myEvents) {
                    if (event.status == EventStatus.active) {
                      activeSonars.addAll(createActivePinSonar(
                        eventId: event.id,
                        center: event.location,
                        animationValue: _sonarController.value,
                      ));
                    }
                  }

                  return GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition ?? _kFallbackLocation,
                      zoom: 15.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controller.isCompleted)
                        _controller.complete(controller);
                    },
                    padding:
                        EdgeInsets.only(top: topPadding, bottom: bottomPadding),
                    onTap: _onMapTapped,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: markers,
                    circles: activeSonars,
                  );
                },
              ),
              if (_tappedLatLng != null) _buildConfirmButtonAndHint(),
              _buildTopOverlayUI(context),
              if (myEvents.any((e) => e.status == EventStatus.scheduled))
                Positioned(
                  top: topPadding + 10,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "本日の予定があります。開始時刻になると通知されます。",
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _onMarkerTapped(EventModel event) {
    final times = _parseEventTime(event.eventTime);
    final start = times['start'];
    bool isFuture = false;

    if (start != null) {
      isFuture = DateTime.now().isBefore(start);
    }

    if (event.status == EventStatus.scheduled && isFuture) {
      _showBusinessEventDetails(event);
    } else {
      _showStatusChangeSheet(event);
    }
  }

  void _showBusinessEventDetails(EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (event.eventImage.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    event.eventImage,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.white)),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: const Text('準備中',
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Text(event.categoryId,
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.eventName,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                          Icons.calendar_today, '日時', event.eventTime),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.location_on, '場所', event.address),
                      const SizedBox(height: 20),
                      const Text('詳細',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(event.description,
                          style: const TextStyle(fontSize: 16, height: 1.5)),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('閉じる'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.black54),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  // --- ステータス変更シート ---
  void _showStatusChangeSheet(EventModel event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Widget content;

        switch (event.status) {
          case EventStatus.active:
            content = Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusButton(
                    event, EventStatus.breakTime, '休憩する', Colors.orange),
                _buildStatusButton(
                    event, EventStatus.finished, '終了する', Colors.red),
              ],
            );
            break;

          case EventStatus.breakTime:
            content = Center(
              child: _buildStatusButton(
                  event, EventStatus.active, '再開する', Colors.green),
            );
            break;

          case EventStatus.finished:
            content = const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    "イベントは終了しました",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ],
              ),
            );
            break;

          case EventStatus.scheduled:
          default:
            content = Center(
              child: _buildStatusButton(
                  event, EventStatus.active, '営業開始', Colors.green),
            );
            break;
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.eventName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("現在の状態を変更します", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              content,
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusButton(
      EventModel event, String statusKey, String label, Color color) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);

        if (statusKey == EventStatus.active) {
          final bool isOpen = _isWithinEventTime(event.eventTime);
          // 時間外チェックはUX向上のため、ここでは許可する（警告のみ）などが一般的ですが、
          // 既存ロジックに合わせて今回はスルーします。
        }

        await _firestoreService.updateEventStatus(event.id, statusKey);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('状態を「$label」に変更しました'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 地図操作・登録 ---

  void _onMapTapped(LatLng latLng) {
    if (_isBottomSheetOpen) {
      FocusScope.of(context).unfocus();
      return;
    }
    setState(() {
      _tappedLatLng = latLng;
      _newRegistrationMarker = Marker(
        markerId: const MarkerId('new_reg_pin'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
      );
    });
    // タップ時に住所を自動取得
    _updateAddressFromLatLng(latLng);
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
          _newRegistrationMarker = Marker(
            markerId: const MarkerId('new_reg_pin'),
            position: locationToRegister!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueCyan),
          );
        });
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newLatLngZoom(locationToRegister, 16),
        );
        // 現在地取得時にも住所を自動取得
        await _updateAddressFromLatLng(locationToRegister);
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

  // --- 登録フォーム関連 ---

  void _showRegistrationSheet() async {
    setState(() {
      _isBottomSheetOpen = true;
      _isRegistrationSuccessful = false;
    });

    _eventNameController.clear();
    _descriptionController.clear();

    // 住所が取得できていない（マーカーがない）場合のみクリア
    if (_tappedLatLng == null) _addressController.clear();

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
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
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
                            child: (_imageBytes == null &&
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
          _tappedLatLng = null;
          _newRegistrationMarker = null;
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

  void _addHoursToEndTime(int hours, StateSetter setModalState) {
    if (_startTimeController.text.isEmpty) return;
    try {
      final parts = _startTimeController.text.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      int newHour = (hour + hours) % 24;
      setModalState(() => _endTimeController.text =
          '${newHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      debugPrint('時刻計算エラー: $e');
    }
  }

  Future<void> _selectTime(BuildContext context,
      TextEditingController controller, StateSetter setModalState) async {
    TimeOfDay initialTime = TimeOfDay.now();
    if (controller.text.isNotEmpty) {
      try {
        final parts = controller.text.split(':');
        initialTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!),
    );
    if (picked != null) {
      setModalState(() => controller.text = _formatTimeOfDay(picked));
    }
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
                stream: _firestoreService.getTemplatesStream(_currentUserId),
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
        adminId: _currentUserId,
        categoryId: _selectedCategory,
        address: _addressController.text,
        eventImage: imageUrl,
        eventDateTime: DateFormat('yyyy/MM/dd').parse(_dateController.text),
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
}