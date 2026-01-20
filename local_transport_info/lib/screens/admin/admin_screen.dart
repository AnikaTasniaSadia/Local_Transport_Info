import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../data/models/route_info.dart';
import '../../data/models/stop.dart';
import '../../services/supabase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    super.key,
    required this.service,
    required this.stops,
    required this.isEnglish,
  });

  final SupabaseService service;
  final List<Stop> stops;
  final bool isEnglish;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loadingRoutes = false;
  List<RouteInfo> _routes = const [];
  String? _routesError;

  String? _fromStopId;
  String? _toStopId;
  String? _routeId;

  final TextEditingController _fareController = TextEditingController();
  final TextEditingController _routeIdController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _fareController.dispose();
    _routeIdController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    if (_loadingRoutes) return;

    setState(() {
      _loadingRoutes = true;
      _routesError = null;
    });

    try {
      final routes = await widget.service.fetchRoutes();
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _routeId ??= routes.isNotEmpty ? routes.first.routeId : null;
        if (_routeId != null && _routeIdController.text.isEmpty) {
          _routeIdController.text = _routeId!;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _routesError = e.toString();
        _routes = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRoutes = false);
      }
    }
  }

  double? get _fareValue {
    final raw = _fareController.text.trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value <= 0) return null;
    return value;
  }

  bool get _canSave {
    return _fromStopId != null &&
        _toStopId != null &&
        _routeId != null &&
        _fromStopId != _toStopId &&
        _fareValue != null;
  }

  Future<void> _saveFare() async {
    if (_saving || !_canSave) return;

    setState(() => _saving = true);
    try {
      await widget.service.upsertFare(
        routeId: _routeId!,
        fromStopId: _fromStopId!,
        toStopId: _toStopId!,
        fare: _fareValue!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fare saved to Supabase.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return;

    final Uint8List? bytes = result.files.single.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read that file on this platform.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final jsonString = utf8.decode(bytes);

    try {
      final count = await widget.service.importFaresFromJsonString(jsonString);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $count fare rows.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exampleJson = const JsonEncoder.withIndent('  ').convert({
      'fares': [
        {
          'route_id': 'a101',
          'from_stop': 'kalshi',
          'to_stop': 'mirpur12',
          'fare': 10,
        },
      ],
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            tooltip: 'Import JSON',
            onPressed: _importJson,
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add / Update Fare',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Writes directly to Supabase. Your RLS policies must allow INSERT/UPDATE for the key you run the app with.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 14),
                          if (_routesError != null) ...[
                            Text(
                              _routesError!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Autocomplete<RouteInfo>(
                                  displayStringForOption: (route) => route
                                      .displayName(isEnglish: widget.isEnglish),
                                  optionsBuilder: (value) {
                                    final query = value.text
                                        .trim()
                                        .toLowerCase();
                                    if (query.isEmpty) return _routes;
                                    return _routes.where((route) {
                                      final name = route
                                          .displayName(
                                            isEnglish: widget.isEnglish,
                                          )
                                          .toLowerCase();
                                      return name.contains(query) ||
                                          route.routeId.toLowerCase().contains(
                                            query,
                                          ) ||
                                          route.routeNo.toLowerCase().contains(
                                            query,
                                          );
                                    });
                                  },
                                  onSelected: (route) {
                                    setState(() => _routeId = route.routeId);
                                    _routeIdController.text = route.routeId;
                                  },
                                  fieldViewBuilder:
                                      (context, controller, focusNode, _) {
                                        return TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          decoration: const InputDecoration(
                                            labelText: 'Route (search)',
                                            prefixIcon: Icon(
                                              Icons.route_outlined,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                tooltip: 'Reload routes',
                                onPressed: _loadingRoutes ? null : _loadRoutes,
                                icon: _loadingRoutes
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _routeIdController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Route ID',
                              hintText: 'e.g. a101',
                              helperText: _routes.isEmpty
                                  ? 'No routes loaded. Type a new route ID.'
                                  : 'You can type a new route ID to add fares.',
                            ),
                            onChanged: (value) {
                              final trimmed = value.trim();
                              setState(() {
                                _routeId = trimmed.isEmpty ? null : trimmed;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownMenu<String>(
                            expandedInsets: EdgeInsets.zero,
                            label: const Text('From Stop'),
                            initialSelection: _fromStopId,
                            onSelected: (v) => setState(() => _fromStopId = v),
                            dropdownMenuEntries: widget.stops
                                .map(
                                  (s) => DropdownMenuEntry<String>(
                                    value: s.stopId,
                                    label: s.displayName(
                                      isEnglish: widget.isEnglish,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                          DropdownMenu<String>(
                            expandedInsets: EdgeInsets.zero,
                            label: const Text('To Stop'),
                            initialSelection: _toStopId,
                            onSelected: (v) => setState(() => _toStopId = v),
                            dropdownMenuEntries: widget.stops
                                .map(
                                  (s) => DropdownMenuEntry<String>(
                                    value: s.stopId,
                                    label: s.displayName(
                                      isEnglish: widget.isEnglish,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _fareController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Fare (BDT)',
                              hintText: 'e.g. 35',
                              prefixIcon: Icon(Icons.currency_exchange),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _canSave ? _saveFare : null,
                            child: _saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save Fare'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JSON Import',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Pick a .json file and the app will upsert fare rows into Supabase.',
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Example JSON:\n$exampleJson',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.tonal(
                            onPressed: _importJson,
                            child: const Text('Import JSON File'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
