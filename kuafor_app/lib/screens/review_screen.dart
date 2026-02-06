import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  final int salonId;
  final int userId;

  const ReviewScreen({
    Key? key,
    required this.salonId,
    required this.userId,
  }) : super(key: key);

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ApiService _apiService = ApiService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await _apiService.getSalonReviews(widget.salonId);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yorum yazın')),
      );
      return;
    }

    try {
      final review = Review(
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        userId: widget.userId,
        salonId: widget.salonId,
      );

      await _apiService.createReview(review);
      _commentController.clear();
      _selectedRating = 5;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum başarıyla eklendi')),
      );
      
      _loadReviews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yorumlar'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Yorum ekleme kartı
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yorum Ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Yıldız seçimi
                  Row(
                    children: [
                      const Text('Puan: '),
                      ...List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Yorum alanı
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Deneyiminizi paylaşın...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('Gönder'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Yorumlar listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Hata: $_error'))
                    : _reviews.isEmpty
                        ? const Center(child: Text('Henüz yorum yok'))
                        : ListView.builder(
                            itemCount: _reviews.length,
                            itemBuilder: (context, index) {
                              final review = _reviews[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple,
                                    child: Text(
                                      review.userName?.substring(0, 1).toUpperCase() ?? 'U',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(review.userName ?? 'Kullanıcı'),
                                      const SizedBox(width: 8),
                                      ...List.generate(
                                        5,
                                        (i) => Icon(
                                          i < review.rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(review.comment),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(review.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
