import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  // Ad Unit IDs from .env
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ANDROID_BANNER_AD_UNIT_ID'] ??
          dotenv.env['banner_ad'] ?? // Fallback to user's key
          'ca-app-pub-3940256099942544/6300978111'; // Fallback to Test ID
    } else if (Platform.isIOS) {
      return dotenv.env['IOS_BANNER_AD_UNIT_ID'] ??
          'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError("Unsupported platform");
  }

  String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ANDROID_NATIVE_AD_UNIT_ID'] ??
          dotenv.env['native_ad'] ??
          'ca-app-pub-3940256099942544/2247696110';
    } else if (Platform.isIOS) {
      return dotenv.env['IOS_NATIVE_AD_UNIT_ID'] ??
          'ca-app-pub-3940256099942544/3986624511';
    }
    throw UnsupportedError("Unsupported platform");
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ANDROID_INTERSTITIAL_AD_UNIT_ID'] ??
          dotenv.env['interstitial_ad'] ??
          'ca-app-pub-7846790707867237/4224112545'; // Production ID
    } else if (Platform.isIOS) {
      return dotenv.env['IOS_INTERSTITIAL_AD_UNIT_ID'] ??
          'ca-app-pub-3940256099942544/4411468910'; // Test ID for iOS
    }
    throw UnsupportedError("Unsupported platform");
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  BannerAd loadBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
    )..load();
  }

  NativeAd loadNativeAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId:
          'listTile', // Ensure this matches android/app/src/main/kotlin/.../MainActivity.kt setup if using platform views, or use Template
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad(ad, error);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        // Simple default style
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xfffffbed),
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF2E7D32),
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black54,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
      ),
    )..load();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (kDebugMode) {
            print('$ad loaded');
          }
          _interstitialAd = ad;
          _numInterstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          if (kDebugMode) {
            print('InterstitialAd failed to load: $error');
          }
          _interstitialAd = null;
          _numInterstitialLoadAttempts += 1;
          if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
            loadInterstitialAd();
          }
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (_interstitialAd == null) {
      if (kDebugMode) {
        print('Warning: attempt to show interstitial ad before loaded.');
      }
      loadInterstitialAd();
      onAdDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        if (kDebugMode) {
          print('$ad onAdShowedFullScreenContent.');
        }
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        if (kDebugMode) {
          print('$ad onAdDismissedFullScreenContent.');
        }
        ad.dispose();
        loadInterstitialAd();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        if (kDebugMode) {
          print('$ad onAdFailedToShowFullScreenContent: $error');
        }
        ad.dispose();
        loadInterstitialAd();
        onAdDismissed?.call();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
