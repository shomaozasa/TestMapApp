import 'package:flutter/material.dart';

class CustomBottomBar extends StatefulWidget {
  final VoidCallback? onMapTap;
  final VoidCallback? onProfileTap;

  const CustomBottomBar({
    super.key,
    this.onMapTap,
    this.onProfileTap,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90, // ← ★これが超重要
      child: SafeArea(
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isExpanded ? 320 : 220,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFD8ECFF),
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// ☰ / ✕
                _circleButton(
                  icon: _isExpanded ? Icons.close : Icons.menu,
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),

                /// ⭐
                if (_isExpanded)
                  _circleButton(
                    icon: Icons.star_border,
                    onTap: () {
                      // お気に入り画面
                    },
                  ),

                /// ● 中央
                _circleButton(
                  icon: Icons.circle,
                  size: 22,
                  onTap: widget.onMapTap,
                ),

                /// 👤
                if (_isExpanded)
                  _circleButton(
                    icon: Icons.person_outline,
                    onTap: widget.onProfileTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    VoidCallback? onTap,
    double size = 26,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size),
      ),
    );
  }
}
