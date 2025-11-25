import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// イベントを登録する
  Future<void> addEvent({
    required String adminId, // ★ 事業者ID
    required String categoryId, // ★ カテゴリID
    required String eventName,
    required String eventTime,
    required String eventImage, // ★ 画像URL
    required LatLng location,
    required String address, // ★ 住所
    required String description,
  }) async {
    try {
      final collectionRef = _db.collection('events');
      // Google MapsのLatLngをFirestoreのGeoPointに変換
      final geoPoint = GeoPoint(location.latitude, location.longitude);
      final now = Timestamp.now(); // 作成・更新日時用

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
        'updatedAt': now, // 更新日時も初期値は作成日時と同じ
      };

      await collectionRef.add(data);
    } catch (e) {
      print("Firestoreへの登録エラー: $e");
      rethrow;
    }
  }

  /// すべてのイベントをリアルタイムで取得する (Stream)
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
}
