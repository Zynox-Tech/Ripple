import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/app_config.dart';
import '../../../config/theme.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/ripple_repository.dart';
import '../../../core/repositories/repository_providers.dart';


class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _notificationsEnabled = true;

  final List<String> _ukCities = [
    'London', 'Birmingham', 'Manchester', 'Leeds', 'Glasgow', 
    'Liverpool', 'Newcastle', 'Bristol', 'Cardiff', 'Edinburgh', 'Belfast'
  ];

  final Map<String, List<String>> _ukSubLocations = {
    'London': ['Westminster', 'Chelsea', 'Hammersmith', 'Camden', 'Greenwich', 'Richmond', 'Hackney', 'Islington', 'Ealing', 'Croydon'],
    'Birmingham': ['Edgbaston', 'Harborne', 'Moseley', 'Solihull', 'Sutton Coldfield', 'Jewellery Quarter', 'Aston'],
    'Manchester': ['Didsbury', 'Chorlton', 'Salford', 'Altrincham', 'Stockport', 'Ancoats', 'Fallowfield'],
    'Leeds': ['Headingley', 'Chapel Allerton', 'Roundhay', 'Horsforth', 'Kirkstall', 'Adel'],
    'Glasgow': ['West End', 'Southside', 'Merchant City', 'Hillhead', 'Shawlands', 'Finnieston'],
    'Liverpool': ['Aigburth', 'Woolton', 'Allerton', 'Crosby', 'Anfield', 'Georgian Quarter'],
    'Bristol': ['Clifton', 'Redland', 'Cotham', 'Bedminster', 'Stokes Croft', 'Southville'],
    'Cardiff': ['Roath', 'Cathays', 'Canton', 'Pontcanna', 'Llandaff', 'Cardiff Bay'],
    'Edinburgh': ['Old Town', 'New Town', 'Stockbridge', 'Leith', 'Morningside', 'Bruntsfield'],
    'Belfast': ['Queen\'s Quarter', 'Titanic Quarter', 'Cathedral Quarter', 'Stormont', 'Malone Road'],
    'Newcastle': ['Jesmond', 'Gosforth', 'Ouseburn', 'Heaton', 'City Centre'],
  };

  String _getAreaFromLatLng(double lat, double lng) {
    if (lat > 51.52) return 'Camden';
    if (lng < -0.18) return 'Hammersmith';
    if (lat < 51.49) return 'Chelsea';
    return 'Westminster';
  }

  Widget _buildAreaButton(
    String area, double lat, double lng,
    StateSetter setMapState,
    void Function(double lat, double lng, String area) onSelected,
  ) {
    return GestureDetector(
      onTap: () => setMapState(() => onSelected(lat, lng, area)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(area, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─────────────────────── Avatar / Phone ─────────────────────────

  void _showAvatarOptions(BuildContext context, RippleUser user, IUserRepository userRepo) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Preset avatar URLs for demo (real app would use image_picker + Firebase Storage)
    const presets = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150',
      'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=150',
      'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=150',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text('Choose Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Tap an avatar below or upload/capture your own photo.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final url = presets[i];
                  final isSelected = user.photoURL == url;
                  return GestureDetector(
                    onTap: () async {
                      final updated = user.copyWith(photoURL: url);
                      await userRepo.saveUserProfile(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: getRippleImageProvider(url),
                      child: isSelected
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black38,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 28),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                        if (picked != null) {
                          final updated = user.copyWith(photoURL: picked.path);
                          await userRepo.saveUserProfile(updated);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('From Gallery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                        if (picked != null) {
                          final updated = user.copyWith(photoURL: picked.path);
                          await userRepo.saveUserProfile(updated);
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: const Text('Camera', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEditPhoneDialog(BuildContext context, RippleUser user, IUserRepository userRepo) {
    final ctrl = TextEditingController(text: user.phoneNumber ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phone Number'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: '+44 7700 900000 (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updated = user.copyWith(phoneNumber: ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
              await userRepo.saveUserProfile(updated);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Dialogs / Sheets ────────────────────────

  void _showEditNameDialog(BuildContext context, RippleUser user, IUserRepository userRepo) {
    final controller = TextEditingController(text: user.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Parent Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter full name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final updated = user.copyWith(displayName: controller.text.trim());
                await userRepo.saveUserProfile(updated);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditLocationDialog(BuildContext context, RippleUser user, IUserRepository userRepo) {
    final cityCtrl = TextEditingController(text: user.city.isNotEmpty ? user.city : 'London');
    final areaCtrl = TextEditingController(text: user.area.isNotEmpty ? user.area : 'Westminster');
    final streetCtrl = TextEditingController(text: user.streetAddress ?? '');
    final houseCtrl = TextEditingController(text: user.houseNo ?? '');
    final postcodeCtrl = TextEditingController(text: user.postcode ?? '');
    
    double? tempLat = user.latitude ?? 51.5074;
    double? tempLng = user.longitude ?? -0.1278;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primaryColor = Theme.of(ctx).primaryColor;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void openMapPicker() {
              double innerLat = tempLat ?? 51.5074;
              double innerLng = tempLng ?? -0.1278;
              String innerArea = areaCtrl.text.trim();

              showDialog(
                context: context,
                builder: (mapCtx) {
                  return StatefulBuilder(
                    builder: (mapCtx, setMapState) {
                      return Dialog(
                        insetPadding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            width: double.infinity,
                            height: MediaQuery.of(mapCtx).size.height * 0.7,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Pinpoint on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(mapCtx)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      RippleMapView(
                                        height: MediaQuery.of(mapCtx).size.height * 0.7 - 130,
                                      ),
                                      // Coordinate tap buttons
                                      Positioned(
                                        bottom: 12,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _buildAreaButton('Westminster', 51.5074, -0.1278, setMapState, (lat, lng, area) {
                                              innerLat = lat; innerLng = lng; innerArea = area;
                                            }),
                                            const SizedBox(width: 8),
                                            _buildAreaButton('Chelsea', 51.4875, -0.1687, setMapState, (lat, lng, area) {
                                              innerLat = lat; innerLng = lng; innerArea = area;
                                            }),
                                            const SizedBox(width: 8),
                                            _buildAreaButton('Camden', 51.5390, -0.1425, setMapState, (lat, lng, area) {
                                              innerLat = lat; innerLng = lng; innerArea = area;
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Assigned Area: $innerArea', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            tempLat = innerLat;
                                            tempLng = innerLng;
                                            areaCtrl.text = innerArea;
                                            streetCtrl.text = 'Street ${innerLat.toStringAsFixed(4)}';
                                            houseCtrl.text = 'Flat ${(innerLng * 100).abs().toStringAsFixed(0)}';
                                            postcodeCtrl.text = 'SW1A 1AA';
                                          });
                                          Navigator.pop(mapCtx);
                                        },
                                        child: const Text('Confirm Pinpoint'),
                                      ),
                                    ],
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
              );
            }

            return AlertDialog(
              title: const Text('Edit Address & Location'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Town / City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: cityCtrl.text),
                      optionsBuilder: (textVal) => _ukCities.where((c) => c.toLowerCase().contains(textVal.text.toLowerCase())),
                      onSelected: (sel) {
                        setDialogState(() {
                          cityCtrl.text = sel;
                          final subs = _ukSubLocations[sel] ?? [];
                          if (subs.isNotEmpty) areaCtrl.text = subs.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Area / Borough', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: areaCtrl.text),
                      optionsBuilder: (textVal) {
                        final subs = _ukSubLocations[cityCtrl.text] ?? [];
                        return subs.where((a) => a.toLowerCase().contains(textVal.text.toLowerCase()));
                      },
                      onSelected: (sel) => setDialogState(() => areaCtrl.text = sel),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: streetCtrl,
                            decoration: const InputDecoration(labelText: 'Street Name'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: houseCtrl,
                            decoration: const InputDecoration(labelText: 'House / Flat No'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: postcodeCtrl,
                      decoration: const InputDecoration(labelText: 'Postcode'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: openMapPicker,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Pinpoint on Google Maps'),
                      ),
                    ),
                    if (tempLat != null && tempLng != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Coords: ${tempLat!.toStringAsFixed(4)}, ${tempLng!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final updated = user.copyWith(
                      city: cityCtrl.text.trim(),
                      area: areaCtrl.text.trim(),
                      streetAddress: streetCtrl.text.trim(),
                      houseNo: houseCtrl.text.trim(),
                      postcode: postcodeCtrl.text.trim(),
                      latitude: tempLat,
                      longitude: tempLng,
                    );
                    await userRepo.saveUserProfile(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Location'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddChildSheet(BuildContext context, String uid, IUserRepository userRepo, ISchoolRepository schoolsRepo) {
    final nameController = TextEditingController();
    String grade = 'Year 5';
    String schoolId = '';
    List<School> availableSchools = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (availableSchools.isEmpty) {
            schoolsRepo.getSchools().then((list) {
              setModalState(() {
                availableSchools = list;
                if (list.isNotEmpty) schoolId = list.first.schoolId;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Add Child Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  const Text("Child's First Name:", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'First Name Only',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Grade / Class:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: grade,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ['Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => grade = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Current School:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (availableSchools.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: schoolId,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: availableSchools.map((s) => DropdownMenuItem(value: s.schoolId, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => schoolId = val);
                      },
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: RippleButton(
                      text: 'Add Profile',
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final targetId = schoolId == 'sch_westminster' ? 'sch_westminstersch' : 'sch_westminster';
                        final child = Child(
                          childId: 'child_${DateTime.now().millisecondsSinceEpoch}',
                          firstName: nameController.text.trim(),
                          gradeYear: grade,
                          currentSchoolId: schoolId,
                          targetSchoolIds: [targetId],
                          status: 'active',
                          age: 9,
                        );
                        await userRepo.addChild(uid, child);
                        ref.invalidate(userChildrenProvider(uid)); // Reactive refresh
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
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

  void _showEditChildSheet(BuildContext context, String uid, Child child, IUserRepository userRepo, ISchoolRepository schoolsRepo) {
    final nameController = TextEditingController(text: child.firstName);
    String grade = child.gradeYear;
    String schoolId = child.currentSchoolId;
    List<School> availableSchools = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (availableSchools.isEmpty) {
            schoolsRepo.getSchools().then((list) {
              setModalState(() {
                availableSchools = list;
                if (list.isNotEmpty && schoolId.isEmpty) schoolId = list.first.schoolId;
              });
            });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Edit Child Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  const Text("Child's First Name:", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Grade / Class:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: grade,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    items: ['Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => grade = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Current School:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (availableSchools.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: availableSchools.any((s) => s.schoolId == schoolId) ? schoolId : availableSchools.first.schoolId,
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: availableSchools.map((s) => DropdownMenuItem(value: s.schoolId, child: Text(s.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => schoolId = val);
                      },
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: RippleButton(
                      text: 'Save Changes',
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        final updated = Child(
                          childId: child.childId,
                          firstName: nameController.text.trim(),
                          gradeYear: grade,
                          currentSchoolId: schoolId,
                          targetSchoolIds: child.targetSchoolIds,
                          status: child.status,
                          age: child.age,
                        );
                        await userRepo.removeChild(uid, child.childId);
                        await userRepo.addChild(uid, updated);
                        ref.invalidate(userChildrenProvider(uid)); // Reactive refresh
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
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

  // ─────────────────────── Build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userRepo = ref.watch(userRepositoryProvider);
    final schoolsRepo = ref.watch(schoolRepositoryProvider);

    // Watch authState reactively
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

    if (user == null) {
      return Container(
        decoration: RippleTheme.backgroundDecoration(isDark),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('Please log in to view profile details')),
        ),
      );
    }

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
                // 1. Premium User Hero Card (Glassmorphism & Gradients)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                          ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                          : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showAvatarOptions(context, user, userRepo),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: getRippleImageProvider(user.photoURL),
                              backgroundColor: Colors.grey.withOpacity(0.2),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).primaryColor,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.black),
                              ),
                            ),
                            if (user.verified)
                              const Positioned(
                                top: 0,
                                right: 0,
                                child: VerifiedBadge(size: 16),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                            ),
                            if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  user.phoneNumber!,
                                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (user.subscriptionTier == 'free' ? Colors.grey : Colors.amber).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user.subscriptionTier.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: user.subscriptionTier == 'free' ? Colors.grey : Colors.amber[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                            onPressed: () => _showEditNameDialog(context, user, userRepo),
                            tooltip: 'Edit Name',
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone_outlined, color: Colors.grey, size: 20),
                            onPressed: () => _showEditPhoneDialog(context, user, userRepo),
                            tooltip: 'Edit Phone',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Children section (Reactive future list)
                _buildChildrenSection(context, user, userRepo, schoolsRepo),

                const SizedBox(height: 24),

                // 3. Location Details Card with Google Map
                _buildLocationSection(context, user, userRepo),

                const SizedBox(height: 24),

                // 4. Preferences & Settings
                _buildSettingsSection(context, l10n, primaryColor, isDark),

                const SizedBox(height: 24),

                // 5. Subscription Upgrade shortcut
                _buildSubscriptionSection(context, l10n),

                const SizedBox(height: 24),

                // 6. Complete moves achievements
                _buildMovesSection(context),

                const SizedBox(height: 36),

                // 7. Sign Out Elegant Button
                SizedBox(
                  width: double.infinity,
                  child: RippleButton(
                    text: l10n.translate('sign_out'),
                    isSecondary: true,
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) router.go('/splash');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Children Section Widget
  Widget _buildChildrenSection(BuildContext context, RippleUser user, IUserRepository userRepo, ISchoolRepository schoolsRepo) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final childrenAsync = ref.watch(userChildrenProvider(user.uid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Children',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
            ),
            TextButton.icon(
              onPressed: () => _showAddChildSheet(context, user.uid, userRepo, schoolsRepo),
              icon: Icon(Icons.add, size: 16, color: primaryColor),
              label: Text('Add Child', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        childrenAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator())),
          error: (e, _) => Center(child: Text('Error loading children: $e')),
          data: (children) {
            if (children.isEmpty) {
              return RippleCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.child_care_rounded, size: 48, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('No children added yet', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _showAddChildSheet(context, user.uid, userRepo, schoolsRepo),
                          child: const Text('Add your first child'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return FutureBuilder<List<School>>(
              future: schoolsRepo.getSchools(),
              builder: (ctx, snap) {
                final schools = snap.data ?? [];
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: children.length,
                  itemBuilder: (context, idx) {
                    final child = children[idx];
                    final curSchool = schools.firstWhere((s) => s.schoolId == child.currentSchoolId, orElse: () => School(schoolId: '', name: 'Unknown School', area: '', city: '', lat: 0, lng: 0, gradesOffered: [], transferRatePerTerm: 0, interestedCount: 0));
                    final targetNames = schools.where((s) => child.targetSchoolIds.contains(s.schoolId)).map((s) => s.name).join(', ');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: RippleCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.15),
                              child: Text(
                                child.firstName.isNotEmpty ? child.firstName[0].toUpperCase() : '?',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${child.firstName} • ${child.gradeYear}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 3),
                                  Text('Current: ${curSchool.name}', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  if (targetNames.isNotEmpty)
                                    Text('Target: $targetNames', style: const TextStyle(fontSize: 12, color: Colors.blueAccent), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showEditChildSheet(context, user.uid, child, userRepo, schoolsRepo),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              onPressed: () async {
                                await userRepo.removeChild(user.uid, child.childId);
                                ref.invalidate(userChildrenProvider(user.uid));
                              },
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
        ),
      ],
    );
  }

  // Verified Location Section
  Widget _buildLocationSection(BuildContext context, RippleUser user, IUserRepository userRepo) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasLocDetails = user.streetAddress != null || user.postcode != null;
    final displayStreet = user.streetAddress?.isNotEmpty == true ? user.streetAddress! : 'No street name set';
    final displayHouse = user.houseNo?.isNotEmpty == true ? user.houseNo! : '';
    final displayPostcode = user.postcode?.isNotEmpty == true ? user.postcode! : 'No postcode set';
    final displayCityArea = user.area.isNotEmpty && user.city.isNotEmpty ? '${user.area}, ${user.city}' : 'No town/city set';

    final hasCoordinates = user.latitude != null && user.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Verified Location',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
            ),
            TextButton.icon(
              onPressed: () => _showEditLocationDialog(context, user, userRepo),
              icon: Icon(Icons.edit_location_alt, size: 16, color: primaryColor),
              label: Text('Edit Location', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
          // Mini map display via RippleMapView
          RippleMapView(
            height: 180,
          ),

        // Location text details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A).withOpacity(0.6) : Colors.white,
            border: Border.all(color: Colors.black.withOpacity(0.08)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayHouse.isNotEmpty ? '$displayHouse, $displayStreet' : displayStreet,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$displayCityArea ($displayPostcode)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Preferences Section Widget
  Widget _buildSettingsSection(BuildContext context, AppLocalizations l10n, Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferences',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              SwitchListTile(
                value: _notificationsEnabled,
                title: Text(l10n.translate('notification_settings')),
                subtitle: const Text('Push alerts for new matches & messages', style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.notifications_none_outlined),
                activeColor: primaryColor,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                value: isDark,
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch app theme', style: TextStyle(fontSize: 11)),
                secondary: const Icon(Icons.dark_mode_outlined),
                activeColor: primaryColor,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggleThemeMode(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Subscription Upgrade
  Widget _buildSubscriptionSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.card_membership_outlined),
            title: Text(l10n.translate('plans')),
            subtitle: const Text('View and upgrade your plan', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 12),
            onTap: () => context.push('/plans'),
          ),
        ),
      ],
    );
  }

  // Completed Moves
  Widget _buildMovesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Completed Moves',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.3),
        ),
        const SizedBox(height: 8),
        RippleCard(
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Westminster to Chelsea Swap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 4),
                    Text(
                      'Year 5 swap successfully confirmed in 3 weeks!',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
