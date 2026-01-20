import 'package:flutter/material.dart';

import '../data/models/stop.dart';
import '../data/models/fare_quote.dart';
import '../data/models/search_history.dart';
import '../profile/profile_screen.dart';
import '../services/app_config.dart';
import '../services/supabase_service.dart';
import 'admin/admin_login_screen.dart';
import 'admin/admin_screen.dart';
import 'auth/user_auth_screen.dart';
import 'history/history_screen.dart';
import 'home/home_tab.dart';
import 'map/map_screen.dart';

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

  bool _isLoadingFare = false;
  String? _fareError;
  FareQuote? _fareQuote;
  bool _hasSearched = false;

  List<SearchHistoryEntry> _history = const [];
  List<SearchHistoryEntry> _localHistory = const [];
  bool _isLoadingHistory = false;
  String? _historyError;

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

  void _applyPopularRoute({required String fromId, required String toId}) {
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

    setState(() {
      _fromStopId = fromId;
      _toStopId = toId;
      _fareQuote = null;
      _fareError = null;
      _hasSearched = false;
    });
  }

  Future<void> _searchRoute() async {
    final fromStopId = _fromStopId;
    final toStopId = _toStopId;

    if (fromStopId == null || toStopId == null) return;
    if (fromStopId == toStopId) return;

    setState(() {
      _isLoadingFare = true;
      _fareError = null;
      _fareQuote = null;
      _hasSearched = true;
    });

    try {
      final quote = await _service.fetchFareQuote(
        fromStopId: fromStopId,
        toStopId: toStopId,
      );

      await _logHistory(
        fromStopId: fromStopId,
        toStopId: toStopId,
        fare: quote?.fare,
        routeNo: quote?.routeNo,
      );

      if (!mounted) return;
      setState(() {
        _fareQuote = quote;
        _isLoadingFare = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fareError = e.toString();
        _isLoadingFare = false;
      });
    }
  }

  Future<void> _logHistory({
    required String fromStopId,
    required String toStopId,
    required double? fare,
    required String? routeNo,
  }) async {
    final entry = SearchHistoryEntry(
      fromStopId: fromStopId,
      toStopId: toStopId,
      fare: fare,
      routeNo: routeNo,
      searchedAt: DateTime.now(),
    );

    setState(() {
      _localHistory = [entry, ..._localHistory];
    });

    if (_service.isSignedIn) {
      try {
        await _service.logSearchHistory(entry);
        if (!mounted) return;
        await _loadHistory();
      } catch (e) {
        if (!mounted) return;
        setState(() => _historyError = e.toString());
      }
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoadingHistory) return;

    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    if (!_service.isSignedIn) {
      setState(() {
        _history = const [];
        _isLoadingHistory = false;
      });
      return;
    }

    try {
      final items = await _service.fetchSearchHistory();
      if (!mounted) return;
      setState(() {
        _history = items;
        _isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _historyError = e.toString();
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _openUserAuth() async {
    final didLogin = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserAuthScreen(service: _service)),
    );

    if (!mounted) return;
    if (didLogin == true) {
      await _loadHistory();
    }
  }

  Future<void> _signOutUser() async {
    await _service.signOut();
    if (!mounted) return;
    setState(() {
      _history = const [];
    });
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

  Widget _getCurrentPage() {
    switch (_bottomNavIndex) {
      case 0:
        return HomeTab(
          isEnglish: _isEnglish,
          isLoadingStops: _isLoadingStops,
          stops: _stops,
          stopsLoadError: _stopsLoadError,
          fromStopId: _fromStopId,
          toStopId: _toStopId,
          fareQuote: _fareQuote,
          fareError: _fareError,
          isLoadingFare: _isLoadingFare,
          hasSearched: _hasSearched,
          onReloadStops: _loadStops,
          onFromChanged: (v) => setState(() {
            _fromStopId = v;
            _fareQuote = null;
            _fareError = null;
            _hasSearched = false;
          }),
          onToChanged: (v) => setState(() {
            _toStopId = v;
            _fareQuote = null;
            _fareError = null;
            _hasSearched = false;
          }),
          onSearch: _searchRoute,
          onApplyPopularRoute: _applyPopularRoute,
        );
      case 1:
        return MapScreen(
          stops: _stops,
          isEnglish: _isEnglish,
          fromStopId: _fromStopId,
          toStopId: _toStopId,
        );
      case 2:
        return HistoryScreen(
          isSignedIn: _service.isSignedIn,
          userEmail: _service.currentUser?.email,
          isLoading: _isLoadingHistory,
          history: _service.isSignedIn ? _history : _localHistory,
          error: _historyError,
          stops: _stops,
          isEnglish: _isEnglish,
          onRefresh: _loadHistory,
          onLogin: _openUserAuth,
          onSignOut: _signOutUser,
        );
      case 3:
        return const ProfileScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEnglish ? 'Local Transport' : 'লোকাল ট্রান্সপোর্ট'),
        actions: [
          IconButton(
            tooltip: _checkingAdmin ? 'Checking admin' : 'Admin',
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
      body: SafeArea(child: _getCurrentPage()),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: _bottomNavIndex,
              onDestinationSelected: (index) {
                setState(() => _bottomNavIndex = index);
                if (index == 2) {
                  _loadHistory();
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  label: 'Map',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
