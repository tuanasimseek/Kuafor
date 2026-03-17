import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Müşteri Paneli"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(userId: _userId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.deleteToken();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hoş geldiniz, $_userName 💇‍♀️',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _MenuCard(
              icon: Icons.campaign,
              title: 'Kampanyalar',
              subtitle: 'Aktif indirim ve fırsatları görüntüle',
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampaignsScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.star,
              title: 'Yorumlar',
              subtitle: 'Salon yorumlarını gör ve yorum ekle',
              color: Colors.amber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(salonId: 1, userId: _userId),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.notifications,
              title: 'Bildirimler',
              subtitle: 'Randevu ve salon bildirimlerini görüntüle',
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(userId: _userId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}