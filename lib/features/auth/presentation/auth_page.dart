import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/app_config.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/repository_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _nameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authRepo = ref.read(authRepositoryProvider);

    try {
      if (_isLoginMode) {
        final user = await authRepo.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          context.go('/home');
        }
      } else {
        final user = await authRepo.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (errorMsg.contains('Exception:')) {
          errorMsg = errorMsg.replaceAll('Exception:', '').trim();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF3F4F6),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Graphic Area (35% approx height)
                  Container(
                    height: constraints.maxHeight * 0.35,
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    child: SafeArea(
                      bottom: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ripple',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('🌊', style: TextStyle(fontSize: 26)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          CustomPaint(
                            size: const Size(220, 110),
                            painter: CommuteRoutePainter(isDark: isDark, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Black Sheet Form (65% approx height)
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B0F19), // Slick Dark background
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Sliding Login / Register Tabs
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _isLoginMode ? null : _toggleAuthMode,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isLoginMode ? primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Login',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _isLoginMode ? Colors.black : Colors.white60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: !_isLoginMode ? null : _toggleAuthMode,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isLoginMode ? primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        'Register',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: !_isLoginMode ? Colors.black : Colors.white60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Form Content
                          if (!_isLoginMode) ...[
                            _buildInputLabel('Parent Full Name'),
                            const SizedBox(height: 6),
                            _buildInputField(
                              controller: _nameController,
                              hint: 'Enter your name',
                              icon: Icons.person_outline,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Parent name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                          ],

                          _buildInputLabel('Email / Username'),
                          const SizedBox(height: 6),
                          _buildInputField(
                            controller: _emailController,
                            hint: 'Enter your email address',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Email is required';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          _buildInputLabel('Password'),
                          const SizedBox(height: 6),
                          _buildInputField(
                            controller: _passwordController,
                            hint: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (val == null || val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),



                          const SizedBox(height: 14),

                          // Remember Me & Forget Password Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      activeColor: primaryColor,
                                      checkColor: Colors.black,
                                      onChanged: (val) {
                                        setState(() {
                                          _rememberMe = val ?? true;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: Text(
                                  'Forget password?',
                                  style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Large Yellow Action Button
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                      ),
                                    )
                                  : Text(
                                      _isLoginMode ? 'Login' : 'Register',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Or Login With row
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or ${_isLoginMode ? 'Register' : 'Login'} with',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Social Logins Capsules
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  label: 'Google',
                                  iconPath: 'Google',
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 28),
                                            const SizedBox(width: 8),
                                            const Text('Google Sign-In'),
                                          ],
                                        ),
                                        content: const Text('Google Sign-In is not enabled yet in this version. Please register/login using email and password.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildSocialButton(
                                  label: 'Facebook',
                                  iconPath: 'Facebook',
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Row(
                                          children: [
                                            Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 28),
                                            const SizedBox(width: 8),
                                            Text('Facebook Sign-In'),
                                          ],
                                        ),
                                        content: const Text('Facebook Sign-In is not enabled yet in this version. Please register/login using email and password.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF161E2E), // Dark input fill
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      validator: validator,
    );
  }

  Widget _buildSocialButton({
    required String label,
    required String iconPath,
    required VoidCallback? onTap,
  }) {
    final logo = iconPath == 'Google' ? Icons.g_mobiledata_rounded : Icons.facebook_rounded;
    final logoColor = iconPath == 'Google' ? Colors.redAccent : const Color(0xFF1877F2);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161E2E), // Dark capsule
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(logo, color: logoColor, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class CommuteRoutePainter extends CustomPainter {
  final bool isDark;
  final Color color;
  CommuteRoutePainter({required this.isDark, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final primaryColor = color;
    final secondaryColor = const Color(0xFF3B82F6); // Blue Accent
    final tealColor = const Color(0xFF0D9488); // Teal Accent

    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw multi-layered translucent concentric ripples representing water & Ripple network
    for (int i = 1; i <= 4; i++) {
      ripplePaint.color = primaryColor.withOpacity(0.08 * (5 - i));
      canvas.drawCircle(center, i * 22.0, ripplePaint);
    }

    // Draw curved gradient connecting swap path
    final pathPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [secondaryColor, primaryColor],
      ).createShader(Rect.fromLTRB(30, 0, size.width - 30, size.height));

    final path = Path()
      ..moveTo(40, size.height / 2 + 10)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.1,
        size.width * 0.7,
        size.height * 0.9,
        size.width - 40,
        size.height / 2 - 10,
      );
    canvas.drawPath(path, pathPaint);

    // Draw pulsing energy dots on path
    final dotPaint = Paint()..style = PaintingStyle.fill;

    // Left Node (Blue parent home)
    dotPaint.color = secondaryColor.withOpacity(0.2);
    canvas.drawCircle(Offset(40, size.height / 2 + 10), 12, dotPaint);
    dotPaint.color = secondaryColor;
    canvas.drawCircle(Offset(40, size.height / 2 + 10), 6, dotPaint);

    // Right Node (Yellow school/target)
    dotPaint.color = primaryColor.withOpacity(0.2);
    canvas.drawCircle(Offset(size.width - 40, size.height / 2 - 10), 12, dotPaint);
    dotPaint.color = primaryColor;
    canvas.drawCircle(Offset(size.width - 40, size.height / 2 - 10), 6, dotPaint);

    // Center interlocking swap arrows
    final glowPaint = Paint()
      ..color = tealColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 16, glowPaint);
    
    // Draw clean modern core swap symbol
    final corePaint = Paint()
      ..color = tealColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 10, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
