import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

// ホーム画面ダミー
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ホーム')),
      body: const Center(child: Text('ホーム画面')),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Map App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SignUpScreen(),
    );
  }
}

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
                  builder: (context) => UserTypeRegisterScreen(userType: userType),
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
            ElevatedButton(
              onPressed: () => _showConfirmationDialog(context, '事業者'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('事業者として始める'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showConfirmationDialog(context, '利用者'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('利用者として始める'),
            ),
          ],
        ),
      ),
    );
  }
}

class UserTypeRegisterScreen extends StatefulWidget {
  final String userType;
  const UserTypeRegisterScreen({super.key, required this.userType});

  @override
  State<UserTypeRegisterScreen> createState() => _UserTypeRegisterScreenState();
}

class _UserTypeRegisterScreenState extends State<UserTypeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 利用者フォーム
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // 事業者フォーム
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController representativeNameController = TextEditingController();
  final TextEditingController homepageController = TextEditingController();
  final TextEditingController xUrlController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String? category;

  File? _iconImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _iconImage = File(pickedFile.path);
      });
    }
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
              widget.userType == '利用者' ? _buildUserForm() : _buildBusinessForm(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfirmScreen(
                          userType: widget.userType,
                          username: usernameController.text.trim(),
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          iconImage: _iconImage,
                          businessName: businessNameController.text.trim(),
                          representativeName: representativeNameController.text.trim(),
                          homepage: homepageController.text.trim(),
                          xUrl: xUrlController.text.trim(),
                          instagram: instagramController.text.trim(),
                          phone: phoneController.text.trim(),
                          category: category,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('入力内容確認'),
              ),
            ],
          ),
        ),
      ),
    );
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
          controller: usernameController,
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
          decoration: const InputDecoration(labelText: 'パスワード'),
          obscureText: true,
          validator: (v) => v == null || v.isEmpty ? 'パスワードを入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          decoration: const InputDecoration(labelText: 'パスワード確認'),
          obscureText: true,
          validator: (v) => v == null || v.isEmpty ? '確認用パスワードを入力してください' : null,
        ),
      ],
    );
  }

  Widget _buildBusinessForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: businessNameController,
          decoration: const InputDecoration(labelText: '事業者名（必須）'),
          validator: (v) => v == null || v.isEmpty ? '事業者名を入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'メールアドレス（必須）'),
          validator: (v) => v == null || v.isEmpty ? 'メールアドレスを入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(labelText: '電話番号（必須）'),
          validator: (v) => v == null || v.isEmpty ? '電話番号を入力してください' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          items: const [
            DropdownMenuItem(value: '美容系', child: Text('美容系')),
            DropdownMenuItem(value: '修理業', child: Text('修理業')),
            DropdownMenuItem(value: '飲食業', child: Text('飲食業')),
            DropdownMenuItem(value: 'その他', child: Text('その他')),
          ],
          decoration: const InputDecoration(labelText: '業者カテゴリ（必須）'),
          onChanged: (value) => category = value,
          validator: (v) => v == null ? 'カテゴリを選択してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: representativeNameController,
          decoration: const InputDecoration(labelText: '代表者名（必須）'),
          validator: (v) => v == null || v.isEmpty ? '代表者名を入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'パスワード（必須）'),
          obscureText: true,
          validator: (v) => v == null || v.isEmpty ? 'パスワードを入力してください' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          decoration: const InputDecoration(labelText: 'パスワード確認（必須）'),
          obscureText: true,
          validator: (v) => v == null || v.isEmpty ? '確認用パスワードを入力してください' : null,
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
}

// 確認画面
class ConfirmScreen extends StatelessWidget {
  final String userType;
  final String username;
  final String email;
  final String password;
  final File? iconImage;

  final String businessName;
  final String representativeName;
  final String homepage;
  final String xUrl;
  final String instagram;
  final String phone;
  final String? category;

  const ConfirmScreen({
    super.key,
    required this.userType,
    required this.username,
    required this.email,
    required this.password,
    this.iconImage,
    this.businessName = '',
    this.representativeName = '',
    this.homepage = '',
    this.xUrl = '',
    this.instagram = '',
    this.phone = '',
    this.category,
  });

  Future<bool> _registerUser(BuildContext context) async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final storage = FirebaseStorage.instance;

      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      String? iconUrl;
      if (iconImage != null) {
        final ref = storage.ref().child('user_icons/$uid.png');
        await ref.putFile(iconImage!);
        iconUrl = await ref.getDownloadURL();
      }

      if (userType == '利用者') {
        await firestore.collection('users').doc(uid).set({
          'username': username,
          'email': email,
          'userType': userType,
          'iconUrl': iconUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'violationCount': 0,
          'suspended': false,
          'emailVerified': false,
        });
      } else {
        await firestore.collection('users').doc(uid).set({
          'businessName': businessName,
          'email': email,
          'phone': phone,
          'category': category ?? '',
          'representativeName': representativeName,
          'homepage': homepage,
          'xUrl': xUrl,
          'instagramUrl': instagram,
          'userType': userType,
          'iconUrl': iconUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'verified': false,
          'suspended': false,
        });
      }

      return true;
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登録失敗: ${e.message}')),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('入力内容確認')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (iconImage != null)
              CircleAvatar(radius: 50, backgroundImage: FileImage(iconImage!)),
            const SizedBox(height: 16),
            if (userType == '利用者') ...[
              ListTile(title: const Text('ユーザー名'), subtitle: Text(username)),
              ListTile(title: const Text('メール'), subtitle: Text(email)),
            ] else ...[
              ListTile(title: const Text('事業者名'), subtitle: Text(businessName)),
              ListTile(title: const Text('メール'), subtitle: Text(email)),
              ListTile(title: const Text('電話'), subtitle: Text(phone)),
              ListTile(title: const Text('カテゴリ'), subtitle: Text(category ?? '')),
              ListTile(title: const Text('代表者名'), subtitle: Text(representativeName)),
              ListTile(title: const Text('ホームページ'), subtitle: Text(homepage)),
              ListTile(title: const Text('X URL'), subtitle: Text(xUrl)),
              ListTile(title: const Text('Instagram URL'), subtitle: Text(instagram)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('戻る')),
                ElevatedButton(
                  onPressed: () async {
                    bool success = await _registerUser(context);
                    if (success) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  },
                  child: const Text('登録'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
