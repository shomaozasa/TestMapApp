import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String businessId;
  final String userId;
  final String eventId;
  final String eventName;
  final String shopName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  
  // ★ 追加: 返信用フィールド
  final String? replyComment; // 返信内容 (nullなら未返信)
  final DateTime? repliedAt;  // 返信日時

  ReviewModel({
    required this.id,
    required this.businessId,
    required this.userId,
    required this.eventId,
    required this.eventName,
    required this.shopName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.replyComment, // ★追加
    this.repliedAt,    // ★追加
  });

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'userId': userId,
      'eventId': eventId,
      'eventName': eventName,
      'shopName': shopName,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      // ★追加
      'replyComment': replyComment, 
      'repliedAt': repliedAt != null ? Timestamp.fromDate(repliedAt!) : null,
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
      shopName: data['shopName'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // ★追加
      replyComment: data['replyComment'],
      repliedAt: (data['repliedAt'] as Timestamp?)?.toDate(),
    );
  }
}