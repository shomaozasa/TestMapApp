import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/core/models/event_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// イベントを登録する
  Future<void> addEvent({
    required String eventName,
    required String eventTime,
    required LatLng location,
    required String description, // ★ 1. description の引数を追加
  }) async {
    try {
      final collectionRef = _db.collection('events');
      final geoPoint = GeoPoint(location.latitude, location.longitude);

      final data = {
        'eventName': eventName,
        'eventTime': eventTime,
        'location': geoPoint,
        'createdAt': Timestamp.now(),
        'description': description, // ★ 2. 保存データに description を追加
      };

      await collectionRef.add(data);
    } catch (e) {
      print("Firestoreへの登録エラー: $e");
      rethrow;
    }
  }

  /// すべてのイベントをリアルタイムで取得する (Stream)
  Stream<List<EventModel>> getEventsStream() {
// ... 既存コード ...
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