import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/dashboard.dart';
import 'screens/commandes.dart';
import 'screens/graphiques.dart';
import 'screens/alarmes.dart';
import 'screens/parametres.dart';
import 'screens/localisation.dart';
import 'screens/ia_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/commandes',    builder: (_, __) => const CommandesScreen()),
        GoRoute(path: '/graphiques',   builder: (_, __) => const GraphiquesScreen()),
        GoRoute(path: '/alarmes',      builder: (_, __) => const AlarmesScreen()),
        GoRoute(path: '/localisation', builder: (_, __) => const LocalisationScreen()),
        GoRoute(path: '/parametres',   builder: (_, __) => const ParametresScreen()),
        GoRoute(path: '/ia',           builder: (_, __) => const IAScreen()),
      ],
    ),
  ],
);

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    '/dashboard',
    '/commandes',
    '/graphiques',
    '/localisation',
    '/ia',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index    = _tabs.indexWhere((t) => location.startsWith(t));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        height: 68,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE1F3EC),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil'),
          NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Cmd'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Graphiques'),
          NavigationDestination(
              icon: Icon(Icons.location_on_outlined),
              selectedIcon: Icon(Icons.location_on),
              label: 'GPS'),
          NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(Icons.psychology),
              label: 'IA'),
        ],
      ),
    );
  }
}
