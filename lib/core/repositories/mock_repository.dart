import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ripple_models.dart';
import 'ripple_repository.dart';

class MockDatabase {
  // In-Memory Database Store
  RippleUser? currentUser;
  final List<Child> myChildren = [];
  final List<School> schools = [];
  final List<RippleUser> otherUsers = [];
  final List<Child> otherChildren = [];
  final List<MatchModel> matches = [];
  final Map<String, List<Message>> messageStore = {};
  final List<Conversation> conversations = [];
  final Map<String, String> registeredMockAccounts = {};
  final Map<String, List<Child>> userChildrenMap = {};
  final List<AppNotification> notifications = [];

  // Stream controllers to simulate live updates
  final StreamController<RippleUser?> _authController = StreamController<RippleUser?>.broadcast();
  final Map<String, StreamController<List<Message>>> _chatMessageControllers = {};
  final StreamController<List<Conversation>> _conversationsController = StreamController<List<Conversation>>.broadcast();
  final StreamController<List<AppNotification>> _notificationsController = StreamController<List<AppNotification>>.broadcast();

  // Singleton instance
  // Singleton instance
  static final MockDatabase instance = MockDatabase._internal();

  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await _loadFromPrefs();
    _initialized = true;
  }

  Map<String, dynamic> toJsonCompatibleMap(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    copy.forEach((key, value) {
      if (value is Timestamp) {
        copy[key] = {'_type': 'timestamp', 'ms': value.millisecondsSinceEpoch};
      } else if (value is Map) {
        copy[key] = toJsonCompatibleMap(value.cast<String, dynamic>());
      } else if (value is List) {
        copy[key] = value.map((e) {
          if (e is Map) return toJsonCompatibleMap(e.cast<String, dynamic>());
          return e;
        }).toList();
      }
    });
    return copy;
  }

  Map<String, dynamic> fromJsonCompatibleMap(Map<String, dynamic> map) {
    final copy = Map<String, dynamic>.from(map);
    copy.forEach((key, value) {
      if (value is Map && value['_type'] == 'timestamp') {
        copy[key] = Timestamp.fromMillisecondsSinceEpoch(value['ms'] as int);
      } else if (value is Map) {
        copy[key] = fromJsonCompatibleMap(value.cast<String, dynamic>());
      } else if (value is List) {
        copy[key] = value.map((e) {
          if (e is Map) return fromJsonCompatibleMap(e.cast<String, dynamic>());
          return e;
        }).toList();
      }
    });
    return copy;
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (currentUser != null) {
        await prefs.setString('mock_current_user', jsonEncode(toJsonCompatibleMap(currentUser!.toMap())));
      } else {
        await prefs.remove('mock_current_user');
      }
      
      await prefs.setString('mock_my_children', jsonEncode(myChildren.map((c) => toJsonCompatibleMap(c.toMap())).toList()));
      await prefs.setString('mock_other_users', jsonEncode(otherUsers.map((u) => toJsonCompatibleMap(u.toMap())).toList()));
      await prefs.setString('mock_other_children', jsonEncode(otherChildren.map((c) => toJsonCompatibleMap(c.toMap())).toList()));
      await prefs.setString('mock_matches', jsonEncode(matches.map((m) => toJsonCompatibleMap(m.toMap())).toList()));
      
      final serializedMessageStore = messageStore.map((key, val) => 
        MapEntry(key, val.map((m) => toJsonCompatibleMap(m.toMap())).toList())
      );
      await prefs.setString('mock_message_store', jsonEncode(serializedMessageStore));
      
      await prefs.setString('mock_conversations', jsonEncode(conversations.map((c) => toJsonCompatibleMap(c.toMap())).toList()));
      await prefs.setString('mock_registered_accounts', jsonEncode(registeredMockAccounts));
      
      final serializedUserChildrenMap = userChildrenMap.map((key, val) =>
        MapEntry(key, val.map((c) => toJsonCompatibleMap(c.toMap())).toList())
      );
      await prefs.setString('mock_user_children_map', jsonEncode(serializedUserChildrenMap));
      
      await prefs.setString('mock_notifications', jsonEncode(notifications.map((n) => toJsonCompatibleMap(n.toMap())).toList()));
      
      developer.log("Mock Database saved to SharedPreferences successfully.");
    } catch (e) {
      developer.log("Error saving Mock Database to prefs: $e");
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final currentUserStr = prefs.getString('mock_current_user');
      if (currentUserStr != null) {
        currentUser = RippleUser.fromMap(fromJsonCompatibleMap(jsonDecode(currentUserStr)));
      }
      
      final myChildrenStr = prefs.getString('mock_my_children');
      if (myChildrenStr != null) {
        myChildren.clear();
        final list = jsonDecode(myChildrenStr) as List;
        myChildren.addAll(list.map((c) => Child.fromMap(fromJsonCompatibleMap(c as Map<String, dynamic>))));
      }
      
      final otherUsersStr = prefs.getString('mock_other_users');
      if (otherUsersStr != null) {
        otherUsers.clear();
        final list = jsonDecode(otherUsersStr) as List;
        otherUsers.addAll(list.map((u) => RippleUser.fromMap(fromJsonCompatibleMap(u as Map<String, dynamic>))));
      }
      
      final otherChildrenStr = prefs.getString('mock_other_children');
      if (otherChildrenStr != null) {
        otherChildren.clear();
        final list = jsonDecode(otherChildrenStr) as List;
        otherChildren.addAll(list.map((c) => Child.fromMap(fromJsonCompatibleMap(c as Map<String, dynamic>))));
      }
      
      final matchesStr = prefs.getString('mock_matches');
      if (matchesStr != null) {
        matches.clear();
        final list = jsonDecode(matchesStr) as List;
        matches.addAll(list.map((m) => MatchModel.fromMap(fromJsonCompatibleMap(m as Map<String, dynamic>))));
      }
      
      final messageStoreStr = prefs.getString('mock_message_store');
      if (messageStoreStr != null) {
        messageStore.clear();
        final map = jsonDecode(messageStoreStr) as Map<String, dynamic>;
        map.forEach((key, val) {
          final list = val as List;
          messageStore[key] = list.map((m) => Message.fromMap(fromJsonCompatibleMap(m as Map<String, dynamic>))).toList();
        });
      }
      
      final conversationsStr = prefs.getString('mock_conversations');
      if (conversationsStr != null) {
        conversations.clear();
        final list = jsonDecode(conversationsStr) as List;
        conversations.addAll(list.map((c) => Conversation.fromMap(fromJsonCompatibleMap(c as Map<String, dynamic>))));
      }
      
      final registeredAccountsStr = prefs.getString('mock_registered_accounts');
      if (registeredAccountsStr != null) {
        registeredMockAccounts.clear();
        final map = jsonDecode(registeredAccountsStr) as Map<String, dynamic>;
        map.forEach((key, val) {
          registeredMockAccounts[key] = val.toString();
        });
      }
      
      final userChildrenMapStr = prefs.getString('mock_user_children_map');
      if (userChildrenMapStr != null) {
        userChildrenMap.clear();
        final map = jsonDecode(userChildrenMapStr) as Map<String, dynamic>;
        map.forEach((key, val) {
          final list = val as List;
          userChildrenMap[key] = list.map((c) => Child.fromMap(fromJsonCompatibleMap(c as Map<String, dynamic>))).toList();
        });
      }
      
      final notificationsStr = prefs.getString('mock_notifications');
      if (notificationsStr != null) {
        notifications.clear();
        final list = jsonDecode(notificationsStr) as List;
        notifications.addAll(list.map((n) => AppNotification.fromMap(fromJsonCompatibleMap(n as Map<String, dynamic>))));
      }
      
      developer.log("Mock Database loaded from SharedPreferences successfully.");
    } catch (e) {
      developer.log("Error loading Mock Database from prefs: $e");
    }
  }

  MockDatabase._internal() {
    _initData();
  }

  void notifyNotifications() => _notificationsController.add(List.from(notifications));

  Stream<List<AppNotification>> getNotificationsStream() {
    Timer(Duration.zero, () => notifyNotifications());
    return _notificationsController.stream;
  }

  void _initData() {

    // Populate default registered accounts
    registeredMockAccounts['oliver@gmail.com'] = '123456';
    registeredMockAccounts['oliver.smith@gmail.com'] = '123456';
    registeredMockAccounts['emma@gmail.com'] = '123456';
    registeredMockAccounts['george@gmail.com'] = '123456';
    registeredMockAccounts['sophie@gmail.com'] = '123456';
    registeredMockAccounts['john@gmail.com'] = '123456';
    registeredMockAccounts['sarah@gmail.com'] = '123456';
    registeredMockAccounts['michael@gmail.com'] = '123456';

    // 1. Initial Current User
    currentUser = RippleUser(
      uid: 'user_oliver',
      displayName: 'Oliver Smith',
      email: 'oliver@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', // Mock photo
      area: 'Westminster',
      city: 'London',
      verified: true,
      subscriptionTier: 'free',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastActive: DateTime.now(),
      phoneNumber: '+44 7911 123456',
    );

    // 2. Mock Schools in London
    schools.addAll([
      School(
        schoolId: 'sch_westminster',
        name: 'Harris Academy Westminster',
        area: 'Westminster',
        city: 'London',
        lat: 51.4980,
        lng: -0.1360,
        gradesOffered: ['Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8', 'Year 9', 'Year 10'],
        transferRatePerTerm: 12,
        interestedCount: 8,
      ),
      School(
        schoolId: 'sch_stpauls',
        name: 'St Paul\'s School',
        area: 'Hammersmith',
        city: 'London',
        lat: 51.4880,
        lng: -0.2280,
        gradesOffered: ['Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8', 'Year 9', 'Year 10'],
        transferRatePerTerm: 15,
        interestedCount: 14,
      ),
      School(
        schoolId: 'sch_westminstersch',
        name: 'Westminster Under School',
        area: 'Westminster',
        city: 'London',
        lat: 51.4990,
        lng: -0.1330,
        gradesOffered: ['Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8'],
        transferRatePerTerm: 9,
        interestedCount: 11,
      ),
      School(
        schoolId: 'sch_camdengirls',
        name: 'Camden School for Girls',
        area: 'Camden',
        city: 'London',
        lat: 51.5450,
        lng: -0.1410,
        gradesOffered: ['Year 4', 'Year 5', 'Year 6', 'Year 7', 'Year 8'],
        transferRatePerTerm: 8,
        interestedCount: 7,
      ),
    ]);

    // 3. Current User's Child
    myChildren.add(
      Child(
        childId: 'child_jack',
        firstName: 'Jack',
        gradeYear: 'Year 5',
        currentSchoolId: 'sch_westminster',
        targetSchoolIds: ['sch_westminstersch'],
        status: 'active',
        age: 9,
      ),
    );

    // 4. Other Families (to create matches)
    // Family B (Complementary Swap)
    final emma = RippleUser(
      uid: 'user_emma',
      displayName: 'Emma Watson',
      email: 'emma@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      area: 'Chelsea', // Lives in Chelsea
      city: 'London',
      verified: true,
      subscriptionTier: 'premium',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      phoneNumber: '+44 7911 234567',
      latitude: 51.4875,
      longitude: -0.1682,
    );
    otherUsers.add(emma);

    final emmaChild = Child(
      childId: 'child_chloe',
      firstName: 'Chloe',
      gradeYear: 'Year 5', // Same grade
      currentSchoolId: 'sch_westminstersch', // Studies at Westminster Under School
      targetSchoolIds: ['sch_westminster'], // Desires Harris Academy
      status: 'active',
      age: 9,
    );
    otherChildren.add(emmaChild);

    // Family C (Partial Match - Grade Match, Close Target)
    final george = RippleUser(
      uid: 'user_george',
      displayName: 'George Bentley',
      email: 'george@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
      area: 'Camden',
      city: 'London',
      verified: false,
      subscriptionTier: 'free',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      lastActive: DateTime.now().subtract(const Duration(days: 1)),
      phoneNumber: '+44 7911 345678',
      latitude: 51.5422,
      longitude: -0.1432,
    );
    otherUsers.add(george);

    final georgeChild = Child(
      childId: 'child_leo',
      firstName: 'Leo',
      gradeYear: 'Year 5',
      currentSchoolId: 'sch_stpauls', // Studies near Hammersmith
      targetSchoolIds: ['sch_westminster'], // Desires Harris Academy
      status: 'active',
      age: 9,
    );
    otherChildren.add(georgeChild);

    // Family D (Close Area, different grade)
    final sophie = RippleUser(
      uid: 'user_sophie',
      displayName: 'Sophie Davies',
      email: 'sophie@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      area: 'Westminster',
      city: 'London',
      verified: true,
      subscriptionTier: 'free',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 45)),
      phoneNumber: '+44 7911 456789',
      latitude: 51.4975,
      longitude: -0.1355,
    );
    otherUsers.add(sophie);

    final sophieChild = Child(
      childId: 'child_lucas',
      firstName: 'Lucas',
      gradeYear: 'Year 6', // Adjacent Grade
      currentSchoolId: 'sch_camdengirls',
      targetSchoolIds: ['sch_westminster'],
      status: 'active',
      age: 10,
    );
    otherChildren.add(sophieChild);

    // Family E: John Doe (for testing)
    final john = RippleUser(
      uid: 'user_john',
      displayName: 'John Doe',
      email: 'john@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      area: 'Camden',
      city: 'London',
      verified: true,
      subscriptionTier: 'free',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      lastActive: DateTime.now().subtract(const Duration(hours: 4)),
      phoneNumber: '+44 7911 567890',
      latitude: 51.5435,
      longitude: -0.1405,
    );
    otherUsers.add(john);

    final johnChild = Child(
      childId: 'child_johnny',
      firstName: 'Johnny',
      gradeYear: 'Year 5',
      currentSchoolId: 'sch_camdengirls',
      targetSchoolIds: ['sch_westminster'],
      status: 'active',
      age: 9,
    );
    otherChildren.add(johnChild);

    // Family F: Sarah Jenkins (for testing)
    final sarah = RippleUser(
      uid: 'user_sarah',
      displayName: 'Sarah Jenkins',
      email: 'sarah@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      area: 'Chelsea',
      city: 'London',
      verified: false,
      subscriptionTier: 'premium',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      lastActive: DateTime.now().subtract(const Duration(hours: 1)),
      phoneNumber: '+44 7911 678901',
      latitude: 51.4860,
      longitude: -0.1700,
    );
    otherUsers.add(sarah);

    final sarahChild = Child(
      childId: 'child_lily',
      firstName: 'Lily',
      gradeYear: 'Year 5',
      currentSchoolId: 'sch_westminstersch',
      targetSchoolIds: ['sch_stpauls'],
      status: 'active',
      age: 9,
    );
    otherChildren.add(sarahChild);

    // Family G: Michael Carter (for testing)
    final michael = RippleUser(
      uid: 'user_michael',
      displayName: 'Michael Carter',
      email: 'michael@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      area: 'Westminster',
      city: 'London',
      verified: true,
      subscriptionTier: 'free',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      phoneNumber: '+44 7911 789012',
      latitude: 51.4965,
      longitude: -0.1390,
    );
    otherUsers.add(michael);

    final michaelChild = Child(
      childId: 'child_ethan',
      firstName: 'Ethan',
      gradeYear: 'Year 6',
      currentSchoolId: 'sch_westminster',
      targetSchoolIds: ['sch_camdengirls'],
      status: 'active',
      age: 10,
    );
    otherChildren.add(michaelChild);

    // Populate userChildrenMap
    userChildrenMap['user_oliver'] = [myChildren.first];
    userChildrenMap['user_emma'] = [emmaChild];
    userChildrenMap['user_george'] = [georgeChild];
    userChildrenMap['user_sophie'] = [sophieChild];
    userChildrenMap['user_john'] = [johnChild];
    userChildrenMap['user_sarah'] = [sarahChild];
    userChildrenMap['user_michael'] = [michaelChild];

    // 5. Generate Matches
    _recalculateMatches();

    // 6. Setup Initial Conversations & Messages
    final complMatch = matches.firstWhere((m) => m.familyB_uid == 'user_emma');
    final chatId = 'chat_${complMatch.matchId}';
    
    conversations.add(
      Conversation(
        chatId: chatId,
        matchId: complMatch.matchId,
        participants: ['user_oliver', 'user_emma'],
        lastMessage: 'Emma accepted your connection request.',
        lastAt: DateTime.now().subtract(const Duration(hours: 1)),
        checklistA: {'applied': true, 'confirmed': false, 'moveDate': false},
        checklistB: {'applied': false, 'confirmed': false, 'moveDate': false},
        moveConfirmed: false,
      ),
    );

    messageStore[chatId] = [
      Message(
        messageId: 'msg_1',
        senderUid: 'user_emma',
        text: 'Hi Oliver! I saw we got a 95% match. My child Chloe is in Year 5 at Westminster Under School, and we want to move her to Harris Academy Westminster because it is much closer to our new home in Chelsea.',
        type: 'text',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        readBy: ['user_oliver', 'user_emma'],
      ),
      Message(
        messageId: 'msg_2',
        senderUid: 'user_oliver',
        text: 'Hi Emma! Yes, our child Jack studies at Harris Academy Westminster but Westminster Under School is right near our area in Westminster. It makes perfect sense to swap!',
        type: 'text',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
        readBy: ['user_oliver', 'user_emma'],
      ),
      Message(
        messageId: 'msg_3',
        senderUid: 'user_emma',
        text: 'Wonderful! Let\'s coordinate the paperwork. I will prepare the application form.',
        type: 'text',
        createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        readBy: ['user_oliver', 'user_emma'],
      ),
      Message(
        messageId: 'sys_1',
        senderUid: 'system',
        text: 'Oliver Smith has marked checklist: "Submitted Transfer Form"',
        type: 'system',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        readBy: ['user_oliver', 'user_emma'],
      ),
    ];

    notifications.addAll([
      AppNotification(
        id: 'not_1',
        title: 'New Match Found!',
        body: 'A 95% swap match is available for Oliver: Harris Academy ⇄ Westminster Under School.',
        category: 'match',
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isRead: false,
      ),
      AppNotification(
        id: 'not_2',
        title: 'Admissions Openings',
        body: '3 seats opened up for Year 4 transfers at Westminster Under School (Westminster).',
        category: 'school',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      AppNotification(
        id: 'not_3',
        title: 'Incoming Message',
        body: 'Emma Watson: "Hi Oliver! Yes, our child Jack..."',
        category: 'chat',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      AppNotification(
        id: 'not_4',
        title: 'Deadline Reminder',
        body: 'Optimal Autumn Term transfer applications close in 5 days. Apply now!',
        category: 'school',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);
  }


  void _recalculateMatches() {
    matches.clear();
    if (currentUser == null || myChildren.isEmpty) return;

    final myChild = myChildren.first;

    for (int i = 0; i < otherUsers.length; i++) {
      final user = otherUsers[i];
      final child = (userChildrenMap[user.uid]?.isNotEmpty ?? false)
          ? userChildrenMap[user.uid]!.first
          : (i < otherChildren.length ? otherChildren[i] : null);
      if (child == null) continue;

      // Calculate compatibility score logic
      double distanceFit = 0.0;
      double gradeMatch = 0.0;
      double timingReadiness = 20.0; // Assume ready for simplicity
      double profileCompleteness = 10.0;

      // Distance calculation simulation
      double distance = 4.2; // default
      if (user.uid == 'user_emma') {
        distanceFit = 40.0;
        distance = 3.5;
      } else if (user.uid == 'user_george') {
        distanceFit = 30.0;
        distance = 5.1;
      } else if (user.uid == 'user_sophie') {
        distanceFit = 35.0;
        distance = 1.2;
      }

      // Grade Match
      if (myChild.gradeYear == child.gradeYear) {
        gradeMatch = 30.0; // Same grade
      } else {
        gradeMatch = 15.0; // Adjacent grade
      }

      double score = distanceFit + gradeMatch + timingReadiness + profileCompleteness;

      matches.add(
        MatchModel(
          matchId: 'match_${user.uid}',
          familyA_uid: currentUser!.uid,
          familyB_uid: user.uid,
          childA_id: myChild.childId,
          childB_id: child.childId,
          compatibilityScore: score,
          distanceKm: distance,
          status: user.uid == 'user_emma' ? 'connected' : 'pending',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      );
    }
  }

  void notifyAuth() => _authController.add(currentUser);
  void notifyConversations() => _conversationsController.add(List.from(conversations));
  
  void notifyMessages(String chatId) {
    if (_chatMessageControllers.containsKey(chatId)) {
      _chatMessageControllers[chatId]!.add(List.from(messageStore[chatId] ?? []));
    }
  }

  Stream<List<Message>> getMessageStream(String chatId) {
    if (!_chatMessageControllers.containsKey(chatId)) {
      _chatMessageControllers[chatId] = StreamController<List<Message>>.broadcast();
    }
    // Seed initial messages asynchronously
    Timer(Duration.zero, () => notifyMessages(chatId));
    return _chatMessageControllers[chatId]!.stream;
  }

  Stream<List<Conversation>> getConversationsStream() {
    Timer(Duration.zero, () => notifyConversations());
    return _conversationsController.stream;
  }
}

// Mock Implementations of Repositories
class MockAuthRepository implements IAuthRepository {
  final MockDatabase _db = MockDatabase.instance;

  Future<void> _loadMockAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('mock_registered_accounts');
      if (jsonStr != null) {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr);
        decoded.forEach((key, value) {
          _db.registeredMockAccounts[key.toLowerCase().trim()] = value.toString();
        });
      }
    } catch (e) {
      developer.log("Error loading mock accounts: $e");
    }
  }

  Future<void> _saveMockAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_registered_accounts', jsonEncode(_db.registeredMockAccounts));
    } catch (e) {
      developer.log("Error saving mock accounts: $e");
    }
  }

  @override
  Future<RippleUser?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _loadMockAccounts();
    if (_db.currentUser == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedEmail = prefs.getString('mock_user_email');
        if (savedEmail != null) {
          final normalizedEmail = savedEmail.toLowerCase().trim();
          if (normalizedEmail == 'oliver@gmail.com' || normalizedEmail == 'oliver.smith@gmail.com') {
            _db.currentUser = RippleUser(
              uid: 'user_oliver',
              displayName: 'Oliver Smith',
              email: savedEmail,
              photoURL: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
              area: 'Westminster',
              city: 'London',
              verified: true,
              subscriptionTier: 'free',
              createdAt: DateTime.now().subtract(const Duration(days: 30)),
              lastActive: DateTime.now(),
              phoneNumber: '+44 7911 123456',
            );
          } else {
            final matchedUser = _db.otherUsers.cast<RippleUser?>().firstWhere(
              (u) => u?.email.toLowerCase().trim() == normalizedEmail,
              orElse: () => null,
            );
            if (matchedUser != null) {
              _db.currentUser = matchedUser;
            } else {
              _db.currentUser = RippleUser(
                uid: 'user_${normalizedEmail.hashCode}',
                displayName: savedEmail.split('@').first,
                email: savedEmail,
                photoURL: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
                area: '',
                city: '',
                verified: false,
                subscriptionTier: 'free',
                createdAt: DateTime.now(),
                lastActive: DateTime.now(),
              );
            }
          }
          _db.myChildren.clear();
          _db.myChildren.addAll(_db.userChildrenMap[_db.currentUser!.uid] ?? []);
          _db._recalculateMatches();
        }
      } catch (e) {
        developer.log("Error loading persisted mock user: $e");
      }
    }
    return _db.currentUser;
  }

  @override
  Future<RippleUser> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _db.currentUser = RippleUser(
      uid: 'user_oliver',
      displayName: 'Oliver Smith',
      email: 'oliver@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      area: '',
      city: '',
      verified: false,
      subscriptionTier: 'free',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_user_email', 'oliver@gmail.com');
    } catch (_) {}
    _db._recalculateMatches();
    _db.notifyAuth();
    await _db.saveToPrefs();
    return _db.currentUser!;
  }

  @override
  Future<RippleUser> signInWithFacebook() async {
    await Future.delayed(const Duration(seconds: 1));
    _db.currentUser = RippleUser(
      uid: 'user_emma',
      displayName: 'Emma Watson',
      email: 'emma@gmail.com',
      photoURL: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      area: '',
      city: '',
      verified: false,
      subscriptionTier: 'free',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_user_email', 'emma@gmail.com');
    } catch (_) {}
    _db._recalculateMatches();
    _db.notifyAuth();
    await _db.saveToPrefs();
    return _db.currentUser!;
  }

  @override
  Future<RippleUser> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadMockAccounts();
    final normalizedEmail = email.toLowerCase().trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception("Email and password cannot be empty");
    }

    final regPassword = _db.registeredMockAccounts[normalizedEmail];
    if (regPassword == null || regPassword != password) {
      throw Exception("Invalid email or password");
    }
    
    if (normalizedEmail == 'oliver@gmail.com' || normalizedEmail == 'oliver.smith@gmail.com') {
      _db.currentUser = RippleUser(
        uid: 'user_oliver',
        displayName: 'Oliver Smith',
        email: email,
        photoURL: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        area: 'Westminster',
        city: 'London',
        verified: true,
        subscriptionTier: 'free',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastActive: DateTime.now(),
        phoneNumber: '+44 7911 123456',
      );
    } else {
      final matchedUser = _db.otherUsers.cast<RippleUser?>().firstWhere(
        (u) => u?.email.toLowerCase().trim() == normalizedEmail,
        orElse: () => null,
      );

      if (matchedUser != null) {
        _db.currentUser = matchedUser;
      } else {
        _db.currentUser = RippleUser(
          uid: 'user_${normalizedEmail.hashCode}',
          displayName: email.split('@').first,
          email: email,
          photoURL: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
          area: '',
          city: '',
          verified: false,
          subscriptionTier: 'free',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
        );
      }
    }

    // Load children
    _db.myChildren.clear();
    _db.myChildren.addAll(_db.userChildrenMap[_db.currentUser!.uid] ?? []);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_user_email', email);
    } catch (_) {}

    _db._recalculateMatches();
    _db.notifyAuth();
    await _db.saveToPrefs();
    return _db.currentUser!;
  }

  @override
  Future<RippleUser> signUpWithEmailAndPassword(String email, String password, String name) async {
    await Future.delayed(const Duration(seconds: 1));
    await _loadMockAccounts();
    final normalizedEmail = email.toLowerCase().trim();
    if (normalizedEmail.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception("All fields are required");
    }

    if (_db.registeredMockAccounts.containsKey(normalizedEmail)) {
      throw Exception("Email already registered");
    }

    _db.registeredMockAccounts[normalizedEmail] = password;
    await _saveMockAccounts();
    
    final newUser = RippleUser(
      uid: 'user_${normalizedEmail.hashCode}',
      displayName: name,
      email: email,
      photoURL: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
      area: '',
      city: '',
      verified: false,
      subscriptionTier: 'free',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
    
    _db.currentUser = newUser;
    _db.myChildren.clear();
    _db.userChildrenMap[newUser.uid] = [];

    // Add to other users so they can show up in searches
    _db.otherUsers.add(newUser);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mock_user_email', email);
    } catch (_) {}

    _db._recalculateMatches();
    _db.notifyAuth();
    await _db.saveToPrefs();
    return _db.currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mock_user_email');
    } catch (_) {}
    _db.currentUser = null;
    _db.myChildren.clear();
    _db.matches.clear();
    _db.conversations.clear();
    _db.notifyAuth();
    await _db.saveToPrefs();
  }

  @override
  Stream<RippleUser?> authStateChanges() {
    Timer(Duration.zero, () => _db.notifyAuth());
    return _db._authController.stream;
  }
}

class MockUserRepository implements IUserRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<RippleUser?> getUserProfile(String uid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_db.currentUser?.uid == uid) return _db.currentUser;
    return _db.otherUsers.firstWhere((u) => u.uid == uid, orElse: () => throw Exception("User not found"));
  }

  @override
  Future<void> saveUserProfile(RippleUser user, {Uint8List? photoBytes}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // On mock mode: if user picked a local file, store its path directly (bytes are ignored in mock)
    if (_db.currentUser?.uid == user.uid) {
      _db.currentUser = user;
    }
    final index = _db.otherUsers.indexWhere((u) => u.uid == user.uid);
    if (index != -1) {
      _db.otherUsers[index] = user;
    } else {
      _db.otherUsers.add(user);
    }
    _db._recalculateMatches();
    _db.notifyAuth();
    await _db.saveToPrefs();
  }

  @override
  Future<List<Child>> getChildren(String uid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.userChildrenMap[uid] ?? [];
  }

  @override
  Future<void> addChild(String uid, Child child) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final kids = _db.userChildrenMap[uid] ?? [];
    kids.add(child);
    _db.userChildrenMap[uid] = kids;
    if (_db.currentUser?.uid == uid) {
      _db.myChildren.clear();
      _db.myChildren.addAll(kids);
      _db._recalculateMatches();
      _db.notifyAuth();
    }
    await _db.saveToPrefs();
  }

  @override
  Future<void> removeChild(String uid, String childId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final kids = _db.userChildrenMap[uid] ?? [];
    kids.removeWhere((c) => c.childId == childId);
    _db.userChildrenMap[uid] = kids;
    if (_db.currentUser?.uid == uid) {
      _db.myChildren.clear();
      _db.myChildren.addAll(kids);
      _db._recalculateMatches();
      _db.notifyAuth();
    }
    await _db.saveToPrefs();
  }

  @override
  Future<void> verifyUser(String uid, String documentPath) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_db.currentUser?.uid == uid) {
      _db.currentUser = _db.currentUser!.copyWith(verified: true);
      _db.notifyAuth();
    }
    final index = _db.otherUsers.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _db.otherUsers[index] = _db.otherUsers[index].copyWith(verified: true);
    }
    await _db.saveToPrefs();
  }
}

class MockSchoolRepository implements ISchoolRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<School>> getSchools() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.schools;
  }

  @override
  Future<School?> getSchoolById(String schoolId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _db.schools.firstWhere((s) => s.schoolId == schoolId, orElse: () => throw Exception("School not found"));
  }
}

class MockMatchesRepository implements IMatchesRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Future<List<MatchModel>> getMatchesForUser(String uid) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _db.matches;
  }

  @override
  Future<MatchModel?> getMatchDetails(String matchId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db.matches.firstWhere((m) => m.matchId == matchId, orElse: () => throw Exception("Match not found"));
  }

  @override
  Future<void> updateMatchStatus(String matchId, String status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    int index = _db.matches.indexWhere((m) => m.matchId == matchId);
    if (index != -1) {
      final match = _db.matches[index];
      _db.matches[index] = MatchModel(
        matchId: match.matchId,
        familyA_uid: match.familyA_uid,
        familyB_uid: match.familyB_uid,
        childA_id: match.childA_id,
        childB_id: match.childB_id,
        compatibilityScore: match.compatibilityScore,
        distanceKm: match.distanceKm,
        status: status,
        createdAt: match.createdAt,
      );

      // If newly connected, create the conversation thread
      if (status == 'connected') {
        final chatId = 'chat_$matchId';
        final isChatExists = _db.conversations.any((c) => c.chatId == chatId);
        if (!isChatExists) {
          _db.conversations.add(
            Conversation(
              chatId: chatId,
              matchId: matchId,
              participants: [match.familyA_uid, match.familyB_uid],
              lastMessage: 'You are now connected! Start coordination.',
              lastAt: DateTime.now(),
              checklistA: {'applied': false, 'confirmed': false, 'moveDate': false},
              checklistB: {'applied': false, 'confirmed': false, 'moveDate': false},
              moveConfirmed: false,
            ),
          );
          _db.messageStore[chatId] = [
            Message(
              messageId: 'welcome_msg',
              senderUid: 'system',
              text: 'You accepted the match connection request. Chat unlocked!',
              type: 'system',
              createdAt: DateTime.now(),
              readBy: [match.familyA_uid, match.familyB_uid],
            )
          ];
          _db.notifyConversations();
        }
      }
      await _db.saveToPrefs();
    }
  }
}

class MockChatRepository implements IChatRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Stream<List<Conversation>> getConversations(String uid) {
    return _db.getConversationsStream();
  }

  @override
  Stream<List<Message>> getMessages(String chatId) {
    return _db.getMessageStream(chatId);
  }

  @override
  Future<void> sendMessage(String chatId, String senderId, String text, {String type = 'text', Uint8List? fileBytes, String? fileName, int? fileSize}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final messages = _db.messageStore[chatId] ?? [];
    final newMsg = Message(
      messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderUid: senderId,
      text: text,
      type: type,
      createdAt: DateTime.now(),
      readBy: [senderId],
    );
    messages.add(newMsg);
    _db.messageStore[chatId] = messages;

    // Trigger Notification for Chat
    if (senderId != 'system') {
      final partnerUid = chatId.replaceFirst('chat_match_', '').replaceFirst('chat_', '');
      final senderName = senderId == 'user_oliver' ? 'Oliver Smith' : 'Emma Watson';
      
      final notification = AppNotification(
        id: 'not_${DateTime.now().millisecondsSinceEpoch}',
        title: 'New message from $senderName',
        body: type == 'image' ? 'Sent a photo' : (type == 'document' ? 'Sent a document' : text),
        category: 'chat',
        createdAt: DateTime.now(),
        isRead: false,
      );
      _db.notifications.insert(0, notification);
      _db.notifyNotifications();
    }

    // Update conversation last message or create a new one
    int idx = _db.conversations.indexWhere((c) => c.chatId == chatId);
    if (idx != -1) {
      _db.conversations[idx] = _db.conversations[idx].copyWith(
        lastMessage: type == 'system' ? text : text,
        lastAt: DateTime.now(),
      );
    } else {
      // Create a new conversation if it does not exist yet (e.g. started from search or matches)
      final partnerUid = chatId.replaceFirst('chat_match_', '').replaceFirst('chat_', '');
      final newConv = Conversation(
        chatId: chatId,
        matchId: chatId.replaceFirst('chat_', ''),
        participants: [senderId, partnerUid],
        lastMessage: text,
        lastAt: DateTime.now(),
        checklistA: {'applied': false, 'confirmed': false, 'moveDate': false},
        checklistB: {'applied': false, 'confirmed': false, 'moveDate': false},
        moveConfirmed: false,
      );
      _db.conversations.add(newConv);
    }
    _db.notifyConversations();

    _db.notifyMessages(chatId);

    // Simulate auto-reply when you send message to Emma
    if (senderId == 'user_oliver' && chatId == 'chat_match_user_emma' && type == 'text') {
      Future.delayed(const Duration(seconds: 2), () async {
        final replies = [
          'Excellent, I will follow up with the admissions office tomorrow.',
          'Understood. Let me check the document checklist again.',
          'Sounds good! Let me update my checklist here as well.',
        ];
        final replyText = replies[math.Random().nextInt(replies.length)];
        final replyMsg = Message(
          messageId: 'msg_reply_${DateTime.now().millisecondsSinceEpoch}',
          senderUid: 'user_emma',
          text: replyText,
          type: 'text',
          createdAt: DateTime.now(),
          readBy: ['user_emma'],
        );
        _db.messageStore[chatId]?.add(replyMsg);
        _db.conversations[idx] = _db.conversations[idx].copyWith(
          lastMessage: replyText,
          lastAt: DateTime.now(),
        );
        _db.notifyConversations();
        _db.notifyMessages(chatId);

        // Add auto-reply notification
        final replyNotification = AppNotification(
          id: 'not_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New message from Emma Watson',
          body: replyText,
          category: 'chat',
          createdAt: DateTime.now(),
          isRead: false,
        );
        _db.notifications.insert(0, replyNotification);
        _db.notifyNotifications();
        await _db.saveToPrefs();
      });
    }
    await _db.saveToPrefs();
  }

  @override
  Future<void> updateChecklist(String chatId, String uid, String key, bool value) async {
    await Future.delayed(const Duration(milliseconds: 200));
    int idx = _db.conversations.indexWhere((c) => c.chatId == chatId);
    if (idx != -1) {
      final conv = _db.conversations[idx];
      Map<String, bool> newChecklistA = Map.from(conv.checklistA);
      Map<String, bool> newChecklistB = Map.from(conv.checklistB);

      if (uid == 'user_oliver') {
        newChecklistA[key] = value;
      } else {
        newChecklistB[key] = value;
      }

      // Check if both completed
      bool allA = newChecklistA.values.every((v) => v == true) && newChecklistA.length == 3;
      bool allB = newChecklistB.values.every((v) => v == true) && newChecklistB.length == 3;
      bool moveConfirmed = allA && allB;

      _db.conversations[idx] = conv.copyWith(
        checklistA: newChecklistA,
        checklistB: newChecklistB,
        moveConfirmed: moveConfirmed,
      );

      _db.notifyConversations();

      // System notification message
      final name = uid == 'user_oliver' ? 'Oliver Smith' : 'Emma Watson';
      final statusStr = value ? 'completed' : 'unchecked';
      String stepName = '';
      if (key == 'applied') stepName = 'Submitted Transfer Form';
      if (key == 'confirmed') stepName = 'Official Transfer Confirmed';
      if (key == 'moveDate') stepName = 'Agreed Move Date';

      await sendMessage(
        chatId,
        'system',
        '$name has $statusStr: "$stepName"',
        type: 'system',
      );

      // Trigger notification for milestone
      if (value == true) {
        final milestoneNotification = AppNotification(
          id: 'not_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Milestone Completed',
          body: '$name has marked checklist: "$stepName"',
          category: 'match',
          createdAt: DateTime.now(),
          isRead: false,
        );
        _db.notifications.insert(0, milestoneNotification);
        _db.notifyNotifications();
      }

      // Trigger automatic complete from Emma if you check everything
      if (uid == 'user_oliver' && value == true && key != 'moveDate') {
        Future.delayed(const Duration(seconds: 3), () async {
          // Emma checks off the same key to keep it interactive
          await updateChecklist(chatId, 'user_emma', key, true);
        });
      } else if (uid == 'user_oliver' && value == true && key == 'moveDate') {
        Future.delayed(const Duration(seconds: 3), () async {
          // Finally complete both and trigger success wall status
          await updateChecklist(chatId, 'user_emma', 'moveDate', true);
          // Set match status to complete
          final matchId = conv.matchId;
          int matchIdx = _db.matches.indexWhere((m) => m.matchId == matchId);
          if (matchIdx != -1) {
            final match = _db.matches[matchIdx];
            _db.matches[matchIdx] = MatchModel(
              matchId: match.matchId,
              familyA_uid: match.familyA_uid,
              familyB_uid: match.familyB_uid,
              childA_id: match.childA_id,
              childB_id: match.childB_id,
              compatibilityScore: match.compatibilityScore,
              distanceKm: match.distanceKm,
              status: 'complete',
              createdAt: match.createdAt,
            );
          }
          await _db.saveToPrefs();
        });
      }
      await _db.saveToPrefs();
    }
  }
}

class MockNotificationRepository implements INotificationRepository {
  final MockDatabase _db = MockDatabase.instance;

  @override
  Stream<List<AppNotification>> getNotifications(String uid) {
    return _db.getNotificationsStream();
  }

  @override
  Future<void> addNotification(String uid, AppNotification notification) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _db.notifications.insert(0, notification);
    _db.notifyNotifications();
    await _db.saveToPrefs();
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _db.notifications.length; i++) {
      _db.notifications[i] = _db.notifications[i].copyWith(isRead: true);
    }
    _db.notifyNotifications();
    await _db.saveToPrefs();
  }

  @override
  Future<void> markAsRead(String uid, String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _db.notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _db.notifications[idx] = _db.notifications[idx].copyWith(isRead: true);
      _db.notifyNotifications();
      await _db.saveToPrefs();
    }
  }
}

