import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_app/core/models/template_model.dart';
import 'package:google_map_app/core/models/business_user_model.dart'; // ★追加

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
    DateTime? eventDateTime, // ★追加: 日時検索用のDateTime
  }) async {
    final collectionRef = _db.collection('events');
    final geoPoint = GeoPoint(location.latitude, location.longitude);
    final now = Timestamp.now();

    final data = {
      'adminId': _userId,
      'categoryId': categoryId,
      'eventName': eventName,
      'eventTime': eventTime,
      'eventImage': eventImage,
      'location': geoPoint,
      'address': address,
      'description': description,
      'createdAt': now,
      'updatedAt': now,
      // ★ 日時検索を正確に行うために、Timestamp型のフィールドを保持します
      'eventDate': eventDateTime != null
          ? Timestamp.fromDate(eventDateTime)
          : now,
    };

    await collectionRef.add(data);
  }

  // --- 2. 全イベント一覧の取得 (ユーザー用: 検索機能付き) ---
  // ★ 引数を追加してフィルタリングに対応
  // --- 2. 全イベント一覧の取得 (ユーザー用: 検索機能付き) ---
  Stream<List<EventModel>> getEventsStream({
    String? keyword,
    String? category,
    DateTime? selectedDate,
  }) {
    Query query = _db
        .collection('events')
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      List<EventModel> events = snapshot.docs.map((doc) {
        return EventModel.fromFirestore(doc);
      }).toList();

      return events.where((event) {
        // カテゴリのチェック
        // UIから 'すべて' が渡された場合は全表示
        final bool matchesCategory =
            (category == null ||
            category == 'すべて' ||
            event.categoryId == category);

        // 日時のチェック
        bool matchesDate = true;
        if (selectedDate != null) {
          try {
            final eventDateTime = DateTime.parse(event.eventTime);
            matchesDate =
                eventDateTime.isAfter(selectedDate) ||
                eventDateTime.isAtSameMomentAs(selectedDate);
          } catch (e) {
            matchesDate = false;
          }
        }

        // キーワードのチェック
        bool matchesKeyword = true;
        if (keyword != null && keyword.isNotEmpty) {
          final lowKeyword = keyword.toLowerCase();
          matchesKeyword =
              event.eventName.toLowerCase().contains(lowKeyword) ||
              event.description.toLowerCase().contains(lowKeyword);
        }

        return matchesCategory && matchesDate && matchesKeyword;
      }).toList();
    });
  }

  // --- 3. 事業者フォロー機能 (旧: お気に入り) ---

  // フォローしている事業者一覧を取得 (UserHomeScreenなどで使用)
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
        // IDを使って事業者情報を取得 (doc.id が businessId)
        final businessDoc =
            await _db.collection('businesses').doc(doc.id).get();
        if (businessDoc.exists) {
          businesses.add(BusinessUserModel.fromFirestore(businessDoc));
        }
      }
      return businesses;
    });
  }

  // フォローの状態を確認するストリーム (ボタンの表示切り替え用)
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

  // フォローの切り替え (追加/削除)
  Future<void> toggleFollowBusiness(String businessId) async {
    if (_userId.isEmpty) return;

    final docRef = _db
        .collection('users')
        .doc(_userId)
        .collection('followed_businesses')
        .doc(businessId);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // フォロー解除
      await docRef.delete();
    } else {
      // フォロー登録
      await docRef.set({
        'followedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- 4. テンプレート管理機能 (事業者用) ---
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

  // --- 5. スケジュール管理用 (事業者用) ---
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

  // FirestoreService クラス内に追加
  Stream<Set<String>> getFavoriteIdsStream() {
    if (_userId.isEmpty) return Stream.value({});

    return _db
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }
}
