/// イベントの現在の状態を定義するクラス
class EventStatus {
  // --- ステータスID (Firestoreに保存される値) ---
  static const String scheduled = 'scheduled'; // 準備中/予定 (デフォルト)
  static const String active = 'active';       // 営業中/開催中
  static const String breakTime = 'break';     // 休憩中
  static const String finished = 'finished';   // 終了

  // --- 表示用ラベル取得メソッド ---
  static String getLabel(String status) {
    switch (status) {
      case active:
        return '営業中';
      case breakTime:
        return '休憩中';
      case finished:
        return '終了';
      case scheduled:
      default:
        return '準備中';
    }
  }
}