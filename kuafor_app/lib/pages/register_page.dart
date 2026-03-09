import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'Müşteri';
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _message;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final roleMap = {
      'Müşteri': 'Customer',
      'Kuaför': 'Hairdresser',
      'Salon Sahibi': 'SalonOwner',
      'Admin': 'Admin',
    };

    final success = await _authService.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: roleMap[_selectedRole]!,
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı 🎉")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      setState(() {
        _message = "Kayıt başarısız. Bu e-posta zaten kayıtlı olabilir.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kayıt Ol")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Ad Soyad"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "E-posta"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Şifre"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: "Rol Seç"),
              items: const [
                DropdownMenuItem(value: 'Müşteri', child: Text("Müşteri")),
                DropdownMenuItem(value: 'Kuaför', child: Text("Kuaför")),
                DropdownMenuItem(value: 'Salon Sahibi', child: Text("Salon Sahibi")),
                DropdownMenuItem(value: 'Admin', child: Text("Admin")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _register,
              child: const Text("Kayıt Ol"),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}