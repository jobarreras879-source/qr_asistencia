import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class _LoginColors {
  static const card = Color(0xFF20263A);
  static const cardBorder = Color(0xFF323952);
  static const field = Color(0xFF20263A);
  static const fieldBorder = Color(0xFF2A3350);
  static const fieldFocus = Color(0xFF2E63F2);
  static const title = Color(0xFF2E63F2);
  static const subtitle = Color(0xFF8A90A8);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF969BB2);
  static const textMuted = Color(0xFF6E7590);
  static const buttonStart = Color(0xFF2E63F2);
  static const buttonEnd = Color(0xFF8B3FF1);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _checkSavedLogin();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Restaura sesión activa desde Supabase Auth (no desde almacenamiento local).
  Future<void> _checkSavedLogin() async {
    final session = await AuthService.restoreSession();
    if (session != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeScreen(usuario: session['usuario']!, rol: session['rol']!),
        ),
      );
    }
  }

  Future<void> _login() async {
    final user = _usuarioCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Completa usuario y contraseña.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Usar Supabase Auth en lugar de consulta directa a tabla usuarios
    final rol = await AuthService.signIn(user, pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (rol != null) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, _, _) =>
              HomeScreen(usuario: user, rol: rol),
          transitionsBuilder: (_, anim, _, child) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      setState(() => _errorMessage = 'Usuario o contraseña incorrectos.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF090F1E), Color(0xFF101733), Color(0xFF0D1330)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _LoginColors.buttonStart.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              top: 90,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _LoginColors.buttonEnd.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: AnimatedBuilder(
                animation: _fadeAnim,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _slideAnim.value),
                      child: child,
                    ),
                  );
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          screenHeight -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),
                        _buildHero(),
                        const SizedBox(height: 32),
                        _buildLoginCard(),
                        const SizedBox(height: 24),
                        _buildFooter(),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_LoginColors.buttonStart, _LoginColors.buttonEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _LoginColors.buttonStart.withValues(alpha: 0.34),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'AVS INGENIERIA',
          textAlign: TextAlign.center,
          style: GoogleFonts.bebasNeue(
            fontSize: 50,
            letterSpacing: 3.2,
            color: _LoginColors.title,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CONTROL DE ASISTENCIA',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            letterSpacing: 5.2,
            fontWeight: FontWeight.w500,
            color: _LoginColors.subtitle,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: _LoginColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _LoginColors.cardBorder.withValues(alpha: 0.92),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('USUARIO'),
          const SizedBox(height: 8),
          TextField(
            controller: _usuarioCtrl,
            style: GoogleFonts.dmSans(
              color: _LoginColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            textInputAction: TextInputAction.next,
            decoration: _buildInputDecoration(
              hint: 'Tu usuario',
              prefixIcon: Icons.person_outline_rounded,
              isFocused: true,
            ),
          ),
          const SizedBox(height: 18),
          _buildFieldLabel('CONTRASENA'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: GoogleFonts.dmSans(
              color: _LoginColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
            textInputAction: TextInputAction.done,
            decoration: _buildInputDecoration(
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: _LoginColors.textMuted,
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            onSubmitted: (_) => _login(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.error.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFFFFB4B4),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            height: 66,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [_LoginColors.buttonStart, _LoginColors.buttonEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _LoginColors.buttonEnd.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.8,
                      ),
                    )
                  : Text(
                      'Ingresar',
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'v1.3.0',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _LoginColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 3,
        color: _LoginColors.textSecondary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool isFocused = false,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: _LoginColors.field,
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(
        color: _LoginColors.textMuted,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(prefixIcon, color: _LoginColors.textSecondary, size: 24),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: _LoginColors.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: isFocused
              ? _LoginColors.fieldFocus
              : _LoginColors.fieldBorder.withValues(alpha: 0.7),
          width: isFocused ? 2.2 : 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(
          color: _LoginColors.fieldFocus,
          width: 2.2,
        ),
      ),
    );
  }
}
