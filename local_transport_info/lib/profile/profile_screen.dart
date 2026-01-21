import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/user_auth_screen.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _service = SupabaseService();

  final _nameController = TextEditingController(text: '');
  final _emailController = TextEditingController(text: '');
  final _phoneController = TextEditingController(text: '');
  final _cityController = TextEditingController(text: 'Dhaka');

  final _authEmailController = TextEditingController();
  final _authPasswordController = TextEditingController();
  bool _authRegister = false;
  bool _authSubmitting = false;
  bool _authObscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _authEmailController.dispose();
    _authPasswordController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved (local only).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAuth() async {
    final didLogin = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserAuthScreen(service: _service)),
    );

    if (!mounted) return;
    if (didLogin == true) {
      setState(() {});
    }
  }

  Future<void> _signOut() async {
    await _service.signOut();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _submitInlineAuth() async {
    if (_authSubmitting) return;

    FocusScope.of(context).unfocus();

    final email = _authEmailController.text.trim();
    final password = _authPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter email and password.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _authSubmitting = true);

    try {
      if (_authRegister) {
        final response = await _service.signUpWithPassword(
          email: email,
          password: password,
        );
        if (!mounted) return;
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm, then log in.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _authRegister = false);
        }
      } else {
        await _service.signInWithPassword(email: email, password: password);
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      final message = e is AuthException
          ? e.message
          : '${_authRegister ? 'Sign up' : 'Login'} failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _authSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_authSubmitting) return;
    setState(() => _authSubmitting = true);
    try {
      await _service.signInWithGoogle();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AuthException ? e.message : 'Google sign-in failed: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _authSubmitting = false);
    }
  }

  String _displayName() {
    final user = _service.currentUser;
    final meta = user?.userMetadata;
    final raw = meta is Map<String, dynamic>
        ? (meta['full_name'] ?? meta['name'])
        : null;
    final fromMeta = raw?.toString().trim();
    if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      final local = email.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return 'Commuter';
  }

  String _initials() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final first = parts.first.characters.first.toUpperCase();
        final last = parts.length > 1
            ? parts.last.characters.first.toUpperCase()
            : '';
        return '$first$last';
      }
    }
    final email =
        _service.currentUser?.email?.trim() ?? _emailController.text.trim();
    if (email.isNotEmpty) return email.characters.first.toUpperCase();
    return 'C';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final isSignedIn = _service.isSignedIn;
    final userEmail = _service.currentUser?.email;
    final displayName = _displayName();

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 520.0;
              final contentWidth = maxWidth > 520 ? 520.0 : maxWidth;

              return Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.98),
                              secondary.withValues(alpha: 0.92),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 22,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 56,
                              width: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  _initials(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isSignedIn
                                        ? (userEmail ?? 'Account connected')
                                        : 'Sign in to sync history & routes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            if (isSignedIn)
                              FilledButton.tonal(
                                onPressed: _signOut,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                child: const Text('Sign out'),
                              ),
                          ],
                        ),
                      ),
                      if (!isSignedIn) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primary.withValues(alpha: 0.95),
                                secondary.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lock_open,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Commuter Login',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Fast access to routes & history sync',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Login'),
                                    selected: !_authRegister,
                                    onSelected: (v) =>
                                        setState(() => _authRegister = !v),
                                  ),
                                  const SizedBox(width: 6),
                                  ChoiceChip(
                                    label: const Text('Register'),
                                    selected: _authRegister,
                                    onSelected: (v) =>
                                        setState(() => _authRegister = v),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _authEmailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _authPasswordController,
                                obscureText: _authObscure,
                                onSubmitted: (_) => _submitInlineAuth(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.9,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _authObscure ? 'Show' : 'Hide',
                                    onPressed: () => setState(
                                      () => _authObscure = !_authObscure,
                                    ),
                                    icon: Icon(
                                      _authObscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: _authSubmitting
                                    ? null
                                    : _submitInlineAuth,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: _authSubmitting
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _authRegister
                                            ? 'Create Account'
                                            : 'Login',
                                      ),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _authSubmitting
                                    ? null
                                    : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.g_mobiledata),
                                label: const Text('Continue with Gmail'),
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: _openAuth,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open full login page'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isSignedIn) ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Details',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Full name',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone',
                                    prefixIcon: Icon(Icons.phone_outlined),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _cityController,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    labelText: 'City',
                                    prefixIcon: Icon(
                                      Icons.location_city_outlined,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _saveProfile,
                                  child: const Text('Save Profile'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
