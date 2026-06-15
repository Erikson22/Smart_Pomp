import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _loading = false;
  bool _remember = false;
  String? _error;

  Future<void> _connexion() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(), password: _passCtrl.text);
      if (mounted) context.go('/dashboard');
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Erreur de connexion');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Container(color: const Color(0xFF1A2F1A)),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x881A2F1A), Color(0xDD000000)],
            ),
          ),
        ),
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(children: [
            const SizedBox(height: 60),
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.water_drop, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text('Smart Pump\nMonitoring',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.3)),
            const SizedBox(height: 8),
            Text('Surveillance et controle intelligent\ndes pompes solaires',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
            const SizedBox(height: 48),
            _ChampTexte(controller: _emailCtrl, hint: 'Adresse e-mail', icon: Icons.person_outline, clavier: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _ChampTexte(controller: _passCtrl, hint: 'Mot de passe', icon: Icons.lock_outline, secret: true),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v!),
                fillColor: WidgetStateProperty.resolveWith((s) =>
                  s.contains(WidgetState.selected) ? const Color(0xFF1D9E75) : Colors.white54),
              ),
              const Text('Se souvenir de moi', style: TextStyle(color: Colors.white)),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _connexion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D9E75),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SE CONNECTER', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                final email = _emailCtrl.text.trim();
                if (email.isEmpty) return;
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('E-mail de reinitialisation envoye')));
              },
              child: Text('Mot de passe oublie ?', style: TextStyle(color: Colors.white.withOpacity(0.8))),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fonctionnalite bientot disponible'))); },
              child: const Text('Creer un compte', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/dashboard'),
          child: const Text('Acces Demo (sans connexion)', style: TextStyle(color: Color(0xFF1D9E75), fontWeight: FontWeight.bold, fontSize: 15)),
        ),
            const SizedBox(height: 30),
          ]),
        )),
      ]),
    );
  }
}

class _ChampTexte extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool secret;
  final TextInputType clavier;
  const _ChampTexte({required this.controller, required this.hint, required this.icon, this.secret = false, this.clavier = TextInputType.text});
  @override
  State<_ChampTexte> createState() => _ChampTexteState();
}

class _ChampTexteState extends State<_ChampTexte> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.secret && !_visible,
      keyboardType: widget.clavier,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(widget.icon, color: Colors.white70),
        suffixIcon: widget.secret ? IconButton(
          icon: Icon(_visible ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
          onPressed: () => setState(() => _visible = !_visible),
        ) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D9E75), width: 2)),
      ),
    );
  }
}


