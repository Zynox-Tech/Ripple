import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/repository_providers.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  String _filterCategory = 'All';

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'match':
        return Icons.people_alt_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'school':
        return Icons.school_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'match':
        return RippleTheme.primaryTeal;
      case 'chat':
        return RippleTheme.secondaryEmerald;
      case 'school':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final authRepo = ref.watch(authRepositoryProvider);
    final notifRepo = ref.watch(notificationRepositoryProvider);

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            FutureBuilder<dynamic>(
              future: authRepo.getCurrentUser(),
              builder: (context, userSnap) {
                final user = userSnap.data;
                if (user == null) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () async {
                    await notifRepo.markAllAsRead(user.uid);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All notifications marked as read')),
                      );
                    }
                  },
                  child: Text(
                    'Mark All Read',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ],
        ),
        body: FutureBuilder(
          future: authRepo.getCurrentUser(),
          builder: (context, userSnap) {
            final user = userSnap.data;
            if (user == null) return const Center(child: CircularProgressIndicator());

            return Column(
              children: [
                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: ['All', 'Match', 'School', 'Chat'].map((cat) {
                      final isSelected = _filterCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat == 'Match'
                              ? 'Matches'
                              : cat == 'School'
                                  ? 'Admissions'
                                  : cat == 'Chat'
                                      ? 'Chats'
                                      : 'All'),
                          selected: isSelected,
                          selectedColor: primaryColor.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) setState(() => _filterCategory = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Live Notification Stream
                Expanded(
                  child: StreamBuilder<List<AppNotification>>(
                    stream: notifRepo.getNotifications(user.uid),
                    builder: (context, snap) {
                      final allNotifs = snap.data ?? [];
                      final filtered = _filterCategory == 'All'
                          ? allNotifs
                          : allNotifs
                              .where((n) => n.category == _filterCategory.toLowerCase())
                              .toList();

                      if (snap.connectionState == ConnectionState.waiting && allNotifs.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_off_outlined,
                                  size: 64, color: Colors.grey.withOpacity(0.4)),
                              const SizedBox(height: 16),
                              const Text('No notifications yet.',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                'Notifications appear here when you get matches,\nmessages and school updates.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white38 : Colors.black38),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final iconColor = _colorForCategory(item.category);
                          final icon = _iconForCategory(item.category);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await notifRepo.markAsRead(user.uid, item.id);
                                if (item.category == 'match') {
                                  context.go('/matches');
                                } else if (item.category == 'chat') {
                                  context.go('/chats');
                                }
                              },
                              child: RippleCard(
                                borderColor: item.isRead
                                    ? null
                                    : primaryColor.withOpacity(0.3),
                                gradientColors: item.isRead
                                    ? null
                                    : isDark
                                        ? [
                                            primaryColor.withOpacity(0.08),
                                            Colors.white.withOpacity(0.01)
                                          ]
                                        : [primaryColor.withOpacity(0.05), Colors.white],
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icon badge
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: iconColor.withOpacity(0.15),
                                      ),
                                      child: Icon(icon, color: iconColor, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontWeight: item.isRead
                                                        ? FontWeight.normal
                                                        : FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                _timeAgo(item.createdAt),
                                                style: const TextStyle(
                                                    fontSize: 10, color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.body,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Category badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: iconColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.category.toUpperCase(),
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: iconColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Unread indicator
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primaryColor,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
