import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'login_page.dart';
import 'profile_page.dart';
import '../screens/reviews_screen.dart';
import '../screens/campaigns_screen.dart';
import '../screens/notifications_screen.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final AuthService _authService = AuthService();
  int _userId = 0;
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
              bottom: 24,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MÜŞTERİ',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hoş geldiniz, $_userName',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          NotificationsScreen(userId: _userId),
                    ),
                  ),
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _logout(context),
                  child: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CampaignsScreen(),
                        ),
                      );
                    },
                    child: const Text("Kampanyalar"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReviewsScreen(
                            salonId: 1,
                            userId: _userId,
                          ),
                        ),
                      );
                    },
                    child: const Text("Yorumlar"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              NotificationsScreen(userId: _userId),
                        ),
                      );
                    },
                    child: const Text("Bildirimler"),
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