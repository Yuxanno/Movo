import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_settings/app_settings.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

import 'data/app_store.dart';
import 'presentation/screens/app_shell.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/pin_screen.dart';
import 'core/ad_service.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('uz', null);
  // Инициализируем AdMob только на мобильных
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
  final savedUser = await AppStore.loadUserFromPrefs();
  runApp(MovoApp(savedUser: savedUser));
}

class MovoApp extends StatelessWidget {
  final Map<String, dynamic>? savedUser;
  const MovoApp({Key? key, this.savedUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final store = AppStore();
        if (savedUser != null) {
          store.setUser(
            savedUser!['_id'] as String,
            name: savedUser!['name'] as String?,
            login: savedUser!['login'] as String?,
          );
          Future.microtask(() {
            store.fetchAccounts();
            store.fetchTransactions();
            store.fetchCategories();
            store.fetchRates();
          });
        }
        return store;
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Movo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Inter',
          scaffoldBackgroundColor: const Color(0xFFF0F7F4),
          colorSchemeSeed: const Color(0xFF22c55e),
        ),
        builder: (context, child) => ConnectionWrapper(child: child!),
        home: AppEntry(savedUser: savedUser),
      ),
    );
  }
}

class ConnectionWrapper extends StatefulWidget {
  final Widget child;
  const ConnectionWrapper({Key? key, required this.child}) : super(key: key);
  @override State<ConnectionWrapper> createState() => _ConnectionWrapperState();
}

class _ConnectionWrapperState extends State<ConnectionWrapper> {
  bool _isNone = false;
  bool _isNoInternet = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _check();
    _sub = Connectivity().onConnectivityChanged.listen((res) => _check());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final res = await Connectivity().checkConnectivity();
    bool none = res.contains(ConnectivityResult.none);
    bool noInternet = false;

    // Strict check only on non-web platforms to avoid CORS issues
    if (!none && !kIsWeb) {
      try {
        final head = await http.head(Uri.parse('https://www.google.com/favicon.ico'))
            .timeout(const Duration(seconds: 4));
        noInternet = head.statusCode != 200;
      } catch (_) {
        noInternet = true;
      }
    }

    if (mounted) setState(() { _isNone = none; _isNoInternet = noInternet; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isNone || _isNoInternet) {
      return Scaffold(
        backgroundColor: const Color(0xFF16a34a),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                Text(
                  _isNone ? 'Wi-Fi выключен' : 'Нет интернета',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _isNone ? 'Включите интернет, чтобы продолжить' : 'Связь есть, но интернет заблокирован или отсутствует',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withAlpha(204)),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isNone ? () {
                    if (kIsWeb) { _check(); } else { AppSettings.openAppSettings(type: AppSettingsType.wifi); }
                  } : _check,
                  icon: Icon(_isNone ? (kIsWeb ? Icons.refresh : Icons.settings) : Icons.refresh),
                  label: Text(_isNone ? (kIsWeb ? 'Обновить' : 'Настройки') : 'Попробовать снова'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF16a34a),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}

class AppEntry extends StatefulWidget {
  final Map<String, dynamic>? savedUser;
  const AppEntry({Key? key, this.savedUser}) : super(key: key);
  @override State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin = prefs.getString('pin_code') != null;
    if (!mounted) return;

    if (widget.savedUser == null) {
      navigatorKey.currentState!.pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } else if (hasPin) {
      navigatorKey.currentState!.pushReplacement(MaterialPageRoute(builder: (_) => PinScreen(
        onSuccess: () => navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShellWithLifecycle()),
          (_) => false,
        ),
      )));
    } else {
      navigatorKey.currentState!.pushReplacement(MaterialPageRoute(builder: (_) => const AppShellWithLifecycle()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF16a34a),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.location_on, color: Colors.white, size: 64),
        SizedBox(height: 12),
        Text('Movo', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
      ])),
    );
  }
}

class AppShellWithLifecycle extends StatefulWidget {
  const AppShellWithLifecycle({Key? key}) : super(key: key);
  @override State<AppShellWithLifecycle> createState() => _AppShellWithLifecycleState();
}

class _AppShellWithLifecycleState extends State<AppShellWithLifecycle> with WidgetsBindingObserver {
  bool _locked = false;
  bool _showingPin = false;
  final _adService = AdService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Загружаем рекламу и показываем через 5 секунд (только на мобильных)
    if (!kIsWeb) {
      _adService.load().then((_) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _adService.show();
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _adService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('pin_code') != null) _locked = true;
    } else if (state == AppLifecycleState.resumed && _locked && !_showingPin) {
      _locked = false;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('pin_code') == null) return;
      _showingPin = true;
      await navigatorKey.currentState!.push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => WillPopScope(
          onWillPop: () async => false, // Cannot pop back
          child: PinScreen(
            onSuccess: () {
              _showingPin = false;
              navigatorKey.currentState!.pop();
            },
          ),
        ),
      ));
      _showingPin = false;
    }
  }

  @override
  Widget build(BuildContext context) => const AppShell();
}
