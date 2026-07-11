import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../models/ripple_models.dart';
import 'ripple_repository.dart';
import 'mock_repository.dart';
import 'firebase_repository.dart';

final authStateProvider = StreamProvider<RippleUser?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

final userChildrenProvider = FutureProvider.family<List<Child>, String>((ref, uid) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.getChildren(uid);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final useMock = ref.watch(mockModeProvider);
  if (useMock) {
    return MockAuthRepository();
  } else {
    return FirebaseAuthRepository();
  }
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final useMock = ref.watch(mockModeProvider);
  if (useMock) {
    return MockUserRepository();
  } else {
    return FirestoreUserRepository();
  }
});

final schoolRepositoryProvider = Provider<ISchoolRepository>((ref) {
  final useMock = ref.watch(mockModeProvider);
  if (useMock) {
    return MockSchoolRepository();
  } else {
    return FirestoreSchoolRepository();
  }
});

final matchesRepositoryProvider = Provider<IMatchesRepository>((ref) {
  final useMock = ref.watch(mockModeProvider);
  if (useMock) {
    return MockMatchesRepository();
  } else {
    return FirestoreMatchesRepository();
  }
});

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  final useMock = ref.watch(mockModeProvider);
  if (useMock) {
    return MockChatRepository();
  } else {
    return FirestoreChatRepository();
  }
});

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  final useMock = ref.watch(mockModeProvider);
  if (useMock) {
    return MockNotificationRepository();
  } else {
    return FirestoreNotificationRepository();
  }
});

