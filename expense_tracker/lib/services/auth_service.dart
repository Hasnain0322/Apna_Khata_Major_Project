import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen for auth state changes (for AuthGate)
  Stream<User?> get user => _auth.authStateChanges();

  // NEW METHOD: Register a user but DO NOT keep them logged in.
  // Returns true on success, false on failure.
  Future<bool> registerWithEmailAndPassword(String email, String password) async {
    try {
      // Create the user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (result.user != null) {
        // IMPORTANT: Immediately sign out to force the user to log in.
        await _auth.signOut();
        return true; // Indicate success
      }
      return false;
    } on FirebaseAuthException catch (e) {
      // Handle errors like 'email-already-in-use', 'weak-password', etc.
      print('Registration failed: ${e.message}');
      return false; // Indicate failure
    }
  }

  // Sign In with Email & Password (no changes needed here)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Sign in failed: ${e.message}');
      return null;
    }
  }

  // Sign Out (no changes needed here)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}