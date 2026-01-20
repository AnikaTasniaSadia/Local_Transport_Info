import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_config.dart';
import '../../services/supabase_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.service,
    required this.fromStopId,
    required this.toStopId,
    required this.fromStopName,
    required this.toStopName,
  });

  final SupabaseService service;
  final String fromStopId;
  final String toStopId;
  final String fromStopName;
  final String toStopName;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TextEditingController _distanceController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  double? _governmentFare;
  String? _routeNo;

  double? get _distanceKm {
    final text = _distanceController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value <= 0) return null;
    return value;
  }

  double? get _estimatedFare {
    final km = _distanceKm;
    if (km == null) return null;
    return km * AppConfig.fallbackRatePerKm;
  }

  @override
  void initState() {
    super.initState();
    _loadFare();
    _distanceController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _loadFare() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _governmentFare = null;
      _routeNo = null;
    });

    try {
      final quote = await widget.service.fetchFareQuote(
        fromStopId: widget.fromStopId,
        toStopId: widget.toStopId,
      );

      if (!mounted) return;
      setState(() {
        _governmentFare = quote?.fare;
        _routeNo = quote?.routeNo;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final estimatedFare = _estimatedFare;
    final hasGovFare = _governmentFare != null;

    final Widget content = _isLoading
        ? const Center(
            key: ValueKey('loading'),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: CircularProgressIndicator(),
            ),
          )
        : _error != null
        ? Column(
            key: const ValueKey('error'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadFare, child: const Text('Retry')),
            ],
          )
        : hasGovFare
        ? Column(
            key: const ValueKey('gov-fare'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '৳${_governmentFare!.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.account_balance, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Official government fare',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          )
        : Column(
            key: const ValueKey('estimate'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Government fare not found for this pair.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter distance (km) to estimate fare:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^[0-9]*\.?[0-9]*$'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Distance (km)',
                  hintText: 'e.g. 10.5',
                  prefixIcon: Icon(Icons.route_outlined),
                ),
              ),
              const SizedBox(height: 12),
              if (estimatedFare != null)
                Text(
                  '৳${estimatedFare.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  'Rate: ৳${AppConfig.fallbackRatePerKm} per km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Route Result')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.fromStopName} → ${widget.toStopName}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Official Fare',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        if (_routeNo != null &&
                            _routeNo!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Route: $_routeNo',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: content,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (!_isLoading && _error == null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_outlined),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Fares are based on official city transport guidelines.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
