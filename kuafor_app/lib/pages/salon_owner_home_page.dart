import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'profile_page.dart';

class SalonOwnerHomePage extends StatelessWidget {
  const SalonOwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Salon Sahibi Paneli"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().deleteToken();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text("Çalışanları ve salon hizmetlerini yönet 🏢"),
      ),
    );
  }
}