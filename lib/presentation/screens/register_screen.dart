import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_store.dart';
import '../../data/api_service.dart';
import 'app_shell.dart';
import 'login_screen.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 0; // 0=Account, 1=Profile, 2=PIN, 3=Done

  // Step 0
  final _loginCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;

  // Step 1
  final _nameCtrl = TextEditingController();
  String _currency = 'UZS';

  // Step 2 — PIN
  String _pin = '';
  String _pinFirst = '';
  bool _pinConfirming = false;
  bool _pinError = false;

  bool _loading = false;
  String _error = '';

  // Real-time login validation
  bool _checkingLogin = false;
  bool _loginAvailable = false;
  bool _loginChecked = false;

  @override
  void initState() {
    super.initState();
    _loginCtrl.addListener(_checkLoginAvailability);
  }

  @override
  void dispose() {
    _loginCtrl.removeListener(_checkLoginAvailability);
    _loginCtrl.dispose(); _passCtrl.dispose();
    _confirmCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAvailability() async {
    final login = _loginCtrl.text.trim();
    
    if (login.isEmpty) {
      setState(() {
        _checkingLogin = false;
        _loginAvailable = false;
        _loginChecked = false;
      });
      return;
    }

    setState(() => _checkingLogin = true);
    
    try {
      final available = await ApiService.checkLoginAvailable(login);
      if (mounted) {
        setState(() {
          _checkingLogin = false;
          _loginAvailable = available;
          _loginChecked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingLogin = false;
          _loginAvailable = false;
          _loginChecked = true;
        });
      }
    }
  }

  Future<void> _handleNext() async {
    final store = context.read<AppStore>();
    setState(() => _error = '');
    if (_step == 0) {
      if (_loginCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
        setState(() => _error = store.t('fill_fields')); return;
      }
      if (_passCtrl.text.length < 6) {
        setState(() => _error = store.t('pass_min')); return;
      }
      if (_passCtrl.text != _confirmCtrl.text) {
        setState(() => _error = store.t('pass_mismatch')); return;
      }
      // Check if login is available
      if (!_loginAvailable) {
        setState(() => _error = 'Логин уже занят'); return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_nameCtrl.text.isEmpty) {
        setState(() => _error = store.t('enter_name')); return;
      }
      setState(() { _loading = true; });
      try {
        final data = await ApiService.register(
          login: _loginCtrl.text.trim(),
          password: _passCtrl.text,
          name: _nameCtrl.text.trim(),
          currency: _currency,
        );
        if (!mounted) return;
        final store = context.read<AppStore>();
        store.setUser(data['_id'] as String, name: data['name'] as String?, login: data['login'] as String?);
        await store.saveUserToPrefs(data);
        await store.fetchAccounts();
        await store.fetchTransactions();
        await store.fetchCategories();
        await store.fetchRates();
        setState(() { _loading = false; _step = 2; });
      } catch (e) {
        setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
      }
    } else if (_step == 3) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppShellWithLifecycle()),
          (_) => false,
        );
      }
    }
  }

  void _onPinKey(String key) async {
    if (_pin.length >= 4) return;
    final next = _pin + key;
    setState(() { _pin = next; _pinError = false; });

    if (next.length == 4) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!_pinConfirming) {
        setState(() { _pinFirst = next; _pin = ''; _pinConfirming = true; });
      } else {
        if (next == _pinFirst) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pin_code', next);
          setState(() { _step = 3; _pin = ''; _pinConfirming = false; _pinFirst = ''; });
        } else {
          setState(() { _pinError = true; _pin = ''; _pinConfirming = false; _pinFirst = ''; });
        }
      }
    }
  }

  void _onPinBack() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _skipPin() {
    setState(() { _step = 3; _pin = ''; _pinConfirming = false; _pinFirst = ''; });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final _steps = [store.t('step_account'), store.t('step_profile'), store.t('step_pin'), store.t('step_done')];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [
        // Hero
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 40),
          color: const Color(0xFF16a34a),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (_step > 0 && _step < 3)
                GestureDetector(
                  onTap: () => setState(() { _step--; _error = ''; }),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  ),
                ),
              if (_step > 0 && _step < 3) const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(store.t('register_title'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(_steps[_step], style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(204))),
                ]),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.language, color: Colors.white),
                onSelected: (l) => context.read<AppStore>().setLanguage(l),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'ru', child: Text('Русский')),
                  const PopupMenuItem(value: 'en', child: Text('English')),
                  const PopupMenuItem(value: 'uz', child: Text('Oʻzbekcha')),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: List.generate(_steps.length, (i) => Expanded(child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < _steps.length - 1 ? 6 : 0),
              decoration: BoxDecoration(
                color: i <= _step ? Colors.white : Colors.white.withAlpha(64),
                borderRadius: BorderRadius.circular(2),
              ),
            )))),
          ]),
        ),

        // Content
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            transform: Matrix4.translationValues(0, -24, 0),
            child: _step == 2 ? _buildPinStep() : _buildFormStep(),
          ),
        ),
      ]),
    );
  }

  Widget _buildFormStep() {
    final store = context.watch<AppStore>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)),
            child: Text(_error, style: const TextStyle(fontSize: 14, color: Color(0xFFef4444))),
          ),

        if (_step == 0) ...[
          Text(store.t('create_account'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1f2937))),
          const SizedBox(height: 4),
          Text(store.t('create_account_desc'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
          const SizedBox(height: 20),
          Stack(
            children: [
              _InputField(controller: _loginCtrl, hint: store.t('login_hint'), icon: Icons.person_outline, action: TextInputAction.next),
              Positioned(
                right: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _checkingLogin
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF16a34a)))
                      : _loginChecked
                          ? Icon(
                              _loginAvailable ? Icons.check_circle : Icons.cancel,
                              color: _loginAvailable ? const Color(0xFF16a34a) : const Color(0xFFef4444),
                              size: 20,
                            )
                          : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InputField(
            controller: _passCtrl, hint: store.t('pass_hint_reg'),
            icon: Icons.lock_outline, obscure: !_showPass,
            action: TextInputAction.next,
            suffix: GestureDetector(
              onTap: () => setState(() => _showPass = !_showPass),
              child: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: const Color(0xFF9ca3af)),
            ),
          ),
          const SizedBox(height: 10),
          _InputField(
            controller: _confirmCtrl, 
            hint: store.t('pass_repeat'), 
            icon: Icons.verified_outlined, 
            obscure: true,
            action: TextInputAction.done,
            onSubmitted: (_) => _handleNext(),
          ),
        ],

        if (_step == 1) ...[
          Text(store.t('about_me'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1f2937))),
          const SizedBox(height: 4),
          Text(store.t('name_currency'), style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
          const SizedBox(height: 20),
          _InputField(
            controller: _nameCtrl, 
            hint: store.t('your_name'), 
            icon: Icons.person_outline,
            action: TextInputAction.done,
            onSubmitted: (_) => _handleNext(),
          ),
          const SizedBox(height: 14),
          Row(children: ['UZS', 'USD', 'RUB'].map((c) => Expanded(child: Padding(
            padding: EdgeInsets.only(right: c != 'RUB' ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _currency = c),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _currency == c ? const Color(0xFF16a34a) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _currency == c ? [BoxShadow(color: const Color(0xFF16a34a).withAlpha(51), blurRadius: 8)] : null,
                ),
                child: Text(c, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: _currency == c ? Colors.white : const Color(0xFF6b7280))),
              ),
            ),
          ))).toList()),
        ],

        if (_step == 3) ...[
          const SizedBox(height: 40),
          Center(child: Column(children: [
            Container(
              width: 96, height: 96,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 48, color: Color(0xFF16a34a)),
            ),
            const SizedBox(height: 16),
            Text(store.t('done_title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1f2937))),
            const SizedBox(height: 8),
            Text(store.t('done_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
          ])),
        ],

        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16a34a), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4, shadowColor: const Color(0xFF16a34a).withAlpha(77),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_step == 3 ? store.t('start_btn') : store.t('next_btn'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),

        if (_step == 0) ...[
          const SizedBox(height: 20),
          Center(child: GestureDetector(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: RichText(text: TextSpan(
              text: store.t('has_account'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af)),
              children: [TextSpan(text: store.t('login_link'), style: const TextStyle(color: Color(0xFF16a34a), fontWeight: FontWeight.bold))],
            )),
          )),
        ],
      ]),
    );
  }

  Widget _buildPinStep() {
    final store = context.watch<AppStore>();
    final title = _pinError
        ? store.t('pin_mismatch')
        : _pinConfirming
            ? store.t('pin_repeat')
            : store.t('pin_create');

    return Column(children: [
      const SizedBox(height: 32),
      Text(title,
        style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold,
          color: _pinError ? const Color(0xFFef4444) : const Color(0xFF1f2937),
        )),
      const SizedBox(height: 6),
      Text(store.t('pin_desc'),
        style: const TextStyle(fontSize: 13, color: Color(0xFF9ca3af))),
      const SizedBox(height: 32),
      // Dots
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(
        width: 16, height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _pinError ? const Color(0xFFef4444) : const Color(0xFF16a34a),
            width: 2,
          ),
          color: _pin.length > i
              ? (_pinError ? const Color(0xFFef4444) : const Color(0xFF16a34a))
              : Colors.transparent,
        ),
      ))),
      const Spacer(),
      // Numpad
      for (final row in [['1','2','3'], ['4','5','6'], ['7','8','9']])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row.map((k) =>
            _PinButton(text: k, onTap: () => _onPinKey(k))
          ).toList()),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          GestureDetector(
            onTap: _skipPin,
            child: SizedBox(width: 72, height: 72,
              child: Center(child: Text(store.t('skip'), style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))))),
          ),
          _PinButton(text: '0', onTap: () => _onPinKey('0')),
          _PinButton(icon: Icons.backspace_outlined, onTap: _onPinBack, isAction: true),
        ]),
      ),
      const SizedBox(height: 24),
    ]);
  }
}

class _PinButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isAction;
  const _PinButton({this.text, this.icon, required this.onTap, this.isAction = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: isAction ? Colors.transparent : Colors.white,
          shape: BoxShape.circle,
          boxShadow: isAction ? null : [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10)],
        ),
        child: Center(
          child: text != null
              ? Text(text!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1f2937)))
              : Icon(icon, color: const Color(0xFF6b7280), size: 24),
        ),
      ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFe5e7eb)),
      ),
      child: Row(children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Icon(icon, size: 18, color: const Color(0xFF9ca3af))),
        Expanded(child: TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: action,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9ca3af), fontSize: 14),
            border: InputBorder.none, isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF1f2937)),
        )),
        if (suffix != null) Padding(padding: const EdgeInsets.only(right: 14), child: suffix!),
      ]),
    );
  }
}
