import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import '../services/employee_service.dart';
import '../widgets/app_widgets.dart';

class BookingScreen extends StatefulWidget {
  final int customerId;
  final int salonId;
  final String salonName;
  // Hizmet önceden seçili gelir
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
  final EmployeeService _employeeService = EmployeeService();

  // Adım 1: Kuaför seç
  List<dynamic> _employees = [];
  Map<String, dynamic>? _selectedEmployee;
  bool _loadingEmployees = true;

  // Adım 2: Tarih seç
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  // Adım 3: Saat seç
  List<TimeOfDay> _availableSlots = [];
  TimeOfDay? _selectedTime;
  bool _loadingSlots = false;

  // Genel
  bool _isBooking = false;
  int _step = 0; // 0=kuaför, 1=tarih, 2=saat, 3=özet

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loadingEmployees = true);
    final list = await _employeeService.getSalonEmployees(widget.salonId);
    setState(() {
      _employees = list;
      _loadingEmployees = false;
    });
  }

  Future<void> _loadSlots() async {
    if (_selectedEmployee == null) return;
    setState(() {
      _loadingSlots = true;
      _selectedTime = null;
      _availableSlots = [];
    });

    final stylistId = _selectedEmployee!['userId'] as int;
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final busyRaw = await _appointmentService.getBusySlots(stylistId, dateStr);

    // Dolu aralıkları hesapla
    final List<_TimeRange> busyRanges = busyRaw.map((b) {
      final dt = DateTime.parse(b['appointmentDate']).toLocal();
      final dur = b['durationMinutes'] as int;
      return _TimeRange(
        start: TimeOfDay(hour: dt.hour, minute: dt.minute),
        durationMinutes: dur,
      );
    }).toList();

    // 09:00 - 20:00 arası 30 dakikalık slotlar üret
    final List<TimeOfDay> slots = [];
    for (int h = 9; h < 20; h++) {
      for (int m = 0; m < 60; m += 30) {
        final slot = TimeOfDay(hour: h, minute: m);
        // Bu slot + hizmet süresi dolu mu?
        final slotStart = _toMinutes(slot);
        final slotEnd = slotStart + widget.serviceDurationMinutes;
        // Gün sonu aşıyor mu?
        if (slotEnd > _toMinutes(const TimeOfDay(hour: 20, minute: 0))) continue;

        bool conflict = false;
        for (final busy in busyRanges) {
          final busyStart = _toMinutes(busy.start);
          final busyEnd = busyStart + busy.durationMinutes;
          // Çakışma: slotStart < busyEnd && slotEnd > busyStart
          if (slotStart < busyEnd && slotEnd > busyStart) {
            conflict = true;
            break;
          }
        }
        if (!conflict) slots.add(slot);
      }
    }

    setState(() {
      _availableSlots = slots;
      _loadingSlots = false;
    });
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _availableSlots = [];
      });
      await _loadSlots();
    }
  }

  Future<void> _book() async {
    if (_selectedEmployee == null || _selectedTime == null) return;
    setState(() => _isBooking = true);

    final appointmentDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final result = await _appointmentService.createAppointment(
      customerId: widget.customerId,
      stylistId: _selectedEmployee!['userId'] as int,
      salonId: widget.salonId,
      serviceId: widget.serviceId,
      appointmentDate: appointmentDate,
      durationMinutes: widget.serviceDurationMinutes,
    );

    setState(() => _isBooking = false);

    if (!mounted) return;

    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // Başarılı
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: Color(0xFF10B981), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Randevu Alındı!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year} '
              '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')} '
              'tarihinde ${_selectedEmployee!['fullName']} ile randevunuz oluşturuldu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog kapat
              Navigator.pop(context); // booking ekranını kapat
            },
            child: const Text(
              'Tamam',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
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
                        'RANDEVU AL',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Adım adım randevu oluştur',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Adım göstergesi
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: Row(
              children: [
                _StepDot(index: 0, current: _step, label: 'Kuaför'),
                _StepLine(active: _step >= 1),
                _StepDot(index: 1, current: _step, label: 'Tarih'),
                _StepLine(active: _step >= 2),
                _StepDot(index: 2, current: _step, label: 'Saat'),
                _StepLine(active: _step >= 3),
                _StepDot(index: 3, current: _step, label: 'Özet'),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hizmet özeti
                  _ServiceSummaryCard(
                    name: widget.serviceName,
                    price: widget.servicePrice,
                    duration: widget.serviceDurationMinutes,
                    salonName: widget.salonName,
                  ),
                  const SizedBox(height: 20),

                  // Adım 0: Kuaför Seç
                  _SectionHeader(
                    title: '1. Kuaför Seçin',
                    done: _selectedEmployee != null,
                  ),
                  const SizedBox(height: 10),
                  _loadingEmployees
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(
                                color: AppColors.accent),
                          ),
                        )
                      : _employees.isEmpty
                          ? _EmptyCard(text: 'Bu salonda kuaför bulunamadı.')
                          : Column(
                              children: _employees.map((emp) {
                                final isSelected =
                                    _selectedEmployee?['id'] == emp['id'];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedEmployee = emp;
                                      _step = 1;
                                      _selectedTime = null;
                                      _availableSlots = [];
                                    });
                                    _loadSlots();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                    .withOpacity(0.15)
                                                : AppColors.accent
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              (emp['fullName'] as String)
                                                      .isNotEmpty
                                                  ? (emp['fullName'] as String)[
                                                          0]
                                                      .toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color: isSelected
                                                    ? AppColors.white
                                                    : AppColors.accent,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            emp['fullName'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected
                                                  ? AppColors.white
                                                  : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded,
                                              color: AppColors.accent, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                  if (_step >= 1) ...[
                    const SizedBox(height: 20),
                    // Adım 1: Tarih Seç
                    _SectionHeader(
                      title: '2. Tarih Seçin',
                      done: _step >= 2,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_today_rounded,
                                  color: AppColors.accent, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                _formatDate(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_rounded,
                                color: AppColors.muted, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (_step >= 1) ...[
                    const SizedBox(height: 20),
                    // Adım 2: Saat Seç
                    _SectionHeader(
                      title: '3. Saat Seçin',
                      done: _selectedTime != null,
                    ),
                    const SizedBox(height: 10),
                    _loadingSlots
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                  color: AppColors.accent),
                            ),
                          )
                        : _availableSlots.isEmpty
                            ? _EmptyCard(
                                text:
                                    'Bu gün için müsait saat yok. Farklı bir tarih deneyin.')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _availableSlots.map((slot) {
                                  final isSelected = _selectedTime == slot;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedTime = slot;
                                        _step = 3;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: Text(
                                        _formatTime(slot),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                  ],

                  // Adım 3: Özet + Onayla
                  if (_step >= 3 && _selectedTime != null) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(title: '4. Randevu Özeti', done: false),
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
                          _SummaryRow(
                              icon: Icons.store_outlined,
                              label: 'Salon',
                              value: widget.salonName),
                          const Divider(height: 20, color: AppColors.border),
                          _SummaryRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Kuaför',
                              value: _selectedEmployee!['fullName'] ?? ''),
                          const Divider(height: 20, color: AppColors.border),
                          _SummaryRow(
                              icon: Icons.content_cut_rounded,
                              label: 'Hizmet',
                              value: widget.serviceName),
                          const Divider(height: 20, color: AppColors.border),
                          _SummaryRow(
                              icon: Icons.calendar_today_rounded,
                              label: 'Tarih',
                              value: _formatDate(_selectedDate)),
                          const Divider(height: 20, color: AppColors.border),
                          _SummaryRow(
                              icon: Icons.access_time_rounded,
                              label: 'Saat',
                              value: _formatTime(_selectedTime!)),
                          const Divider(height: 20, color: AppColors.border),
                          _SummaryRow(
                              icon: Icons.attach_money_rounded,
                              label: 'Ücret',
                              value: '₺${widget.servicePrice.toStringAsFixed(0)}'),
                          const Divider(height: 20, color: AppColors.border),
                          _SummaryRow(
                              icon: Icons.timer_outlined,
                              label: 'Süre',
                              value: '${widget.serviceDurationMinutes} dakika'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _isBooking ? null : _book,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: _isBooking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Randevuyu Onayla',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dolu slot için yardımcı sınıf
class _TimeRange {
  final TimeOfDay start;
  final int durationMinutes;
  _TimeRange({required this.start, required this.durationMinutes});
}

// Alt widget'lar
class _StepDot extends StatelessWidget {
  final int index;
  final int current;
  final String label;
  const _StepDot(
      {required this.index, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done
                ? const Color(0xFF10B981)
                : active
                    ? AppColors.primary
                    : AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Icon(
            done ? Icons.check_rounded : Icons.circle,
            color: Colors.white,
            size: done ? 16 : 8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppColors.primary : AppColors.muted,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool active;
  const _StepLine({required this.active});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: active ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

class _ServiceSummaryCard extends StatelessWidget {
  final String name;
  final double price;
  final int duration;
  final String salonName;
  const _ServiceSummaryCard({
    required this.name,
    required this.price,
    required this.duration,
    required this.salonName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.content_cut_rounded,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$salonName · $duration dk',
                  style: const TextStyle(
                      color: AppColors.white, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
          Text(
            '₺${price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool done;
  const _SectionHeader({required this.title, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const Spacer(),
        if (done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Seçildi ✓',
              style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ),
    );
  }
}