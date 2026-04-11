import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/auth_service.dart';
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
  static const _maxContentWidth = 1180.0;

  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _versionLabel = 'v1.5.0';

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

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
    _slideAnim = Tween<double>(begin: 26, end: 0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _loadVersionLabel();
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

  Future<void> _loadVersionLabel() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLabel = 'v${packageInfo.version}';
      });
    } catch (_) {
      // Mantiene el valor por defecto si la versión no puede consultarse.
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

  Widget _buildAuthColumn({double? maxWidth}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? 460),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            versionLabel: _versionLabel,
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
              final isWideLayout = constraints.maxWidth >= 1040;
              final heroHeight = isWideLayout
                  ? (viewportHeight - 52).clamp(560.0, 760.0).toDouble()
                  : (viewportHeight > 760 ? 352.0 : 304.0);
              const overlap = 86.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  isWideLayout ? 18 : 0,
                  16,
                  media.viewInsets.bottom + 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewportHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxContentWidth,
                      ),
                      child: isWideLayout
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 12,
                                  child: LoginHero(
                                    height: heroHeight,
                                    compact: false,
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  flex: 9,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: _buildAuthColumn(maxWidth: 460),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                LoginHero(height: heroHeight, compact: true),
                                Transform.translate(
                                  offset: const Offset(0, -overlap),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: _buildAuthColumn(),
                                  ),
                                ),
                              ],
                            ),
                    ),
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
