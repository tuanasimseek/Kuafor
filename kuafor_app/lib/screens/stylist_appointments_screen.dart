import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../widgets/app_widgets.dart';

class StylistAppointmentsScreen extends StatefulWidget {
  final int stylistId;
  const StylistAppointmentsScreen({super.key, required this.stylistId});

  @override
  State<StylistAppointmentsScreen> createState() =>
      _StylistAppointmentsScreenState();
}

class _StylistAppointmentsScreenState
    extends State<StylistAppointmentsScreen> {
  final AppointmentService _service = AppointmentService();
  late Future<List<dynamic>> _future;
  String _filter = 'Tümü'; // Tümü / Beklemede / Onaylandı / Tamamlandı

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _service.getStylistAppointments(widget.stylistId);
    });
  }

  Future<void> _updateStatus(int id, String status) async {
    final ok = await _service.updateStatus(id, status);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellendi: $status'),
          backgroundColor: AppColors.primary,
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Güncelleme başarısız'),
          backgroundColor: Colors.red,
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RANDEVULARIM',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Randevu yönetimi',
                      style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtre çipleri
          Container(
            color: AppColors.surface,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tümü', 'Beklemede', 'Onaylandı', 'Tamamlandı', 'İptal Edildi']
                    .map((f) {
                  final active = _filter == f;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color:
                            active ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active
                                ? AppColors.primary
                                : AppColors.border),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color:
                              active ? AppColors.white : AppColors.muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.accent));
                }

                final all = snap.data ?? [];
                final filtered = _filter == 'Tümü'
                    ? all
                    : all
                        .where((a) => a['status'] == _filter)
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Bu filtrede randevu yok',
                        style: TextStyle(color: AppColors.muted)),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final a = filtered[i];
                      return _StylistAppointmentCard(
                        appt: a,
                        onApprove: () =>
                            _updateStatus(a['id'] as int, 'Onaylandı'),
                        onComplete: () =>
                            _updateStatus(a['id'] as int, 'Tamamlandı'),
                        onCancel: () =>
                            _updateStatus(a['id'] as int, 'İptal Edildi'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StylistAppointmentCard extends StatelessWidget {
  final Map appt;
  final VoidCallback onApprove;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _StylistAppointmentCard({
    required this.appt,
    required this.onApprove,
    required this.onComplete,
    required this.onCancel,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Onaylandı':
        return const Color(0xFF10B981);
      case 'İptal Edildi':
        return Colors.red;
      case 'Tamamlandı':
        return AppColors.accent;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(String raw) {
    final dt = DateTime.parse(raw).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = appt['status'] as String? ?? 'Beklemede';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          (appt['customerName'] as String? ?? '?')
                              .isNotEmpty
                              ? (appt['customerName'] as String)[0]
                                  .toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt['customerName'] ?? 'Müşteri',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            appt['serviceName'] ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(appt['appointmentDate'] as String),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                    const Spacer(),
                    Text(
                      '${appt['durationMinutes']} dk · ₺${appt['servicePrice']}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Aksiyon butonları
          if (status == 'Beklemede') ...[
            const Divider(height: 1, color: AppColors.border),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onApprove,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(14)),
                      ),
                      child: const Center(
                        child: Text(
                          'Onayla',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.border),
                Expanded(
                  child: GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(14)),
                      ),
                      child: const Center(
                        child: Text(
                          'Reddet',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'Onaylandı') ...[
            const Divider(height: 1, color: AppColors.border),
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: const Center(
                  child: Text(
                    'Tamamlandı Olarak İşaretle',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}