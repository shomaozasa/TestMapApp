import 'package:flutter/material.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({Key? key}) : super(key: key);

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _confirmDelete() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("パスワードを入力してください")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("最終確認"),
        content: const Text(
          "アカウントを削除すると、すべてのデータが完全に削除されます。\n\n本当に削除しますか？",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("キャンセル"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: _deleteAccount,
            child: const Text("削除する"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    Navigator.pop(context);
    setState(() => _isLoading = true);

    // 本来はここでAPI / Firebase Auth を呼ぶ
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("アカウントを削除しました")),
    );

    // 本来はログイン画面へ
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("アカウント削除"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _warningBox(),
            const SizedBox(height: 24),

            const Text(
              "確認のため、現在のパスワードを入力してください",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "パスワード",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _confirmDelete,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("アカウントを削除する"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: const [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "この操作は取り消せません。\n投稿・設定・履歴など、すべて削除されます。",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
