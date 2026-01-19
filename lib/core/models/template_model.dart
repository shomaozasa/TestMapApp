class TemplateModel {
  final String id;
  final String adminId;
  final String templateName;
  final String eventName;
  final String categoryId;
  final String startTime;
  final String endTime;
  final String description;
  final String imagePath;
  final String createdAt; // ★追加: 並び替え用

  TemplateModel({
    required this.id,
    required this.adminId,
    required this.templateName,
    required this.eventName,
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    this.description = '',
    this.imagePath = '',
    this.createdAt = '', // ★追加
  });

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'templateName': templateName,
      'eventName': eventName,
      'categoryId': categoryId,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'imagePath': imagePath,
      'createdAt': DateTime.now().toIso8601String(), // 保存時
    };
  }

  factory TemplateModel.fromMap(String id, Map<String, dynamic> map) {
    return TemplateModel(
      id: id,
      adminId: map['adminId'] ?? '',
      templateName: map['templateName'] ?? '',
      eventName: map['eventName'] ?? '',
      categoryId: map['categoryId'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      description: map['description'] ?? '',
      imagePath: map['imagePath'] ?? '',
      createdAt: map['createdAt'] ?? '', // ★追加: 読み込み時
    );
  }
}