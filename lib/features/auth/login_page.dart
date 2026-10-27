import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/config/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher.dart';
import '../../data/services/auth_service.dart';

/// Halaman Login PolijeCare — port 1:1 dari `pages/NewLoginPage.jsx` di web.
class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.fromFormLaporan = false,
    this.initialError,
  });

  final bool fromFormLaporan;
  final String? initialError;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String _loginError = '';
  bool _isLoading = false;
  bool _showPassword = false;

  // Animasi float ikon header & background blobs (sama seperti framer-motion di web)
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final AnimationController _bgCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    if (widget.initialError != null && widget.initialError!.isNotEmpty) {
      _loginError = _mapErrorParam(widget.initialError!);
    }
    _emailController.addListener(_onEmailChanged);
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _passwordController.removeListener(_onPasswordChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _floatCtrl.dispose();
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _mapErrorParam(String errorParam) {
    if (errorParam == 'domain_not_allowed') {
      return 'Akses ditolak. Gunakan email @polije.ac.id atau @student.polije.ac.id';
    } else if (errorParam == 'sso_failed') {
      return 'Autentikasi Google gagal. Silakan coba lagi.';
    }
    return errorParam;
  }

  void _onEmailChanged() {
    if (_emailError != null || _loginError.isNotEmpty) {
      setState(() {
        _emailError = null;
        _loginError = '';
      });
    }
  }

  void _onPasswordChanged() {
    if (_passwordError != null || _loginError.isNotEmpty) {
      setState(() {
        _passwordError = null;
        _loginError = '';
      });
    }
  }

  /// Validasi format email — sesuai `validateEmail` di `NewLoginPage.jsx`.
  bool _validateEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Validasi form — sesuai `validateForm` di `NewLoginPage.jsx`.
  bool _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? emailErr;
    String? passErr;

    if (email.isEmpty) {
      emailErr = 'Email wajib diisi';
    } else if (!_validateEmail(email)) {
      emailErr = 'Format email tidak valid';
    }

    if (password.isEmpty) {
      passErr = 'Password wajib diisi';
    } else if (password.length < 6) {
      passErr = 'Password minimal 6 karakter';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    return emailErr == null && passErr == null;
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _loginError = '';
    });

    final result = await AuthService.instance.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.success && result.user != null) {
      final targetRoute =
          result.redirectRoute ?? AuthService.instance.redirectPath;
      Navigator.of(context).pushNamedAndRemoveUntil(
        targetRoute,
        (route) => false,
      );
    } else {
      setState(() {
        _loginError = result.message;
      });
    }
  }

  void _handleGoogleLogin() {
    final url = '${ApiConfig.baseUrl}/auth/google';
    openExternal(context, url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEFF6FF), // blue-50
              Colors.white,
              Color(0xFFEEF2FF), // indigo-50
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements (sama seperti motion.div di NewLoginPage.jsx)
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) {
                final t = _bgCtrl.value;
                return Stack(
                  children: [
                    Positioned(
                      top: 40 + (15 * t),
                      left: 32 + (20 * t),
                      child: Transform.scale(
                        scale: 1.0 + (0.1 * t),
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFBFDBFE).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40 - (20 * t),
                      right: 32 + (15 * t),
                      child: Transform.scale(
                        scale: 1.0 + (0.2 * t),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFC7D2FE).withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Main Card
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F1E3A8A),
                            blurRadius: 40,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          if (widget.fromFormLaporan) _buildFormLaporanBanner(),
                          _buildSectionDivider(
                              'MASUK DENGAN EMAIL & KATA SANDI'),
                          const SizedBox(height: 16),
                          _buildEmailField(),
                          const SizedBox(height: 20),
                          _buildPasswordField(),
                          const SizedBox(height: 20),
                          if (_loginError.isNotEmpty) _buildLoginErrorBanner(),
                          _buildSubmitButton(),
                          const SizedBox(height: 16),
                          _buildSectionDivider('ATAU'),
                          const SizedBox(height: 16),
                          _buildGoogleButton(),
                          const SizedBox(height: 12),
                          const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.gray500,
                              ),
                              children: [
                                TextSpan(text: 'Gunakan email '),
                                TextSpan(
                                  text: '@polije.ac.id',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                TextSpan(text: ' atau '),
                                TextSpan(
                                  text: '@student.polije.ac.id',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Floating circular login icon
        AnimatedBuilder(
          animation: _floatCtrl,
          builder: (context, child) {
            final dy = -5.0 + (10.0 * _floatCtrl.value);
            return Transform.translate(
              offset: Offset(0, dy),
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3B82F6), // blue-500
                  Color(0xFF4F46E5), // indigo-600
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x403B82F6),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.login_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title dengan gradient blue-600 -> indigo-700
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFF2563EB), // blue-600
              Color(0xFF4338CA), // indigo-700
            ],
          ).createShader(bounds),
          child: const Text(
            'PolijeCare Login',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        const Text(
          'Masuk ke sistem PolijeCare untuk akses layanan pengaduan dan penanganan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray600,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),

        // Badge "Terhubung dengan database Polije"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFF0FDF4), // green-50
                Color(0xFFECFDF5), // emerald-50
              ],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDCFCE7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) => Opacity(
                  opacity: 0.4 + (0.6 * _pulseCtrl.value),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Terhubung dengan database Polije',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFormLaporanBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFEEF2FF),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.error_outline_rounded,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Silakan login terlebih dahulu',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1D4ED8),
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(text: 'Gunakan '),
                      const TextSpan(
                        text: 'email Polije',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const TextSpan(text: ' Anda (contoh: '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'nama@polije.ac.id',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(
                          text: ') untuk mengakses Form Pengaduan.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(String text) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.gray200, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.gray400,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.gray200, thickness: 1)),
      ],
    );
  }

  Widget _buildEmailField() {
    final hasError = _emailError != null && _emailError!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.mail_outline_rounded,
                size: 16, color: AppColors.gray700),
            SizedBox(width: 8),
            Text(
              'Email Polije',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          style: const TextStyle(fontSize: 14.5, color: AppColors.gray900),
          decoration: InputDecoration(
            hintText: 'contoh@polije.ac.id',
            hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
            filled: true,
            fillColor: hasError ? const Color(0xFFFEF2F2) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(
              Icons.mail_outline_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    hasError ? const Color(0xFFFCA5A5) : AppColors.gray200,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gray200,
                width: 2,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _emailError!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField() {
    final hasError = _passwordError != null && _passwordError!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lock_outline_rounded,
                size: 16, color: AppColors.gray700),
            SizedBox(width: 8),
            Text(
              'Password',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          enabled: !_isLoading,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleSubmit(),
          style: const TextStyle(fontSize: 14.5, color: AppColors.gray900),
          decoration: InputDecoration(
            hintText: 'Masukkan password',
            hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
            filled: true,
            fillColor: hasError ? const Color(0xFFFEF2F2) : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
            suffixIcon: IconButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    hasError ? const Color(0xFFFCA5A5) : AppColors.gray200,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gray200,
                width: 2,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 16, color: AppColors.red),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _passwordError!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLoginErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFEF2F2), // red-50
            Color(0xFFFFF7ED), // orange-50
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) => Opacity(
              opacity: 0.5 + (0.5 * _pulseCtrl.value),
              child: child,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _loginError,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w500,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final blur = _isLoading ? 8.0 : 15.0 + (5.0 * _pulseCtrl.value);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: _isLoading
                  ? const [
                      Color(0xFF60A5FA), // blue-400
                      Color(0xFF818CF8), // indigo-400
                    ]
                  : const [
                      Color(0xFF2563EB), // blue-600
                      Color(0xFF4338CA), // indigo-700
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6)
                    .withValues(alpha: _isLoading ? 0.2 : 0.35),
                blurRadius: blur,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _handleSubmit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Memproses Login...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Masuk ke PolijeCare',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.gray700,
          side: const BorderSide(color: AppColors.gray300, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            SizedBox(width: 12),
            Text(
              'Masuk dengan Google',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.5,
                color: AppColors.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(color: AppColors.gray200, height: 1),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3B82F6), // blue-500
                Color(0xFF4F46E5), // indigo-600
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x333B82F6),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.landing,
                (route) => false,
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Kembali ke Landing Page',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter untuk logo 4-warna Google (sama seperti SVG di `NewLoginPage.jsx`).
class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.21;
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Merah (atas)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.78, math.pi * 0.56, false, paint);

    // Kuning (kiri)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.78, math.pi * 0.44, false, paint);

    // Hijau (bawah)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.22, math.pi * 0.56, false, paint);

    // Biru (kanan + garis horizontal)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.05, math.pi * 0.30, false, paint);

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx,
        center.dy - stroke * 0.48,
        size.width * 0.48,
        stroke * 0.96,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

