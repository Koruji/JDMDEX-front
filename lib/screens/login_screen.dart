import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/events_service.dart';
import '../services/favorites_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Pseudo et mot de passe requis');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isRegister) {
        await AuthService.instance.register(username, _emailCtrl.text.trim(), password);
      } else {
        await AuthService.instance.login(username, password);
      }
      await Future.wait([
        FavoritesService.instance.load(),
        EventsService.instance.load(),
        UserService.instance.load(),
      ]);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'JDMDex',
                  style: TextStyle(fontFamily: 'GozaruDemo', color: kCream, fontSize: 52),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegister ? 'Créer un compte' : 'Connexion',
                  style: const TextStyle(color: kTextDim, fontSize: 14),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _usernameCtrl,
                  style: const TextStyle(color: kBg),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Pseudo'),
                ),
                if (_isRegister) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    style: const TextStyle(color: kBg),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  style: const TextStyle(color: kBg),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kRed.withOpacity(0.4)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: kText, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_isRegister ? 'Créer le compte' : 'Se connecter'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }),
                  child: Text(
                    _isRegister ? 'Déjà un compte ? Se connecter' : "Pas de compte ? S'inscrire",
                    style: const TextStyle(color: kTextDim, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
