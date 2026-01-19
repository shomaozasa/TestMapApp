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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('テンプレート管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<TemplateModel>>(
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
                  Icon(Icons.note_add_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('テンプレートがありません\n右下のボタンから作成してください', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
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
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showTemplateDetails(context, template),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            image: template.imagePath.isNotEmpty
                                ? DecorationImage(image: NetworkImage(template.imagePath), fit: BoxFit.cover)
                                : null,
                          ),
                          child: template.imagePath.isEmpty
                              ? const Icon(Icons.image, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(template.templateName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text("${template.categoryId}  |  ${template.eventName}", style: const TextStyle(fontSize: 12, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                (template.startTime.isNotEmpty && template.endTime.isNotEmpty)
                                    ? "${template.startTime} ～ ${template.endTime}"
                                    : "時間指定なし (登録時に設定)",
                                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () async {
                            await _firestoreService.deleteTemplate(template.id);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateForm(context),
        label: const Text('新規作成'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 作成フォームの表示
  void _showTemplateForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: template.imagePath.isNotEmpty
                          ? Image.network(template.imagePath, fit: BoxFit.cover)
                          : const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "テンプレート名: ${template.templateName}",
                          style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(template.eventName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.category, 'カテゴリ', template.categoryId),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.access_time, 
                        '設定時間', 
                        (template.startTime.isNotEmpty && template.endTime.isNotEmpty)
                            ? "${template.startTime} ～ ${template.endTime}"
                            : "未設定 (登録時に指定)"
                      ),
                      const Divider(height: 40),
                      Text('詳細情報', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        template.description.isNotEmpty ? template.description : '詳細情報はありません。',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5)
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
        Icon(icon, color: Colors.black54, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87)),
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
  
  // ★ 仮のStorageServiceを使用
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
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Center(
              child: Text('テンプレート作成', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),

            _buildSectionLabel('管理用テンプレート名', isRequired: true),
            TextField(
              controller: _templateNameController,
              decoration: InputDecoration(
                hintText: '例: 平日ランチ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionLabel('カテゴリ', isRequired: true),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: Colors.orange.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.orange.shade900 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (bool selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _buildSectionLabel('活動時間 (空欄なら登録時に設定)', isRequired: false),
            Row(
              children: [
                Expanded(child: _buildTimeBox('開始', _startTime, true)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('～', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ),
                Expanded(child: _buildTimeBox('終了', _endTime, false)),
              ],
            ),
            const SizedBox(height: 20),

            _buildSectionLabel('デフォルト写真 (任意)', isRequired: false),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  image: _imageBytes != null
                      ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                      : null,
                ),
                child: _imageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                          Text('写真をアップロード', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      )
                    : null,
              ),
            ),
            if (_imageBytes != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() {
                    _pickedImage = null;
                    _imageBytes = null;
                  }),
                  child: const Text('削除', style: TextStyle(color: Colors.red)),
                ),
              ),
            const SizedBox(height: 20),

            _buildSectionLabel('イベント名 / PRタイトル', isRequired: true),
            TextField(
              controller: _eventNameController,
              decoration: InputDecoration(
                hintText: '例: 本日の日替わり定食',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '詳細説明 (任意)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _isLoading ? null : _saveTemplate,
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
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
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          if (isRequired)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: Text('必須', style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
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
                          child: const Text("完了", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: hasTime ? Colors.orange : Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (hasTime)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isStart) _startTime = ""; else _endTime = "";
                    }),
                    child: const Icon(Icons.close, size: 14, color: Colors.grey),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hasTime ? timeStr : "--:--",
              style: TextStyle(
                fontSize: 18, 
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