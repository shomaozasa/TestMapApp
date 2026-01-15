import 'package:flutter/material.dart';
import 'package:google_map_app/core/features/user_flow/user_profile_page.dart';

class CustomBottomBar extends StatelessWidget {
  final VoidCallback onMapTap;

  const CustomBottomBar({
    super.key,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffd7eaff), Color(0xffb8dcff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ← 左アイコン（プロフィール）
          IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserProfilePage(),
                ),
              );
            },
          ),

          // → 右アイコン（マップ）
          IconButton(
            icon: const Icon(Icons.location_on, size: 32),
            onPressed: onMapTap,
          ),
        ],
      ),
    );
  }
}
