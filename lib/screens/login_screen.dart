import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../utils/perf_diagnostics.dart';
import '../widgets/login/login_bottom_actions.dart';
import '../widgets/login/login_form_card.dart';
import '../widgets/login/login_hero.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _heroColor = Color(0xFF001A6B);
  static const _pageBg = Color(0xFFF7F9FB);
  static const _textPrimary = Color(0xFF171B1F);
  static const _textSecondary = Color(0xFF4A5160);

  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;
  late final PerfTrace _loginTrace;

  @override
  void initState() {
    super.initState();
    _loginTrace = PerfDiagnostics.startTrace('login_screen');
    _loginTrace.mark(
      'init_state',
      data: {'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds},
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<double>(begin: 26, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loginTrace.mark(
        'first_frame',
        data: {'sinceAppStartMs': PerfDiagnostics.appStart.elapsedMilliseconds},
      );
    });
    _checkSavedLogin();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkSavedLogin() async {
    final trace = PerfDiagnostics.startTrace('login_restore_session');
    final session = await trace.measureAsync(
      'AuthService.restoreSession',
      AuthService.restoreSession,
    );
    trace.finish(data: {'hasSession': session != null});
    if (session != null && mounted) {
      _loginTrace.mark(
        'navigate_home_from_saved_session',
        data: {'usuario': session['usuario']},
      );
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
    final trace = PerfDiagnostics.startTrace(
      'login_submit',
      context: {'usuario': _usuarioCtrl.text.trim().toLowerCase()},
    );
    final user = _usuarioCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Completa usuario y contraseña.');
      trace.finish(data: {'result': 'validation_error'});
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final rol = await trace.measureAsync(
      'AuthService.signIn',
      () => AuthService.signIn(user, pass),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (rol != null) {
      trace.mark('navigate_home', data: {'rol': rol});
      trace.finish(data: {'result': 'success'});
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
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      setState(() => _errorMessage = AuthService.getFriendlyLastError());
      trace.finish(data: {'result': 'error'});
    }
  }

  void _showInfoDialog({required String title, required String message}) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.4,
              color: _textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Entendido',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _heroColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Scaffold(
      backgroundColor: _pageBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final viewportHeight = constraints.maxHeight;
              final heroHeight = viewportHeight > 760 ? 324.0 : 286.0;
              const overlap = 78.0;

              return SingleChildScrollView(
                padding: EdgeInsets.only(bottom: media.viewInsets.bottom + 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: Column(
                    children: [
                      LoginHero(height: heroHeight),
                      Transform.translate(
                        offset: const Offset(0, -overlap),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              LoginFormCard(
                                usuarioController: _usuarioCtrl,
                                passwordController: _passwordCtrl,
                                isLoading: _isLoading,
                                obscurePassword: _obscurePassword,
                                errorMessage: _errorMessage,
                                onLogin: _login,
                                onTogglePassword: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                versionLabel: 'V1.4.0',
                              ),
                              const SizedBox(height: 18),
                              LoginBottomActions(
                                onForgotPassword: () {
                                  _showInfoDialog(
                                    title: 'Recuperar contraseña',
                                    message:
                                        'Por ahora la recuperación automática no está habilitada. Contacta a soporte técnico para restablecer tu acceso.',
                                  );
                                },
                                onSupport: () {
                                  _showInfoDialog(
                                    title: 'Soporte técnico',
                                    message:
                                        'Comunícate con el administrador o con el equipo de soporte para obtener ayuda con tu cuenta.',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}
