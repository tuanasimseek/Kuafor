import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';

class AvailabilityScreen extends StatefulWidget {
  final int userId;
  const AvailabilityScreen({super.key, required this.userId});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
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

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime(String day, bool isOpen) async {
    final initial = isOpen ? _openTime[day]! : _closeTime[day]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F172A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTime[day] = picked;
        } else {
          _closeTime[day] = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Müsaitlik saatleri kaydedildi ✓'),
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
                      'MÜSAİTLİK SAATLERİ',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Çalışma takviminizi ayarlayın',
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
            child: ListView(
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
                                child: GestureDetector(
                                  onTap: () => _pickTime(day, true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.login_rounded,
                                            size: 14, color: AppColors.muted),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatTime(_openTime[day]!),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Giriş',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _pickTime(day, false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.logout_rounded,
                                            size: 14, color: AppColors.muted),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatTime(_closeTime[day]!),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Çıkış',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.muted),
                                        ),
                                      ],
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