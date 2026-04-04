import 'package:flutter/material.dart';
import '../widgets/app_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  String? _message;
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _message = 'Lütfen e-posta adresinizi girin.');
      return;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _message = 'Lütfen geçerli bir e-posta adresi girin.');
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _message = 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TopVisual(
            headline: 'Şifrenizi\nsıfırlayın',
            subtitle: 'E-posta adresinizi girin, size bağlantı gönderelim',
            tag: 'YARDIM',
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new_rounded,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Girişe dön',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 18),

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
                      label: 'Sıfırlama bağlantısı gönder',
                      onTap: _sendResetLink,
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