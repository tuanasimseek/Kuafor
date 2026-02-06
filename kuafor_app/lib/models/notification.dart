class AppNotification {
  final int? id;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final int userId;

  AppNotification({
    this.id,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.userId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      message: json['message'],
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'userId': userId,
    };
  }
}
