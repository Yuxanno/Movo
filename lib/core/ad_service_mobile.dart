import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const _adUnitId = 'ca-app-pub-6927990255059344/3694136021';
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 3);

  InterstitialAd? _ad;
  bool _loaded = false;
  int _retryCount = 0;

  Future<void> load() async {
    // Небольшая задержка — даём AdMob SDK полностью инициализироваться
    await Future.delayed(const Duration(milliseconds: 500));
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
          _retryCount = 0;
        },
        onAdFailedToLoad: (error) {
          _loaded = false;
          // Повторяем попытку при неудаче
          if (_retryCount < _maxRetries) {
            _retryCount++;
            Future.delayed(_retryDelay, _loadAd);
          }
        },
      ),
    );
  }

  Future<void> show() async {
    if (_loaded && _ad != null) {
      _ad!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _ad = null;
          _loaded = false;
          // Сразу грузим следующую рекламу для следующего показа
          _retryCount = 0;
          _loadAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _ad = null;
          _loaded = false;
        },
      );
      await _ad!.show();
    }
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }
}
