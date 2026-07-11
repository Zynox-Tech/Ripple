import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme.dart';
import '../../../config/l10n/app_localizations.dart';
import '../../../core/models/ripple_models.dart';
import '../../../core/widgets/ripple_widgets.dart';
import '../../../core/repositories/repository_providers.dart';

class ProfileSetupPage extends ConsumerStatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isVerifiedSimulated = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  // Step 1: Parent Details
  final TextEditingController _nameController = TextEditingController();
  int _parentAge = 30;
  String _parentGender = 'Male';
  String _selectedPhotoURL = '';
  bool _useCustomPhoto = false;

  // Step 2: City & Area
  String _selectedCity = 'London';
  String _selectedArea = 'Westminster';
  bool _enterDirectly = true;
  double? _latitude = 51.5074;
  double? _longitude = -0.1278;
  String _streetAddress = '';

  final TextEditingController _streetCtrl = TextEditingController();
  final TextEditingController _houseNoCtrl = TextEditingController();
  final TextEditingController _postcodeCtrl = TextEditingController();

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

  // Male & Female built-in avatar presets
  final List<String> _maleAvatars = [
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
  ];
  final List<String> _femaleAvatars = [
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
  ];

  String _getAreaFromLatLng(double lat, double lng) {
    if (lat > 51.52) return 'Camden';
    if (lng < -0.18) return 'Hammersmith';
    if (lat < 51.49) return 'Chelsea';
    return 'Westminster';
  }

  // Step 3: Children Profiles
  final List<Map<String, dynamic>> _tempChildren = [];

  // Available Schools List
  List<School> _availableSchools = [];

  final List<String> _grades = ['Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8', 'Year 9', 'Year 10'];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    _loadInitialUserData();
    _loadSchools();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    _nameController.dispose();
    _streetCtrl.dispose();
    _houseNoCtrl.dispose();
    _postcodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (user != null) {
      _nameController.text = user.displayName;
      if (user.city.isNotEmpty) _selectedCity = user.city;
      if (user.area.isNotEmpty) _selectedArea = user.area;
      if (user.photoURL.isNotEmpty) {
        _selectedPhotoURL = user.photoURL;
        if (!user.photoURL.startsWith('http')) {
          _useCustomPhoto = true;
        }
      }
      if (user.age != null) _parentAge = user.age!;
      if (user.gender != null && user.gender!.isNotEmpty) _parentGender = user.gender!;
    }
  }

  Future<void> _loadSchools() async {
    final schools = await ref.read(schoolRepositoryProvider).getSchools();
    setState(() {
      _availableSchools = schools;
    });
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _fadeController.reset();
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _fadeController.reset();
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    }
  }

  String _getDefaultPhoto() {
    if (_selectedPhotoURL.isNotEmpty) return _selectedPhotoURL;
    final avatars = _parentGender == 'Male' ? _maleAvatars : _femaleAvatars;
    return avatars.first;
  }

  void _showPhotoPickerSheet(bool isDark, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final avatars = _parentGender == 'Male' ? _maleAvatars : _femaleAvatars;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const Text('Choose Profile Photo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Pick a built-in character or upload your own photo', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54)),
                const SizedBox(height: 20),

                // Built-in character avatars
                Text('${_parentGender} Characters', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatars.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final url = avatars[i];
                      final isSelected = _selectedPhotoURL == url;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPhotoURL = url);
                          Navigator.pop(ctx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundImage: NetworkImage(url),
                            child: isSelected ? Container(
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black38),
                              child: const Icon(Icons.check, color: Colors.white, size: 28),
                            ) : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Upload from phone
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setState(() {
                          _useCustomPhoto = true;
                          _selectedPhotoURL = picked.path;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Photo selected!'),
                                ],
                              ),
                              backgroundColor: primaryColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Upload from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                      if (picked != null) {
                        setState(() {
                          _useCustomPhoto = true;
                          _selectedPhotoURL = picked.path;
                        });
                      }
                    },
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMapPickerDialog() {
    double tempLat = _latitude ?? 51.5074;
    double tempLng = _longitude ?? -0.1278;
    String tempArea = _selectedArea;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = Theme.of(context).primaryColor;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pinpoint Location on Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            RippleMapView(
                              height: MediaQuery.of(context).size.height * 0.7 - 160,
                              onTap: () {},
                            ),
                            // Area selector buttons overlaid on map
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAreaChip('Westminster', 51.5074, -0.1278, setDialogState, (lat, lng, area) {
                                    tempLat = lat; tempLng = lng; tempArea = area;
                                  }, primaryColor),
                                  const SizedBox(width: 8),
                                  _buildAreaChip('Chelsea', 51.4875, -0.1687, setDialogState, (lat, lng, area) {
                                    tempLat = lat; tempLng = lng; tempArea = area;
                                  }, primaryColor),
                                  const SizedBox(width: 8),
                                  _buildAreaChip('Camden', 51.5390, -0.1425, setDialogState, (lat, lng, area) {
                                    tempLat = lat; tempLng = lng; tempArea = area;
                                  }, primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Selected Location', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                      Text('$tempArea, London (${tempLat.toStringAsFixed(4)}, ${tempLng.toStringAsFixed(4)})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedCity = 'London';
                                  _selectedArea = tempArea;
                                  _latitude = tempLat;
                                  _longitude = tempLng;
                                  _streetCtrl.text = 'Street ${tempLat.toStringAsFixed(4)}';
                                  _houseNoCtrl.text = 'Flat ${(tempLng * 100).abs().toStringAsFixed(0)}';
                                  _postcodeCtrl.text = 'SW1A 1AA';
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Confirm Location Pin', style: TextStyle(fontWeight: FontWeight.w900)),
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

  Widget _buildAreaChip(
    String label,
    double lat,
    double lng,
    StateSetter setDialogState,
    void Function(double, double, String) onTap,
    Color primaryColor,
  ) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
      backgroundColor: primaryColor.withOpacity(0.08),
      side: BorderSide(color: primaryColor.withOpacity(0.2)),
      onPressed: () {
        setDialogState(() {
          onTap(lat, lng, label);
        });
      },
    );
  }

  void _showAddChildSetupDialog() {
    final nameController = TextEditingController();
    int age = 9;
    String grade = 'Year 5';
    String schoolId = _availableSchools.isNotEmpty ? _availableSchools.first.schoolId : '';
    List<String> targetSchoolIds = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = Theme.of(context).primaryColor;

            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add Child Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('CHILD NAME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'First Name Only (for privacy)',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: age,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                items: List.generate(11, (i) => i + 5).map((a) => DropdownMenuItem(value: a, child: Text('$a years'))).toList(),
                                onChanged: (val) { if (val != null) setModalState(() => age = val); },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('GRADE YEAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: grade,
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (val) { if (val != null) setModalState(() => grade = val); },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('CURRENT SCHOOL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    if (_availableSchools.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: schoolId.isEmpty ? _availableSchools.first.schoolId : schoolId,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                        items: _availableSchools.map((sch) => DropdownMenuItem(value: sch.schoolId, child: Text(sch.name, maxLines: 1, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) { if (val != null) setModalState(() => schoolId = val); },
                      )
                    else
                      const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('DESIRED TARGET SCHOOLS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    if (_availableSchools.isNotEmpty)
                      Column(
                        children: _availableSchools.map((sch) {
                          final isSelected = targetSchoolIds.contains(sch.schoolId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor.withOpacity(0.08) : (isDark ? const Color(0xFF1E293B).withOpacity(0.4) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? primaryColor : Colors.black.withOpacity(0.04), width: 1.5),
                            ),
                            child: CheckboxListTile(
                              title: Text(sch.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(sch.area, style: const TextStyle(fontSize: 11)),
                              value: isSelected,
                              activeColor: primaryColor,
                              checkColor: Colors.black,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) targetSchoolIds.add(sch.schoolId);
                                  else targetSchoolIds.remove(sch.schoolId);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter child\'s first name')));
                            return;
                          }
                          if (targetSchoolIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one desired target school')));
                            return;
                          }
                          setState(() {
                            _tempChildren.add({
                              'childId': 'child_temp_${DateTime.now().millisecondsSinceEpoch}',
                              'firstName': nameController.text.trim(),
                              'gradeYear': grade,
                              'currentSchoolId': schoolId,
                              'targetSchoolIds': List<String>.from(targetSchoolIds),
                              'status': 'active',
                              'age': age,
                            });
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Add Child Profile', style: TextStyle(fontWeight: FontWeight.w900)),
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
  }

  Future<void> _saveAll() async {
    if (_tempChildren.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one child profile to continue')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final currentUser = await authRepo.getCurrentUser();

      if (currentUser != null) {
        final photoUrl = _selectedPhotoURL.isNotEmpty ? _selectedPhotoURL : _getDefaultPhoto();
        final updatedUser = currentUser.copyWith(
          displayName: _nameController.text.trim(),
          city: _selectedCity,
          area: _selectedArea,
          verified: _isVerifiedSimulated,
          streetAddress: _streetCtrl.text.trim(),
          houseNo: _houseNoCtrl.text.trim(),
          postcode: _postcodeCtrl.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          photoURL: photoUrl,
          age: _parentAge,
          gender: _parentGender,
        );
        await userRepo.saveUserProfile(updatedUser);

        // Add Children safely
        for (var c in _tempChildren) {
          final List<String> targetIds = List<String>.from(c['targetSchoolIds'] ?? []);
          final child = Child(
            childId: c['childId'] as String,
            firstName: c['firstName'] as String,
            gradeYear: c['gradeYear'] as String,
            currentSchoolId: c['currentSchoolId'] as String,
            targetSchoolIds: targetIds,
            status: c['status'] as String,
            age: (c['age'] as int?) ?? 9,
          );
          await userRepo.addChild(currentUser.uid, child);
        }

        if (mounted) {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Bar with close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _prevStep,
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Step ${_currentStep + 1} of 4',
                          style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / 4,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white12 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Cross/Close button for convenience during setup
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Exit Setup?', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('Your progress won\'t be saved. You can complete setup later from the home screen.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Going')),
                            ElevatedButton(
                              onPressed: () { Navigator.pop(ctx); context.go('/home'); },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Exit'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.black38),
                  ),
                ],
              ),
            ),

            // Steps Pages
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStepParentDetails(isDark, primaryColor),
                    _buildStepLocation(isDark, primaryColor),
                    _buildStepChildren(isDark, primaryColor),
                    _buildStepReview(isDark, primaryColor),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _prevStep,
                      child: Text('Back', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox.shrink(),

                  _currentStep == 3
                      ? SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveAll,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : const Text('Finish Setup', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        )
                      : SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name')));
                                return;
                              }
                              if (_currentStep == 2 && _tempChildren.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one child profile')));
                                return;
                              }
                              _nextStep();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text('Next Step', style: TextStyle(fontWeight: FontWeight.w900)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
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

  // STEP 1: Parent Profile Details — now includes name, age, gender, photo
  Widget _buildStepParentDetails(bool isDark, Color primaryColor) {
    final displayPhoto = _selectedPhotoURL.isNotEmpty ? _selectedPhotoURL : (_parentGender == 'Male' ? _maleAvatars.first : _femaleAvatars.first);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Create Parent Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Tell us about yourself so matching families can connect with you.', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 28),

          // Profile Photo
          Center(
            child: GestureDetector(
              onTap: () => _showPhotoPickerSheet(isDark, primaryColor),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundImage: getRippleImageProvider(displayPhoto),
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  Positioned(
                    bottom: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor, border: Border.all(color: isDark ? Colors.black : Colors.white, width: 2)),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Tap to change photo', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 28),

          // Gender Selection
          const Text('GENDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: ['Male', 'Female'].map((g) {
              final isSelected = _parentGender == g;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: g == 'Male' ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _parentGender = g;
                        // Reset photo to match gender
                        if (!_useCustomPhoto) _selectedPhotoURL = '';
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor.withOpacity(0.15) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? primaryColor : Colors.black.withOpacity(0.08), width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(g == 'Male' ? Icons.male_rounded : Icons.female_rounded, color: isSelected ? primaryColor : Colors.grey, size: 20),
                          const SizedBox(width: 6),
                          Text(g, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? primaryColor : (isDark ? Colors.white60 : Colors.black54))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // Parent Name
          const Text('FULL NAME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),

          const SizedBox(height: 22),

          // Parent Age
          const Text('AGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _parentAge,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              prefixIcon: const Icon(Icons.cake_outlined, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
            items: List.generate(50, (i) => i + 18).map((a) => DropdownMenuItem(value: a, child: Text('$a years old'))).toList(),
            onChanged: (val) { if (val != null) setState(() => _parentAge = val); },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // STEP 2: City & Area Selection
  Widget _buildStepLocation(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Where Do You Live?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('We match you with nearby school-swapping routes. Home addresses are never shown to ensure complete privacy.', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Enter Directly', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: _enterDirectly,
                  selectedColor: primaryColor,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (val) { if (val) setState(() => _enterDirectly = true); },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Select on Map', style: TextStyle(fontWeight: FontWeight.bold))),
                  selected: !_enterDirectly,
                  selectedColor: primaryColor,
                  backgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (val) { if (val) setState(() => _enterDirectly = false); },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_enterDirectly) ...[
            const Text('TOWN / CITY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _selectedCity),
              optionsBuilder: (TextEditingValue textEditingValue) {
                return _ukCities.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                setState(() {
                  _selectedCity = selection;
                  final subs = _ukSubLocations[selection] ?? [];
                  if (subs.isNotEmpty) _selectedArea = subs.first;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search UK Town / City',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    prefixIcon: const Icon(Icons.location_city_rounded, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text('AREA / BOROUGH', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _selectedArea),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final list = _ukSubLocations[_selectedCity] ?? [];
                return list.where((option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) { setState(() => _selectedArea = selection); },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search Area / Neighbourhood',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    prefixIcon: const Icon(Icons.holiday_village_rounded, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('STREET NAME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _streetCtrl,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'e.g. Baker Street',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('HOUSE / FLAT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _houseNoCtrl,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: '221B',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('POSTCODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            TextField(
              controller: _postcodeCtrl,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'e.g. NW1 6XE',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                prefixIcon: const Icon(Icons.markunread_mailbox_rounded, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
            ),
            const SizedBox(height: 30),
          ] else ...[
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(Icons.map_rounded, color: primaryColor, size: 64),
                  const SizedBox(height: 16),
                  const Text('Pinpoint Your Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  const Text('Use Google Maps to drop a marker on your home location.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showMapPickerDialog,
                    icon: const Icon(Icons.my_location_rounded, color: Colors.black),
                    label: const Text('Open Map Picker', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pinpoint Saved!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Coords: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Text('Area: $_selectedArea, $_selectedCity', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
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
        ],
      ),
    );
  }

  // STEP 3: Child Profiles
  Widget _buildStepChildren(bool isDark, Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Add Your Children', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Add details for the child or children you want to swap schools for.', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 24),

          if (_tempChildren.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.08)),
                      child: Icon(Icons.child_care_rounded, color: primaryColor, size: 54),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Children Added Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    const Text('Add at least one child profile to find match candidates.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tempChildren.length,
              itemBuilder: (context, index) {
                final c = _tempChildren[index];
                final schoolList = _availableSchools;
                String schoolName = 'Unknown School';
                if (schoolList.isNotEmpty) {
                  try {
                    final found = schoolList.firstWhere((s) => s.schoolId == c['currentSchoolId']);
                    schoolName = found.name;
                  } catch (_) {
                    schoolName = schoolList.first.name;
                  }
                }
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withOpacity(0.12),
                      child: Icon(Icons.child_care_rounded, color: primaryColor),
                    ),
                    title: Text('${c['firstName']} (Age ${c['age']} • ${c['gradeYear']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Current: $schoolName', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      onPressed: () => setState(() => _tempChildren.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _showAddChildSetupDialog,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add Child Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // STEP 4: Review and Confirm
  Widget _buildStepReview(bool isDark, Color primaryColor) {
    final displayPhoto = _selectedPhotoURL.isNotEmpty ? _selectedPhotoURL : _getDefaultPhoto();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Confirm Profile', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text('Please review your details before completing setup.', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundImage: getRippleImageProvider(displayPhoto), radius: 28),
                  title: Row(
                    children: [
                      Text(_nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Parent', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (_isVerifiedSimulated) ...[const SizedBox(width: 6), const VerifiedBadge(size: 16)],
                    ],
                  ),
                  subtitle: Text('$_parentGender • Age $_parentAge • $_selectedArea, $_selectedCity'),
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                const Text('CHILDREN FOR SWAP:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                const SizedBox(height: 12),
                if (_tempChildren.isEmpty)
                  const Text('No children added yet.', style: TextStyle(color: Colors.grey))
                else
                  ..._tempChildren.map((c) {
                    // Safely find school name
                    String curSchoolName = 'Unknown';
                    String targets = 'None selected';
                    if (_availableSchools.isNotEmpty) {
                      try {
                        final cs = _availableSchools.firstWhere((s) => s.schoolId == c['currentSchoolId']);
                        curSchoolName = cs.name;
                      } catch (_) {
                        curSchoolName = _availableSchools.first.name;
                      }
                      final targetIds = List<String>.from(c['targetSchoolIds'] ?? []);
                      final targetNames = _availableSchools.where((s) => targetIds.contains(s.schoolId)).map((s) => s.name);
                      targets = targetNames.isNotEmpty ? targetNames.join(', ') : 'None selected';
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.subdirectory_arrow_right_rounded, size: 16, color: primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
                                children: [
                                  TextSpan(text: '${c['firstName']} (Age ${c['age']} • ${c['gradeYear']})\n', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: 'Current: $curSchoolName\n', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  TextSpan(text: 'Desired: $targets', style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Verification
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: Color(0xFF10B981)),
                    SizedBox(width: 10),
                    Expanded(child: Text('Instant Seat Verification (Optional)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Upload your student enrollment letter to get a verified badge and unlock direct connection matches.', style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
                const SizedBox(height: 16),
                _isVerifiedSimulated
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                            SizedBox(width: 8),
                            Text('Document Verified Successfully!', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _isVerifiedSimulated = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Admission letter simulated upload. Parent verified!'), backgroundColor: Color(0xFF10B981)),
                            );
                          },
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: const Text('Simulate Verification Document', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
