import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/salon_service.dart';
import '../widgets/app_widgets.dart';
import '../screens/notifications_screen.dart';
import '../screens/campaigns_screen.dart';
import '../screens/salon_detail_screen.dart';
import 'login_page.dart';
import 'profile_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final AuthService _authService = AuthService();
  final SalonService _salonService = SalonService();
  int _userId = 0;
  String _userName = '';
  late Future<List<dynamic>> _salonsFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _salonsFuture = _salonService.getSalons();
  }

  Future<void> _loadUser() async {
    final token = await _authService.getToken();
    if (token == null) return;
    final user = await _authService.getUserInfo(token);
    if (user != null) {
      setState(() {
        _userId = user['id'] ?? 0;
        _userName = user['name'] ?? '';
      });
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
              bottom: 28,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MÜŞTERİ PANELİ',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
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
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  child: const Icon(Icons.person_outline,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _logout(context),
                  child:
                      const Icon(Icons.logout, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Hızlı erişim butonları
                Row(
                  children: [
                    Expanded(
                      child: _QuickBtn(
                        icon: Icons.campaign_outlined,
                        label: 'Kampanyalar',
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CampaignsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickBtn(
                        icon: Icons.notifications_outlined,
                        label: 'Bildirimler',
                        color: AppColors.accent,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                NotificationsScreen(userId: _userId),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Salonlar
                const Text(
                  'SALONLAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<dynamic>>(
                  future: _salonsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                              color: AppColors.accent),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'Henüz salon eklenmemiş',
                            style: TextStyle(
                                color: AppColors.muted, fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: snapshot.data!.map((salon) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalonDetailScreen(
                                salonId: salon['id'],
                                userId: _userId,
                                salonName: salon['name'] ?? 'Salon',
                              ),
                            ),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.store_outlined,
                                      color: AppColors.accent, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        salon['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (salon['address'] != null &&
                                          salon['address']
                                              .toString()
                                              .isNotEmpty)
                                        Text(
                                          salon['address'],
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.muted),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.muted, size: 20),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}