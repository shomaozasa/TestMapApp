// ★ 追加: debugPrintを使うために必要
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/models/template_model.dart';
import 'package:google_map_app/core/models/business_user_model.dart';
import 'package:google_map_app/core/models/review_model.dart'; // ★追加: レビューモデル
import 'package:google_map_app/core/constants/event_status.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get user => FirebaseAuth.instance.currentUser;
  String get _userId => user?.uid ?? '';

  // --- 1. イベント登録 (事業者用) ---
  Future<void> addEvent({
    required String adminId,
    required String categoryId,
    required String eventName,
    required String eventTime,
    required String eventImage,
    required LatLng location,
    required String address,
    required String description,
    DateTime? eventDateTime,
  }) async {
    final collectionRef = _db.collection('events');
    final geoPoint = GeoPoint(location.latitude, location.longitude);
    final now = Timestamp.now();

    // eventTime文字列から日付を解析して、検索用の eventDate を正確にセットする
    Timestamp searchDateTimestamp = now;
    try {
      final datePart = eventTime.split(' ').first; // 例: "2026/02/04"
      final parts = datePart.split('/');
      if (parts.length == 3) {
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        searchDateTimestamp = Timestamp.fromDate(date);
      }
    } catch (_) {
      // 解析失敗時は引数の日時を使用
      if (eventDateTime != null) {
        searchDateTimestamp = Timestamp.fromDate(eventDateTime);
      }
    }

    final data = {
      'adminId': _userId,
      'categoryId': categoryId,
      'eventName': eventName,
      'eventTime': eventTime,
      'eventImage': eventImage,
      'location': geoPoint,
      'address': address,
      'description': description,
      'status': EventStatus.scheduled,
      'createdAt': now,
      'updatedAt': now,
      'eventDate': searchDateTimestamp, // ★ 検索用に日付を正規化して保存
    };

    await collectionRef.add(data);
  }

  // --- 2. 全イベント一覧の取得 (ユーザー用) ---
  // 指定日（デフォルトは今日）のイベントを取得するよう修正済み
  Stream<List<EventModel>> getEventsStream({
    String? keyword,
    String? category,
    DateTime? selectedDate,
  }) {
    final now = DateTime.now();
    // 検索日付が指定されていればそれを、なければ「今日」を使う
    final targetDate = selectedDate ?? DateTime(now.year, now.month, now.day);
    
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final endOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);

    // eventDate が 指定日(今日) の範囲内にあるものを取得
    Query query = _db
        .collection('events')
        .where('eventDate', isGreaterThanOrEqualTo: startTimestamp)
        .where('eventDate', isLessThanOrEqualTo: endTimestamp)
        .orderBy('eventDate', descending: true);

    return query.snapshots().map((snapshot) {
      List<EventModel> events = snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();

      return events.where((event) {
        // カテゴリフィルタ
        final bool matchesCategory =
            (category == null ||
            category == 'すべて' ||
            event.categoryId == category);

        // キーワードフィルタ
        bool matchesKeyword = true;
        if (keyword != null && keyword.isNotEmpty) {
          final lowKeyword = keyword.toLowerCase();
          matchesKeyword =
              event.eventName.toLowerCase().contains(lowKeyword) ||
              event.description.toLowerCase().contains(lowKeyword);
        }

        return matchesCategory && matchesKeyword;
      }).toList();
    });
  }

  // --- イベント情報の編集 (事業者用) ---
  Future<void> updateEvent({
    required String eventId,
    required String eventName,
    required String eventTime,
    String? newImageUrl, 
    required String categoryId,
    required String description,
  }) async {
    final Map<String, dynamic> data = {
      'eventName': eventName,
      'eventTime': eventTime,
      'categoryId': categoryId,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (newImageUrl != null && newImageUrl.isNotEmpty) {
      data['eventImage'] = newImageUrl;
    }

    await _db.collection('events').doc(eventId).update(data);
  }

  // --- ステータス更新 ---
  Future<void> updateEventStatus(String eventId, String newStatus) async {
    try {
      await _db.collection('events').doc(eventId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('ステータスの更新に失敗しました: $e');
    }
  }

  // --- 3. 事業者フォロー機能 ---
  Stream<List<BusinessUserModel>> getFollowedBusinessesStream() {
    if (_userId.isEmpty) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(_userId)
        .collection('followed_businesses')
        .orderBy('followedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<BusinessUserModel> businesses = [];
      for (var doc in snapshot.docs) {
        final businessDoc =
            await _db.collection('businesses').doc(doc.id).get();
        if (businessDoc.exists) {
          businesses.add(BusinessUserModel.fromFirestore(businessDoc));
        }
      }
      return businesses;
    });
  }

  Stream<bool> isBusinessFollowedStream(String businessId) {
    if (_userId.isEmpty) {
      return Stream.value(false);
    }
    return _db
        .collection('users')
        .doc(_userId)
        .collection('followed_businesses')
        .doc(businessId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Future<void> toggleFollowBusiness(String businessId) async {
    if (_userId.isEmpty) return;
    final docRef = _db
        .collection('users')
        .doc(_userId)
        .collection('followed_businesses')
        .doc(businessId);
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
      await docRef.delete();
    } else {
      await docRef.set({'followedAt': FieldValue.serverTimestamp()});
    }
  }

  Stream<Set<String>> getFavoriteIdsStream() {
    if (_userId.isEmpty) return Stream.value({});
    return _db
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  // --- 4. テンプレート管理機能 ---
  Stream<List<TemplateModel>> getTemplatesStream(String adminId) {
    return _db
        .collection('templates')
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) {
      final List<TemplateModel> templates = snapshot.docs
          .map((doc) => TemplateModel.fromMap(doc.id, doc.data()))
          .toList();
      templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return templates;
    });
  }

  Future<void> addTemplate(TemplateModel template) async {
    await _db.collection('templates').add(template.toMap());
  }

  Future<void> deleteTemplate(String templateId) async {
    await _db.collection('templates').doc(templateId).delete();
  }

  // --- 5. スケジュール管理用 ---
  Stream<List<EventModel>> getFutureEventsStream(String adminId) {
    return _db
        .collection('events')
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }

  // --- レビュー機能 ---
  
  /// レビューを投稿する
  /// 保存時に事業者情報を取得し、店舗名(shopName)も含めて保存する
  Future<void> addReview({
    required String businessId,
    required String eventId,
    required String eventName,
    required int rating,
    required String comment,
  }) async {
    if (_userId.isEmpty) return;

    // 1. 店舗名を取得 (BusinessUserModelのadmin_name)
    String shopName = '';
    try {
      final businessDoc = await _db.collection('businesses').doc(businessId).get();
      if (businessDoc.exists) {
        final data = businessDoc.data();
        shopName = data?['admin_name'] ?? '';
      }
    } catch (e) {
      debugPrint('店舗名取得エラー: $e');
    }

    // 2. レビューを保存
    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .add({
      'businessId': businessId,
      'userId': _userId,
      'eventId': eventId,
      'eventName': eventName,
      'shopName': shopName, // ★追加: 取得した店舗名を保存
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 事業者へのレビュー一覧を取得 (事業者画面用)
  Stream<List<ReviewModel>> getBusinessReviewsStream(String businessId) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    });
  }

  /// ★追加: ログインユーザーの投稿したレビュー一覧を取得 (利用者画面用)
  /// [Collection Group Query] を使用
  Stream<List<ReviewModel>> getUserReviewsStream() {
    if (_userId.isEmpty) return Stream.value([]);

    // 'reviews' という名前のコレクションすべての中から、userIdが一致するものを探す
    return _db
        .collectionGroup('reviews')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
    });
  }

  // --- レビュー返信機能 ---

  /// レビューに返信する（または編集する）
  Future<void> replyToReview({
    required String businessId,
    required String reviewId,
    required String reply,
  }) async {
    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'replyComment': reply,
      'repliedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 返信を削除する
  Future<void> deleteReviewReply({
    required String businessId,
    required String reviewId,
  }) async {
    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'replyComment': FieldValue.delete(),
      'repliedAt': FieldValue.delete(),
    });
  }

  // --- 通知用トークン管理 ---
  Future<void> saveUserToken(String uid, String token) async {
    try {
      await _db.collection('users').doc(uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("FCMトークンを保存しました: $token");
    } catch (e) {
      debugPrint("トークン保存エラー: $e");
    }
  }
}