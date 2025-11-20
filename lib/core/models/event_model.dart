import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestoreに保存するイベント情報のデータモデル
class EventModel {
  final String id; // ドキュメントID
  final String eventName; // イベント名
  final String eventTime; // 開催時間 (例: "13:00-15:00")
  final GeoPoint location; // 緯度経度
  final Timestamp createdAt; // 作成日時

  // --- ★ 1. 詳細説明フィールドを追加 ---
  final String description; // イベント詳細説明

  EventModel({
    required this.id,
    required this.eventName,
    required this.eventTime,
    required this.location,
    required this.createdAt,
    required this.description, // ★ 1. コンストラクタにも追加
  });

  /// Firestoreのドキュメント（Map）からEventModelオブジェクトを生成する
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      eventName: data['eventName'] ?? '',
      eventTime: data['eventTime'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      // ★ 1. description も読み込む (存在しない場合は空文字)
      description: data['description'] ?? '', 
    );
  }

  /// EventModelオブジェクトをFirestoreに保存可能なMap形式に変換する
  Map<String, dynamic> toFirestore() {
    return {
      'eventName': eventName,
      'eventTime': eventTime,
      'location': location,
      'createdAt': createdAt,
      'description': description, // ★ 1. 保存するMapにも追加
    };
  }
}