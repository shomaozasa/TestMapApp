import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/core/models/template_model.dart';
import 'package:google_map_app/core/service/storage_service.dart';

class TemplateManagementScreen extends StatefulWidget {
  final String adminId;
  const TemplateManagementScreen({super.key, required this.adminId});

  @override
  State<TemplateManagementScreen> createState() => _TemplateManagementScreenState();
}

class _TemplateManagementScreenState extends State<TemplateManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // テーマカラー
  static const Color themeColor = Colors.orange;
  static const Color gradientStart = Color(0xFFFFCC80);
  static const Color gradientEnd = Color(0xFFFFF3E0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStart, gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // --- ヘッダー ---
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.copy_all_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Text(
                      "Templates",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),

              // --- コンテンツエリア ---
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    child: StreamBuilder<List<TemplateModel>>(
                      stream: _firestoreService.getTemplatesStream(widget.adminId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final templates = snapshot.data ?? [];

                        if (templates.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.note_add_outlined, size: 60, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'テンプレートがありません\n右下のボタンから作成してください',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: templates.length,
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            return _buildTemplateCard(template);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateForm(context),
        label: const Text('新規作成', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // テンプレートカード
  Widget _buildTemplateCard(TemplateModel template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showTemplateDetails(context, template),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // サムネイル画像
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    image: template.imagePath.isNotEmpty
                        ? DecorationImage(image: NetworkImage(template.imagePath), fit: BoxFit.cover)
                        : null,
                  ),
                  child: template.imagePath.isEmpty
                      ? Icon(Icons.image, color: Colors.grey.shade400, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // 詳細情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          template.templateName,
                          style: const TextStyle(fontSize: 10, color: themeColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.eventName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (template.startTime.isNotEmpty && template.endTime.isNotEmpty)
                            ? "${template.startTime} ～ ${template.endTime}"
                            : "時間指定なし",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                // 削除ボタン
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                  onPressed: () => _confirmDelete(template),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(TemplateModel template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('削除の確認', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('このテンプレートを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestoreService.deleteTemplate(template.id);
            },
            child: const Text('削除する', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 作成フォームの表示
  void _showTemplateForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _TemplateForm(adminId: widget.adminId),
    );
  }

  // 詳細画面の表示
  void _showTemplateDetails(BuildContext context, TemplateModel template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // 画像エリア
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: template.imagePath.isNotEmpty
                          ? Image.network(template.imagePath, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.image, size: 60, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "テンプレート: ${template.templateName}",
                              style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              template.categoryId,
                              style: const TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(template.eventName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      
                      _buildInfoRow(
                        Icons.access_time_filled, 
                        '設定時間', 
                        (template.startTime.isNotEmpty && template.endTime.isNotEmpty)
                            ? "${template.startTime} ～ ${template.endTime}"
                            : "未設定 (登録時に指定)"
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Divider(),
                      ),
                      
                      const Text('詳細情報', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        template.description.isNotEmpty ? template.description : '詳細情報はありません。',
                        style: const TextStyle(height: 1.6, fontSize: 15, color: Colors.black87),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.black54, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TemplateForm extends StatefulWidget {
  final String adminId;
  const _TemplateForm({required this.adminId});

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<_TemplateForm> {
  final _templateNameController = TextEditingController();
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _startTime = "";
  String _endTime = "";
  
  final List<String> _categories = ['Food', 'Music', 'Shop', 'Art', 'Other'];
  String _selectedCategory = 'Food';

  XFile? _pickedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();
  
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ドラッグハンドル
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            // ヘッダー (タイトル & 閉じるボタン)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('テンプレート作成', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('管理用テンプレート名', isRequired: true),
            TextField(
              controller: _templateNameController,
              decoration: InputDecoration(
                hintText: '例: 平日ランチ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('カテゴリ', isRequired: true),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: Colors.orange,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('活動時間 (空欄なら登録時に設定)', isRequired: false),
            Row(
              children: [
                Expanded(child: _buildTimeBox('開始', _startTime, true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                ),
                Expanded(child: _buildTimeBox('終了', _endTime, false)),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('デフォルト写真 (任意)', isRequired: false),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('写真をアップロード', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : null,
              ),
            ),
            if (_imageBytes != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _pickedImage = null;
                    _imageBytes = null;
                  }),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('画像を削除', style: TextStyle(color: Colors.red)),
                ),
              ),
            const SizedBox(height: 24),

            _buildSectionLabel('イベント名 / PRタイトル', isRequired: true),
            TextField(
              controller: _eventNameController,
              decoration: InputDecoration(
                hintText: '例: 本日の日替わり定食',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '詳細説明 (任意)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                ),
                onPressed: _isLoading ? null : _saveTemplate,
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('テンプレートを保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text, {required bool isRequired}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
          if (isRequired)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: const Text('必須', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String label, String timeStr, bool isStart) {
    final bool hasTime = timeStr.isNotEmpty;
    return InkWell(
      onTap: () async {
        DateTime initialDate = DateTime.now();
        if (hasTime) {
          final parts = timeStr.split(':');
          if (parts.length == 2) {
            initialDate = DateTime(
              initialDate.year, initialDate.month, initialDate.day,
              int.parse(parts[0]), int.parse(parts[1])
            );
          }
        } else {
          int minute = initialDate.minute;
          int remainder = minute % 5;
          if (remainder != 0) {
            int addMinutes = 5 - remainder;
            initialDate = initialDate.add(Duration(minutes: addMinutes));
          }
        }

        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          builder: (BuildContext builder) {
            return SizedBox(
              height: 250,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("時間を選択", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("完了", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: initialDate,
                      use24hFormat: true,
                      minuteInterval: 5,
                      onDateTimeChanged: (DateTime newDateTime) {
                        final formatted = "${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}";
                        setState(() {
                          if (isStart) {
                            _startTime = formatted;
                            if (_endTime.isEmpty) {
                              final endDate = newDateTime.add(const Duration(hours: 3));
                              _endTime = "${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}";
                            }
                          } else {
                            _endTime = formatted;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
        if (isStart && _startTime.isEmpty) {
           final formatted = "${initialDate.hour.toString().padLeft(2, '0')}:${initialDate.minute.toString().padLeft(2, '0')}";
           setState(() => _startTime = formatted);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasTime ? Colors.orange : Colors.grey.shade300, width: hasTime ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                if (hasTime)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isStart) _startTime = ""; else _endTime = "";
                    }),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              hasTime ? timeStr : "--:--",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: hasTime ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (_templateNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テンプレート名を入力してください')));
      return;
    }
    if (_eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('イベント名を入力してください')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = "";
      if (_pickedImage != null) {
        try {
          imageUrl = await _storageService.uploadImage(_pickedImage!, 'template_images');
        } catch (e) {
          debugPrint("画像アップロードエラー: $e");
        }
      }

      final newTemplate = TemplateModel(
        id: '',
        adminId: widget.adminId,
        templateName: _templateNameController.text,
        eventName: _eventNameController.text,
        categoryId: _selectedCategory,
        startTime: _startTime,
        endTime: _endTime,
        description: _descriptionController.text,
        imagePath: imageUrl,
      );

      await _firestoreService.addTemplate(newTemplate);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('テンプレートを作成しました')));
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}