import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessUserModel {
  final String adminId;
  final String adminName;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String adminCategory;
  final String homepage;
  final String xUrl;
  final String instagramUrl;
  final String? iconImage;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAuth;
  final bool isStoped;
  
  // ★追加: 平均評価とレビュー数
  final double avgRating;
  final int reviewCount;

  BusinessUserModel({
    required this.adminId,
    required this.adminName,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.adminCategory,
    required this.homepage,
    required this.xUrl,
    required this.instagramUrl,
    this.iconImage,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.isAuth = false,
    this.isStoped = false,
    // ★追加: 初期値は0
    this.avgRating = 0.0,
    this.reviewCount = 0,
  });

  factory BusinessUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessUserModel(
      adminId: data['admin_id'] ?? '',
      adminName: data['admin_name'] ?? '',
      ownerName: data['owner_name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
      adminCategory: data['admin_category'] ?? '',
      homepage: data['homepage'] ?? '',
      xUrl: data['xUrl'] ?? '',
      instagramUrl: data['instagramUrl'] ?? '',
      iconImage: data['icon_image'],
      description: data['description'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAuth: data['is_auth'] ?? false,
      isStoped: data['is_stoped'] ?? false,
      // ★追加: データがない場合は0
      avgRating: (data['avgRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'admin_id': adminId,
      'admin_name': adminName,
      'owner_name': ownerName,
      'email': email,
      'phone_number': phoneNumber,
      'admin_category': adminCategory,
      'homepage': homepage,
      'xUrl': xUrl,
      'instagramUrl': instagramUrl,
      'icon_image': iconImage,
      'description': description,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'is_auth': isAuth,
      'is_stoped': isStoped,
      // ★追加
      'avgRating': avgRating,
      'reviewCount': reviewCount,
    };
  }
}