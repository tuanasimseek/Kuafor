import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'customer_home_page.dart';
import 'stylist_home_page.dart';
import 'salon_owner_home_page.dart';
import 'admin_dashboard.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading   = false;
  bool _obscurePass = true;
  String? _errorMessage;

  // ── Orijinal login logic — dokunulmadı ────────────────────
  Future<void> _login() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Lütfen e-posta ve şifre alanlarını doldurun.");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final token = await _authService.login(email, password);
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      final user = await _authService.getUserInfo(token);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        final role = user['role'];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Giriş başarılı.")),
        );
        if (role == 'Customer') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CustomerHomePage()));
        } else if (role == 'Hairdresser') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StylistHomePage()));
        } else if (role == 'SalonOwner') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalonOwnerHomePage()));
        } else if (role == 'Admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
        } else {
          setState(() => _errorMessage = "Rol bilgisi tanınmadı.");
        }
      } else {
        setState(() => _errorMessage = "Kullanıcı bilgisi alınamadı.");
      }
    } else {
      setState(() { _isLoading = false; _errorMessage = "E-posta veya şifre hatalı."; });
    }
  }
  // ──────────────────────────────────────────────────────────

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Fotoğraf + overlay ────────────────────────────
          TopVisual(
            headline: 'Güzellik\nsizi bekliyor',
            subtitle: 'Saniyeler içinde randevunuzu oluşturun',
            tag: 'RANDEVU AL',
          ),

          // ── Form sheet ────────────────────────────────────
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
                    // Tabs
                    SegmentBar(
                      selected: 0,
                      onTap: (i) {
                        if (i == 1) {
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const RegisterPage()));
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // E-posta
                    const FieldLabel(text: 'E-posta'),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _emailController,
                      hint: 'ornek@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefix: const Icon(Icons.mail_outline_rounded,
                          size: 18, color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),

                    // Şifre
                    const FieldLabel(text: 'Şifre'),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      obscureText: _obscurePass,
                      prefix: const Icon(Icons.lock_outline_rounded,
                          size: 18, color: AppColors.muted),
                      suffix: GestureDetector(
                        onTap: () => setState(() => _obscurePass = !_obscurePass),
                        child: Icon(
                          _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18, color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Şifremi unuttum
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Şifremi unuttum',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hata
                    if (_errorMessage != null) ...[
                      ErrorBanner(message: _errorMessage!),
                      const SizedBox(height: 14),
                    ],

                    // Giriş butonu
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                        : PrimaryButton(label: 'Giriş yap', onTap: _login),
                    const SizedBox(height: 16),

                    // Veya
                    const OrDivider(),
                    const SizedBox(height: 14),

                    // Sosyal butonlar
                    const SocialButtons(),
                    const SizedBox(height: 22),

                    // Alt link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const RegisterPage())),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Hesabın yok mu?  ',
                            style: TextStyle(fontSize: 13, color: AppColors.muted),
                            children: [
                              TextSpan(
                                text: 'Hemen kaydol',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
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