import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_app/core/models/template_model.dart';

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

  // --- 3. お気に入り一覧の取得 (ユーザー別) ---
  Stream<List<EventModel>> getFavoritesStream() {
    return _db
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return EventModel.fromFirestore(doc);
          }).toList();
        });
  }

  // --- 4. お気に入りの切り替え (追加/削除) ---
  Future<void> toggleFavorite(EventModel event) async {
    if (_userId.isEmpty) return; // 未ログイン時は何もしない

    final docRef = _db
        .collection('users')
        .doc(_userId)
        .collection('favorites')
        .doc(event.id);

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await docRef.delete();
    } else {
      await docRef.set(event.toFirestore());
    }
  }

  // --- 5. テンプレート管理機能 (事業者用) ---
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

  // --- 6. スケジュール管理用 ---
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
