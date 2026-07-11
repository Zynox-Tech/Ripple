import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/ripple_repository.dart';
import '../../../core/repositories/repository_providers.dart';

class ChatsPage extends ConsumerWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;

    final authRepo = ref.watch(authRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);
    final chatRepo = ref.watch(chatRepositoryProvider);
    final matchesRepo = ref.watch(matchesRepositoryProvider);
    final schoolsRepo = ref.watch(schoolRepositoryProvider);

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Coordinating Swaps'),
          backgroundColor: Colors.transparent,
        ),
        body: FutureBuilder<RippleUser?>(
          future: authRepo.getCurrentUser(),
          builder: (context, userSnapshot) {
            final currentUser = userSnapshot.data;
            if (currentUser == null) return const Center(child: CircularProgressIndicator());

            return StreamBuilder<List<Conversation>>(
              stream: chatRepo.getConversations(currentUser.uid),
              builder: (context, chatsSnapshot) {
                final conversations = chatsSnapshot.data ?? [];
                if (chatsSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text(
                          'No active coordination yet.',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            'Matches you accept will appear here so you can begin school swap coordination.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<List<School>>(
                  future: schoolsRepo.getSchools(),
                  builder: (context, schoolsSnapshot) {
                    final schools = schoolsSnapshot.data ?? [];

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0), // Padding for floating bar
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        final conv = conversations[index];
                        final partnerUid = conv.participants.firstWhere((id) => id != currentUser.uid);

                        return FutureBuilder<RippleUser?>(
                          future: userRepo.getUserProfile(partnerUid),
                          builder: (context, partnerSnapshot) {
                            final partner = partnerSnapshot.data;
                            if (partner == null) return const SizedBox.shrink();

                            return FutureBuilder<List<Child>>(
                              future: userRepo.getChildren(partner.uid),
                              builder: (context, childrenSnapshot) {
                                final partnerChildren = childrenSnapshot.data ?? [];
                                final childB = partnerChildren.isNotEmpty ? partnerChildren.first : null;

                                return FutureBuilder<MatchModel?>(
                                  future: matchesRepo.getMatchDetails(conv.matchId),
                                  builder: (context, matchSnapshot) {
                                    final match = matchSnapshot.data;
                                    if (match == null) return const SizedBox.shrink();

                                    // Status pill settings
                                    String statusText = 'Connected';
                                    Color statusColor = primaryColor;
                                    if (match.status == 'complete') {
                                      statusText = 'Swap Confirmed!';
                                      statusColor = const Color(0xFF10B981); // Emerald
                                    } else if (conv.checklistA.values.any((v) => v) || conv.checklistB.values.any((v) => v)) {
                                      statusText = 'In Progress';
                                      statusColor = const Color(0xFF3B82F6); // Blue
                                    }

                                    final timeString = DateFormat('jm').format(conv.lastAt);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: RippleCard(
                                        onTap: () => context.push('/chats/${conv.chatId}'),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 26,
                                                  backgroundImage: getRippleImageProvider(partner.photoURL),
                                                ),
                                                if (partner.verified)
                                                  const Positioned(
                                                    bottom: 0,
                                                    right: 0,
                                                    child: VerifiedBadge(size: 14),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(width: 14),

                                            // Text Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        partner.displayName.split(' ').first,
                                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                      ),
                                                      Text(
                                                        timeString,
                                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  if (childB != null)
                                                    Text(
                                                      'Grade ${childB.gradeYear} • ${partner.area}',
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
                                                    ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    conv.lastMessage,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: isDark ? Colors.white60 : Colors.black87,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  
                                                  // Progress Badge
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      statusText,
                                                      style: TextStyle(fontSize: 9, color: statusColor, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                                                    ),
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
}
