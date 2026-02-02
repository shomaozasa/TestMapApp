import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_map_app/core/constants/event_status.dart';

class MapUtils {
  /// ステータスに応じたマーカーアイコンを取得する
  static BitmapDescriptor getMarkerIconByStatus(String status) {
    switch (status) {
      case EventStatus.active:
        // 営業中 = 緑色 (目立つ色)
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        
      case EventStatus.breakTime:
        // 休憩中 = オレンジ (注意/一時停止)
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        
      case EventStatus.finished:
        // 終了 = 赤 (または彩度を落とした色)
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        
      case EventStatus.scheduled:
      default:
        // 準備中/デフォルト = 青 (標準)
        return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }
}