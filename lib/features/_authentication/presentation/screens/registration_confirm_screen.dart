import 'dart:io';
import 'package:flutter/foundation.dart'; // ★ kIsWeb用
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // ★ XFile用

class RegistrationConfirmScreen extends StatefulWidget {
  final XFile? imageFile; // ★ File -> XFileに変更
  final String title;
  final String subtitle;
  final Future<void> Function() onConfirm;
  final Color themeColor;

  const RegistrationConfirmScreen({
    super.key,
    required this.imageFile,
    required this.title,
    required this.subtitle,
    required this.onConfirm,
    this.themeColor = Colors.blue,
  });

  @override
  State<RegistrationConfirmScreen> createState() => _RegistrationConfirmScreenState();
}

class _RegistrationConfirmScreenState extends State<RegistrationConfirmScreen> {
  bool _isLoading = false;

  void _handleConfirm() async {
    setState(() => _isLoading = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ★ 画像プロバイダーをWeb/Mobileで切り替えるメソッド
  ImageProvider? _getImageProvider() {
    if (widget.imageFile == null) return null;
    
    if (kIsWeb) {
      // Webの場合: image_pickerのpathはBlob URLになっているためNetworkImageで表示可能
      return NetworkImage(widget.imageFile!.path);
    } else {
      // Mobileの場合: ファイルシステムから読み込む
      return FileImage(File(widget.imageFile!.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("登録処理中..."),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "こちらで登録しますか？",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),

                      // アイコン画像
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.grey.shade300,
                          // ★ 修正: 切り替えたプロバイダーを使用
                          backgroundImage: _getImageProvider(),
                          child: widget.imageFile == null
                              ? Icon(Icons.person, size: 80, color: Colors.grey.shade400)
                              : null,
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 60),

                      Container(
                        width: 200,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.themeColor.withOpacity(0.4),
                              widget.themeColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: widget.themeColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _handleConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "はい！",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: 200,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            "だめ！",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}