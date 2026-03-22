import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/app_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _selectedGender = 'male';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    try {
      if (_isLogin) {
        await state.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      } else {
        await state.register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _selectedGender,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AppState>().isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              kGradientPurple.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          kGradient.createShader(bounds),
                      child: const Icon(Icons.explore,
                          size: 64, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          kGradient.createShader(bounds),
                      child: Text(
                        'Event Discovery',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connect & socialize around shared interests',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (!_isLogin) ...[
                            _field(
                              controller: _nameCtrl,
                              hint: 'Full name',
                              icon: Icons.person_outline,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _field(
                            controller: _emailCtrl,
                            hint: 'Email',
                            icon: Icons.email_outlined,
                            inputType: TextInputType.emailAddress,
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Enter a valid email'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            controller: _passwordCtrl,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            obscure: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Min 6 characters'
                                : null,
                          ),
                          if (!_isLogin) ...[
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: _inputDeco('Gender', Icons.wc),
                              items: const [
                                DropdownMenuItem(
                                    value: 'male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'other', child: Text('Other')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedGender = v!),
                            ),
                          ],
                          const SizedBox(height: 24),
                          GradientButton(
                            label: _isLogin ? 'Sign In' : 'Create Account',
                            isLoading: isLoading,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? "Don't have an account? Sign Up"
                            : 'Already have an account? Sign In',
                        style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: obscure,
      validator: validator,
      decoration: _inputDeco(hint, icon),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kGradientPurple, width: 2),
      ),
    );
  }
}
