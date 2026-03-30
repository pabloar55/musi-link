import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musi_link/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musi_link/providers/service_providers.dart';

/// Pantalla de autenticación con Firebase.
/// Permite login/registro con email+contraseña y Google Sign-In.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey =
      GlobalKey<
        FormState
      >(); //Creamos la clave para hacer referencia al formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true; // true = login, false = registro
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitEmailForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      User? user;
      if (_isLogin) {
        user = await ref.read(authServiceProvider).signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        user = await ref.read(authServiceProvider).registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      }

      if (user == null && mounted) {
        _showError(AppLocalizations.of(context)!.authErrorCouldNotAuth);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_mapFirebaseError(e.code));
    } catch (e) {
      if (mounted) _showError(AppLocalizations.of(context)!.authErrorUnexpected);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user == null && mounted) {
        _showError(AppLocalizations.of(context)!.authErrorGoogleSignIn);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_mapFirebaseError(e.code));
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('canceled')) {
          // Si el usuario cancela el diálogo, no mostramos error
          return;
        }
        _showError(
          AppLocalizations.of(context)!.authErrorGoogleSignInGeneric,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapFirebaseError(String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'email-already-in-use':
        return l10n.authErrorEmailInUse;
      case 'invalid-email':
        return l10n.authErrorInvalidEmail;
      case 'weak-password':
        return l10n.authErrorWeakPassword;
      case 'user-not-found':
        return l10n.authErrorUserNotFound;
      case 'wrong-password':
        return l10n.authErrorWrongPassword;
      case 'invalid-credential':
        return l10n.authErrorInvalidCredential;
      case 'too-many-requests':
        return l10n.authErrorTooManyRequests;
      case 'account-exists-with-different-credential':
        return l10n.authErrorAccountExistsWithDifferentCredential;
      default:
        return l10n.authErrorGeneric(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 250),
                const SizedBox(height: 32),

                // Formulario
                Form(
                  key:
                      _formKey, // Asociamos el formulario a la clave para hacer referencia desde fuera de la clase
                  child: Column(
                    children: [
                      // Nombre (solo en registro)
                      if (!_isLogin)
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.authName,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (!_isLogin &&
                                (value == null || value.trim().isEmpty)) {
                              return l10n.authEnterName;
                            }
                            return null;
                          },
                        ),
                      if (!_isLogin) const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: l10n.authEmail,
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.authEnterEmail;
                          }
                          if (!value.contains('@')) {
                            return l10n.authInvalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l10n.authPassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.authEnterPassword;
                          }
                          if (!_isLogin && value.length < 6) {
                            return l10n.authMinChars;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Botón principal
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submitEmailForm,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isLogin
                                      ? l10n.authSignIn
                                      : l10n.authCreateAccount,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        l10n.authOr,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Sign-In
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: const Icon(FontAwesomeIcons.google, size: 20),
                    label: Text(l10n.authContinueGoogle),
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle login/registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLogin ? l10n.authNoAccount : l10n.authHaveAccount),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() => _isLogin = !_isLogin);
                              _formKey.currentState?.reset();
                            },
                      child: Text(
                        _isLogin ? l10n.authRegister : l10n.authLogin,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
