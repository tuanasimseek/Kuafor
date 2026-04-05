import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/post_service.dart';
import '../widgets/app_widgets.dart';

class PostsScreen extends StatefulWidget {
  final int salonId;
  final bool isOwner;
  const PostsScreen({super.key, required this.salonId, this.isOwner = false});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostService _postService = PostService();
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _loading = true);
    final posts = await _postService.getPostsBySalon(widget.salonId);
    setState(() {
      _posts = posts;
      _loading = false;
    });
  }

  void _showCreatePostDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'Genel';
    final List<Map<String, dynamic>> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('Yeni Gönderi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Başlık *',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Açıklama',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Kategori',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['Genel', 'BeforeAfter', 'Kampanya']
                            .map((cat) => ChoiceChip(
                                  label: Text(cat),
                                  selected: selectedCategory == cat,
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: selectedCategory == cat
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                  onSelected: (_) =>
                                      setModalState(() => selectedCategory = cat),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Fotoğraflar',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (selectedImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedImages.length,
                            itemBuilder: (_, i) => Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(File(selectedImages[i]['path'])),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setModalState(
                                        () => selectedImages.removeAt(i)),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                                if (selectedCategory == 'BeforeAfter')
                                  Positioned(
                                    bottom: 4,
                                    left: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedImages[i]['tag'] =
                                              selectedImages[i]['tag'] == 'before'
                                                  ? 'after'
                                                  : 'before';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: selectedImages[i]['tag'] == 'before'
                                              ? Colors.orange
                                              : Colors.green,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          selectedImages[i]['tag'] ?? 'genel',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await picker.pickMultiImage();
                          if (picked.isNotEmpty) {
                            setModalState(() {
                              for (int i = 0; i < picked.length; i++) {
                                selectedImages.add({
                                  'path': picked[i].path,
                                  'tag': selectedCategory == 'BeforeAfter'
                                      ? (selectedImages.isEmpty ? 'before' : 'after')
                                      : null,
                                  'order': selectedImages.length + i,
                                });
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Fotoğraf Ekle'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Başlık gerekli')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await _createPostWithImages(
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      category: selectedCategory,
                      images: selectedImages,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Yayınla',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPostWithImages({
    required String title,
    required String description,
    required String category,
    required List<Map<String, dynamic>> images,
  }) async {
    final postId = await _postService.createPost(
      title: title,
      description: description.isEmpty ? null : description,
      category: category,
      salonId: widget.salonId,
    );

    if (postId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderi oluşturulamadı')),
        );
      }
      return;
    }

    for (final img in images) {
      await _postService.uploadPostImage(
        postId: postId,
        filePath: img['path'],
        tag: img['tag'],
        order: img['order'] ?? 0,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gönderi yayınlandı ✓')),
      );
      _loadPosts();
    }
  }

  void _openPostDetail(Map<String, dynamic> post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    ).then((_) => _loadPosts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gönderiler'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreatePostDialog,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Henüz gönderi yok',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16)),
                      if (widget.isOwner) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showCreatePostDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('İlk gönderiyi oluştur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPosts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) => _PostCard(
                      post: _posts[i],
                      isOwner: widget.isOwner,
                      onTap: () => _openPostDetail(_posts[i]),
                      onDelete: () async {
                        await _postService.deletePost(_posts[i]['id']);
                        _loadPosts();
                      },
                    ),
                  ),
                ),
      floatingActionButton: widget.isOwner && _posts.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showCreatePostDialog,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}

// ─── PostCard ────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.isOwner,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<Map<String, dynamic>>.from(post['images'] ?? []);
    final firstImage =
        images.isNotEmpty ? images.first['imageUrl'] as String? : null;
    final category = post['category'] ?? 'Genel';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: firstImage != null
                        ? Image.network(
                            firstImage,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image,
                                  color: Colors.grey, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image,
                                  color: Colors.grey, size: 40),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _categoryColor(category).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (isOwner)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.white, size: 20),
                        onSelected: (val) {
                          if (val == 'delete') onDelete();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Sil',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '+${images.length - 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                post['title'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'BeforeAfter':
        return Colors.purple;
      case 'Kampanya':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
}

// ─── PostDetailScreen ────────────────────────────────────────────────────────

class PostDetailScreen extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostDetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final images = List<Map<String, dynamic>>.from(post['images'] ?? []);
    final category = post['category'] ?? 'Genel';
    final beforeImages = images.where((i) => i['tag'] == 'before').toList();
    final afterImages = images.where((i) => i['tag'] == 'after').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(post['title'] ?? 'Gönderi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category == 'BeforeAfter' &&
                (beforeImages.isNotEmpty || afterImages.isNotEmpty)) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                            child: const Text('ÖNCE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (beforeImages.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8)),
                              child: Image.network(
                                beforeImages.first['imageUrl'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                              ),
                              child:
                                  const Center(child: Text('Fotoğraf yok')),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            ),
                            child: const Text('SONRA',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (afterImages.isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8)),
                              child: Image.network(
                                afterImages.first['imageUrl'],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(8)),
                              ),
                              child:
                                  const Center(child: Text('Fotoğraf yok')),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (images.isNotEmpty) ...[
              SizedBox(
                height: 280,
                child: PageView.builder(
                  itemCount: images.length,
                  itemBuilder: (_, i) => Image.network(
                    images[i]['imageUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image,
                          size: 60, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(category,
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text(
                        post['salonName'] ?? '',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (post['description'] != null &&
                      post['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post['description'],
                      style:
                          TextStyle(color: Colors.grey[700], fontSize: 15),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}