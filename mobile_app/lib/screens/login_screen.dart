import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLoginSuccess,
    this.locale = const Locale('en'),
    this.onLocaleChanged,
  });

  final VoidCallback? onLoginSuccess;
  final Locale locale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _authErrorMessage(Object error, AppLocalizations loc) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => loc.tr('emailAlreadyInUse'),
        'invalid-email' => loc.tr('invalidEmail'),
        'weak-password' => loc.tr('weakPassword'),
        'operation-not-allowed' => loc.tr('registrationDisabled'),
        'network-request-failed' => loc.tr('networkError'),
        'too-many-requests' => loc.tr('tooManyRequests'),
        _ => error.message ?? loc.tr('authFailed'),
      };
    }
    return loc.tr('authFailed');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final worker = _isRegistering
          ? await AuthService.instance.registerHealthWorker(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
            )
          : await AuthService.instance.login(
              _emailController.text,
              _passwordController.text,
            );

      if (!mounted) return;

      if (worker == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).tr('invalidCredentials'),
            ),
          ),
        );
        return;
      }

      final onLoginSuccess = widget.onLoginSuccess;
      if (onLoginSuccess != null) {
        onLoginSuccess();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _AppHomeRedirect()),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_authErrorMessage(error, AppLocalizations.of(context)))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleRegistration() {
    setState(() {
      _isRegistering = !_isRegistering;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1D7D8D);
    const tealDark = Color(0xFF0D4C5C);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [teal, tealDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 420,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.center,
                          child: Icon(Icons.local_hospital_rounded,
                              size: 56, color: teal),
                        ),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.center,
                          child: Text(
                            'CREPISENSE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: teal,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                loc.tr(_isRegistering
                                    ? 'registerHealthWorker'
                                    : 'healthWorkerSignIn'),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<Locale>(
                              tooltip: loc.tr('selectLanguage'),
                              onSelected: widget.onLocaleChanged,
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: Locale('en'),
                                  child: Text('English'),
                                ),
                                PopupMenuItem(
                                  value: Locale('hi'),
                                  child: Text('हिन्दी'),
                                ),
                                PopupMenuItem(
                                  value: Locale('bn'),
                                  child: Text('বাংলা'),
                                ),
                                PopupMenuItem(
                                  value: Locale('as'),
                                  child: Text('অসমীয়া'),
                                ),
                              ],
                              child: Text(
                                widget.locale.languageCode.toUpperCase(),
                                style: const TextStyle(
                                  color: teal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (_isRegistering) ...[
                          Text(
                            loc.tr('registrationHint'),
                            style: const TextStyle(
                              color: Color(0xFF61747A),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_isRegistering) ...[
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? loc.tr('enterName')
                                    : null,
                            decoration: InputDecoration(
                              labelText: loc.tr('fullName'),
                              prefixIcon: const Icon(Icons.person_outline),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? loc.tr('enterEmail')
                                  : null,
                          decoration: InputDecoration(
                            labelText: loc.tr('email'),
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: _isRegistering
                              ? TextInputAction.next
                              : TextInputAction.done,
                          validator: (value) => (value == null || value.isEmpty)
                              ? loc.tr('enterPassword')
                              : _isRegistering && value.length < 6
                                  ? loc.tr('weakPassword')
                                  : null,
                          decoration: InputDecoration(
                            labelText: loc.tr('password'),
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_isRegistering) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            validator: (value) =>
                                value != _passwordController.text
                                    ? loc.tr('passwordsDoNotMatch')
                                    : null,
                            decoration: InputDecoration(
                              labelText: loc.tr('confirmPassword'),
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Text(
                                    loc.tr(_isRegistering
                                        ? 'createAccount'
                                        : 'signIn'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed:
                                _isSubmitting ? null : _toggleRegistration,
                            child: Text(loc.tr(_isRegistering
                                ? 'alreadyHaveAccount'
                                : 'needAccount')),
                          ),
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
    );
  }
}

class _AppHomeRedirect extends StatelessWidget {
  const _AppHomeRedirect();

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
