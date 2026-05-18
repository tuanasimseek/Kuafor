import 'dart:async';
import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../services/availability_service.dart';
import '../services/salon_service.dart';
import '../widgets/app_widgets.dart';

class BookingScreen extends StatefulWidget {
  final int customerId;
  final int salonId;
  final String salonName;
  final int serviceId;
  final String serviceName;
  final double servicePrice;
  final int serviceDurationMinutes;

  const BookingScreen({
    super.key,
    required this.customerId,
    required this.salonId,
    required this.salonName,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDurationMinutes,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  final SalonService _salonService = SalonService();

  int _step = 0;

  List<dynamic> _stylists = [];
  bool _loadingStylists = true;

  Map<String, dynamic>? _selectedStylist;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay? _selectedTime;

  List<DateTime> _busySlots = [];
  List<dynamic> _availabilityRows = [];
  bool _loadingSlots = false;

  bool _booking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStylists();
  }

  Future<void> _loadStylists() async {
    setState(() => _loadingStylists = true);

    // Önce Employee endpoint'ini dene
    final employees = await _salonService.getEmployeesBySalon(widget.salonId);
    print('[BookingScreen] employees from /Employee/salon: $employees');

    if (employees.isNotEmpty) {
      if (mounted) {
        setState(() {
          _stylists = employees;
          _loadingStylists = false;
        });
      }
      return;
    }

    // Fallback: services içindeki stylistName'lerden stilist listesi oluştur
    // Bu durumda stylistId olmayacak — sadece isim gösterilir
    final salon = await _salonService.getSalonDetail(widget.salonId);
    final services = (salon?['services'] as List<dynamic>?) ?? [];
    print('[BookingScreen] services fallback: $services');

    // stylistName'e göre tekrarsız stilist listesi
    final Map<String, Map<String, dynamic>> stylistMap = {};
    for (final s in services) {
      final stylistName = s['stylistName'] as String?;
      if (stylistName != null && stylistName.isNotEmpty) {
        stylistMap[stylistName] = {
          'id': null,       // stylistId yok — backend'den gelmiyor
          'userId': null,
          'user': {
            'fullName': stylistName,
            'specialty': '',
            'rating': 0,
          },
          '_fromServices': true, // flag: bu fallback verisi
        };
      }
    }

    if (mounted) {
      setState(() {
        _stylists = stylistMap.values.toList();
        _loadingStylists = false;
      });
    }
  }

  Future<void> _loadBusySlots() async {
    if (_selectedStylist == null) return;
    final stylistId = _selectedStylist!['userId'] ?? _selectedStylist!['id'];
    // stylistId yoksa busy slot kontrolü atla
    if (stylistId == null) return;
    setState(() => _loadingSlots = true);
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final slots = await _appointmentService.getBusySlots(stylistId as int, dateStr);
    final availability = await _availabilityService.getStylistAvailability(stylistId);
    if (mounted) {
      setState(() {
        _busySlots = _appointmentService.parseBusySlotDates(slots);
        _availabilityRows = availability;
        _loadingSlots = false;
      });
    }
  }

  bool _isSlotBusy(TimeOfDay time) {
    final candidate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
    for (final busy in _busySlots) {
      final diff = candidate.difference(busy).abs().inMinutes;
      if (diff < widget.serviceDurationMinutes) return true;
    }
    return false;
  }

  List<TimeOfDay> _generateTimeSlots() {
    final businessDay = _selectedDate.weekday;
    Map<String, dynamic>? row;
    for (final item in _availabilityRows) {
      if (item is Map<String, dynamic>) {
        final day = item['dayOfWeek'] ?? item['DayOfWeek'];
        if (day == businessDay) {
          row = item;
          break;
        }
      }
    }

    if (row != null) {
      final isOpen = row['isOpen'] ?? row['IsOpen'] ?? true;
      if (isOpen == false) return [];
      final open = _parseTime((row['openTime'] ?? row['OpenTime'] ?? '09:00').toString());
      final close = _parseTime((row['closeTime'] ?? row['CloseTime'] ?? '20:00').toString());
      return _generateSlotsBetween(open, close);
    }

    final slots = <TimeOfDay>[];
    for (int h = 9; h < 20; h++) {
      slots.add(TimeOfDay(hour: h, minute: 0));
      slots.add(TimeOfDay(hour: h, minute: 30));
    }
    return slots;
  }

  TimeOfDay _parseTime(String raw) {
    final clean = raw.length >= 5 ? raw.substring(0, 5) : raw;
    final parts = clean.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  List<TimeOfDay> _generateSlotsBetween(TimeOfDay open, TimeOfDay close) {
    final slots = <TimeOfDay>[];
    var minutes = open.hour * 60 + open.minute;
    final closeMinutes = close.hour * 60 + close.minute;
    while (minutes + widget.serviceDurationMinutes <= closeMinutes) {
      slots.add(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
      minutes += 30;
    }
    return slots;
  }

  bool _isDateSelectable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !date.isBefore(today);
  }

  Future<void> _book() async {
    if (_selectedStylist == null || _selectedTime == null) return;

    final stylistId = _selectedStylist!['userId'] ?? _selectedStylist!['id'];

    // stylistId yoksa (fallback modunda) hata göster
    if (stylistId == null) {
      setState(() => _error =
          'Stilist ID bilgisi alınamadı. Lütfen salon yöneticisiyle iletişime geçin.');
      return;
    }

    setState(() { _booking = true; _error = null; });

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final result = await _appointmentService.createAppointment(
      customerId: widget.customerId,
      stylistId: stylistId as int,
      salonId: widget.salonId,
      serviceId: widget.serviceId,
      appointmentDate: dt,
      durationMinutes: widget.serviceDurationMinutes,
    );

    if (!mounted) return;
    setState(() => _booking = false);

    if (result.error == null) {
      _showSuccessSheet();
    } else {
      setState(() => _error = result.error);
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.green, size: 38),
            ),
            const SizedBox(height: 18),
            const Text(
              'Randevu Alındı!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.salonName} • ${widget.serviceName}\n'
              '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}  '
              '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.6),
            ),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Tamam',
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildStepper(),
          Expanded(child: _buildStep()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 20,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RANDEVU AL',
                    style: TextStyle(color: AppColors.accent, fontSize: 11,
                        fontWeight: FontWeight.w600, letterSpacing: 2)),
                const SizedBox(height: 2),
                Text(widget.serviceName,
                    style: const TextStyle(color: AppColors.white,
                        fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '₺${widget.servicePrice.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.accent,
                  fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['Stilist', 'Tarih', 'Saat', 'Özet'];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < _step ? AppColors.accent : AppColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex < _step;
          final active = stepIndex == _step;
          return Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.accent : active ? AppColors.primary : AppColors.border,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: active ? Colors.white : AppColors.muted,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                  color: active ? AppColors.primary : AppColors.muted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _buildStylistStep();
      case 1: return _buildDateStep();
      case 2: return _buildTimeStep();
      case 3: return _buildSummaryStep();
      default: return const SizedBox();
    }
  }

  Widget _buildStylistStep() {
    if (_loadingStylists) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    if (_stylists.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Bu salonda stilist bulunamadı.',
              style: TextStyle(color: AppColors.muted)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stylists.length,
      itemBuilder: (_, i) {
        final s = _stylists[i];
        final user = s['user'] as Map<String, dynamic>? ?? s;
        final name = user['fullName'] ?? user['name'] ?? 'Stilist';
        final specialty = user['specialty'] as String? ?? '';
        final rating = (user['rating'] as num?)?.toDouble() ?? 0.0;
        final stylistId = s['userId'] ?? s['id'] ?? user['id'];
        final selected = _selectedStylist != null &&
            ((_selectedStylist!['userId'] ?? _selectedStylist!['id']) ==
                stylistId);

        return GestureDetector(
          onTap: () => setState(() => _selectedStylist = s),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.accent,
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600, color: AppColors.primary)),
                      if (specialty.isNotEmpty)
                        Text(specialty,
                            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      if (rating > 0)
                        Row(children: [
                          const Icon(Icons.star_rounded, size: 13,
                              color: Color(0xFFFBBF24)),
                          const SizedBox(width: 3),
                          Text(rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted)),
                        ]),
                      // fallback uyarısı
                      if (s['_fromServices'] == true && stylistId == null)
                        const Text('* Randevu için salon sahibiyle iletişime geçin',
                            style: TextStyle(fontSize: 10, color: Colors.orange)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 22),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateStep() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, now.day);
    final lastDay = firstDay.add(const Duration(days: 60));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tarih Seçin',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: CalendarDatePicker(
              initialDate: _selectedDate.isAfter(firstDay)
                  ? _selectedDate
                  : firstDay.add(const Duration(days: 1)),
              firstDate: firstDay.add(const Duration(days: 1)),
              lastDate: lastDay,
              onDateChanged: (date) => setState(() => _selectedDate = date),
              selectableDayPredicate: _isDateSelectable,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, size: 16,
                  color: AppColors.accent),
              const SizedBox(width: 10),
              Text(
                'Seçilen: ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
                style: const TextStyle(fontSize: 13, color: AppColors.accent,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStep() {
    final slots = _generateTimeSlots();
    return _loadingSlots
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.accent))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: slots.length,
            itemBuilder: (_, i) {
              final slot = slots[i];
              final busy = _isSlotBusy(slot);
              final selected = _selectedTime != null &&
                  _selectedTime!.hour == slot.hour &&
                  _selectedTime!.minute == slot.minute;

              return GestureDetector(
                onTap: busy ? null : () => setState(() => _selectedTime = slot),
                child: Container(
                  decoration: BoxDecoration(
                    color: busy
                        ? AppColors.border.withOpacity(0.4)
                        : selected
                            ? AppColors.primary
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: busy
                            ? AppColors.muted.withOpacity(0.5)
                            : selected
                                ? Colors.white
                                : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
  }

  Widget _buildSummaryStep() {
    final stylistUser = _selectedStylist?['user'] as Map<String, dynamic>?
        ?? _selectedStylist ?? {};
    final stylistName =
        stylistUser['fullName'] ?? stylistUser['name'] ?? 'Stilist';

    final rows = [
      _SummaryRow(icon: Icons.store_outlined, label: 'Salon', value: widget.salonName),
      _SummaryRow(icon: Icons.content_cut_rounded, label: 'Hizmet', value: widget.serviceName),
      _SummaryRow(icon: Icons.person_outline_rounded, label: 'Stilist', value: stylistName),
      _SummaryRow(
        icon: Icons.calendar_today_rounded,
        label: 'Tarih',
        value: '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
      ),
      _SummaryRow(
        icon: Icons.access_time_rounded,
        label: 'Saat',
        value:
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
      ),
      _SummaryRow(
        icon: Icons.timer_outlined,
        label: 'Süre',
        value: '${widget.serviceDurationMinutes} dk',
      ),
      _SummaryRow(
        icon: Icons.payments_outlined,
        label: 'Ücret',
        value: '₺${widget.servicePrice.toStringAsFixed(0)}',
        highlight: true,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Randevu Özeti',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: List.generate(rows.length, (i) {
                return Column(
                  children: [
                    rows[i],
                    if (i < rows.length - 1)
                      const Divider(height: 1, color: AppColors.border,
                          indent: 16, endIndent: 16),
                  ],
                );
              }),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            ErrorBanner(message: _error!),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canNext = switch (_step) {
      0 => _selectedStylist != null,
      1 => true,
      2 => _selectedTime != null,
      3 => true,
      _ => false,
    };

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            GestureDetector(
              onTap: () => setState(() { _step--; _error = null; }),
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_rounded,
                    size: 16, color: AppColors.primary),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            child: _booking
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
                : GestureDetector(
                    onTap: canNext
                        ? () async {
                            if (_step == 3) {
                              await _book();
                            } else {
                              if (_step == 1) {
                                await _loadBusySlots();
                              }
                              setState(() { _step++; _error = null; });
                            }
                          }
                        : null,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: canNext ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _step == 3 ? 'Randevu Al' : 'Devam Et',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: canNext ? Colors.white : AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight ? AppColors.accent : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
