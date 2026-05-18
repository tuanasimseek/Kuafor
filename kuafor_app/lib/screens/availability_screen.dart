import 'package:flutter/material.dart';
import '../services/availability_service.dart';
import '../widgets/app_widgets.dart';

class AvailabilityScreen extends StatefulWidget {
  final int userId;
  const AvailabilityScreen({super.key, required this.userId});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  final List<String> _days = [
    'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'
  ];

  // Her gün için açık/kapalı ve saat bilgisi
  final Map<String, bool> _isOpen = {
    'Pazartesi': true,
    'Salı': true,
    'Çarşamba': true,
    'Perşembe': true,
    'Cuma': true,
    'Cumartesi': false,
    'Pazar': false,
  };

  final Map<String, TimeOfDay> _openTime = {
    'Pazartesi': const TimeOfDay(hour: 9, minute: 0),
    'Salı': const TimeOfDay(hour: 9, minute: 0),
    'Çarşamba': const TimeOfDay(hour: 9, minute: 0),
    'Perşembe': const TimeOfDay(hour: 9, minute: 0),
    'Cuma': const TimeOfDay(hour: 9, minute: 0),
    'Cumartesi': const TimeOfDay(hour: 10, minute: 0),
    'Pazar': const TimeOfDay(hour: 10, minute: 0),
  };

  final Map<String, TimeOfDay> _closeTime = {
    'Pazartesi': const TimeOfDay(hour: 18, minute: 0),
    'Salı': const TimeOfDay(hour: 18, minute: 0),
    'Çarşamba': const TimeOfDay(hour: 18, minute: 0),
    'Perşembe': const TimeOfDay(hour: 18, minute: 0),
    'Cuma': const TimeOfDay(hour: 18, minute: 0),
    'Cumartesi': const TimeOfDay(hour: 17, minute: 0),
    'Pazar': const TimeOfDay(hour: 17, minute: 0),
  };

  bool _isSaving = false;
  bool _isLoading = true;

  static const List<String> _timeOptions = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
    '11:00', '11:30', '12:00', '12:30', '13:00', '13:30',
    '14:00', '14:30', '15:00', '15:30', '16:00', '16:30',
    '17:00', '17:30', '18:00', '18:30', '19:00', '19:30',
    '20:00', '20:30', '21:00',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _parseTime(String raw) {
    final parts = raw.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _load() async {
    final rows = await _availabilityService.getStylistAvailability(widget.userId);
    if (!mounted) return;
    setState(() {
      for (final row in rows) {
        final dayIndex = (row['dayOfWeek'] ?? row['DayOfWeek'] ?? 1) as int;
        final day = _days[dayIndex - 1];
        _isOpen[day] = row['isOpen'] ?? row['IsOpen'] ?? true;
        _openTime[day] = _parseTime((row['openTime'] ?? row['OpenTime'] ?? '09:00').toString().substring(0, 5));
        _closeTime[day] = _parseTime((row['closeTime'] ?? row['CloseTime'] ?? '18:00').toString().substring(0, 5));
      }
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final rows = List.generate(_days.length, (index) {
      final day = _days[index];
      return {
        'dayOfWeek': index + 1,
        'isOpen': _isOpen[day]!,
        'openTime': _formatTime(_openTime[day]!),
        'closeTime': _formatTime(_closeTime[day]!),
      };
    });
    final ok = await _availabilityService.saveStylistAvailability(
      stylistId: widget.userId,
      rows: rows,
    );
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Çalışma saatleri kaydedildi' : 'Saatler kaydedilemedi'),
        backgroundColor: Color(0xFF0F172A),
      ),
    );
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
                      'ÇALIŞMA SAATLERİ',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Randevu alınabilecek saatleri ayarlayın',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._days.map((day) {
                  final open = _isOpen[day]!;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: open
                            ? AppColors.border
                            : AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: open
                                      ? AppColors.primary
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isOpen[day] = !open),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: open
                                      ? AppColors.accent
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: open
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              open ? 'Açık' : 'Kapalı',
                              style: TextStyle(
                                fontSize: 12,
                                color: open ? AppColors.accent : AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (open) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _TimeDropdown(
                                  label: 'Başlangıç',
                                  value: _formatTime(_openTime[day]!),
                                  options: _timeOptions,
                                  onChanged: (value) => setState(() => _openTime[day] = _parseTime(value)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TimeDropdown(
                                  label: 'Bitiş',
                                  value: _formatTime(_closeTime[day]!),
                                  options: _timeOptions,
                                  onChanged: (value) => setState(() => _closeTime[day] = _parseTime(value)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isSaving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Kaydet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _TimeDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.contains(value) ? value : options.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted),
          items: options.map((time) {
            return DropdownMenuItem(
              value: time,
              child: Text(
                '$label  $time',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
