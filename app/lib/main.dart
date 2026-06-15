import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'services/pompe_service.dart';
import 'utils/notifications.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppLoader());
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});
  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _pret = false;
  String _erreur = '';

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      await initNotifications();
      setState(() => _pret = true);
    } catch (e) {
      setState(() => _erreur = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_erreur.isNotEmpty) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF1A2F1A),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text('Erreur Firebase',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_erreur,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _erreur = '';
                      _initialiser();
                    }),
                    child: const Text('Reessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_pret) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF1A2F1A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.water_drop, color: Color(0xFF1D9E75), size: 60),
                SizedBox(height: 24),
                Text('Smart Pump',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                CircularProgressIndicator(color: Color(0xFF1D9E75)),
                SizedBox(height: 16),
                Text('Connexion Firebase...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PompeService())],
      child: MaterialApp.router(
        title: 'Smart Pump',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1D9E75),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF3F7F4),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Color(0xFFF3F7F4),
            foregroundColor: Color(0xFF17231F),
            titleTextStyle: TextStyle(
              color: Color(0xFF17231F),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: Color(0xFFE5ECE8)),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDDE7E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDDE7E1)),
            ),
          ),
        ),
        builder: (context, child) => OrientationGate(
          child: child ?? const SizedBox.shrink(),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}

class OrientationGate extends StatefulWidget {
  final Widget child;

  const OrientationGate({super.key, required this.child});

  @override
  State<OrientationGate> createState() => _OrientationGateState();
}

class _OrientationGateState extends State<OrientationGate> {
  bool? _lockedPortrait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyOrientationPolicy();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _applyOrientationPolicy() {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final shouldLockPortrait = shortestSide < 600;

    if (_lockedPortrait == shouldLockPortrait) return;
    _lockedPortrait = shouldLockPortrait;

    if (shouldLockPortrait) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }
}
