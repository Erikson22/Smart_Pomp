import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// On supprime l'import de firebase_auth car on ne l'utilise plus
// import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/graphiques_screen.dart';
import 'screens/commandes_screen.dart';
import 'screens/alarmes_screen.dart';
import 'screens/parametres_screen.dart';

final appRouter = GoRouter(
  // Démarre directement sur l'écran Commandes (ou autre)
  initialLocation: '/commandes',

  // Plus de redirection ni d'authentification
  routes: [
    // La route /login est supprimée (plus affichée)
    // On garde uniquement la ShellRoute avec les 5 onglets
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/graphiques', builder: (_, __) => const GraphiquesScreen()),
        GoRoute(path: '/commandes',  builder: (_, __) => const CommandesScreen()),
        GoRoute(path: '/alarmes',    builder: (_, __) => const AlarmesScreen()),
        GoRoute(path: '/parametres', builder: (_, __) => const ParametresScreen()),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  // L'ordre des onglets : Dashboard (index 0), Graphiques (1), Commandes (2), ...
  static const _tabs = ['/dashboard', '/graphiques', '/commandes', '/alarmes', '/parametres'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int index = _tabs.indexWhere((t) => location.startsWith(t));
    if (index < 0) index = 0; // sécurité

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),         selectedIcon: Icon(Icons.home),         label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined),    selectedIcon: Icon(Icons.bar_chart),    label: 'Graphiques'),
          NavigationDestination(icon: Icon(Icons.tune_outlined),         selectedIcon: Icon(Icons.tune),         label: 'Commandes'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined),selectedIcon: Icon(Icons.notifications),label: 'Alarmes'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),     selectedIcon: Icon(Icons.settings),     label: 'Parametres'),
        ],
      ),
    );
  }
}