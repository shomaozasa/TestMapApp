// import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Firestoreに保存するイベント情報のデータモデル
class EventModel {
  final String id; // ドキュメントID
  final String adminId; // 事業者ID
  final String categoryId; // カテゴリID
  final String eventName; // イベント名
  final String eventTime; // 開催時間 (13:00-15:00)
  final String eventImage; // イベント画像のURL(firebaseのstrageのURL)
  final GeoPoint location; // 座標
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

  /// Firestoreのドキュメント（Map）からEventModelオブジェクトを生成する
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    // locationが存在し、GeoPoint型であることを確認
    final GeoPoint locationData = data['location'] is GeoPoint
        ? data['location']
        : const GeoPoint(0, 0); // 存在しない、または型が異なる場合はデフォルト値を設定
    return EventModel(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      categoryId: data['categoryId'] ?? '',
      eventName: data['eventName'] ?? '',
      eventTime: data['eventTime'] ?? '',
      eventImage: data['eventImage'] ?? '',
      location: locationData, // x座標とｙ座標はここに含める
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
      'location': location,
      'address': address,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
