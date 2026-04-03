import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
//  UYGULAMA RENK PALETİ
// ══════════════════════════════════════════════════════════════
class AppColors {
  static const background = Color(0xFFF5F9FF);
  static const surface    = Color(0xFFFFFFFF);
  static const primary    = Color(0xFF0F172A); // koyu lacivert
  static const accent     = Color(0xFF3B82F6); // canlı mavi
  static const muted      = Color(0xFF6B7280);
  static const border     = Color(0xFFE5E7EB);
  static const white      = Color(0xFFFFFFFF);
}
// ══════════════════════════════════════════════════════════════
//  ÜST GÖRSEL ALAN
// ══════════════════════════════════════════════════════════════
class TopVisual extends StatelessWidget {
  final String headline;
  final String subtitle;
  const TopVisual({super.key, required this.headline, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 240,
      color: AppColors.primary,
      child: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: DecorCircle(size: 180, color: const Color(0xFF1A1A1A)),
          ),
          Positioned(
            bottom: -20, left: 20,
            child: DecorCircle(size: 90, color: const Color(0xFF181818)),
          ),
          Positioned(
            top: 40, right: 60,
            child: DecorCircle(size: 60, color: const Color(0xFF1C1C1C)),
          ),
          Positioned(
            top: 52, left: 0, right: 0,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Center(
                    child: Icon(Icons.content_cut_rounded,
                        color: AppColors.accent, size: 20),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'STİLİST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DecorCircle extends StatelessWidget {
  final double size;
  final Color color;
  const DecorCircle({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SEGMENT BAR (Giriş / Kayıt)
// ══════════════════════════════════════════════════════════════
class SegmentBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  const SegmentBar({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          SegItem(
              label: 'Giriş yap',
              active: selected == 0,
              onTap: () => onTap(0)),
          SegItem(
              label: 'Kayıt ol',
              active: selected == 1,
              onTap: () => onTap(1)),
        ],
      ),
    );
  }
}

class SegItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const SegItem(
      {super.key,
        required this.label,
        required this.active,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: active ? Border.all(color: AppColors.border) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.primary : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  ALAN ETİKETİ
// ══════════════════════════════════════════════════════════════
class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  TEXT FIELD
// ══════════════════════════════════════════════════════════════
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.primary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PRIMARY BUTON
// ══════════════════════════════════════════════════════════════
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const PrimaryButton(
      {super.key, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: color ?? AppColors.primary,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  VEYA AYIRICI
// ══════════════════════════════════════════════════════════════
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AppColors.border)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('veya',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ),
        Expanded(child: Container(height: 0.5, color: AppColors.border)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  GOOGLE BUTONU
// ══════════════════════════════════════════════════════════════
class GoogleButton extends StatelessWidget {
  final VoidCallback? onTap;
  const GoogleButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap ?? () {},
        icon: const Icon(Icons.g_mobiledata_rounded,
            size: 22, color: AppColors.primary),
        label: const Text(
          'Google ile devam et',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11)),
          backgroundColor: AppColors.white,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HATA BANNER
// ══════════════════════════════════════════════════════════════
class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF7C1C1)),
      ),
      child: Text(
        message,
        style: const TextStyle(fontSize: 13, color: Color(0xFFA32D2D)),
      ),
    );
  }
}