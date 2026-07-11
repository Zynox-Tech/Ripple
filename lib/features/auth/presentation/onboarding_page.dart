import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../config/app_config.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/widgets/ripple_widgets.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final walkthroughData = [
      {
        'title': 'Find your dream school swap to start your journey',
        'desc': 'Connect with families travelling in opposite directions to easily swap school admissions.',
        'painter': (bool dark) => CustomPaint(
              size: const Size(280, 180),
              painter: SchoolBusPainter(isDark: dark),
            ),
      },
      {
        'title': 'Coordinate with matching families securely',
        'desc': 'Chat in real-time, organize paperwork checklists, and manage mutual transfers safely.',
        'painter': (bool dark) => CustomPaint(
              size: const Size(280, 180),
              painter: SecureChatPainter(isDark: dark),
            ),
      },
      {
        'title': 'Track progress step by step',
        'desc': 'Follow the synchronization checklist for both parents. Confirm school swaps together.',
        'painter': (bool dark) => CustomPaint(
              size: const Size(280, 180),
              painter: ChecklistSyncPainter(isDark: dark),
            ),
      }
    ];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Theme Switcher & Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ripple',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: RippleTheme.primaryTealDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '🌊',
                        style: TextStyle(
                          fontSize: 22,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.03),
                    ),
                    child: IconButton(
                      onPressed: () => ref.read(themeModeProvider.notifier).toggleThemeMode(),
                      icon: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Walkthrough PageView (Titles, Subtitles, custom graphics)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: walkthroughData.length,
                itemBuilder: (context, index) {
                  final item = walkthroughData[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: (item['painter'] as Widget Function(bool))(isDark),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : Colors.black,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                walkthroughData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? primaryColor
                        : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Bottom Onboarding Actions - Custom sliding Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InteractiveSliderButton(
                    onTrigger: _completeOnboarding,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

// ----------------- Custom Vector Painters -----------------

class SchoolBusPainter extends CustomPainter {
  final bool isDark;
  SchoolBusPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final busColor = const Color(0xFFFACC15);
    final accentColor = const Color(0xFFEAB308);
    final tyreColor = const Color(0xFF1F2937);
    final glassColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    
    final paint = Paint()..style = PaintingStyle.fill;
    
    final roadPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(10, size.height - 30), Offset(size.width - 10, size.height - 30), roadPaint);

    final shadowPaint = Paint()
      ..color = isDark ? Colors.black38 : Colors.black.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, size.height - 110, size.width - 60, 68),
        const Radius.circular(16),
      ),
      shadowPaint,
    );

    paint.color = busColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, size.height - 115, size.width - 60, 68),
        const Radius.circular(16),
      ),
      paint,
    );

    paint.color = accentColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(30, size.height - 95, 25, 48),
        const Radius.circular(8),
      ),
      paint,
    );

    paint.color = const Color(0xFF111827);
    canvas.drawRect(Rect.fromLTWH(55, size.height - 85, size.width - 90, 8), paint);

    paint.color = glassColor;
    final double windowWidth = 24.0;
    final double windowHeight = 22.0;
    final double startX = 65.0;
    for (int i = 0; i < 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + (i * 32), size.height - 105, windowWidth, windowHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }

    paint.color = tyreColor;
    canvas.drawCircle(Offset(70, size.height - 35), 18, paint);
    canvas.drawCircle(Offset(size.width - 80, size.height - 35), 18, paint);

    paint.color = isDark ? const Color(0xFF4B5563) : Colors.white;
    canvas.drawCircle(Offset(70, size.height - 35), 7, paint);
    canvas.drawCircle(Offset(size.width - 80, size.height - 35), 7, paint);

    paint.color = const Color(0xFFFDE047);
    canvas.drawArc(
      Rect.fromLTWH(26, size.height - 80, 10, 16),
      1.57,
      3.14,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SecureChatPainter extends CustomPainter {
  final bool isDark;
  SecureChatPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final primaryYellow = const Color(0xFFFACC15);
    final softBlue = const Color(0xFF3B82F6);
    final paint = Paint()..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.black12
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.5), Offset(size.width * 0.75, size.height * 0.5), linePaint);
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.25), linePaint);
    canvas.drawLine(Offset(size.width * 0.75, size.height * 0.5), Offset(size.width * 0.5, size.height * 0.25), linePaint);

    paint.color = softBlue;
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.5), 18, paint);
    paint.color = primaryYellow;
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.5), 18, paint);

    paint.color = isDark ? const Color(0xFF1E293B) : Colors.white;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.25), 24, paint);

    final borderPaint = Paint()
      ..color = primaryYellow
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.25), 24, borderPaint);

    paint.style = PaintingStyle.fill;
    paint.color = primaryYellow;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.5 - 8, size.height * 0.25 - 8, 16, 16),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ChecklistSyncPainter extends CustomPainter {
  final bool isDark;
  ChecklistSyncPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final secondaryEmerald = const Color(0xFF10B981);
    final paint = Paint()..style = PaintingStyle.fill;

    final checkBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6);
    paint.color = checkBg;
    
    for (int i = 0; i < 3; i++) {
      paint.color = checkBg;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(30, 20.0 + (i * 45), size.width - 60, 32),
          const Radius.circular(8),
        ),
        paint,
      );

      paint.color = i < 2 ? secondaryEmerald : Colors.grey.withOpacity(0.3);
      canvas.drawCircle(Offset(50, 36.0 + (i * 45)), 10, paint);

      if (i < 2) {
        final checkPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(46, 36.0 + (i * 45)), Offset(49, 39.0 + (i * 45)), checkPaint);
        canvas.drawLine(Offset(49, 39.0 + (i * 45)), Offset(55, 33.0 + (i * 45)), checkPaint);
      }

      paint.color = isDark ? Colors.white38 : Colors.black26;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(75, 32.0 + (i * 45), size.width - 150, 8),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class InteractiveSliderButton extends StatefulWidget {
  final VoidCallback onTrigger;
  final bool isDark;
  const InteractiveSliderButton({super.key, required this.onTrigger, required this.isDark});

  @override
  State<InteractiveSliderButton> createState() => _InteractiveSliderButtonState();
}

class _InteractiveSliderButtonState extends State<InteractiveSliderButton> {
  double _dragValue = 0.0;
  final double _buttonHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    final yellowBg = const Color(0xFFFACC15);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double maxDrag = maxWidth - _buttonHeight;

        return Container(
          height: _buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: yellowBg,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: yellowBg.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                left: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.lock_open_rounded, color: Colors.black54, size: 22),
                ),
              ),

              const Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Icon(Icons.lock_rounded, color: Colors.black54, size: 22),
                ),
              ),

              Center(
                child: Opacity(
                  opacity: (1.0 - (_dragValue / maxDrag)).clamp(0.2, 1.0),
                  child: const Text(
                    'Get Started  >>>',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: _dragValue,
                top: 3,
                bottom: 3,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragValue += details.delta.dx;
                      if (_dragValue < 0) _dragValue = 0;
                      if (_dragValue > maxDrag) _dragValue = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragValue >= maxDrag * 0.85) {
                      setState(() {
                        _dragValue = maxDrag;
                      });
                      widget.onTrigger();
                    } else {
                      setState(() {
                        _dragValue = 0.0;
                      });
                    }
                  },
                  child: Container(
                    width: _buttonHeight - 6,
                    height: _buttonHeight - 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
