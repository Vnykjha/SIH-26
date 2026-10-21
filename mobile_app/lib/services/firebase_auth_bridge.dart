import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthBridge {
  static Future<bool> isAvailable() async {
    try {
      await FirebaseAuth.instance.authStateChanges().first;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<UserCredential> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    await credential.user?.reload();
    return credential;
  }
}
