import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  final String token;
  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await _authService.getUserInfo(widget.token);
    setState(() {
      _userData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kuaför Ana Sayfa")),
      body: Center(
        child: _userData == null
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text("Kullanıcı bilgisi alınamadı ❌"),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Hoş geldin ${_userData!['name'] ?? 'Kullanıcı'} 👋",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("E-posta: ${_userData!['email']}", style: const TextStyle(fontSize: 18)),
            Text("Rol: ${_userData!['role'] ?? '-'}", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
