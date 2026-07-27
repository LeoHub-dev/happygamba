import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/api_client.dart';

class LiveBetsFeed extends ConsumerWidget {
  const LiveBetsFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(apiClientProvider).getLiveBets(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bets = snapshot.data!;
        final formatter = NumberFormat('#,###', 'es');
        return Column(
          children: bets.map((b) {
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF161B22),
                child: Text(b.username[0], style: const TextStyle(fontSize: 12)),
              ),
              title: Text(b.username),
              subtitle: Text('${b.game} · ${formatter.format(b.bet)}'),
              trailing: Text(
                '${b.multiplier}x · ${formatter.format(b.payout)}',
                style: const TextStyle(color: Color(0xFF00E676)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
