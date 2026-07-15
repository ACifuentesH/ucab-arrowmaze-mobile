import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';

/// Pantalla de registro conectada a [AuthViewModel].
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _usernameFocused = false;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(_onUsernameFocusChange);
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
  }

  void _onUsernameFocusChange() {
    final focused = _usernameFocus.hasFocus;
    if (focused != _usernameFocused) {
      setState(() => _usernameFocused = focused);
    }
  }

  void _onEmailFocusChange() {
    final focused = _emailFocus.hasFocus;
    if (focused != _emailFocused) {
      setState(() => _emailFocused = focused);
    }
  }

  void _onPasswordFocusChange() {
    final focused = _passwordFocus.hasFocus;
    if (focused != _passwordFocused) {
      setState(() => _passwordFocused = focused);
    }
  }

  @override
  void dispose() {
    _usernameFocus.removeListener(_onUsernameFocusChange);
    _emailFocus.removeListener(_onEmailFocusChange);
    _passwordFocus.removeListener(_onPasswordFocusChange);
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authViewModelProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref.read(authViewModelProvider.notifier).register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _t.hudText,
        title: const Text('Crear cuenta'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Arrow\nEscape',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: _t.primary,
                            height: 1.05,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Completa tus datos para registrarte',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: _t.hudText.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const _SectionLabel('Username'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enabled: !auth.isLoading,
                          onTap: () {
                            if (!_usernameFocused) {
                              setState(() => _usernameFocused = true);
                            }
                          },
                          decoration: _inputDecoration(
                            hintText: 'tu_usuario',
                            showHint: !_usernameFocused,
                            prefixIcon: Icons.person_outline,
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Ingresa un username';
                            if (trimmed.length < 3 || trimmed.length > 30) {
                              return 'El username debe tener entre 3 y 30 caracteres';
                            }
                            return null;
                          },
                          onChanged: (_) => ref
                              .read(authViewModelProvider.notifier)
                              .clearError(),
                        ),
                        const SizedBox(height: 20),
                        const _SectionLabel('Email'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enabled: !auth.isLoading,
                          onTap: () {
                            if (!_emailFocused) {
                              setState(() => _emailFocused = true);
                            }
                          },
                          decoration: _inputDecoration(
                            hintText: 'tu@email.com',
                            showHint: !_emailFocused,
                            prefixIcon: Icons.mail_outline,
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Ingresa tu correo';
                            if (!trimmed.contains('@')) {
                              return 'Correo electrónico inválido';
                            }
                            return null;
                          },
                          onChanged: (_) => ref
                              .read(authViewModelProvider.notifier)
                              .clearError(),
                        ),
                        const SizedBox(height: 20),
                        const _SectionLabel('Password'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          enabled: !auth.isLoading,
                          onTap: () {
                            if (!_passwordFocused) {
                              setState(() => _passwordFocused = true);
                            }
                          },
                          decoration: _inputDecoration(
                            hintText: '••••••••',
                            showHint: !_passwordFocused,
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: auth.isLoading
                                  ? null
                                  : () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                          onChanged: (_) => ref
                              .read(authViewModelProvider.notifier)
                              .clearError(),
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 20),
                          _ErrorBanner(message: auth.errorMessage!),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _t.primary,
                                foregroundColor: _t.onPrimary,
                                disabledBackgroundColor:
                                    _t.primary.withValues(alpha: 0.5),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: auth.isLoading ? null : _submit,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('REGISTRARSE'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              '¿Ya tienes cuenta? Inicia sesión',
                              style: TextStyle(
                                color: _t.primary.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool showHint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: showHint ? hintText : '',
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: _t.boardBackground,
      prefixIcon: Icon(prefixIcon, color: _t.hudText.withValues(alpha: 0.6)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _t.hudText.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _t.primary.withValues(alpha: 0.8)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: ThemeConfig.dark.hudText,
          ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
