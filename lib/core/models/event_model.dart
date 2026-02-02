import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// ★追加: ステータス定数をインポート
import 'package:google_map_app/core/constants/event_status.dart';

/// Firestoreに保存するイベント情報のデータモデル
class EventModel {
  final String id;
  final String adminId;
  final String categoryId;
  final String eventName;
  final String eventTime;
  final String eventImage;
  final LatLng location;
  final String address;
  final String description;
  // ★追加: イベントの状態
  final String status; 
  final Timestamp createdAt;
  final Timestamp updatedAt;

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
    // ★追加: デフォルト値は 'scheduled' (準備中)
    this.status = EventStatus.scheduled,
    required this.createdAt,
    required this.updatedAt,
  });

  double get latitude => location.latitude;
  double get longitude => location.longitude;

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    final GeoPoint geoPoint = data['location'] is GeoPoint
        ? data['location']
        : const GeoPoint(33.590354, 130.401719);
    
    final LatLng latLng = LatLng(geoPoint.latitude, geoPoint.longitude);

    return EventModel(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventTime: data['eventTime'] ?? '',
      eventImage: data['eventImage'] ?? '',
      location: latLng,
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      
      // ★追加: Firestoreからステータスを取得 (なければデフォルト)
      status: data['status'] ?? EventStatus.scheduled,
      
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminId': adminId,
      'categoryId': categoryId,
      'eventName': eventName,
      'eventTime': eventTime,
      'eventImage': eventImage,
      'location': GeoPoint(location.latitude, location.longitude),
      'address': address,
      'description': description,
      
      // ★追加: 保存時にもステータスを含める
      'status': status,
      
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}