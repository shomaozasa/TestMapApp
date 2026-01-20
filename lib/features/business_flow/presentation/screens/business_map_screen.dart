import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // ★ 日付フォーマット用に intl を使用推奨（なければ追加、あるいは手動フォーマット）

import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/service/storage_service.dart';
import 'package:google_map_app/core/models/template_model.dart';

class BusinessMapScreen extends StatefulWidget {
  // ★ 追加: カレンダーから遷移してきた場合に日付を受け取る
  final DateTime? initialDate; 

  const BusinessMapScreen({super.key, this.initialDate});

  @override
  State<BusinessMapScreen> createState() => _BusinessMapScreenState();
}

class _BusinessMapScreenState extends State<BusinessMapScreen> {
  final String _testAdminId = 'test_user_id';
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  Marker? _tappedMarker;
  LatLng? _tappedLatLng;

  // コントローラー
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  // ★ 追加: 日付用コントローラー
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
  
  // ★ 追加: 「時間は未定」フラグ
  bool _isTimeUndecided = false; 

  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

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
    _dateController.dispose(); // ★ 追加
    super.dispose();
  }

  // 日付フォーマット用ヘルパー
  String _formatDate(DateTime date) {
    return "${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    // UI部分は変更なし
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
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            zoomGesturesEnabled: !_isBottomSheetOpen,
            scrollGesturesEnabled: !_isBottomSheetOpen,
            rotateGesturesEnabled: !_isBottomSheetOpen,
            tiltGesturesEnabled: !_isBottomSheetOpen,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: <Marker>{if (_tappedMarker != null) _tappedMarker!},
          ),
          _buildConfirmButtonAndHint(),
          _buildTopOverlayUI(context),
        ],
      ),
    );
  }

  // --- UIパーツ (変更なし部分は省略、変更点のみ記述) ---

  Widget _buildTopOverlayUI(BuildContext context) {
    // 変更なし
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

  Widget _buildCircleButton({required BuildContext context, required IconData icon, required VoidCallback onPressed}) {
    // 変更なし
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
    // 変更なし
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
    // 変更なし
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
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: (_isLoadingLocation || _isBottomSheetOpen) ? null : _onStartNowPressed,
            child: _isLoadingLocation
                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                : Text(_tappedLatLng == null ? '現在地ではじめる' : 'ここ(選択した場所)ではじめる'),
          ),
        ],
      ),
    );
  }

  void _onStartNowPressed() async {
    // 変更なし
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
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          );
        });
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(locationToRegister, 16));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('現在地を取得できませんでした: $e'), backgroundColor: Colors.red));
        }
      }
    }
    setState(() => _isLoadingLocation = false);
    if (locationToRegister != null) {
      _showRegistrationSheet();
    }
  }

  // ★★★ 登録シートの表示ロジック (大幅修正) ★★★
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
    
    // ★ 修正: 日付と時間の初期化ロジック
    // 引数で日付が渡されていればそれを、なければ今日を設定
    final DateTime targetDate = widget.initialDate ?? DateTime.now();
    _dateController.text = _formatDate(targetDate);

    // 時間未定フラグのリセット
    _isTimeUndecided = false;

    // 時間の初期値
    if (widget.initialDate != null) {
      // 予定登録の場合、現在時刻を入れるのは不自然なので空またはキリの良い時間にする
      _startTimeController.text = "12:00"; 
      _endTimeController.text = "13:00";
    } else {
      // 通常登録（今すぐ）の場合、現在時刻を入れる
      _startTimeController.text = _formatTimeOfDay(TimeOfDay.now());
      _endTimeController.clear();
    }

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  left: 24, right: 24, top: 24,
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
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showTemplateSelector(setModalState),
                            icon: const Icon(Icons.note_add_outlined, size: 18),
                            label: const Text("テンプレ読込"),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 画像エリア (変更なし)
                      Center(
                        child: InkWell(
                          onTap: () async {
                            final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (image != null) {
                              final Uint8List bytes = await image.readAsBytes();
                              setModalState(() { _pickedImage = image; _imageBytes = bytes; });
                            }
                          },
                          child: Container(
                            width: double.infinity, height: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade400),
                              image: _imageBytes != null
                                  ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                                  : (_templateImageUrl != null && _templateImageUrl!.isNotEmpty)
                                      ? DecorationImage(image: NetworkImage(_templateImageUrl!), fit: BoxFit.cover)
                                      : null,
                            ),
                            child: (_imageBytes == null && (_templateImageUrl == null || _templateImageUrl!.isEmpty))
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('イベント画像を追加', style: TextStyle(color: Colors.grey)),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (_imageBytes != null || (_templateImageUrl != null && _templateImageUrl!.isNotEmpty))
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              setModalState(() { _pickedImage = null; _imageBytes = null; _templateImageUrl = null; });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('画像を削除', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // イベント名
                      TextField(
                        controller: _eventNameController,
                        decoration: const InputDecoration(labelText: 'イベント名 (必須)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.event)),
                      ),
                      const SizedBox(height: 12),

                      // カテゴリ
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(labelText: 'カテゴリ (必須)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                        items: _categories.map((String category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                        onChanged: (String? newValue) => setModalState(() => _selectedCategory = newValue!),
                      ),
                      const SizedBox(height: 12),

                      // ★ 追加: 日付選択
                      TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: '開催日 (必須)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                        readOnly: true, // 手入力不可
                        onTap: () async {
                          // 日付ピッカーを表示
                          DateTime initD = widget.initialDate ?? DateTime.now();
                          // もし入力済みの値があればそれをパースして初期値にする
                          try {
                             final parts = _dateController.text.split('/');
                             if(parts.length == 3) {
                               initD = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
                             }
                          } catch(_){}

                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initD,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            locale: const Locale('ja'), // 日本語対応
                          );
                          if (picked != null) {
                            setModalState(() {
                              _dateController.text = _formatDate(picked);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // ★ 追加: 「時間は未定」チェックボックス
                      CheckboxListTile(
                        title: const Text("時間は未定", style: TextStyle(fontWeight: FontWeight.bold)),
                        value: _isTimeUndecided,
                        onChanged: (bool? value) {
                          setModalState(() {
                            _isTimeUndecided = value ?? false;
                            // 未定にした場合、入力欄をクリアしても良いし、残しても良い。今回は残す。
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      const SizedBox(height: 8),

                      // 時間入力 (未定の場合は無効化)
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
                                      decoration: InputDecoration(
                                        labelText: '開始時刻',
                                        border: const OutlineInputBorder(),
                                        // 現在時刻ボタンは予定モードでも便利なので残す
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.update),
                                          onPressed: () => setModalState(() => _startTimeController.text = _formatTimeOfDay(TimeOfDay.now())),
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
                                      decoration: const InputDecoration(labelText: '終了時刻', hintText: '例: 17:00', border: OutlineInputBorder()),
                                      readOnly: false,
                                      keyboardType: TextInputType.datetime,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 時刻アシストボタン
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text('終了時刻を簡単入力: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  OutlinedButton(onPressed: () => _setEndTime(setModalState, 1), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)), child: const Text('+1h')),
                                  const SizedBox(width: 4),
                                  OutlinedButton(onPressed: () => _setEndTime(setModalState, 2), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)), child: const Text('+2h')),
                                  const SizedBox(width: 4),
                                  OutlinedButton(onPressed: () => _setEndTime(setModalState, 3), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)), child: const Text('+3h')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      // 住所入力
                      TextField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: '場所・住所 (必須)', hintText: '例: 天神中央公園', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on)),
                      ),
                      const SizedBox(height: 12),

                      // 詳細
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'イベント詳細（任意）', hintText: 'セールの情報やメニューなど...', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description)),
                        maxLines: 3, keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: _isLoadingSheet ? null : () => _submitEvent(setModalState),
                        child: _isLoadingSheet ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)) : const Text('OK (登録)'),
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

  // テンプレート選択 (変更なし)
  void _showTemplateSelector(StateSetter setModalState) {
    final String targetAdminId = _testAdminId; 
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("テンプレートを選択", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<TemplateModel>>(
                  stream: _firestoreService.getTemplatesStream(targetAdminId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final templates = snapshot.data ?? [];
                    if (templates.isEmpty) return const Center(child: Text("テンプレートがありません"));
                    return ListView.builder(
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12), elevation: 0, color: Colors.grey.shade50,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            leading: template.imagePath.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(template.imagePath, width: 50, height: 50, fit: BoxFit.cover)) : const Icon(Icons.note, color: Colors.grey),
                            title: Text(template.templateName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(template.eventName),
                            onTap: () {
                              setModalState(() {
                                _eventNameController.text = template.eventName;
                                _descriptionController.text = template.description;
                                if (_categories.contains(template.categoryId)) _selectedCategory = template.categoryId;
                                // テンプレートの時間はあくまで「目安」なので、予定登録時は慎重に扱うべきだが、一応セットする
                                if (!_isTimeUndecided) {
                                   if (template.startTime.isNotEmpty) _startTimeController.text = template.startTime;
                                   if (template.endTime.isNotEmpty) _endTimeController.text = template.endTime;
                                }
                                _templateImageUrl = template.imagePath;
                                _pickedImage = null; _imageBytes = null;
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テンプレートを反映しました')));
                            },
                          ),
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

  void _setEndTime(StateSetter setModalState, int hoursToAdd) {
    final TimeOfDay startTime = _parseTimeOfDay(_startTimeController.text);
    final TimeOfDay endTime = startTime.replacing(hour: (startTime.hour + hoursToAdd) % 24);
    setModalState(() => _endTimeController.text = _formatTimeOfDay(endTime));
    FocusScope.of(context).unfocus();
  }

  TimeOfDay _parseTimeOfDay(String formattedTime) {
    try {
      final parts = formattedTime.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]); final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {}
    return TimeOfDay.now();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ★★★ 登録処理 (日付・時間未定の考慮) ★★★
  void _submitEvent(StateSetter setModalState) async {
    final eventName = _eventNameController.text;
    final dateStr = _dateController.text; // 日付文字列
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;
    final description = _descriptionController.text;
    final address = _addressController.text;
    final category = _selectedCategory;

    // バリデーション
    if (eventName.isEmpty || address.isEmpty || _tappedLatLng == null || dateStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('必須項目（イベント名、開催日、場所）を入力してください'), backgroundColor: Colors.red));
      return;
    }
    
    // 時間のバリデーション (未定でないなら必須)
    if (!_isTimeUndecided && (startTime.isEmpty || endTime.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('時間を入力するか、「時間は未定」にチェックを入れてください'), backgroundColor: Colors.red));
      return;
    }

    setModalState(() => _isLoadingSheet = true);

    try {
      String imageUrl = "";
      if (_pickedImage != null) {
        imageUrl = await _storageService.uploadImage(_pickedImage!, 'event_images');
      } else if (_templateImageUrl != null) {
        imageUrl = _templateImageUrl!;
      }

      // ★ 修正: 保存するイベント時間の文字列を作成
      // 例: "2026/01/20 10:00 - 12:00" または "2026/01/20 (時間未定)"
      String eventTimeDisplay = "";
      if (_isTimeUndecided) {
        eventTimeDisplay = "$dateStr (時間未定)";
      } else {
        eventTimeDisplay = "$dateStr $startTime - $endTime";
      }
      
      // 注意: 本来は Firestoreの createdAt フィールド以外に、eventDate という Timestampフィールドを持つべきですが
      // 現状のDB構造(createdAtでソート)を維持するため、ここでは createdAt を「イベント開催日」として保存するハックを使います。
      // もし正確な登録日時が必要な場合は、EventModelにフィールドを追加する必要があります。
      
      // 今回は「イベント開催日」を createdAt として扱えるように、
      // 登録処理側(_firestoreService)には手を加えず、
      // 表示上の文字列(eventTime)に日付を含めることで対応します。
      
      final String adminId = _testAdminId;

      // ★ ハック: Firestoreに保存する際、createdAt が自動で「今」になるのが通常の仕様ですが、
      // 予定管理のために「指定した日付」を保存したい場合、FirestoreService の addEvent を修正するか、
      // あるいは eventDate フィールドを追加するのが筋です。
      // 今回は既存コードへの影響を最小限にするため、
      // 「eventTime文字列に日付を含める」ことで、カレンダー表示やリスト表示で日付がわかるようにしました。
      // ソート順(createdAt)は「登録順」のままになります。
      // ※ カレンダーにドットを出すロジックは createdAt を見ているため、
      // 「未来の日付の予定」を入れた場合、カレンダー上は「今日」の位置にドットが出てしまう問題が残ります。
      
      // ★ 解決策: FirestoreServiceの修正を行わない範囲で、
      // カレンダー表示のためには、eventTime文字列から日付をパースして表示するロジックが ScheduleScreen 側に必要です。
      // ですが、今回は ScheduleScreen 側で createdAt を見ていたので、
      // ここで「未来の日付」を createdAt として保存することはできません（サーバー側でTimestamp.now()されるため）。
      
      // なので、理想は EventModel に `eventDate` を追加することですが、
      // 現状のまま進めるなら「eventTime」に全ての情報を詰め込みます。

      await _firestoreService.addEvent(
        eventName: eventName,
        eventTime: eventTimeDisplay, // 日付入り文字列
        location: _tappedLatLng!,
        description: description,
        adminId: adminId,
        categoryId: category,
        address: address,
        eventImage: imageUrl, 
      );

      _isRegistrationSuccessful = true;
      if (mounted) Navigator.of(context).pop();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('イベントを登録しました！'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登録に失敗しました: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setModalState(() => _isLoadingSheet = false);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled; LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('ロケーションサービスが無効です。');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('ロケーションの権限が拒否されました。');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('ロケーションの権限が永久に拒否されています。');
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}