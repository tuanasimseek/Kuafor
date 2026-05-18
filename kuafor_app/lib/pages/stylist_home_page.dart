import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/salon_service.dart';
import '../widgets/app_widgets.dart';
import '../screens/notifications_screen.dart';
import '../screens/availability_screen.dart';
import '../screens/stylist_appointments_screen.dart';
import '../screens/stylist_services_screen.dart';
import 'login_page.dart';
import 'profile_page.dart';

class StylistHomePage extends StatefulWidget {
  const StylistHomePage({super.key});

  @override
  State<StylistHomePage> createState() => _StylistHomePageState();
}

class _StylistHomePageState extends State<StylistHomePage> {
  final AuthService _authService = AuthService();
  final SalonService _salonService = SalonService();
  int _userId = 0;
  int _salonId = 0;
  String _userName = '';
  bool _loadingUser = true;
  bool _salonFound = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _loadingUser = true);

    final token = await _authService.getToken();
    if (token == null) {
      setState(() => _loadingUser = false);
      return;
    }

    final user = await _authService.getUserInfo(token);
    if (user != null) {
      final userId = user['id'] ?? 0;
      setState(() {
        _userId = userId;
        _userName = user['name'] ?? '';
      });

      final salon = await _salonService.getSalonByStylist(userId);
      if (salon != null) {
        setState(() {
          _salonId = salon['id'] ?? 0;
          _salonFound = true;
        });
      } else {
        setState(() {
          _salonId = 0;
          _salonFound = false;
        });
      }
    }

    setState(() => _loadingUser = false);
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.deleteToken();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openServices() {
    if (_loadingUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bilgiler yükleniyor, lütfen bekleyin...')),
      );
      return;
    }
    if (_salonId == 0 || !_salonFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bir salona kayıtlı değilsiniz. Salon sahibiyle iletişime geçin.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StylistServicesScreen(
          stylistId: _userId,
          salonId: _salonId,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STİLİST',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loadingUser
                            ? 'Yükleniyor...'
                            : 'Hoş geldiniz, $_userName',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(userId: _userId),
                    ),
                  ),
                  child: _HeaderBtn(icon: Icons.notifications_outlined),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  child: _HeaderBtn(icon: Icons.person_outline_rounded),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _logout(context),
                  child:
                      _HeaderBtn(icon: Icons.logout_rounded, accent: true),
                ),
              ],
            ),
          ),

          if (!_loadingUser && !_salonFound)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Henüz bir salona kayıtlı değilsiniz. Salon sahibiyle iletişime geçin.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _loadingUser
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.accent),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'İşlemler',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // ← Artık gerçek ekrana yönlendirir
                        _MenuCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Randevularım',
                          subtitle: 'Günlük ve haftalık randevularını gör',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StylistAppointmentsScreen(
                                  stylistId: _userId),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MenuCard(
                          icon: Icons.content_cut_rounded,
                          title: 'Hizmetlerim',
                          subtitle: 'Sunduğun hizmetleri düzenle',
                          onTap: _openServices,
                          disabled: _salonId == 0,
                        ),
                        const SizedBox(height: 10),
                        _MenuCard(
                          icon: Icons.notifications_outlined,
                          title: 'Bildirimler',
                          subtitle: 'Randevu ve sistem bildirimlerini gör',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NotificationsScreen(userId: _userId),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _MenuCard(
                          icon: Icons.access_time_rounded,
                          title: 'Çalışma Saatleri',
                          subtitle: 'Randevu alınabilecek saatleri ayarla',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AvailabilityScreen(userId: _userId),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final bool accent;
  const _HeaderBtn({required this.icon, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Icon(icon,
          color: accent ? AppColors.accent : AppColors.white, size: 20),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool disabled;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
