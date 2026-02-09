import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:google_map_app/core/models/user_model.dart';
import 'package:google_map_app/features/_authentication/presentation/screens/login_screen.dart';
import 'package:google_map_app/features/_authentication/presentation/screens/registration_confirm_screen.dart';

class UserSignupScreen extends StatefulWidget {
  const UserSignupScreen({super.key});

  @override
  State<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends State<UserSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  XFile? _iconImage;
  final ImagePicker _picker = ImagePicker();
  
  bool _isObscure = true; // パスワード表示用

  // テーマカラー（青）
  static const Color themeColor = Color(0xFF4A90E2);
  static const Color gradientStart = Color(0xFFE3F2FD); // 薄い青
  static const Color gradientEnd = Color(0xFFBBDEFB);   // 少し濃い青

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) setState(() => _iconImage = pickedFile);
  }

  void _onRegisterPressed() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationConfirmScreen(
          imageFile: _iconImage,
          title: userNameController.text.trim(),
          subtitle: emailController.text.trim(),
          themeColor: themeColor,
          onConfirm: _performRegistration,
        ),
      ),
    );
  }

  Future<void> _performRegistration() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    String? iconUrl;

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final uid = userCredential.user!.uid;

      if (_iconImage != null) {
        final ref = storage.ref().child('user_icons/$uid.png');
        if (kIsWeb) {
          final data = await _iconImage!.readAsBytes();
          await ref.putData(data, SettableMetadata(contentType: 'image/png'));
        } else {
          await ref.putFile(File(_iconImage!.path));
        }
        iconUrl = await ref.getDownloadURL();
      }

      final newUser = UserModel(
        userId: uid,
        userName: userNameController.text.trim(),
        email: emailController.text.trim(),
        iconImage: iconUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        violated: 0,
        isStoped: false,
        isAuth: false,
      );

      await firestore.collection('users').doc(uid).set(newUser.toMap());

      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登録が完了しました。ログインしてください。')),
      );

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録失敗: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // 共通のInputDecoration (おしゃれ版)
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: Icon(icon, color: themeColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: themeColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('利用者登録', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        // ★ 修正: ここで画面サイズいっぱいに広げる指定を追加
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
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // 画像選択エリア
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: themeColor.withOpacity(0.3), width: 3),
                              ),
                              child: CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage: _iconImage != null 
                                    ? (kIsWeb 
                                        ? NetworkImage(_iconImage!.path) 
                                        : FileImage(File(_iconImage!.path)) as ImageProvider)
                                    : null,
                                child: _iconImage == null
                                    ? Icon(Icons.person, size: 60, color: Colors.grey.shade300)
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
                      ),
                      const SizedBox(height: 12),
                      const Text('プロフィール画像', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      
                      const SizedBox(height: 30),
                      
                      // 入力フォーム
                      TextFormField(
                        controller: userNameController,
                        decoration: _buildInputDecoration('ユーザー名', Icons.person_outline),
                        validator: (v) => v == null || v.isEmpty ? 'ユーザー名を入力してください' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration('メールアドレス', Icons.email_outlined),
                        validator: (v) => v == null || v.isEmpty ? 'メールを入力してください' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: _isObscure,
                        decoration: _buildInputDecoration('パスワード (8文字以上)', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                            onPressed: () => setState(() => _isObscure = !_isObscure),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.length < 8 ? 'パスワードは8文字以上必要です' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: _isObscure,
                        decoration: _buildInputDecoration('パスワード確認', Icons.check_circle_outline),
                        validator: (v) =>
                            v != passwordController.text ? 'パスワードが一致しません' : null,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(27),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _onRegisterPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          child: const Text('登録確認へ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}