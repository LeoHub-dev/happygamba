import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob integration with safe fallbacks.
///
/// Requires `com.google.android.gms.ads.APPLICATION_ID` in AndroidManifest and
/// `GADApplicationIdentifier` in iOS Info.plist — otherwise the process can
/// native-crash before any Dart logs appear.
class AdsService {
  static bool _mockMode = true;
  static BannerAd? _bannerAd;
  static int _interstitialCounter = 0;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Skip native SDK on web / when explicitly disabled.
    if (kIsWeb) {
      _mockMode = true;
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _mockMode = false;
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111',
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (ad, error) {
            developer.log('Banner failed: $error', name: 'AdsService');
            ad.dispose();
            _bannerAd = null;
            _mockMode = true;
          },
        ),
      );
      await _bannerAd?.load();
    } catch (e, st) {
      developer.log('Ads initialize error: $e', name: 'AdsService', stackTrace: st);
      _mockMode = true;
      _bannerAd = null;
    }
  }

  static Widget bannerWidget() {
    if (_mockMode || _bannerAd == null) {
      return Container(
        color: const Color(0xFF161B22),
        alignment: Alignment.center,
        child: const Text(
          'Publicidad',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
        ),
      );
    }
    return AdWidget(ad: _bannerAd!);
  }

  static Future<void> showInterstitial() async {
    if (_mockMode) return;
    _interstitialCounter++;
    if (_interstitialCounter % 3 != 0) return;

    await InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => ad.show(),
        onAdFailedToLoad: (error) {
          developer.log('Interstitial failed: $error', name: 'AdsService');
        },
      ),
    );
  }

  static Future<void> showRewardedAd({
    required Future<void> Function() onReward,
  }) async {
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
