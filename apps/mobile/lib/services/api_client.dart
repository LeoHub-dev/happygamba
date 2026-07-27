import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../main.dart';
import '../models/user_profile.dart';

class ApiClient {
  ApiClient(this._prefs);

  final SharedPreferences _prefs;
  static const _tokenKey = 'auth_token';

  String? get token => _prefs.getString(_tokenKey);

  Future<void> setToken(String? token) async {
    if (token == null) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, token);
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(data['error']?.toString() ?? 'Request failed');
    }
    return data;
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    if (res.statusCode >= 400) {
      final map = data is Map ? data as Map<String, dynamic> : <String, dynamic>{};
      throw ApiException(map['error']?.toString() ?? 'Request failed');
    }
    return data as Map<String, dynamic>;
  }

  Future<AuthResult> register(String username, String password) async {
    final data = await _post('/auth/register', {'username': username, 'password': password});
    await setToken(data['token'] as String);
    return AuthResult.fromJson(data);
  }

  Future<AuthResult> login(String username, String password) async {
    final data = await _post('/auth/login', {'username': username, 'password': password});
    await setToken(data['token'] as String);
    return AuthResult.fromJson(data);
  }

  Future<AuthResult> syncSocial({
    required String firebaseUid,
    required String displayName,
    required String provider,
    String? avatarUrl,
  }) async {
    final data = await _post('/auth/sync', {
      'firebaseUid': firebaseUid,
      'displayName': displayName,
      'provider': provider,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    await setToken(data['token'] as String);
    return AuthResult.fromJson(data);
  }

  Future<UserProfile> getProfile() async {
    final data = await _get('/user/profile');
    return UserProfile.fromJson(data);
  }

  Future<SlotsResult> spinSlots(int bet) async {
    final data = await _post('/games/slots/spin', {'bet': bet});
    return SlotsResult.fromJson(data);
  }

  Future<BlackjackStart> startBlackjack(int bet) async {
    final data = await _post('/games/blackjack/start', {'bet': bet});
    return BlackjackStart.fromJson(data);
  }

  Future<BlackjackActionResult> blackjackAction(String sessionId, String action) async {
    final data = await _post('/games/blackjack/action', {
      'sessionId': sessionId,
      'action': action,
    });
    return BlackjackActionResult.fromJson(data);
  }

  Future<DailyBonusResult> claimDailyBonus({bool rewarded = false}) async {
    final data = await _post('/economy/daily-bonus', {'rewarded': rewarded});
    return DailyBonusResult.fromJson(data);
  }

  Future<List<LiveBet>> getLiveBets() async {
    final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/feed/live-bets'));
    final list = jsonDecode(res.body) as List;
    return list.map((e) => LiveBet.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> logout() => setToken(null);
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(sharedPreferencesProvider));
});

class AuthResult {
  AuthResult({required this.token, required this.user});
  final String token;
  final Map<String, dynamic> user;
  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        token: json['token'] as String,
        user: json['user'] as Map<String, dynamic>,
      );
}

class SlotsResult {
  SlotsResult({
    required this.bet,
    required this.cascades,
    required this.totalPayout,
    required this.balance,
    required this.tier,
  });
  final int bet;
  final List<CascadeStep> cascades;
  final int totalPayout;
  final int balance;
  final String tier;

  factory SlotsResult.fromJson(Map<String, dynamic> json) => SlotsResult(
        bet: json['bet'] as int,
        cascades: (json['cascades'] as List)
            .map((e) => CascadeStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalPayout: json['totalPayout'] as int,
        balance: json['balance'] as int,
        tier: json['tier'] as String,
      );
}

class CascadeStep {
  CascadeStep({required this.grid, required this.wins, this.removed = const []});
  final List<List<String>> grid;
  final List<WinCell> wins;
  final List<(int, int)> removed;

  factory CascadeStep.fromJson(Map<String, dynamic> json) => CascadeStep(
        grid: (json['grid'] as List)
            .map((row) => (row as List).map((c) => c.toString()).toList())
            .toList(),
        wins: (json['wins'] as List? ?? [])
            .map((e) => WinCell.fromJson(e as Map<String, dynamic>))
            .toList(),
        removed: (json['removed'] as List? ?? [])
            .map((e) {
              final pair = e as List;
              return ((pair[0] as num).toInt(), (pair[1] as num).toInt());
            })
            .toList(),
      );

  Set<(int, int)> get winningCells {
    final cells = <(int, int)>{};
    for (final win in wins) {
      cells.addAll(win.cells);
    }
    if (cells.isEmpty) cells.addAll(removed);
    return cells;
  }
}

class WinCell {
  WinCell({
    required this.payout,
    required this.mult,
    this.cells = const [],
    this.symbol,
  });
  final int payout;
  final double mult;
  final List<(int, int)> cells;
  final String? symbol;
  factory WinCell.fromJson(Map<String, dynamic> json) => WinCell(
        payout: (json['payout'] as num).toInt(),
        mult: (json['mult'] as num).toDouble(),
        cells: (json['cells'] as List? ?? [])
            .map((e) {
              final pair = e as List;
              return ((pair[0] as num).toInt(), (pair[1] as num).toInt());
            })
            .toList(),
        symbol: json['symbol'] as String?,
      );
}

class BlackjackStart {
  BlackjackStart({
    required this.sessionId,
    required this.bet,
    required this.playerCards,
    required this.dealerCards,
    required this.playerTotal,
    required this.canHit,
  });
  final String sessionId;
  final int bet;
  final List<Map<String, String>> playerCards;
  final List<Map<String, String>> dealerCards;
  final int playerTotal;
  final bool canHit;

  factory BlackjackStart.fromJson(Map<String, dynamic> json) => BlackjackStart(
        sessionId: json['sessionId'] as String,
        bet: json['bet'] as int,
        playerCards: (json['playerCards'] as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        dealerCards: (json['dealerCards'] as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        playerTotal: json['playerTotal'] as int,
        canHit: json['canHit'] as bool,
      );
}

class BlackjackActionResult {
  BlackjackActionResult({
    required this.sessionId,
    required this.playerCards,
    required this.dealerCards,
    required this.playerTotal,
    required this.dealerTotal,
    required this.status,
    this.outcome,
    this.payout,
    this.balance,
    this.canHit = false,
    this.dealerHidden = false,
  });
  final String sessionId;
  final List<Map<String, String>> playerCards;
  final List<Map<String, String>> dealerCards;
  final int playerTotal;
  final int? dealerTotal;
  final String status;
  final String? outcome;
  final int? payout;
  final int? balance;
  final bool canHit;
  final bool dealerHidden;

  factory BlackjackActionResult.fromJson(Map<String, dynamic> json) => BlackjackActionResult(
        sessionId: json['sessionId'] as String,
        playerCards: (json['playerCards'] as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        dealerCards: (json['dealerCards'] as List)
            .map((e) => Map<String, String>.from(e as Map))
            .toList(),
        playerTotal: json['playerTotal'] as int,
        dealerTotal: json['dealerTotal'] as int?,
        status: json['status'] as String,
        outcome: json['outcome'] as String?,
        payout: json['payout'] as int?,
        balance: json['balance'] as int?,
        canHit: json['canHit'] as bool? ?? false,
        dealerHidden: json['dealerHidden'] as bool? ?? false,
      );
}

class DailyBonusResult {
  DailyBonusResult({required this.bonus, required this.balance});
  final int bonus;
  final int balance;
  factory DailyBonusResult.fromJson(Map<String, dynamic> json) => DailyBonusResult(
        bonus: json['bonus'] as int,
        balance: json['balance'] as int,
      );
}

class LiveBet {
  LiveBet({
    required this.username,
    required this.bet,
    required this.multiplier,
    required this.payout,
    required this.game,
  });
  final String username;
  final int bet;
  final String multiplier;
  final int payout;
  final String game;

  factory LiveBet.fromJson(Map<String, dynamic> json) => LiveBet(
        username: json['username'] as String,
        bet: json['bet'] as int,
        multiplier: json['multiplier'].toString(),
        payout: json['payout'] as int,
        game: json['game'] as String,
      );
}
