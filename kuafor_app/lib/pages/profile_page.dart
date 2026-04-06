import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../widgets/app_widgets.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  String name = "";
  String email = "";
  String role = "";
  String _profileImageUrl = "";

  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _uploadingPhoto = false;
  bool _notifOn = true;
  bool _campaignNotif = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
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
        name             = user['name']            ?? '';
        email            = user['email']           ?? '';
        role             = user['role']            ?? '';
        _profileImageUrl = user['profileImageUrl'] ?? '';
        _isLoading       = false;
      });
    } else {
      setState(() {
        _isLoading    = false;
        _errorMessage = "Kullanıcı bilgileri alınamadı.";
      });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Fotoğraf Seç',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20),
                ),
                title: const Text('Galeriden Seç', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20),
                ),
                title: const Text('Kameradan Çek', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    final token = await _authService.getToken();
    if (token == null) {
      setState(() => _uploadingPhoto = false);
      return;
    }

    final url = await _authService.uploadProfilePhoto(
      token: token,
      filePath: picked.path,
    );

    if (!mounted) return;

    if (url != null) {
      setState(() {
        _profileImageUrl = url;
        _uploadingPhoto  = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi')),
      );
    } else {
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf yüklenemedi')),
      );
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await _authService.deleteToken();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: name);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditBottomSheet(
          title: 'Ad Soyad Güncelle',
          subtitle: 'Profilinizde görünecek adı düzenleyin',
          child: _SheetTextField(
            controller: controller,
            hintText: 'Yeni ad soyad',
            icon: Icons.person_outline_rounded,
          ),
          onSave: () {
            final value = controller.text.trim();
            if (value.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ad soyad boş bırakılamaz.")),
              );
              return;
            }
            Navigator.pop(context, value);
          },
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oturum bulunamadı.")),
      );
      return;
    }

    final success = await _authService.updateProfile(
      token: token,
      fullName: result.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() => name = result.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad soyad güncellendi")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Güncelleme başarısız")),
      );
    }
  }

  Future<void> _editPassword() async {
    final passwordController = TextEditingController();
    final confirmController  = TextEditingController();

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        bool obscure1 = true;
        bool obscure2 = true;

        return StatefulBuilder(
          builder: (context, setLocalState) {
            return _EditBottomSheet(
              title: 'Şifre Güncelle',
              subtitle: 'Güvenliğiniz için yeni bir şifre belirleyin',
              child: Column(
                children: [
                  _SheetTextField(
                    controller: passwordController,
                    hintText: 'Yeni şifre',
                    icon: Icons.lock_outline_rounded,
                    obscureText: obscure1,
                    suffix: IconButton(
                      icon: Icon(
                        obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                      ),
                      onPressed: () => setLocalState(() => obscure1 = !obscure1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SheetTextField(
                    controller: confirmController,
                    hintText: 'Yeni şifre tekrar',
                    icon: Icons.lock_outline_rounded,
                    obscureText: obscure2,
                    suffix: IconButton(
                      icon: Icon(
                        obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.muted,
                      ),
                      onPressed: () => setLocalState(() => obscure2 = !obscure2),
                    ),
                  ),
                ],
              ),
              onSave: () {
                final password = passwordController.text.trim();
                final confirm  = confirmController.text.trim();

                if (password.isEmpty || confirm.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen tüm alanları doldurun.")),
                  );
                  return;
                }
                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Şifre en az 6 karakter olmalıdır.")),
                  );
                  return;
                }
                if (password != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Şifreler birbiriyle eşleşmiyor.")),
                  );
                  return;
                }

                Navigator.pop(context, password);
              },
            );
          },
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oturum bulunamadı.")),
      );
      return;
    }

    final success = await _authService.updateProfile(
      token: token,
      password: result.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Şifre güncellendi" : "Şifre güncelleme başarısız")),
    );
  }

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  String get _roleLabel {
    const map = {
      'Customer':    'Müşteri',
      'Hairdresser': 'Kuaför',
      'SalonOwner':  'Salon Sahibi',
      'Admin':       'Yönetici',
    };
    return map[role] ?? role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.mainDark, strokeWidth: 2))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ErrorBanner(message: _errorMessage!),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // ── Başlık ───────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: Row(
                            children: [
                              _IconBtn(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              const Expanded(
                                child: Text('Profil',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                              _IconBtn(icon: Icons.edit_outlined, onTap: _editName),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Profil kartı ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.mainDark,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Avatar — fotoğraf varsa göster, yoksa baş harfler
                            GestureDetector(
                              onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                              child: Stack(
                                children: [
                                  // Ana avatar dairesi
                                  _uploadingPhoto
                                      ? Container(
                                          width: 66, height: 66,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24, height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 66, height: 66,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.08),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withOpacity(0.08), width: 2),
                                            image: _profileImageUrl.isNotEmpty
                                                ? DecorationImage(
                                                    image: NetworkImage(_profileImageUrl),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: _profileImageUrl.isEmpty
                                              ? Center(
                                                  child: Text(
                                                    _initials,
                                                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -1),
                                                  ),
                                                )
                                              : null,
                                        ),
                                  // Kamera ikonu rozeti
                                  if (!_uploadingPhoto)
                                    Positioned(
                                      bottom: 0, right: 0,
                                      child: Container(
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.mainDark, width: 1.5),
                                        ),
                                        child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isNotEmpty ? name : 'Kullanıcı',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    email.isNotEmpty ? email : '-',
                                    style: TextStyle(color: Colors.white.withOpacity(0.62), fontSize: 12),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppColors.accent.withOpacity(0.28)),
                                    ),
                                    child: Text(
                                      _roleLabel,
                                      style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Stat kartları ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Row(
                          children: const [
                            _StatCard(label: 'Randevu', value: '—'),
                            SizedBox(width: 8),
                            _StatCard(label: 'Yorum', value: '—'),
                            SizedBox(width: 8),
                            _StatCard(label: 'Kampanya', value: '—'),
                          ],
                        ),
                      ),
                    ),

                    // ── Hesap bölümü ──────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Hesap',
                        child: Column(
                          children: [
                            _InfoRow(icon: Icons.person_outline_rounded, label: 'Ad Soyad', value: name.isNotEmpty ? name : '-', onTap: _editName),
                            _InfoRow(icon: Icons.mail_outline_rounded,   label: 'E-posta',  value: email.isNotEmpty ? email : '-', onTap: null),
                            _InfoRow(icon: Icons.lock_outline_rounded,   label: 'Şifre',    value: '••••••••', onTap: _editPassword, isLast: true),
                          ],
                        ),
                      ),
                    ),

                    // ── Tercihler ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Tercihler',
                        child: Column(
                          children: [
                            _ToggleRow(
                              icon: Icons.notifications_outlined, label: 'Bildirimler',
                              subtitle: 'Randevu hatırlatmaları', value: _notifOn,
                              onChanged: (v) => setState(() => _notifOn = v),
                            ),
                            _ToggleRow(
                              icon: Icons.campaign_outlined, label: 'Kampanya Bildirimleri',
                              subtitle: 'Fırsat ve indirimler', value: _campaignNotif,
                              onChanged: (v) => setState(() => _campaignNotif = v),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Diğer ─────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Diğer',
                        child: Column(
                          children: [
                            _InfoRow(icon: Icons.help_outline_rounded,  label: 'Yardım & Destek',         onTap: null),
                            _InfoRow(icon: Icons.star_outline_rounded,  label: 'Uygulamayı Değerlendir',  onTap: null),
                            _InfoRow(icon: Icons.info_outline_rounded,  label: 'Versiyon', value: '1.0.0', showArrow: false, isLast: true),
                          ],
                        ),
                      ),
                    ),

                    // ── Çıkış ─────────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: _isLoggingOut
                            ? const Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2))
                            : GestureDetector(
                                onTap: _logout,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  decoration: BoxDecoration(
                                    color: AppColors.mainDark,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.logout_rounded, color: AppColors.accent, size: 18),
                                      SizedBox(width: 8),
                                      Text('Çıkış Yap',
                                          style: TextStyle(color: AppColors.accent, fontSize: 15, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ── Alt sheet ve yardımcı widget'lar (değişmedi) ──────────────────────────────

class _EditBottomSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onSave;

  const _EditBottomSheet({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42, height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(height: 18),
              child,
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: AppColors.surface,
                      ),
                      child: const Text('İptal', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.mainDark,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Kaydet', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;

  const _SheetTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.muted),
          prefixIcon: Icon(icon, color: AppColors.muted),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 17, color: AppColors.primary),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool isLast;
  final bool showArrow;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.isLast = false,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF1F1F1), width: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(value!, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ],
              ),
            ),
            if (showArrow && onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F1F1), width: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.mainDark,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.border,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}