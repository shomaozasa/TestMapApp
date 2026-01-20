import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/event_model.dart';
// EventModelでGeoPointを使っているため、google_maps_flutterのインポートは不要な場合もありますが
// 念のため記述しておきます。
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_map_app/core/models/template_model.dart'; // ★追加: テンプレートモデル

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // // ★ テスト用の固定ユーザーID（本番では FirebaseAuth.instance.currentUser.uid を使用）
  // final String _userId = 'test_user_id';

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
  }) async {
    final collectionRef = _db.collection('events');
    final geoPoint = GeoPoint(location.latitude, location.longitude);
    final now = Timestamp.now();

    final data = {
      'adminId': adminId,
      'categoryId': categoryId,
      'eventName': eventName,
      'eventTime': eventTime,
      'eventImage': eventImage,
      'location': geoPoint,
      'address': address,
      'description': description,
      'createdAt': now,
      'updatedAt': now,
      // 日付検索用に DateTime型のフィールドも持たせておくと便利ですが、
      // ここでは既存実装に合わせて createdAt を使用します。
      // 必要であれば 'eventDate': Timestamp.fromDate(...) などを追加してください。
    };

    await collectionRef.add(data);
  }

  // --- 2. 全イベント一覧の取得 (ユーザー用) ---
  Stream<List<EventModel>> getEventsStream() {
    return _db
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return EventModel.fromFirestore(doc);
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

  // ▼▼▼ ここから下が追加・復元した機能です ▼▼▼

  // --- 5. テンプレート管理機能 (事業者用) ---
  
  // テンプレート一覧を取得
  Stream<List<TemplateModel>> getTemplatesStream(String adminId) {
    return _db
        .collection('templates')
        .where('adminId', isEqualTo: adminId) // 絞り込みのみ（インデックス不要）
        // .orderBy(...) は削除
        .snapshots()
        .map((snapshot) {
          // 1. まずモデルリストに変換
          final List<TemplateModel> templates = snapshot.docs
            .map((doc) => TemplateModel.fromMap(doc.id, doc.data()))
            .toList();
          
          // 2. アプリ側で「作成日時」の降順（新しい順）にソート
          templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return templates;
        });
  }

  // テンプレートを追加
  Future<void> addTemplate(TemplateModel template) async {
    await _db.collection('templates').add(template.toMap());
  }

  // テンプレートを削除
  Future<void> deleteTemplate(String templateId) async {
    await _db.collection('templates').doc(templateId).delete();
  }

  // --- 6. スケジュール管理用 (事業者用: 自分のイベントのみ取得・削除) ---

  // 特定の事業者のイベント一覧を取得
  Stream<List<EventModel>> getFutureEventsStream(String adminId) {
    return _db
        .collection('events')
        .where('adminId', isEqualTo: adminId) // 絞り込みのみ
        // .orderBy(...) は削除してインデックス回避
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
          
          // アプリ側で「新しい順」に並び替え
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return events;
        });
  }

  // イベントを削除
  Future<void> deleteEvent(String eventId) async {
    await _db.collection('events').doc(eventId).delete();
  }
}
