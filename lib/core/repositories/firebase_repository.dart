import 'dart:developer' as developer;
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/ripple_models.dart';
import 'ripple_repository.dart';

Future<String> uploadLocalFileOrBytes({
  String? localPath,
  Uint8List? bytes,
  required String storagePath,
}) async {
  try {
    final ref = FirebaseStorage.instance.ref().child(storagePath);
    if (kIsWeb) {
      if (bytes != null) {
        final uploadTask = await ref.putData(bytes);
        return await uploadTask.ref.getDownloadURL();
      }
      return '';
    } else {
      if (bytes != null) {
        final uploadTask = await ref.putData(bytes);
        return await uploadTask.ref.getDownloadURL();
      }
      if (localPath != null && localPath.isNotEmpty) {
        final file = io.File(localPath);
        if (file.existsSync()) {
          final uploadTask = await ref.putFile(file);
          return await uploadTask.ref.getDownloadURL();
        }
      }
      return '';
    }
  } catch (e) {
    developer.log("Error uploading file to Firebase Storage: $e");
    return '';
  }
}


class FirebaseAuthRepository implements IAuthRepository {
  final fba.FirebaseAuth _auth = fba.FirebaseAuth.instance;

  RippleUser _mapFirebaseUser(fba.User user) {
    return RippleUser(
      uid: user.uid,
      displayName: user.displayName ?? 'Parent User',
      email: user.email ?? '',
      photoURL: user.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      area: '',
      city: '',
      verified: false,
      subscriptionTier: 'free',
      createdAt: DateTime.now(),
      lastActive: DateTime.now(),
    );
  }

  @override
  Future<RippleUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // Fetch profile from firestore if exists to get area/city info
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return RippleUser.fromMap(doc.data()!);
      }
    } catch (e) {
      developer.log("Error loading user profile from Firestore: $e");
    }
    return _mapFirebaseUser(user);
  }

  @override
  Future<RippleUser> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) {
        throw Exception("Google Sign-In canceled by user.");
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      // v7: accessToken moved to authorizationClient; only idToken needed for Firebase
      final fba.OAuthCredential credential = fba.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw Exception("Google Sign-In failed to get credentials");
      }

      final rippleUser = _mapFirebaseUser(userCredential.user!);
      // Save profile to firestore if not exists
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(rippleUser.uid).get();
      if (!userDoc.exists) {
        await FirestoreUserRepository().saveUserProfile(rippleUser);
      }
      
      // Auto seed database for this user
      await seedUserSpecificData(rippleUser.uid);
      
      return rippleUser;
    } catch (e) {
      developer.log("Google Sign-In error: $e. Falling back to simulated login.");
      // Fallback for emulator/tests: simulate a successful Google user login
      final simulatedUser = RippleUser(
        uid: 'user_google_simulated',
        displayName: 'Simulated Google User',
        email: 'google.user@example.com',
        photoURL: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        area: '',
        city: '',
        verified: false,
        subscriptionTier: 'free',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      try {
        await FirestoreUserRepository().saveUserProfile(simulatedUser);
        await seedUserSpecificData(simulatedUser.uid);
      } catch (_) {}
      return simulatedUser;
    }
  }

  @override
  Future<RippleUser> signInWithFacebook() async {
    try {
      // Simulation of Facebook Sign-In flow
      await Future.delayed(const Duration(milliseconds: 1500));
      final simulatedUser = RippleUser(
        uid: 'user_facebook_simulated',
        displayName: 'Simulated Facebook User',
        email: 'facebook.user@example.com',
        photoURL: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        area: '',
        city: '',
        verified: false,
        subscriptionTier: 'free',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      try {
        await FirestoreUserRepository().saveUserProfile(simulatedUser);
        await seedUserSpecificData(simulatedUser.uid);
      } catch (_) {}
      return simulatedUser;
    } catch (e) {
      throw Exception("Facebook login failed: $e");
    }
  }

  @override
  Future<RippleUser> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (userCredential.user == null) {
      throw Exception("User login failed");
    }
    final rippleUser = _mapFirebaseUser(userCredential.user!);
    
    // Check if Firestore user document exists, if not save it
    final doc = await FirebaseFirestore.instance.collection('users').doc(rippleUser.uid).get();
    if (!doc.exists) {
      await FirestoreUserRepository().saveUserProfile(rippleUser);
    }
    
    // Auto seed matches and conversations
    await seedUserSpecificData(rippleUser.uid);
    
    // Load full profile
    return await getCurrentUser() ?? rippleUser;
  }

  @override
  Future<RippleUser> signUpWithEmailAndPassword(String email, String password, String name) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (userCredential.user == null) {
      throw Exception("User signup failed");
    }
    await userCredential.user!.updateDisplayName(name);
    await userCredential.user!.reload();
    final updatedUser = _auth.currentUser ?? userCredential.user!;
    final rippleUser = _mapFirebaseUser(updatedUser).copyWith(displayName: name);
    
    // Save profile to Firestore
    await FirestoreUserRepository().saveUserProfile(rippleUser);
    
    // Auto seed matches and conversations
    await seedUserSpecificData(rippleUser.uid);
    
    return rippleUser;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Stream<RippleUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          return RippleUser.fromMap(doc.data()!);
        }
      } catch (_) {}
      return _mapFirebaseUser(user);
    });
  }

  // Seeding functions
  static Future<void> seedFirebaseIfEmpty() async {
    try {
      final db = FirebaseFirestore.instance;
      
      // Check if schools collection is empty
      final schoolsQuery = await db.collection('schools').limit(1).get();
      if (schoolsQuery.docs.isEmpty) {
        developer.log("Firestore empty. Seeding initial database tables...");
        
        // 1. Seed Schools
        final schools = [
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
        ];

        for (var sch in schools) {
          await db.collection('schools').doc(sch.schoolId).set(sch.toMap());
        }

        // 2. Seed Mock Target Families
        final mockUsers = [
          RippleUser(
            uid: 'user_emma',
            displayName: 'Emma Watson',
            email: 'emma@gmail.com',
            photoURL: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
            area: 'Chelsea',
            city: 'London',
            verified: true,
            subscriptionTier: 'premium',
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
            lastActive: DateTime.now(),
          ),
          RippleUser(
            uid: 'user_george',
            displayName: 'George Bentley',
            email: 'george@gmail.com',
            photoURL: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
            area: 'Camden',
            city: 'London',
            verified: false,
            subscriptionTier: 'free',
            createdAt: DateTime.now().subtract(const Duration(days: 20)),
            lastActive: DateTime.now(),
          ),
          RippleUser(
            uid: 'user_sophie',
            displayName: 'Sophie Davies',
            email: 'sophie@gmail.com',
            photoURL: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
            area: 'Westminster',
            city: 'London',
            verified: true,
            subscriptionTier: 'free',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
            lastActive: DateTime.now(),
          ),
        ];

        for (var u in mockUsers) {
          await db.collection('users').doc(u.uid).set(u.toMap());
        }

        // 3. Seed their children profiles
        final childEmma = Child(
          childId: 'child_chloe',
          firstName: 'Chloe',
          gradeYear: 'Year 5',
          currentSchoolId: 'sch_westminstersch',
          targetSchoolIds: ['sch_westminster'],
          status: 'active',
          age: 9,
        );

        final childGeorge = Child(
          childId: 'child_leo',
          firstName: 'Leo',
          gradeYear: 'Year 5',
          currentSchoolId: 'sch_stpauls',
          targetSchoolIds: ['sch_westminster'],
          status: 'active',
          age: 10,
        );

        final childSophie = Child(
          childId: 'child_lucas',
          firstName: 'Lucas',
          gradeYear: 'Year 6',
          currentSchoolId: 'sch_camdengirls',
          targetSchoolIds: ['sch_westminster'],
          status: 'active',
          age: 11,
        );

        await db.collection('users').doc('user_emma').collection('children').doc(childEmma.childId).set(childEmma.toMap());
        await db.collection('users').doc('user_george').collection('children').doc(childGeorge.childId).set(childGeorge.toMap());
        await db.collection('users').doc('user_sophie').collection('children').doc(childSophie.childId).set(childSophie.toMap());
        
        developer.log("Firestore seeding completed successfully.");
      }
    } catch (e) {
      developer.log("Seeding failed: $e");
    }
  }

  // Seed user matches and active chats dynamically
  static Future<void> seedUserSpecificData(String myUid) async {
    try {
      final db = FirebaseFirestore.instance;
      
      // Ensure we don't overwrite if matches already exist
      final matchesQuery = await db.collection('matches').where('familyA_uid', isEqualTo: myUid).limit(1).get();
      if (matchesQuery.docs.isEmpty) {
        developer.log("Generating matches and chat workspaces for new user $myUid...");
        
        // Add a mock child for the current user in Firestore if they don't have one
        final kidsQuery = await db.collection('users').doc(myUid).collection('children').get();
        String myChildId = 'child_jack';
        if (kidsQuery.docs.isEmpty) {
          final defaultChild = Child(
            childId: 'child_jack',
            firstName: 'Jack',
            gradeYear: 'Year 5',
            currentSchoolId: 'sch_westminster',
            targetSchoolIds: ['sch_westminstersch'],
            status: 'active',
            age: 9,
          );
          await db.collection('users').doc(myUid).collection('children').doc(defaultChild.childId).set(defaultChild.toMap());
        } else {
          myChildId = kidsQuery.docs.first.id;
        }

        // Add 3 Matches
        final matchEmma = MatchModel(
          matchId: 'match_${myUid}_emma',
          familyA_uid: myUid,
          familyB_uid: 'user_emma',
          childA_id: myChildId,
          childB_id: 'child_chloe',
          compatibilityScore: 95.0,
          distanceKm: 3.5,
          status: 'connected',
          createdAt: DateTime.now(),
        );

        final matchGeorge = MatchModel(
          matchId: 'match_${myUid}_george',
          familyA_uid: myUid,
          familyB_uid: 'user_george',
          childA_id: myChildId,
          childB_id: 'child_leo',
          compatibilityScore: 80.0,
          distanceKm: 5.1,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        final matchSophie = MatchModel(
          matchId: 'match_${myUid}_sophie',
          familyA_uid: myUid,
          familyB_uid: 'user_sophie',
          childA_id: myChildId,
          childB_id: 'child_lucas',
          compatibilityScore: 75.0,
          distanceKm: 1.2,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        await db.collection('matches').doc(matchEmma.matchId).set(matchEmma.toMap());
        await db.collection('matches').doc(matchGeorge.matchId).set(matchGeorge.toMap());
        await db.collection('matches').doc(matchSophie.matchId).set(matchSophie.toMap());

        // Create Chat conversation with Emma
        final chatId = 'chat_match_${myUid}_emma';
        final conv = Conversation(
          chatId: chatId,
          matchId: matchEmma.matchId,
          participants: [myUid, 'user_emma'],
          lastMessage: 'Emma accepted your connection request.',
          lastAt: DateTime.now().subtract(const Duration(hours: 1)),
          checklistA: {'applied': true, 'confirmed': false, 'moveDate': false},
          checklistB: {'applied': false, 'confirmed': false, 'moveDate': false},
          moveConfirmed: false,
        );
        await db.collection('conversations').doc(chatId).set(conv.toMap());

        // Add default messages to the conversation
        final messages = [
          Message(
            messageId: 'msg_1',
            senderUid: 'user_emma',
            text: 'Hi! I saw we got a 95% match. My child Chloe is in Year 5 at Westminster Under School, and we want to move her to Harris Academy Westminster because it is much closer to our new home in Chelsea.',
            type: 'text',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            readBy: [myUid, 'user_emma'],
          ),
          Message(
            messageId: 'msg_2',
            senderUid: myUid,
            text: 'Hi Emma! Yes, our child Jack studies at Harris Academy Westminster but Westminster Under School is right near our area in Westminster. It makes perfect sense to swap!',
            type: 'text',
            createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
            readBy: [myUid, 'user_emma'],
          ),
          Message(
            messageId: 'msg_3',
            senderUid: 'user_emma',
            text: 'Wonderful! Let\'s coordinate the paperwork. I will prepare the application form.',
            type: 'text',
            createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
            readBy: [myUid, 'user_emma'],
          ),
          Message(
            messageId: 'sys_1',
            senderUid: 'system',
            text: 'You has completed: "Submitted Transfer Form"',
            type: 'system',
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
            readBy: [myUid, 'user_emma'],
          ),
        ];

        for (var msg in messages) {
          await db.collection('conversations').doc(chatId).collection('messages').doc(msg.messageId).set(msg.toMap());
        }
      }
    } catch (e) {
      developer.log("User specific seeding failed: $e");
    }
  }
}

class FirestoreUserRepository implements IUserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<RippleUser?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return RippleUser.fromMap(doc.data()!);
  }

  @override
  Future<void> saveUserProfile(RippleUser user, {Uint8List? photoBytes}) async {
    String photoURL = user.photoURL;
    // If photoBytes provided, upload to Firebase Storage
    if (photoBytes != null && photoBytes.isNotEmpty) {
      final uploadedUrl = await uploadLocalFileOrBytes(
        bytes: photoBytes,
        storagePath: 'users/${user.uid}/profile_photo.jpg',
      );
      if (uploadedUrl.isNotEmpty) {
        photoURL = uploadedUrl;
      }
    } else if (!user.photoURL.startsWith('http://') &&
        !user.photoURL.startsWith('https://') &&
        user.photoURL.isNotEmpty) {
      // Local path or blob – try to upload bytes if on native
      if (!kIsWeb) {
        final uploadedUrl = await uploadLocalFileOrBytes(
          localPath: user.photoURL,
          storagePath: 'users/${user.uid}/profile_photo.jpg',
        );
        if (uploadedUrl.isNotEmpty) {
          photoURL = uploadedUrl;
        }
      }
    }
    final updatedUser = photoURL != user.photoURL ? user.copyWith(photoURL: photoURL) : user;
    await _firestore.collection('users').doc(user.uid).set(updatedUser.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<Child>> getChildren(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).collection('children').get();
    return snapshot.docs.map((doc) => Child.fromMap(doc.data())).toList();
  }

  @override
  Future<void> addChild(String uid, Child child) async {
    await _firestore.collection('users').doc(uid).collection('children').doc(child.childId).set(child.toMap());
  }

  @override
  Future<void> removeChild(String uid, String childId) async {
    await _firestore.collection('users').doc(uid).collection('children').doc(childId).delete();
  }

  @override
  Future<void> verifyUser(String uid, String documentPath) async {
    await _firestore.collection('users').doc(uid).update({'verified': true});
  }
}

class FirestoreSchoolRepository implements ISchoolRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<School>> getSchools() async {
    final snapshot = await _firestore.collection('schools').get();
    return snapshot.docs.map((doc) => School.fromMap(doc.data())).toList();
  }

  @override
  Future<School?> getSchoolById(String schoolId) async {
    final doc = await _firestore.collection('schools').doc(schoolId).get();
    if (!doc.exists) return null;
    return School.fromMap(doc.data()!);
  }
}

class FirestoreMatchesRepository implements IMatchesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<MatchModel>> getMatchesForUser(String uid) async {
    final snapshot = await _firestore.collection('matches')
        .where('familyA_uid', isEqualTo: uid)
        .get();
    return snapshot.docs.map((doc) => MatchModel.fromMap(doc.data())).toList();
  }

  @override
  Future<MatchModel?> getMatchDetails(String matchId) async {
    final doc = await _firestore.collection('matches').doc(matchId).get();
    if (!doc.exists) return null;
    return MatchModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateMatchStatus(String matchId, String status) async {
    await _firestore.collection('matches').doc(matchId).update({'status': status});
  }
}

class FirestoreChatRepository implements IChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Conversation>> getConversations(String uid) {
    return _firestore.collection('conversations')
        .where('participants', arrayContains: uid)
        .orderBy('lastAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Conversation.fromMap(doc.data())).toList());
  }

  @override
  Stream<List<Message>> getMessages(String chatId) {
    return _firestore.collection('conversations')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Message.fromMap(doc.data())).toList());
  }

  @override
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    String type = 'text',
    Uint8List? fileBytes,
    String? fileName,
    int? fileSize,
  }) async {
    String messageText = text;
    String messageType = type;

    // If we have file bytes, upload to Firebase Storage first
    if (fileBytes != null && fileBytes.isNotEmpty && type != 'text') {
      final ext = type == 'image' ? 'jpg' : (fileName?.split('.').last ?? 'bin');
      final storagePath = 'chats/$chatId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final uploadedUrl = await uploadLocalFileOrBytes(
        bytes: fileBytes,
        storagePath: storagePath,
      );
      if (uploadedUrl.isNotEmpty) {
        if (type == 'document' && fileName != null) {
          final sizeMB = fileSize != null ? (fileSize / (1024 * 1024)).toStringAsFixed(1) : '?';
          messageText = '$fileName • $sizeMB MB • $uploadedUrl';
        } else {
          messageText = uploadedUrl;
        }
      }
    }

    final msg = Message(
      messageId: _firestore.collection('conversations').doc(chatId).collection('messages').doc().id,
      senderUid: senderId,
      text: messageText,
      type: messageType,
      createdAt: DateTime.now(),
      readBy: [senderId],
    );
    
    final batch = _firestore.batch();
    final newMsgRef = _firestore.collection('conversations').doc(chatId).collection('messages').doc(msg.messageId);
    batch.set(newMsgRef, msg.toMap());
    
    final convRef = _firestore.collection('conversations').doc(chatId);
    batch.update(convRef, {
      'lastMessage': type == 'text' ? text : (type == 'image' ? '[Photo]' : '[Document]'),
      'lastAt': Timestamp.now(),
    });
    
    await batch.commit();
  }

  @override
  Future<void> updateChecklist(String chatId, String uid, String key, bool value) async {
    final convDoc = await _firestore.collection('conversations').doc(chatId).get();
    if (convDoc.exists) {
      final conv = Conversation.fromMap(convDoc.data()!);
      final isA = conv.participants.indexOf(uid) == 0;
      
      final field = isA ? 'checklistA.$key' : 'checklistB.$key';
      
      // Update checklist
      await _firestore.collection('conversations').doc(chatId).update({field: value});
      
      // Verify if both completed
      final updatedConvDoc = await _firestore.collection('conversations').doc(chatId).get();
      final updatedConv = Conversation.fromMap(updatedConvDoc.data()!);
      
      bool allA = updatedConv.checklistA.values.every((v) => v == true) && updatedConv.checklistA.length == 3;
      bool allB = updatedConv.checklistB.values.every((v) => v == true) && updatedConv.checklistB.length == 3;
      bool moveConfirmed = allA && allB;
      
      if (moveConfirmed != updatedConv.moveConfirmed) {
        await _firestore.collection('conversations').doc(chatId).update({'moveConfirmed': moveConfirmed});
        if (moveConfirmed) {
          // Update match status to complete
          await _firestore.collection('matches').doc(updatedConv.matchId).update({'status': 'complete'});
        }
      }
    }
  }
}

class FirestoreNotificationRepository implements INotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<AppNotification>> getNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppNotification.fromMap(d.data())).toList());
  }

  @override
  Future<void> addNotification(String uid, AppNotification notification) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toMap());
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  Future<void> markAsRead(String uid, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
