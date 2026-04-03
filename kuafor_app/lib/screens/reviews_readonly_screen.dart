import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../widgets/app_widgets.dart';

class ReviewsReadOnlyScreen extends StatefulWidget {
  final int salonId;
  const ReviewsReadOnlyScreen({super.key, required this.salonId});

  @override
  State<ReviewsReadOnlyScreen> createState() => _ReviewsReadOnlyScreenState();
}

class _ReviewsReadOnlyScreenState extends State<ReviewsReadOnlyScreen> {
  final ReviewService _reviewService = ReviewService();
  late Future<List<dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _reviewService.getSalonReviews(widget.salonId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MÜŞTERİ YORUMLARI',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Gelen değerlendirmeler',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56,
                            color: AppColors.muted.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Henüz yorum yok',
                          style: TextStyle(color: AppColors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                final reviews = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final rating = review['rating'] ?? 0;
                    final name = review['user']?['fullName'] ?? 'Kullanıcı';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < rating
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: i < rating
                                              ? const Color(0xFFFBBF24)
                                              : AppColors.border,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review['comment'] ?? '',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}