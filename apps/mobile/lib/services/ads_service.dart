import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static bool _mockMode = true;
  static BannerAd? _bannerAd;
  static int _interstitialCounter = 0;

  static Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      _mockMode = false;
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111',
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (_, __) => _mockMode = true,
        ),
      );
      await _bannerAd?.load();
    } catch (_) {
      _mockMode = true;
    }
  }

  static Widget bannerWidget() {
    if (_mockMode || _bannerAd == null) {
      return Container(
        color: const Color(0xFF161B22),
        alignment: Alignment.center,
        child: const Text('Publicidad', style: TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
      );
    }
    return AdWidget(ad: _bannerAd!);
  }

  static Future<void> showInterstitial() async {
    if (_mockMode) return;
    _interstitialCounter++;
    if (_interstitialCounter % 3 != 0) return;

    final ad = InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => ad.show(),
        onAdFailedToLoad: (_) {},
      ),
    );
    await ad;
  }

  static Future<void> showRewardedAd({required Future<void> Function() onReward}) async {
    if (_mockMode) {
      await onReward();
      return;
    }

    await RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (_, __) => onReward());
        },
        onAdFailedToLoad: (_) async => await onReward(),
      ),
    );
  }
}
