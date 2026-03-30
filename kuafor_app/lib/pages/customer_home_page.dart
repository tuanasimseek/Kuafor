import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'login_page.dart';
import 'profile_page.dart';
import '../screens/reviews_screen.dart';
import '../screens/campaigns_screen.dart';
import '../screens/notifications_screen.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().deleteToken();
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
          // ── Üst başlık ────────────────────────────────────
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
                    children: const [
                      Text(
                        'STİLİST',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hoş geldiniz',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(userId: 1))),
                  child: _HeaderBtn(icon: Icons.notifications_outlined),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfilePage())),
                  child: _HeaderBtn(icon: Icons.person_outline_rounded),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _logout(context),
                  child: _HeaderBtn(
                      icon: Icons.logout_rounded, accent: true),
                ),
              ],
            ),
          ),

          // ── İçerik ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ne yapmak istersiniz?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _MenuCard(
                    icon: Icons.campaign_outlined,
                    title: 'Kampanyalar',
                    subtitle: 'Aktif indirim ve fırsatları görüntüle',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const CampaignsScreen())),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.star_outline_rounded,
                    title: 'Yorumlar',
                    subtitle: 'Salon yorumlarını gör ve yorum ekle',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const ReviewsScreen(salonId: 1, userId: 1))),
                  ),
                  const SizedBox(height: 10),
                  _MenuCard(
                    icon: Icons.notifications_outlined,
                    title: 'Bildirimler',
                    subtitle: 'Randevu ve salon bildirimlerini görüntüle',
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const NotificationsScreen(userId: 1))),
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

// ── Header ikon butonu ───────────────────────────────────────
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

// ── Menü kartı ───────────────────────────────────────────────
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