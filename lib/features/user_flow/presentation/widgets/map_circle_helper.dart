import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Set<Circle> createSearchRadiusCircle({
  required LatLng? center,
  required double radiusKm,
}) {
  if (center == null) return {};

  return {
    Circle(
      circleId: const CircleId('search_radius'),
      center: center,
      // radiusは「メートル」指定なので1000倍する
      radius: radiusKm * 1000,
      fillColor: Colors.blue.withOpacity(0.15),
      strokeColor: Colors.blue.withOpacity(0.3),
      strokeWidth: 2,
    ),
  };
}
