import 'dart:math'; // pow関数のために追加
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Set<Circle> createSearchRadiusWithSonar({
  required LatLng? center,
  required double radiusKm,
  required double animationValue, // 0.0 〜 1.0
}) {
  if (center == null) return {};

  final double maxRadiusMeters = radiusKm * 1000;
  final Set<Circle> circles = {};

  // 1. 静止している検索範囲（ベース）
  circles.add(
    Circle(
      circleId: const CircleId('staticRadius'),
      center: center,
      radius: maxRadiusMeters,
      // ベースは極めて薄くして、点滅を目立たなくする
      fillColor: Colors.lightBlue.withOpacity(0.05),
      strokeColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 1,
    ),
  );

  // 2. ソナーアニメーション（3つの波で密度を上げる）
  // 波の数を2つから3つに増やし、間隔を詰めることでより滑らかに見せます
  final List<double> waves = [
    animationValue,
    //(animationValue + 0.33) % 1.0,
    (animationValue + 0.66) % 1.0,
  ];

  for (int i = 0; i < waves.length; i++) {
    final double value = waves[i];
    
    // 半径: 0% -> 100%
    final double currentRadius = maxRadiusMeters * value;

    // ★ 修正ポイント: 透明度の計算
    // 単純な引き算 (1.0 - value) ではなく、pow(..., 4) で4乗します。
    // これにより、アニメーションの後半（外側）で急激に透明になり、
    // 端に到達する前には人間の目には見えないレベルまで消えます。
    // 結果、消滅時の「チカッ」がなくなります。
    double opacityCurve = pow(1.0 - value, 2).toDouble();
    
    // 最大透明度を掛ける (0.3)
    final double opacity = (opacityCurve * 0.3).clamp(0.0, 1.0);

    // 透明度が低すぎる場合（ほぼ見えない）は描画しないことで負荷も下げる
    if (opacity > 0.01) {
      circles.add(
        Circle(
          circleId: CircleId('sonarWave_$i'),
          center: center,
          radius: currentRadius,
          fillColor: Colors.blue.withOpacity(opacity),
          strokeColor: Colors.transparent, // 線なし
          strokeWidth: 0,
        ),
      );
    }
  }

  return circles;
}
