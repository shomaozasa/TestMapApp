import 'package:cloud_firestore/cloud_firestore.dart';

// ========================================
// ユーザーモデル
// ========================================
class UserModel {
  final String userId;
  final String password;
  final String username;
  final String? iconImage;
  final String email;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final int loginAttempts;
  final bool isAccountSuspended;
  final bool isEmailVerified;

  UserModel({
    required this.userId,
    required this.password,
    required this.username,
    this.iconImage,
    required this.email,
    required this.registeredAt,
    required this.updatedAt,
    this.loginAttempts = 0,
    this.isAccountSuspended = false,
    this.isEmailVerified = false,
  });

  // Firestoreからデータを取得
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }
    
    return UserModel(
      userId: doc.id,
      password: data['password'] ?? '',
      username: data['username'] ?? '',
      iconImage: data['iconImage'],
      email: data['email'] ?? '',
      registeredAt: _toDateTime(data['registeredAt']),
      updatedAt: _toDateTime(data['updatedAt']),
      loginAttempts: data['loginAttempts'] ?? 0,
      isAccountSuspended: data['isAccountSuspended'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  // Timestamp変換ヘルパー
  static DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  // Firestoreに保存するためのMap
  Map<String, dynamic> toFirestore() {
    return {
      'password': password,
      'username': username,
      'iconImage': iconImage,
      'email': email,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'loginAttempts': loginAttempts,
      'isAccountSuspended': isAccountSuspended,
      'isEmailVerified': isEmailVerified,
    };
  }

  UserModel copyWith({
    String? userId,
    String? password,
    String? username,
    String? iconImage,
    String? email,
    DateTime? registeredAt,
    DateTime? updatedAt,
    int? loginAttempts,
    bool? isAccountSuspended,
    bool? isEmailVerified,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      password: password ?? this.password,
      username: username ?? this.username,
      iconImage: iconImage ?? this.iconImage,
      email: email ?? this.email,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      loginAttempts: loginAttempts ?? this.loginAttempts,
      isAccountSuspended: isAccountSuspended ?? this.isAccountSuspended,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

// ========================================
// 事業者モデル
// ========================================
class BusinessModel {
  final String businessId;
  final String password;
  final String businessName;
  final String? iconImage;
  final String email;
  final String? phoneNumber;
  final String? category;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final bool isVerified;
  final String? representativeName;
  final String? websiteUrl;
  final String? twitterUrl;
  final String? instagramUrl;
  final bool isAccountSuspended;

  BusinessModel({
    required this.businessId,
    required this.password,
    required this.businessName,
    this.iconImage,
    required this.email,
    this.phoneNumber,
    this.category,
    required this.registeredAt,
    required this.updatedAt,
    this.isVerified = false,
    this.representativeName,
    this.websiteUrl,
    this.twitterUrl,
    this.instagramUrl,
    this.isAccountSuspended = false,
  });

  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BusinessModel(
      businessId: doc.id,
      password: data['password'] ?? '',
      businessName: data['businessName'] ?? '',
      iconImage: data['iconImage'],
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      category: data['category'],
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isVerified: data['isVerified'] ?? false,
      representativeName: data['representativeName'],
      websiteUrl: data['websiteUrl'],
      twitterUrl: data['twitterUrl'],
      instagramUrl: data['instagramUrl'],
      isAccountSuspended: data['isAccountSuspended'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'password': password,
      'businessName': businessName,
      'iconImage': iconImage,
      'email': email,
      'phoneNumber': phoneNumber,
      'category': category,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isVerified': isVerified,
      'representativeName': representativeName,
      'websiteUrl': websiteUrl,
      'twitterUrl': twitterUrl,
      'instagramUrl': instagramUrl,
      'isAccountSuspended': isAccountSuspended,
    };
  }

  BusinessModel copyWith({
    String? businessId,
    String? password,
    String? businessName,
    String? iconImage,
    String? email,
    String? phoneNumber,
    String? category,
    DateTime? registeredAt,
    DateTime? updatedAt,
    bool? isVerified,
    String? representativeName,
    String? websiteUrl,
    String? twitterUrl,
    String? instagramUrl,
    bool? isAccountSuspended,
  }) {
    return BusinessModel(
      businessId: businessId ?? this.businessId,
      password: password ?? this.password,
      businessName: businessName ?? this.businessName,
      iconImage: iconImage ?? this.iconImage,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      category: category ?? this.category,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      representativeName: representativeName ?? this.representativeName,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      isAccountSuspended: isAccountSuspended ?? this.isAccountSuspended,
    );
  }
}

// ========================================
// カテゴリモデル
// ========================================
class CategoryModel {
  final String categoryId;
  final String categoryName;
  final DateTime registeredAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.registeredAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      categoryId: doc.id,
      categoryName: data['categoryName'] ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoryName': categoryName,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// ========================================
// イベントモデル (非正規化)
// ========================================
class EventModel {
  final String eventId;
  final String businessId;
  final String businessName; // 非正規化
  final String? businessIcon; // 非正規化
  final String categoryId;
  final String categoryName; // 非正規化
  final DateTime startTime;
  final DateTime endTime;
  final String? eventImage;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? description;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final int bookmarkCount; // キャッシュ
  final int reviewCount; // キャッシュ
  final double averageRating; // キャッシュ

  EventModel({
    required this.eventId,
    required this.businessId,
    required this.businessName,
    this.businessIcon,
    required this.categoryId,
    required this.categoryName,
    required this.startTime,
    required this.endTime,
    this.eventImage,
    required this.location,
    this.latitude,
    this.longitude,
    this.description,
    required this.registeredAt,
    required this.updatedAt,
    this.bookmarkCount = 0,
    this.reviewCount = 0,
    this.averageRating = 0.0,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventId: doc.id,
      businessId: data['businessId'] ?? '',
      businessName: data['businessName'] ?? '',
      businessIcon: data['businessIcon'],
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      eventImage: data['eventImage'],
      location: data['location'] ?? '',
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      description: data['description'],
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      bookmarkCount: data['bookmarkCount'] ?? 0,
      reviewCount: data['reviewCount'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'businessIcon': businessIcon,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'eventImage': eventImage,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'bookmarkCount': bookmarkCount,
      'reviewCount': reviewCount,
      'averageRating': averageRating,
    };
  }

  EventModel copyWith({
    String? eventId,
    String? businessId,
    String? businessName,
    String? businessIcon,
    String? categoryId,
    String? categoryName,
    DateTime? startTime,
    DateTime? endTime,
    String? eventImage,
    String? location,
    double? latitude,
    double? longitude,
    String? description,
    DateTime? registeredAt,
    DateTime? updatedAt,
    int? bookmarkCount,
    int? reviewCount,
    double? averageRating,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessIcon: businessIcon ?? this.businessIcon,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      eventImage: eventImage ?? this.eventImage,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      registeredAt: registeredAt ?? this.registeredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      reviewCount: reviewCount ?? this.reviewCount,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}

// ========================================
// ブックマークモデル (サブコレクション)
// ========================================
class BookmarkModel {
  final String eventId;
  final DateTime registeredAt;

  BookmarkModel({
    required this.eventId,
    required this.registeredAt,
  });

  factory BookmarkModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BookmarkModel(
      eventId: doc.id,
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'registeredAt': Timestamp.fromDate(registeredAt),
    };
  }
}

// ========================================
// レビューモデル (サブコレクション)
// ========================================
class ReviewModel {
  final String reviewId;
  final String userId;
  final String username; // 非正規化
  final String? userIcon; // 非正規化
  final double rating;
  final String comment;
  final List<String> reviewImages;
  final DateTime registeredAt;
  final DateTime updatedAt;
  final bool hasReply;

  ReviewModel({
    required this.reviewId,
    required this.userId,
    required this.username,
    this.userIcon,
    required this.rating,
    required this.comment,
    this.reviewImages = const [],
    required this.registeredAt,
    required this.updatedAt,
    this.hasReply = false,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      reviewId: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userIcon: data['userIcon'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      reviewImages: List<String>.from(data['reviewImages'] ?? []),
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      hasReply: data['hasReply'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      'userIcon': userIcon,
      'rating': rating,
      'comment': comment,
      'reviewImages': reviewImages,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'hasReply': hasReply,
    };
  }
}

// ========================================
// レビュー返信モデル (サブコレクション)
// ========================================
class ReviewReplyModel {
  final String replyId;
  final String replyComment;
  final DateTime registeredAt;
  final DateTime updatedAt;

  ReviewReplyModel({
    required this.replyId,
    required this.replyComment,
    required this.registeredAt,
    required this.updatedAt,
  });

  factory ReviewReplyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReviewReplyModel(
      replyId: doc.id,
      replyComment: data['replyComment'] ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'replyComment': replyComment,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

// ========================================
// クーポンモデル
// ========================================
class CouponModel {
  final String couponId;
  final String couponName;
  final String description;
  final DateTime validFrom;
  final DateTime validUntil;
  final String userId;
  final String businessId;
  final int issueValue;
  final bool isUsed;
  final DateTime? usedAt;

  CouponModel({
    required this.couponId,
    required this.couponName,
    required this.description,
    required this.validFrom,
    required this.validUntil,
    required this.userId,
    required this.businessId,
    required this.issueValue,
    this.isUsed = false,
    this.usedAt,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CouponModel(
      couponId: doc.id,
      couponName: data['couponName'] ?? '',
      description: data['description'] ?? '',
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      businessId: data['businessId'] ?? '',
      issueValue: data['issueValue'] ?? 0,
      isUsed: data['isUsed'] ?? false,
      usedAt: data['usedAt'] != null 
          ? (data['usedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'couponName': couponName,
      'description': description,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'userId': userId,
      'businessId': businessId,
      'issueValue': issueValue,
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
    };
  }
}

// ========================================
// スタンプモデル
// ========================================
class StampModel {
  final String stampId;
  final String couponId;
  final String stampName;
  final String? stampImage;
  final DateTime acquiredAt;

  StampModel({
    required this.stampId,
    required this.couponId,
    required this.stampName,
    this.stampImage,
    required this.acquiredAt,
  });

  factory StampModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StampModel(
      stampId: doc.id,
      couponId: data['couponId'] ?? '',
      stampName: data['stampName'] ?? '',
      stampImage: data['stampImage'],
      acquiredAt: (data['acquiredAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'couponId': couponId,
      'stampName': stampName,
      'stampImage': stampImage,
      'acquiredAt': Timestamp.fromDate(acquiredAt),
    };
  }
}

// ========================================
// 来訪履歴モデル (サブコレクション)
// ========================================
class VisitHistoryModel {
  final String historyId;
  final String eventId;
  final String eventName; // 非正規化
  final DateTime visitedAt;

  VisitHistoryModel({
    required this.historyId,
    required this.eventId,
    required this.eventName,
    required this.visitedAt,
  });

  factory VisitHistoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return VisitHistoryModel(
      historyId: doc.id,
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? '',
      visitedAt: (data['visitedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'eventName': eventName,
      'visitedAt': Timestamp.fromDate(visitedAt),
    };
  }
}