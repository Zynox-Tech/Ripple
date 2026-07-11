import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../config/app_config.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/ripple_repository.dart';
import '../../../core/repositories/repository_providers.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  final String chatId;
  const ChatRoomPage({super.key, required this.chatId});

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isChecklistExpanded = true;
  bool _isOverlayDismissed = false;

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showAttachmentOptions(IChatRepository chatRepo, String myUid) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
              ),
              const Text('Share Attachment', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 6),
              Text('Upload from your phone gallery, camera, or share a document', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentItem(
                    icon: Icons.photo_library_rounded,
                    label: 'From Gallery',
                    color: Colors.purple,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (picked != null && mounted) {
                          if (kIsWeb) {
                            final bytes = await picked.readAsBytes();
                            chatRepo.sendMessage(widget.chatId, myUid,
                              'photo_${DateTime.now().millisecondsSinceEpoch}', type: 'image', fileBytes: bytes, fileName: picked.name);
                          } else {
                            chatRepo.sendMessage(widget.chatId, myUid,
                              picked.path, type: 'image');
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: const Text('Photo shared!'),
                              backgroundColor: primaryColor, behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not access gallery: $e')));
                      }
                    },
                  ),
                  _buildAttachmentItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: Colors.teal,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                        if (picked != null && mounted) {
                          if (kIsWeb) {
                            final bytes = await picked.readAsBytes();
                            chatRepo.sendMessage(widget.chatId, myUid,
                              'photo_${DateTime.now().millisecondsSinceEpoch}', type: 'image', fileBytes: bytes, fileName: picked.name);
                          } else {
                            chatRepo.sendMessage(widget.chatId, myUid,
                              picked.path, type: 'image');
                          }
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not access camera: $e')));
                      }
                    },
                  ),
                  _buildAttachmentItem(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: Colors.blue,
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx'],
                          withData: true,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final file = result.files.single;
                          final name = file.name;
                          final size = (file.size / (1024 * 1024)).toStringAsFixed(1);
                          final bytes = file.bytes;
                          if (bytes != null) {
                            chatRepo.sendMessage(widget.chatId, myUid,
                              '$name • $size MB', type: 'document', fileBytes: bytes, fileName: name, fileSize: file.size);
                          } else if (!kIsWeb && file.path != null) {
                            chatRepo.sendMessage(widget.chatId, myUid,
                              '$name • $size MB', type: 'document', fileName: name, fileSize: file.size);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Document "$name" shared!'),
                                backgroundColor: Colors.blue, behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                          }
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick file: $e')));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  void _startCallSimulation(String photoUrl, String partnerName, bool isVideo) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Call Simulation',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final primaryColor = Theme.of(context).primaryColor;
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SafeArea(
            child: CallSimulationWidget(
              photoUrl: photoUrl,
              partnerName: partnerName,
              isVideo: isVideo,
              primaryColor: primaryColor,
              onEndCall: () => Navigator.pop(context),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final authRepo = ref.watch(authRepositoryProvider);
    final userRepo = ref.watch(userRepositoryProvider);
    final chatRepo = ref.watch(chatRepositoryProvider);
    final matchesRepo = ref.watch(matchesRepositoryProvider);
    final schoolsRepo = ref.watch(schoolRepositoryProvider);

    return Container(
      decoration: RippleTheme.backgroundDecoration(isDark),
      child: FutureBuilder<RippleUser?>(
        future: authRepo.getCurrentUser(),
        builder: (context, userSnapshot) {
          final currentUser = userSnapshot.data;
          if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

          return StreamBuilder<List<Conversation>>(
            stream: chatRepo.getConversations(currentUser.uid),
            builder: (context, convSnapshot) {
              final convs = convSnapshot.data ?? [];
              if (convSnapshot.connectionState == ConnectionState.waiting && convs.isEmpty) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
               final conv = convs.firstWhere((c) => c.chatId == widget.chatId, orElse: () => convs.isNotEmpty ? convs.first : Conversation(
                chatId: widget.chatId,
                matchId: widget.chatId.replaceFirst('chat_', ''),
                participants: [currentUser.uid, widget.chatId.replaceFirst('chat_match_', '').replaceFirst('chat_', '')],
                lastMessage: '',
                lastAt: DateTime.now(),
                checklistA: {'applied': false, 'confirmed': false, 'moveDate': false},
                checklistB: {'applied': false, 'confirmed': false, 'moveDate': false},
                moveConfirmed: false,
              ));
              String partnerUid;
              try {
                final matchConv = convs.firstWhere((c) => c.chatId == widget.chatId);
                partnerUid = matchConv.participants.firstWhere((id) => id != currentUser.uid, orElse: () => 'user_emma');
              } catch (_) {
                partnerUid = widget.chatId.replaceFirst('chat_match_', '').replaceFirst('chat_', '');
                if (partnerUid.isEmpty || partnerUid == widget.chatId) {
                  partnerUid = 'user_emma';
                }
              }

              return FutureBuilder<RippleUser?>(
                future: userRepo.getUserProfile(partnerUid),
                builder: (context, partnerSnap) {
                  final partner = partnerSnap.data;
                  final name = partner?.displayName.split(' ').first ?? 'Chat';

                  return Scaffold(
                    backgroundColor: Colors.transparent,
                    appBar: AppBar(
                      titleSpacing: 0,
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
                        onPressed: () => context.pop(),
                      ),
                      title: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: getRippleImageProvider(partner?.photoURL ?? ''),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const Text('Coordination Workspace', style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(Icons.call_outlined, color: primaryColor, size: 22),
                          onPressed: () => _startCallSimulation(partner?.photoURL ?? '', name, false),
                        ),
                        IconButton(
                          icon: Icon(Icons.videocam_outlined, color: primaryColor, size: 22),
                          onPressed: () => _startCallSimulation(partner?.photoURL ?? '', name, true),
                        ),
                        IconButton(
                          icon: Icon(
                            _isChecklistExpanded ? Icons.playlist_add_check_circle_rounded : Icons.playlist_add_check_rounded,
                            color: primaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              _isChecklistExpanded = !_isChecklistExpanded;
                            });
                          },
                        ),
                      ],
                    ),
                    body: Stack(
                      children: [
                        FutureBuilder<MatchModel?>(
                          future: matchesRepo.getMatchDetails(conv.matchId),
                          builder: (context, matchSnapshot) {
                            final match = matchSnapshot.data;
                            if (match == null) return const Center(child: CircularProgressIndicator());

                            return FutureBuilder<List<School>>(
                              future: schoolsRepo.getSchools(),
                              builder: (context, schoolsSnapshot) {
                                final schools = schoolsSnapshot.data ?? [];
                                if (schools.isEmpty) return const SizedBox.shrink();

                                return FutureBuilder<List<Child>>(
                                  future: userRepo.getChildren(currentUser.uid),
                                  builder: (context, myKidsSnap) {
                                    final childA = myKidsSnap.data?.isNotEmpty == true ? myKidsSnap.data!.first : null;
                                    
                                    return FutureBuilder<List<Child>>(
                                      future: userRepo.getChildren(partnerUid),
                                      builder: (context, partnerKidsSnap) {
                                        final childB = partnerKidsSnap.data?.isNotEmpty == true ? partnerKidsSnap.data!.first : null;
                                        if (childA == null || childB == null) return const SizedBox.shrink();

                                        final schoolA = schools.firstWhere((s) => s.schoolId == childA.currentSchoolId, orElse: () => schools.first);
                                        final schoolB = schools.firstWhere((s) => s.schoolId == childB.currentSchoolId, orElse: () => schools.first);

                                        return Column(
                                          children: [
                                            // Context info bar
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${schoolA.name.split(' ').first} ⇄ ${schoolB.name.split(' ').first}',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Grade ${childA.gradeYear} • ${match.distanceKm.toStringAsFixed(1)} miles',
                                                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Expandable Coordination Checklist Drawer
                                            if (_isChecklistExpanded)
                                              Container(
                                                padding: const EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                                  border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        const Text(
                                                          'Mutual Coordination Milestones',
                                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                                                        ),
                                                        if (conv.moveConfirmed)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                            decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                                            child: const Text('Swap Completed!', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 9)),
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 10),
                                                    
                                                    _buildChecklistItem(
                                                      title: 'Parent Submitted School Transfer Form',
                                                      isMeChecked: conv.checklistA['applied'] ?? false,
                                                      isPartnerChecked: conv.checklistB['applied'] ?? false,
                                                      onChanged: (val) => chatRepo.updateChecklist(widget.chatId, currentUser.uid, 'applied', val ?? false),
                                                      partnerName: name,
                                                      primaryColor: primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    _buildChecklistItem(
                                                      title: 'Official School Transfer Confirmed',
                                                      isMeChecked: conv.checklistA['confirmed'] ?? false,
                                                      isPartnerChecked: conv.checklistB['confirmed'] ?? false,
                                                      onChanged: (val) => chatRepo.updateChecklist(widget.chatId, currentUser.uid, 'confirmed', val ?? false),
                                                      partnerName: name,
                                                      primaryColor: primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                    _buildChecklistItem(
                                                      title: 'Agreed School Start Date Scheduled',
                                                      isMeChecked: conv.checklistA['moveDate'] ?? false,
                                                      isPartnerChecked: conv.checklistB['moveDate'] ?? false,
                                                      onChanged: (val) => chatRepo.updateChecklist(widget.chatId, currentUser.uid, 'moveDate', val ?? false),
                                                      partnerName: name,
                                                      primaryColor: primaryColor,
                                                      isDark: isDark,
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            // Message list stream
                                            Expanded(
                                              child: StreamBuilder<List<Message>>(
                                                stream: chatRepo.getMessages(widget.chatId),
                                                builder: (context, messagesSnapshot) {
                                                  final messages = messagesSnapshot.data ?? [];
                                                  
                                                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                                                  return ListView.builder(
                                                    controller: _scrollController,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                                    itemCount: messages.length,
                                                    itemBuilder: (context, index) {
                                                      final msg = messages[index];
                                                      final isMe = msg.senderUid == currentUser.uid;

                                                      if (msg.type == 'system') {
                                                        return Center(
                                                          child: Container(
                                                            margin: const EdgeInsets.symmetric(vertical: 8),
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                            decoration: BoxDecoration(
                                                              color: isDark ? Colors.white10 : Colors.black12,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              msg.text,
                                                              style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        );
                                                      }

                                                      return _buildChatBubble(msg, isMe, primaryColor, isDark);
                                                    },
                                                  );
                                                },
                                              ),
                                            ),

                                            // Quick replies bar
                                            Container(
                                              height: 48,
                                              alignment: Alignment.centerLeft,
                                              color: Colors.transparent,
                                              child: ListView(
                                                scrollDirection: Axis.horizontal,
                                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                                children: [
                                                  _buildQuickReplyChip('Form submitted!', chatRepo, currentUser.uid),
                                                  _buildQuickReplyChip('Confirming with school...', chatRepo, currentUser.uid),
                                                  _buildQuickReplyChip('Let\'s meet at school', chatRepo, currentUser.uid),
                                                  _buildQuickReplyChip('Sounds good!', chatRepo, currentUser.uid),
                                                ],
                                              ),
                                            ),

                                            // Input Panel
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 24.0),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                                                      color: primaryColor,
                                                      onPressed: () => _showAttachmentOptions(chatRepo, currentUser.uid),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextField(
                                                      controller: _msgController,
                                                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                                      decoration: InputDecoration(
                                                        hintText: 'Type message...',
                                                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                                                        filled: true,
                                                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(24),
                                                          borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12),
                                                        ),
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                                      ),
                                                      textInputAction: TextInputAction.send,
                                                      onSubmitted: (text) {
                                                        if (text.trim().isNotEmpty) {
                                                          chatRepo.sendMessage(widget.chatId, currentUser.uid, text.trim());
                                                          _msgController.clear();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  CircleAvatar(
                                                    backgroundColor: primaryColor,
                                                    radius: 22,
                                                    child: IconButton(
                                                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                                                      onPressed: () {
                                                        if (_msgController.text.trim().isNotEmpty) {
                                                          chatRepo.sendMessage(widget.chatId, currentUser.uid, _msgController.text.trim());
                                                          _msgController.clear();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),

                        if (conv.moveConfirmed && !_isOverlayDismissed)
                          Positioned.fill(
                            child: AnimatedOpacity(
                              opacity: conv.moveConfirmed ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 500),
                              child: Container(
                                color: const Color(0xFF020617).withOpacity(0.95), 
                                padding: const EdgeInsets.all(28.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Close button
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 28),
                                          onPressed: () => setState(() => _isOverlayDismissed = true),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF10B981).withOpacity(0.12),
                                        border: Border.all(color: const Color(0xFF10B981), width: 3),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF10B981),
                                        size: 72,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Swap Confirmed!',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Congratulations! You and $name have completed all transfer milestones.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white60,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(
                                            children: [
                                              Icon(Icons.access_time_rounded, color: Colors.amber, size: 24),
                                              SizedBox(height: 4),
                                              Text('300+', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                                              Text('Hours Saved/Yr', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Icon(Icons.local_gas_station_rounded, color: Colors.blueAccent, size: 24),
                                              SizedBox(height: 4),
                                              Text('£800+', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16)),
                                              Text('Fuel Saved/Yr', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 48),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.go('/home');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                                        ),
                                        child: const Text(
                                          'Return to Dashboard',
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool isMeChecked,
    required bool isPartnerChecked,
    required ValueChanged<bool?> onChanged,
    required String partnerName,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isMeChecked,
            onChanged: onChanged,
            activeColor: primaryColor,
            checkColor: Colors.black,
          ),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                decoration: isMeChecked ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isMeChecked ? Colors.grey : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPartnerChecked ? const Color(0xFF10B981).withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPartnerChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 10,
                    color: isPartnerChecked ? const Color(0xFF10B981) : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    partnerName,
                    style: TextStyle(
                      fontSize: 9,
                      color: isPartnerChecked ? const Color(0xFF10B981) : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Message msg, bool isMe, Color primaryColor, bool isDark) {
    final bubbleColor = isMe 
        ? primaryColor 
        : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100);
    final textColor = isMe 
        ? Colors.black 
        : (isDark ? RippleTheme.darkTextPrimary : RippleTheme.lightTextPrimary);

    Widget bubbleContent;
    if (msg.type == 'image') {
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (() {
              final text = msg.text;
              final isUrl = text.startsWith('http://') || text.startsWith('https://');
              if (kIsWeb) {
                // On web: only load from URL (bytes were uploaded to Firebase/mock)
                if (isUrl) {
                  return Image.network(text, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey.shade300, height: 150, width: 200,
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey)),
                    loadingBuilder: (c, child, progress) {
                      if (progress == null) return child;
                      return Container(color: Colors.grey.withOpacity(0.1), height: 150, width: 200,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(strokeWidth: 2,
                          value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null));
                    });
                } else {
                  return Container(
                    color: Colors.grey.shade300, height: 150, width: 200,
                    child: const Icon(Icons.photo_rounded, color: Colors.grey));
                }
              } else {
                // Native: can use File path or URL
                if (isUrl) {
                  return Image.network(text, fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey.shade300, height: 150, width: 200,
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey)));
                } else {
                  return Image.file(io.File(text), fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey.shade300, height: 150, width: 200,
                      child: const Icon(Icons.broken_image_rounded, color: Colors.grey)));
                }
              }
            })(),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_rounded, size: 12, color: Colors.grey),
              SizedBox(width: 4),
              Text('Photo', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      );
    } else if (msg.type == 'document') {
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text.split('•').first.trim(),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  msg.text.contains('•') ? msg.text.split('•').last.trim() : 'Document • PDF',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_circle_down_rounded, color: Colors.grey, size: 22),
        ],
      );
    } else {
      bubbleContent = Text(
        msg.text,
        style: TextStyle(color: textColor, fontSize: 13, height: 1.4, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: msg.type == 'image' ? const EdgeInsets.all(4) : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
          border: isMe 
              ? null 
              : Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                ),
        ),
        child: bubbleContent,
      ),
    );
  }

  Widget _buildQuickReplyChip(String text, IChatRepository chatRepo, String myUid) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          chatRepo.sendMessage(widget.chatId, myUid, text);
        },
      ),
    );
  }
}

// ----------------- Call Simulation Widget -----------------

class CallSimulationWidget extends StatefulWidget {
  final String photoUrl;
  final String partnerName;
  final bool isVideo;
  final Color primaryColor;
  final VoidCallback onEndCall;

  const CallSimulationWidget({
    super.key,
    required this.photoUrl,
    required this.partnerName,
    required this.isVideo,
    required this.primaryColor,
    required this.onEndCall,
  });

  @override
  State<CallSimulationWidget> createState() => _CallSimulationWidgetState();
}

class _CallSimulationWidgetState extends State<CallSimulationWidget> {
  String _statusText = 'Ringing...';
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusText = 'Connected';
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration() {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isVideoActive = widget.isVideo && _statusText == 'Connected';
    
    return Stack(
      children: [
        if (isVideoActive)
          Positioned.fill(
            child: Container(
              color: Colors.black87,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Positioned(
                    right: 16,
                    top: 16,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      child: SizedBox(
                        width: 90,
                        height: 120,
                        child: ColoredBox(
                          color: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white60, size: 32),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_camera_front_rounded, color: Colors.white30, size: 84),
                      const SizedBox(height: 16),
                      Text(
                        'Simulating Video Feed from ${widget.partnerName}',
                        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: widget.photoUrl.startsWith('http')
                  ? Image.network(
                      widget.photoUrl.isNotEmpty ? widget.photoUrl : 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      io.File(widget.photoUrl),
                      fit: BoxFit.cover,
                    ),
            ),
          ),

        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 80.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isVideoActive) ...[
                  CircleAvatar(
                    radius: 54,
                    backgroundImage: getRippleImageProvider(widget.photoUrl),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  widget.partnerName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText == 'Connected' ? _formatDuration() : _statusText,
                  style: TextStyle(
                    color: _statusText == 'Ringing...' ? Colors.amberAccent : Colors.greenAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isVideo ? 'Ripple Video Call' : 'Ripple Voice Call',
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 60.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCallActionCircle(
                      icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      isActive: _isMuted,
                      onTap: () => setState(() => _isMuted = !_isMuted),
                    ),
                    const SizedBox(width: 32),
                    _buildCallActionCircle(
                      icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      isActive: _isSpeaker,
                      onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: widget.onEndCall,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent,
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallActionCircle({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.white : Colors.white12,
        ),
        child: Icon(icon, color: isActive ? Colors.black : Colors.white, size: 24),
      ),
    );
  }
}
