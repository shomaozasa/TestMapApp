import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/event_model.dart';
// EventModelでGeoPointを使っているため、google_maps_flutterのインポートは不要な場合もありますが
// 念のため記述しておきます。
import 'package:google_maps_flutter/google_maps_flutter.dart'; 

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ★ テスト用の固定ユーザーID（本番では FirebaseAuth.instance.currentUser.uid を使用）
  final String _userId = 'test_user_id'; 

  // --- 1. イベント登録 (事業者用: 以前の機能を維持) ---
  Future<void> addEvent({
    required String adminId,
    required String categoryId,
    required String eventName,
    required String eventTime,
    required String eventImage,
    required LatLng location, // GoogleMapからの入力はLatLng
    required String address,
    required String description,
  }) async {
    final collectionRef = _db.collection('events');
    // LatLng -> GeoPoint 変換
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
    };

    await collectionRef.add(data);
  }

  // --- 2. 全イベント一覧の取得 ---
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
        .orderBy('createdAt', descending: true) // お気に入りした順などでソート
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
        .doc(event.id); // イベントIDをドキュメントIDとして使用

    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // 既に存在する場合は削除 (お気に入り解除)
      await docRef.delete();
    } else {
      // 存在しない場合は保存 (お気に入り登録)
      // EventModelの toFirestore() を使用してMap化して保存
      await docRef.set(event.toFirestore());
    }
  }
}