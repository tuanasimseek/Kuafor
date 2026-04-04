import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../widgets/app_widgets.dart';

class CustomerAppointmentsScreen extends StatefulWidget {
  final int customerId;
  const CustomerAppointmentsScreen({super.key, required this.customerId});

  @override
  State<CustomerAppointmentsScreen> createState() =>
      _CustomerAppointmentsScreenState();
}

class _CustomerAppointmentsScreenState
    extends State<CustomerAppointmentsScreen> {
  final AppointmentService _service = AppointmentService();
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _service.getCustomerAppointments(widget.customerId);
    });
  }

  Future<void> _cancel(Map appt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Randevuyu İptal Et',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: const Text(
            'Bu randevuyu iptal etmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç',
                style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('İptal Et',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _service.cancelAppointment(
        appt['id'] as int, widget.customerId);

    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Randevu iptal edildi'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Bir hata oluştu'),
          backgroundColor: Colors.red.shade700,
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
                      'Randevu geçmişi',
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
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent));
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.calendar_month_outlined,
                              size: 34, color: AppColors.accent),
                        ),
                        const SizedBox(height: 16),
                        const Text('Henüz randevunuz yok',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text('Salon listesinden randevu alabilirsiniz',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: AppColors.accent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snap.data!.length,
                    itemBuilder: (context, i) {
                      final a = snap.data![i];
                      return _AppointmentCard(
                        appt: a,
                        onCancel: () => _cancel(a),
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

class _AppointmentCard extends StatelessWidget {
  final Map appt;
  final VoidCallback onCancel;
  const _AppointmentCard({required this.appt, required this.onCancel});

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
    final canCancel = status == 'Beklemede' || status == 'Onaylandı';

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
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.content_cut_rounded,
                          color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appt['serviceName'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            appt['salonName'] ?? '',
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
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(appt['stylistName'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                    const Spacer(),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(appt['appointmentDate'] as String),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.attach_money_rounded,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      '₺${appt['servicePrice']}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(
                      '${appt['durationMinutes']} dk',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canCancel) ...[
            const Divider(height: 1, color: AppColors.border),
            GestureDetector(
              onTap: onCancel,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: const Center(
                  child: Text(
                    'İptal Et',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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