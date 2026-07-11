import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme.dart';
import '../../../config/app_config.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/ripple_repository.dart';
import '../../../core/repositories/repository_providers.dart';


class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _selectedCategory = 'All';
  bool _bannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _bannerDismissed = prefs.getBool('parent_setup_dismissed') ?? false;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;
    
    final chatRepo = ref.watch(chatRepositoryProvider);
    final authRepo = ref.watch(authRepositoryProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.value;

    if (authState.isLoading) {
      return Container(
        decoration: RippleTheme.backgroundDecoration(isDark),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final name = user?.displayName.split(' ').first ?? 'Parent';
    final hasLocation = user != null && user.area.isNotEmpty == true && user.city.isNotEmpty == true;
    final locationText = hasLocation ? '${user.area}, ${user.city}' : 'Set Location';

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0, bottom: 100.0), // Padding for floating bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Custom Row (Profile, Location dropdown, Notification bell)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: getRippleImageProvider(user?.photoURL ?? ''),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                    ),
                    
                    // Location Selector (Pill format) - tappable
                    GestureDetector(
                      onTap: () => context.push('/setup'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black.withOpacity(0.03)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded, color: primaryColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              locationText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    ),

                        // Notification Bell Icon
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                            border: Border.all(color: Colors.black.withOpacity(0.03)),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () => context.push('/notifications'),
                            color: isDark ? Colors.white : Colors.black87,
                            iconSize: 22,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 2. Headline Greeting
                    Text(
                      'Hello $name!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start coordinating your school swap today.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),

                    if (user == null || user.city.isEmpty || user.area.isEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [RippleTheme.primaryTealDark, Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: RippleTheme.primaryTealDark.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.lock_person_rounded, color: Colors.black, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  'Complete Your Parent Profile',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Please set up your location and add your children to unlock matching swaps nearby.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.8),
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await context.push('/setup');
                                  setState(() {}); // refresh home page on return
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Set Up Profile Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 3. Search Bar Pill (Outlined, matches Screen 3 of RideCab)
                    GestureDetector(
                      onTap: () => context.go('/matches'),
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: Colors.black.withOpacity(0.02)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Which school?',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Enter school name to swap...',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white12 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Any grade • Any distance',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. Horizontal Categories chips (Year Groups / All)
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ['All', 'Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8'].map((cat) {
                          final bool isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(
                                cat,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black54),
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: primaryColor,
                              backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                              side: BorderSide(
                                color: isSelected ? primaryColor : Colors.black.withOpacity(0.04),
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    _selectedCategory = cat;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 5. Families Near You — RippleMapView
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Families Near You',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        TextButton(
                          onPressed: () => context.go('/matches'),
                          child: Text('View All', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    RippleMapView(
                      height: 220,
                      onTap: () => context.go('/matches'),
                    ),

                    const SizedBox(height: 24),

                    // 6. Ripple Advantages Cards
                    Text(
                      'Why Ripple?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    ..._buildAdvantageCards(context, isDark, primaryColor),

                    const SizedBox(height: 24),

                    // 7. Recent active chats short list
                    Text(
                      'Recent Active Swaps',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    
                    StreamBuilder<List<Conversation>>(
                      stream: user == null
                          ? Stream.value(<Conversation>[])
                          : chatRepo.getConversations(user.uid),
                      builder: (context, snapshot) {
                        final convs = snapshot.data ?? [];
                        if (convs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text('No active swaps yet.', style: TextStyle(color: isDark ? Colors.white30 : Colors.black38)),
                            ),
                          );
                        }
                        final displayConvs = convs.take(3).toList();
                        return Column(
                          children: displayConvs.map((conv) {
                            final partnerUid = conv.participants
                                .firstWhere((id) => id != (user?.uid ?? ''), orElse: () => '');
                            return FutureBuilder<RippleUser?>(
                              future: ref.read(userRepositoryProvider).getUserProfile(partnerUid),
                              builder: (ctx, partnerSnap) {
                                final partner = partnerSnap.data;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                                  ),
                                  child: ListTile(
                                    onTap: () => context.push('/chats/${conv.chatId}'),
                                    leading: CircleAvatar(
                                      backgroundImage: getRippleImageProvider(partner?.photoURL ?? ''),
                                    ),
                                    title: Text(
                                      partner?.displayName ?? partnerUid,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      conv.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      );
    }

  List<Widget> _buildAdvantageCards(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final advantages = [
      (
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF6366F1),
        title: 'Trusted Community',
        body: 'Connect only with verified parents from your school network — no strangers.',
      ),
      (
        icon: Icons.route_rounded,
        color: const Color(0xFF10B981),
        title: 'Share the School Run',
        body: 'Take turns driving with nearby families and cut your weekly trips in half.',
      ),
      (
        icon: Icons.lock_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Safe by Design',
        body: 'Children details, routes, and schedules are encrypted end-to-end.',
      ),
      (
        icon: Icons.eco_rounded,
        color: const Color(0xFF3B82F6),
        title: 'Greener Journeys',
        body: 'Fewer cars on school roads means less emissions and safer streets for everyone.',
      ),
    ];

    return advantages.map((a) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: a.color.withOpacity(0.18)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: a.color.withOpacity(0.13),
              child: Icon(a.icon, color: a.color, size: 22),
            ),
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(a.body, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
          ),
        ),
      );
    }).toList();
  }
}
