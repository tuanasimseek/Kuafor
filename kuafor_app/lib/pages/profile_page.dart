import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  String name = "";
  String email = "";
  String role = "";

  bool _isLoading = true;
  bool _isLoggingOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = "Oturum bulunamadı. Lütfen tekrar giriş yapın.";
      });
      return;
    }

    final user = await _authService.getUserInfo(token);

    if (!mounted) return;

    if (user != null) {
      setState(() {
        name = user['name'] ?? '';
        email = user['email'] ?? '';
        role = user['role'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Kullanıcı bilgileri alınamadı.";
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    await _authService.deleteToken();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ad Soyad: $name",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Email: $email",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              "Rol: $role",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            _isLoggingOut
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _isLoggingOut ? null : _logout,
              child: const Text("Çıkış Yap"),
            ),
          ],
        ),
      ),
    );
  }
}