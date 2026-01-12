import 'package:flutter/material.dart';

void main() {
  runApp(const LocalTransportInfoApp());
}

class LocalTransportInfoApp extends StatelessWidget {
  const LocalTransportInfoApp({super.key});

  static const Color _seedColor = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Transport Info',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        scaffoldBackgroundColor: Colors.white,
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEnglish = true;
  int _bottomNavIndex = 0;

  final List<String> _stops = const [
    'Mirpur',
    'Farmgate',
    'Gulistan',
    'Jatrabari',
    'Uttara',
    'Motijheel',
  ];

  String? _fromStop;
  String? _toStop;

  bool get _canSearch =>
      _fromStop != null && _toStop != null && _fromStop != _toStop;

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language: ${_isEnglish ? 'English' : 'Bangla'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyPopularRoute({required String from, required String to}) {
    setState(() {
      _fromStop = from;
      _toStop = to;
    });
  }

  void _searchRoute() {
    if (!_canSearch) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(fromStop: _fromStop!, toStop: _toStop!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Transport Info'),
        actions: [
          IconButton(
            tooltip: _isEnglish ? 'Switch to Bangla' : 'Switch to English',
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Your Bus Fare',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Government approved bus fare & routes',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            value: _fromStop,
                            items: _stops
                                .map(
                                  (stop) => DropdownMenuItem<String>(
                                    value: stop,
                                    child: Text(stop),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _fromStop = value);
                            },
                            decoration: const InputDecoration(
                              labelText: 'From Stop',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _toStop,
                            items: _stops
                                .map(
                                  (stop) => DropdownMenuItem<String>(
                                    value: stop,
                                    child: Text(stop),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _toStop = value);
                            },
                            decoration: const InputDecoration(
                              labelText: 'To Stop',
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _canSearch ? _searchRoute : null,
                            child: const Text('Search Route'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Popular Routes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ActionChip(
                        label: const Text('Mirpur → Farmgate'),
                        onPressed: () =>
                            _applyPopularRoute(from: 'Mirpur', to: 'Farmgate'),
                      ),
                      ActionChip(
                        label: const Text('Gulistan → Jatrabari'),
                        onPressed: () => _applyPopularRoute(
                          from: 'Gulistan',
                          to: 'Jatrabari',
                        ),
                      ),
                      ActionChip(
                        label: const Text('Uttara → Motijheel'),
                        onPressed: () =>
                            _applyPopularRoute(from: 'Uttara', to: 'Motijheel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (index) {
          setState(() => _bottomNavIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.fromStop, required this.toStop});

  final String fromStop;
  final String toStop;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Route Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$fromStop → $toStop',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Results will appear here (Firestore integration later).',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
