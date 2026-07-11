import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/repositories/firebase_repository.dart';
import 'core/repositories/mock_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Defensive Firebase initialization
  try {
    // Note: If you have configured your firebase files, this runs correctly.
    // Otherwise, we catch the initialization exception so the app can fallback 
    // seamlessly to our local Mock Repositories sandbox mode!
    await Firebase.initializeApp();
    developer.log('Firebase initialized successfully.');
    await FirebaseAuthRepository.seedFirebaseIfEmpty();
  } catch (e) {
    developer.log(
      'Firebase initialization skipped or failed: ${e.toString()}.\n'
      'Falling back to local Mock Repository sandbox mode for testing.',
    );
  }

  // Initialize Mock Database persistence
  await MockDatabase.instance.ensureInitialized();

  runApp(
    const ProviderScope(
      child: RippleApp(),
    ),
  );
}
