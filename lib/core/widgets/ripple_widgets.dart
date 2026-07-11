import 'dart:math' as math;
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/l10n/app_localizations.dart';

// Animated concentric ripple logo
class RippleLogo extends StatefulWidget {
  final double size;
  final Color? color;
  const RippleLogo({super.key, this.size = 120, this.color});

  @override
  State<RippleLogo> createState() => _RippleLogoState();
}

class _RippleLogoState extends State<RippleLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rippleColor = widget.color ?? Theme.of(context).primaryColor;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Offset the animations of the ripples
              double progress = (_controller.value + (index / 3.0)) % 1.0;
              double scale = progress * 1.3 + 0.3;
              double opacity = (1.0 - progress) * 0.7;
              
              if (progress < 0.1) {
                opacity = progress * 7.0 * 0.7; // Fade in at beginning
              }

              return Container(
                width: widget.size,
                height: widget.size,
                transform: Matrix4.identity()..scale(scale, scale),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: rippleColor.withOpacity(opacity),
                    width: 2.0,
                  ),
                ),
              );
            },
          );
        })..add(
          // Center Core Logo Circle
          Container(
            width: widget.size * 0.45,
            height: widget.size * 0.45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rippleColor,
              boxShadow: [
                BoxShadow(
                  color: rippleColor.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
            child: const Icon(
              Icons.waves,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// Glassmorphic Card
class RippleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final List<Color>? gradientColors;
  final VoidCallback? onTap;

  const RippleCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.gradientColors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: borderColor ?? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
          width: 1.2,
        ),
        gradient: gradientColors != null 
            ? LinearGradient(
                colors: gradientColors!,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.04),
                        Colors.white.withOpacity(0.01),
                      ]
                    : [
                        Colors.white.withOpacity(0.85),
                        Colors.white.withOpacity(0.95),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: content,
        ),
      );
    }
    return content;
  }
}

// Custom Styled Button with dynamic gradient
class RippleButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isLoading;

  const RippleButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    if (isSecondary) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: primaryColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            primaryColor,
            const Color(0xFF00BFA5), // Vibrant Emerald Teal
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Verified Badge Widget
class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueAccent,
      ),
      child: Icon(
        Icons.verified,
        color: Colors.white,
        size: size,
      ),
    );
  }
}

// RtlSupport helper that automatically alignments content
class RtlSupport extends StatelessWidget {
  final Widget child;
  const RtlSupport({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textDir = l10n?.textDirection ?? TextDirection.ltr;
    
    return Directionality(
      textDirection: textDir,
      child: child,
    );
  }
}

// Dynamically retrieves the correct image provider for network, local file, or asset paths.
ImageProvider getRippleImageProvider(String pathOrUrl) {
  if (pathOrUrl.isEmpty) {
    return const NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150');
  }
  if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
    return NetworkImage(pathOrUrl);
  } else if (pathOrUrl.startsWith('assets/')) {
    return AssetImage(pathOrUrl);
  } else {
    // Local file path – only valid on native platforms
    if (!kIsWeb) {
      try {
        final file = io.File(pathOrUrl);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }
    // Fallback: return default avatar
    return const NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150');
  }
}

// ─── RippleMapView ──────────────────────────────────────────────────────────
// A resilient map widget. On web or when Google Maps fails, falls back to a
// beautiful hand-drawn CustomPaint vector map of London/Westminster.
class RippleMapView extends StatefulWidget {
  final double? height;
  final VoidCallback? onTap;
  final List<_MapMarkerData> markers;

  const RippleMapView({
    super.key,
    this.height,
    this.onTap,
    this.markers = const [],
  });

  @override
  State<RippleMapView> createState() => _RippleMapViewState();
}

class _MapMarkerData {
  final double lat;
  final double lng;
  final String label;
  final Color color;

  const _MapMarkerData({
    required this.lat,
    required this.lng,
    required this.label,
    this.color = Colors.redAccent,
  });
}

class _RippleMapViewState extends State<RippleMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.3).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final height = widget.height ?? 220.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: height,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _LondonMapPainter(
                  isDark: isDark,
                  primaryColor: primaryColor,
                  pulseScale: _pulseAnim.value,
                  markers: widget.markers,
                ),
                child: child,
              );
            },
            child: Stack(
              children: [
                // Map label
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.6)
                          : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded,
                            color: const Color(0xFF00BFA5), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'London, UK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tap hint
                if (widget.onTap != null)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.6)
                            : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Text(
                        'Tap to explore',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LondonMapPainter extends CustomPainter {
  final bool isDark;
  final Color primaryColor;
  final double pulseScale;
  final List<_MapMarkerData> markers;

  _LondonMapPainter({
    required this.isDark,
    required this.primaryColor,
    required this.pulseScale,
    required this.markers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F4EA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bgColor);

    // Grid lines (subtle)
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Thames river (sinuous blue ribbon)
    final thamesPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.55)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.cubicTo(
      size.width * 0.25, size.height * 0.62,
      size.width * 0.5,  size.height * 0.68,
      size.width * 0.75, size.height * 0.60,
    );
    path.cubicTo(
      size.width * 0.85, size.height * 0.55,
      size.width * 0.95, size.height * 0.58,
      size.width,        size.height * 0.55,
    );
    canvas.drawPath(path, thamesPaint);

    // Thames label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'River Thames',
        style: TextStyle(
          color: const Color(0xFF3B82F6).withOpacity(0.8),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    canvas.save();
    canvas.translate(size.width * 0.3, size.height * 0.67);
    canvas.rotate(-0.05);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();

    // Major roads
    final roadPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey.shade700).withOpacity(0.18)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Horizontal arterial roads
    _drawRoad(canvas, size, roadPaint, 0, 0.3, 1.0, 0.28);
    _drawRoad(canvas, size, roadPaint, 0, 0.5, 1.0, 0.48);
    // Vertical roads
    _drawRoad(canvas, size, roadPaint, 0.3, 0.0, 0.32, 1.0);
    _drawRoad(canvas, size, roadPaint, 0.6, 0.0, 0.62, 1.0);

    // Parks (green blobs)
    final parkPaint = Paint()..color = const Color(0xFF34D399).withOpacity(0.30);
    // Hyde Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width * 0.22, size.height * 0.35),
            width: size.width * 0.16,
            height: size.height * 0.22),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    // Regent's Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width * 0.42, size.height * 0.20),
            width: size.width * 0.12,
            height: size.height * 0.18),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    // Greenwich
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(size.width * 0.75, size.height * 0.40),
            width: size.width * 0.10,
            height: size.height * 0.14),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // Match markers (pulsing dots)
    final matchPositions = [
      Offset(size.width * 0.35, size.height * 0.38),
      Offset(size.width * 0.55, size.height * 0.30),
      Offset(size.width * 0.70, size.height * 0.50),
    ];

    final colors = [
      primaryColor,
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
    ];

    for (int i = 0; i < matchPositions.length; i++) {
      final pos = matchPositions[i];
      final col = colors[i % colors.length];

      // Pulsing ring
      canvas.drawCircle(
        pos,
        (14 * pulseScale).clamp(8.0, 20.0),
        Paint()..color = col.withOpacity(0.25),
      );
      // Outer ring
      canvas.drawCircle(
        pos,
        9,
        Paint()..color = col.withOpacity(0.45),
      );
      // Inner dot
      canvas.drawCircle(
        pos,
        5,
        Paint()..color = col,
      );
      // White center
      canvas.drawCircle(
        pos,
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  void _drawRoad(Canvas canvas, Size size, Paint paint,
      double x1f, double y1f, double x2f, double y2f) {
    canvas.drawLine(
      Offset(size.width * x1f, size.height * y1f),
      Offset(size.width * x2f, size.height * y2f),
      paint,
    );
  }

  @override
  bool shouldRepaint(_LondonMapPainter old) =>
      old.pulseScale != pulseScale || old.isDark != isDark;
}
