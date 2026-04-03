import 'package:flutter/material.dart';
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

  String name  = "";
  String email = "";
  String role  = "";

  bool _isLoading     = true;
  bool _isLoggingOut  = false;
  bool _notifOn       = true;
  bool _campaignNotif = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // ── Orijinal logic — dokunulmadı ──────────────────────────
  Future<void> _loadUser() async {
    setState(() { _isLoading = true; _errorMessage = null; });
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
        name  = user['name']  ?? '';
        email = user['email'] ?? '';
        role  = user['role']  ?? '';
        _isLoading = false;
      });
    } else {
      setState(() { _isLoading = false; _errorMessage = "Kullanıcı bilgileri alınamadı."; });
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
  // ──────────────────────────────────────────────────────────

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
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
      backgroundColor: const Color(0xFFF7F6F4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF111111), strokeWidth: 2))
          : _errorMessage != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: ErrorBanner(message: _errorMessage!)))
          : CustomScrollView(
        slivers: [
          // Top bar
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    _IconBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                    const Expanded(
                      child: Text('Profil',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111111)),
                      ),
                    ),
                    _IconBtn(icon: Icons.edit_outlined, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),

          // Hero kart
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 66, height: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF333333), width: 2),
                    ),
                    child: Center(
                      child: Text(_initials,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.isNotEmpty ? name : 'Kullanıcı',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 3),
                        Text(email.isNotEmpty ? email : '-',
                          style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: Text(_roleLabel,
                            style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // İstatistikler
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _StatCard(label: 'Randevu', value: '—'),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Yorum', value: '—'),
                  const SizedBox(width: 8),
                  _StatCard(label: 'Kampanya', value: '—'),
                ],
              ),
            ),
          ),

          // Hesap bilgileri
          SliverToBoxAdapter(
            child: _Section(
              title: 'Hesap',
              child: Column(
                children: [
                  _InfoRow(icon: Icons.person_outline_rounded, label: 'Ad Soyad', value: name.isNotEmpty ? name : '-', onTap: () {}),
                  _InfoRow(icon: Icons.mail_outline_rounded, label: 'E-posta', value: email.isNotEmpty ? email : '-', onTap: () {}),
                  _InfoRow(icon: Icons.lock_outline_rounded, label: 'Şifre', value: '••••••••', onTap: () {}, isLast: true),
                ],
              ),
            ),
          ),

          // Tercihler
          SliverToBoxAdapter(
            child: _Section(
              title: 'Tercihler',
              child: Column(
                children: [
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    label: 'Bildirimler',
                    subtitle: 'Randevu hatırlatmaları',
                    value: _notifOn,
                    onChanged: (v) => setState(() => _notifOn = v),
                  ),
                  _ToggleRow(
                    icon: Icons.campaign_outlined,
                    label: 'Kampanya Bildirimleri',
                    subtitle: 'Fırsat ve indirimler',
                    value: _campaignNotif,
                    onChanged: (v) => setState(() => _campaignNotif = v),
                    isLast: true,
                  ),
                ],
              ),
            ),
          ),

          // Diğer
          SliverToBoxAdapter(
            child: _Section(
              title: 'Diğer',
              child: Column(
                children: [
                  _InfoRow(icon: Icons.help_outline_rounded, label: 'Yardım & Destek', onTap: () {}),
                  _InfoRow(icon: Icons.star_outline_rounded, label: 'Uygulamayı Değerlendir', onTap: () {}),
                  _InfoRow(icon: Icons.info_outline_rounded, label: 'Versiyon', value: '1.0.0', showArrow: false, isLast: true),
                ],
              ),
            ),
          ),

          // Çıkış butonu
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
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: AppColors.accent, size: 18),
                      SizedBox(width: 8),
                      Text('Çıkış Yap',
                        style: TextStyle(color: AppColors.accent, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
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

// ════════════════════════════════════════════════════════════
//  YARDIMCI WİDGET'LAR
// ════════════════════════════════════════════════════════════

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: const Color(0xFFEDEAE4), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 16, color: const Color(0xFF111111)),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEAE4)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBBB), fontWeight: FontWeight.w500)),
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
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFBBBBBB), letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDEAE4)),
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
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF3F1EE), width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: const Color(0xFFF7F6F4), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 15, color: const Color(0xFF555555)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
                  if (value != null) ...[
                    const SizedBox(height: 1),
                    Text(value!, style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
                  ],
                ],
              ),
            ),
            if (showArrow && onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCCCCCC)),
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
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF3F1EE), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: const Color(0xFFF7F6F4), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 15, color: const Color(0xFF555555)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
                const SizedBox(height: 1),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF111111),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFEDEAE4),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }
}