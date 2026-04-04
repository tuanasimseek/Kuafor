import 'package:flutter/material.dart';
import '../services/salon_service.dart';
import '../services/review_service.dart';
import '../screens/booking_screen.dart';
import '../widgets/app_widgets.dart';

class SalonDetailScreen extends StatefulWidget {
  final int salonId;
  final int userId;
  final String salonName;

  const SalonDetailScreen({
    super.key,
    required this.salonId,
    required this.userId,
    required this.salonName,
  });

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  final SalonService _salonService = SalonService();
  final ReviewService _reviewService = ReviewService();

  late Future<Map<String, dynamic>?> _salonFuture;
  late Future<List<dynamic>> _reviewsFuture;

  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _salonFuture = _salonService.getSalonDetail(widget.salonId);
    _loadReviews();
  }

  void _loadReviews() {
    setState(() {
      _reviewsFuture = _reviewService.getSalonReviews(widget.salonId);
    });
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum boş olamaz')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    final success = await _reviewService.addReview(
      salonId: widget.salonId,
      userId: widget.userId,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
    );
    setState(() => _isSubmitting = false);
    if (success) {
      _commentController.clear();
      setState(() => _selectedRating = 5);
      _loadReviews();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorumunuz eklendi ✓'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum eklenemedi, tekrar deneyin')),
      );
    }
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SALON',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.salonName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _salonFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                final salon = snapshot.data;
                final services = (salon?['services'] as List<dynamic>?) ?? [];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Salon bilgisi
                    if (salon != null) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.store_outlined,
                                      color: AppColors.accent, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        salon['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (salon['address'] != null &&
                                          salon['address']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          salon['address'],
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (salon['description'] != null &&
                                salon['description']
                                    .toString()
                                    .isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                salon['description'],
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                    height: 1.4),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Hizmetler
                    const Text(
                      'HİZMETLER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (services.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'Henüz hizmet eklenmemiş',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ...services.map((service) {
                        final stylistName =
                            service['stylistName'] as String?;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.accent.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                        Icons.content_cut_rounded,
                                        size: 18,
                                        color: AppColors.accent),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.access_time_rounded,
                                                size: 11,
                                                color: AppColors.muted),
                                            const SizedBox(width: 3),
                                            Text(
                                              '${service['durationMinutes']} dk',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.muted),
                                            ),
                                            if (stylistName != null &&
                                                stylistName.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              const Text('·',
                                                  style: TextStyle(
                                                      color: AppColors.muted)),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                  Icons.person_outline_rounded,
                                                  size: 11,
                                                  color: AppColors.muted),
                                              const SizedBox(width: 3),
                                              Text(
                                                stylistName,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.muted),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₺${service['price']}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              // ← YENİ: Randevu Al butonu
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingScreen(
                                        customerId: widget.userId,
                                        salonId: widget.salonId,
                                        salonName: widget.salonName,
                                        serviceId: service['id'] as int,
                                        serviceName: service['name'] as String,
                                        servicePrice: (service['price'] as num)
                                            .toDouble(),
                                        serviceDurationMinutes:
                                            service['durationMinutes'] as int,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Randevu Al',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 20),

                    // Yorum yazma
                    const Text(
                      'YORUM YAZ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              final star = i + 1;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedRating = star),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    star <= _selectedRating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: star <= _selectedRating
                                        ? const Color(0xFFFBBF24)
                                        : AppColors.border,
                                    size: 28,
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.primary),
                            decoration: InputDecoration(
                              hintText: 'Deneyiminizi paylaşın...',
                              hintStyle: const TextStyle(
                                  color: AppColors.muted, fontSize: 14),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _isSubmitting ? null : _submitReview,
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Gönder',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Yorumlar listesi
                    const Text(
                      'MÜŞTERİ YORUMLARI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<dynamic>>(
                      future: _reviewsFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                  color: AppColors.accent),
                            ),
                          );
                        }
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Text(
                                'Henüz yorum yok',
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: snap.data!.map((review) {
                            final rating = review['rating'] ?? 0;
                            final name =
                                review['user']?['fullName'] ?? 'Kullanıcı';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
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
                                          color: AppColors.accent
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Center(
                                          child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                      : Icons
                                                          .star_outline_rounded,
                                                  color: i < rating
                                                      ? const Color(
                                                          0xFFFBBF24)
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
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}