import 'package:flutter/material.dart';
import '../services/campaign_service.dart';
import '../widgets/app_widgets.dart';

class CampaignsScreen extends StatefulWidget {
  // salonId verilirse salon sahibi modu (ekleme/silme aktif)
  // verilmezse müşteri modu (sadece listeleme)
  final int? salonId;

  const CampaignsScreen({super.key, this.salonId});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  final CampaignService _campaignService = CampaignService();
  List<dynamic> _campaigns = [];
  bool _loading = true;

  bool get _isOwner => widget.salonId != null && widget.salonId! > 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    if (_isOwner) {
      _campaigns = await _campaignService.getSalonCampaigns(widget.salonId!);
    } else {
      _campaigns = await _campaignService.getCampaigns();
    }
    setState(() => _loading = false);
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCampaignSheet(
        salonId: widget.salonId!,
        onSaved: () {
          Navigator.pop(context);
          _load();
        },
      ),
    );
  }

  Future<void> _confirmDelete(int campaignId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kampanyayı Sil',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Bu kampanya kalıcı olarak silinecek. Emin misiniz?',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final ok = await _campaignService.deleteCampaign(campaignId);
      if (!mounted) return;
      if (ok) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kampanya silindi.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme işlemi başarısız.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Üst başlık ──
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
                        'KAMPANYALAR',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isOwner ? 'Kampanya yönetimi' : 'Aktif fırsatlar',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isOwner)
                  GestureDetector(
                    onTap: _showAddSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.accent, size: 22),
                    ),
                  ),
              ],
            ),
          ),

          // ── Liste ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : _campaigns.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign_outlined,
                                size: 56,
                                color: AppColors.muted.withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              _isOwner
                                  ? 'Henüz kampanya eklenmedi'
                                  : 'Aktif kampanya bulunmuyor',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 14),
                            ),
                            if (_isOwner) ...[
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _showAddSheet,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'İlk kampanyayı ekle',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _campaigns.length,
                        itemBuilder: (context, index) {
                          final c = _campaigns[index];
                          return _CampaignCard(
                            campaign: c,
                            isOwner: _isOwner,
                            onDelete: () => _confirmDelete(c['id']),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Kampanya Kartı ──
class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final bool isOwner;
  final VoidCallback onDelete;

  const _CampaignCard({
    required this.campaign,
    required this.isOwner,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    String? endDateStr;
    if (campaign['endDate'] != null) {
      try {
        endDateStr = campaign['endDate'].toString().substring(0, 10);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // İndirim yüzdesi
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '%${campaign['discountPercent'] ?? 0}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Başlık ve açıklama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign['title'] ?? '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if ((campaign['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    campaign['description'],
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 13),
                  ),
                ],
                if (endDateStr != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        'Bitiş: $endDateStr',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Salon sahibi silme butonu
          if (isOwner)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: Colors.red, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Kampanya Ekleme Bottom Sheet ──
class _AddCampaignSheet extends StatefulWidget {
  final int salonId;
  final VoidCallback onSaved;

  const _AddCampaignSheet({required this.salonId, required this.onSaved});

  @override
  State<_AddCampaignSheet> createState() => _AddCampaignSheetState();
}

class _AddCampaignSheetState extends State<_AddCampaignSheet> {
  final CampaignService _campaignService = CampaignService();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _discountController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final discountStr = _discountController.text.trim();

    if (title.isEmpty) {
      setState(() => _error = 'Kampanya başlığı zorunludur.');
      return;
    }
    final discount = int.tryParse(discountStr);
    if (discount == null || discount < 0 || discount > 100) {
      setState(() => _error = 'İndirim oranı 0-100 arası bir sayı olmalıdır.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await _campaignService.createCampaign(
      salonId: widget.salonId,
      title: title,
      description: desc,
      discountPercent: discount,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      widget.onSaved();
    } else {
      setState(() => _error = result.error ?? 'Bir hata oluştu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Yeni Kampanya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            const FieldLabel(text: 'Kampanya Başlığı'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _titleController,
              hint: 'ör. Yaz İndirimi',
            ),
            const SizedBox(height: 14),

            const FieldLabel(text: 'Açıklama'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _descController,
              hint: 'ör. Tüm hizmetlerde geçerli',
            ),
            const SizedBox(height: 14),

            const FieldLabel(text: 'İndirim Oranı (%)'),
            const SizedBox(height: 6),
            AppTextField(
              controller: _discountController,
              hint: 'ör. 20',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),

            const FieldLabel(text: 'Bitiş Tarihi (Opsiyonel)'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickEndDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 10),
                    Text(
                      _endDate == null
                          ? 'Tarih seçin'
                          : '${_endDate!.day}.${_endDate!.month}.${_endDate!.year}',
                      style: TextStyle(
                        color: _endDate == null
                            ? AppColors.muted
                            : AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                    if (_endDate != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _endDate = null),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 14),
            ],

            _saving
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2))
                : PrimaryButton(
                    label: 'Kampanyayı Kaydet',
                    onTap: _save,
                    color: AppColors.accent,
                  ),
          ],
        ),
      ),
    );
  }
}