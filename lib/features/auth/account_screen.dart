import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/firebase/auth_service.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../core/state/app_scope.dart';
import '../../core/theme/letters_app_bar.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _prefilledName = false;

  String get _next {
    return GoRouterState.of(context).uri.queryParameters['next'] ?? '';
  }

  String get _reason {
    return GoRouterState.of(context).uri.queryParameters['reason'] ?? '';
  }

  bool get _isBackupOffer => _reason == 'backup';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilledName) {
      return;
    }
    _prefilledName = true;
    final existing = AppScope.of(context).displayName.trim();
    if (existing.isNotEmpty) {
      _nameController.text = existing;
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finishAfterAuth() async {
    final app = AppScope.of(context);
    final next = Uri.decodeComponent(_next);
    if (next.isNotEmpty && next.startsWith('/')) {
      if (!app.onboardingComplete && app.currentMemorial != null) {
        await app.completeOnboarding();
      }
      if (mounted) {
        context.go(next);
      }
      return;
    }
    if (_next == 'home' || app.currentMemorial != null) {
      if (!app.onboardingComplete) {
        await app.completeOnboarding();
      }
      if (mounted) {
        context.go('/shell/home');
      }
      return;
    }
    if (app.currentMemorial == null) {
      context.push('/memorial-setup');
      return;
    }
    if (!app.onboardingComplete) {
      context.push('/first-action');
      return;
    }
    context.go('/shell/home');
  }

  Future<void> _createAccount() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty) {
      setState(() {
        _error = 'Please enter a display name.';
        _busy = false;
      });
      return;
    }
    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter your email address.';
        _busy = false;
      });
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Please enter a valid email address.';
        _busy = false;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _error = 'Use a password with at least 6 characters.';
        _busy = false;
      });
      return;
    }

    try {
      late final String newUid;
      if (FirebaseBootstrap.isReady) {
        final cred = await AuthService.instance.createAccount(
          email: email,
          password: password,
        );
        newUid = cred.user.uid;
      } else {
        newUid = const Uuid().v4();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_account_password_hash', password);
      }
      if (!mounted) {
        return;
      }
      await AppScope.of(context).saveAccount(
        newUid: newUid,
        newDisplayName: name,
        newEmail: email,
      );
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      await _finishAfterAuth();
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (FirebaseBootstrap.isReady) {
        if (email.isEmpty || !_isValidEmail(email)) {
          setState(() {
            _error = 'Please enter the email for your account.';
            _busy = false;
          });
          return;
        }
        final cred = await AuthService.instance.signIn(
          email: email,
          password: password,
        );
        if (!mounted) {
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        final enteredName = _nameController.text.trim();
        final displayName = enteredName.isNotEmpty
            ? enteredName
            : prefs.getString('user_display_name') ?? email.split('@').first;
        if (!mounted) {
          return;
        }
        await AppScope.of(context).saveAccount(
          newUid: cred.user.uid,
          newDisplayName: displayName,
          newEmail: email,
        );
      } else {
        final prefs = await SharedPreferences.getInstance();
        final savedUid = prefs.getString('user_uid');
        final savedPassword = prefs.getString('local_account_password_hash');
        if (savedUid == null) {
          setState(() {
            _error = 'No local account found. Create one first.';
            _busy = false;
          });
          return;
        }
        if (savedPassword != password) {
          setState(() {
            _error = 'Password does not match this device\'s saved account.';
            _busy = false;
          });
          return;
        }
        if (!mounted) {
          return;
        }
        await AppScope.of(context).load();
      }

      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      await _finishAfterAuth();
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final intro = _isBackupOffer
        ? 'Register to save what you already wrote—privately, on your terms.'
        : 'Optional—create an account when you want encrypted backup.';
    final helper = _isBackupOffer
        ? 'Your entry is already on this device. Register only if you want '
            'encrypted backup and access from another device.'
        : 'Your account uses Firebase Auth so photos can back up to '
            'private cloud storage when you enable it in Settings.';

    return Scaffold(
      appBar: LettersAppBar(
        title: Text(_isBackupOffer ? 'Register to save' : 'Your account'),
        intro: intro,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Register'),
            Tab(text: 'Sign in'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AccountForm(
            showName: true,
            requireEmail: true,
            emailController: _emailController,
            passwordController: _passwordController,
            nameController: _nameController,
            error: _error,
            busy: _busy,
            onSubmit: _createAccount,
            submitLabel: _isBackupOffer ? 'Register to Save' : 'Create account',
            helperText: helper,
          ),
          _AccountForm(
            showName: true,
            requireEmail: true,
            emailController: _emailController,
            passwordController: _passwordController,
            nameController: _nameController,
            error: _error,
            busy: _busy,
            onSubmit: _signIn,
            submitLabel: 'Sign in',
            helperText:
                'Sign in with the email and password you created. You can choose '
                'a screen name to use instead of the default.',
            nameLabel: 'Screen name (optional)',
          ),
        ],
      ),
    );
  }
}

class _AccountForm extends StatelessWidget {
  const _AccountForm({
    required this.showName,
    required this.requireEmail,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.error,
    required this.busy,
    required this.onSubmit,
    required this.submitLabel,
    required this.helperText,
    this.nameLabel = 'Display name',
  });

  final bool showName;
  final bool requireEmail;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final String? error;
  final bool busy;
  final VoidCallback onSubmit;
  final String submitLabel;
  final String helperText;
  final String nameLabel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(helperText, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),
        if (showName)
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: nameLabel),
            textInputAction: TextInputAction.next,
          ),
        if (showName) const SizedBox(height: 12),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: requireEmail ? 'Email' : 'Email (optional)',
          ),
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : onSubmit,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(submitLabel),
        ),
      ],
    );
  }
}
