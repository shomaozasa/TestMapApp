import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// -------------------- ログイン画面選択 --------------------
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
              'どちらでログインしますか？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _showLoginTypeDialog(context, '事業者'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('事業者でログイン'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showLoginTypeDialog(context, '利用者'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('利用者でログイン'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- ログインフォーム --------------------
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

      final collection = widget.userType == '利用者' ? 'users' : 'businesses';
      final doc = await FirebaseFirestore.instance.collection(collection).doc(uid).get();
      final data = doc.data();
      if (data == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'ユーザーデータが存在しません');
      }

      final isAuth = data['is_auth'] ?? false;
      final isStopped = data['is_stoped'] ?? false;
      final violated = data['violated'] ?? 0;

      if (isStopped || (widget.userType == '利用者' && violated >= 10)) {
        throw FirebaseAuthException(code: 'user-disabled', message: 'アカウントが停止されています');
      }

      if (!isAuth) {
        if (widget.userType == '事業者') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const BusinessAuthPendingScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserAuthPendingScreen()),
          );
        }
        return;
      }

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
                validator: (v) => v == null || v.isEmpty ? 'メールアドレスを入力してください' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                validator: (v) => v == null || v.isEmpty ? 'パスワードを入力してください' : null,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PasswordResetScreen(),
                      ),
                    );
                  },
                  child: const Text('パスワードを忘れた場合'),
                ),
              ),
              const SizedBox(height: 16),
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
            const Text(
              '登録済みメールアドレスを入力してください',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSending ? null : _sendResetEmail,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('送信'),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- 認証待ち画面 --------------------
class UserAuthPendingScreen extends StatelessWidget {
  const UserAuthPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('認証待ち')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'メール認証が完了していません。\nメールを確認してください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            children: [
              const Icon(Icons.hourglass_top, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                '事業者認証が完了していません。\n管理者による承認をお待ちください。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
                child: const Text('ログアウトして戻る'),
              ),
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
