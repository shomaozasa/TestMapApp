import 'dart:io'; // Mobile用
import 'dart:typed_data'; // Web用
import 'package:flutter/foundation.dart'; // kIsWeb判定用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/business_user_model.dart';

// ★追加: 正しいログアウトボタンをインポート
import 'package:google_map_app/features/_authentication/presentation/screens/logout_button.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String adminId;

  const BusinessProfileScreen({super.key, required this.adminId});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // コントローラー
  late TextEditingController _adminNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _homepageController;
  late TextEditingController _xUrlController;
  late TextEditingController _instagramController;
  late TextEditingController _descriptionController;

  String? _category;
  String? _currentIconUrl;
  
  // 画像関連の変数
  XFile? _pickedFile;
  Uint8List? _webImageBytes; // Web表示用の画像データ

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchData();
  }

  void _initializeControllers() {
    _adminNameController = TextEditingController();
    _ownerNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _homepageController = TextEditingController();
    _xUrlController = TextEditingController();
    _instagramController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.adminId)
          .get();

      if (doc.exists) {
        final business = BusinessUserModel.fromFirestore(doc);
        
        _adminNameController.text = business.adminName;
        _ownerNameController.text = business.ownerName;
        _emailController.text = business.email;
        _phoneController.text = business.phoneNumber;
        _homepageController.text = business.homepage;
        _xUrlController.text = business.xUrl;
        _instagramController.text = business.instagramUrl;
        _descriptionController.text = business.description;

        setState(() {
          _category = business.adminCategory.isNotEmpty ? business.adminCategory : null;
          _currentIconUrl = business.iconImage;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 画像選択処理
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (picked != null) {
        if (kIsWeb) {
          // Webの場合: バイトデータを読み込んでセット
          final bytes = await picked.readAsBytes();
          setState(() {
            _pickedFile = picked;
            _webImageBytes = bytes;
          });
        } else {
          // Mobileの場合
          setState(() {
            _pickedFile = picked;
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Image picker error: $e');
    }
  }

  // 保存処理
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? iconUrl = _currentIconUrl;

      // 画像が新しく選択されていたらアップロード
      if (_pickedFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_icons/${widget.adminId}_${DateTime.now().millisecondsSinceEpoch}.png');
        
        if (kIsWeb) {
          // Web: バイトデータとしてアップロード (putData)
          if (_webImageBytes != null) {
             await ref.putData(
               _webImageBytes!, 
               SettableMetadata(contentType: 'image/png') // メタデータ指定でWeb表示を安定させる
             );
          }
        } else {
          // Mobile: ファイルパスからアップロード (putFile)
          await ref.putFile(File(_pickedFile!.path));
        }
        
        iconUrl = await ref.getDownloadURL();
      }

      // Firestore更新
      await FirebaseFirestore.instance.collection('businesses').doc(widget.adminId).update({
        'phone_number': _phoneController.text.trim(),
        'admin_category': _category ?? '',
        'homepage': _homepageController.text.trim(),
        'xUrl': _xUrlController.text.trim(),
        'instagramUrl': _instagramController.text.trim(),
        'icon_image': iconUrl,
        'description': _descriptionController.text.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ★ 修正: バグの原因だった古い _logout メソッドを削除しました

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('店舗プロフィール編集'),
        actions: const [
          // ★ 修正: 自作した LogoutButton を配置
          LogoutButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildIconPicker()),
                    const SizedBox(height: 32),

                    // --- 編集不可エリア ---
                    _buildSectionTitle('基本情報 (変更不可)'),
                    const Text('※変更が必要な場合は運営にお問い合わせください', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 10),
                    _buildReadOnlyTextField('事業者名', _adminNameController),
                    const SizedBox(height: 16),
                    _buildReadOnlyTextField('代表者名', _ownerNameController),
                    const SizedBox(height: 16),
                    _buildReadOnlyTextField('メールアドレス', _emailController),
                    const SizedBox(height: 32),

                    // --- 編集可能エリア ---
                    _buildSectionTitle('店舗情報 (編集可能)'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '自己紹介・お店のアピール',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _category,
                      items: const [
                        DropdownMenuItem(value: '美容系', child: Text('美容系')),
                        DropdownMenuItem(value: '修理業', child: Text('修理業')),
                        DropdownMenuItem(value: '飲食業', child: Text('飲食業')),
                        DropdownMenuItem(value: 'その他', child: Text('その他')),
                      ],
                      decoration: const InputDecoration(labelText: 'カテゴリ'),
                      onChanged: (v) => setState(() => _category = v),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: '電話番号'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? '入力してください' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _homepageController,
                      decoration: const InputDecoration(labelText: 'ホームページURL'),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _xUrlController,
                      decoration: const InputDecoration(labelText: 'X (Twitter) URL'),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(labelText: 'Instagram URL'),
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('変更を保存する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // WebとMobileの画像表示切り替え
  Widget _buildIconPicker() {
    ImageProvider? imageProvider;

    if (_pickedFile != null) {
      if (kIsWeb) {
        if (_webImageBytes != null) {
          imageProvider = MemoryImage(_webImageBytes!);
        } else {
          imageProvider = null;
        }
      } else {
        imageProvider = FileImage(File(_pickedFile!.path));
      }
    } else if (_currentIconUrl != null && _currentIconUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentIconUrl!);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.store, size: 60, color: Colors.white)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildReadOnlyTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(color: Colors.black54),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.lock, size: 18, color: Colors.grey),
      ),
    );
  }
}