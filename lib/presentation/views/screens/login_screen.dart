import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arrow_maze/config/providers.dart';
import 'package:arrow_maze/config/theme_config.dart';
import 'package:arrow_maze/l10n/app_localizations.dart';
import 'package:arrow_maze/presentation/view_models/auth/auth_state.dart';
import 'package:arrow_maze/presentation/views/screens/register_screen.dart';

/// Pantalla de inicio de sesión conectada a [AuthViewModel].
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const ThemeConfig _t = ThemeConfig.dark;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
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
    _emailFocus.removeListener(_onEmailFocusChange);
    _passwordFocus.removeListener(_onPasswordFocusChange);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref.read(authViewModelProvider.notifier).clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(authViewModelProvider.notifier)
        .login(_emailController.text, _passwordController.text, l10n: l10n);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final l = AppLocalizations.of(context)!;

    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && context.mounted) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      backgroundColor: _t.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _t.hudText,
        title: Text(l.loginTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 24),
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
                                l.loginSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _t.hudText.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 40),
                              _SectionLabel(l.emailLabel),
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
                                  hintText: l.emailHint,
                                  showHint: !_emailFocused,
                                  prefixIcon: Icons.mail_outline,
                                ),
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.isEmpty) {
                                    return l.emailRequired;
                                  }
                                  if (!trimmed.contains('@')) {
                                    return l.emailInvalid;
                                  }
                                  return null;
                                },
                                onChanged: (_) => ref
                                    .read(authViewModelProvider.notifier)
                                    .clearError(),
                              ),
                              const SizedBox(height: 20),
                              _SectionLabel(l.passwordLabel),
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
                                    return l.passwordRequired;
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
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 32),
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
                                      disabledBackgroundColor: _t.primary
                                          .withValues(alpha: 0.5),
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
                                        : Text(l.loginSubmitButton),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen(),
                                          ),
                                        ),
                                  child: Text(
                                    l.loginRegisterLink,
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
            );
          },
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
        borderSide: BorderSide(color: _t.hudText.withValues(alpha: 0.1)),
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
