import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_locale.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLogin = true;

  Future<void> _submit() async {
    final s = S.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = _isLogin
        ? await auth.login(
            _usernameController.text.trim(), _passwordController.text)
        : await auth.register(
            _usernameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );

    if (!success && mounted) {
      final error = auth.lastError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? (_isLogin ? s.signInFailed : s.registerFailed),
          ),
        ),
      );
    }
  }

  void _toggleLanguage() async {
    final locale = LocaleController.of(context, listen: false);
    final picked = await showDialog<AppLang>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(S.of(context).language),
        children: AppLang.values.map((l) {
          return SimpleDialogOption(
            child: Row(
              children: [
                Text(l.label),
                const SizedBox(width: 8),
                if (l == locale.lang) Icon(Icons.check, color: kRed, size: 18),
              ],
            ),
            onPressed: () => Navigator.pop(context, l),
          );
        }).toList(),
      ),
    );
    if (picked != null) await locale.setLang(picked);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: kUserBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Language toggle (visible before login too)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _toggleLanguage,
                      icon: const Icon(Icons.language, size: 18),
                      label: Text(
                        '${LocaleController.of(context, listen: false).lang.label}',
                        style: outfitStyle(size: 12, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kRed,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        'N',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? s.welcomeBack : s.joinNaql,
                    style: outfitStyle(
                        size: 24, weight: FontWeight.bold, color: kUserText),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: s.usernameOrEmail,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: s.emailAddress,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: s.password,
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: context.watch<AuthProvider>().isLoading
                          ? null
                          : _submit,
                      child: context.watch<AuthProvider>().isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isLogin ? s.loginBtn : s.registerBtn,
                              style: outfitStyle(
                                  size: 16,
                                  weight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? s.createAccount : s.alreadyHave),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
