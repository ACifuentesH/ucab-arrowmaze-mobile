import 'package:flutter/material.dart';

import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';

/// Resultado elegido por el usuario en [showLoginPromptSheet].
enum LoginPromptChoice { login, register, guest }

/// Bottom sheet ligero que se muestra al tocar "JUGAR" sin sesión activa.
/// Ofrece iniciar sesión, registrarse o continuar como invitado — el modo
/// invitado es la opción más simple/visible para no añadir fricción a quien
/// no quiere loguearse. Devuelve `null` si el usuario lo cierra sin elegir
/// (p. ej. deslizando hacia abajo o tocando fuera), en cuyo caso la Home no
/// avanza a ningún lado.
Future<LoginPromptChoice?> showLoginPromptSheet(BuildContext context) {
  const t = ThemeConfig.dark;
  return showModalBottomSheet<LoginPromptChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _LoginPromptSheet(t: t),
  );
}

class _LoginPromptSheet extends StatelessWidget {
  final ThemeConfig t;

  const _LoginPromptSheet({required this.t});

  static const Color _cardBackground = Color(0xFF0A1628);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.loginPromptTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.loginPromptSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.onPrimary,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(LoginPromptChoice.login),
                  child: Text(l.loginPromptLoginButton),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.hudText,
                    side: BorderSide(color: t.primary.withValues(alpha: 0.5)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pop(LoginPromptChoice.register),
                  child: Text(l.loginPromptRegisterButton),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(LoginPromptChoice.guest),
                child: Text(
                  l.loginPromptGuestButton,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
