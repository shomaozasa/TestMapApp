import 'dart:io';
import 'package:flutter/foundation.dart'; // ★ kIsWeb用
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:google_map_app/core/models/business_user_model.dart';
import 'package:google_map_app/features/_authentication/presentation/screens/login_screen.dart';
import 'package:google_map_app/features/_authentication/presentation/screens/registration_confirm_screen.dart';

class BusinessUserSignupScreen extends StatefulWidget {
  const BusinessUserSignupScreen({super.key});

  @override
  State<BusinessUserSignupScreen> createState() => _BusinessUserSignupScreenState();
}

class _BusinessUserSignupScreenState extends State<BusinessUserSignupScreen> {
  final _formKey = GlobalKey<FormState>();

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

  XFile? _iconImage; // ★ File -> XFileに変更
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    adminNameController.dispose();
    ownerNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    homepageController.dispose();
    xUrlController.dispose();
    instagramController.dispose();
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
          title: adminNameController.text.trim(),
          subtitle: "${ownerNameController.text.trim()} (代表)",
          themeColor: Colors.orange,
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
          final data = await _iconImage!.readAsBytes();
          await ref.putData(data, SettableMetadata(contentType: 'image/png'));
        } else {
          await ref.putFile(File(_iconImage!.path));
        }
        iconUrl = await ref.getDownloadURL();
      }

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
        description: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isAuth: false,
        isStoped: false,
      );

      await firestore.collection('businesses').doc(uid).set(newBusiness.toMap());

      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BusinessPendingScreen(uid: uid)),
        (route) => false,
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
      appBar: AppBar(title: const Text('事業者 新規登録')),
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
                    // ★ 修正: Web対応表示
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
              
              ElevatedButton(
                onPressed: _onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.orange,
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

// -------------------- 事業者認証待ち画面 --------------------
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

        // DBのフィールド名が 'is_auth' か 'isAuth' かに注意
        // 今回のモデルでは 'isAuth' として保存しているのでそちらを優先
        final isAuth = data['isAuth'] ?? false; 

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