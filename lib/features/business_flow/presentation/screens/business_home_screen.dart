import 'package:flutter/material.dart';
// ★ 遷移先の画面（BusinessMapScreen）をインポートします
import 'package:google_map_app/features/business_flow/presentation/screens/business_map_screen.dart';
// (もし↑のパスでエラーが出る場合は、相対パスをお試しください)
// import 'business_map_screen.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事業者ホーム（ダッシュボード）'),
        backgroundColor: Colors.indigo.shade50,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              'ようこそ、事業者様',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 40),

            // --- ★ ここを修正します ---
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt),
              label: const Text('イベントを登録する (マップ)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                // ★ 画面遷移のロジックをここに追加
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // BusinessMapScreen（インポートした画面）に遷移
                    builder: (context) => const BusinessMapScreen(),
                  ),
                );
              },
            ),
            // --- 修正ここまで ---

            const SizedBox(height: 20),
            // TODO: 他のメニューボタン（例：過去のイベント一覧など）
          ],
        ),
      ),
    );
  }
}