import 'package:digital_wardrobe_app/core/widgets/back_arrow_button.dart';
import 'package:digital_wardrobe_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Change password flow: verifies the current password through the existing
/// Supabase authentication architecture, then updates it with
/// [AuthController.updatePassword]. Password storage remains server-side.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  bool _saving = false;

  static final RegExp _hasUppercase = RegExp(r'[A-Z]');
  static final RegExp _hasLowercase = RegExp(r'[a-z]');
  static final RegExp _hasDigit = RegExp(r'[0-9]');
  static final RegExp _hasSpecial = RegExp(r'[^A-Za-z0-9]');

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isStrongPassword(String password) {
    if (password.length < 8) return false;
    return _hasUppercase.hasMatch(password) &&
        _hasLowercase.hasMatch(password) &&
        _hasDigit.hasMatch(password) &&
        _hasSpecial.hasMatch(password);
  }

  Future<void> _changePassword() async {
    final String currentPassword = _currentPasswordController.text;
    final String newPassword = _newPasswordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      _showMessage('Please enter your current password.');
      return;
    }

    if (!_isStrongPassword(newPassword)) {
      _showMessage(
        'New password must be at least 8 characters and include an '
        'uppercase letter, a lowercase letter, a number and a special '
        'character.',
      );
      return;
    }

    if (newPassword != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() => _saving = true);

    try {
      try {
        await ref
            .read(authControllerProvider)
            .signInWithEmail(widget.email, currentPassword);
      } on AuthException {
        if (!mounted) return;
        _showMessage('Current password is incorrect.');
        return;
      }

      await ref.read(authControllerProvider).updatePassword(newPassword);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Password updated'),
            content: const Text(
              'Your password has been changed successfully.',
            ),
            actions: <Widget>[
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      context.go('/auth');
    } on AuthException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to update your password. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackArrowButton(),
        title: const Text('Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Change password',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use a strong password with uppercase and lowercase letters, '
                'numbers, and a special character.',
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _currentPasswordController,
                obscureText: _hideCurrentPassword,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideCurrentPassword = !_hideCurrentPassword;
                      });
                    },
                    icon: Icon(
                      _hideCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _newPasswordController,
                obscureText: _hideNewPassword,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideNewPassword = !_hideNewPassword;
                      });
                    },
                    icon: Icon(
                      _hideNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _confirmPasswordController,
                obscureText: _hideConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _hideConfirmPassword = !_hideConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saving ? null : _changePassword,
                child: Text(
                  _saving ? 'Changing...' : 'Change Password',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}