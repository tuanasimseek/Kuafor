import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'customer_home_page.dart';
import 'stylist_home_page.dart';
import 'salon_owner_home_page.dart';
import 'admin_dashboard.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Lütfen e-posta ve şifre alanlarını doldurun.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await _authService.login(email, password);

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      final user = await _authService.getUserInfo(token);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        final role = user['role'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş başarılı 🎉")),
        );

        if (role == 'Customer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerHomePage(),
            ),
          );
        } else if (role == 'Hairdresser') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const StylistHomePage(),
            ),
          );
        } else if (role == 'SalonOwner') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SalonOwnerHomePage(),
            ),
          );
        } else if (role == 'Admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminDashboard(),
            ),
          );
        } else {
          setState(() {
            _errorMessage = "Rol bilgisi tanınmadı.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Kullanıcı bilgisi alınamadı.";
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "E-posta veya şifre hatalı.";
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kuaför Giriş")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "E-posta"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Şifre"),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: const Text("Giriş Yap"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterPage(),
                  ),
                );
              },
              child: const Text("Hesabın yok mu? Kayıt ol"),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}