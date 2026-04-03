import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const _adUnitId = 'ca-app-pub-6927990255059344/3694136021';

  InterstitialAd? _ad;
  bool _loaded = false;

  Future<void> load() async {
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loaded = true;
        },
        onAdFailedToLoad: (_) {
          _loaded = false;
        },
      ),
    );
  }

  Future<void> show() async {
    if (_loaded && _ad != null) {
      await _ad!.show();
      _loaded = false;
      _ad = null;
    }
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
