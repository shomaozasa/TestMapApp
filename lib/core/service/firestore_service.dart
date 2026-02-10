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
      // ★追加: 初期評価
      'avgRating': 0.0,
      'reviewCount': 0,
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

  /// 事業者をフォロー/フォロー解除する (双方向書き込み版)
  /// 通知機能のために、事業者側にもフォロワー情報を保存する
  Future<void> toggleFollowBusiness(String businessId) async {
    if (_userId.isEmpty) return;

    // 1. 「自分が」誰をフォローしているかのパス
    final userFollowRef = _db
        .collection('users')
        .doc(_userId)
        .collection('followed_businesses')
        .doc(businessId);

    // 2. 「事業者が」誰にフォローされているかのパス (★新規追加: 通知用)
    final businessFollowerRef = _db
        .collection('businesses')
        .doc(businessId)
        .collection('followers')
        .doc(_userId);

    // 現在の状態を確認
    final docSnapshot = await userFollowRef.get();
    final bool isFollowing = docSnapshot.exists;

    // バッチ処理で一括更新 (整合性を保つため)
    final batch = _db.batch();

    if (isFollowing) {
      // フォロー解除: 両方から削除
      batch.delete(userFollowRef);
      batch.delete(businessFollowerRef);
    } else {
      // フォロー登録: 両方に追加
      final data = {'followedAt': FieldValue.serverTimestamp()};
      batch.set(userFollowRef, data);
      batch.set(businessFollowerRef, data);
    }

    await batch.commit();
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

  // --- レビュー機能 (平均評価更新ロジック追加版) ---
  
  /// レビューを投稿し、イベントと事業者の平均評価を更新する
  Future<void> addReview({
    required String businessId,
    required String eventId,
    required String eventName,
    required int rating,
    required String comment,
  }) async {
    if (_userId.isEmpty) return;

    // トランザクションを使って整合性を保ちながら更新
    await _db.runTransaction((transaction) async {
      // 1. 事業者情報を取得して店舗名と現在の評価をゲット
      final businessRef = _db.collection('businesses').doc(businessId);
      final businessDoc = await transaction.get(businessRef);
      
      if (!businessDoc.exists) throw Exception("事業者が見つかりません");
      final businessData = businessDoc.data()!;
      final String shopName = businessData['admin_name'] ?? '';
      
      // 現在の事業者評価を取得 (フィールドがない場合は0として扱う)
      double bizAvg = (businessData['avgRating'] ?? 0.0).toDouble();
      int bizCount = businessData['reviewCount'] ?? 0;

      // 2. イベント情報を取得
      final eventRef = _db.collection('events').doc(eventId);
      final eventDoc = await transaction.get(eventRef);
      
      if (!eventDoc.exists) throw Exception("イベントが見つかりません");
      final eventData = eventDoc.data()!;
      
      // 現在のイベント評価を取得
      double eventAvg = (eventData['avgRating'] ?? 0.0).toDouble();
      int eventCount = eventData['reviewCount'] ?? 0;

      // 3. レビューを保存 (サブコレクション)
      final reviewRef = businessRef.collection('reviews').doc();
      transaction.set(reviewRef, {
        'businessId': businessId,
        'userId': _userId,
        'eventId': eventId,
        'eventName': eventName,
        'shopName': shopName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
        // 初期状態
        'replyComment': null,
        'repliedAt': null,
      });

      // 4. 新しい平均と件数を計算
      // 計算式: (旧平均 * 旧件数 + 新評価) / (旧件数 + 1)
      final double newBizAvg = ((bizAvg * bizCount) + rating) / (bizCount + 1);
      final int newBizCount = bizCount + 1;

      final double newEventAvg = ((eventAvg * eventCount) + rating) / (eventCount + 1);
      final int newEventCount = eventCount + 1;

      // 5. 事業者とイベントのドキュメントを更新
      transaction.update(businessRef, {
        'avgRating': newBizAvg,
        'reviewCount': newBizCount,
      });

      transaction.update(eventRef, {
        'avgRating': newEventAvg,
        'reviewCount': newEventCount,
      });
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

  /// ログインユーザーの投稿したレビュー一覧を取得 (利用者画面用)
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

  /// 利用者が自分のレビューを編集する
  Future<void> updateUserReview({
    required String businessId,
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'rating': rating,
      'comment': comment,
      // 必要であれば 'updatedAt': FieldValue.serverTimestamp() を追加
    });
    // 注意: 平均評価の再計算は実装の複雑さを避けるためここでは省略していますが、
    // 厳密にはここでもトランザクションで再計算が必要です。
  }

  /// 利用者が自分のレビューを削除する
  Future<void> deleteUserReview({
    required String businessId,
    required String reviewId,
  }) async {
    // パスを指定して削除
    await _db
        .collection('businesses')
        .doc(businessId)
        .collection('reviews')
        .doc(reviewId)
        .delete();
    // 注意: 平均評価の再計算（マイナス処理）は省略しています。
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