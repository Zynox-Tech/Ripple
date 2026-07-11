import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/repository_providers.dart';


class MatchDetailPage extends ConsumerStatefulWidget {
  final String matchId;
  const MatchDetailPage({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _RippleMapPainter extends CustomPainter {
  final bool isDark;
  _RippleMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // Draw grid
    const step = 25;
    for (int i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
    }
    for (int i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }

    // Zones
    final paintZone = Paint()
      ..color = const Color(0xFFFACC15).withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 45, paintZone);

    // Roads
    final roadPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), roadPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MatchDetailPageState extends ConsumerState<MatchDetailPage> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;

    final authRepo = ref.watch(authRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);
    final matchesRepo = ref.watch(matchesRepositoryProvider);
    final schoolsRepo = ref.watch(schoolRepositoryProvider);

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Swap Verification'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => context.pop(),
          ),
        ),
        body: FutureBuilder<RippleUser?>(
          future: authRepo.getCurrentUser(),
          builder: (context, userSnapshot) {
            final currentUser = userSnapshot.data;
            if (currentUser == null) return const Center(child: CircularProgressIndicator());
            return FutureBuilder<MatchModel?>(
              future: matchesRepo.getMatchDetails(widget.matchId),
              builder: (context, matchSnapshot) {
                final match = matchSnapshot.data;
                if (match == null) {
                  if (matchSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const Center(child: Text('Match details not found.'));
                }
                return FutureBuilder<RippleUser?>(
                  future: userRepo.getUserProfile(match.familyB_uid),
                  builder: (context, partnerSnapshot) {
                    final partner = partnerSnapshot.data;
                    if (partner == null) return const SizedBox.shrink();
                    return FutureBuilder<List<Child>>(
                      future: userRepo.getChildren(currentUser.uid),
                      builder: (context, myChildrenSnapshot) {
                        final myChildren = myChildrenSnapshot.data ?? [];
                        if (myChildren.isEmpty) return const SizedBox.shrink();
                        final childA = myChildren.first;
                        return FutureBuilder<List<Child>>(
                          future: userRepo.getChildren(partner.uid),
                          builder: (context, partnerChildrenSnapshot) {
                            final partnerChildren = partnerChildrenSnapshot.data ?? [];
                            if (partnerChildren.isEmpty) return const SizedBox.shrink();
                            final childB = partnerChildren.first;
                            return FutureBuilder<List<School>>(
                              future: schoolsRepo.getSchools(),
                              builder: (context, schoolsSnapshot) {
                                final schools = schoolsSnapshot.data ?? [];
                                if (schools.isEmpty) return const SizedBox.shrink();
                                final schoolA = schools.firstWhere((s) => s.schoolId == childA.currentSchoolId, orElse: () => schools.first);
                                final schoolB = schools.firstWhere((s) => s.schoolId == childB.currentSchoolId, orElse: () => schools.first);

                                double distFit = 40.0;
                                double grMatch = 30.0;
                                double timeReady = 20.0;
                                double profileComp = 10.0;
                                if (match.compatibilityScore < 90) {
                                  grMatch = 15.0; // adjacent grade
                                }

                                return SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // 1. Profile Card Header
                                      RippleCard(
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 28,
                                              backgroundImage: getRippleImageProvider(partner.photoURL),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        partner.displayName.split(' ').first,
                                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                                      ),
                                                      if (partner.verified) ...[
                                                        const SizedBox(width: 6),
                                                        const VerifiedBadge(size: 16),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    'Seeking grade: ${childB.gradeYear}',
                                                    style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.15),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                                              ),
                                              child: Text(
                                                '${match.compatibilityScore.toInt()}%',
                                                style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // 2. School Swap Diagram
                                      const Text(
                                        'Proposed Swap Flow',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 8),
                                      RippleCard(
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('YOUR CHILD CURRENTLY AT', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 4),
                                                      Text(schoolA.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                      Text(schoolA.area, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.1)),
                                                  child: Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 20),
                                                ),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      const Text('SWAP TO ENROLL AT', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                      const SizedBox(height: 4),
                                                      Text(schoolB.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                                                      Text(schoolB.area, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.right),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 12.0),
                                              child: Divider(color: Colors.white10),
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Text('Total Daily Commute Saved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                                Text(
                                                  '${match.distanceKm.toStringAsFixed(1)} miles',
                                                  style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor, fontSize: 15),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // 3. Map View
                                      const Text(
                                        'Visual Route Swap Map',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 8),
                                      RippleCard(
                                        padding: EdgeInsets.zero,
                                        child: RippleMapView(
                                          height: 180,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // 4. Compatibility Breakdown
                                      const Text(
                                        'Compatibility Score Breakdown',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 8),
                                      RippleCard(
                                        child: Column(
                                          children: [
                                            _buildScoreRow('Catchment Distance Fit', distFit.toInt(), 40, primaryColor, isDark),
                                            const Divider(height: 16, color: Colors.white10),
                                            _buildScoreRow('Grade Level Sync', grMatch.toInt(), 30, primaryColor, isDark),
                                            const Divider(height: 16, color: Colors.white10),
                                            _buildScoreRow('Timing & Transfer Readiness', timeReady.toInt(), 20, primaryColor, isDark),
                                            const Divider(height: 16, color: Colors.white10),
                                            _buildScoreRow('Profile Verification Rate', profileComp.toInt(), 10, primaryColor, isDark),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      // Disclaimer Text box
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          l10n.translate('disclaimer'),
                                          style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 30),

                                      // 5. Connect / Message Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            if (match.status == 'connected') {
                                              context.push('/chats/chat_${match.matchId}');
                                            } else {
                                              setState(() => _isConnecting = true);
                                              try {
                                                await matchesRepo.updateMatchStatus(match.matchId, 'connected');
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.translate('chat_connected'))));
                                                  context.go('/chats/chat_${match.matchId}');
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error connecting: $e')));
                                                }
                                              } finally {
                                                if (mounted) setState(() => _isConnecting = false);
                                              }
                                            }
                                          },
                                          icon: Icon(match.status == 'connected' ? Icons.chat_bubble_rounded : Icons.handshake_rounded),
                                          label: _isConnecting
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                                )
                                              : Text(
                                                  match.status == 'connected' ? 'Open Chat Workspace' : 'Send Swap Request',
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                                ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationPin(String area, {required bool isUser}) {
    final color = isUser ? Theme.of(context).primaryColor : const Color(0xFF3B82F6);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
          child: Text(area, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        Icon(Icons.location_on, color: color, size: 20),
      ],
    );
  }

  Widget _buildScoreRow(String label, int val, int max, Color progressColor, bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val / max,
              minHeight: 5,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$val/$max',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        ),
      ],
    );
  }
}
