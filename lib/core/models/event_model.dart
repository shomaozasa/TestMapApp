import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // ★ GoogleMapsの型を使うために追加

/// Firestoreに保存するイベント情報のデータモデル
class EventModel {
  final String id; // ドキュメントID
  final String adminId; // 事業者ID
  final String categoryId; // カテゴリID
  final String eventName; // イベント名
  final String eventTime; // 開催時間 (13:00-15:00)
  final String eventImage; // イベント画像のURL(firebaseのstrageのURL)
  
  // ★ 修正: アプリ内で扱いやすいように GeoPoint ではなく LatLng で保持
  final LatLng location; // 座標 (位置情報)
  
  final String address; // 場所
  // --- ★ 1. 詳細説明フィールドを追加 ---
  final String description; // イベント詳細説明
  final Timestamp createdAt; // 作成日時
  final Timestamp updatedAt; // 更新日時

  EventModel({
    required this.id,
    required this.adminId,
    required this.categoryId,
    required this.eventName,
    required this.eventTime,
    required this.eventImage,
    required this.location,
    required this.address,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    // ★ 1. コンストラクタにも追加
  });

  // ★ 追加: マップ画面等で使いやすいように緯度経度を直接取れるゲッター
  double get latitude => location.latitude;
  double get longitude => location.longitude;

  /// Firestoreのドキュメント（Map）からEventModelオブジェクトを生成する
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // ★ 修正: FirestoreのGeoPointをGoogleMapのLatLngに変換
    // locationが存在し、GeoPoint型であることを確認 (なければデフォルト値)
    final GeoPoint geoPoint = data['location'] is GeoPoint
        ? data['location']
        : const GeoPoint(33.590354, 130.401719); // デフォルト値(天神など)
    
    final LatLng latLng = LatLng(geoPoint.latitude, geoPoint.longitude);

    return EventModel(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventTime: data['eventTime'] ?? '',
      eventImage: data['eventImage'] ?? '',
      
      location: latLng, // ★ LatLngに変換したものをセット
      
      // ★ 1. description も読み込む (存在しない場合は空文字)
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  /// EventModelオブジェクトをFirestoreに保存可能なMap形式に変換する
  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'categoryId': categoryId,
      'eventName': eventName,
      'eventTime': eventTime,
      'eventImage': eventImage,
      
      // ★ 修正: 保存時は LatLng を Firestore 用の GeoPoint に戻す
      'location': GeoPoint(location.latitude, location.longitude),
      
      'address': address,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}