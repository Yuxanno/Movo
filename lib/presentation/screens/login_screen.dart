import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_store.dart';
import '../../data/api_service.dart';
import '../../main.dart';
import 'app_shell.dart';
import 'register_screen.dart';
import 'pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPass = false;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _loginCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loginCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Заполните все поля');
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await ApiService.login(_loginCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      final store = context.read<AppStore>();
      store.setUser(data['_id'] as String, name: data['name'] as String?, login: data['login'] as String?);
      await store.saveUserToPrefs(data);
      await store.fetchAccounts();
      await store.fetchTransactions();
      await store.fetchCategories();
      await store.fetchRates();
      if (!mounted) return;
      // Если есть PIN — попросить ввести перед входом
      final prefs = await SharedPreferences.getInstance();
      final savedPin = prefs.getString('pin_code');
      if (savedPin != null && mounted) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => PinScreen(
            title: 'Подтвердите вход',
            onSuccess: () => navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AppShellWithLifecycle()),
              (_) => false,
            ),
          )),
          (_) => false,
        );
      } else if (mounted) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShellWithLifecycle()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // Hero
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 32, 24, 48),
          color: const Color(0xFF16a34a),
          child: Column(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 16)]),
              child: const Center(child: Icon(Icons.location_on, color: Color(0xFF16a34a), size: 40)),
            ),
            const SizedBox(height: 12),
            const Text('Movo', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text('Управляй финансами легко', style: TextStyle(fontSize: 14, color: Colors.white.withAlpha(204))),
          ]),
        ),
        // Form
        Expanded(
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            transform: Matrix4.translationValues(0, -24, 0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Вход', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1f2937))),
                const SizedBox(height: 4),
                const Text('Войдите в свой аккаунт', style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
                const SizedBox(height: 24),
                if (_error.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)),
                    child: Text(_error, style: const TextStyle(fontSize: 14, color: Color(0xFFef4444))),
                  ),
                _InputField(
                  controller: _loginCtrl, 
                  hint: 'Логин', 
                  icon: Icons.person_outline,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _InputField(
                  controller: _passCtrl, 
                  hint: 'Пароль', 
                  icon: Icons.lock_outline,
                  obscure: !_showPass,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  suffix: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(0xFF9ca3af)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4, shadowColor: const Color(0xFF16a34a).withAlpha(77),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Войти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                Center(child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: RichText(text: const TextSpan(
                    text: 'Нет аккаунта? ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
                    children: [TextSpan(text: 'Зарегистрироваться', style: TextStyle(color: Color(0xFF16a34a), fontWeight: FontWeight.bold))],
                  )),
                )),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.action,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe5e7eb))),
      child: Row(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Icon(icon, size: 18, color: const Color(0xFF9ca3af))),
        Expanded(child: TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: action,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFF9ca3af), fontSize: 14),
            border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1f2937)),
        )),
        if (suffix != null) Padding(padding: const EdgeInsets.only(right: 14), child: suffix!),
      ]),
    );
  }
}
