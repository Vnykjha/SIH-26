import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/intake_screen.dart';
import 'screens/screening_history_screen.dart';
import 'services/database_service.dart';

void main() {
  runApp(const CrepisenseApp());
}

class CrepisenseApp extends StatefulWidget {
  const CrepisenseApp({super.key});

  @override
  State<CrepisenseApp> createState() => _CrepisenseAppState();
}

class _CrepisenseAppState extends State<CrepisenseApp> {
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1D7D8D);
    const softBg = Color(0xFFEFF4F5);

    return MaterialApp(
      title: 'CREPISENSE',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
        useMaterial3: true,
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: softBg,
        appBarTheme: const AppBarTheme(
          backgroundColor: softBg,
          foregroundColor: Color(0xFF203846),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF203846),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      home: HomeScreen(
        locale: _locale,
        onLocaleChanged: (locale) => setState(() => _locale = locale),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1D7D8D);
    const deepTeal = Color(0xFF0D4C5C);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [teal, deepTeal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.accessibility_new_rounded,
                    size: 68, color: teal),
              ),
              const SizedBox(height: 28),
              const Text(
                'CREPISENSE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Offline OA Risk Screening',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 42),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Preparing your screening workspace...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.locale = const Locale('en'),
    this.onLocaleChanged,
  });

  final Locale locale;
  final ValueChanged<Locale>? onLocaleChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _screenedToday = 0;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final screenings = await DatabaseService.instance.getAllScreenings();
      final now = DateTime.now();
      final screenedToday = screenings.where((screening) {
        final created = screening.createdAt.toLocal();
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      }).length;
      if (mounted) {
        setState(() {
          _screenedToday = screenedToday;
          _savedCount = screenings.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1D7D8D);
    const tealDark = Color(0xFF0D4C5C);
    const softBg = Color(0xFFEFF4F5);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.tr('appTitle'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: teal,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  PopupMenuButton<Locale>(
                    tooltip: loc.tr('selectLanguage'),
                    onSelected: widget.onLocaleChanged,
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: Locale('en'), child: Text('English')),
                      PopupMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                      PopupMenuItem(value: Locale('bn'), child: Text('বাংলা')),
                      PopupMenuItem(
                          value: Locale('as'), child: Text('অসমীয়া')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: teal.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.language, size: 16, color: teal),
                          const SizedBox(width: 6),
                          Text(
                            widget.locale.languageCode.toUpperCase(),
                            style: const TextStyle(
                                color: teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [teal, tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'STANDARD SCREENING — TIER 1',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      loc.tr('homeHeadline'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      loc.tr('homeSubtitle'),
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _stepChip('1', 'Intake'),
                        _stepDivider(),
                        _stepChip('2', 'WOMAC'),
                        _stepDivider(),
                        _stepChip('3', 'Mobility'),
                        _stepDivider(),
                        _stepChip('4', 'Report'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IntakeScreen(
                          onLocaleChanged: widget.onLocaleChanged,
                        ),
                      ),
                    ).then((_) => _loadStats());
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 22),
                  label: Text(
                    loc.tr('startScreening'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScreeningHistoryScreen()),
                    ).then((_) => _loadStats());
                  },
                  icon: const Icon(Icons.folder_open_rounded, size: 22),
                  label: Text(
                    loc.tr('savedScreenings'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: teal,
                    side: const BorderSide(color: teal, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: const Text(
                    'WORKSPACE STATUS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF72848A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                      child: _statCard('Screened Today', '$_screenedToday',
                          const Color(0xFF4A5B62))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard('Saved Offline', '$_savedCount',
                          const Color(0xFF2C8A80))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _statCard(
                          'Pending Sync', '0', const Color(0xFFC56E3B))),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepChip(String number, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _stepDivider() {
    return Container(
      width: 16,
      height: 1,
      margin: const EdgeInsets.only(bottom: 20),
      color: Colors.white.withOpacity(0.35),
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9E2E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667880),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
