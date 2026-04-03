import 'package:flutter/material.dart';
import '../services/service_service.dart';
import '../widgets/app_widgets.dart';

class StylistServicesScreen extends StatefulWidget {
  final int stylistId;
  final int salonId; // YENİ — müşteri ekranında hizmetin görünmesi için gerekli

  const StylistServicesScreen({
    super.key,
    required this.stylistId,
    required this.salonId,
  });

  @override
  State<StylistServicesScreen> createState() => _StylistServicesScreenState();
}

class _StylistServicesScreenState extends State<StylistServicesScreen> {
  final ServiceService _serviceService = ServiceService();
  List<dynamic> _services = [];
  bool _loading = true;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    final services =
        await _serviceService.getStylistServices(widget.stylistId);
    setState(() {
      _services = services;
      _loading = false;
    });
  }

  Future<void> _addService() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());

    if (name.isEmpty || price == null || duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    setState(() => _isAdding = true);

    // DÜZELTİLDİ: hem stylistId hem salonId gönderiliyor
    final success = await _serviceService.createStylistService(
      stylistId: widget.stylistId,
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
      await _loadServices();
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
      await _loadServices();
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
                        'HİZMETLERİM',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hizmetleri Yönet',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
                const Text(
                  'YENİ HİZMET EKLE',
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
                    children: [
                      _InputField(
                        controller: _nameController,
                        hint: 'Hizmet adı (ör. Saç Kesimi)',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              controller: _priceController,
                              hint: 'Fiyat (₺)',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InputField(
                              controller: _durationController,
                              hint: 'Süre (dk)',
                              keyboardType: TextInputType.number,
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
                                        color: Colors.white, strokeWidth: 2),
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
                const SizedBox(height: 20),

                // Mevcut hizmetler
                const Text(
                  'MEVCUT HİZMETLER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child:
                          CircularProgressIndicator(color: AppColors.accent),
                    ),
                  )
                else if (_services.isEmpty)
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
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...(_services.map((service) {
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
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        size: 11, color: AppColors.muted),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${service['durationMinutes']} dk',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted),
                                    ),
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
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _deleteService(service['id']),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  })),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.primary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        filled: true,
        fillColor: AppColors.background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}