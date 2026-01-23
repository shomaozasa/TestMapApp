import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String userName;
  final String email;
  final String? iconImage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int violated;
  final bool isStoped;
  final bool isAuth;

  UserModel({
    required this.userId,
    required this.userName,
    required this.email,
    this.iconImage,
    required this.createdAt,
    required this.updatedAt,
    this.violated = 0,
    this.isStoped = false,
    this.isAuth = false,
  });

  // Firestoreからデータを読み込むためのファクトリ
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      email: data['email'] ?? '',
      iconImage: data['icon_image'],
      // Timestamp型をDateTime型に変換
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      violated: data['violated'] ?? 0,
      isStoped: data['is_stoped'] ?? false,
      isAuth: data['is_auth'] ?? false,
    );
  }

  // Firestoreに保存するためのMap変換
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'email': email,
      'icon_image': iconImage,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'violated': violated,
      'is_stoped': isStoped,
      'is_auth': isAuth,
    };
  }
}