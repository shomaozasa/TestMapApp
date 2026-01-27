import 'package:flutter/material.dart';
import 'package:google_map_app/core/models/business_user_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';
import 'package:google_map_app/features/user_flow/presentation/screens/business_public_profile_screen.dart';

class FavoriteListScreen extends StatelessWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('フォロー中の事業者'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<BusinessUserModel>>(
        // ★ 変更: フォロー事業者一覧を取得
        stream: firestoreService.getFollowedBusinessesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final followedBusinesses = snapshot.data ?? [];

          if (followedBusinesses.isEmpty) {
            return const Center(child: Text('まだフォローしている事業者はいません'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: followedBusinesses.length,
            itemBuilder: (context, index) {
              final business = followedBusinesses[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (business.iconImage != null && business.iconImage!.isNotEmpty)
                        ? NetworkImage(business.iconImage!)
                        : null,
                    child: (business.iconImage == null || business.iconImage!.isEmpty)
                        ? const Icon(Icons.store, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    business.adminName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    business.adminCategory,
                    style: TextStyle(color: Colors.orange.shade800),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // プロフィールへ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BusinessPublicProfileScreen(adminId: business.adminId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(60, 30),
                    ),
                    child: const Text('見る', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BusinessPublicProfileScreen(adminId: business.adminId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}