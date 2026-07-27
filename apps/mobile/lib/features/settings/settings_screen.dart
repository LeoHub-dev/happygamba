import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          if (profile != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(profile.username),
              subtitle: Text('Proveedor: ${profile.authProvider}'),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Aviso legal'),
            subtitle: const Text(
              'HappyGamba es una app de entretenimiento con moneda ficticia. '
              'No se puede retirar dinero real. No es apuestas con dinero real. '
              'Solo para mayores de 18 años.',
            ),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('Tienda'),
            onTap: () => context.push('/shop'),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restaurar compras'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar sesión'),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth');
            },
          ),
        ],
      ),
    );
  }
}
