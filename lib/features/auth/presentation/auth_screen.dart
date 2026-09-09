import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/privacy_policy_button.dart';
import '../../../shared/widgets/terms_of_use_button.dart';
import '../domain/account_type.dart';
import '../providers/auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  bool _createAccount = false;
  bool _obscurePassword = true;
  AccountType? _accountType;
  bool _declarationAccepted = false;
  String? _declarationError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(authActionControllerProvider);

    final errorMessage = action.when(
      data: (_) => null,
      loading: () => null,
      error: (error, _) => _messageFor(error),
    );

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Center(
              child: Image.asset(
                'assets/branding/past question paper.png',
                width: 88,
                height: 88,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _createAccount ? 'Create your account' : 'Welcome back',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _createAccount
                  ? 'Save questions and track your progress.'
                  : 'Sign in to access your saved learning.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText:
                          _createAccount &&
                              _accountType == AccountType.guardianManagedLearner
                          ? 'Parent or guardian email address'
                          : 'Email address',
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (!email.contains('@') || !email.contains('.')) {
                        return 'Enter a valid email address.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: _createAccount
                        ? TextInputAction.next
                        : TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) {
                      if (!_createAccount) {
                        _submit();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').length < 8) {
                        return 'Use at least 8 characters.';
                      }

                      return null;
                    },
                  ),
                  if (_createAccount) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }

                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Who is creating this account?',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AccountTypeOption(
                      title: 'I am 18 or older',
                      description:
                          'I am creating and managing my own learner account.',
                      selected: _accountType == AccountType.adultLearner,
                      onTap: () {
                        setState(() {
                          _accountType = AccountType.adultLearner;
                          _declarationAccepted = false;
                          _declarationError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _AccountTypeOption(
                      title: 'Parent or guardian',
                      description:
                          'I am creating and managing this account for a learner under 18.',
                      selected:
                          _accountType == AccountType.guardianManagedLearner,
                      onTap: () {
                        setState(() {
                          _accountType = AccountType.guardianManagedLearner;
                          _declarationAccepted = false;
                          _declarationError = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _declarationAccepted,
                      onChanged: _accountType == null
                          ? null
                          : (value) {
                              setState(() {
                                _declarationAccepted = value ?? false;
                                _declarationError = null;
                              });
                            },
                      title: Text(switch (_accountType) {
                        AccountType.adultLearner =>
                          'I confirm that I am 18 or older, that this email belongs '
                              'to me, and that I have read the Privacy Policy and '
                              'Terms of Use.',
                        AccountType.guardianManagedLearner =>
                          'I confirm that I am the learner’s parent or legal guardian, '
                              'that this is my email address, and that I have read the '
                              'Privacy Policy and Terms of Use and consent to the described '
                              'processing for '
                              'the learner account.',
                        null => 'Select an account type before accepting.',
                      }),
                    ),
                    const Wrap(
                      children: [PrivacyPolicyButton(), TermsOfUseButton()],
                    ),
                    if (_declarationError != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _declarationError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: action.isLoading ? null : _submit,
              child: action.isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_createAccount ? 'Create account' : 'Sign in'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: action.isLoading
                  ? null
                  : () {
                      setState(() {
                        _createAccount = !_createAccount;
                        _accountType = null;
                        _declarationAccepted = false;
                        _declarationError = null;
                      });
                    },
              child: Text(
                _createAccount
                    ? 'Already have an account? Sign in'
                    : 'New here? Create an account',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: action.isLoading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Continue as guest'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final formIsValid = _formKey.currentState!.validate();

    if (_createAccount && (_accountType == null || !_declarationAccepted)) {
      setState(() {
        _declarationError = _accountType == null
            ? 'Select who is creating this account.'
            : 'Accept the account declaration to continue.';
      });

      return;
    }

    if (!formIsValid) {
      return;
    }

    final controller = ref.read(authActionControllerProvider.notifier);

    if (_createAccount) {
      final result = await controller.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        accountType: _accountType!,
        declarationAccepted: _declarationAccepted,
      );

      if (!mounted || result == null) {
        return;
      }

      if (result.requiresEmailConfirmation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to confirm your account.'),
          ),
        );
      }

      Navigator.of(context).pop();
      return;
    }

    await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    final state = ref.read(authActionControllerProvider);

    if (!state.hasError) {
      Navigator.of(context).pop();
    }
  }

  String _messageFor(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login')) {
        return 'Incorrect email address or password.';
      }

      if (message.contains('email not confirmed')) {
        return 'Confirm your email before signing in.';
      }

      if (message.contains('already registered')) {
        return 'An account already exists for this email.';
      }

      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}

class _AccountTypeOption extends StatelessWidget {
  const _AccountTypeOption({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foregroundColor = selected ? colors.onPrimary : colors.onSurface;

    return Card(
      margin: EdgeInsets.zero,
      color: selected ? colors.primary : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? colors.primary : colors.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colors.onPrimary : colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: foregroundColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: foregroundColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
