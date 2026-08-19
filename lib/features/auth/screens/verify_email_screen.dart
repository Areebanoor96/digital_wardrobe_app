import 'package:digital_wardrobe_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends ConsumerState<VerifyEmailScreen> {
  final TextEditingController _codeController =
  TextEditingController();

  bool _verifying = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final String code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage('Enter the verification code.');
      return;
    }

    setState(() => _verifying = true);

    try {
      final AuthResponse response =
      await ref.read(authControllerProvider).verifyEmailOtp(
        widget.email,
        code,
      );

      if (!mounted) return;

      if (response.session != null) {
        context.go('/setup');
      } else {
        _showMessage(
          'Email verified. Please sign in to continue.',
        );
        context.go('/auth');
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Unable to verify the code. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);

    try {
      await ref
          .read(authControllerProvider)
          .resendSignupOtp(widget.email);

      if (!mounted) return;

      _showMessage('A new verification code has been sent.');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'Unable to resend the code. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _resending = false);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Check your email',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification code to\n${widget.email}',
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  hintText: 'Enter code',
                ),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: Text(
                  _verifying
                      ? 'Verifying...'
                      : 'Verify Email',
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: Text(
                  _resending
                      ? 'Sending...'
                      : 'Resend code',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}