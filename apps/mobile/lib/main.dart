import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/ads_service.dart';
import 'services/purchases_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    developer.log(
      details.exceptionAsString(),
      name: 'FlutterError',
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    developer.log('$error', name: 'PlatformError', stackTrace: stack);
    return true;
  };

  final prefs = await SharedPreferences.getInstance();

  // Never block first frame on ads/IAP — those SDKs can fail natively.
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const HappyGambaApp(),
  ));

  unawaited(_initOptionalSdks());
}

Future<void> _initOptionalSdks() async {
  try {
    await AdsService.initialize();
  } catch (e, st) {
    developer.log('Ads init failed: $e', name: 'AdsService', stackTrace: st);
  }
  try {
    await PurchasesService.initialize();
  } catch (e, st) {
    developer.log(
      'Purchases init failed: $e',
      name: 'PurchasesService',
      stackTrace: st,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});
