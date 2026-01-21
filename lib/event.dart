import 'package:flutter/material.dart';

// イベントデータモデル
class Event {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String categoryLabel;
  final List<String> photos;
  final String startTime;
  final String endTime;
  final String location;
  final double distance;
  final String comment;
  final double rating;
  final int reviewCount;
  final String status;
  final List<Review> reviews;
  final List<UpcomingEvent> upcomingEvents;
  final Coupon? coupon;

  Event({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.categoryLabel,
    required this.photos,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.distance,
    required this.comment,
    required this.rating,
    required this.reviewCount,
    required this.status,
    required this.reviews,
    required this.upcomingEvents,
    this.coupon,
  });
}

class Review {
  final String userName;
  final double rating;
  final String comment;
  final String date;
  final int likes;

  Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    required this.likes,
  });
}

class UpcomingEvent {
  final String date;
  final String time;
  final String location;

  UpcomingEvent({
    required this.date,
    required this.time,
    required this.location,
  });
}

class Coupon {
  final String title;
  final String discount;

  Coupon({
    required this.title,
    required this.discount,
  });
}

// サンプルデータ
final sampleEvent = Event(
  id: '1',
  name: '今だけ！の極旨クレープ販売',
  emoji: '🍔',
  category: 'food',
  categoryLabel: '飲食',
  photos: [
    'https://via.placeholder.com/400x300/FF9800/FFFFFF?text=Crepe+1',
    'https://via.placeholder.com/400x300/FF5722/FFFFFF?text=Crepe+2',
    'https://via.placeholder.com/400x300/FFC107/FFFFFF?text=Crepe+3',
  ],
  startTime: '14:00',
  endTime: '18:00',
  location: '天神イムズ前',
  distance: 40,
  comment: '焼きたてクレープ販売中！\nチョコバナナが特に人気です♪',
  rating: 4.5,
  reviewCount: 23,
  status: 'active',
  reviews: [
    Review(
      userName: 'ユーザーA',
      rating: 5,
      comment: '最高でした！',
      date: '2日前',
      likes: 5,
    ),
  ],
  upcomingEvents: [
    UpcomingEvent(
      date: '10/12(木)',
      time: '14:00-18:00',
      location: '天神イムズ前',
    ),
  ],
  coupon: Coupon(
    title: '初回限定',
    discount: '100円OFF',
  ),
);

// イベント詳細画面
class EventDetailScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const EventDetailScreen({Key? key, this.scrollController}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final PageController _photoController = PageController();
  int _currentPhotoIndex = 0;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final event = sampleEvent;

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        /// 写真エリア
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: Colors.lightBlue,
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() => _isFavorite = !_isFavorite);
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: PageView.builder(
              controller: _photoController,
              onPageChanged: (i) => setState(() => _currentPhotoIndex = i),
              itemCount: event.photos.length,
              itemBuilder: (_, i) => Image.network(
                event.photos[i],
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        /// コンテンツ
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${event.emoji} ${event.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(event.comment),
              ),

              const SizedBox(height: 24),

              /// ✅ 下部ボタン（ここに移動）
              _buildBottomButtons(context),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('共有')),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('共有'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ルート案内')),
                );
              },
              icon: const Icon(Icons.directions),
              label: const Text('ルート案内'),
            ),
          ),
        ],
      ),
    );
  }
}
