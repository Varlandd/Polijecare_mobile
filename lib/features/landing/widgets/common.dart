import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Judul section dua warna, contoh: "Cara **Melapor**".
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.first,
    required this.highlight,
    this.highlightColor = AppColors.primary,
    this.gradient,
    this.fontSize = 30,
    this.textAlign = TextAlign.center,
  });

  final String first;
  final String highlight;
  final Color highlightColor;
  final Gradient? gradient;
  final double fontSize;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: AppColors.gray900,
      height: 1.2,
      letterSpacing: -0.5,
    );
    final hlStyle = gradient != null
        ? base.copyWith(
            foreground: Paint()
              ..shader = gradient!.createShader(
                  Rect.fromLTWH(0, 0, highlight.length * fontSize * 0.55, fontSize)),
          )
        : base.copyWith(color: highlightColor);

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$first ', style: base),
        TextSpan(text: highlight, style: hlStyle),
      ]),
      textAlign: textAlign,
    );
  }
}

/// Animasi muncul (fade + slide up) sekali saat widget pertama kali dibangun,
/// pengganti `framer-motion` di web.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.offsetY = 24,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, widget.offsetY * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Lingkaran blur dekoratif (background blob seperti di web).
class BlurBlob extends StatelessWidget {
  const BlurBlob({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Tombol pil berwarna dengan ikon panah (pengganti `FlowButton` web).
class FlowButton extends StatelessWidget {
  const FlowButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.expand = true,
    this.icon = Icons.arrow_forward_rounded,
  });

  final String text;
  final Color color;
  final VoidCallback onPressed;
  final bool expand;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 18),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Kartu putih dengan border & bayangan halus (rounded-3xl).
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color = Colors.white,
    this.borderColor = AppColors.gray100,
    this.radius = 24,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

