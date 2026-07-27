class UserProfile {
  UserProfile({
    required this.id,
    required this.username,
    required this.balance,
    required this.phase,
    required this.isVip,
    required this.isAdFree,
    required this.authProvider,
  });

  final String id;
  final String username;
  final int balance;
  final String phase;
  final bool isVip;
  final bool isAdFree;
  final String authProvider;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        balance: json['balance'] as int,
        phase: json['phase'] as String,
        isVip: (json['is_vip'] as int? ?? 0) == 1,
        isAdFree: (json['is_ad_free'] as int? ?? 0) == 1,
        authProvider: json['auth_provider'] as String? ?? 'password',
      );

  UserProfile copyWith({int? balance}) => UserProfile(
        id: id,
        username: username,
        balance: balance ?? this.balance,
        phase: phase,
        isVip: isVip,
        isAdFree: isAdFree,
        authProvider: authProvider,
      );
}
