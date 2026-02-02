import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_map_app/core/models/template_model.dart';
import 'package:google_map_app/core/models/business_user_model.dart';
// ★ 追加: ステータス定数をインポート
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

    final data = {
      'adminId': _userId,
      'categoryId': categoryId,
      'eventName': eventName,
      'eventTime': eventTime,
      'eventImage': eventImage,
      'location': geoPoint,
      'address': address,
      'description': description,
      
      // ★ 修正: 新規登録時は必ず「準備中」で保存 (これでピンの色問題が解決します)
      'status': EventStatus.scheduled,
      
      'createdAt': now,
      'updatedAt': now,
      // 日時検索・アーカイブ機能用に保存
      'eventDate': eventDateTime != null
          ? Timestamp.fromDate(eventDateTime)
          : now,
    };

    await collectionRef.add(data);
  }

  // --- 2. 全イベント一覧の取得 (ユーザー用: 検索機能 + アーカイブフィルタ) ---
  Stream<List<EventModel>> getEventsStream({
    String? keyword,
    String? category,
    DateTime? selectedDate,
  }) {
    // ★ 追加: 終了したイベントを表示する期限（現在時刻の24時間前）
    // これより古いイベントはマップに表示されなくなります
    final DateTime threshold = DateTime.now().subtract(const Duration(hours: 24));
    final Timestamp thresholdTimestamp = Timestamp.fromDate(threshold);

    // クエリ作成: eventDate が 「24時間前」より未来のものだけを取得
    // ※ 注意: これにより並び順の基準が createdAt から eventDate に変わります
    Query query = _db
        .collection('events')
        .where('eventDate', isGreaterThan: thresholdTimestamp)
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

        // 日時フィルタ（検索パネルで指定された場合）
        bool matchesDate = true;
        if (selectedDate != null) {
          try {
            // イベントの日付データを取得（文字列解析よりTimestamp推奨だが既存踏襲）
            // eventTime文字列のフォーマットに依存するため、try-catchを入れています
            // 簡易的に eventDate フィールドと比較しても良いですが、
            // 既存ロジックを尊重して文字列解析を試みます
            final eventDateTime = DateTime.parse(event.eventTime.split(' ').first.replaceAll('/', '-'));
             matchesDate =
                eventDateTime.isAfter(selectedDate) ||
                eventDateTime.isAtSameMomentAs(selectedDate);
          } catch (e) {
            // 文字列解析失敗時は、とりあえず表示する（または除外する）
            matchesDate = true; 
          }
        }

        // キーワードフィルタ
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

  // --- 2-2. ステータス更新 (事業者用) ---
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

  // --- 5. スケジュール管理用 (事業者用: 自分のイベント取得) ---
  Stream<List<EventModel>> getFutureEventsStream(String adminId) {
    // 事業者用画面でも、あまりに古いイベントは表示しなくて良い場合は
    // 同様にフィルタリングを入れることができます。
    // 今回は「全ての履歴」が見えるようにフィルタなしにします。
    return _db
        .collection('events')
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();
      // 日付順にソート (新しい順)
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }
}