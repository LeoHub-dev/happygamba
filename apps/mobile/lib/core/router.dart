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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth',
    redirect: (context, state) {
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
