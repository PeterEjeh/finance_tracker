import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup/signup_email_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true; // toggle between login/signup
  bool _loading = false;
  bool _obscurePassword = true;
  bool _keepMeLoggedIn = false;
  String? _error;

  void _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _forgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // App Logo
                _buildAppLogo(),

                const SizedBox(height: 24),

                // App Name
                Text(
                  'FinanceTracker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),

                const SizedBox(height: 40),

                // Tagline
                _buildTagline(),

                const SizedBox(height: 50),

                // Error Message
                if (_error != null) _buildErrorMessage(),

                // Email Field
                _buildEmailField(),

                const SizedBox(height: 20),

                // Password Field
                _buildPasswordField(),

                const SizedBox(height: 24),

                // Keep me logged in & Forgot password
                _buildOptionsRow(),

                const SizedBox(height: 40),

                // Sign In Button
                _buildSignInButton(),

                const SizedBox(height: 24),

                // Sign Up Toggle
                _buildSignUpToggle(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet,
        color: Colors.white,
        size: 40,
      ),
    );
  }

  Widget _buildTagline() {
    final cs = Theme.of(context).colorScheme;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w300,
          color: cs.onBackground.withOpacity(0.6),
          height: 1.2,
        ),
        children: [
          TextSpan(
            text: 'Track. Budget. Save. ',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              color: cs.onBackground,
            ),
          ),
          TextSpan(
            text: 'Grow.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: cs.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 14),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'hello@financetracker.com',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: '• • • • • • • • • •',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      children: [
        // Keep me logged in checkbox
        GestureDetector(
          onTap: () {
            setState(() {
              _keepMeLoggedIn = !_keepMeLoggedIn;
            });
          },
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _keepMeLoggedIn
                      ? const Color(0xFF2C2C2C)
                      : Colors.transparent,
                  border: Border.all(
                    color: _keepMeLoggedIn
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFCCCCCC),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _keepMeLoggedIn
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              const Text(
                'Keep me logged in',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Forgot password link
        GestureDetector(
          onTap: _forgotPassword,
          child: Text(
            'Forgot password?',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2C2C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: const Color(0xFF2C2C2C).withOpacity(0.6),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Sign In' : 'Sign Up',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildSignUpToggle() {
    return Column(
      children: [
        // Google Sign In Button
        _buildGoogleSignInButton(),

        const SizedBox(height: 16),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFCCCCCC))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFCCCCCC))),
          ],
        ),

        const SizedBox(height: 16),

        // Sign Up Link
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignupScreen()),
            );
          },
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
              children: [
                TextSpan(text: "Don't have an account? "),
                TextSpan(
                  text: 'Sign Up',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
        icon: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/g-logo.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
        label: const Text(
          'Continue with Google',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDeveloperAttribution() {
    return Text(
      'developed by petes-tech',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }
}
