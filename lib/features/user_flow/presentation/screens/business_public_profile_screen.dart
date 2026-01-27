import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/business_user_model.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart'; // ★追加
import 'package:firebase_auth/firebase_auth.dart'; // ★追加

class BusinessPublicProfileScreen extends StatelessWidget {
  final String adminId;
  final FirestoreService _firestoreService = FirestoreService(); // ★追加

  BusinessPublicProfileScreen({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('事業者プロフィール'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          // // ★ フォローボタンをAppBarにも追加
          // StreamBuilder<bool>(
          //   stream: _firestoreService.isBusinessFollowedStream(adminId),
          //   builder: (context, snapshot) {
          //     final isFollowed = snapshot.data ?? false;
          //     return IconButton(
          //       icon: Icon(
          //         isFollowed ? Icons.favorite : Icons.favorite_border,
          //         color: isFollowed ? Colors.red : Colors.grey,
          //       ),
          //       onPressed: () async {
          //         final user = FirebaseAuth.instance.currentUser;
          //         if (user != null) {
          //           await _firestoreService.toggleFollowBusiness(adminId);
          //         } else {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(content: Text('フォローするにはログインが必要です')),
          //           );
          //         }
          //       },
          //     );
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBusinessInfo(context),
            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
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

  Widget _buildBusinessInfo(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('businesses')
          .doc(adminId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("事業者データが見つかりません"),
          );
        }

        final business = BusinessUserModel.fromFirestore(snapshot.data!);

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    (business.iconImage != null &&
                        business.iconImage!.isNotEmpty)
                    ? NetworkImage(business.iconImage!)
                    : null,
                child:
                    (business.iconImage == null || business.iconImage!.isEmpty)
                    ? const Icon(Icons.store, size: 50, color: Colors.grey)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                business.adminName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // ★ 大きなフォローボタン
              StreamBuilder<bool>(
                stream: _firestoreService.isBusinessFollowedStream(adminId),
                builder: (context, snapshot) {
                  final isFollowed = snapshot.data ?? false;
                  return ElevatedButton.icon(
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await _firestoreService.toggleFollowBusiness(adminId);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowed
                          ? Colors.white
                          : Colors.orange,
                      foregroundColor: isFollowed
                          ? Colors.orange
                          : Colors.white,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: Icon(isFollowed ? Icons.check : Icons.add),
                    label: Text(isFollowed ? 'フォロー中' : 'フォローする'),
                  );
                },
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  business.adminCategory,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (business.description.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    business.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildInfoRow(Icons.language, business.homepage, 'ホームページ'),
              _buildInfoRow(
                Icons.alternate_email,
                business.instagramUrl,
                'Instagram',
              ),
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
              value,
              style: const TextStyle(fontSize: 14, color: Colors.blue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('adminId', isEqualTo: adminId)
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
            child: Text(
              '現在登録されているイベントはありません。',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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
                  child: event.eventImage.isEmpty
                      ? const Icon(Icons.event)
                      : null,
                ),
                title: Text(
                  event.eventName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
