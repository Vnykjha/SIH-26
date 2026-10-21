import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/health_worker.dart';
import 'database_service.dart';
import 'firebase_auth_bridge.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  HealthWorker? currentUser;

  static String hashPassword(String password) {
    final bytes = utf8.encode(password.trim());
    return sha256.convert(bytes).toString();
  }

  Future<void> initializeDefaultUser() async {
    final existing = await DatabaseService.instance
        .getHealthWorkerByEmail('admin@crepisense.in');
    if (existing != null) {
      currentUser = existing;
      return;
    }

    final defaultUser = HealthWorker(
      name: 'Demo Health Worker',
      email: 'admin@crepisense.in',
      passwordHash: hashPassword('crepisense123'),
      role: 'admin',
    );

    await DatabaseService.instance.insertHealthWorker(defaultUser);
    currentUser = defaultUser;
  }

  Future<HealthWorker?> login(String email, String password) async {
    final normalizedEmail = email.trim();

    final firebaseAvailable = await FirebaseAuthBridge.isAvailable();
    if (firebaseAvailable) {
      final firebaseUser = await FirebaseAuthBridge.signInWithEmailPassword(
          normalizedEmail, password);
      if (firebaseUser != null) {
        final user = firebaseUser.user;
        final firebaseEmail = user?.email ?? normalizedEmail;
        final displayName = user?.displayName?.trim();
        currentUser = HealthWorker(
          id: user?.uid ?? 'firebase-user',
          name: displayName?.isNotEmpty == true
              ? displayName!
              : _nameFromEmail(firebaseEmail),
          email: firebaseEmail,
          passwordHash: hashPassword(password),
          role: 'health_worker',
        );
        return currentUser;
      }
    }

    final worker = await DatabaseService.instance.authenticateWorker(
      normalizedEmail,
      hashPassword(password),
    );
    if (worker == null) {
      return null;
    }

    currentUser = worker;
    return worker;
  }

  Future<HealthWorker> registerHealthWorker({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await FirebaseAuthBridge.registerWithEmailPassword(
      name: name,
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'registration-failed',
        message: 'Firebase did not return a registered user.',
      );
    }

    currentUser = HealthWorker(
      id: user.uid,
      name: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : name.trim(),
      email: user.email ?? email.trim(),
      passwordHash: '',
      role: 'health_worker',
    );
    return currentUser!;
  }

  String _nameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words =
        localPart.split(RegExp(r'[._+-]+')).where((part) => part.isNotEmpty);
    return words
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void logout() {
    currentUser = null;
  }
}
