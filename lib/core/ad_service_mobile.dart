import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const _adUnitId = 'ca-app-pub-6927990255059344/3694136021';
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 5);

  InterstitialAd? _ad;
  bool _loaded = false;
  bool _loading = false;
  int _retryCount = 0;

  /// Загружает рекламу. Если уже загружена или идёт загрузка — не дублирует.
  Future<void> load() async {
    if (_loaded || _loading) return;
    _loading = true;
    _retryCount = 0;
    await _loadAd();
  }

  Future<void> _loadAd() async {
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loaded = true;
          _loading = false;
          _retryCount = 0;
        },
        onAdFailedToLoad: (error) {
          _loaded = false;
          _loading = false;
          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(_retryDelay, _loadAd);
          }
        },
      ),
    );
  }

  /// Показывает рекламу если загружена.
  /// [onComplete] вызывается когда пользователь закрыл рекламу.
  Future<void> show({VoidCallback? onComplete}) async {
    if (!_loaded || _ad == null) {
      // Реклама ещё не готова — пробуем загрузить на следующий раз
      load();
      onComplete?.call();
      return;
    }

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _loaded = false;
        // Сразу грузим следующую
        load();
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _ad = null;
        _loaded = false;
        load();
        onComplete?.call();
      },
    );
    await _ad!.show();
  }

  bool get isLoaded => _loaded;

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
    _loading = false;
  }
}
