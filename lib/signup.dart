import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'features/user_flow/presentation/screens/user_home_screen.dart';
import 'login.dart' hide UserHomeScreen;

// -------------------- サインアップ画面 --------------------
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  void _showConfirmationDialog(BuildContext context, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$userTypeで登録を始めます'),
        content: const Text('よろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserTypeRegisterScreen(userType: userType),
                ),
              );
            },
            child: const Text('はい'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アカウント登録')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'どちらで始めますか？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUserTypeButton(context, '事業者', Colors.orange),
                _buildUserTypeButton(context, '利用者', Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 丸ボタン＋ラベルの共通関数
  Widget _buildUserTypeButton(
    BuildContext context,
    String userType,
    Color color,
  ) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showConfirmationDialog(context, userType),
            child: SizedBox(
              width: 100,
              height: 100,
              child: Center(
                child: Text(
                  userType,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// -------------------- ユーザー種別ごとの登録画面 --------------------
class UserTypeRegisterScreen extends StatefulWidget {
  final String userType;
  const UserTypeRegisterScreen({super.key, required this.userType});

  @override
  State<UserTypeRegisterScreen> createState() => _UserTypeRegisterScreenState();
}

class _UserTypeRegisterScreenState extends State<UserTypeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 利用者用
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // 事業者用
  final TextEditingController adminNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
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
    );
    if (pickedFile != null) setState(() => _iconImage = File(pickedFile.path));
  }

  Widget _buildIconPicker() {
    return Center(
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
    );
  }

  Widget _buildUserForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: userNameController,
          decoration: const InputDecoration(labelText: 'ユーザー名'),
          validator: (v) => v == null || v.isEmpty ? 'ユーザー名を入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'メールアドレス'),
          validator: (v) => v == null || v.isEmpty ? 'メールを入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'パスワード(8文字以上)'),
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
      ],
    );
  }

  Widget _buildBusinessForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: adminNameController,
          decoration: const InputDecoration(labelText: '事業者名'),
          validator: (v) => v == null || v.isEmpty ? '事業者名を入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: ownerNameController,
          decoration: const InputDecoration(labelText: '代表者名'),
          validator: (v) => v == null || v.isEmpty ? '代表者名を入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'メールアドレス'),
          validator: (v) => v == null || v.isEmpty ? 'メールを入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'パスワード(8文字以上)'),
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
          decoration: const InputDecoration(labelText: '電話番号'),
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
          decoration: const InputDecoration(labelText: '事業者カテゴリ'),
          onChanged: (v) => setState(() => category = v),
          validator: (v) => v == null ? 'カテゴリを選択してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: homepageController,
          decoration: const InputDecoration(labelText: 'ホームページURL（任意）'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: xUrlController,
          decoration: const InputDecoration(labelText: 'X URL（任意）'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: instagramController,
          decoration: const InputDecoration(labelText: 'Instagram URL（任意）'),
        ),
      ],
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

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
        await ref.putFile(_iconImage!);
        iconUrl = await ref.getDownloadURL();
      }

      if (widget.userType == '利用者') {
        await firestore.collection('users').doc(uid).set({
          'user_id': uid,
          'user_name': userNameController.text.trim(),
          'password': passwordController.text,
          'icon_image': iconUrl,
          'email': emailController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'violated': 0,
          'is_stoped': false,
          'is_auth': false,
        });
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        await firestore.collection('businesses').doc(uid).set({
          'admin_id': uid,
          'admin_name': adminNameController.text.trim(),
          'owner_name': ownerNameController.text.trim(),
          'password': passwordController.text,
          'icon_image': iconUrl,
          'email': emailController.text.trim(),
          'phone_number': phoneController.text.trim(),
          'admin_category': category ?? '',
          'homepage': homepageController.text.trim(),
          'xUrl': xUrlController.text.trim(),
          'instagramUrl': instagramController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
          'is_auth': false,
          'is_stoped': false,
        });
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BusinessPendingScreen(uid: uid)),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('登録失敗: ${e.message}')));
    }
  }

  Future<void> _skipRegister() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.userType} 新規登録')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildIconPicker(),
              const SizedBox(height: 24),
              widget.userType == '利用者'
                  ? _buildUserForm()
                  : _buildBusinessForm(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('登録'),
              ),
              const SizedBox(height: 50),
              widget.userType == '利用者'
                  ? ElevatedButton(
                      onPressed: _skipRegister,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('登録をスキップ'),
                    )
                  : const SizedBox(height: 0),
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
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isAuth = data['is_auth'] ?? false;

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
                    '管理者があなたの事業者アカウントを確認しています。\n認証が完了すると自動で開始できます。',
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
