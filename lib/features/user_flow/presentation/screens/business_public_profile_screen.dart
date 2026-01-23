import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/business_user_model.dart';
import 'package:google_map_app/core/models/event_model.dart';
// URLランチャーなどが将来必要になるかもしれませんが、今回は表示のみ実装します

class BusinessPublicProfileScreen extends StatelessWidget {
  final String adminId; // このIDを使ってデータを取得します

  const BusinessPublicProfileScreen({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事業者プロフィール'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. 事業者基本情報 ---
            _buildBusinessInfo(),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // --- 2. この事業者のイベント/予定一覧 ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                '開催予定のイベント',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildBusinessEvents(),
          ],
        ),
      ),
    );
  }

  // 事業者情報をFirestoreから取得して表示
  Widget _buildBusinessInfo() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('businesses').doc(adminId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(padding: EdgeInsets.all(20), child: Text("事業者データが見つかりません"));
        }

        final business = BusinessUserModel.fromFirestore(snapshot.data!);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // アイコン
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: (business.iconImage != null && business.iconImage!.isNotEmpty)
                    ? NetworkImage(business.iconImage!)
                    : null,
                child: (business.iconImage == null || business.iconImage!.isEmpty)
                    ? const Icon(Icons.store, size: 50, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              // 店舗名
              Text(
                business.adminName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // カテゴリタグ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  business.adminCategory,
                  style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              // 自己紹介
              if (business.description.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    business.description,
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // SNSリンクなどの情報（あれば表示）
              _buildInfoRow(Icons.language, business.homepage, 'ホームページ'),
              _buildInfoRow(Icons.alternate_email, business.instagramUrl, 'Instagram'),
              _buildInfoRow(Icons.phone, business.phoneNumber, '電話番号'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String value, String label) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value, // 本来はここをタップしてURLを開く処理などを入れます
              style: const TextStyle(fontSize: 14, color: Colors.blue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // この事業者のイベント一覧を表示
  Widget _buildBusinessEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('adminId', isEqualTo: adminId) // ★ adminIdでフィルタリング
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('現在登録されているイベントはありません。', style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // 全体スクロールに任せる
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final event = EventModel.fromFirestore(docs[index]);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                    image: event.eventImage.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(event.eventImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: event.eventImage.isEmpty ? const Icon(Icons.event) : null,
                ),
                title: Text(event.eventName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${event.eventTime}\n${event.address}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}