import 'dart:io';
import 'package:flutter/foundation.dart'; // ★ kIsWeb用
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

  XFile? _iconImage; // ★ File -> XFile に変更
  final ImagePicker _picker = ImagePicker();

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
    // ★ そのままXFileを保持
    if (pickedFile != null) setState(() => _iconImage = pickedFile);
  }

  void _onRegisterPressed() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrationConfirmScreen(
          imageFile: _iconImage, // XFileを渡す
          title: userNameController.text.trim(),
          subtitle: emailController.text.trim(),
          themeColor: Colors.blue,
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

      // ★ 修正: 画像アップロード (Web/Mobile分岐)
      if (_iconImage != null) {
        final ref = storage.ref().child('user_icons/$uid.png');
        if (kIsWeb) {
          // Web: バイトデータとしてアップロード
          final data = await _iconImage!.readAsBytes();
          await ref.putData(data, SettableMetadata(contentType: 'image/png'));
        } else {
          // Mobile: ファイルパスからアップロード
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用者 新規登録')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    // ★ 修正: Web対応の表示ロジック
                    backgroundImage: _iconImage != null 
                        ? (kIsWeb 
                            ? NetworkImage(_iconImage!.path) 
                            : FileImage(File(_iconImage!.path)) as ImageProvider)
                        : null,
                    child: _iconImage == null
                        ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                        : null,
                  ),
                ),
              ),
              // ... (以下のフォーム部分は変更なし) ...
              const SizedBox(height: 8),
              const Text('プロフィール画像', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: userNameController,
                decoration: const InputDecoration(labelText: 'ユーザー名 (必須)'),
                validator: (v) => v == null || v.isEmpty ? 'ユーザー名を入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス (必須)'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'メールを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'パスワード (8文字以上)'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.length < 8 ? 'パスワードは8文字以上必要です' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(labelText: 'パスワード確認'),
                obscureText: true,
                validator: (v) =>
                    v != passwordController.text ? 'パスワードが一致しません' : null,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('登録確認へ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}