import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  // Firebase Storageのインスタンス
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 画像をアップロードし、そのダウンロードURLを返すメソッド
  /// [file]: ユーザーが選択した画像ファイル
  /// [folderName]: 保存先のフォルダ名 (例: 'event_images')
  Future<String> uploadImage(XFile file, String folderName) async {
    try {
      // 1. ファイル名を決定
      // (同じ名前で上書きされないよう、現在時刻(ミリ秒)をファイル名に含める)
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      
      // 2. 保存場所(リファレンス)を作成
      // 例: event_images/1715000000000_image.jpg
      final Reference ref = _storage.ref().child('$folderName/$fileName');

      // 3. 画像データをバイト形式で読み込む
      // (Webとモバイルの両方に対応するため、パスではなくバイトデータを使います)
      final Uint8List imgBytes = await file.readAsBytes();

      // 4. アップロード時の設定 (メタデータ)
      // これを設定しないと、ブラウザで画像を開いた時にダウンロードされてしまうことがあります
      final metadata = SettableMetadata(
        contentType: file.mimeType ?? 'image/jpeg', // MIMEタイプ (image/pngなど)
      );

      // 5. アップロード実行
      final UploadTask task = ref.putData(imgBytes, metadata);

      // 6. アップロード完了を待つ
      final TaskSnapshot snapshot = await task;

      // 7. 保存された画像の「ダウンロードURL」を取得して返す
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
      
    } catch (e) {
      print('画像アップロードエラー: $e');
      throw Exception('画像のアップロードに失敗しました');
    }
  }
}