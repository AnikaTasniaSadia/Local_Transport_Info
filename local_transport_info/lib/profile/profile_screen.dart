import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../screens/auth/user_auth_screen.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Uint8List? _profileImageBytes;

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

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load that image on this platform.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _profileImageBytes = bytes;
    });
  }

  void _removeProfileImage() {
    setState(() {
      _profileImageBytes = null;
    });
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_authRegister ? 'Sign up' : 'Login'} failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _authSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final isSignedIn = _service.isSignedIn;
    final userEmail = _service.currentUser?.email;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isSignedIn) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _authRegister
                                  ? 'Create commuter account'
                                  : 'Login to your account',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _authRegister
                                  ? 'Use email and password to register.'
                                  : 'Use email and password to log in.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _authEmailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
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
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _authSubmitting
                                  ? null
                                  : _submitInlineAuth,
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
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _authSubmitting
                                  ? null
                                  : () => setState(
                                    () => _authRegister = !_authRegister,
                                  ),
                              child: Text(
                                _authRegister
                                    ? 'Already have an account? Login'
                                    : 'New here? Create account',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _openAuth,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open full login page'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSignedIn
                                      ? 'Signed in'
                                      : 'Login or Register',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isSignedIn
                                      ? (userEmail ?? 'Account connected')
                                      : 'Sign in to sync your history',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (isSignedIn)
                            TextButton(
                              onPressed: _signOut,
                              child: const Text('Sign out'),
                            )
                          else
                            FilledButton.tonal(
                              onPressed: _openAuth,
                              child: const Text('Login'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImageBytes == null
                              ? null
                              : MemoryImage(_profileImageBytes!),
                          child: _profileImageBytes == null
                              ? Icon(
                                  Icons.person_outline,
                                  color: primary,
                                  size: 32,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Basic information & profile photo',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Add profile image',
                          onPressed: _pickProfileImage,
                          icon: const Icon(Icons.camera_alt_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: _pickProfileImage,
                                child: const Text('Choose Image'),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _profileImageBytes == null
                                    ? null
                                    : _removeProfileImage,
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
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
                              prefixIcon: Icon(Icons.location_city_outlined),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _saveProfile,
                            child: const Text('Save'),
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
