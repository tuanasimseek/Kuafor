class Campaign {
  final int? id;
  final String title;
  final String description;
  final int discountPercentage;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final int salonId;

  Campaign({
    this.id,
    required this.title,
    required this.description,
    required this.discountPercentage,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.salonId,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      discountPercentage: json['discountPercentage'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'],
      salonId: json['salonId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'discountPercentage': discountPercentage,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'salonId': salonId,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isOngoing => !isExpired && !isUpcoming && isActive;
}
