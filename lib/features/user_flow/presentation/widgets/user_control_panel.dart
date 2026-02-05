import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/favorite_list_screen.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/user_profile_screen.dart';

class UserControlPanel extends StatelessWidget {
  /// 「閉じる」ボタンが押された時の処理
  final VoidCallback? onClose;
  
  /// 「検索」ボタンが押された時の処理
  /// (指定しない場合は「マップ画面で検索してください」と表示)
  final VoidCallback? onSearch;

  const UserControlPanel({
    super.key,
    this.onClose,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFCDE8F6).withOpacity(0.95),
        borderRadius: BorderRadius.circular(35),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. 閉じるボタン
          _buildCircleButton(
            icon: Icons.close,
            onPressed: onClose ?? () => Navigator.pop(context), // 指定なければ戻る
          ),
          
          // 2. お気に入り (共通遷移)
          _buildCircleButton(
            icon: Icons.store_mall_directory_outlined,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoriteListScreen()),
            ),
          ),
          
          // 3. プロフィール (共通遷移)
          _buildCircleButton(
            icon: Icons.person_outline,
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfileScreen(userId: user.uid),
                  ),
                );
              }
            },
          ),
          
          // 4. 検索ボタン
          _buildCircleButton(
            icon: Icons.search,
            onPressed: onSearch ?? () {
              // デフォルトの挙動: スナックバー表示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('マップ画面で検索してください')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 28),
      ),
    );
  }
}