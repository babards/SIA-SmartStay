class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    required this.isRead,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: map['data'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }
}
