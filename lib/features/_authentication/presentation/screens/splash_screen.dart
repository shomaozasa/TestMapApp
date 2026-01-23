import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_map_app/features/_authentication/presentation/screens/signup_selection_screen.dart';
// ★ パス修正: ログイン画面の新しい場所を指定
import 'package:google_map_app/features/_authentication/presentation/screens/login_screen.dart';

// -------------------- スプラッシュ画面 --------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); 

    // 2秒後に画面遷移
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AccountCheckScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: RealisticECGPainter(_controller.value),
              );
            },
          ),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('image/logo.jpg', fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------- 心電図アニメーション (変更なし) --------------------
class RealisticECGPainter extends CustomPainter {
  final double progress;

  RealisticECGPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path = Path();
    double yCenter = size.height / 2;
    double waveLength = 120.0;
    double offset = progress * waveLength;

    path.moveTo(0, yCenter);

    for (double x = 0; x < size.width; x++) {
      double localX = (x + offset) % waveLength;
      double y = yCenter;
      
      // 心電図の波形計算
      if (localX < waveLength * 0.05) {
        y = yCenter;
      } else if (localX < waveLength * 0.10) {
        y = yCenter - 50;
      } else if (localX < waveLength * 0.15) {
        y = yCenter + 20;
      } else if (localX < waveLength * 0.20) {
        y = yCenter;
      } else if (localX < waveLength * 0.30) {
        y = yCenter + sin((localX - waveLength * 0.2) / (waveLength * 0.1) * pi) * 15;
      } else {
        y = yCenter;
      }

      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RealisticECGPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// -------------------- アカウント確認画面 --------------------
class AccountCheckScreen extends StatelessWidget {
  const AccountCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF90CAF9),
              Color(0xFFFFCC80),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('image/logo.jpg', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '街の今をみつけよう',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                const Text(
                  'みつけたい人も、みつけられたい人も。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpSelectionScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      '始める',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  // ★ 修正箇所: ここで新しい LoginScreen へ遷移
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'アカウントをお持ちの方はこちら',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange,
                      decoration: TextDecoration.underline,
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