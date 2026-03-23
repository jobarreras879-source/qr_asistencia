import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
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
          builder: (_) => HomeScreen(
            usuario: session['usuario']!,
            rol: session['rol']!,
          ),
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
          pageBuilder: (context, animation, secondaryAnimation) =>
              HomeScreen(usuario: user, rol: rol),
          transitionsBuilder: (context, anim, secondaryAnimation, child) {
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accent2.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.accent2.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          'Plataforma de asistencia',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent2Light,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: BrandLogo(size: 74),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'AVS Ingenieria',
                      style: GoogleFonts.ibmPlexSerif(
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Accede al sistema para registrar asistencia, evidencias y operaciones de campo con una interfaz mas formal y controlada.',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Acceso al sistema',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ingresa con tus credenciales autorizadas.',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'USUARIO',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usuarioCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: AppTheme.inputDecoration(
                              hint: 'Ingresa tu usuario',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'CONTRASENA',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
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
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.error.withValues(alpha: 0.3),
                                ),
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
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: AppTheme.accentGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withValues(alpha: 0.24),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
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
                                          color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'Ingresar al panel',
                                      style: GoogleFonts.ibmPlexSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'AVS Ingenieria  •  Entorno seguro de operacion',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
