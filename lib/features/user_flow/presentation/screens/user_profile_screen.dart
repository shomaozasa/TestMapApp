import 'dart:io'; // Mobile用
import 'dart:typed_data'; // Web用
import 'package:flutter/foundation.dart'; // kIsWeb用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/user_model.dart';

// 作成したログアウトボタンをインポート
import 'package:google_map_app/features/_authentication/presentation/screens/logout_button.dart';
// ★ 追加: レビュー履歴画面をインポート
import 'package:google_map_app/features/user_flow/presentation/screens/review_history_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _userNameController;
  late TextEditingController _emailController;
  
  String? _currentIconUrl;
  
  XFile? _pickedFile;
  Uint8List? _webImageBytes;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _emailController = TextEditingController();
    _fetchData();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // データ取得
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        _userNameController.text = user.userName;
        _emailController.text = user.email;
        setState(() {
          _currentIconUrl = user.iconImage;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 画像選択
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      
      if (picked != null) {
        if (kIsWeb) {
          final bytes = await picked.readAsBytes();
          setState(() {
            _pickedFile = picked;
            _webImageBytes = bytes;
          });
        } else {
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

      if (_pickedFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_icons/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.png');
        
        if (kIsWeb && _webImageBytes != null) {
           await ref.putData(_webImageBytes!, SettableMetadata(contentType: 'image/png'));
        } else {
           await ref.putFile(File(_pickedFile!.path));
        }
        iconUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'user_name': _userNameController.text.trim(),
        'icon_image': iconUrl,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: const [
          LogoutButton(), // ログアウトボタン
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildIconPicker(),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _userNameController,
                      decoration: const InputDecoration(
                        labelText: 'ユーザー名',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? '入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.grey),
                      decoration: const InputDecoration(
                        labelText: 'メールアドレス',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                        prefixIcon: Icon(Icons.lock, size: 18, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('変更を保存', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    
                    // ★ 追加: レビュー履歴画面への遷移ボタン
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReviewHistoryScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text("レビュー履歴を見る", style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIconPicker() {
    ImageProvider? imageProvider;

    if (_pickedFile != null) {
      if (kIsWeb && _webImageBytes != null) {
        imageProvider = MemoryImage(_webImageBytes!);
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
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}