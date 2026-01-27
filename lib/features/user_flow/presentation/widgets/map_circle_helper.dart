import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 現在地と検索距離を受け取り、描画すべきサークルのセットを返す関数
Set<Circle> createSearchRadiusCircle({
  required LatLng? center,
  required double radiusKm,
}) {
  if (center == null) {
    return {};
  }

  return {
    Circle(
      circleId: const CircleId('searchRadius'),
      center: center,
      radius: radiusKm * 1000, // km -> m
      // ★ 修正: 透明度を 0.3 -> 0.15 に下げて、地図を見やすくする
      fillColor: Colors.lightBlue.withOpacity(0.1),
      strokeColor: Colors.blue.withOpacity(0.5),
      strokeWidth: 1,
    ),
  };
}