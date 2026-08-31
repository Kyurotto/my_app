import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/app_service.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isAutoLogging = true; // Show loading while checking auto-login
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initRememberMe();
  }

  /// On page load: check if auto-login session exists.
  /// If valid, navigate directly to the appropriate dashboard.
  /// If only the identifier was saved, pre-fill the username field.
  Future<void> _initRememberMe() async {
    try {
      final appService = AppService.instance;

      final savedId = await appService.getSavedIdentifier();
      if (!mounted) return;

      if (savedId != null && savedId.isNotEmpty) {
        _identifierController.text = savedId;
        _rememberMe = true;

        final LocalAuthentication auth = LocalAuthentication();
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

        if (canAuthenticate) {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to log in automatically',
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          );

          if (didAuthenticate) {
            bool success = await appService.tryAutoLogin();
            if (!success) {
               success = await appService.biometricLogin(savedId);
            }

            if (success) {
              if (!mounted) return;
              final role = appService.currentUser?.role;
              if (role == 'admin') {
                Navigator.pushReplacementNamed(context, '/admin_dashboard');
              } else {
                Navigator.pushReplacementNamed(context, '/employee_dashboard');
              }
              return;
            }
          }
        } else {
          final autoLoggedIn = await appService.tryAutoLogin();
          if (autoLoggedIn) {
            if (!mounted) return;
            final role = appService.currentUser?.role;
            if (role == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin_dashboard');
            } else {
              Navigator.pushReplacementNamed(context, '/employee_dashboard');
            }
            return;
          }
        }
      } else {
        // No saved id, do nothing and just show login form
      }
    } catch (e) {
      debugPrint('⚠️ Remember Me init error: $e');
    } finally {
      if (mounted) {
        setState(() => _isAutoLogging = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appService = AppService.instance;
      String? identifier = _identifierController.text.trim();

      if (identifier.isEmpty) {
        identifier = await appService.getSavedIdentifier();
      }

      if (identifier == null || identifier.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your email or username first, or sign in once with password.';
        });
        return;
      }

      final LocalAuthentication auth = LocalAuthentication();
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _errorMessage = 'Biometric authentication is not supported or not set up on this device.';
        });
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to sign in',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );

      if (!mounted) return;

      if (didAuthenticate) {
        bool success = await appService.tryAutoLogin();
        if (!success) {
          success = await appService.biometricLogin(identifier);
        }

        if (success) {
          if (_rememberMe) {
            await appService.saveRememberMe(identifier);
          }

          if (!mounted) return;
          final role = appService.currentUser?.role;
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/employee_dashboard');
          }
        } else {
          setState(() {
            _errorMessage = 'User not found. Please check your username/email.';
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Biometric authentication error: $e');
      setState(() {
        _errorMessage = 'Biometric authentication error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final identifier = _identifierController.text.trim();
    final success = await AppService.instance.login(
      identifier,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Handle "Remember me" — save or clear session
      if (_rememberMe) {
        await AppService.instance.saveRememberMe(identifier);
      } else {
        await AppService.instance.clearRememberMe();
      }

      if (!mounted) return;

      final role = AppService.instance.currentUser?.role;
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/employee_dashboard');
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid username/email or password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while checking auto-login status
    if (_isAutoLogging) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBF8F3),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.amberGold),
              ),
              const SizedBox(height: 16),
              Text(
                'Checking session...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 4,
                shadowColor: AppTheme.primaryCoffee.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFEBE5DA), width: 1),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Logo
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.amberGold.withValues(alpha: 0.18),
                              border: Border.all(color: AppTheme.amberGold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.amberGold.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.coffee_rounded,
                              size: 42,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title
                        const Text(
                          'Coffee Shop POS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E1B18),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please sign in to access your terminal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Error Banner
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 18),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Email / Username field
                        TextFormField(
                          controller: _identifierController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email or Username',
                            prefixIcon: Icon(Icons.person_rounded, color: Color(0xFF78472A)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your email or username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF78472A)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                color: const Color(0xFF78472A),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Remember Me
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppTheme.amberGold,
                                checkColor: AppTheme.primaryCoffee,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remember me',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Submit button and Fingerprint quick action
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : () => _handleLogin(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.amberGold,
                                  foregroundColor: AppTheme.primaryCoffee,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCoffee),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Tooltip(
                              message: 'Sign in with Fingerprint',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoading ? null : _handleBiometricLogin,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    height: 52,
                                    width: 52,
                                    decoration: BoxDecoration(
                                      color: AppTheme.amberGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppTheme.amberGold, width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
                                      color: Color(0xFF78472A),
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Quick Biometric text button
                        InkWell(
                          onTap: _isLoading ? null : _handleBiometricLogin,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.fingerprint_rounded,
                                  size: 20,
                                  color: Color(0xFF78472A),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Sign in with Fingerprint / Face ID',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Register button
                        OutlinedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFE5E0D8)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Create an Account',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C1810),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
