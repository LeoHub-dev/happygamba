import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isRegister) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authProvider.notifier);
      if (isRegister) {
        await auth.register(_usernameController.text.trim(), _passwordController.text);
      } else {
        await auth.login(_usernameController.text.trim(), _passwordController.text);
      }
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _social(String provider) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).socialLogin(provider);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'HappyGamba',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Casino de entretenimiento — moneda ficticia',
                style: TextStyle(color: Color(0xFF8B949E)),
              ),
              const SizedBox(height: 32),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF00E676),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF8B949E),
                tabs: const [Tab(text: 'Entrar'), Tab(text: 'Registrarse')],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Usuario'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                onSubmitted: (_) => _submit(_tabController.index == 1),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : () => _submit(_tabController.index == 1),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_tabController.index == 1 ? 'Crear cuenta' : 'Entrar'),
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF8B949E))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o continúa con', style: TextStyle(color: Color(0xFF8B949E))),
                  ),
                  Expanded(child: Divider(color: Color(0xFF8B949E))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _social('google'),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text('Google'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _social('apple'),
                      icon: const Icon(Icons.apple),
                      label: const Text('Apple'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Solo entretenimiento. Sin dinero real.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
