class Review {
  final int? id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final int userId;
  final String? userName;
  final int salonId;

  Review({
    this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.userId,
    this.userName,
    required this.salonId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'],
      userName: json['user']?['fullName'],
      salonId: json['salonId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'userId': userId,
      'salonId': salonId,
    };
  }
}
