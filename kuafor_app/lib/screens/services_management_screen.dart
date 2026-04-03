import 'package:flutter/material.dart';
import '../services/service_service.dart';
import '../widgets/app_widgets.dart';

class ServicesManagementScreen extends StatefulWidget {
  final int salonId;
  const ServicesManagementScreen({super.key, required this.salonId});

  @override
  State<ServicesManagementScreen> createState() =>
      _ServicesManagementScreenState();
}

class _ServicesManagementScreenState extends State<ServicesManagementScreen> {
  final ServiceService _serviceService = ServiceService();
  late Future<List<dynamic>> _servicesFuture;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  bool _isAdding = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    setState(() {
      _servicesFuture = _serviceService.getSalonServices(widget.salonId);
    });
  }

  Future<void> _addService() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());

    if (name.isEmpty || price == null || duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isAdding = true);
    final success = await _serviceService.createService(
      salonId: widget.salonId,
      name: name,
      price: price,
      durationMinutes: duration,
    );
    setState(() => _isAdding = false);

    if (success) {
      _nameController.clear();
      _priceController.clear();
      _durationController.clear();
      setState(() => _showForm = false);
      _loadServices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hizmet eklendi ✓'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hizmet eklenemedi, tekrar deneyin')),
      );
    }
  }

  Future<void> _deleteService(int serviceId) async {
    final success = await _serviceService.deleteService(serviceId);
    if (success) {
      _loadServices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hizmet silindi'),
          backgroundColor: Color(0xFF0F172A),
        ),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HİZMETLER',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Salon hizmetlerini yönet',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showForm = !_showForm),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _showForm
                          ? AppColors.accent
                          : Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Icon(
                      _showForm ? Icons.close : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hizmet ekleme formu
                if (_showForm) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YENİ HİZMET',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameController,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.primary),
                          decoration: InputDecoration(
                            hintText: 'Hizmet adı (ör: Saç Kesimi)',
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.primary),
                                decoration: InputDecoration(
                                  hintText: 'Fiyat (₺)',
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
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _durationController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.primary),
                                decoration: InputDecoration(
                                  hintText: 'Süre (dk)',
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
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _isAdding ? null : _addService,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isAdding
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Ekle',
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
                  const SizedBox(height: 16),
                ],

                // Hizmet listesi
                FutureBuilder<List<dynamic>>(
                  future: _servicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: AppColors.accent),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'Henüz hizmet eklenmemiş\nSağ üstteki + butonuna bas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13, height: 1.5),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((service) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.content_cut_rounded,
                                    size: 18, color: AppColors.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      '${service['durationMinutes']} dk',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted),
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
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Hizmeti Sil'),
                                    content: Text(
                                        '"${service['name']}" silinecek. Emin misin?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteService(service['id']);
                                        },
                                        child: const Text('Sil',
                                            style: TextStyle(
                                                color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                ),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      size: 16, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}