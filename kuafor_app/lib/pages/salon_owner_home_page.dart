import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/salon_service.dart';
import '../widgets/app_widgets.dart';
import '../screens/notifications_screen.dart';
import '../screens/campaigns_screen.dart';
import '../screens/reviews_readonly_screen.dart';
import '../screens/services_management_screen.dart';
import '../screens/appointments_placeholder_screen.dart';
import 'login_page.dart';
import 'profile_page.dart';

class SalonOwnerHomePage extends StatefulWidget {
  const SalonOwnerHomePage({super.key});

  @override
  State<SalonOwnerHomePage> createState() => _SalonOwnerHomePageState();
}

class _SalonOwnerHomePageState extends State<SalonOwnerHomePage> {
  final AuthService _authService = AuthService();
  final SalonService _salonService = SalonService();
  int _userId = 0;
  int _salonId = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final user = await _authService.getUserInfo(token);
    if (user != null) {
      final userId = user['id'] ?? 0;
      setState(() {
        _userId = userId;
        _userName = user['name'] ?? '';
      });
      final salon = await _salonService.getSalonByOwner(userId);
      if (salon != null) {
        setState(() => _salonId = salon['id'] ?? 0);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.deleteToken();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
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
                        'SALON SAHİBİ',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hoş geldiniz, $_userName',
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
                  child: _HeaderBtn(icon: Icons.logout_rounded, accent: true),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Salon Yönetimi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MenuCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Çalışanlar',
                    subtitle: 'Kuaförlerini ve personelini yönet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AppointmentsPlaceholderScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.content_cut_rounded,
                    title: 'Hizmetler',
                    subtitle: 'Salon hizmetlerini düzenle ve fiyatlandır',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServicesManagementScreen(salonId: _salonId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Randevular',
                    subtitle: 'Tüm salon randevularını görüntüle',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AppointmentsPlaceholderScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.campaign_outlined,
                    title: 'Kampanyalar',
                    subtitle: 'Aktif kampanyaları görüntüle ve yönet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CampaignsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.star_outline_rounded,
                    title: 'Yorumlar',
                    subtitle: 'Müşteri yorumlarını takip et',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReviewsReadOnlyScreen(salonId: _salonId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.notifications_outlined,
                    title: 'Bildirimler',
                    subtitle: 'Salon bildirimlerini görüntüle',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsScreen(userId: _userId),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Raporlar',
                    subtitle: 'Gelir ve performans istatistikleri',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AppointmentsPlaceholderScreen(),
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

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }
}