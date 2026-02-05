import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String businessId; // レビュー対象の事業者ID
  final String userId;     // 投稿した利用者ID
  final String eventId;    // 関連イベントID
  final String eventName;  // イベント名
  final String shopName;   // ★追加: 店舗名 (一覧表示用)
  final int rating;        // 評価 (1-5)
  final String comment;    // コメント
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.eventId,
    required this.eventName,
    required this.shopName, // ★追加
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'userId': userId,
      'eventId': eventId,
      'eventName': eventName,
      'shopName': shopName, // ★追加
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      userId: data['userId'] ?? '',
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? '',
      shopName: data['shopName'] ?? '', // ★追加
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}