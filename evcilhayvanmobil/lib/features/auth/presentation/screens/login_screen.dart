// lib/features/auth/presentation/screens/login_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evcilhayvanmobil/core/services/social_auth_service.dart';
import 'package:evcilhayvanmobil/core/widgets/modern_background.dart';
import 'package:evcilhayvanmobil/features/auth/data/repositories/auth_repository.dart';

import '../../domain/user_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final SocialAuthService _socialAuthService = SocialAuthService();
  bool _isLoading = false;
  String? _errorMessage;
  SocialProvider? _socialInProgress;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final email = _emailController.text;
      final user = await authRepo.login(email, _passwordController.text);
      ref.read(authProvider.notifier).loginSuccess(user);
    } on VerificationRequiredException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
      if (mounted) context.pushNamed('verify-email', extra: e.email);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loginAsGuest() {
    context.goNamed('home');
  }

  void _goToRegister() {
    context.pushNamed('register');
  }

  void _goToForgotPassword() {
    context.pushNamed('forgot-password');
  }

  Future<void> _handleSocialLogin(SocialProvider provider) async {
    if (_isLoading || _socialInProgress != null) return;

    setState(() {
      _errorMessage = null;
      _socialInProgress = provider;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      late final User user;

      if (provider == SocialProvider.google) {
        final result = await _socialAuthService.signInWithGoogle();
        user = await authRepo.loginWithGoogleToken(result.token);
      } else {
        final result = await _socialAuthService.signInWithFacebook();
        user = await authRepo.loginWithFacebookToken(result.token);
      }

      ref.read(authProvider.notifier).loginSuccess(user);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoş geldin ${user.name}!'),
        ),
      );
    } on SocialAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _socialInProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<User?>(authProvider, (previous, next) {
      if (next != null) {
        context.pushReplacementNamed('home');
      }
    });

    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: ModernBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surface.withOpacity(0.92),
                        theme.colorScheme.primary.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 32,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.pets,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Tekrar hoş geldin! 👋',
                                        style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Evcil dostlar dünyasına giriş yap ve topluluğa katıl.',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _AnimatedField(
                              delay: 0,
                              child: TextField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _AnimatedField(
                              delay: 80,
                              child: TextField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Şifre',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                obscureText: true,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _goToForgotPassword,
                                child: const Text('Şifremi Unuttum?'),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ],
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Giriş Yap'),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Google ile',
                                    accentColor: Colors.redAccent,
                                    onTap: () => _handleSocialLogin(SocialProvider.google),
                                    isLoading: _socialInProgress == SocialProvider.google,
                                    iconText: 'G',
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialButton(
                                    label: 'Facebook ile',
                                    accentColor: const Color(0xFF1877F2),
                                    onTap: () => _handleSocialLogin(SocialProvider.facebook),
                                    isLoading: _socialInProgress == SocialProvider.facebook,
                                    iconText: 'f',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const _OrDivider(),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _loginAsGuest,
                              icon: const Icon(Icons.visibility_off_outlined),
                              label: const Text('Misafir olarak göz at'),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Hesabın yok mu?'),
                                TextButton(
                                  onPressed: _goToRegister,
                                  child: const Text('Üye ol'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedField extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedField({required this.child, this.delay = 0});

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value = _animation.value;
        return Transform.translate(
          offset: Offset(0, (1 - value) * 20),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: widget.child,
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String iconText;
  final Color accentColor;
  final VoidCallback onTap;
  final bool isLoading;

  const _SocialButton({
    required this.label,
    required this.iconText,
    required this.accentColor,
    required this.onTap,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.95),
                accentColor.withOpacity(0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: Text(
                  iconText,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: textStyle,
                ),
              ),
              if (isLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant.withOpacity(0.4);

    return Row(
      children: [
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Divider(color: dividerColor, thickness: 1)),
      ],
    );
  }
}
