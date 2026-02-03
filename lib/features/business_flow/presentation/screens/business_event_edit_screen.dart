import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/service/storage_service.dart';

class BusinessEventEditScreen extends StatefulWidget {
  final EventModel event;

  const BusinessEventEditScreen({super.key, required this.event});

  @override
  State<BusinessEventEditScreen> createState() => _BusinessEventEditScreenState();
}

class _BusinessEventEditScreenState extends State<BusinessEventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _eventNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _startTimeController;
  late TextEditingController _endTimeController;
  
  final List<String> _categories = ['Food', 'Music', 'Shop', 'Art', 'Other'];
  late String _selectedCategory;
  
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // 初期値をセット
    _eventNameController = TextEditingController(text: widget.event.eventName);
    _descriptionController = TextEditingController(text: widget.event.description);
    
    // カテゴリの初期値 (リストにない場合はその他)
    _selectedCategory = _categories.contains(widget.event.categoryId) 
        ? widget.event.categoryId 
        : 'Other';

    // 日時の分解 (例: "2026/01/20 10:00 - 12:00" -> 日付, 開始, 終了)
    _parseEventTime(widget.event.eventTime);
  }

  void _parseEventTime(String timeStr) {
    // 簡易的なパース処理 (フォーマットが崩れている場合は空にする)
    try {
      if (timeStr.contains("(未定)")) {
        final parts = timeStr.split(' ');
        _dateController = TextEditingController(text: parts[0]);
        _startTimeController = TextEditingController();
        _endTimeController = TextEditingController();
      } else {
        // "2026/01/20 10:00 - 12:00"
        final parts = timeStr.split(' ');
        _dateController = TextEditingController(text: parts[0]);
        _startTimeController = TextEditingController(text: parts[1]);
        _endTimeController = TextEditingController(text: parts[3]);
      }
    } catch (_) {
      _dateController = TextEditingController(text: "");
      _startTimeController = TextEditingController();
      _endTimeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _pickedImage = image);
    }
  }

  Future<void> _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 時間のフォーマットチェック (簡易)
    if (_startTimeController.text.isEmpty && _endTimeController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('開始時間を入力してください')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? newImageUrl;
      
      // 画像が変更された場合のみアップロード
      if (_pickedImage != null) {
        newImageUrl = await _storageService.uploadImage(_pickedImage!, 'event_images');
      }

      // 時間文字列の生成
      String timeStr;
      if (_startTimeController.text.isEmpty) {
        timeStr = "${_dateController.text} (未定)";
      } else {
        timeStr = "${_dateController.text} ${_startTimeController.text} - ${_endTimeController.text}";
      }

      await _firestoreService.updateEvent(
        eventId: widget.event.id,
        eventName: _eventNameController.text,
        eventTime: timeStr,
        categoryId: _selectedCategory,
        description: _descriptionController.text,
        newImageUrl: newImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('イベント情報を更新しました')));
        Navigator.pop(context); // 編集画面を閉じる
        Navigator.pop(context); // 詳細モーダルも閉じる (更新反映のため)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('イベント編集')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 画像エリア
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          image: _pickedImage != null
                              ? DecorationImage(
                                  image: kIsWeb 
                                    ? NetworkImage(_pickedImage!.path) 
                                    : FileImage(File(_pickedImage!.path)) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : (widget.event.eventImage.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(widget.event.eventImage),
                                      fit: BoxFit.cover,
                                    )
                                  : null),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_pickedImage == null && widget.event.eventImage.isEmpty)
                              const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 編集不可エリア (場所)
                    const Text('開催場所 (変更不可)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.event.address,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                          const Icon(Icons.lock, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // イベント名
                    TextFormField(
                      controller: _eventNameController,
                      decoration: const InputDecoration(
                        labelText: 'イベント名',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? '入力してください' : null,
                    ),
                    const SizedBox(height: 16),

                    // カテゴリ
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'カテゴリ',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(height: 16),

                    // 日付 (今回はテキストフィールドとして編集させる簡易実装。必要ならDatePickerを入れる)
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: '開催日 (yyyy/MM/dd)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 時間
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startTimeController,
                            decoration: const InputDecoration(
                              labelText: '開始 (HH:mm)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('～'),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _endTimeController,
                            decoration: const InputDecoration(
                              labelText: '終了 (HH:mm)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 詳細
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '詳細',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 32),

                    // 保存ボタン
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('変更を保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      )     
    );
  }
}