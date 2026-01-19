import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({Key? key}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  File? headerImage;
  File? iconImage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickHeaderImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        headerImage = File(picked.path);
      });
    }
  }

  Future<void> _pickIconImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        iconImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0F8),
      appBar: AppBar(
        title: const Text("プロフィール編集"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== ヘッダープレビュー =====
            GestureDetector(
              onTap: _pickHeaderImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.grey[300],
                  image: headerImage != null
                      ? DecorationImage(
                          image: FileImage(headerImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: headerImage == null
                    ? const Center(child: Text("タップしてヘッダー画像を選択"))
                    : null,
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -40),
              child: Center(
                child: GestureDetector(
                  onTap: _pickIconImage,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        iconImage != null ? FileImage(iconImage!) : null,
                    child: iconImage == null
                        ? const Icon(Icons.camera_alt)
                        : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// ===== 保存 =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    {
                      "headerImage": headerImage,
                      "iconImage": iconImage,
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text("保存"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
