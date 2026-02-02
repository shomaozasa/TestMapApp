import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- 1. 検索範囲用の青いソナー (利用者用) ---
Set<Circle> createSearchRadiusWithSonar({
  required LatLng? center,
  required double radiusKm,
  required double animationValue,
}) {
  if (center == null) return {};

  final double baseRadiusMeters = radiusKm * 1000;
  final Set<Circle> circles = {};
  const double fadeFactor = 3.0;
  const double radiusScale = 1.0;

  // 静止している検索範囲（ベース）
  circles.add(
    Circle(
      circleId: const CircleId('staticRadius'),
      center: center,
      radius: baseRadiusMeters,
      fillColor: Colors.lightBlue.withOpacity(0.05),
      strokeColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 1,
    ),
  );

  // 動く波紋
  final List<double> waves = [
    animationValue,
    (animationValue + 0.33) % 1.0,
    (animationValue + 0.66) % 1.0,
  ];

  for (int i = 0; i < waves.length; i++) {
    final double value = waves[i];
    final double currentRadius = baseRadiusMeters * value * radiusScale;
    double opacityCurve = pow(1.0 - value, fadeFactor).toDouble();
    final double opacity = (opacityCurve * 0.3).clamp(0.0, 1.0);

    if (opacity > 0.01) {
      circles.add(
        Circle(
          circleId: CircleId('sonarWave_$i'),
          center: center,
          radius: currentRadius,
          fillColor: Colors.blue.withOpacity(opacity),
          strokeColor: Colors.transparent,
          strokeWidth: 0,
        ),
      );
    }
  }
  return circles;
}

// --- 2. 営業中ピン用の緑色ソナー (事業者用) ---
Set<Circle> createActivePinSonar({
  required String eventId,
  required LatLng center,
  required double animationValue,
}) {
  final Set<Circle> circles = {};

  // 半径: 300m程度まで広がる
  const double maxRadiusMeters = 300.0;
  
  // ★ 修正1: フェード係数を下げて、外側まで色を残りやすくする (2.0 -> 1.5)
  const double fadeFactor = 1.5; 

  // 波を2つ生成
  final List<double> waves = [
    animationValue,
    (animationValue + 0.5) % 1.0,
  ];

  for (int i = 0; i < waves.length; i++) {
    final double value = waves[i];
    final double currentRadius = maxRadiusMeters * value;

    // 透明度計算
    double opacityCurve = pow(1.0 - value, fadeFactor).toDouble();
    
    // ★ 修正2: 最大透明度を 0.4 -> 0.7 にアップして濃くする
    final double opacity = (opacityCurve * 0.7).clamp(0.0, 1.0);

    if (opacity > 0.05) { // 薄すぎるものは描画しない閾値も少し上げる
      circles.add(
        Circle(
          circleId: CircleId('activeSonar_${eventId}_$i'),
          center: center,
          radius: currentRadius,
          
          // ★ 修正3: 色を通常の緑より少し明るいアクセントカラーにして視認性アップ
          // (もし濃い緑が良い場合は Colors.green[700] などにしてください)
          fillColor: Colors.greenAccent.shade700.withOpacity(opacity),
          
          strokeColor: Colors.transparent,
          strokeWidth: 0,
        ),
      );
    }
  }
  return circles;
}