import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_config.dart';
import '../../../config/theme.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/repositories/mock_repository.dart';
import '../../auth/presentation/auth_page.dart';

class MatchesPage extends ConsumerStatefulWidget {
  const MatchesPage({super.key});

  @override
  ConsumerState<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends ConsumerState<MatchesPage> {
  String _selectedFilterGrade = 'All';
  String _sortBy = 'Score'; // Score / Distance
  String _viewMode = 'List'; // List / Map / Game

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          title: const Text('Families Near You'),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: Icon(Icons.list_rounded, color: _viewMode == 'List' ? primaryColor : Colors.grey, size: 22),
              onPressed: () => setState(() => _viewMode = 'List'),
              tooltip: 'List View',
            ),
            IconButton(
              icon: Icon(Icons.map_rounded, color: _viewMode == 'Map' ? primaryColor : Colors.grey, size: 22),
              onPressed: () => setState(() => _viewMode = 'Map'),
              tooltip: 'Map View',
            ),
            IconButton(
              icon: Icon(Icons.bolt_rounded, color: _viewMode == 'Game' ? primaryColor : Colors.grey, size: 22),
              onPressed: () => setState(() => _viewMode = 'Game'),
              tooltip: 'Swipe Game',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Map preview (only in Map viewMode)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _viewMode == 'Map'
                  ? const SizedBox(
                      height: 200,
                      child: RippleMapView(
                        height: 200,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            Expanded(
              child: _viewMode == 'Game'
                  ? SwipeGameView(
                      primaryColor: primaryColor,
                      isDark: isDark,
                      ref: ref,
                    )
                  : FutureBuilder<RippleUser?>(
          future: authRepo.getCurrentUser(),
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final isPremium = user.subscriptionTier != 'free';

            return FutureBuilder<List<MatchModel>>(
              future: matchesRepo.getMatchesForUser(user.uid),
              builder: (context, matchesSnapshot) {
                final matches = matchesSnapshot.data ?? [];
                if (matchesSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FutureBuilder<List<School>>(
                  future: schoolsRepo.getSchools(),
                  builder: (context, schoolsSnapshot) {
                    final schools = schoolsSnapshot.data ?? [];
                    
                    // Filter and sort matches logic
                    List<MatchModel> filteredMatches = List.from(matches);
                    
                    // Filter by Grade if not All
                    if (_selectedFilterGrade != 'All') {
                      // Filter matches where child grade matches selected
                      // For simulated purposes, we'll keep the full list or filter
                    }

                    // Sort matches
                    if (_sortBy == 'Score') {
                      filteredMatches.sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
                    } else {
                      filteredMatches.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
                    }

                    return Column(
                      children: [
                        // Filter Bar / Sort Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Filter Grade pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedFilterGrade,
                                  dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  underline: const SizedBox.shrink(),
                                  icon: Icon(Icons.arrow_drop_down, color: primaryColor),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  items: ['All', 'Year 4', 'Year 5', 'Year 6'].map((g) {
                                    return DropdownMenuItem(value: g, child: Text(g));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedFilterGrade = val);
                                    }
                                  },
                                ),
                              ),

                              // Sort options chips
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('Match Score', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    selected: _sortBy == 'Score',
                                    selectedColor: primaryColor,
                                    backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onSelected: (val) {
                                      if (val) setState(() => _sortBy = 'Score');
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Distance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    selected: _sortBy == 'Distance',
                                    selectedColor: primaryColor,
                                    backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    onSelected: (val) {
                                      if (val) setState(() => _sortBy = 'Distance');
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Match Cards List
                        Expanded(
                          child: filteredMatches.isEmpty
                              ? const Center(child: Text('No matches found.'))
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0), // Padding for navigation bar
                                  itemCount: filteredMatches.length,
                                  itemBuilder: (context, index) {
                                    final match = filteredMatches[index];
                                    
                                    // Lock logic: first match free, rest locked
                                    final isMatchLocked = !isPremium && (index > 0);

                                    return FutureBuilder<RippleUser?>(
                                      future: userRepo.getUserProfile(match.familyB_uid),
                                      builder: (context, partnerSnapshot) {
                                        final partner = partnerSnapshot.data;
                                        if (partner == null) return const SizedBox.shrink();

                                        return FutureBuilder<List<Child>>(
                                          future: userRepo.getChildren(partner.uid),
                                          builder: (context, childrenSnapshot) {
                                            final partnerChildren = childrenSnapshot.data ?? [];
                                            if (partnerChildren.isEmpty) return const SizedBox.shrink();
                                            final childB = partnerChildren.first;

                                            return FutureBuilder<List<Child>>(
                                              future: userRepo.getChildren(user.uid),
                                              builder: (context, myChildrenSnapshot) {
                                                final myChildren = myChildrenSnapshot.data ?? [];
                                                if (myChildren.isEmpty) return const SizedBox.shrink();
                                                final childA = myChildren.first;

                                                final schoolA = schools.firstWhere((s) => s.schoolId == childA.currentSchoolId, orElse: () => schools.first);
                                                final schoolB = schools.firstWhere((s) => s.schoolId == childB.currentSchoolId, orElse: () => schools.first);

                                                return _buildMatchCard(
                                                  context,
                                                  match: match,
                                                  partnerName: partner.displayName,
                                                  partnerArea: partner.area,
                                                  childGrade: childB.gradeYear,
                                                  schoolAName: schoolA.name,
                                                  schoolBName: schoolB.name,
                                                  isLocked: isMatchLocked,
                                                  primaryColor: primaryColor,
                                                  isDark: isDark,
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
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(
    BuildContext context, {
    required MatchModel match,
    required String partnerName,
    required String partnerArea,
    required String childGrade,
    required String schoolAName,
    required String schoolBName,
    required bool isLocked,
    required Color primaryColor,
    required bool isDark,
  }) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compatibility Score & Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  partnerName.split(' ').first,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    childGrade,
                    style: const TextStyle(fontSize: 10, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${match.compatibilityScore.toInt()}%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Visual Swap Diagram (School A <-> School B)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('STUDIES AT', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(schoolBName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.swap_horiz_rounded, color: primaryColor, size: 22),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('WANTS SCHOOL', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(schoolAName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Distance & Location Footer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(partnerArea, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Text(
              '${match.distanceKm.toStringAsFixed(1)} miles away',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
        if (match.status == 'connected') ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/matches/${match.matchId}'),
                icon: const Icon(Icons.info_outline_rounded, size: 14),
                label: const Text('Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final useMock = ref.read(mockModeProvider);
                  final String resolvedChatId = useMock 
                      ? 'chat_${match.matchId}' 
                      : 'chat_match_${match.familyA_uid}_emma';
                  context.push('/chats/$resolvedChatId');
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 14, color: Colors.black),
                label: const Text('Chat Workspace', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Underlying Card Layout
          RippleCard(
            onTap: isLocked ? null : () => context.push('/matches/${match.matchId}'),
            child: cardContent,
          ),
          
          // Locked overlay layer
          if (isLocked)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: const Color(0xFF0F172A).withOpacity(0.92), // Slate overlay
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_rounded, color: primaryColor, size: 24),
                      const SizedBox(height: 6),
                      const Text(
                        'Unlock Match Coordination',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Upgrade to Ripple Plus to connect with all active swap routes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, fontSize: 10),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => context.push('/plans'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: const Text('Upgrade Plan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SwipeGameView extends StatefulWidget {
  final Color primaryColor;
  final bool isDark;
  final WidgetRef ref;

  const SwipeGameView({
    super.key,
    required this.primaryColor,
    required this.isDark,
    required this.ref,
  });

  @override
  State<SwipeGameView> createState() => _SwipeGameViewState();
}

class _SwipeGameViewState extends State<SwipeGameView> with TickerProviderStateMixin {
  List<MatchModel> _pendingMatches = [];
  bool _loading = true;
  RippleUser? _currentUser;
  List<School> _schools = [];
  
  // Game state
  int _currentIndex = 0;
  double _cardXOffset = 0.0;
  double _cardAngle = 0.0;
  bool _animating = false;
  
  // Confetti / Match overlay state
  MatchModel? _currentMatchCeleb;
  RippleUser? _currentPartnerCeleb;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final authRepo = widget.ref.read(authRepositoryProvider);
    final matchesRepo = widget.ref.read(matchesRepositoryProvider);
    final schoolsRepo = widget.ref.read(schoolRepositoryProvider);

    final user = await authRepo.getCurrentUser();
    if (user != null) {
      final matches = await matchesRepo.getMatchesForUser(user.uid);
      final schools = await schoolsRepo.getSchools();
      setState(() {
        _currentUser = user;
        _schools = schools;
        // Only pending matches that are not connected/complete
        _pendingMatches = matches.where((m) => m.status == 'pending').toList();
        _currentIndex = 0;
        _loading = false;
      });
    }
  }

  void _swipe(bool liked) async {
    if (_currentIndex >= _pendingMatches.length || _animating) return;
    
    setState(() {
      _animating = true;
      _cardXOffset = liked ? 600.0 : -600.0;
      _cardAngle = liked ? 0.3 : -0.3;
    });

    await Future.delayed(const Duration(milliseconds: 350));
    
    final match = _pendingMatches[_currentIndex];
    
    if (liked) {
      // Connect match!
      final matchesRepo = widget.ref.read(matchesRepositoryProvider);
      await matchesRepo.updateMatchStatus(match.matchId, 'connected');
      
      // Load partner profile for celebration screen
      final userRepo = widget.ref.read(userRepositoryProvider);
      final partner = await userRepo.getUserProfile(match.familyB_uid);
      
      // Trigger celebration overlay!
      setState(() {
        _currentMatchCeleb = match;
        _currentPartnerCeleb = partner;
      });
    }

    if (mounted) {
      setState(() {
        _currentIndex++;
        _cardXOffset = 0.0;
        _cardAngle = 0.0;
        _animating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_currentUser == null) {
      return const Center(child: Text("Please log in to play."));
    }

    final hasCards = _currentIndex < _pendingMatches.length;

    return Stack(
      children: [
        // Main game area
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasCards) ...[
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Under card (if available)
                      if (_currentIndex + 1 < _pendingMatches.length)
                        Opacity(
                          opacity: 0.6,
                          child: Transform.scale(
                            scale: 0.95,
                            child: _buildCard(_pendingMatches[_currentIndex + 1]),
                          ),
                        ),
                      
                      // Top card (active)
                      GestureDetector(
                        onPanUpdate: (details) {
                          if (_animating) return;
                          setState(() {
                            _cardXOffset += details.delta.dx;
                            _cardAngle = _cardXOffset / 1000;
                          });
                        },
                        onPanEnd: (details) {
                          if (_animating) return;
                          if (_cardXOffset > 120) {
                            _swipe(true);
                          } else if (_cardXOffset < -120) {
                            _swipe(false);
                          } else {
                            setState(() {
                              _cardXOffset = 0.0;
                              _cardAngle = 0.0;
                            });
                          }
                        },
                        child: AnimatedContainer(
                          duration: _animating ? const Duration(milliseconds: 300) : Duration.zero,
                          curve: Curves.easeOut,
                          transform: Matrix4.translationValues(_cardXOffset, 0, 0)
                            ..rotateZ(_cardAngle),
                          child: _buildCard(_pendingMatches[_currentIndex]),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Swipe Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dislike Button
                    _buildActionButton(
                      icon: Icons.close_rounded,
                      color: Colors.redAccent,
                      onPressed: () => _swipe(false),
                    ),
                    const SizedBox(width: 28),
                    // Info Button
                    _buildActionButton(
                      icon: Icons.info_outline_rounded,
                      color: Colors.blueAccent,
                      onPressed: () {
                        if (_currentIndex < _pendingMatches.length) {
                          context.push('/matches/${_pendingMatches[_currentIndex].matchId}');
                        }
                      },
                      isSmall: true,
                    ),
                    const SizedBox(width: 28),
                    // Like Button
                    _buildActionButton(
                      icon: Icons.favorite_rounded,
                      color: const Color(0xFF10B981), // Emerald green
                      onPressed: () => _swipe(true),
                    ),
                  ],
                ),
              ] else ...[
                // Empty state / Reset
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.primaryColor.withOpacity(0.12),
                        ),
                        child: Icon(Icons.style_rounded, size: 64, color: widget.primaryColor),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'All Swept Clean! 🌊',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You have swiped on all pending families nearby. Check back later for new matches!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: widget.isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          // For testing/mocking, reset all matched states back to pending
                          setState(() => _loading = true);
                          final db = MockDatabase.instance;
                          for (int i = 0; i < db.matches.length; i++) {
                            if (db.matches[i].familyB_uid != 'user_emma') {
                              db.matches[i] = MatchModel(
                                matchId: db.matches[i].matchId,
                                familyA_uid: db.matches[i].familyA_uid,
                                familyB_uid: db.matches[i].familyB_uid,
                                childA_id: db.matches[i].childA_id,
                                childB_id: db.matches[i].childB_id,
                                compatibilityScore: db.matches[i].compatibilityScore,
                                distanceKm: db.matches[i].distanceKm,
                                status: 'pending',
                                createdAt: db.matches[i].createdAt,
                              );
                            }
                          }
                          await db.saveToPrefs();
                          widget.ref.invalidate(matchesRepositoryProvider);
                          await _loadGameData();
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Colors.black),
                        label: const Text('Reset Game & Play Again', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Celeb Match Overlay
        if (_currentMatchCeleb != null && _currentPartnerCeleb != null)
          _buildMatchCelebrationOverlay(),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isSmall = false,
  }) {
    final size = isSmall ? 48.0 : 64.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF1E293B), // Dark capsule fill
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: isSmall ? 22 : 28),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCard(MatchModel match) {
    final userRepo = widget.ref.read(userRepositoryProvider);
    
    return FutureBuilder<RippleUser?>(
      future: userRepo.getUserProfile(match.familyB_uid),
      builder: (context, userSnap) {
        final partner = userSnap.data;
        if (partner == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<Child>>(
          future: userRepo.getChildren(partner.uid),
          builder: (context, kidsSnap) {
            final kids = kidsSnap.data ?? [];
            if (kids.isEmpty) return const SizedBox.shrink();
            final childB = kids.first;

            return FutureBuilder<List<Child>>(
              future: userRepo.getChildren(_currentUser!.uid),
              builder: (context, myKidsSnap) {
                final myKids = myKidsSnap.data ?? [];
                if (myKids.isEmpty) return const SizedBox.shrink();
                final childA = myKids.first;

                final schoolA = _schools.firstWhere((s) => s.schoolId == childA.currentSchoolId, orElse: () => _schools.first);
                final schoolB = _schools.firstWhere((s) => s.schoolId == childB.currentSchoolId, orElse: () => _schools.first);

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B), // Dark Slate Card
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Image Area (60% Card Height)
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(
                                image: getRippleImageProvider(partner.photoURL),
                                fit: BoxFit.cover,
                              ),
                              // Gradient Overlay
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, Color(0xFF1E293B)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              // Top Right Match Tag
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [widget.primaryColor, const Color(0xFF00BFA5)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: widget.primaryColor.withOpacity(0.3),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt, color: Colors.black, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${match.compatibilityScore.toInt()}% Match',
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Left Swipe PASS badge / Right Swipe LIKE badge
                              if (_cardXOffset.abs() > 20)
                                Positioned(
                                  top: 30,
                                  left: _cardXOffset > 0 ? 16 : null,
                                  right: _cardXOffset < 0 ? 16 : null,
                                  child: Transform.rotate(
                                    angle: _cardXOffset > 0 ? -0.15 : 0.15,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _cardXOffset > 0 ? const Color(0xFF10B981) : Colors.redAccent,
                                          width: 3.0,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _cardXOffset > 0 ? 'CONNECT' : 'PASS',
                                        style: TextStyle(
                                          color: _cardXOffset > 0 ? const Color(0xFF10B981) : Colors.redAccent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                              // Partner Info
                              Positioned(
                                bottom: 16,
                                left: 20,
                                right: 20,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          partner.displayName,
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                        ),
                                        const SizedBox(width: 8),
                                        if (partner.verified)
                                          const VerifiedBadge(size: 16),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${partner.area}, ${partner.city} • ${match.distanceKm.toStringAsFixed(1)} miles away',
                                      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Swap Details (40% Card Height)
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'CHILD YEAR: ',
                                    style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    childB.gradeYear,
                                    style: TextStyle(color: widget.primaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Visual route connection diagram
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('STUDIES AT', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(schoolB.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: widget.primaryColor.withOpacity(0.12),
                                      ),
                                      child: Icon(Icons.swap_horiz_rounded, color: widget.primaryColor, size: 18),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('WANTS SCHOOL', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(schoolA.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMatchCelebrationOverlay() {
    final partner = _currentPartnerCeleb!;
    final match = _currentMatchCeleb!;
    
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.9),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti simulation or concentric pulsing waves
            CustomPaint(
              size: Size.infinite,
              painter: CommuteRoutePainter(isDark: true, color: widget.primaryColor),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RippleLogo(size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    "IT'S A MATCH! 🌊",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You and ${partner.displayName} are ready to swap!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40),
                  
                  // Double Avatar bubble layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Current User Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.primaryColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: widget.primaryColor.withOpacity(0.4),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: getRippleImageProvider(_currentUser?.photoURL ?? ''),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Connect swap icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF1E293B),
                        ),
                        child: Icon(Icons.swap_horiz_rounded, color: widget.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      // Partner Avatar
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00BFA5), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BFA5).withOpacity(0.4),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: getRippleImageProvider(partner.photoURL),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Go to Chat Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentMatchCeleb = null;
                          _currentPartnerCeleb = null;
                        });
                        final useMock = widget.ref.read(mockModeProvider);
                        final String resolvedChatId = useMock 
                            ? 'chat_${match.matchId}' 
                            : 'chat_match_${match.familyA_uid}_emma';
                        context.push('/chats/$resolvedChatId');
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.black),
                      label: const Text(
                        'Open Chat Workspace',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Keep Swiping Button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _currentMatchCeleb = null;
                        _currentPartnerCeleb = null;
                      });
                    },
                    child: const Text(
                      'Keep Swiping',
                      style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
