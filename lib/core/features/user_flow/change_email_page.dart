import 'package:flutter/material.dart';

class ChangeEmailPage extends StatefulWidget {
  const ChangeEmailPage({Key? key}) : super(key: key);

  @override
  State<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends State<ChangeEmailPage> {
  final _currentEmailController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _confirmEmailController = TextEditingController();

  bool _isLoading = false;

  void _changeEmail() async {
    final current = _currentEmailController.text.trim();
    final newEmail = _newEmailController.text.trim();
    final confirm = _confirmEmailController.text.trim();

    if (current.isEmpty || newEmail.isEmpty || confirm.isEmpty) {
      _showMessage("すべて入力してください");
      return;
    }

    if (!_isValidEmail(newEmail)) {
      _showMessage("正しいメールアドレスを入力してください");
      return;
    }

    if (newEmail != confirm) {
      _showMessage("新しいメールアドレスが一致しません");
      return;
    }

    setState(() => _isLoading = true);

    // 📩 本来はここでメール変更APIを呼ぶ
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("メールアドレスを変更しました")),
    );

    Navigator.pop(context);
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[\w\.-]+@[\w\.-]+\.\w+$',
    ).hasMatch(email);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("メールアドレス変更"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _emailField(
              label: "現在のメールアドレス",
              controller: _currentEmailController,
            ),
            const SizedBox(height: 16),

            _emailField(
              label: "新しいメールアドレス",
              controller: _newEmailController,
            ),
            const SizedBox(height: 16),

            _emailField(
              label: "新しいメールアドレス（確認）",
              controller: _confirmEmailController,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changeEmail,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("変更する"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailField({
    required String label,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
