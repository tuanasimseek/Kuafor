import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'login_page.dart';

class BusinessRegisterPage extends StatefulWidget {
  const BusinessRegisterPage({super.key});

  @override
  State<BusinessRegisterPage> createState() => _BusinessRegisterPageState();
}

class _BusinessRegisterPageState extends State<BusinessRegisterPage> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _salonNameController = TextEditingController();
  final _salonAddressController = TextEditingController();

  String _role = 'SalonOwner';
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _salonNameController.dispose();
    _salonAddressController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final salonName = _salonNameController.text.trim();
    final salonAddress = _salonAddressController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _message = 'Ad, e-posta ve şifre zorunludur.');
      return;
    }
    if (_role == 'SalonOwner' && salonName.isEmpty) {
      setState(() => _message = 'Salon sahibi kaydı için salon adı zorunludur.');
      return;
    }
    if (password.length < 6) {
      setState(() => _message = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }

    setState(() { _loading = true; _message = null; });
    final ok = await _authService.register(
      fullName: name,
      email: email,
      username: username.isEmpty ? null : username,
      password: password,
      role: _role,
      salonName: _role == 'SalonOwner' ? salonName : null,
      salonAddress: _role == 'SalonOwner' ? salonAddress : null,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşletme kaydı oluşturuldu. Giriş yapabilirsiniz.')),
      );
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      setState(() => _message = 'Kayıt başarısız. E-posta veya kullanıcı adı kullanılıyor olabilir.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TopVisual(
            headline: 'İşletmeni\nbüyüt',
            subtitle: 'Salon ve kuaförler için özel kayıt alanı',
            tag: 'İŞLETME',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Geri dön', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _RoleButton(label: 'Salon Sahibi', active: _role == 'SalonOwner', onTap: () => setState(() => _role = 'SalonOwner'))),
                      const SizedBox(width: 10),
                      Expanded(child: _RoleButton(label: 'Kuaför', active: _role == 'Hairdresser', onTap: () => setState(() => _role = 'Hairdresser'))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const FieldLabel(text: 'Ad Soyad'),
                  const SizedBox(height: 6),
                  AppTextField(controller: _nameController, hint: 'Adınız Soyadınız'),
                  const SizedBox(height: 12),
                  const FieldLabel(text: 'E-posta'),
                  const SizedBox(height: 6),
                  AppTextField(controller: _emailController, hint: 'ornek@email.com', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  const FieldLabel(text: 'Kullanıcı adı'),
                  const SizedBox(height: 6),
                  AppTextField(controller: _usernameController, hint: 'isteğe bağlı'),
                  const SizedBox(height: 12),
                  const FieldLabel(text: 'Şifre'),
                  const SizedBox(height: 6),
                  AppTextField(controller: _passwordController, hint: 'en az 6 karakter', obscureText: true),
                  if (_role == 'SalonOwner') ...[
                    const SizedBox(height: 12),
                    const FieldLabel(text: 'Salon adı'),
                    const SizedBox(height: 6),
                    AppTextField(controller: _salonNameController, hint: 'Salon adı'),
                    const SizedBox(height: 12),
                    const FieldLabel(text: 'Salon adresi'),
                    const SizedBox(height: 6),
                    AppTextField(controller: _salonAddressController, hint: 'Adres'),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                    ),
                    child: const Text(
                      'İlk ay ücretsiz salon yönetimi, randevu takibi ve kampanya yayınlama avantajı.',
                      style: TextStyle(color: AppColors.primary, fontSize: 13, height: 1.4),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    ErrorBanner(message: _message!),
                  ],
                  const SizedBox(height: 18),
                  _loading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : PrimaryButton(label: 'İşletme hesabı oluştur', onTap: _register),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? AppColors.white : AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
