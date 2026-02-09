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
// レビュー履歴画面をインポート
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

  // テーマカラー
  static const Color themeColor = Color(0xFF4A90E2);
  static const Color gradientStart = Color(0xFFE3F2FD); // 薄い青
  static const Color gradientEnd = Color(0xFFF5F5F5);   // 白に近いグレー

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

  // 入力欄のスタイル定義
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: themeColor),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: themeColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('マイページ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LogoutButton(),
          ),
        ],
      ),
      body: _isLoading
          ? Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()),
            )
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientStart, gradientEnd],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // プロフィール画像エリア
                      _buildIconPicker(),
                      const SizedBox(height: 24),
                      
                      // メインフォームカード
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("基本情報", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 16),
                                
                                TextFormField(
                                  controller: _userNameController,
                                  decoration: _buildInputDecoration('ユーザー名', Icons.person_outline),
                                  validator: (v) => v!.isEmpty ? '入力してください' : null,
                                ),
                                const SizedBox(height: 16),
                                
                                TextFormField(
                                  controller: _emailController,
                                  readOnly: true,
                                  style: const TextStyle(color: Colors.grey),
                                  decoration: _buildInputDecoration('メールアドレス', Icons.email_outlined).copyWith(
                                    fillColor: Colors.grey[100], // ReadOnly感
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                
                                // 保存ボタン
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeColor,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text('変更を保存', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // メニューカード
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        color: Colors.white,
                        child: Column(
                          children: [
                            _buildMenuTile(
                              icon: Icons.history,
                              title: "レビュー履歴",
                              subtitle: "過去に投稿したレビューを確認・編集",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ReviewHistoryScreen()),
                                );
                              },
                            ),
                            // 今後、他のメニュー（通知設定など）が増えたらここに追加
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // アイコンピッカー
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                  : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // メニュー項目ウィジェット
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: themeColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}