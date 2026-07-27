import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/blackjack/blackjack_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/slots/slots_screen.dart';
import '../features/vip/vip_screen.dart';
import '../providers/auth_provider.dart';

/// Notifier so GoRouter refreshes redirects without being recreated.
/// Recreating the router (via ref.watch) resets navigation — e.g. leaving /slots
/// every time the balance updates.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.onDispose(refresh.dispose);

  ref.listen(authProvider, (_, __) => refresh.ping());

  return GoRouter(
    initialLocation: '/auth',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      // Stay put while session bootstrap / login is in flight.
      if (authState.isLoading) return null;

      final isAuth = authState.valueOrNull != null;
      final onAuth = state.matchedLocation == '/auth';
      if (!isAuth && !onAuth) return '/auth';
      if (isAuth && onAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/slots', builder: (_, __) => const SlotsScreen()),
      GoRoute(path: '/blackjack', builder: (_, __) => const BlackjackScreen()),
      GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
      GoRoute(path: '/vip', builder: (_, __) => const VipScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
