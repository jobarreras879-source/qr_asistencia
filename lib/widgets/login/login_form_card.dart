import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginFormCard extends StatelessWidget {
  static const _heroColor = Color(0xFF001A6B);
  static const _heroColorDark = Color(0xFF022B8A);
  static const _cardBg = Color(0xFFFFFEFC);
  static const _fieldBg = Color(0xFFF4F7FB);
  static const _fieldBorder = Color(0xFFD8E0EB);
  static const _fieldIcon = Color(0xFF6F7A8E);
  static const _textPrimary = Color(0xFF171B1F);
  static const _textSecondary = Color(0xFF4A5160);
  static const _textMuted = Color(0xFF8D94A3);
  static const _shadowColor = Color(0x1C19243A);

  final TextEditingController usuarioController;
  final TextEditingController passwordController;
  final bool isLoading;
  final bool obscurePassword;
  final String? errorMessage;
  final VoidCallback onLogin;
  final VoidCallback onTogglePassword;
  final String versionLabel;

  const LoginFormCard({
    super.key,
    required this.usuarioController,
    required this.passwordController,
    required this.isLoading,
    required this.obscurePassword,
    required this.errorMessage,
    required this.onLogin,
    required this.onTogglePassword,
    required this.versionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFFE6ECF4)),
        boxShadow: [
          const BoxShadow(
            color: _shadowColor,
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.72),
            blurRadius: 0,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ingreso protegido',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: _heroColor,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  versionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Bienvenido',
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingrese sus credenciales para acceder al sistema de asistencia.',
            style: GoogleFonts.inter(
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 30),
          _LoginFieldLabel(label: 'Usuario'),
          const SizedBox(height: 12),
          _LoginInput(
            controller: usuarioController,
            hint: 'usuario',
            obscureText: false,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person_rounded,
          ),
          const SizedBox(height: 28),
          _LoginFieldLabel(label: 'Contraseña'),
          const SizedBox(height: 12),
          _LoginInput(
            controller: passwordController,
            hint: '••••••••',
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_rounded,
            onSubmitted: (_) => onLogin(),
            suffixIcon: IconButton(
              splashRadius: 18,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: _fieldIcon,
                size: 22,
              ),
              onPressed: onTogglePassword,
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3CBC6)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFBA1A1A),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF93000A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 30),
          SizedBox(
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [_heroColor, _heroColorDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _heroColor.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE7EDF5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: _heroColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Acceso reservado para personal autorizado y administradores del sistema.',
                    style: GoogleFonts.inter(
                      fontSize: 12.8,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: _textSecondary,
                    ),
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

class _LoginFieldLabel extends StatelessWidget {
  final String label;

  const _LoginFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF3B4050),
      ),
    );
  }
}

class _LoginInput extends StatelessWidget {
  static const _heroColor = Color(0xFF001A6B);
  static const _fieldBg = Color(0xFFF4F7FB);
  static const _fieldBorder = Color(0xFFD8E0EB);
  static const _fieldIcon = Color(0xFF6F7A8E);
  static const _textPrimary = Color(0xFF171B1F);
  static const _textMuted = Color(0xFF8D94A3);

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputAction textInputAction;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _LoginInput({
    required this.controller,
    required this.hint,
    required this.obscureText,
    required this.textInputAction,
    required this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textMuted,
        ),
        filled: true,
        fillColor: _fieldBg,
        prefixIcon: Icon(prefixIcon, color: _fieldIcon, size: 22),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _heroColor, width: 1.5),
        ),
      ),
    );
  }
}
