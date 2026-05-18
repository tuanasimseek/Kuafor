import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../widgets/app_widgets.dart';

class SalonOwnerAppointmentsScreen extends StatefulWidget {
  final int salonId;
  const SalonOwnerAppointmentsScreen({super.key, required this.salonId});

  @override
  State<SalonOwnerAppointmentsScreen> createState() =>
      _SalonOwnerAppointmentsScreenState();
}

class _SalonOwnerAppointmentsScreenState
    extends State<SalonOwnerAppointmentsScreen> {
  final AppointmentService _service = AppointmentService();
  late Future<List<dynamic>> _future;
  String _filter = 'All';

  // Türkçe etiket → backend değeri
  static const Map<String, String> _filterMap = {
    'Tümü':        'All',
    'Beklemede':   'Pending',
    'Onaylandı':   'Confirmed',
    'Tamamlandı':  'Completed',
    'İptal Edildi':'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = _service.getSalonAppointments(widget.salonId);
    });
  }

  Future<void> _updateStatus(int id, String backendStatus) async {
    final ok = await _service.updateStatus(id, backendStatus);
    if (!mounted) return;
    if (ok) {
      final label = _filterMap.entries
          .firstWhere((e) => e.value == backendStatus,
              orElse: () => const MapEntry('Güncellendi', ''))
          .key;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum: $label'),
          backgroundColor: AppColors.primary,
        ),
      );
      _load();
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':  return const Color(0xFF10B981);
      case 'Cancelled':  return Colors.red;
      case 'Completed':  return AppColors.accent;
      default:           return Colors.orange; // Pending
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Confirmed':  return 'Onaylandı';
      case 'Cancelled':  return 'İptal Edildi';
      case 'Completed':  return 'Tamamlandı';
      default:           return 'Beklemede';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24, right: 24, bottom: 24,
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
                    Text('TÜM RANDEVULAR',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5)),
                    SizedBox(height: 2),
                    Text('Salon randevu yönetimi',
                        style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          // ── Filtre ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterMap.entries.map((entry) {
                  final active = _filter == entry.value;
                  return GestureDetector(
                    onTap: () => setState(() => _filter = entry.value),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: active ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.normal,
                          color: active ? AppColors.white : AppColors.muted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Liste ─────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent));
                }

                final all = snap.data ?? [];
                final filtered = _filter == 'All'
                    ? all
                    : all
                        .where((a) =>
                            _statusCode(a) == _filter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 68, height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.calendar_month_outlined,
                              size: 34, color: AppColors.accent),
                        ),
                        const SizedBox(height: 16),
                        const Text('Randevu bulunamadı',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
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
                      final status = _statusCode(a);
                      return _OwnerAppointmentCard(
                        appt: a,
                        statusLabel: _statusLabel(status),
                        statusColor: _statusColor(status),
                        onApprove: status == 'Pending'
                            ? () => _updateStatus(a['id'] as int, 'Confirmed')
                            : null,
                        onCancel: (status == 'Pending' || status == 'Confirmed')
                            ? () => _updateStatus(a['id'] as int, 'Cancelled')
                            : null,
                        onComplete: status == 'Confirmed'
                            ? () => _updateStatus(a['id'] as int, 'Completed')
                            : null,
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

  String _statusCode(dynamic appt) {
    final status = (appt['statusCode'] ?? appt['status'] ?? appt['Status'] ?? 'Pending').toString();
    switch (status) {
      case 'Onaylandı':
      case 'Confirmed':
        return 'Confirmed';
      case 'İptal Edildi':
      case 'Cancelled':
        return 'Cancelled';
      case 'Tamamlandı':
      case 'Completed':
        return 'Completed';
      default:
        return 'Pending';
    }
  }
}

class _OwnerAppointmentCard extends StatelessWidget {
  final Map appt;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback? onApprove;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;

  const _OwnerAppointmentCard({
    required this.appt,
    required this.statusLabel,
    required this.statusColor,
    this.onApprove,
    this.onCancel,
    this.onComplete,
  });

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}'
          '  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActions =
        onApprove != null || onCancel != null || onComplete != null;

    final customerName = appt['customerName']
        ?? appt['customer']?['fullName']
        ?? appt['Customer']?['FullName']
        ?? 'Müşteri';
    final serviceName = appt['serviceName']
        ?? appt['service']?['name']
        ?? appt['Service']?['Name']
        ?? '';
    final stylistName = appt['stylistName']
        ?? appt['stylist']?['fullName']
        ?? appt['Stylist']?['FullName']
        ?? '';
    final dateRaw = (appt['appointmentDate']
        ?? appt['AppointmentDate']
        ?? '') as String;
    final duration = appt['durationMinutes']
        ?? appt['service']?['durationMinutes']
        ?? appt['Service']?['DurationMinutes']
        ?? 0;
    final price = appt['servicePrice']
        ?? appt['service']?['price']
        ?? appt['Service']?['Price']
        ?? 0;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customerName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                          Text(
                            [serviceName, stylistName]
                                .where((s) => s.isNotEmpty)
                                .join(' · '),
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
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
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
                    Text(dateRaw.isNotEmpty ? _formatDate(dateRaw) : '—',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                    const Spacer(),
                    Text('$duration dk · ₺$price',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          if (hasActions) ...[
            const Divider(height: 1, color: AppColors.border),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onApprove,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text('Onayla',
                              style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                if (onApprove != null &&
                    (onCancel != null || onComplete != null))
                  Container(width: 1, height: 40, color: AppColors.border),
                if (onComplete != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onComplete,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text('Tamamlandı',
                              style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                if (onComplete != null && onCancel != null)
                  Container(width: 1, height: 40, color: AppColors.border),
                if (onCancel != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancel,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text('İptal Et',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
