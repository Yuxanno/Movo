import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/app_store.dart';
import '../../core/utils/helpers.dart';
import '../../main.dart';
import '../widgets/currency_calculator.dart';
import 'pin_screen.dart';
import 'categories_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _biometry = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AppStore>().loadLanguage());
  }

  void _showLanguageDialog() {
    final store = context.read<AppStore>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _LangItem(label: 'Русский', code: 'ru', flag: '🇷🇺', current: store.lang, 
            onTap: (c) { store.setLanguage(c); Navigator.pop(context); }),
          _LangItem(label: 'English', code: 'en', flag: '🇺🇸', current: store.lang, 
            onTap: (c) { store.setLanguage(c); Navigator.pop(context); }),
          _LangItem(label: 'O\'zbekcha', code: 'uz', flag: '🇺🇿', current: store.lang, 
            onTap: (c) { store.setLanguage(c); Navigator.pop(context); }),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final flag = store.lang == 'ru' ? '🇷🇺' : (store.lang == 'en' ? '🇺🇸' : '🇺🇿');

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(children: [
            const SizedBox(height: 20),
            Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.person, size: 40, color: Color(0xFF16a34a))),
            const SizedBox(height: 12),
            Text(store.userName ?? '—', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1f2937))),
            Text('@${store.userLogin ?? '—'}', style: const TextStyle(fontSize: 14, color: Color(0xFF9ca3af))),
            const SizedBox(height: 20),

            Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
                child: Column(children: [
                  Text('${store.accounts.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16a34a))),
                  Text(store.t('accounts'), style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                ]),
              )),
              const SizedBox(width: 12),
              Expanded(child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
                child: Column(children: [
                  Text('${store.transactions.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16a34a))),
                  Text(store.t('operations'), style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af))),
                ]),
              )),
            ]),
            const SizedBox(height: 16),

            // Currency Calculator
            const CurrencyCalculatorWidget(),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8)]),
              child: Column(children: [
                _SettingRow(icon: Icons.tag, label: store.t('categories'), onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: context.read<AppStore>(), child: const CategoriesScreen())));
                }),
                _SettingRow(icon: Icons.language, label: store.t('language'), trailing: flag, onTap: _showLanguageDialog),
                
                FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snapshot) {
                    final prefs = snapshot.data;
                    final bool hasPin = prefs?.getString('pin_code') != null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                               child: const Icon(Icons.lock_outline, size: 16, color: Color(0xFF6b7280))),
                            const SizedBox(width: 12),
                            Text(store.t('security_pin'), style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                          ]),
                          Switch(
                            value: hasPin,
                            activeColor: const Color(0xFF16a34a),
                            onChanged: (v) async {
                              if (v) {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => const PinScreen(isConfirming: false)));
                                setState(() {});
                              } else {
                                await Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => PinScreen(
                                    title: store.lang == 'ru' ? "Введите текущий PIN" : "Enter current PIN",
                                    onSuccess: () async {
                                      final p = await SharedPreferences.getInstance();
                                      await p.remove('pin_code');
                                      setState(() {});
                                    },
                                  ),
                                ));
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [
                       Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fingerprint, size: 16, color: Color(0xFF6b7280))),
                       const SizedBox(width: 12),
                       Text(store.t('biometry'), style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
                    ]),
                    Switch(value: _biometry, activeColor: const Color(0xFF16a34a), onChanged: (v) => setState(() => _biometry = v)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final savedPin = prefs.getString('pin_code');
                  if (!mounted) return;
                  if (savedPin != null) {
                    navigatorKey.currentState!.push(MaterialPageRoute(
                      builder: (_) => PinScreen(
                        title: store.lang == 'ru' ? 'Подтвердите выход' : 'Confirm logout',
                        onSuccess: () async {
                          await context.read<AppStore>().logout();
                          navigatorKey.currentState!.pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        },
                      ),
                    ));
                  } else {
                    await context.read<AppStore>().logout();
                    navigatorKey.currentState!.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: Text(store.t('logout')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFef4444),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LangItem extends StatelessWidget {
  final String label;
  final String code;
  final String flag;
  final String current;
  final Function(String) onTap;
  const _LangItem({required this.label, required this.code, required this.flag, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool active = current == code;
    return InkWell(
      onTap: () => onTap(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (active) const Icon(Icons.check_circle, color: Color(0xFF16a34a), size: 20),
        ]),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  final bool last;
  const _SettingRow({required this.icon, required this.label, this.trailing, required this.onTap, this.last = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 16, color: const Color(0xFF6b7280))),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
          ]),
          Row(children: [
            if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFd1d5db)),
          ]),
        ]),
      ),
    );
  }
}
