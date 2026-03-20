import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

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
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _pulseAnim;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _checkSavedLogin();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSavedLogin() async {
    final savedUser = await SecureStorageService.getUsuario();
    final savedRol = await SecureStorageService.getRol() ?? 'USUARIO';
    if (savedUser != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(usuario: savedUser, rol: savedRol)),
      );
    }
  }

  Future<void> _login() async {
    final user = _usuarioCtrl.text.trim().toUpperCase();
    final pass = _passwordCtrl.text;

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Completa usuario y contraseña.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rol = await ApiService.loginConRol(user, pass);

    setState(() => _isLoading = false);

    if (rol != null) {
      await SecureStorageService.saveUsuario(user);
      await SecureStorageService.saveRol(rol);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => HomeScreen(usuario: user, rol: rol),
          transitionsBuilder: (_, anim, __, child) {
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
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
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // ─── Logo / Icon ────────────────────────
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.accentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accent
                                    .withOpacity(0.4 * _pulseAnim.value),
                                blurRadius: 40 * _pulseAnim.value,
                                spreadRadius: 4 * _pulseAnim.value,
                              ),
                              BoxShadow(
                                color: AppTheme.accent.withOpacity(0.1),
                                blurRadius: 100,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.qr_code_scanner_rounded,
                              color: Colors.white, size: 40),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Brand Title ────────────────────────
                    Text(
                      'AVS Ingeniería',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 36,
                        letterSpacing: 4,
                        color: AppTheme.accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CONTROL DE ASISTENCIA',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // ─── Glass Card Form ────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Usuario label
                          Text(
                            'USUARIO',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usuarioCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            textCapitalization: TextCapitalization.characters,
                            decoration: AppTheme.inputDecoration(
                              hint: 'Tu usuario',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password label
                          Text(
                            'CONTRASEÑA',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: AppTheme.inputDecoration(
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.textMuted,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            onSubmitted: (_) => _login(),
                          ),

                          // Error message
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppTheme.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                          color: AppTheme.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Login button
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: AppTheme.accentGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Text(
                                      'Ingresar',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Footer
                    Text(
                      'v1.1.0 • AVS Ingeniería',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Powered by Supabase Security',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        color: AppTheme.textMuted.withOpacity(0.5),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
