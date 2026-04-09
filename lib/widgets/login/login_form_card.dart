import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginFormCard extends StatelessWidget {
  static const _heroColor = Color(0xFF001A6B);
  static const _cardBg = Colors.white;
  static const _fieldIcon = Color(0xFF7C8190);
  static const _textPrimary = Color(0xFF171B1F);
  static const _textSecondary = Color(0xFF4A5160);
  static const _textMuted = Color(0xFF8D94A3);
  static const _shadowColor = Color(0x14191C1E);

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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(color: _shadowColor, blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bienvenido',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ingrese sus credenciales para acceder al\nsistema.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 34),
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
          const SizedBox(height: 32),
          SizedBox(
            height: 58,
            child: ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _heroColor,
                disabledBackgroundColor: _heroColor.withValues(alpha: 0.75),
                elevation: 0,
                shadowColor: _heroColor.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                          'Iniciar Sesión',
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
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 82,
              height: 1,
              color: const Color(0xFFE8EAF0),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            versionLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: _textMuted,
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
  static const _fieldBg = Color(0xFFE9EDF2);
  static const _fieldIcon = Color(0xFF7C8190);
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
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _fieldIcon, width: 1.1),
        ),
      ),
    );
  }
}
