import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showLoginTypeDialog(BuildContext context, String userType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$userTypeでログインします'),
        content: const Text('続行してもよろしいですか？'),
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
                  builder: (context) => LoginFormScreen(userType: userType),
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
      appBar: AppBar(title: const Text('ログイン')),
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
              onPressed: () => _showLoginTypeDialog(context, '事業者'),
              child: const Text('事業者でログイン'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showLoginTypeDialog(context, '利用者'),
              child: const Text('利用者でログイン'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginFormScreen extends StatefulWidget {
  final String userType;
  const LoginFormScreen({super.key, required this.userType});

  @override
  State<LoginFormScreen> createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = userCredential.user!.uid;

      // コレクションとフィールドを物理名称に合わせる
      final collection = widget.userType == '利用者' ? 'users' : 'businesses';
      final doc = await FirebaseFirestore.instance.collection(collection).doc(uid).get();
      final data = doc.data();
      if (data == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'ユーザーデータが存在しません');
      }

      if (widget.userType == '利用者') {
        final isStopped = data['is_stoped'] ?? false;
        final isAuth = data['is_auth'] ?? false;
        final violated = data['violated'] ?? 0;

        if (isStopped || violated >= 10) {
          throw FirebaseAuthException(code: 'user-disabled', message: 'アカウントが停止されています');
        }
        if (!isAuth) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メール認証が必要です')),
          );
          return;
        }
      } else {
        final isStopped = data['is_stoped'] ?? false;
        final isAuth = data['is_auth'] ?? false;

        if (isStopped) {
          throw FirebaseAuthException(code: 'user-disabled', message: 'アカウントが停止されています');
        }
        if (!isAuth) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('事業者認証が完了していません')),
          );
          return;
        }
      }

      // ホーム画面遷移
      if (!mounted) return;
      if (widget.userType == '事業者') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BusinessHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログイン失敗: ${e.message}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.userType} ログインフォーム')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'メールアドレスを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                validator: (value) =>
                    value == null || value.isEmpty ? 'パスワードを入力してください' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ログイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 利用者ホーム画面
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('利用者ホーム')),
      body: const Center(child: Text('利用者向けホーム画面です')),
    );
  }
}

// 事業者ホーム画面
class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('事業者ホーム')),
      body: const Center(child: Text('事業者向けホーム画面です')),
    );
  }
}
