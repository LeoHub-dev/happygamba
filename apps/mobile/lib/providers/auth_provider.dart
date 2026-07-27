import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/api_client.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthNotifier(this._api) : super(const AsyncValue.loading()) {
    _init();
  }

  final ApiClient _api;

  Future<void> _init() async {
    if (_api.token == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final profile = await _api.getProfile();
      state = AsyncValue.data(profile);
    } catch (_) {
      await _api.logout();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> register(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _api.register(username, password);
      final profile = await _api.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _api.login(username, password);
      final profile = await _api.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> socialLogin(String provider) async {
    state = const AsyncValue.loading();
    try {
      final uid = 'demo_${provider}_${DateTime.now().millisecondsSinceEpoch}';
      await _api.syncSocial(
        firebaseUid: uid,
        displayName: '${provider}_player',
        provider: provider,
      );
      final profile = await _api.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    final profile = await _api.getProfile();
    state = AsyncValue.data(profile);
  }

  void updateBalance(int balance) {
    state.whenData((p) {
      if (p != null) state = AsyncValue.data(p.copyWith(balance: balance));
    });
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserProfile?>>((ref) {
  return AuthNotifier(ref.watch(apiClientProvider));
});
