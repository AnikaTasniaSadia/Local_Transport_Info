import 'package:flutter/material.dart';

import '../data/models/stop.dart';
import '../profile/profile_screen.dart';
import '../services/app_config.dart';
import '../services/supabase_service.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_screen.dart';
import 'home/home_tab.dart';
import 'home/result_screen.dart';
import 'map/map_tab.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key, this.startupWarning});

  final String? startupWarning;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _isEnglish = true;
  int _bottomNavIndex = 0;

  final SupabaseService _service = SupabaseService();

  bool _checkingAdmin = false;

  List<Stop> _stops = const [];
  bool _isLoadingStops = false;
  String? _stopsLoadError;

  String? _fromStopId;
  String? _toStopId;

  @override
  void initState() {
    super.initState();

    final warning = widget.startupWarning;
    if (warning != null && warning.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(warning),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      });
    }

    _loadStops();
  }

  void _toggleLanguage() {
    setState(() => _isEnglish = !_isEnglish);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Language: ${_isEnglish ? 'English' : 'Bangla'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadStops() async {
    if (_isLoadingStops) return;

    setState(() {
      _isLoadingStops = true;
      _stopsLoadError = null;
    });

    try {
      final stops = await _service.fetchStops();
      if (!mounted) return;
      setState(() {
        _stops = stops;
        if (_fromStopId != null &&
            !_stops.any((s) => s.stopId == _fromStopId)) {
          _fromStopId = null;
        }
        if (_toStopId != null && !_stops.any((s) => s.stopId == _toStopId)) {
          _toStopId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stopsLoadError = e.toString();
        _stops = const [];
      });
    } finally {
      if (mounted) setState(() => _isLoadingStops = false);
    }
  }

  String _normalizeName(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _findStopIdByName(String query) {
    if (_stops.isEmpty) return null;

    final q = _normalizeName(query);

    for (final stop in _stops) {
      final en = _normalizeName(stop.nameEn);
      final bn = _normalizeName(stop.nameBn);
      if (en.isNotEmpty && en == q) return stop.stopId;
      if (bn.isNotEmpty && bn == q) return stop.stopId;
    }

    for (final stop in _stops) {
      final en = _normalizeName(stop.nameEn);
      final bn = _normalizeName(stop.nameBn);
      if (en.isNotEmpty && (en.contains(q) || q.contains(en))) {
        return stop.stopId;
      }
      if (bn.isNotEmpty && (bn.contains(q) || q.contains(bn))) {
        return stop.stopId;
      }
    }

    return null;
  }

  void _applyPopularRoute({required String fromEn, required String toEn}) {
    if (_isLoadingStops) return;
    if (_stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stops are not loaded yet. Tap reload and try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadStops();
      return;
    }

    final fromId = _findStopIdByName(fromEn);
    final toId = _findStopIdByName(toEn);

    if (fromId == null || toId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Popular route stops not found in the stop list.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _fromStopId = fromId;
      _toStopId = toId;
    });
  }

  void _searchRoute() {
    final fromStopId = _fromStopId;
    final toStopId = _toStopId;

    if (fromStopId == null || toStopId == null) return;
    if (fromStopId == toStopId) return;

    final fromStop = _stops.firstWhere((s) => s.stopId == fromStopId);
    final toStop = _stops.firstWhere((s) => s.stopId == toStopId);

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          service: _service,
          fromStopId: fromStopId,
          toStopId: toStopId,
          fromStopName: fromStop.displayName(isEnglish: _isEnglish),
          toStopName: toStop.displayName(isEnglish: _isEnglish),
        ),
      ),
    );
  }

  Future<void> _openAdmin() async {
    if (_checkingAdmin) return;

    if (AppConfig.isAdmin) {
      _pushAdmin();
      return;
    }

    if (!_service.isSignedIn) {
      final didLogin = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => AdminLoginScreen(service: _service)),
      );

      if (!mounted) return;
      if (didLogin == true) {
        await _openAdmin();
      }
      return;
    }

    setState(() => _checkingAdmin = true);
    try {
      final isAdmin = await _service.isCurrentUserAdmin();
      if (!mounted) return;
      if (isAdmin) {
        _pushAdmin();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are not registered as an admin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Admin check failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingAdmin = false);
    }
  }

  void _pushAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminScreen(
          service: _service,
          stops: _stops,
          isEnglish: _isEnglish,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> destinations = [
      HomeTab(
        isEnglish: _isEnglish,
        isLoadingStops: _isLoadingStops,
        stops: _stops,
        stopsLoadError: _stopsLoadError,
        fromStopId: _fromStopId,
        toStopId: _toStopId,
        onReloadStops: _loadStops,
        onFromChanged: (v) => setState(() => _fromStopId = v),
        onToChanged: (v) => setState(() => _toStopId = v),
        onSearch: _searchRoute,
        onApplyPopularRoute: _applyPopularRoute,
      ),
      MapTab(
        stops: _stops,
        isEnglish: _isEnglish,
        fromStopId: _fromStopId,
        toStopId: _toStopId,
      ),
      const _PlaceholderTab(
        title: 'History',
        subtitle: 'Search history coming soon.',
        icon: Icons.history,
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Transport Info'),
        actions: [
          IconButton(
            tooltip: 'Admin',
            onPressed: _checkingAdmin ? null : _openAdmin,
            icon: _checkingAdmin
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.admin_panel_settings_outlined),
          ),
          IconButton(
            tooltip: _isEnglish ? 'Switch to Bangla' : 'Switch to English',
            onPressed: _toggleLanguage,
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      body: destinations[_bottomNavIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomNavIndex,
        onDestinationSelected: (index) =>
            setState(() => _bottomNavIndex = index),
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

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(icon, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
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
