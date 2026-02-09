import 'dart:io';
import 'package:flutter/foundation.dart';
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

  XFile? _iconImage;
  final ImagePicker _picker = ImagePicker();
  
  bool _isObscure = true;
  
  // テーマカラー（オレンジ）
  static const Color themeColor = Color(0xFFFF9800);
  static const Color gradientStart = Color(0xFFFFF3E0); // 薄いオレンジ
  static const Color gradientEnd = Color(0xFFFFE0B2);   // 少し濃いオレンジ

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
          themeColor: themeColor,
          onConfirm: _performRegistration,
        ),
      ),
    );
  }

  Future<void> _performRegistration() async {
    // ... (ロジックは変更なし) ...
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

  // 共通スタイル (おしゃれ版)
  InputDecoration _buildInputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: themeColor) : null,
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

  // セクションヘッダー (おしゃれ版)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: themeColor), // アクセントライン
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('事業者 新規登録', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // 画像エリア
                      Center(
                        child: GestureDetector(
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
                                  radius: 50,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: _iconImage != null 
                                      ? (kIsWeb 
                                          ? NetworkImage(_iconImage!.path) 
                                          : FileImage(File(_iconImage!.path)) as ImageProvider)
                                      : null,
                                  child: _iconImage == null
                                      ? Icon(Icons.store, size: 50, color: Colors.grey.shade300)
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
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(child: Text('店舗ロゴ・アイコン', style: TextStyle(color: Colors.grey, fontSize: 12))),

                      // 基本情報セクション
                      _buildSectionHeader('アカウント情報'),
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
                        validator: (v) => v == null || v.length < 8 ? 'パスワードは8文字以上必要です' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: _isObscure,
                        decoration: _buildInputDecoration('パスワード確認', Icons.check_circle_outline),
                        validator: (v) => v != passwordController.text ? 'パスワードが一致しません' : null,
                      ),

                      // 店舗詳細セクション
                      _buildSectionHeader('店舗・事業者情報'),
                      TextFormField(
                        controller: adminNameController,
                        decoration: _buildInputDecoration('事業者名 (店舗名)', Icons.store_mall_directory_outlined),
                        validator: (v) => v == null || v.isEmpty ? '事業者名を入力してください' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: ownerNameController,
                        decoration: _buildInputDecoration('代表者名', Icons.person_outline),
                        validator: (v) => v == null || v.isEmpty ? '代表者名を入力してください' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration('電話番号', Icons.phone_outlined),
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
                        decoration: _buildInputDecoration('事業者カテゴリ', Icons.category_outlined),
                        onChanged: (v) => setState(() => category = v),
                        validator: (v) => v == null ? 'カテゴリを選択してください' : null,
                      ),

                      // リンク情報セクション
                      _buildSectionHeader('リンク (任意)'),
                      TextFormField(
                        controller: homepageController,
                        decoration: _buildInputDecoration('ホームページURL', Icons.language),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: xUrlController,
                        decoration: _buildInputDecoration('X URL', Icons.link),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: instagramController,
                        decoration: _buildInputDecoration('Instagram URL', Icons.camera_alt_outlined),
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

// -------------------- 事業者認証待ち画面 (変更なし) --------------------
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