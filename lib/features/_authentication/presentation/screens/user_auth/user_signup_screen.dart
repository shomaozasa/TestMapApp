import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
// ★ 作成したモデルをインポート
import 'package:google_map_app/core/models/user_model.dart';
// ★ ログイン画面への遷移用 (パスは環境に合わせて調整してください)
import 'package:google_map_app/login.dart'; 

class UserSignupScreen extends StatefulWidget {
  const UserSignupScreen({super.key});

  @override
  State<UserSignupScreen> createState() => _UserSignupScreenState();
}

class _UserSignupScreenState extends State<UserSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  File? _iconImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // 画像サイズ圧縮
    );
    if (pickedFile != null) setState(() => _iconImage = File(pickedFile.path));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    String? iconUrl;

    try {
      // 1. Authへの登録
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final uid = userCredential.user!.uid;

      // 2. 画像アップロード
      if (_iconImage != null) {
        final ref = storage.ref().child('user_icons/$uid.png');
        await ref.putFile(_iconImage!);
        iconUrl = await ref.getDownloadURL();
      }

      // 3. モデルの作成
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

      // 4. Firestoreへの保存 (モデルのtoMapを使用)
      await firestore.collection('users').doc(uid).set(newUser.toMap());

      if (!mounted) return;
      
      // 登録完了 -> ログイン画面へ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登録が完了しました。ログインしてください。')),
      );

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録失敗: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用者 新規登録')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // アイコン選択
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _iconImage != null ? FileImage(_iconImage!) : null,
                          child: _iconImage == null
                              ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('プロフィール画像', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    
                    // 入力フォーム
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
                    
                    // 登録ボタン
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('登録して始める'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}