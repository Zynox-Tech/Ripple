import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/widgets/ripple_video_player.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage>
    with TickerProviderStateMixin {
  int _activeStep = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  // ── Interactive phone tour ──
  int _tourSlide = 0;
  bool _isTourPlaying = false;
  double _tourProgress = 0.0;
  Timer? _tourTimer;
  late final AnimationController _slideController;
  late final Animation<double> _slideAnim;
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  static const _steps = [
    (
      icon: Icons.app_registration_rounded,
      color: Color(0xFF6366F1),
      title: 'Create Your Profile',
      body:
          'Sign up and tell us about your children — their school, grade, and which school you\'d prefer. It takes under 2 minutes.',
    ),
    (
      icon: Icons.travel_explore_rounded,
      color: Color(0xFF10B981),
      title: 'We Find Your Matches',
      body:
          'Ripple\'s algorithm scans nearby families whose swap request mirrors yours. A perfect match means both children move to each other\'s school.',
    ),
    (
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFFF59E0B),
      title: 'Chat & Coordinate',
      body:
          'Once matched, open a private chat workspace. Share schedules, discuss routes, and co-ordinate the school run — all in the app.',
    ),
    (
      icon: Icons.check_circle_rounded,
      color: Color(0xFF3B82F6),
      title: 'Complete the Swap',
      body:
          'Both families submit the mutual transfer request to their respective councils. Ripple helps you track progress and celebrate the move.',
    ),
  ];

  static const _stats = [
    ('92%', 'Match success\nrate'),
    ('3 days', 'Average time\nto first match'),
    ('4,200+', 'Families\nconnected'),
    ('£0', 'Cost to\nget started'),
  ];

  // Simulated phone screens for the tour
  static const _tourSlides = [
    (
      label: 'Step 1',
      title: 'Profile Setup',
      subtitle: 'Enter your details & children info',
      icon: Icons.person_add_rounded,
      color: Color(0xFF6366F1),
      detail: 'Sarah M. • Westminster • London',
      badge: 'Year 5 • Harris Academy',
    ),
    (
      label: 'Step 2',
      title: 'Finding Matches',
      subtitle: 'Scanning 4,200+ active families...',
      icon: Icons.travel_explore_rounded,
      color: Color(0xFF10B981),
      detail: '3 perfect matches found nearby!',
      badge: '95% compatibility',
    ),
    (
      label: 'Step 3',
      title: 'Chat Workspace',
      subtitle: 'Coordinate the school swap',
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFFF59E0B),
      detail: '"Hi Emma! Great match — let\'s discuss!"',
      badge: 'Transfer form submitted ✓',
    ),
    (
      label: 'Step 4',
      title: 'Swap Confirmed!',
      subtitle: 'Both councils approved the transfer',
      icon: Icons.celebration_rounded,
      color: Color(0xFF3B82F6),
      detail: '🎉 Congratulations — swap complete!',
      badge: '£800+ fuel saved/year',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.96, end: 1.04).animate(_pulseController);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tourTimer?.cancel();
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startTour() {
    _tourTimer?.cancel();
    setState(() {
      _isTourPlaying = true;
      _tourProgress = 0.0;
      _tourSlide = 0;
    });
    _slideController.forward(from: 0);

    _tourTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _tourProgress += 0.004; // ~20s for full tour
        // Each slide gets 25% of progress
        final newSlide = (_tourProgress * 4).floor().clamp(0, 3);
        if (newSlide != _tourSlide) {
          _tourSlide = newSlide;
          _slideController.forward(from: 0);
        }
        if (_tourProgress >= 1.0) {
          _tourProgress = 1.0;
          _isTourPlaying = false;
          timer.cancel();
        }
      });
    });
  }

  void _pauseTour() {
    _tourTimer?.cancel();
    setState(() => _isTourPlaying = false);
  }

  void _restartTour() {
    _tourTimer?.cancel();
    setState(() {
      _isTourPlaying = false;
      _tourProgress = 0.0;
      _tourSlide = 0;
    });
    _slideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('How It Works'),
          backgroundColor: Colors.transparent,
          actions: [
            TextButton.icon(
              onPressed: () => context.push('/plans'),
              icon: const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
              label: const Text(
                'Get Plus',
                style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Video Player ──
              const RippleVideoPlayer(videoPath: 'assets/videos/how_it_works.mp4'),

              const SizedBox(height: 20),

              // ── Hero banner ──
              _buildHeroBanner(context, isDark, primaryColor),

              const SizedBox(height: 28),

              // ── Stats row ──
              _buildStatsRow(isDark, primaryColor),

              const SizedBox(height: 28),

              // ── Step-by-step guide ──
              Text(
                'Step-by-Step Guide',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _buildStepper(context, isDark, primaryColor),

              const SizedBox(height: 28),

              // ── Interactive Phone Mockup App Tour ──
              _buildPhoneMockupTour(context, isDark, primaryColor),

              const SizedBox(height: 28),

              // ── FAQ ──
              Text(
                'Frequently Asked Questions',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _buildFaq(isDark, primaryColor),

              const SizedBox(height: 28),

              // ── CTA ──
              SizedBox(
                width: double.infinity,
                child: RippleButton(
                  text: 'Find My Matches Now',
                  onPressed: () => context.go('/matches'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, bool isDark, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.85),
            primaryColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'School swaps,\nsimplified.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ripple connects parents who want to swap school places — so every child ends up closer to home.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push('/setup'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text(
                    'Set Up My Profile →',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.18),
              ),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: Colors.white, size: 44),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color primaryColor) {
    return Row(
      children: _stats.map((s) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text(
                  s.$1,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStepper(BuildContext context, bool isDark, Color primaryColor) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isActive = _activeStep == i;
        final isDone = _activeStep > i;

        return GestureDetector(
          onTap: () => setState(() => _activeStep = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? step.color.withOpacity(0.1)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? step.color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : step.color.withOpacity(0.14),
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : step.icon,
                          color: isDone ? const Color(0xFF10B981) : step.color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Step ${i + 1}: ${step.title}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isActive
                                ? step.color
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ),
                      Icon(
                        isActive
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (isActive)
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(74, 0, 16, 16),
                    child: Text(
                      step.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPhoneMockupTour(BuildContext context, bool isDark, Color primaryColor) {
    final slide = _tourSlides[_tourSlide];
    final isComplete = _tourProgress >= 1.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone_iphone_rounded, color: Colors.amber, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interactive App Tour',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      Text(
                        'See Ripple in action — step by step',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isComplete ? '🎉 Done' : 'Live Demo',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Phone Mockup + Slide labels row
                Row(
                  children: [
                    // Slide step labels (left sidebar)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_tourSlides.length, (i) {
                        final isActive = i == _tourSlide;
                        final isDone = _tourProgress > (i + 1) / 4;
                        final sc = _tourSlides[i];
                        return GestureDetector(
                          onTap: () {
                            _pauseTour();
                            setState(() {
                              _tourSlide = i;
                              _tourProgress = i / 4.0;
                            });
                            _slideController.forward(from: 0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? sc.color.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isActive ? sc.color : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDone && !isActive
                                      ? Icons.check_circle_rounded
                                      : sc.icon,
                                  size: 14,
                                  color: isDone && !isActive
                                      ? const Color(0xFF10B981)
                                      : isActive ? sc.color : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sc.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? sc.color : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 12),

                    // Phone mockup
                    Expanded(
                      child: Center(
                        child: _buildPhoneMockup(isDark, primaryColor, slide),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _tourProgress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete ? const Color(0xFF10B981) : primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Controls row
                Row(
                  children: [
                    // Restart button
                    IconButton(
                      onPressed: _restartTour,
                      icon: const Icon(Icons.replay_rounded, size: 20),
                      color: Colors.grey,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.withOpacity(0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Play / Pause button
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: isComplete
                              ? _restartTour
                              : (_isTourPlaying ? _pauseTour : _startTour),
                          icon: Icon(
                            isComplete
                                ? Icons.replay_rounded
                                : (_isTourPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            size: 18,
                            color: Colors.black,
                          ),
                          label: Text(
                            isComplete
                                ? 'Watch Again'
                                : (_isTourPlaying ? 'Pause Tour' : (_tourProgress > 0 ? 'Resume' : 'Play App Tour')),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isComplete
                                ? const Color(0xFF10B981)
                                : primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Skip to end (if not done)
                    if (!isComplete)
                      IconButton(
                        onPressed: () {
                          _tourTimer?.cancel();
                          setState(() {
                            _tourProgress = 1.0;
                            _tourSlide = 3;
                            _isTourPlaying = false;
                          });
                          _slideController.forward(from: 0);
                        },
                        icon: const Icon(Icons.skip_next_rounded, size: 20),
                        color: Colors.grey,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),

                if (isComplete) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tour complete! Ready to start your school swap journey?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/setup'),
                          child: const Text(
                            'Start →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneMockup(bool isDark, Color primaryColor, dynamic slide) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          width: 160,
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: slide.color.withOpacity(_glowAnim.value * 0.6),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: slide.color.withOpacity(_glowAnim.value * 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Column(
          children: [
            // Phone notch area
            Container(
              height: 24,
              color: const Color(0xFF0F172A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),

            // Screen content with slide animation
            Expanded(
              child: FadeTransition(
                opacity: _slideAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(_slideAnim),
                  child: _buildPhoneScreenContent(slide),
                ),
              ),
            ),

            // Home indicator
            Container(
              height: 20,
              color: const Color(0xFF0F172A),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneScreenContent(dynamic slide) {
    final isComplete = _tourProgress >= 1.0;

    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar area
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            color: slide.color.withOpacity(0.15),
            child: Row(
              children: [
                Icon(slide.icon, size: 12, color: slide.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    slide.title,
                    style: TextStyle(
                      color: slide.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Simulated app UI cards
                  if (_tourSlide == 0) ...[
                    _phoneCard(icon: Icons.person_rounded, text: 'Sarah Mitchell', color: const Color(0xFF6366F1)),
                    const SizedBox(height: 6),
                    _phoneCard(icon: Icons.location_on_rounded, text: 'Westminster, London', color: Colors.teal),
                    const SizedBox(height: 6),
                    _phoneCard(icon: Icons.school_rounded, text: 'Harris Academy • Yr 5', color: Colors.orange),
                  ] else if (_tourSlide == 1) ...[
                    _matchCard('Emma W.', '95%', const Color(0xFF10B981)),
                    const SizedBox(height: 5),
                    _matchCard('George B.', '80%', const Color(0xFF3B82F6)),
                    const SizedBox(height: 5),
                    _matchCard('Sophie D.', '75%', Colors.purple),
                  ] else if (_tourSlide == 2) ...[
                    _bubbleChat('Hi! Great 95% match! 🎉', true),
                    const SizedBox(height: 5),
                    _bubbleChat('Let\'s coordinate forms!', false),
                    const SizedBox(height: 5),
                    _checklistTile('Transfer Form', true),
                  ] else ...[
                    // Completion screen
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.celebration_rounded,
                              color: Color(0xFF10B981), size: 36),
                          SizedBox(height: 6),
                          Text(
                            'Swap\nConfirmed!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom badge
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: slide.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: slide.color.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, size: 10, color: slide.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    slide.badge,
                    style: TextStyle(
                      fontSize: 8.5,
                      color: slide.color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneCard({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(String name, String pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(pct, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _bubbleChat(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF14B8A6) : Colors.white12,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8),
            bottomLeft: isMe ? const Radius.circular(8) : const Radius.circular(2),
            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 8.5),
        ),
      ),
    );
  }

  Widget _checklistTile(String label, bool checked) {
    return Row(
      children: [
        Icon(
          checked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
          size: 12,
          color: checked ? const Color(0xFF10B981) : Colors.grey,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: checked ? Colors.white60 : Colors.white70,
              fontSize: 9,
              decoration: checked ? TextDecoration.lineThrough : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFaq(bool isDark, Color primaryColor) {
    const faqs = [
      (
        q: 'Is Ripple free to use?',
        a: 'Yes — finding and matching with families is completely free. Premium features like advanced analytics are optional.',
      ),
      (
        q: 'Do both families have to apply to the council?',
        a: 'Yes. Ripple coordinates you so both families submit their mutual transfer at the same time, which significantly increases approval rates.',
      ),
      (
        q: 'What happens if our swap falls through?',
        a: 'Ripple keeps your profile active and shows you new matches automatically. You can run multiple conversations simultaneously.',
      ),
      (
        q: 'Is my personal data safe?',
        a: 'Absolutely. Your exact home address is never shared with other users — only your general area (e.g. Westminster) is visible.',
      ),
    ];

    return Column(
      children: faqs.map((faq) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding:
                const EdgeInsets.fromLTRB(16, 0, 16, 14),
            title: Text(faq.q,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            iconColor: primaryColor,
            collapsedIconColor: Colors.grey,
            children: [
              Text(faq.a,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? Colors.white60 : Colors.black54)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
