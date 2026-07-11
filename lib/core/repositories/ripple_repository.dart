import 'dart:typed_data';
import '../models/ripple_models.dart';

abstract class IAuthRepository {
  Future<RippleUser?> getCurrentUser();
  Future<RippleUser> signInWithGoogle();
  Future<RippleUser> signInWithFacebook();
  Future<RippleUser> signInWithEmailAndPassword(String email, String password);
  Future<RippleUser> signUpWithEmailAndPassword(String email, String password, String name);
  Future<void> signOut();
  Stream<RippleUser?> authStateChanges();
}

abstract class IUserRepository {
  Future<RippleUser?> getUserProfile(String uid);
  Future<void> saveUserProfile(RippleUser user, {Uint8List? photoBytes});
  Future<List<Child>> getChildren(String uid);
  Future<void> addChild(String uid, Child child);
  Future<void> removeChild(String uid, String childId);
  Future<void> verifyUser(String uid, String documentPath);
}

abstract class ISchoolRepository {
  Future<List<School>> getSchools();
  Future<School?> getSchoolById(String schoolId);
}

abstract class IMatchesRepository {
  Future<List<MatchModel>> getMatchesForUser(String uid);
  Future<MatchModel?> getMatchDetails(String matchId);
  Future<void> updateMatchStatus(String matchId, String status);
}

abstract class IChatRepository {
  Stream<List<Conversation>> getConversations(String uid);
  Stream<List<Message>> getMessages(String chatId);
  Future<void> sendMessage(String chatId, String senderId, String text, {String type, Uint8List? fileBytes, String? fileName, int? fileSize});
  Future<void> updateChecklist(String chatId, String uid, String key, bool value);
}

abstract class INotificationRepository {
  Stream<List<AppNotification>> getNotifications(String uid);
  Future<void> addNotification(String uid, AppNotification notification);
  Future<void> markAllAsRead(String uid);
  Future<void> markAsRead(String uid, String notificationId);
}

