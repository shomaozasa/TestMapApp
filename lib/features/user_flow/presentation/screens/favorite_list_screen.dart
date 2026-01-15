import 'package:flutter/material.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/service/firestore_service.dart';

class FavoriteListScreen extends StatelessWidget {
  const FavoriteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('お気に入り一覧'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: StreamBuilder<List<EventModel>>(
        // FirestoreServiceに getFavoritesStream が実装されている前提です
        stream: firestoreService.getFavoritesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteEvents = snapshot.data ?? [];

          if (favoriteEvents.isEmpty) {
            return const Center(child: Text('お気に入りはまだありません'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteEvents.length,
            itemBuilder: (context, index) {
              final event = favoriteEvents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      image: event.eventImage.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(event.eventImage),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: event.eventImage.isEmpty
                        ? const Icon(Icons.image, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    event.eventName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(event.eventTime, style: const TextStyle(fontSize: 12)),
                      Text(
                        event.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      // 一覧画面からも削除可能
                      await firestoreService.toggleFavorite(event);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}