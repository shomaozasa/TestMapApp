import 'package:flutter/material.dart';

class TwoFactorAuthPage extends StatefulWidget {
  const TwoFactorAuthPage({Key? key}) : super(key: key);

  @override
  State<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  bool _isEnabled = false;
  String _method = "sms"; // sms / email
  final _codeController = TextEditingController();

  void _verifyCode() {
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("6桁の認証コードを入力してください")),
      );
      return;
    }

    setState(() {
      _isEnabled = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("二段階認証を有効にしました")),
    );
  }

  void _disable2FA() {
    setState(() {
      _isEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("二段階認証を無効にしました")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: const Text("二段階認証"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statusCard(),
            const SizedBox(height: 20),

            if (!_isEnabled) ...[
              _methodSelector(),
              const SizedBox(height: 20),
              _codeInput(),
              const SizedBox(height: 24),
              _enableButton(),
            ] else ...[
              _disableButton(),
            ],
          ],
        ),
      ),
    );
  }

  // ===== 状態表示 =====
  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isEnabled ? Icons.verified_user : Icons.warning,
            color: _isEnabled ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEnabled
                  ? "二段階認証は有効です"
                  : "二段階認証は無効です",
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ===== 認証方法選択 =====
  Widget _methodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "認証方法",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          RadioListTile<String>(
            value: "sms",
            groupValue: _method,
            title: const Text("SMS（電話番号）"),
            onChanged: (v) => setState(() => _method = v!),
          ),

          RadioListTile<String>(
            value: "email",
            groupValue: _method,
            title: const Text("メール"),
            onChanged: (v) => setState(() => _method = v!),
          ),
        ],
      ),
    );
  }

  // ===== コード入力 =====
  Widget _codeInput() {
    return TextField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: "認証コード（6桁）",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ===== 有効化 =====
  Widget _enableButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _verifyCode,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text("有効にする"),
      ),
    );
  }

  // ===== 無効化 =====
  Widget _disableButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _disable2FA,
        child: const Text("二段階認証を無効にする"),
      ),
    );
  }
}
