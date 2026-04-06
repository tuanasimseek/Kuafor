import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
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
  final _confirmPasswordController = TextEditingController();
  final _salonNameController = TextEditingController();
  final _salonAddressController = TextEditingController();

  String _selectedRole = 'Müşteri';
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _message;

  bool get _isSalonOwner => _selectedRole == 'Salon Sahibi';

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final salonName = _salonNameController.text.trim();
    final salonAddress = _salonAddressController.text.trim();

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _message = "Lütfen tüm alanları doldurun.");
      return;
    }

    if (_isSalonOwner && salonName.isEmpty) {
      setState(() => _message = "Lütfen salon adını girin.");
      return;
    }

    if (_isSalonOwner && salonAddress.isEmpty) {
      setState(() => _message = "Lütfen salon adresini girin.");
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _message = "Lütfen geçerli bir e-posta adresi girin.");
      return;
    }

    if (password.length < 6) {
      setState(() => _message = "Şifre en az 6 karakter olmalıdır.");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _message = "Şifreler birbiriyle eşleşmiyor.");
      return;
    }

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
      fullName: fullName,
      email: email,
      password: password,
      role: roleMap[_selectedRole]!,
      salonName: _isSalonOwner ? salonName : null,
      salonAddress: _isSalonOwner ? salonAddress : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı.")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      setState(() {
        _message = "Kayıt başarısız. Bu e-posta zaten kayıtlı olabilir.";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _salonNameController.dispose();
    _salonAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TopVisual(
            headline: 'Aramıza\nkatılın',
            subtitle: 'Ücretsiz hesabınızı dakikada oluşturun',
            tag: 'ÜCRETSİZ',
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SegmentBar(
                      selected: 1,
                      onTap: (i) {
                        if (i == 0) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    const FieldLabel(text: 'Ad Soyad'),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _nameController,
                      hint: 'Adınız Soyadınız',
                      prefix: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 13),

                    const FieldLabel(text: 'E-posta'),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _emailController,
                      hint: 'ornek@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefix: const Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 13),

                    const FieldLabel(text: 'Şifre'),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      obscureText: _obscurePass,
                      prefix: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePass = !_obscurePass),
                        child: Icon(
                          _obscurePass
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),

                    const FieldLabel(text: 'Şifre Tekrar'),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _confirmPasswordController,
                      hint: '••••••••',
                      obscureText: _obscureConfirm,
                      prefix: const Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      suffix: GestureDetector(
                        onTap: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                        ),
                        child: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const FieldLabel(text: 'Hesap Türü'),
                    const SizedBox(height: 8),
                    _RoleChips(
                      selected: _selectedRole,
                      roles: const [
                        'Müşteri',
                        'Kuaför',
                        'Salon Sahibi',
                        'Admin',
                      ],
                      onChanged: _isLoading
                          ? null
                          : (v) => setState(() => _selectedRole = v),
                    ),
                    const SizedBox(height: 14),

                    if (_isSalonOwner) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.store_outlined,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Salon Bilgileri',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller: _salonNameController,
                              hint: 'Salon adı (ör. Ahmet Kuaför)',
                            ),
                            const SizedBox(height: 10),
                            AppTextField(
                              controller: _salonAddressController,
                              hint: 'Adres (ör. İstanbul, Kadıköy)',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_message != null) ...[
                      ErrorBanner(message: _message!),
                      const SizedBox(height: 14),
                    ],

                    _isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    )
                        : PrimaryButton(
                      label: 'Hesap oluştur',
                      onTap: _register,
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Zaten hesabın var mı?  ',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                            children: [
                              TextSpan(
                                text: 'Giriş yap',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChips extends StatelessWidget {
  final String selected;
  final List<String> roles;
  final ValueChanged<String>? onChanged;

  const _RoleChips({
    required this.selected,
    required this.roles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((role) {
        final isActive = role == selected;

        return GestureDetector(
          onTap: onChanged != null ? () => onChanged!(role) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isActive ? AppColors.mainDark : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? AppColors.mainDark : AppColors.border,
              ),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.white : AppColors.muted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}