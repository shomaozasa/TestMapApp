import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
// ★ 作成したモデルをインポート
import 'package:google_map_app/core/models/business_user_model.dart';
// ★ ログイン画面への遷移用
import 'package:google_map_app/login.dart';

class BusinessUserSignupScreen extends StatefulWidget {
  const BusinessUserSignupScreen({super.key});

  @override
  State<BusinessUserSignupScreen> createState() => _BusinessUserSignupScreenState();
}

class _BusinessUserSignupScreenState extends State<BusinessUserSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? category;
  final TextEditingController homepageController = TextEditingController();
  final TextEditingController xUrlController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();

  File? _iconImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
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
      final newBusiness = BusinessUserModel(
        adminId: uid,
        adminName: adminNameController.text.trim(),
        ownerName: ownerNameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        adminCategory: category ?? 'その他',
        homepage: homepageController.text.trim(),
        xUrl: xUrlController.text.trim(),
        instagramUrl: instagramController.text.trim(),
        iconImage: iconUrl,
        description: '', // 初期値は空でOK
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAuth: false, // 認証待ちはfalse
        isStoped: false,
      );

      // 4. Firestoreへの保存 (モデルのtoMapを使用)
      await firestore.collection('businesses').doc(uid).set(newBusiness.toMap());

      if (!mounted) return;
      
      // 認証待ち画面へ遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => BusinessPendingScreen(uid: uid)),
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
      appBar: AppBar(title: const Text('事業者 新規登録')),
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
                    const Text('店舗ロゴ・アイコン', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: adminNameController,
                      decoration: const InputDecoration(labelText: '事業者名 (必須)'),
                      validator: (v) => v == null || v.isEmpty ? '事業者名を入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: ownerNameController,
                      decoration: const InputDecoration(labelText: '代表者名 (必須)'),
                      validator: (v) => v == null || v.isEmpty ? '代表者名を入力してください' : null,
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: '電話番号 (必須)'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.isEmpty ? '電話番号を入力してください' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: const [
                        DropdownMenuItem(value: '美容系', child: Text('美容系')),
                        DropdownMenuItem(value: '修理業', child: Text('修理業')),
                        DropdownMenuItem(value: '飲食業', child: Text('飲食業')),
                        DropdownMenuItem(value: 'その他', child: Text('その他')),
                      ],
                      decoration: const InputDecoration(labelText: '事業者カテゴリ (必須)'),
                      onChanged: (v) => setState(() => category = v),
                      validator: (v) => v == null ? 'カテゴリを選択してください' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: homepageController,
                      decoration: const InputDecoration(labelText: 'ホームページURL (任意)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: xUrlController,
                      decoration: const InputDecoration(labelText: 'X URL (任意)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: instagramController,
                      decoration: const InputDecoration(labelText: 'Instagram URL (任意)'),
                    ),
                    const SizedBox(height: 32),
                    
                    // 登録ボタン
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('申請して登録'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// -------------------- 事業者認証待ち画面 --------------------
// 事業者登録フローの一部なので、ここに配置しています
class BusinessPendingScreen extends StatelessWidget {
  final String uid;
  const BusinessPendingScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final docStream = FirebaseFirestore.instance
        .collection('businesses')
        .doc(uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: docStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
           return const Scaffold(body: Center(child: Text("データが見つかりません")));
        }

        final isAuth = data['is_auth'] ?? false;

        // 認証が完了したらログイン画面へ自動遷移
        if (isAuth) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(title: const Text('認証待ち')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock, size: 80, color: Colors.orange),
                  SizedBox(height: 24),
                  Text(
                    '🔒 アカウント認証待ち',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '管理者があなたの事業者アカウントを確認しています。\n認証が完了すると自動でログイン画面へ遷移します。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}