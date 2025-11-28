import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// -------------------- ログインフォーム --------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      final userCredential = await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = userCredential.user!.uid;

      // 利用者チェック
      var userDoc = await firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final isStopped = data['is_stoped'] ?? false;
        final violated = data['violated'] ?? 0;

        if (isStopped || violated >= 10) {
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'アカウントが停止されています',
          );
        }

        // 利用者ホームへ
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
        );
        return;
      }

      // 事業者チェック
      var businessDoc = await firestore.collection('businesses').doc(uid).get();
      if (businessDoc.exists) {
        final data = businessDoc.data()!;
        final isAuth = data['is_auth'] ?? false;
        final isStopped = data['is_stoped'] ?? false;

        if (isStopped) {
          throw FirebaseAuthException(
            code: 'user-disabled',
            message: 'アカウントが停止されています',
          );
        }

        if (!isAuth) {
          // 事業者認証待ち画面へ
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BusinessAuthPendingScreen()),
          );
          return;
        }

        // 認証済みなら事業者ホームへ
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BusinessHomeScreen()),
        );
        return;
      }

      // どちらにも存在しない場合
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'ユーザーデータが存在しません',
      );
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
      appBar: AppBar(title: const Text('ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'メールアドレスを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'パスワードを入力してください' : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
                    );
                  },
                  child: const Text('パスワードを忘れた場合'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ログイン', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- パスワードリセット --------------------
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final TextEditingController emailController = TextEditingController();
  bool _isSending = false;

  Future<void> _sendResetEmail() async {
    if (emailController.text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リセットメールを送信しました')),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('送信失敗: ${e.message}')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('パスワードリセット')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('登録済みメールアドレスを入力してください',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSending ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('送信', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- 認証待ち画面 --------------------
class BusinessAuthPendingScreen extends StatelessWidget {
  const BusinessAuthPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('認証待ち')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              SizedBox(height: 24),
              Text(
                '事業者認証が完了していません。\n管理者による承認をお待ちください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 40),
              Text('ログアウトして戻る', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- ホーム画面 --------------------
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
